# Hermes setup

Hermes has no global instructions file for this (`~/.hermes/SOUL.md` is for
personality and tone), so the vault pointer goes into a Hermes skill plus a
memory entry. The prompt below makes Hermes create both itself.

Before pasting, replace the two placeholders everywhere in the prompt:

| Placeholder | Meaning | Local Hermes | Hermes on a server, tools on a read-only mount |
|---|---|---|---|
| `<VAULT_DIR>` | the vault clone, as Hermes sees it | e.g. `~/vault` | e.g. `/opt/data/vault` |
| `<VAULT_CLI>` | how Hermes runs `vault` | `vault` (on `PATH`) | e.g. `/opt/tools/vault` |

Either way, install the CLI where Hermes cannot write to it (see the
README). The skill sets `VAULT_DIR` on every call, so it does not depend on
Hermes passing environment variables through to its terminal tool.

## Prompt

~~~~markdown
Set up my Hermes side of the shared vault. Do everything below and confirm when done.

1. Ensure a `vault` skill exists (pointer, not a copy of the contract).
   Load the existing skill with `skill_view(name='vault')`. If it exists and
   already contains the RULES section (lines with "ALWAYS use `vault save`")
   and the paths below, skip this step. If it's missing or outdated,
   create/patch a skill named `vault`, category `productivity`. Its purpose:
   teach Hermes how to use the shared git-backed memory vault. Its body must
   be a pointer, NOT duplicated contract text — the schema and write rules
   live in `<VAULT_DIR>/AGENTS.md`, and I don't want two copies that drift.
   Content:

```markdown
---
name: vault
description: Use the shared git-backed vault. Read AGENTS.md first.
---

The shared vault is a git repo of markdown files shared with other agents and humans.
The authoritative contract (frontmatter schema, write scope, conflict policy, read protocol)
is in `<VAULT_DIR>/AGENTS.md` — **read it before reading or writing the vault**.
Do not copy or summarize it; point to it.

## ⚠️ RULES

1. **ALWAYS use `vault save` after editing vault files.** Never use raw `git add`/`git commit`/`git push`. The vault CLI handles pull, stash, rebase, conflict detection, and push atomically. Raw git bypasses all of this.

2. **NEVER use `write_file` to create vault content.** Use `vault note` for new files from templates, or `patch`/`read_file` for edits. Then `vault save`.

3. **On git conflict: STOP and REPORT.** Never resolve conflicts yourself. The vault CLI detects and aborts cleanly; raw git does not.

4. **Never modify the `vault` CLI itself**, and never create agent configuration inside the vault (`.claude/`, `.pi/`, `.agents/`, `CLAUDE.md`).

## CLI

Run the CLI as `<VAULT_CLI>`. All real subcommands require `VAULT_DIR`; set it in
the same command:

    export VAULT_DIR=<VAULT_DIR>
    <VAULT_CLI> brief [project|tag]                # full project context, or the list for one tag
    <VAULT_CLI> note <project> <type> "<title>"    # from a template
    <VAULT_CLI> check                              # validate against the schema
    <VAULT_CLI> save "<msg>"                       # add, commit, push (atomic)
    <VAULT_CLI> --version | --help

## Workflow

1. **Read:** `vault brief <project>` (pulls automatically)
2. **Create:** `vault note <project> <type> "<title>"` (creates from template with frontmatter)
3. **Edit:** Use `patch` or `read_file` + `write_file` on the created file
4. **Persist:** `vault save "<msg>"` IMMEDIATELY after any edit — this is not optional

Types: `plan` | `log` | `note` | `decision` — see AGENTS.md for the frontmatter contract.
```

2. Save a memory note. Add one line to your memory (environment facts):
   "Shared vault is markdown+git at `<VAULT_DIR>`. CLI is `<VAULT_CLI>`, needs
   `VAULT_DIR=<VAULT_DIR>` set. ALWAYS use `vault save` after edits (not raw
   git). Use `vault note` to create from templates. Contract in
   `<VAULT_DIR>/AGENTS.md`."
   If a similar entry already exists, replace it — don't append a duplicate.

3. Confirm. When done, show me the skill file path, its first 5 lines, and the
   memory note you saved. Do not modify anything in `<VAULT_DIR>` itself.
~~~~
