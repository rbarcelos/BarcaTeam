# BarcaTeam -- Doctor Script (Windows / PowerShell)
# Usage: .\scripts\doctor.ps1
# Each FAIL line includes a copy-paste fix.

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$REPO_ROOT = Split-Path -Parent $PSScriptRoot
$EXPECTED_AGENTS = 32
$EXPECTED_SKILLS = 21

function Write-Pass { param([string]$msg) Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Fix  { param([string]$msg) Write-Host "         Fix: $msg" -ForegroundColor DarkGray }
function Write-Step { param([string]$msg) Write-Host "`n== $msg ==" -ForegroundColor White }
function Test-Cmd   { param([string]$Name) return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

$script:ok = 0
$script:warn = 0
$script:fail = 0

function Check {
    param([string]$Label, [bool]$Passed, [string]$FailMsg = "", [string]$FixCmd = $null, [bool]$IsWarn = $false)
    if ($Passed) {
        Write-Pass $Label; $script:ok++
    } elseif ($IsWarn) {
        if ($FailMsg) { Write-Warn "$Label - $FailMsg" } else { Write-Warn $Label }
        if ($FixCmd) { Write-Fix $FixCmd }
        $script:warn++
    } else {
        if ($FailMsg) { Write-Fail "$Label - $FailMsg" } else { Write-Fail $Label }
        if ($FixCmd) { Write-Fix $FixCmd }
        $script:fail++
    }
}

Write-Host ""
Write-Host "  BarcaTeam Doctor" -ForegroundColor Cyan
Write-Host "  Repo: $REPO_ROOT" -ForegroundColor DarkGray
Write-Host ""

Write-Step "Core CLIs"
if (Test-Cmd node) {
    Check -Label "Node.js $((node --version 2>&1) -replace '^v','')" -Passed $true
} else {
    Check -Label "Node.js" -Passed $false -FailMsg "not found" -FixCmd "https://nodejs.org -- download and install LTS"
}

if (Test-Cmd npm) {
    Check -Label "npm $(npm --version 2>$null | Select-Object -First 1)" -Passed $true
} else {
    Check -Label "npm" -Passed $false -FailMsg "not found" -FixCmd "Install Node.js from https://nodejs.org"
}

if (Test-Cmd copilot) {
    $copilotVersion = (copilot --version 2>&1 | Select-Object -First 1)
    Check -Label "copilot: $copilotVersion" -Passed $true
    Write-Warn "copilot requires GitHub authentication; run 'copilot' and follow the sign-in prompt if requested."
    $script:warn++
} else {
    Check -Label "copilot" -Passed $false -FailMsg "not found" -FixCmd "npm install -g @github/copilot"
}

Write-Step "Repo assets"
$instructions = Join-Path $REPO_ROOT ".github\copilot-instructions.md"
Check -Label ".github/copilot-instructions.md" -Passed (Test-Path $instructions) -FailMsg "missing" -FixCmd "git restore .github/copilot-instructions.md"

$agentsDir = Join-Path $REPO_ROOT ".github\agents"
$agentCount = if (Test-Path $agentsDir) { @(Get-ChildItem $agentsDir -Filter "*.agent.md" -File).Count } else { 0 }
Check -Label "agents count: $agentCount" -Passed ($agentCount -eq $EXPECTED_AGENTS) -FailMsg "expected $EXPECTED_AGENTS" -FixCmd "git restore .github/agents"

$skillsDir = Join-Path $REPO_ROOT ".github\skills"
$skillCount = if (Test-Path $skillsDir) { @(Get-ChildItem $skillsDir -Filter "SKILL.md" -File -Recurse).Count } else { 0 }
Check -Label "skills count: $skillCount" -Passed ($skillCount -eq $EXPECTED_SKILLS) -FailMsg "expected $EXPECTED_SKILLS" -FixCmd "git restore .github/skills"

Write-Step "MCP configuration"
$mcpJson = Join-Path $REPO_ROOT ".mcp.json"
if (Test-Path $mcpJson) {
    try {
        $mcp = Get-Content $mcpJson -Raw | ConvertFrom-Json
        Check -Label ".mcp.json valid JSON" -Passed $true
        $servers = @($mcp.mcpServers.PSObject.Properties.Name)
        Check -Label ".mcp.json memory server" -Passed ("memory" -in $servers) -FailMsg "missing" -FixCmd "Add mcpServers.memory using npx -y @modelcontextprotocol/server-memory"
    } catch {
        Check -Label ".mcp.json valid JSON" -Passed $false -FailMsg "invalid JSON - $_" -FixCmd "Fix the JSON syntax in .mcp.json"
    }
} else {
    Check -Label ".mcp.json" -Passed $false -FailMsg "not found" -FixCmd ".\scripts\install.ps1"
}

Write-Step "Recommended tools"
if (Test-Cmd gitnexus) {
    $gitnexusVersion = (gitnexus --version 2>&1 | Select-Object -First 1)
    Check -Label "GitNexus: $gitnexusVersion" -Passed $true
} else {
    Check -Label "GitNexus" -Passed $false -FailMsg "not found, recommended for cross-file safety checks" -FixCmd "Install GitNexus manually if you need impact analysis" -IsWarn $true
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor White
Write-Host "  Doctor Summary" -ForegroundColor White
if ($script:fail -gt 0) {
    Write-Host "  OK: $($script:ok)   Warn: $($script:warn)   Fail: $($script:fail)" -ForegroundColor Red
    Write-Host "  Run .\scripts\install.ps1 to fix most issues automatically." -ForegroundColor Red
} elseif ($script:warn -gt 0) {
    Write-Host "  OK: $($script:ok)   Warn: $($script:warn)   Fail: $($script:fail)" -ForegroundColor Yellow
    Write-Host "  Minor warnings only -- BarcaTeam should work." -ForegroundColor Yellow
} else {
    Write-Host "  OK: $($script:ok)   Warn: $($script:warn)   Fail: $($script:fail)" -ForegroundColor Green
    Write-Host "  All checks passed -- BarcaTeam is healthy." -ForegroundColor Green
}
Write-Host "=======================================" -ForegroundColor White
Write-Host ""

