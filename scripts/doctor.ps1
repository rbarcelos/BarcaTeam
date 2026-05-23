# BarcaTeam — Doctor Script (Windows / PowerShell)
# Usage: .\scripts\doctor.ps1
#
# Audits current install state and reports what's configured, stale, or missing.
# Each FAIL line includes a "Fix:" command you can copy-paste.

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$REPO_ROOT = Split-Path -Parent $PSScriptRoot

function Write-Pass  { param([string]$msg) Write-Host "  [OK]   $msg" -ForegroundColor Green  }
function Write-Warn  { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red    }
function Write-Fix   { param([string]$msg) Write-Host "         Fix: $msg" -ForegroundColor DarkGray }
function Write-Step  { param([string]$msg) Write-Host "`n== $msg ==" -ForegroundColor White   }
function Test-Cmd    { param([string]$Name) return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

$script:ok   = 0
$script:warn = 0
$script:fail = 0

function Check {
    param(
        [string]$Label,
        [bool]$Passed,
        [string]$FailMsg,
        [string]$FixCmd = $null,
        [bool]$IsWarn = $false
    )
    if ($Passed) {
        Write-Pass $Label
        $script:ok++
    } elseif ($IsWarn) {
        Write-Warn "$Label — $FailMsg"
        if ($FixCmd) { Write-Fix $FixCmd }
        $script:warn++
    } else {
        Write-Fail "$Label — $FailMsg"
        if ($FixCmd) { Write-Fix $FixCmd }
        $script:fail++
    }
}

Write-Host ""
Write-Host "  BarcaTeam Doctor" -ForegroundColor Cyan
Write-Host "  Repo: $REPO_ROOT" -ForegroundColor DarkGray
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Core CLIs
# ---------------------------------------------------------------------------
Write-Step "Core CLIs"

# Node.js
if (Test-Cmd node) {
    $nodeVer = (node --version 2>&1) -replace 'v',''
    $nodeMajor = [int](($nodeVer -split '\.')[0])
    Check -Label "Node.js $nodeVer" -Passed ($nodeMajor -ge 20) `
          -FailMsg "version $nodeVer found but >= 20 required" `
          -FixCmd  "https://nodejs.org — download and install LTS"
} else {
    Check -Label "Node.js" -Passed $false `
          -FailMsg "not found" `
          -FixCmd  "https://nodejs.org"
}

# Python (optional)
if (Test-Cmd python) {
    $pyVer = (python --version 2>&1) -replace 'Python ',''
    $pyParts = $pyVer -split '\.'
    $pyOk = [int]$pyParts[0] -ge 3 -and [int]$pyParts[1] -ge 11
    Check -Label "Python $pyVer (optional)" -Passed $pyOk `
          -FailMsg "< 3.11 — upgrade at https://python.org" `
          -IsWarn  $true
} else {
    Check -Label "Python (optional)" -Passed $false `
          -FailMsg "not found — needed for dev-env.sh only" `
          -IsWarn  $true
}

# Claude CLI
if (Test-Cmd claude) {
    $claudeVer = (claude --version 2>&1 | Select-Object -First 1)
    Check -Label "Claude CLI: $claudeVer" -Passed $true
} else {
    Check -Label "Claude CLI" -Passed $false `
          -FailMsg "not found" `
          -FixCmd  "npm install -g @anthropic-ai/claude-code"
}

# GitHub CLI
if (Test-Cmd gh) {
    $ghStatus = gh auth status 2>&1
    $ghOk = $LASTEXITCODE -eq 0
    Check -Label "GitHub CLI (gh)" -Passed $ghOk `
          -FailMsg "not authenticated" `
          -FixCmd  "gh auth login"
} else {
    Check -Label "GitHub CLI (gh)" -Passed $false `
          -FailMsg "not found" `
          -FixCmd  "https://cli.github.com"
}

# ---------------------------------------------------------------------------
# 2. psmux
# ---------------------------------------------------------------------------
Write-Step "psmux (terminal multiplexer)"

if (Test-Cmd psmux) {
    $psmuxVer = (psmux -V 2>&1 | Select-Object -First 1)
    Write-Pass "psmux: $psmuxVer"
    $script:ok++

    # Check managed config
    $managedFile = Join-Path $HOME ".config\psmux\capabilities.managed.conf"
    Check -Label "psmux capabilities.managed.conf" -Passed (Test-Path $managedFile) `
          -FailMsg "not found — capabilities not configured" `
          -FixCmd  ".\upgrade-psmux.ps1"

    # Check for critical capabilities
    if (Test-Path $managedFile) {
        $managedContent = Get-Content $managedFile -Raw -ErrorAction SilentlyContinue
        $hasClaudeCodeFix = $managedContent -match 'claude-code-fix-tty'
        Check -Label "psmux: claude-code-fix-tty capability" -Passed $hasClaudeCodeFix `
              -FailMsg "missing — Claude Code pane launch may fail" `
              -FixCmd  ".\upgrade-psmux.ps1"
    }
} else {
    Check -Label "psmux" -Passed $false `
          -FailMsg "not found" `
          -FixCmd  'winget install psmux --accept-source-agreements --accept-package-agreements'
}

# ---------------------------------------------------------------------------
# 3. claude-ping (WhatsApp MCP)
# ---------------------------------------------------------------------------
Write-Step "claude-ping (WhatsApp MCP server)"

$claudePingDist = Join-Path $REPO_ROOT "claude-ping\dist\mcp\server.js"
$claudePingPkg  = Join-Path $REPO_ROOT "claude-ping\package.json"

if (Test-Path $claudePingPkg) {
    Check -Label "claude-ping: package.json present" -Passed $true
    Check -Label "claude-ping: dist/mcp/server.js built" -Passed (Test-Path $claudePingDist) `
          -FailMsg "not built — run npm install && npm run build in claude-ping/" `
          -FixCmd  "Push-Location claude-ping; npm install; npm run build; Pop-Location"
} else {
    Check -Label "claude-ping" -Passed $false `
          -FailMsg "submodule not initialised" `
          -FixCmd  "git submodule update --init"
}

# ---------------------------------------------------------------------------
# 4. .mcp.json
# ---------------------------------------------------------------------------
Write-Step "MCP configuration (.mcp.json)"

$mcpJson = Join-Path $REPO_ROOT ".mcp.json"
if (Test-Path $mcpJson) {
    try {
        $mcp = Get-Content $mcpJson -Raw | ConvertFrom-Json
        Write-Pass ".mcp.json present and valid JSON"
        $script:ok++
        $servers = $mcp.mcpServers.PSObject.Properties.Name
        foreach ($s in @("claude-ping","memory")) {
            Check -Label ".mcp.json: $s server configured" -Passed ($s -in $servers) `
                  -FailMsg "missing from .mcp.json" `
                  -FixCmd  "Add the $s block to .mcp.json — see README.md for the format"
        }
    } catch {
        Check -Label ".mcp.json valid JSON" -Passed $false `
              -FailMsg "invalid JSON — $_" `
              -FixCmd  "Fix the JSON syntax in .mcp.json"
    }
} else {
    Check -Label ".mcp.json" -Passed $false `
          -FailMsg "not found" `
          -FixCmd  ".\scripts\install.ps1"
}

# ---------------------------------------------------------------------------
# 5. Claude plugins
# ---------------------------------------------------------------------------
Write-Step "Claude plugins"

$requiredPlugins = @(
    @{ Name = "context7";           Package = "context7@claude-plugins-official"            }
    @{ Name = "playwright";         Package = "playwright@claude-plugins-official"          }
    @{ Name = "pr-review-toolkit";  Package = "pr-review-toolkit@claude-plugins-official"  }
    @{ Name = "security-guidance";  Package = "security-guidance@claude-plugins-official"  }
    @{ Name = "typescript-lsp";     Package = "typescript-lsp@claude-plugins-official"     }
    @{ Name = "pyright-lsp";        Package = "pyright-lsp@claude-plugins-official"        }
    @{ Name = "claude-md-management"; Package = "claude-md-management@claude-plugins-official" }
    @{ Name = "claude-code-setup";  Package = "claude-code-setup@claude-plugins-official"  }
)

if (Test-Cmd claude) {
    $installedPluginsRaw = claude plugin list 2>&1
    foreach ($p in $requiredPlugins) {
        $found = $installedPluginsRaw | Select-String -Pattern [regex]::Escape($p.Name) -Quiet
        Check -Label "plugin: $($p.Name)" -Passed $found `
              -FailMsg "not installed" `
              -FixCmd  "claude plugin install $($p.Package)"
    }
} else {
    Write-Warn "  [SKIP] Claude CLI not found — cannot check plugins"
    $script:warn++
}

# ---------------------------------------------------------------------------
# 6. Repo structure
# ---------------------------------------------------------------------------
Write-Step "Repo structure"

$expectedFiles = @(
    @{ Path = "CLAUDE.md";                   Label = "CLAUDE.md (shared agent instructions)" }
    @{ Path = "start.ps1";                   Label = "start.ps1 (Windows launcher)" }
    @{ Path = ".github\copilot-instructions.md"; Label = ".github/copilot-instructions.md" }
    @{ Path = "agents\lead.agent.md";        Label = "agents/lead.agent.md" }
    @{ Path = ".claude\skills";              Label = ".claude/skills/ directory" }
    @{ Path = "scripts\install.ps1";         Label = "scripts/install.ps1" }
    @{ Path = "scripts\doctor.ps1";          Label = "scripts/doctor.ps1" }
)

foreach ($f in $expectedFiles) {
    $fullPath = Join-Path $REPO_ROOT $f.Path
    Check -Label $f.Label -Passed (Test-Path $fullPath) `
          -FailMsg "missing at $($f.Path)" `
          -FixCmd  "git checkout origin/master -- $($f.Path)"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=======================================" -ForegroundColor White
Write-Host "  Doctor Summary" -ForegroundColor White
Write-Host "  OK: $($script:ok)   Warn: $($script:warn)   Fail: $($script:fail)" -ForegroundColor $(
    if     ($script:fail -gt 0) { "Red"    }
    elseif ($script:warn -gt 0) { "Yellow" }
    else                        { "Green"  }
)
Write-Host "=======================================" -ForegroundColor White
Write-Host ""

if ($script:fail -gt 0) {
    Write-Host "  Run .\scripts\install.ps1 to fix most issues automatically." -ForegroundColor Red
} elseif ($script:warn -gt 0) {
    Write-Host "  Minor warnings only — BarcaTeam should work. See above for optional fixes." -ForegroundColor Yellow
} else {
    Write-Host "  All checks passed — BarcaTeam is healthy." -ForegroundColor Green
}
Write-Host ""
