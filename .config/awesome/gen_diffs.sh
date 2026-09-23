#! /usr/bin/bash

if ! git rev-parse --verify upstream/master >/dev/null 2>&1; then
    echo "Error: 'upstream/master' does not exist. Please add it..."
    exit 1
fi

git diff upstream/master...master -- . ":(exclude)*.diff" > diff_upstream.diff
git diff origin/bkp -- . ":(exclude)*.diff" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_bkp.diff
git diff origin/tarneaux -- . ":(exclude)*.diff" ":(exclude).gitignore" ":(exclude)patches/**" ":(exclude)patches_git/**" > diff_tarneaux.diff

# claude_usage/ is a vendored copy of an unrelated repo, so it has no remote here
# and git diff cannot reach it. Clone upstream to a temp dir and compare trees.
# The result shows local patches to the vendored copy (ideally none) together with
# whatever upstream has added since it was vendored.
CLAUDE_UPSTREAM="https://github.com/derblub/awesome-claude-usage"
CLAUDE_DIR="claude_usage"

gen_claude_diff() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        echo "Skipping $CLAUDE_DIR: not vendored here."
        return
    fi

    local tmp
    tmp=$(mktemp -d) || return 1
    trap 'rm -rf "$tmp"' RETURN

    if ! git clone -q --depth 1 "$CLAUDE_UPSTREAM" "$tmp/upstream" 2>/dev/null; then
        echo "Skipping $CLAUDE_DIR: could not reach $CLAUDE_UPSTREAM."
        return
    fi

    local head
    head=$(git -C "$tmp/upstream" rev-parse --short HEAD)
    rm -rf "$tmp/upstream/.git"

    # --no-index always exits non-zero when the trees differ; that is not an error.
    git diff --no-index --src-prefix="a/$CLAUDE_DIR/" --dst-prefix="b/$CLAUDE_DIR/" \
        "$tmp/upstream" "$CLAUDE_DIR" > diff_claude_usage.diff
    : # swallow the exit status above so `set -e` users are not surprised

    if [ -s diff_claude_usage.diff ]; then
        echo "$CLAUDE_DIR differs from $CLAUDE_UPSTREAM @ $head (see diff_claude_usage.diff)"
    else
        echo "$CLAUDE_DIR is identical to $CLAUDE_UPSTREAM @ $head"
    fi
}

gen_claude_diff
