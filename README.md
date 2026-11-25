# vault-tools

`vault`, the CLI for a shared memory vault: a git repo of Markdown files that
several agents and humans read and write (see [`vault.example/`](./vault.example/)).

Kept in its own repo, not inside the vault — so nothing executable lives on a
tree that an unattended agent, or untrusted content it ingests, can write to.

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

### Without Nix

`bin/vault` is a single Bash script. It needs `bash`, `git`, `sed`, `grep` and
`rg` (ripgrep) on `PATH`, and checks for them at startup. The source carries
two placeholders, `@VAULT_TOOLS_REV@` and `@VAULT_TOOLS_DATE@`, that the
Nix build fills in; install it with them filled in from a checkout:

```
git clone https://github.com/OleMussmann/vault-tools && cd vault-tools
sed -e "s/@VAULT_TOOLS_REV@/$(git rev-parse HEAD)/" \
    -e "s/@VAULT_TOOLS_DATE@/$(TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%d%H%M%S)/" \
    bin/vault > ~/.local/bin/vault
chmod +x ~/.local/bin/vault
```

Copying `bin/vault` unfilled also runs, but `vault --version` then prints the
placeholders and the `.tools-version` check (below) is silently skipped.
To update, `git pull` and repeat the `sed` step.

`vault --help` is the reference — this README only says what the repo is,
not how to use the tool.

## Layout

```
bin/vault             # brief, note, save, check, --version — see the vault's AGENTS.md
flake.nix             # vault: writeShellApplication, pins runtimeInputs, shellchecks at build
                       # vault-portable: same source, shellchecked, no Nix wrapper — see below
vault.example/        # scaffold for a new vault (copy, never edit in place)
HERMES.md             # agent setup prompt for Hermes
skills/vault-save/    # Pi skill: enforce `vault save` over raw git
```

**Two `vault` outputs, for two different environments.** `packages.vault`
(`writeShellApplication`) is for machines with Nix: a `/nix/store` shebang
and a `runtimeInputs`-pinned `PATH` are correct there, and shellcheck runs
at build time. `packages.vault-portable` is for Nix-less targets such as a
container image, where that shebang would fail with "not found" before the
script ever ran. It builds from the same `bin/vault` source, still
shellchecked, just installed unwrapped: the source's own shebang
(`#!/usr/bin/env bash`) and `bin/vault`'s own `command -v` preflight (git,
sed, grep, rg) stand in for the wrapper's `PATH` pin, using whatever is on
the target's `PATH`.

**Install the CLI read-only for any agent that writes to the vault.** An
agent must not be able to modify its own `vault`: install it where the
agent has no write access (e.g. a read-only mount in its container), and
update it from outside — never by making that location writable from inside
the agent's environment.

No update channel: these change a few times a year, applied by hand
(a flake input bump, or rebuilding and redeploying `vault-portable`).
`vault --version` reports the built commit and its commit time.

**Out-of-date builds warn.** A vault may carry a `.tools-version` file
(`vault.example/` ships one, set to the build its `AGENTS.md` describes): the
oldest vault-tools build it relies on, as a commit time `YYYYmmddHHMMSS`
(UTC). Every `vault` command compares its own build time against it and
prints a warning when it is older, so a stale install shows up wherever
`vault` is used — including on Hermes, which cannot update itself but can
report the warning. After pushing a change the vault depends on (a fix, a new
behaviour — not every commit), raise the minimum to that commit's time and
save it:

```
TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%d%H%M%S > "$VAULT_DIR/.tools-version"
vault save "require vault-tools <short rev>"
```

(run in the vault-tools checkout, on the pushed commit). The value matches
the flake's `lastModifiedDate`, which is what builds report.

**Agent configuration is kept out of the vault.** Agents that can write to
the vault must not be able to plant configuration for another agent:
`.claude/`, `.pi/` and `.agents/` directories and `CLAUDE.md` /
`CLAUDE.local.md` files, at any depth. `vault save` refuses to commit new or
changed files there (removing them is allowed), `vault brief` and `vault save`
warn after pulling if any are tracked, and `vault check` fails. Untracked
local files are not affected — they never reach another machine.

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
   - `vault brief <tag>` for the projects carrying that tag (e.g. `work`).
   - Read the vault's own `AGENTS.md` for the contract (frontmatter schema, write rules).
   - `vault --help` for everything else.

   If `vault` is not on `$PATH`, the vault is still plain markdown:
   find the directory and search it with ripgrep.

   Never create agent configuration inside the vault: no `.claude/`, `.pi/`
   or `.agents/` directories, no `CLAUDE.md`.
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
