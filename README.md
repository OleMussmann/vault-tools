# vault-tools

CLI tooling for the [Hermes/Pi shared memory vault](https://github.com/OleMussmann/vault):
`vault` (read/write the vault) and `stack` (update the Hermes Incus stack).

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
[ vault-tools.packages.${system}.vault vault-tools.packages.${system}.stack ]
```

Or directly: `nix run github:OleMussmann/vault-tools#vault -- --help`

`vault --help` and `stack {check|update}` are the reference — this README
only says what the repo is, not how to use either tool.

## Layout

```
bin/vault    # brief, note, save, check, --version — see the vault's AGENTS.md
bin/stack    # check, update — see IMPLEMENTATION.md in the vault's history/
flake.nix    # writeShellApplication: pins runtimeInputs, shellchecks at build time
```

No update channel: these change a few times a year, applied by hand
(`nix build` + `incus file push` for Hermes, a flake input bump everywhere
else). `vault --version` reports the built commit so drift between machines
is visible rather than silently possible.
