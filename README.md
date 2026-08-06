# vault-tools

CLI tooling for the [Hermes/Pi shared memory vault](https://github.com/OleMussmann/vault):
`vault` (read/write the vault). Image-update tooling for the Incus stacks
lives in its own repo now:
[github.com/OleMussmann/incus-compose-update](https://github.com/OleMussmann/incus-compose-update)
(ex-`stack`, extracted 2026-08-05).

Packaged with Nix, not shipped inside the vault repo itself — so nothing
executable lives on a tree that an unattended agent, or untrusted content it
ingests, can write to. Full reasoning:
[`AMENDMENT-1-tooling-repo-split.md`](https://github.com/OleMussmann/vault/blob/main/history/AMENDMENT-1-tooling-repo-split.md)
in the vault's own history.

Public on purpose: these scripts hold no secrets, and a public flake input
needs no auth token or SSH URL on any machine that consumes it.

## Use

```nix
# flake.nix
inputs.vault-tools.url = "github:OleMussmann/vault-tools";
# environment.systemPackages
[ vault-tools.packages.${system}.vault ]
```

Or directly: `nix run github:OleMussmann/vault-tools#vault -- --help`

`vault --help` is the reference — this README only says what the repo is,
not how to use the tool.

## Layout

```
bin/vault             # brief, note, save, check, --version — see the vault's AGENTS.md
flake.nix             # vault: writeShellApplication, pins runtimeInputs, shellchecks at build
                       # vault-portable: same source, shellchecked, no Nix wrapper — see below
                       # vault-hermes: alias for vault-portable, kept one cycle (A3)
vault.example/        # scaffold for a new vault (copy, never edit in place)
HERMES.md             # agent setup prompt for Hermes
skills/vault-save/    # Pi skill: enforce `vault save` over raw git
```

**Two `vault` outputs, for two different environments.** `packages.vault`
(`writeShellApplication`) is for the workstation/Pi — both run NixOS, so a
`/nix/store` shebang and a `runtimeInputs`-pinned `PATH` are correct there,
and the point of `writeShellApplication` (shellcheck at build time) is worth
keeping. `packages.vault-portable` is for any Nix-less target container
(the Hermes container, today), which has no Nix store at all — that shebang
would fail with "not found" before the script ever ran (hit this for real
2026-08-01). It builds from the same `bin/vault` source, still shellchecked,
just installed unwrapped: the source's own shebang (`#!/usr/bin/env bash`)
and `bin/vault`'s own `command -v` preflight (git, sed, grep, rg) stand in
for the wrapper's `PATH` pin, using whatever's already on the target
image's `PATH` — verified present on Hermes. `vault-hermes` is the old name,
now an alias for one cycle; new refs should use `vault-portable`.

**Installing into Hermes is not a plain file push.** `/opt/tools` is
mounted read-only inside `hermes-1`, and the mount mode is a property of
the *instance* — flipping hermes-1's own mount to read-write, even briefly,
would hand the running agent write access to its own tooling for that
window, which defeats the point. The procedure lives in the Hermes stack
repo: `~/code/IncusOS/Hermes/push-vault-to-hermes.sh` — it stops hermes-1,
populates the volume through a disposable helper instance, tears the helper
down, and restarts hermes-1; hermes-1's own mount is never anything but
read-only. Real cost, accepted deliberately: updating `vault` on Hermes
takes longer than a file push. Given there's no update channel and this
happens a few times a year, that trade is fine, but only because the
procedure lives in a script rather than being reconstructed by hand each
time.

No update channel: these change a few times a year, applied by hand
(the deploy script for Hermes, a flake input bump everywhere else).
`vault --version` reports the built commit so drift between machines is
visible rather than silently possible.

## Agent setup

### Hermes

[`HERMES.md`](./HERMES.md) — copy-paste this prompt into Hermes to set up vault access.

### Pi

Pi discovers the shared vault through `~/.pi/agent/AGENTS.md`. Set it up once
and every Pi session picks it up.

1. Create your vault repo using the scaffolding in [`vault.example/`](./vault.example/):
   ```
   cp -r vault.example /path/to/my-vault
   cd /path/to/my-vault
   git init
   git add -A && git commit -m "initial vault scaffold"
   # push to your remote, or keep local
   export VAULT_DIR=/path/to/my-vault
   ```
   Make `VAULT_DIR` persistent (e.g. `~/.bashrc` or equivalent).
   Customize `AGENTS.md` and add your first project under `projects/<slug>/`.

2. Install the `vault` CLI via the flake input or `nix run` — see [Use](#use).

3. Append this vault section to your `~/.pi/agent/AGENTS.md`:

   ```
   ## Vault

   A shared git-backed memory vault covering multiple projects.
   Run `echo $VAULT_DIR` to find it.

   `vault` works globally — no `cd` needed, it reads `VAULT_DIR` from the environment.

   - `vault brief <project>` for full project context in one call.
   - Read the vault's own `AGENTS.md` for the contract (frontmatter schema, write rules).
   - `vault --help` for everything else.

   If `vault` is not on `$PATH`, the vault is still plain markdown:
   find the directory and search it with ripgrep.

   Never create `.pi/skills/` or `.agents/skills/` inside the vault.
   ```

4. (Optional) Create `~/.pi/agent/APPEND_SYSTEM.md` for behavioral policy
   (tool preferences, writing conventions — see the vault's own `AGENTS.md`
   for the full contract).

5. (Recommended) Install the `vault-save` skill to enforce `vault save` over
   raw git commands:
   ```
   mkdir -p ~/.pi/agent/skills/vault-save
   cp skills/vault-save/SKILL.md ~/.pi/agent/skills/vault-save/SKILL.md
   ```
   Without this skill, Pi can bypass the vault CLI by running `git` directly,
   which skips schema validation and the stale-base pull guard.
