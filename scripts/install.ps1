# BarcaTeam -- One-Command Install Script (Windows / PowerShell)
# Usage: .\scripts\install.ps1
# Idempotent -- safe to re-run at any time.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REPO_ROOT = Split-Path -Parent $PSScriptRoot
$EXPECTED_AGENTS = 32
$EXPECTED_SKILLS = 21

function Write-Pass  { param([string]$msg) Write-Host "  [PASS] $msg" -ForegroundColor Green  }
function Write-Skip  { param([string]$msg) Write-Host "  [SKIP] $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red    }
function Write-Info  { param([string]$msg) Write-Host "  [INFO] $msg" -ForegroundColor Cyan   }
function Write-Step  { param([string]$msg) Write-Host "`n== $msg ==" -ForegroundColor White   }
function Test-Cmd    { param([string]$Name) return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

$script:pass = 0
$script:skip = 0
$script:fail = 0

function Pass { param([string]$msg) Write-Pass $msg; $script:pass++ }
function Skip { param([string]$msg) Write-Skip $msg; $script:skip++ }
function Fail { param([string]$msg) Write-Fail $msg; $script:fail++ }

Write-Host ""
Write-Host "  BarcaTeam -- One-Command Install" -ForegroundColor Cyan
Write-Host ""

Write-Step "Pre-flight checks"
$preflightOk = $true

if (Test-Cmd node) {
    $nodeVer = (node --version 2>&1) -replace '^v',''
    Pass "Node.js $nodeVer"
} else {
    Fail "Node.js not found. Install from: https://nodejs.org"
    $preflightOk = $false
}

if (Test-Cmd npm) {
    $npmVer = (npm --version 2>$null | Select-Object -First 1)
    Pass "npm $npmVer"
} else {
    Fail "npm not found. Install Node.js from: https://nodejs.org"
    $preflightOk = $false
}

if (-not $preflightOk) {
    Write-Host ""
    Write-Host "  Pre-flight failed. Fix the issues above, then re-run this script." -ForegroundColor Red
    exit 1
}

Write-Step "GitHub Copilot CLI"
if (Test-Cmd copilot) {
    $currentVersion = (copilot --version 2>&1 | Select-Object -First 1)
    Skip "copilot already installed: $currentVersion"
} else {
    Write-Info "Installing @github/copilot globally..."
    npm install -g @github/copilot
    if ($LASTEXITCODE -ne 0) { Fail "npm install -g @github/copilot failed"; exit 1 }
    Pass "@github/copilot installed"
}

if (Test-Cmd copilot) {
    $version = (copilot --version 2>&1 | Select-Object -First 1)
    Pass "copilot --version: $version"
} else {
    Fail "copilot still not found after install. Restart your terminal and re-run."
}

Write-Step "Repo assets"
$agentsDir = Join-Path $REPO_ROOT ".github\agents"
$skillsDir = Join-Path $REPO_ROOT ".github\skills"
$instructions = Join-Path $REPO_ROOT ".github\copilot-instructions.md"

$agentCount = if (Test-Path $agentsDir) { @(Get-ChildItem $agentsDir -Filter "*.agent.md" -File).Count } else { 0 }
if ($agentCount -eq $EXPECTED_AGENTS) { Pass "agents: $agentCount" } else { Fail "agents: expected $EXPECTED_AGENTS, found $agentCount" }

$skillCount = if (Test-Path $skillsDir) { @(Get-ChildItem $skillsDir -Filter "SKILL.md" -File -Recurse).Count } else { 0 }
if ($skillCount -eq $EXPECTED_SKILLS) { Pass "skills: $skillCount" } else { Fail "skills: expected $EXPECTED_SKILLS, found $skillCount" }

if (Test-Path $instructions) { Pass ".github\copilot-instructions.md present" } else { Fail ".github\copilot-instructions.md missing" }

Write-Step "MCP configuration"
$mcpJson = Join-Path $REPO_ROOT ".mcp.json"
if (Test-Path $mcpJson) {
    try {
        $mcp = Get-Content $mcpJson -Raw | ConvertFrom-Json
        Pass ".mcp.json valid JSON"
        $servers = @($mcp.mcpServers.PSObject.Properties.Name)
        if ("memory" -in $servers) { Pass ".mcp.json contains memory server" } else { Fail ".mcp.json missing memory server" }
    } catch {
        Fail ".mcp.json invalid JSON: $_"
    }
} else {
    Fail ".mcp.json missing"
}

try {
    $memoryVersion = (npm view @modelcontextprotocol/server-memory version 2>&1 | Select-Object -First 1)
    Pass "memory MCP package reachable: $memoryVersion"
} catch {
    Fail "Cannot resolve @modelcontextprotocol/server-memory with npm"
}

Write-Step "Recommended tools"
if (Test-Cmd gitnexus) {
    $gitnexusVersion = (gitnexus --version 2>&1 | Select-Object -First 1)
    Pass "GitNexus: $gitnexusVersion"
} else {
    Skip "GitNexus not found (recommended for cross-file safety checks)"
}

Write-Step "Doctor verification"
$doctorScript = Join-Path $PSScriptRoot "doctor.ps1"
if (Test-Path $doctorScript) {
    & $doctorScript
} else {
    Skip "doctor.ps1 not found"
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor White
if ($script:fail -gt 0) {
    Write-Host "  Install complete -- Pass: $($script:pass)  Skip: $($script:skip)  Fail: $($script:fail)" -ForegroundColor Red
    Write-Host "  Fix the failures above and re-run: .\scripts\install.ps1" -ForegroundColor Red
    exit 1
} elseif ($script:skip -gt 0) {
    Write-Host "  Install complete -- Pass: $($script:pass)  Skip: $($script:skip)  Fail: $($script:fail)" -ForegroundColor Yellow
} else {
    Write-Host "  Install complete -- Pass: $($script:pass)  Skip: $($script:skip)  Fail: $($script:fail)" -ForegroundColor Green
}
Write-Host "===============================================" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Sign in if needed: copilot"
Write-Host "    2. Start BarcaTeam: .\start.ps1 <repo-name-or-path>"
Write-Host "    3. Check health: .\scripts\doctor.ps1"
Write-Host ""

