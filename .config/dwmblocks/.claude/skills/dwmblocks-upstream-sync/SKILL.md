---
name: dwmblocks-upstream-sync
description: Land upstream torrinfail/dwmblocks commits into this customized dwmblocks fork, one at a time and in upstream order. Finds the newest upstream commit already in master by subject, applies the next ones, resolves conflicts, keeps the local blocks.h in step with blocks.def.h, verifies with make, commits each with the upstream subject and refreshes the diff files. Asks before any change that needs a logic or implementation change to the fork.
disable-model-invocation: true
argument-hint: "[empty means every remaining commit, or: status, <commit-id>]"
---

# Sync upstream dwmblocks commits into this fork

This repo (`~/.config/dwmblocks`, branch `master`, remote `origin` = `https://github.com/ornfelt/dwmblocks`)
is a patched dwmblocks. Upstream is `https://github.com/torrinfail/dwmblocks` (not suckless), tracked as the `upstream` remote in this same
repo - no separate clone is used.

## Arguments

- **none** - apply the remaining upstream commits, oldest first, within the per-run budget below.
- `status` - only report the last synced commit and the remaining list. Write nothing.
- `<commit-id>` - apply just that upstream commit.

## 1. Make sure the upstream remote is there and current

```bash
cd ~/.config/dwmblocks
git remote get-url upstream 2>/dev/null || git remote add upstream https://github.com/torrinfail/dwmblocks
git fetch upstream
git status --short -- . ':(exclude).claude'   # must be clean before starting (.claude/ itself is ignored) - otherwise stop and ask
```

## 2. Find where to start

Upstream commits are landed here by hand with **the same subject line** as upstream (e.g.
`bump version to ...`), each usually followed by an `update diff files` commit. Upstream is GitHub-style with
`Merge pull request` commits - skip those (`--no-merges`); their content arrives through the
non-merge commits. Upstream commits are also often already in master's history directly (the fork
was made from upstream), in which case the merge base alone shows they are synced. Otherwise match
on subject:

```bash
BASE=$(git merge-base master upstream/master)
# upstream commits after the merge base, oldest first
git log --reverse --no-merges --format="%h %s" "$BASE..upstream/master"
# subjects already in master
git log --format="%s" "$BASE..master"
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

3. **Conflicts** - the fork carries its own blocks, Makefile flags and compile fixes, so
   conflicts are possible. Resolve them by keeping the fork's customizations and adding upstream's intent on
   top. Prefer upstream's exact wording where the surrounding code still matches.
4. **Ask first** - if landing the commit needs a logic or implementation change to the fork's own
   code (not just a textual merge) - e.g. a patched function has to be restructured, a fork feature
   would behave differently, or upstream's change conflicts with a deliberate customization - stop
   before committing. Explain what the commit does, what would have to change in the fork and why,
   and wait for the user's answer. Leave the tree as it was (`git cherry-pick --abort` or
   `git reset --hard HEAD` after showing the planned change) and do not continue with later commits.
5. **blocks.h** - `blocks.h` is the real, local config but it is gitignored (and `compile.sh`
   edits it temporarily for the battery/internet block). When upstream touches `blocks.def.h`,
   merge the change into the fork's `blocks.def.h` and mirror it into the local `blocks.h` too
   (adapted to the blocks already there). Never commit `blocks.h`.
6. Verify (see below). Fix build errors caused by this commit; report pre-existing ones.
7. Commit using the same commit name and description as upstream - upstream's subject line and
   body (if any), unchanged, so the subject match in step 2 keeps working on later runs:

   ```bash
   git commit -m "<upstream subject>" [-m "<upstream body>"]
   ```

   **Do not add a `Co-Authored-By` trailer** (or any other attribution line) to this commit or to
   the `update diff files` commit - the message is upstream's message and nothing else.

8. Refresh the diff files against the upstream commit just landed (`<sha>`) and commit them:

   ```bash
   git diff <sha> master -- . ":(exclude)*.diff" > diff_upstream.diff
   git add -A "*.diff" && git commit -m "update diff files"
   ```

   Only commit if the diffs actually changed.

Then move on to the next commit. Never squash several upstream commits into one.

## How much per run

Take one upstream commit at a time - one fork commit (plus its `update diff files` commit) per
upstream commit - but keep going through the work list until roughly **1000 changed lines** have
been landed in the run (count the upstream diffs: `git show --numstat <sha>`), or stop earlier at a
logical point: a question for the user, a larger commit that is better done in its own run, or a
group of related commits that has just been completed (e.g. a fix and its follow-up regression
fix). Do not stop in the middle of such a group just because the budget is reached; finish it, then
stop. If nothing is left before the budget is spent, stop there.

Do not push. The user pushes.

## Verification

Build with the `Makefile` (`compile.sh` runs `make clean`, `make` and `sudo make install`). Do not build in place, since
that would replace the user's built binary - build a throwaway copy:

```bash
TMP=$(mktemp -d) && git ls-files -z | xargs -0 cp --parents -t "$TMP" && cp blocks.h "$TMP"/
make -C "$TMP" && echo BUILD OK
rm -rf "$TMP"
```

The build must pass with no new warnings from the changed code. Do not run `make install` or `./compile.sh`
(it runs `sudo make install`); that is the user's call.

## Report

At the end, list per upstream commit: sha, subject, whether it applied cleanly, was merged with
conflicts (and how they were resolved), or was stopped for a question. Include the build result
and the fork commits created. If stopped on a question, name the commit it is waiting on so the
next run starts there.
