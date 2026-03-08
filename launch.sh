#!/usr/bin/env bash
# BarcaTeam tmux workspace launcher (called by start-claude.cmd via WSL)
# Env vars expected: SESSION, REPOS, RESET, TEAM_DIR
#
# Layout:
#   Window 0 "lead"     — Claude agent (full pane)
#   Window N "<repo>"   — one window per repo, 3 panes: logs | tests | ops

# ── Bootstrap nvm so WSL-native node/claude takes priority over /mnt/c/ ──────
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Install nvm if missing
if ! command -v nvm &>/dev/null; then
    echo "nvm not found — installing..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

# Install Node LTS if no WSL-native node exists
if ! nvm which current &>/dev/null 2>&1; then
    echo "Node not found via nvm — installing LTS..."
    nvm install --lts
fi
nvm use --lts --silent

# Install claude if missing or if it still resolves to a Windows path
CLAUDE_PATH=$(command -v claude 2>/dev/null || true)
if [ -z "$CLAUDE_PATH" ] || [[ "$CLAUDE_PATH" == /mnt/* ]]; then
    echo "Installing @anthropic-ai/claude-code via WSL-native npm..."
    npm install -g @anthropic-ai/claude-code
fi

CLAUDE_BIN=$(command -v claude)
echo "Using claude: $CLAUDE_BIN"
[[ "$CLAUDE_BIN" == /mnt/* ]] && echo "WARNING: claude still resolves to a Windows path — PATH may need fixing" && exit 1

# Parse colon-separated $REPOS into an array and build --add-dir flags
ADD_DIRS=""
IFS=':' read -ra REPO_PATHS <<< "$REPOS"
for p in "${REPO_PATHS[@]}"; do
    ADD_DIRS="$ADD_DIRS --add-dir \"$p\""
done

if [ "${RESET:-0}" = "1" ]; then
    tmux kill-session -t "$SESSION" 2>/dev/null || true
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' already exists — attaching. Use --reset to restart with new repos."
    tmux attach -t "$SESSION"
    exit 0
fi

# ── Create session with lead window ──────────────────────────────────────────
NVM_INIT="export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\" && nvm use --lts --silent"

tmux new-session -d -s "$SESSION" -n "lead"
tmux send-keys -t "$SESSION:lead.0" "$NVM_INIT && cd '$TEAM_DIR' && claude --teammate-mode tmux $ADD_DIRS" C-m

# ── One window per repo ───────────────────────────────────────────────────────
for repo_path in "${REPO_PATHS[@]}"; do
    repo_name=$(basename "$repo_path")

    tmux new-window -t "$SESSION" -n "$repo_name"

    # Pane 0: logs (full left column)
    tmux send-keys -t "$SESSION:$repo_name.0" "$NVM_INIT && cd '$repo_path' && echo '=== logs / dev server ==='" C-m

    # Pane 1: tests (top right)
    tmux split-window -h -t "$SESSION:$repo_name"
    tmux send-keys -t "$SESSION:$repo_name.1" "$NVM_INIT && cd '$repo_path' && echo '=== tests / watch ==='" C-m

    # Pane 2: ops shell (bottom right)
    tmux split-window -v -t "$SESSION:$repo_name.1"
    tmux send-keys -t "$SESSION:$repo_name.2" "$NVM_INIT && cd '$repo_path' && echo '=== ops / git ==='" C-m

    tmux select-pane -t "$SESSION:$repo_name.0"
done

# ── Global options ────────────────────────────────────────────────────────────
tmux set-option -g mouse on
tmux set-option -g history-limit 200000

# Focus back on lead window
tmux select-window -t "$SESSION:lead"
tmux attach -t "$SESSION"
