#!/usr/bin/env bash
# BarcaTeam — Doctor Script (Linux / macOS)
# Usage: ./scripts/doctor.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_AGENTS=32
EXPECTED_SKILLS=21

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}[OK]  ${NC} $*"; (( OK_COUNT++ )) || true; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $*"; (( WARN_COUNT++ )) || true; }
fail() { echo -e "  ${RED}[FAIL]${NC} $*"; (( FAIL_COUNT++ )) || true; }
fix()  { echo -e "         ${GRAY}Fix: $*${NC}"; }
step() { echo -e "\n== $* =="; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

OK_COUNT=0; WARN_COUNT=0; FAIL_COUNT=0

printf '\n  %bBarcaTeam Doctor%b\n  Repo: %s\n\n' "$CYAN" "$NC" "$REPO_ROOT"

step "Core CLIs"
if cmd_exists node; then
    ok "Node.js $(node --version | sed 's/^v//')"
else
    fail "Node.js not found"
    fix "https://nodejs.org -- download and install LTS"
fi

if cmd_exists npm; then
    ok "npm $(npm --version)"
else
    fail "npm not found"
    fix "Install Node.js from https://nodejs.org"
fi

if cmd_exists copilot; then
    ok "copilot: $(copilot --version 2>&1 | head -1)"
    warn "copilot requires GitHub authentication; run 'copilot' and follow the sign-in prompt if requested."
else
    fail "copilot not found"
    fix "npm install -g @github/copilot"
fi

step "Repo assets"
if [ -f "$REPO_ROOT/.github/copilot-instructions.md" ]; then
    ok ".github/copilot-instructions.md"
else
    fail ".github/copilot-instructions.md missing"
    fix "git restore .github/copilot-instructions.md"
fi

AGENT_COUNT=0
if [ -d "$REPO_ROOT/.github/agents" ]; then
    AGENT_COUNT=$(find "$REPO_ROOT/.github/agents" -maxdepth 1 -type f -name '*.agent.md' | wc -l | tr -d ' ')
fi
if [ "$AGENT_COUNT" -eq "$EXPECTED_AGENTS" ]; then
    ok "agents count: $AGENT_COUNT"
else
    fail "agents count: $AGENT_COUNT (expected $EXPECTED_AGENTS)"
    fix "git restore .github/agents"
fi

SKILL_COUNT=0
if [ -d "$REPO_ROOT/.github/skills" ]; then
    SKILL_COUNT=$(find "$REPO_ROOT/.github/skills" -type f -name 'SKILL.md' | wc -l | tr -d ' ')
fi
if [ "$SKILL_COUNT" -eq "$EXPECTED_SKILLS" ]; then
    ok "skills count: $SKILL_COUNT"
else
    fail "skills count: $SKILL_COUNT (expected $EXPECTED_SKILLS)"
    fix "git restore .github/skills"
fi

step "MCP configuration"
MCP_JSON="$REPO_ROOT/.mcp.json"
if [ -f "$MCP_JSON" ]; then
    if node -e "const fs=require('fs'); JSON.parse(fs.readFileSync(process.argv[1],'utf8'));" "$MCP_JSON" >/dev/null 2>&1; then
        ok ".mcp.json valid JSON"
        if node -e "const fs=require('fs'); const cfg=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); process.exit(cfg.mcpServers && cfg.mcpServers.memory ? 0 : 1);" "$MCP_JSON" >/dev/null 2>&1; then
            ok ".mcp.json memory server"
        else
            fail ".mcp.json memory server missing"
            fix "Add mcpServers.memory using npx -y @modelcontextprotocol/server-memory"
        fi
    else
        fail ".mcp.json invalid JSON"
        fix "Fix the JSON syntax in .mcp.json"
    fi
else
    fail ".mcp.json not found"
    fix "./scripts/install.sh"
fi

step "Recommended tools"
if cmd_exists gitnexus; then
    ok "GitNexus: $(gitnexus --version 2>&1 | head -1)"
else
    warn "GitNexus not found, recommended for cross-file safety checks"
    fix "Install GitNexus manually if you need impact analysis"
fi

echo ""
echo "======================================="
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}Doctor Summary: OK=$OK_COUNT  Warn=$WARN_COUNT  Fail=$FAIL_COUNT${NC}"
    echo "  Run ./scripts/install.sh to fix most issues automatically."
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}Doctor Summary: OK=$OK_COUNT  Warn=$WARN_COUNT  Fail=$FAIL_COUNT${NC}"
    echo "  Minor warnings only -- BarcaTeam should work."
else
    echo -e "  ${GREEN}Doctor Summary: OK=$OK_COUNT  Warn=$WARN_COUNT  Fail=$FAIL_COUNT -- All checks passed.${NC}"
fi
echo "======================================="
echo ""
