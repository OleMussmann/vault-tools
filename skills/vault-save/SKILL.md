---
name: vault-save
description: >
  Enforce `vault save` for all writes to the shared git-backed vault.
  Trigger: any write intent (edit, write, move, delete) inside the
  $VAULT_DIR directory tree. Prevents the stale-base overwrites and
  conflict-marker commits that bypassing the vault CLI would cause.
---

# vault-save — Always use `vault save`, never raw git

The vault at `$VAULT_DIR` is a shared, git-backed memory store
accessed through the `vault` CLI. Writing directly with `git`
bypasses critical guards and WILL corrupt shared state.

## Rules

1. **Never run `git add`, `git commit`, or `git push`** on any repo
   under `$VAULT_DIR`. The `bash` tool will happily run them; you
   must not.

2. **Always use `vault save "<msg>"`** to commit and push vault
   changes. It does: pull (stale-base and conflict guard) → add →
   schema validation → commit → push, refuses to commit agent
   configuration (`.claude/`, `.pi/`, `.agents/`, `CLAUDE.md`), and
   refuses messages that look like flags (`vault save --help` is usage,
   never a commit). This is the only safe write path.

3. **Schema violations block the save automatically** (since
   vault-tools 2026-10-16): `vault save` runs `vault check` and refuses
   to commit when it fails, printing the offending files. A separate
   manual `vault check` is still useful after edits to catch problems
   early, but it is no longer the only line of defence.

4. **If `vault save` fails** with a stale-base or conflict message,
   read the error carefully and follow its instructions. Do not
   retry with raw `git` commands.

## Before (broken — do not do this)

```
cd $VAULT_DIR
git add -A
git commit -m "stuff"
git push
```

This skips the pull (stale-base write risk), skips the refusal of
agent configuration, and bypasses the error-handling that
`vault save` provides for conflicts.

## After (correct)

```
vault save "short description of what changed"
```

## When this skill is unavailable

If `vault` is not on PATH, the vault is unreachable — do not fall
back to raw git. Report that `vault` CLI is missing and stop.
