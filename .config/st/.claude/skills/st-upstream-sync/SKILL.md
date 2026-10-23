---
name: st-upstream-sync
description: Land upstream suckless st commits into this customized st fork, one at a time and in upstream order. Every upstream commit after the fork point has a row in UPSTREAM_SYNC.md - pending until looked at, in commit-date order, with its origin (upstream, fork or merge), its handling (as-is, needed or requested) and any special handling or upstream bug flag - and upstream_info.txt names the upstream commit the fork is synced through. Commits that reached upstream from a contributor's fork are landed too, a merge is skipped only when it changes nothing, and the ledger can be rebuilt from master and upstream/master. Applies each commit, resolves conflicts, keeps config.h in step with config.def.h, verifies with make, commits each with the upstream subject, followed by a ledger commit. Does not generate diff files. Asks before any change that needs a logic or implementation change to the fork.
disable-model-invocation: true
argument-hint: "[empty means every remaining commit within the run budget, or: setup, status, rebuild, <commit-id>, skip <commit-id> <reason>, replay <commit-id>]"
---

# Sync upstream st commits into this fork

This repo (`~/.config/st`, branch `master`, remote `origin` = `https://github.com/ornfelt/st`)
is a patched st. Upstream is suckless st, tracked as the `upstream` remote in this same
repo - no separate clone is used.

This skill walks upstream's history forward from the fork point, **one commit at a time**, lands
each commit in `master`, and keeps track of every upstream commit in `UPSTREAM_SYNC.md`.

- **Commits from forks are landed too.** A commit that reaches `upstream/master` only through a
  merge - from a contributor's fork or branch (origin `fork`, see the ledger) - is landed under the
  same rules as one made on upstream's own line. Having come from a fork is never a reason to skip
  it.
- **Merge commits are skipped only when they change nothing.** A merge whose
  `git show --remerge-diff <commit>` (cross-checked with `git show --cc <commit>`) is empty only
  joins its parents, which are rows of their own. A merge that resolved a conflict in code is landed
  like any other commit. Suckless st's history has had no merge after the fork point so far.
- **Every upstream commit after the fork point has a row** in `UPSTREAM_SYNC.md` - landed, skipped,
  waiting on the user's answer, or `pending` (not looked at yet) - so the file always shows what is
  synced and what is not.

## Arguments

- **none** - land the remaining upstream commits, oldest first, within the per-run budget below.
- `setup` - or the ledger does not exist yet: create `UPSTREAM_SYNC.md` with a row for every
  upstream commit after the fork point, filled per "Picking up the current state", update
  `upstream_info.txt`, commit both (see "Committing the ledger"), then continue as **none**.
- `status` - only report the fork point, the high-water mark, the remaining list, the open questions
  and the open "Flagged for upstream" entries. When the ledger disagrees with the tree, report what
  "Picking up the current state" would change. Write nothing.
- `rebuild` - redo the ledger per "Picking up the current state", keeping the notes, Special
  handling entries, flags and open questions of rows the rebuild confirms. A ledger-only run.
- `<commit-id>` - land just that upstream commit, even out of order.
- `skip <commit-id> <reason>` - record the commit as `skipped` without landing it, Handling
  `requested`, with the reason under "Special handling" in the user's words. Use this when the user
  answered "no" to an earlier question.
- `replay <commit-id>` - redo a commit that already has a row, because the earlier attempt was wrong
  or incomplete, or because the user wants a bug flagged for upstream fixed in the fork too. See
  "Replay".

## 1. Make sure the upstream remote is there and current

```bash
cd ~/.config/st
git remote get-url upstream 2>/dev/null || git remote add upstream https://git.suckless.org/st
git fetch upstream
git status --short -- . ':(exclude).claude'   # must be clean before starting (.claude/ itself is ignored) - otherwise stop and ask
```

## 2. The fork point

The fork point is the merge base of `master` and `upstream/master`:

```bash
BASE=$(git merge-base master upstream/master)
```

