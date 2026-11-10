#!/usr/bin/env bash
# Writes the commits in the work dir (on top of the pinned upstream) back to patches/.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for repo in "${REPOS[@]}"; do
    name="$(repo_name "$repo")"; dir="$(repo_path "$repo")"
    if [[ -n "$(git -C "$dir" status --porcelain --untracked-files=no --ignore-submodules=all)" ]]; then
        echo "error: uncommitted changes in $name; commit them first" >&2
        exit 1
    fi
    base="$(git -C "$dir" rev-parse refs/patcher/base)"
    out="$PATCH_DIR/$name"
    mkdir -p "$out"
    rm -f "$out"/*.patch
    git -C "$dir" -c core.abbrev=10 format-patch --quiet --no-stat --no-numbered \
        --no-signature --zero-commit -o "$out" "$base..HEAD"
    if grep -lq '^Subproject commit' "$out"/*.patch 2>/dev/null; then
        echo "error: a $name patch changes a submodule pointer (git add -A picked up a patched submodule?). Patch the submodule through its own series instead." >&2
        exit 1
    fi
    git -C "$dir" update-ref refs/patcher/applied HEAD
    echo "$name: $(ls "$out"/*.patch 2>/dev/null | wc -l) patch(es)"
done
