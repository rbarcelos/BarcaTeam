#!/usr/bin/env bash
# BarcaTeam — One-Command Install Script (Linux / macOS)
# Usage: ./scripts/install.sh
# Idempotent — safe to re-run at any time.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_AGENTS=32
EXPECTED_SKILLS=21

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
pass()  { echo -e "  ${GREEN}[PASS]${NC} $*"; (( PASS_COUNT++ )) || true; }
skip()  { echo -e "  ${YELLOW}[SKIP]${NC} $*"; (( SKIP_COUNT++ )) || true; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $*"; (( FAIL_COUNT++ )) || true; }
info()  { echo -e "  ${CYAN}[INFO]${NC} $*"; }
step()  { echo -e "\n== $* =="; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

PASS_COUNT=0; SKIP_COUNT=0; FAIL_COUNT=0

printf '\n  BarcaTeam -- One-Command Install\n\n'

step "Pre-flight checks"
PREFLIGHT_OK=true

if cmd_exists node; then
    pass "Node.js $(node --version | sed 's/^v//')"
else
    fail "Node.js not found. Install from: https://nodejs.org"
    PREFLIGHT_OK=false
fi

if cmd_exists npm; then
    pass "npm $(npm --version)"
else
    fail "npm not found. Install Node.js from: https://nodejs.org"
    PREFLIGHT_OK=false
fi

if [ "$PREFLIGHT_OK" = "false" ]; then
    echo -e "\n  ${RED}Pre-flight failed. Fix the issues above, then re-run this script.${NC}"
    exit 1
fi

step "GitHub Copilot CLI"
if cmd_exists copilot; then
    skip "copilot already installed: $(copilot --version 2>&1 | head -1)"
else
    info "Installing @github/copilot globally..."
    npm install -g @github/copilot
    pass "@github/copilot installed"
fi

if cmd_exists copilot; then
    pass "copilot --version: $(copilot --version 2>&1 | head -1)"
else
    fail "copilot still not found after install. Restart your terminal and re-run."
fi

step "Repo assets"
AGENT_COUNT=0
if [ -d "$REPO_ROOT/.github/agents" ]; then
    AGENT_COUNT=$(find "$REPO_ROOT/.github/agents" -maxdepth 1 -type f -name '*.agent.md' | wc -l | tr -d ' ')
fi
if [ "$AGENT_COUNT" -eq "$EXPECTED_AGENTS" ]; then
    pass "agents: $AGENT_COUNT"
else
    fail "agents: expected $EXPECTED_AGENTS, found $AGENT_COUNT"
fi

SKILL_COUNT=0
if [ -d "$REPO_ROOT/.github/skills" ]; then
    SKILL_COUNT=$(find "$REPO_ROOT/.github/skills" -type f -name 'SKILL.md' | wc -l | tr -d ' ')
fi
if [ "$SKILL_COUNT" -eq "$EXPECTED_SKILLS" ]; then
    pass "skills: $SKILL_COUNT"
else
    fail "skills: expected $EXPECTED_SKILLS, found $SKILL_COUNT"
fi

if [ -f "$REPO_ROOT/.github/copilot-instructions.md" ]; then
    pass ".github/copilot-instructions.md present"
else
    fail ".github/copilot-instructions.md missing"
fi

step "MCP configuration"
MCP_JSON="$REPO_ROOT/.mcp.json"
if [ -f "$MCP_JSON" ]; then
    if node -e "const fs=require('fs'); const cfg=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); if (!cfg.mcpServers || !cfg.mcpServers.memory) process.exit(2);" "$MCP_JSON"; then
        pass ".mcp.json valid JSON with memory server"
    else
        fail ".mcp.json must be valid JSON containing mcpServers.memory"
    fi
else
    fail ".mcp.json missing"
fi

if npm view @modelcontextprotocol/server-memory version >/dev/null 2>&1; then
    pass "memory MCP package reachable: $(npm view @modelcontextprotocol/server-memory version 2>/dev/null | head -1)"
else
    fail "Cannot resolve @modelcontextprotocol/server-memory with npm"
fi

step "Recommended tools"
if cmd_exists gitnexus; then
    pass "GitNexus: $(gitnexus --version 2>&1 | head -1)"
else
    skip "GitNexus not found (recommended for cross-file safety checks)"
fi

step "Doctor verification"
DOCTOR_SH="$REPO_ROOT/scripts/doctor.sh"
if [ -f "$DOCTOR_SH" ]; then
    bash "$DOCTOR_SH"
else
    skip "doctor.sh not found"
fi

echo ""
echo "==============================================="
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}Install complete -- $PASS_COUNT pass, $SKIP_COUNT skip, $FAIL_COUNT fail${NC}"
    echo "  Fix the failures above and re-run: ./scripts/install.sh"
    exit 1
elif [ "$SKIP_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}Install complete -- $PASS_COUNT pass, $SKIP_COUNT skip, $FAIL_COUNT fail${NC}"
else
    echo -e "  ${GREEN}Install complete -- $PASS_COUNT pass, $SKIP_COUNT skip, $FAIL_COUNT fail${NC}"
fi
echo "==============================================="
echo ""
echo "  Next steps:"
echo "    1. Sign in if needed: copilot"
echo "    2. Start BarcaTeam: ./start.sh <repo-name-or-path>"
echo "    3. Check health: ./scripts/doctor.sh"
echo ""
