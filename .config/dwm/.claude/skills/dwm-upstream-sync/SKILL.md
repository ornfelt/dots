---
name: dwm-upstream-sync
description: Land upstream suckless dwm commits into this customized dwm fork, one at a time and in upstream order. Finds the newest upstream commit already in master by subject, applies the next ones, resolves conflicts, keeps config.h in step with config.def.h, verifies with make, commits each with the upstream subject and refreshes the diff files. Asks before any change that needs a logic or implementation change to the fork.
disable-model-invocation: true
argument-hint: "[empty means every remaining commit, or: status, <commit-id>]"
---

# Sync upstream dwm commits into this fork

This repo (`~/.config/dwm`, branch `master`, remote `origin` = `https://github.com/ornfelt/dwm`)
is a heavily patched dwm. Upstream is suckless dwm, tracked as the `upstream` remote in this same
repo - no separate clone is used.

## Arguments

- **none** - apply every remaining upstream commit, oldest first.
- `status` - only report the last synced commit and the remaining list. Write nothing.
- `<commit-id>` - apply just that upstream commit.

## 1. Make sure the upstream remote is there and current

```bash
cd ~/.config/dwm
git remote get-url upstream 2>/dev/null || git remote add upstream https://git.suckless.org/dwm
git fetch upstream
git status --short   # must be clean before starting - otherwise stop and ask
```

## 2. Find where to start

Upstream commits are landed here by hand with **the same subject line** as upstream (e.g.
`drw.c: drw_scm_free: call free inside`), each usually followed by an `update diff files` commit.
There is no shared merge history for them, so match on subject:

```bash
BASE=$(git merge-base master upstream/master)
# upstream commits after the merge base, oldest first
git log --reverse --format='%h %s' "$BASE..upstream/master"
# subjects already in master
git log --format='%s' "$BASE..master"
```

The newest upstream commit whose subject appears in master is the last synced one; everything
after it on `upstream/master` is the work list, in order. If an upstream commit's subject is
missing but its change is clearly already in the code (applied under another message), treat it
as synced and say so. If nothing remains, say the fork is caught up and stop.

## 3. Apply each commit, in order

For each commit in the work list:

1. Read it first: `git show <sha>`.
2. Apply it without committing, so the commit gets the fork's author and message:

   ```bash
   git cherry-pick -n <sha>
   ```

3. **Conflicts** - the fork carries many patches (vanitygaps, scratchpads, swallow, xresources,
   multi-monitor fixes, ...), so dwm.c and drw.c conflicts are expected. Resolve them by keeping
   the fork's customizations and adding upstream's intent on top. Prefer upstream's exact wording
   where the surrounding code still matches.
4. **Ask first** - if landing the commit needs a logic or implementation change to the fork's own
   code (not just a textual merge) - e.g. a patched function has to be restructured, a fork feature
   would behave differently, or upstream's change conflicts with a deliberate customization - stop
   before committing. Explain what the commit does, what would have to change in the fork and why,
   and wait for the user's answer. Leave the tree as it was (`git cherry-pick --abort` or
   `git reset --hard HEAD` after showing the planned change) and do not continue with later commits.
5. **config.h** - `config.h` is tracked and is the fork's real config. When upstream touches
   `config.def.h`, mirror the same change into `config.h` too (adapted to the values already
   there). `config.mk` version bumps are taken as-is.
6. Verify (see below). Fix build errors caused by this commit; report pre-existing ones.
7. Commit with upstream's subject (and body, if any), unchanged:

   ```bash
   git commit -m "<upstream subject>"
   ```

8. Refresh the diff files and commit them:

   ```bash
   ./gen_diffs.sh
   git add -A '*.diff' && git commit -m "update diff files"
   ```

   Only commit if the diffs actually changed.

Then move on to the next commit. Never squash several upstream commits into one.

Do not push. The user pushes.

## Verification

The only build script is the `Makefile`. The existing `*.o` files and `dwm` binary are owned by
root (from `sudo make install`), so do not build in place - build a throwaway copy:

```bash
TMP=$(mktemp -d) && git ls-files -z | xargs -0 cp --parents -t "$TMP" && cp config.h "$TMP"/
make -C "$TMP" && echo BUILD OK
rm -rf "$TMP"
```

The build must pass with no new warnings from the changed code. Do not run `make install`; that
needs root and is the user's call.

## Report

At the end, list per upstream commit: sha, subject, whether it applied cleanly, was merged with
conflicts (and how they were resolved), or was stopped for a question. Include the build result
and the fork commits created. If stopped on a question, name the commit it is waiting on so the
next run starts there.
