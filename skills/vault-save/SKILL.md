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
   commit → push, and refuses to commit agent configuration
   (`.claude/`, `.pi/`, `.agents/`, `CLAUDE.md`). It does **not**
   validate the schema — see rule 3. This is the only safe write path.

3. **Before `vault save`, run `vault check`** if you made manual
   edits to vault files outside the `vault note`/`vault brief`
   commands. `vault save` does not run it, so this is the only thing
   that catches schema-violating frontmatter before it reaches the
   remote.

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
