#!/usr/bin/env bash
# BarcaTeam — Doctor Script (Linux / macOS)
# Usage: ./scripts/doctor.sh
#
# Audits current install state and reports what's configured, stale, or missing.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}[OK]  ${NC} $*"; (( OK_COUNT++ ))   || true; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $*"; (( WARN_COUNT++ )) || true; }
fail() { echo -e "  ${RED}[FAIL]${NC} $*"; (( FAIL_COUNT++ )) || true; }
fix()  { echo -e "         ${GRAY}Fix: $*${NC}"; }
step() { echo -e "\n== $* =="; }

OK_COUNT=0; WARN_COUNT=0; FAIL_COUNT=0

cmd_exists() { command -v "$1" &>/dev/null; }

echo ""
echo -e "  ${CYAN}BarcaTeam Doctor${NC}"
echo -e "  Repo: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# 1. Core CLIs
# ---------------------------------------------------------------------------
step "Core CLIs"

# Node
if cmd_exists node; then
    NODE_VER=$(node --version | tr -d 'v')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        ok "Node.js $NODE_VER (>= 20)"
    else
        fail "Node.js $NODE_VER found but >= 20 required"
        fix "https://nodejs.org — install LTS"
    fi
else
    fail "Node.js not found"
    fix "https://nodejs.org"
fi

# Python (optional)
if cmd_exists python3; then
    PY_VER=$(python3 --version | sed 's/Python //')
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MINOR" -ge 11 ]; then
        ok "Python $PY_VER (>= 3.11, optional)"
    else
        warn "Python $PY_VER < 3.11 (optional — upgrade at https://python.org)"
    fi
else
    warn "python3 not found (optional — needed only for dev-env.sh)"
fi

# Claude CLI
if cmd_exists claude; then
    CLAUDE_VER=$(claude --version 2>&1 | head -1)
    ok "Claude CLI: $CLAUDE_VER"
else
    fail "Claude CLI not found"
    fix "npm install -g @anthropic-ai/claude-code"
fi

# GitHub CLI
if cmd_exists gh; then
    if gh auth status &>/dev/null; then
        ok "GitHub CLI authenticated"
    else
        fail "GitHub CLI not authenticated"
        fix "gh auth login"
    fi
else
    fail "GitHub CLI not found"
    fix "https://cli.github.com"
fi

# ---------------------------------------------------------------------------
# 2. tmux
# ---------------------------------------------------------------------------
step "tmux (terminal multiplexer)"

if cmd_exists tmux; then
    TMUX_VER=$(tmux -V)
    ok "tmux: $TMUX_VER"
else
    fail "tmux not found"
    if cmd_exists brew;    then fix "brew install tmux"
    elif cmd_exists apt-get; then fix "sudo apt-get install tmux"
    else fix "https://github.com/tmux/tmux"
    fi
fi

# ---------------------------------------------------------------------------
# 3. claude-ping
# ---------------------------------------------------------------------------
step "claude-ping (WhatsApp MCP server)"

CLAUDE_PING_PKG="$REPO_ROOT/claude-ping/package.json"
CLAUDE_PING_DIST="$REPO_ROOT/claude-ping/dist/mcp/server.js"

if [ -f "$CLAUDE_PING_PKG" ]; then
    ok "claude-ping submodule initialised"
    if [ -f "$CLAUDE_PING_DIST" ]; then
        ok "claude-ping built (dist/mcp/server.js)"
    else
        fail "claude-ping not built"
        fix "cd claude-ping && npm install && npm run build"
    fi
else
    fail "claude-ping submodule not initialised"
    fix "git submodule update --init"
fi

# ---------------------------------------------------------------------------
# 4. .mcp.json
# ---------------------------------------------------------------------------
step "MCP configuration (.mcp.json)"

MCP_JSON="$REPO_ROOT/.mcp.json"
if [ -f "$MCP_JSON" ]; then
    if python3 -c "import json,sys; json.load(open('$MCP_JSON'))" &>/dev/null 2>&1 || \
       node -e "JSON.parse(require('fs').readFileSync('$MCP_JSON','utf8'))" &>/dev/null 2>&1; then
        ok ".mcp.json present and valid JSON"
        for server in claude-ping memory; do
            if grep -q "\"$server\"" "$MCP_JSON"; then
                ok ".mcp.json: $server configured"
            else
                fail ".mcp.json: $server server missing"
                fix "Add the $server block — see README.md"
            fi
        done
    else
        fail ".mcp.json invalid JSON"
        fix "Fix the JSON syntax in .mcp.json"
    fi
else
    fail ".mcp.json not found"
    fix "./scripts/install.sh"
fi

# ---------------------------------------------------------------------------
# 5. Claude plugins
# ---------------------------------------------------------------------------
step "Claude plugins"

REQUIRED_PLUGINS=(
    "context7"
    "playwright"
    "pr-review-toolkit"
    "security-guidance"
    "typescript-lsp"
    "pyright-lsp"
    "claude-md-management"
    "claude-code-setup"
)

if cmd_exists claude; then
    INSTALLED=$(claude plugin list 2>&1 || true)
    for plugin in "${REQUIRED_PLUGINS[@]}"; do
        if echo "$INSTALLED" | grep -q "$plugin"; then
            ok "plugin: $plugin"
        else
            fail "plugin: $plugin not installed"
            fix "claude plugin install ${plugin}@claude-plugins-official"
        fi
    done
else
    warn "Claude CLI not found — cannot check plugins"
fi

# ---------------------------------------------------------------------------
# 6. Repo structure
# ---------------------------------------------------------------------------
step "Repo structure"

EXPECTED=(
    "CLAUDE.md"
    "start.ps1"
    ".github/copilot-instructions.md"
    "agents/lead.agent.md"
    ".claude/skills"
    "scripts/install.ps1"
    "scripts/install.sh"
    "scripts/doctor.ps1"
    "scripts/doctor.sh"
)

for f in "${EXPECTED[@]}"; do
    if [ -e "$REPO_ROOT/$f" ]; then
        ok "$f"
    else
        fail "$f missing"
        fix "git checkout origin/master -- $f"
    fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "======================================="
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}Doctor Summary: OK=$OK_COUNT  Warn=$WARN_COUNT  Fail=$FAIL_COUNT${NC}"
    echo ""
    echo "  Run ./scripts/install.sh to fix most issues automatically."
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}Doctor Summary: OK=$OK_COUNT  Warn=$WARN_COUNT  Fail=$FAIL_COUNT${NC}"
    echo ""
    echo "  Minor warnings only — BarcaTeam should work."
else
    echo -e "  ${GREEN}Doctor Summary: OK=$OK_COUNT  Warn=$WARN_COUNT  Fail=$FAIL_COUNT — All checks passed.${NC}"
fi
echo "======================================="
echo ""