It is currently **`6009e6e`** - "Clear screen: Fix edge case" (2024-12-06).
Everything at or before it is in the fork by definition and never comes up again. The upstream
commits after it share no merge history with `master`: they are landed here by hand with **the
same subject line** as upstream (e.g. `Disable bracked paste in reset`), each followed by an
`update upstream sync ledger` commit (older ones by an `update diff files` commit). If the merge
base ever moves (upstream was merged into `master`), record the new one in the ledger and say so.

## 3. The ledger

`UPSTREAM_SYNC.md` in the repo root (tracked) is the progress file. Every run reads it first and
updates it last. It is a hint that makes orientation cheap, not the source of truth - the code is.

Setup creates it with this shape:

```markdown
# st upstream sync ledger

Maintained by the `st-upstream-sync` skill. A hint, not the source of truth - the code is.

Upstream: <https://git.suckless.org/st>, `upstream/master`.
Fork point: `6009e6e` - Clear screen: Fix edge case (2024-12-06)
High-water mark: `<sha>` `<subject>` (every row up to and including this one is decided)
Upstream HEAD when last checked: `<sha>` `<subject>` (<date of the run>)
Remaining: `<n>` (`pending` and `asked` rows)

Statuses: `pending` (not looked at yet), `applied` (landed as upstream wrote it, conflicts resolved
the usual way), `adapted` (landed, but reshaped for the fork), `partial` (part landed, part
skipped - the notes say which), `skipped` (a merge that changes nothing, already in the code under
another message, or deliberately not landed), `asked` (waiting on an answer from the user, nothing
written).

Origin: `upstream` (on upstream's own first-parent line), `fork` (reached `upstream/master` only
through a merge - a contributor's fork or branch), `merge` (a merge commit).

Handling: `as-is` (landed as upstream wrote it - textual conflict resolution that keeps the fork's
customizations and the config.h mirror included), `needed` (changed because the fork needed it),
`requested` (changed, or skipped, because the user asked). Anything but `as-is` has an entry under
Special handling.

| # | Date | Commit | Origin | Subject | Status | Handling | Fork commit | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

## Special handling

<one bullet per row whose Handling is not `as-is`: the row and commit, `needed` or `requested`,
what was done differently from upstream's diff, and why - the fork constraint, or the user's request
in their own words>

## Flagged for upstream

<one bullet per evident bug found in a landed commit's own change - see "Upstream bug flags">

## Open questions

<one bullet per `asked` row: the question put to the user and what it is waiting on>
```

Rules for the ledger:

- **One row per upstream commit after the fork point, every one of them** - landed, skipped,
  `asked` or `pending`. Each run first adds `pending` rows for the commits that have none yet:
  `git log --reverse --date-order --format='%h %cs %p | %s' "$BASE..upstream/master"`, minus the
  commits that already have a row.
- **Chronological order, oldest first**: rows are appended in that `--date-order` order - by commit
  date, never a commit before its parent - and existing rows never move. `#` keeps counting up.
  `Date` is the commit date. An old commit that only arrives through a later merge is appended when
  it arrives, so its date can be older than the row above it; that is expected.
- **Origin**: `merge` when the commit has more than one parent; else `upstream` when
  `git rev-list --first-parent "$BASE..upstream/master"` lists it; else `fork`.
- **Handling** as above; `requested` wins over `needed`. A skipped no-change merge is `as-is`. An
  `adapted` or `partial` row always has `needed` or `requested`. Something the user asks for in the
  run is done and documented, never silently folded into the commit.
- `Fork commit` is the short sha of the `master` commit that carries the upstream subject, or `-`.
- The **high-water mark** is the last row before the first row that is still `pending` or `asked`.
  A commit landed out of order (`<commit-id>`) gets its row decided but does not move the mark.
- `Remaining` is the `pending` and `asked` rows, recomputed each run, not carried over.
- The `Notes` column is where the real information lives: conflicts and how they were resolved,
  what was mirrored into config.h, what was reshaped or dropped and why, and `flagged` when the row
  has an entry under "Flagged for upstream".
- A ledger in an older shape is brought to this one by the next run that writes it.
- If the ledger disagrees with `master`, **the tree wins** and the rows concerned are rebuilt per
  "Picking up the current state" in the same run.

