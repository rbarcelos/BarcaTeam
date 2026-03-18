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

# ── Create session ────────────────────────────────────────────────────────────
NVM_INIT="export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\" && nvm use --lts --silent"

tmux new-session -d -s "$SESSION" -n "lead"

# Propagate agent teams env var to every pane spawned in this session
tmux set-environment -t "$SESSION" CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1

# ── Global options ────────────────────────────────────────────────────────────
tmux set-option -g mouse on
tmux set-option -g history-limit 200000

# ── Lead window — Claude orchestrator ────────────────────────────────────────
tmux send-keys -t "$SESSION:lead.0" "$NVM_INIT && cd '$TEAM_DIR' && claude $ADD_DIRS" C-m

# ── Agents window — pre-created panes for teammate sessions ──────────────────
# Claude will spawn agent panes here automatically via teamMateMode=tmux
tmux new-window -t "$SESSION" -n "agents"
tmux send-keys -t "$SESSION:agents.0" "echo '=== agent panes will appear here ==='" C-m

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

# Focus back on lead window
tmux select-window -t "$SESSION:lead"
tmux attach -t "$SESSION"
