#!/usr/bin/env bash
# BarcaTeam — WSL-native launcher
# Usage: ./start.sh [--reset] [--session <name>] <repo1> [repo2] ...
#
# Repo args can be:
#   - a name     : investFlorida.ai        → expands to ~/repos/investFlorida.ai
#   - a path     : ~/repos/investFlorida.ai or /mnt/c/...  → used as-is
#
# Examples:
#   ./start.sh investFlorida.ai str_simulation
#   ./start.sh --session mywork investFlorida.ai
#   ./start.sh --reset investFlorida.ai str_simulation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION=barcateam
RESET=0

if [ $# -eq 0 ]; then
    echo "Usage: ./start.sh [--reset] [--session <name>] <repo1> [repo2] ..."
    echo "       repo can be a name (expanded to ~/repos/<name>) or a full path"
    exit 1
fi

if [ "$1" = "--reset" ]; then
    RESET=1
    shift
fi

if [ "${1:-}" = "--session" ]; then
    SESSION="$2"
    shift 2
fi

if [ $# -eq 0 ]; then
    echo "Error: at least one repo required."
    exit 1
fi

# Resolve repo args to absolute paths
REPOS=""
for arg in "$@"; do
    if [[ "$arg" == /* ]] || [[ "$arg" == ~* ]]; then
        # Already an absolute or home-relative path
        path="${arg/#\~/$HOME}"
    else
        # Treat as repo name under ~/repos/
        path="$HOME/repos/$arg"
    fi

    if [ ! -d "$path" ]; then
        echo "ERROR: repo not found at '$path'"
        echo "       Clone it first: git -C ~/repos clone git@github.com:rbarcelos/$arg"
        exit 1
    fi

    if [ -z "$REPOS" ]; then REPOS="$path"; else REPOS="$REPOS:$path"; fi
done

echo ""
echo " BarcaTeam — Starting agent orchestration hub..."
echo " Session: $SESSION"
echo " Repos: $REPOS"
[ "$RESET" = "1" ] && echo " Mode: --reset (existing session will be killed)"
echo ""

SESSION="$SESSION" REPOS="$REPOS" RESET="$RESET" TEAM_DIR="$SCRIPT_DIR" bash "$SCRIPT_DIR/launch.sh"