### upstream_info.txt

`upstream_info.txt` in the repo root (tracked) names the upstream commit the fork is synced
through - the high-water mark's full hash:

```text
st
  commit <full hash of the high-water mark>
```

It changes whenever the high-water mark moves, and is committed with the ledger.

### Picking up the current state

The ledger can be rebuilt from `master` and `upstream/master` - on setup, in `rebuild` mode, and
whenever the ledger is missing rows, has a row for a commit not in `$BASE..upstream/master`, or
disagrees with the code (a commit landed by hand, a lost or hand-edited ledger). For each upstream
commit after the fork point, in ledger order, with origin as above:

1. **An earlier sync**: `git log --format='%h %s' -F --grep='<upstream subject>' "$BASE..master"`
   finds the fork commit that carries the same subject. Found: `applied` (or `adapted` / `partial`
   with `needed` when the fork commit's diff differs from upstream's beyond conflict resolution),
   naming that fork commit.
2. **Already in the code**: with no such commit, check the change against `master`'s code, by
   intent, not by text - the fork's patches may have reshaped the code around it. All of it in:
   `skipped`, noting `already in the code (<how found>)`. Part of it: `pending` with a note saying
   which part is there, and the run that takes it lands the rest. None: `pending`.
3. **A no-change merge**: `skipped (merge, changes nothing)`.

Recompute the high-water mark, `Remaining` and `upstream_info.txt` from the rows. Say in the report
how many rows this added or changed and which commits were found already synced.

## 4. Land each commit, in order

The work list is the ledger's `pending` rows, oldest first (for `<commit-id>`, just that commit).
If nothing is left, say the fork is caught up and stop.

For each commit in the work list:

1. Read it first: `git show <sha>`. A merge is read with `git show --remerge-diff <sha>` (and
   `--cc`): empty, it is `skipped (merge, changes nothing)` and needs no commit of its own;
   otherwise that resolution is the change, landed by hand in the next steps.
