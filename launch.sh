#!/usr/bin/env bash
# BarcaTeam launcher — starts tmux session and runs claude inside it
# Env vars expected: SESSION, REPOS, RESET, TEAM_DIR

# Bootstrap nvm so WSL-native node/claude takes priority over /mnt/c/
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
    echo "nvm not found — installing..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

if ! nvm which current &>/dev/null 2>&1; then
    echo "Node not found via nvm — installing LTS..."
    nvm install --lts
fi
nvm use --lts --silent

CLAUDE_PATH=$(command -v claude 2>/dev/null || true)
if [ -z "$CLAUDE_PATH" ] || [[ "$CLAUDE_PATH" == /mnt/* ]]; then
    echo "Installing @anthropic-ai/claude-code via WSL-native npm..."
    npm install -g @anthropic-ai/claude-code
fi

CLAUDE_BIN=$(command -v claude)
echo "Using claude: $CLAUDE_BIN"
[[ "$CLAUDE_BIN" == /mnt/* ]] && echo "WARNING: claude resolves to a Windows path — PATH may need fixing" && exit 1

# Build --add-dir flags for extra repos
ADD_DIRS=""
if [ -n "${REPOS:-}" ]; then
    IFS=':' read -ra REPO_PATHS <<< "$REPOS"
    for p in "${REPO_PATHS[@]}"; do
        ADD_DIRS="$ADD_DIRS --add-dir \"$p\""
    done
fi

if [ "${RESET:-0}" = "1" ]; then
    tmux kill-session -t "$SESSION" 2>/dev/null || true
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' already exists — attaching. Use --reset to restart."
    tmux attach -t "$SESSION"
    exit 0
fi

NVM_INIT="export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\" && nvm use --lts --silent"

tmux set-option -g mouse on
tmux set-option -g history-limit 200000

tmux new-session -d -s "$SESSION" -n "lead"
tmux send-keys -t "$SESSION:lead" "$NVM_INIT && cd '$TEAM_DIR' && claude $ADD_DIRS" C-m

tmux attach -t "$SESSION"
