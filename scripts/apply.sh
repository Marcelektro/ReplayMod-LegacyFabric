#!/usr/bin/env bash
# Resets the work dir to the pinned upstream revision and applies patches/ on top.
# Usage: scripts/apply.sh [--force]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

force=0
[[ "${1:-}" == "--force" ]] && force=1

if [[ ! -d "$WORK_DIR/.git" ]]; then
    git clone --no-checkout "$UPSTREAM_URL" "$WORK_DIR"
fi

if (( ! force )); then
    for repo in "${REPOS[@]}"; do check_clean "$repo"; done
fi

cd "$WORK_DIR"
git cat-file -e "$UPSTREAM_COMMIT^{commit}" 2>/dev/null || git fetch -q origin
git checkout -q -f --detach "$UPSTREAM_COMMIT"
git clean -fdq
git submodule update --init --recursive --force -q
git submodule foreach --recursive -q 'git clean -fdq'

for repo in "${REPOS[@]}"; do
    dir="$(repo_path "$repo")"
    git -C "$dir" update-ref refs/patcher/base HEAD
done

for repo in "${REPOS[@]}"; do
    name="$(repo_name "$repo")"; dir="$(repo_path "$repo")"
    shopt -s nullglob
    patches=("$PATCH_DIR/$name"/*.patch)
    shopt -u nullglob
    for p in "${patches[@]}"; do
        echo "applying $name/$(basename "$p")"
        if ! git -C "$dir" am --3way --quiet "$p"; then
            echo "error: $p did not apply. Fix the conflict in $dir, 'git am --continue', then run scripts/rebuild.sh" >&2
            exit 1
        fi
    done
    git -C "$dir" update-ref refs/patcher/applied HEAD
done
echo "done: $WORK_DIR"