2. **Upstream bug flags** - while reading, check the commit's **own change** (not the code around
   it) for an evident, reproducible bug: a crash, an out-of-bounds access, a leak, a wrong
   condition, a value used before it is set, behavior that contradicts the commit's own message.
   Style and "I would have done it differently" are not bugs. When there is one:
   - land the commit **exactly as upstream wrote it** anyway, and carry on with the run;
   - add an entry under "Flagged for upstream": the row and commit, the file and function, what goes
     wrong, a repro, the suggested fix, where a patch belongs (upstream suckless st - a patch to
     hackers@suckless.org - or this fork when it only bites the fork's own code around the change),
     and the decision, `open` until the user decides. Put `flagged` in the row's notes;
   - when the user wants the fork fixed too, `replay <commit>` lands the fix (see "Replay").
3. Apply it without committing, so the commit gets the fork's author and message:

   ```bash
   git cherry-pick -n <sha>
   ```

4. **Conflicts** - the fork carries several patches (alpha, ligatures, scrollback, changealpha,
   externalpipe, workingdir, quickselect), so conflicts are expected. Resolve them by keeping
   the fork's customizations and adding upstream's intent on top. Prefer upstream's exact wording
   where the surrounding code still matches. That is routine (`as-is`); a hunk that has to be
   reshaped, moved into the fork's patched code or dropped is `needed`.
5. **Ask first** - if landing the commit needs a logic or implementation change to the fork's own
   code (not just a textual merge) - e.g. a patched function has to be restructured, a fork feature
   would behave differently, or upstream's change conflicts with a deliberate customization - stop
   before committing. Explain what the commit does, what would have to change in the fork and why,
   with a recommended path, and wait for the user's answer. Leave the tree as it was
   (`git cherry-pick --abort` or `git reset --hard HEAD` after showing the planned change), record
   the row as `asked` with the question under "Open questions", and do not continue with later
   commits. Landing it after a "yes" is `requested`.
6. **config.h** - `config.h` is tracked and is the fork's real config. When upstream touches
   `config.def.h`, mirror the same change into `config.h` too (adapted to the values already
   there). `config.mk` version bumps are taken as-is.
7. Verify (see below). Fix build errors caused by this commit; report pre-existing ones.
8. Commit using the same commit name and description as upstream - upstream's subject line and
   body (if any), unchanged, so the subject match in "Picking up the current state" keeps working:

   ```bash
   git commit -m "<upstream subject>" [-m "<upstream body>"]
   ```

   **Do not add a `Co-Authored-By` trailer** (or any other attribution line) to this commit or to
   the `update upstream sync ledger` commit - the message is upstream's message and nothing else. The ledger
   is **not** part of this commit: edit `UPSTREAM_SYNC.md` and `upstream_info.txt` only after it
   exists, so they are never staged into it.

9. Record the commit in the ledger and commit it. **Do not generate diff files** - no `*.diff`
   refresh; the user does not want this skill to run it.

   ```bash
   # fill in the row (status, origin, handling, fork commit, notes), add its Special handling /
   # Flagged for upstream entries, add pending rows for new upstream commits, move the high-water
   # mark and update upstream_info.txt when it moved
   git add UPSTREAM_SYNC.md upstream_info.txt && git commit -m "update upstream sync ledger"
   ```

Then move on to the next commit. Never squash several upstream commits into one.

### Committing the ledger

The ledger and `upstream_info.txt` are committed in the `update upstream sync ledger` commit after
each landed commit (step 9). A run that changes them without landing a commit - a skipped no-change
merge, a commit already in the code, `skip`, `asked`, `setup`, `rebuild` - commits them the same
way on their own:

```bash
git add UPSTREAM_SYNC.md upstream_info.txt && git commit -m "update upstream sync ledger"
```

When such decisions come before a landed commit in the same run, fold them into that commit's
ledger commit instead. No attribution trailer.

### Replay

`replay <commit>` never rewrites a commit already in `master` (it may be pushed). For a landed
commit, the correction - the rest of a `partial` commit, a wrong conflict resolution, or the fix for
a bug flagged for upstream that the user wants in the fork too - is a new fork commit on top, named
for what it does and the upstream commit it follows up (e.g.
`st.c: <what was fixed> (follow-up to upstream <short sha>)`), verified like any other,
followed by the ledger commit. The existing row is updated in place, never duplicated: Handling becomes
`requested` when the user asked for it, the Special handling entry says what was redone and quotes
the request, and a flag the replay settles records the user's decision. For a commit that is not
landed yet (`asked`, `skipped`), replay just lands it per section 4.

## How much per run

Take one upstream commit at a time - one fork commit (plus its ledger commit) per
upstream commit - but keep going through the work list until roughly **1000 changed lines** have
been landed in the run (count the upstream diffs: `git show --numstat <sha>`), or stop earlier at a
logical point: a question for the user, a larger commit that is better done in its own run, or a
group of related commits that has just been completed (e.g. a fix and its follow-up regression
fix). Do not stop in the middle of such a group just because the budget is reached; finish it, then
stop. If nothing is left before the budget is spent, stop there.

Do not push. The user pushes.

## Verification

The only build script is the `Makefile`. The existing `*.o` files and binaries are owned by root
(from `sudo make install`), so do not build in place - build a throwaway copy:

```bash
TMP=$(mktemp -d) && git ls-files -z | xargs -0 cp --parents -t "$TMP"
make -C "$TMP" && echo BUILD OK
rm -rf "$TMP"
```

The build must pass with no new warnings from the changed code. Do not run `make install`; that
needs root and is the user's call.

## Report

At the end, list per upstream commit: sha, date, origin, subject, the status and handling, whether
it applied cleanly or was merged with conflicts (and how they were resolved), or was stopped for a
question. Give any "Flagged for upstream" entry with its repro and suggested fix, for the user to
decide on, and any special handling with its reason. Say how many `pending` rows were added and
which rows a rebuild or a disagreement with the tree changed. Include the build result, the fork
commits created, the new high-water mark and `upstream_info.txt`, and how many rows remain. If
stopped on a question, name the commit it is waiting on so the next run starts there.
