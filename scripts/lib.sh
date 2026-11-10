#!/usr/bin/env bash
# Shared helpers for the patch scripts. Source this, do not run it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../upstream.conf
source "$ROOT/upstream.conf"

# Where the patched upstream tree lives. Override with WORK_DIR=... (e.g. a tmpfs
# to avoid disk wear from builds). Relative paths are relative to the repo root.
WORK_DIR="${WORK_DIR:-$ROOT/work}"
case "$WORK_DIR" in /*) ;; *) WORK_DIR="$ROOT/$WORK_DIR" ;; esac
PATCH_DIR="$ROOT/patches"

# "<patch-dir-name>:<path inside the work dir>". Each is its own git repository
# (jGui is a submodule of ReplayMod), so each gets its own patch series.
REPOS=("replaymod:." "jgui:jGui")

# Applying patches creates commits; give them a stable committer so that it
# works without any git identity configured. Authors come from the patches.
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-ReplayMod-LegacyFabric}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-noreply@users.noreply.github.com}"

repo_name() { echo "${1%%:*}"; }
repo_path() { echo "$WORK_DIR/${1#*:}"; }

# Prints a message and fails if the repo has uncommitted changes or commits that
# were not written back to patches/ with rebuild.sh.
check_clean() {
    local repo="$1" dir applied head
    dir="$(repo_path "$repo")"
    [[ -e "$dir/.git" ]] || return 0 # not checked out yet
    applied="$(git -C "$dir" rev-parse -q --verify refs/patcher/applied || true)"
    [[ -n "$applied" ]] || return 0
    head="$(git -C "$dir" rev-parse HEAD)"
    if [[ -n "$(git -C "$dir" status --porcelain --untracked-files=no --ignore-submodules=all)" ]]; then
        echo "error: uncommitted changes in $(repo_name "$repo") (commit them, then run scripts/rebuild.sh; or pass --force to discard)" >&2
        return 1
    fi
    if [[ "$head" != "$applied" ]]; then
        echo "error: $(repo_name "$repo") has commits that are not in patches/ (run scripts/rebuild.sh, or pass --force to discard)" >&2
        return 1
    fi
}
