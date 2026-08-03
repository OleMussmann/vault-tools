# Pi vault setup — reference

Pi's access to the shared vault is handled through the global Pi agent config,
not through this repo. This file documents what's configured and where, for
maintenance reference.

## Where it lives

| What | Where |
|------|-------|
| Vault pointer + env facts | `~/.pi/agent/AGENTS.md` — "Run `echo $VAULT_DIR` to find it." |
| Behavioral policy | `~/.pi/agent/APPEND_SYSTEM.md` — split from the vault pointer by "is this a fact about the machine or how Pi should behave." |
| Vault contract (schema, write rules) | `<VAULT_DIR>/AGENTS.md` — the vault's own contract, not duplicated in Pi's config. |

(All three files committed to `github:OleMussmann/pi_config`.)

## How Pi finds the vault

- `VAULT_DIR` is exported in the shell profile (NixOS `environment.sessionVariables` or `~/.bashrc`).
- `vault` CLI is on `$PATH` (installed via NixOS flake input `vault-tools.packages.${system}.vault`).
- `vault brief` pulls at read time and `vault save` pushes at write time — no manual `git pull` needed.

## What's not here

This is NOT a setup prompt (see [`HERMES.md`](./HERMES.md) for the Hermes equivalent).
Pi's vault config was established once in Phase 6 of the `vault-setup` project
and does not need per-instance setup.
