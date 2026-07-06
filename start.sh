#!/usr/bin/env bash
# BarcaTeam Workspace Launcher (GitHub Copilot CLI)
# Usage: ./start.sh <repo1> [repo2] ...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -eq 0 ]; then
    echo "Usage: ./start.sh <repo1> [repo2] ..."
    echo "       repo can be a name (sibling dir or \$HOME/repos/<name>) or a full path"
    exit 1
fi

if ! command -v copilot >/dev/null 2>&1; then
    echo "ERROR: copilot CLI not found on PATH."
    echo "       Run: ./scripts/install.sh"
    echo "       Or:  npm install -g @github/copilot"
    exit 1
fi

resolve_repo_path() {
    local repo="$1"
    local path

    if [[ "$repo" = /* || "$repo" = ~* ]]; then
        path="${repo/#\~/$HOME}"
    else
        local sibling
        sibling="$(cd "$SCRIPT_DIR/.." && pwd)/$repo"
        if [ -d "$sibling" ]; then
            path="$sibling"
        else
            path="$HOME/repos/$repo"
        fi
    fi

    if [ ! -d "$path" ]; then
        echo "ERROR: repo not found at '$path'" >&2
        echo "       Clone it first, e.g.: git clone <url> \"$path\"" >&2
        exit 1
    fi

    cd "$path" && pwd
}

COPILOT_ARGS=()
REPO_PATHS=()
for repo in "$@"; do
    repo_path="$(resolve_repo_path "$repo")"
    REPO_PATHS+=("$repo_path")
    COPILOT_ARGS+=("--add-dir" "$repo_path")
done

printf '\n BarcaTeam — Starting GitHub Copilot CLI\n'
printf ' Repos: %s\n\n' "$(IFS=', '; echo "${REPO_PATHS[*]}")"

cd "$SCRIPT_DIR"
exec copilot "${COPILOT_ARGS[@]}"
