Set up my Hermes side of the shared vault. Do everything below and confirm when done.

1. Ensure a `vault` skill exists (pointer, not a copy of the contract).
   Load the existing skill with `skill_view(name='vault')`. If it exists and
   already contains the RULES section (lines with "ALWAYS use `vault save`"),
   skip this step. If it's missing or outdated, create/patch a skill named
   `vault`, category `productivity`. Its purpose: teach Hermes how to use the
   shared git-backed memory vault. Its body must be a pointer, NOT duplicated
   contract text — the schema and write rules live in `<VAULT_DIR>/AGENTS.md`,
   and I don't want two copies that drift. Content:

```markdown
---
name: vault
description: Use the shared git-backed vault. Read AGENTS.md first.
---

The shared vault is a git repo of markdown files shared with the Pi coding agent and User.
The authoritative contract (frontmatter schema, write scope, conflict policy, read protocol)
is in `<VAULT_DIR>/AGENTS.md` — **read it before reading or writing the vault**.
Do not copy or summarize it; point to it.

## ⚠️ RULES
 
1. **ALWAYS use `vault save` after editing vault files.** Never use raw `git add`/`git commit`/`git push`. The vault CLI handles pull, stash, rebase, conflict detection, and push atomically. Raw git bypasses all of this.
 
2. **NEVER use `write_file` to create vault content.** Use `vault note` for new files from templates, or `patch`/`read_file` for edits. Then `vault save`.
 
3. **On git conflict: STOP and REPORT.** Never resolve conflicts yourself. The vault CLI detects and aborts cleanly; raw git does not.
 
## CLI

The `vault` CLI is NOT on `$PATH`. It is a portable build at `/opt/tools/vault`
(read-only `hermes-tools` volume; `/opt/tools` is unlistable as `hermes` but the binary runs).
All real subcommands require `VAULT_DIR` set. Usage:

    export VAULT_DIR=/opt/data/vault
    /opt/tools/vault brief <project>              # full project context in one call
    /opt/tools/vault note <project> <type> "<title>"   # from a template
    /opt/tools/vault check                        # validate against the schema
    /opt/tools/vault save "<msg>"                 # add, commit, push (atomic)
    /opt/tools/vault --version | --help

## Workflow
 
1. **Read:** `vault brief <project>` (pulls automatically)
2. **Create:** `vault note <project> <type> "<title>"` (creates from template with frontmatter)
3. **Edit:** Use `patch` or `read_file` + `write_file` on the created file
4. **Persist:** `vault save "<msg>"` IMMEDIATELY after any edit — this is not optional
 
Types: `plan` | `log` | `note` | `decision` — see AGENTS.md for the frontmatter contract.
```

2. Save a memory note. Add one line to your memory (environment facts):
   "Vault shared with Pi/User is markdown+git at `/opt/data/vault`. CLI at
   `/opt/tools/vault` (read-only volume), needs `VAULT_DIR=/opt/data/vault`
   set. ALWAYS use `vault save` after edits (not raw git). Use `vault note`
   to create from templates. Contract in `<VAULT_DIR>/AGENTS.md`."
   If a similar entry already exists, replace it — don't append a duplicate.

3. Confirm. When done, show me the skill file path, its first 5 lines, and the
   memory note you saved. Do not modify anything in `/opt/data/vault` itself.
