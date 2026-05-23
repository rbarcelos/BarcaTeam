#!/usr/bin/env bash
# BarcaTeam — One-Command Install Script (Linux / macOS)
# Usage: ./scripts/install.sh
#
# Idempotent — safe to re-run at any time.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
pass()  { echo -e "  ${GREEN}[PASS]${NC} $*"; (( PASS_COUNT++ )) || true; }
skip()  { echo -e "  ${YELLOW}[SKIP]${NC} $*"; (( SKIP_COUNT++ )) || true; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $*"; (( FAIL_COUNT++ )) || true; }
info()  { echo -e "  ${CYAN}[INFO]${NC} $*"; }
step()  { echo -e "\n== $* =="; }

PASS_COUNT=0; SKIP_COUNT=0; FAIL_COUNT=0

cmd_exists() { command -v "$1" &>/dev/null; }

echo ""
echo "  ____                    _____                  "
echo " | __ )  __ _ _ __ ___  |_   _|__  __ _ _ __ ___"
echo " |  _ \\ / _' | '__/ __|   | |/ _ \\/ _' | '_ ' _ \\"
echo " | |_) | (_| | | | (__    | |  __/ (_| | | | | | |"
echo " |____/ \\__,_|_|  \\___|   |_|\\___|\\___|_| |_| |_|"
echo ""
echo "  One-Command Install (Linux / macOS)"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Pre-flight checks
# ---------------------------------------------------------------------------
step "Pre-flight checks"

PREFLIGHT_OK=true

# Node >= 20
if cmd_exists node; then
    NODE_VER=$(node --version | tr -d 'v')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        pass "Node.js $NODE_VER (>= 20)"
    else
        fail "Node.js $NODE_VER found but >= 20 required. Upgrade: https://nodejs.org"
        PREFLIGHT_OK=false
    fi
else
    fail "Node.js not found. Install from: https://nodejs.org"
    PREFLIGHT_OK=false
fi

# Python >= 3.11 (optional)
if cmd_exists python3; then
    PY_VER=$(python3 --version | sed 's/Python //')
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MINOR" -ge 11 ]; then
        pass "Python $PY_VER (>= 3.11)"
    else
        skip "Python $PY_VER (< 3.11 — optional, upgrade at https://python.org if needed)"
    fi
else
    skip "python3 not found (optional — needed only for dev-env.sh)"
fi

# gh CLI
if cmd_exists gh; then
    if gh auth status &>/dev/null; then
        pass "GitHub CLI authenticated"
    else
        fail "GitHub CLI found but not authenticated. Run: gh auth login"
    fi
else
    fail "GitHub CLI not found. Install: https://cli.github.com"
    PREFLIGHT_OK=false
fi

# Claude CLI
if cmd_exists claude; then
    CLAUDE_VER=$(claude --version 2>&1 | head -1)
    pass "Claude CLI: $CLAUDE_VER"
else
    info "Claude CLI not found — installing via npm..."
    npm install -g @anthropic-ai/claude-code
    pass "Claude CLI installed"
fi

if [ "$PREFLIGHT_OK" = "false" ]; then
    echo ""
    echo -e "  ${RED}Pre-flight failed. Fix the issues above, then re-run this script.${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 2: tmux (Linux/macOS multiplexer)
# ---------------------------------------------------------------------------
step "tmux (terminal multiplexer)"

if cmd_exists tmux; then
    TMUX_VER=$(tmux -V)
    pass "tmux: $TMUX_VER"
else
    info "tmux not found — installing..."
    if cmd_exists brew; then
        brew install tmux && pass "tmux installed via Homebrew"
    elif cmd_exists apt-get; then
        sudo apt-get install -y tmux && pass "tmux installed via apt"
    elif cmd_exists yum; then
        sudo yum install -y tmux && pass "tmux installed via yum"
    else
        fail "tmux not found and no known package manager available. Install manually: https://github.com/tmux/tmux"
    fi
fi

# ---------------------------------------------------------------------------
# Step 3: claude-ping MCP server (WhatsApp integration)
# ---------------------------------------------------------------------------
step "claude-ping (WhatsApp MCP server)"

CLAUDE_PING_DIR="$REPO_ROOT/claude-ping"
CLAUDE_PING_DIST="$CLAUDE_PING_DIR/dist/mcp/server.js"

if [ -f "$CLAUDE_PING_DIST" ]; then
    skip "claude-ping already built (dist/mcp/server.js exists)"
else
    if [ -f "$CLAUDE_PING_DIR/package.json" ]; then
        info "Installing claude-ping npm deps..."
        cd "$CLAUDE_PING_DIR"
        npm install
        if node -e "require('./package.json').scripts.build" &>/dev/null 2>&1; then
            npm run build
        fi
        cd "$REPO_ROOT"
        pass "claude-ping built"
    else
        fail "claude-ping/package.json not found. Run: git submodule update --init"
    fi
fi

# ---------------------------------------------------------------------------
# Step 4: Verify .mcp.json is in place
# ---------------------------------------------------------------------------
step "MCP server configuration (.mcp.json)"

MCP_JSON="$REPO_ROOT/.mcp.json"
if [ -f "$MCP_JSON" ]; then
    pass ".mcp.json present"
else
    fail ".mcp.json missing. Run: ./scripts/install.ps1 or restore from git."
fi

# ---------------------------------------------------------------------------
# Step 5: Claude plugins (install if missing)
# ---------------------------------------------------------------------------
step "Claude plugins"

REQUIRED_PLUGINS=(
    "context7@claude-plugins-official"
    "playwright@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "typescript-lsp@claude-plugins-official"
    "pyright-lsp@claude-plugins-official"
    "claude-md-management@claude-plugins-official"
    "claude-code-setup@claude-plugins-official"
)

INSTALLED_PLUGINS=$(claude plugin list 2>&1 || true)

for plugin in "${REQUIRED_PLUGINS[@]}"; do
    short="${plugin/@claude-plugins-official/}"
    if echo "$INSTALLED_PLUGINS" | grep -q "$short"; then
        skip "plugin: $plugin (already installed)"
    else
        info "Installing $plugin..."
        claude plugin install "$plugin" 2>&1 || true
        pass "plugin: $plugin installed"
    fi
done

# ---------------------------------------------------------------------------
# Step 6: Doctor verification
# ---------------------------------------------------------------------------
step "Doctor verification"

DOCTOR_SH="$REPO_ROOT/scripts/doctor.sh"
if [ -f "$DOCTOR_SH" ]; then
    bash "$DOCTOR_SH"
else
    skip "doctor.sh not found — skipping"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "==============================================="
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}Install complete — $PASS_COUNT pass, $SKIP_COUNT skip, $FAIL_COUNT FAIL${NC}"
    echo ""
    echo "  Fix the failures above and re-run: ./scripts/install.sh"
    exit 1
elif [ "$SKIP_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}Install complete — $PASS_COUNT pass, $SKIP_COUNT skip, $FAIL_COUNT fail${NC}"
else
    echo -e "  ${GREEN}Install complete — $PASS_COUNT pass, $SKIP_COUNT skip, $FAIL_COUNT fail${NC}"
fi
echo "==============================================="
echo ""
echo "  Next steps:"
echo "    1. Start BarcaTeam against your target repo(s):"
echo "         ./start.ps1 <repo-name-or-path>   # Windows"
echo "         # (or use start.sh / launch.sh on Linux/Mac)"
echo ""
echo "    2. Check install health any time:"
echo "         ./scripts/doctor.sh"
echo ""
echo "    3. Configure WhatsApp (claude-ping):"
echo "         Open a Claude session with BarcaTeam — claude-ping will prompt for QR code."
echo ""
echo "  See CLAUDE.md for advanced configuration."
echo ""
