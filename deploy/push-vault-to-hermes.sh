#!/usr/bin/env bash
# push-vault-to-hermes.sh — build the portable `vault` and install it into
# hermes-1's read-only /opt/tools volume, without ever attaching that volume
# read-write to hermes-1 itself.
#
# Why not just flip hermes-1's own mount to rw and back: the mount mode is a
# property of the instance. Flipping it, even briefly, hands the running
# Hermes agent write access to its own tooling for that window — exactly the
# capability this design exists to remove. Confirmed as a real gap
# 2026-08-01 (see, in the vault, projects/vault-setup/log/2026-08-01-
# read-only-tools-volume-works-deployed-binaries-do-not-run.md).
#
# Instead: stop hermes-1 (a stopped instance's disk devices aren't mounted,
# so the volume is free for exclusive read-write attachment elsewhere with
# no multi-attach configuration needed), attach it read-write to a
# disposable helper instance, push the file, delete the helper, start
# hermes-1 again. hermes-1's own device config (compose.yaml's
# `hermes-tools:/opt/tools:ro`) never changes, so a plain stop/start
# suffices — no --recreate.
#
# The helper is created with raw `incus launch`/`incus delete`, not
# incus-compose: it must NOT be part of the hermes compose project, or a
# stray `incus-compose up` could resurrect it later. It's still scoped with
# --project on every call to stay within the hermes Incus project and avoid
# touching anything else on the shared host.
#
# Only `vault` is deployed here. `stack` needs incus/incus-compose/curl/jq,
# none of which belong inside Hermes — it only runs from the workstation/Pi,
# via the native (Nix-wrapped) flake output, installed through
# environment.systemPackages.
#
# Run from the workstation. Requires: nix, incus, incus-compose.
#
# Config from the environment:
#   STACK_DIR   path to the hermes compose.yaml/.env directory (required)

set -euo pipefail

PROJECT="${INCUS_PROJECT:-hermes}"
POOL="${INCUS_POOL:-local}"
VOLUME="${HERMES_TOOLS_VOLUME:-vol-hermes-tools}"
HELPER="hermes-tools-helper"
HELPER_IMAGE="${HELPER_IMAGE:-images:alpine/edge}"
STACK_DIR="${STACK_DIR:?set STACK_DIR to the path of your hermes stack directory (compose.yaml/.env)}"
VAULT_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_OUT="$(mktemp -d)"

die() { echo "push-vault-to-hermes: error: $*" >&2; exit 1; }

HERMES_STOPPED=0
HELPER_CREATED=0
HELPER_ATTACHED=0

# Whatever fails partway, always try to detach/delete the helper and bring
# hermes back up — a script that dies leaving hermes stopped is worse than
# the bug it was written to fix.
cleanup() {
  local status=$?
  if [[ "$HELPER_ATTACHED" -eq 1 ]]; then
    incus --project "$PROJECT" storage volume detach "$POOL" "$VOLUME" "$HELPER" 2>/dev/null || true
  fi
  if [[ "$HELPER_CREATED" -eq 1 ]]; then
    incus --project "$PROJECT" delete --force "$HELPER" 2>/dev/null || true
  fi
  if [[ "$HERMES_STOPPED" -eq 1 ]]; then
    echo "==> starting hermes back up"
    ( cd "$STACK_DIR" && incus-compose start hermes ) 2>/dev/null || true
  fi
  rm -rf "$BUILD_OUT"
  exit "$status"
}
trap cleanup EXIT

echo "==> building portable vault (vault-hermes)"
nix build "$VAULT_TOOLS_DIR#vault-hermes" -o "$BUILD_OUT/result"
[[ -x "$BUILD_OUT/result/bin/vault" ]] || die "build did not produce an executable bin/vault"

echo "==> stopping hermes (frees hermes-tools for exclusive read-write attach)"
( cd "$STACK_DIR" && incus-compose stop hermes )
HERMES_STOPPED=1

echo "==> launching disposable helper (project: $PROJECT, image: $HELPER_IMAGE)"
incus --project "$PROJECT" launch "$HELPER_IMAGE" "$HELPER"
HELPER_CREATED=1

echo "==> waiting for helper to come up"
for _ in $(seq 1 20); do
  incus --project "$PROJECT" exec "$HELPER" -- true 2>/dev/null && break
  sleep 1
done

echo "==> attaching $VOLUME read-write to helper"
incus --project "$PROJECT" storage volume attach "$POOL" "$VOLUME" "$HELPER" /opt/tools
HELPER_ATTACHED=1

echo "==> pushing vault"
incus --project "$PROJECT" file push --mode 0555 "$BUILD_OUT/result/bin/vault" "$HELPER/opt/tools/vault"

echo "==> tearing down helper"
incus --project "$PROJECT" storage volume detach "$POOL" "$VOLUME" "$HELPER"
HELPER_ATTACHED=0
incus --project "$PROJECT" delete --force "$HELPER"
HELPER_CREATED=0

echo "==> starting hermes back up"
( cd "$STACK_DIR" && incus-compose start hermes )
HERMES_STOPPED=0

echo "==> verifying"
( cd "$STACK_DIR" && incus-compose exec hermes -- /opt/tools/vault --version )
( cd "$STACK_DIR" && incus-compose exec hermes -- /command/s6-setuidgid hermes sh -c 'echo x >> /opt/tools/vault' ) \
  && die "write to /opt/tools/vault succeeded — volume is not read-only, fix before trusting this boundary" \
  || echo "==> confirmed: /opt/tools/vault is not writable by hermes"
