Set up my Hermes side of the shared vault. Do everything below and confirm when done.

1. Create a `vault` skill (pointer, not a copy of the contract).
   Create a skill named `vault`, category `productivity`. Its purpose: teach
   Hermes how to use the shared git-backed memory vault. Its body must be a
   pointer, NOT duplicated contract text — the schema and write rules live in
   `<VAULT_DIR>/AGENTS.md`, and I don't want two copies that drift. Content:

```markdown
---
name: vault
description: Use the shared git-backed vault. Read AGENTS.md first.
---

The shared vault is a git repo of markdown files shared with the Pi coding agent and Ole.
The authoritative contract (frontmatter schema, write scope, conflict policy, read protocol)
is in `<VAULT_DIR>/AGENTS.md` — **read it before reading or writing the vault**.
Do not copy or summarize it; point to it.

The `vault` CLI is NOT on `$PATH`. It is a portable build at `/opt/tools/vault`
(read-only `hermes-tools` volume; `/opt/tools` is unlistable as `hermes` but the binary runs).
All real subcommands require `VAULT_DIR` set. Usage:

    export VAULT_DIR=/opt/data/vault
    /opt/tools/vault brief <project>              # full project context in one call
    /opt/tools/vault note <project> <type> "<title>"   # from a template
    /opt/tools/vault check                        # validate against the schema
    /opt/tools/vault save "<msg>"                 # add, commit, push (atomic)
    /opt/tools/vault --version | --help

On a git conflict, stop and report — never resolve.
```

2. Save a memory note. Add one line to your memory (environment facts):
   "Vault shared with Pi/Ole is markdown+git at `/opt/data/vault`. CLI not on
   `$PATH`: `/opt/tools/vault` (read-only volume), needs `VAULT_DIR=/opt/data/vault`
   set. Contract in `<VAULT_DIR>/AGENTS.md`. Subcommands as in the `vault` skill."

3. Confirm. When done, show me the skill file path, its first 5 lines, and the
   memory note you saved. Do not modify anything in `/opt/data/vault` itself.
