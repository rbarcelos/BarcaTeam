# BarcaTeam — One-Command Install Script (Windows / PowerShell)
# Usage: .\scripts\install.ps1
#
# Idempotent — safe to re-run at any time.
# Re-running skips already-configured components and reports green.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REPO_ROOT = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
function Write-Pass  { param([string]$msg) Write-Host "  [PASS] $msg" -ForegroundColor Green  }
function Write-Skip  { param([string]$msg) Write-Host "  [SKIP] $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red    }
function Write-Info  { param([string]$msg) Write-Host "  [INFO] $msg" -ForegroundColor Cyan   }
function Write-Step  { param([string]$msg) Write-Host "`n== $msg ==" -ForegroundColor White   }
function Write-Banner {
    Write-Host ""
    Write-Host "  ____                    _____                  " -ForegroundColor Cyan
    Write-Host " | __ )  __ _ _ __ ___  |_   _|__  __ _ _ __ ___" -ForegroundColor Cyan
    Write-Host " |  _ \ / _' | '__/ __|   | |/ _ \/ _' | '_ ' _ \" -ForegroundColor Cyan
    Write-Host " | |_) | (_| | | | (__    | |  __/ (_| | | | | | |" -ForegroundColor Cyan
    Write-Host " |____/ \__,_|_|  \___|   |_|\___|\__,_|_| |_| |_|" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  One-Command Install" -ForegroundColor White
    Write-Host ""
}

$script:pass  = 0
$script:skip  = 0
$script:fail  = 0

function Test-Cmd { param([string]$Name) return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Check,    # returns $true if already done (skip)
        [scriptblock]$Action    # runs only if Check returns $false
    )
    if (& $Check) {
        Write-Skip $Label
        $script:skip++
    } else {
        try {
            & $Action
            Write-Pass $Label
            $script:pass++
        } catch {
            Write-Fail "$Label — $_"
            $script:fail++
        }
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
Write-Banner

# ---------------------------------------------------------------------------
# Step 1: Pre-flight checks
# ---------------------------------------------------------------------------
Write-Step "Pre-flight checks"

$preflight_ok = $true

# Node >= 20
if (Test-Cmd node) {
    $nodeVer = (node --version 2>&1) -replace 'v',''
    $nodeMajor = [int]($nodeVer -split '\.')[0]
    if ($nodeMajor -ge 20) {
        Write-Pass "Node.js $nodeVer (>= 20)"
        $script:pass++
    } else {
        Write-Fail "Node.js $nodeVer found but >= 20 required. Upgrade: https://nodejs.org"
        $script:fail++; $preflight_ok = $false
    }
} else {
    Write-Fail "Node.js not found. Install from: https://nodejs.org"
    $script:fail++; $preflight_ok = $false
}

# Python >= 3.11 (optional but recommended for dev-env.sh)
if (Test-Cmd python) {
    $pyVer = (python --version 2>&1) -replace 'Python ',''
    $pyParts = $pyVer -split '\.'
    if ([int]$pyParts[0] -ge 3 -and [int]$pyParts[1] -ge 11) {
        Write-Pass "Python $pyVer (>= 3.11)"
        $script:pass++
    } else {
        Write-Skip "Python $pyVer (< 3.11 — optional, upgrade at https://python.org if needed)"
        $script:skip++
    }
} else {
    Write-Skip "Python not found (optional — needed only for dev-env.sh)"
    $script:skip++
}

# gh CLI authenticated
if (Test-Cmd gh) {
    $ghStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "GitHub CLI authenticated"
        $script:pass++
    } else {
        Write-Fail "GitHub CLI found but not authenticated. Run: gh auth login"
        $script:fail++
    }
} else {
    Write-Fail "GitHub CLI not found. Install: https://cli.github.com"
    $script:fail++; $preflight_ok = $false
}

# Claude CLI
if (Test-Cmd claude) {
    $claudeVer = (claude --version 2>&1 | Select-Object -First 1)
    Write-Pass "Claude CLI: $claudeVer"
    $script:pass++
} else {
    Write-Info "Claude CLI not found — installing via npm..."
    try {
        npm install -g @anthropic-ai/claude-code
        Write-Pass "Claude CLI installed"
        $script:pass++
    } catch {
        Write-Fail "Failed to install Claude CLI: $_"
        $script:fail++; $preflight_ok = $false
    }
}

if (-not $preflight_ok) {
    Write-Host ""
    Write-Host "  Pre-flight failed. Fix the issues above, then re-run this script." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2: psmux (Windows terminal multiplexer, tmux-compatible)
# ---------------------------------------------------------------------------
Write-Step "psmux (terminal multiplexer)"

Invoke-Step -Label "psmux installed" `
    -Check  { Test-Cmd psmux } `
    -Action {
        Write-Info "Installing psmux via winget..."
        winget install psmux --accept-source-agreements --accept-package-agreements --silent
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path","User")
        if (-not (Test-Cmd psmux)) {
            throw "psmux installed but not on PATH. Restart your terminal and re-run."
        }
    }

# Run upgrade-psmux.ps1 to configure psmux capabilities (idempotent)
$upgradePsmux = Join-Path $REPO_ROOT "upgrade-psmux.ps1"
if (Test-Path $upgradePsmux) {
    Invoke-Step -Label "psmux capabilities configured" `
        -Check  {
            $managedFile = Join-Path $HOME ".config\psmux\capabilities.managed.conf"
            Test-Path $managedFile
        } `
        -Action {
            Write-Info "Running upgrade-psmux.ps1 to apply capabilities..."
            & $upgradePsmux
        }
} else {
    Write-Skip "upgrade-psmux.ps1 not found — skip psmux capability config"
    $script:skip++
}

# ---------------------------------------------------------------------------
# Step 3: claude-ping MCP server (WhatsApp integration)
# ---------------------------------------------------------------------------
Write-Step "claude-ping (WhatsApp MCP server)"

$claudePingDir = Join-Path $REPO_ROOT "claude-ping"
$claudePingDist = Join-Path $claudePingDir "dist\mcp\server.js"

Invoke-Step -Label "claude-ping dependencies installed" `
    -Check  { Test-Path $claudePingDist } `
    -Action {
        if (-not (Test-Path $claudePingDir)) {
            throw "claude-ping directory not found at $claudePingDir. Clone the submodule first: git submodule update --init"
        }
        Write-Info "Installing claude-ping npm deps..."
        Push-Location $claudePingDir
        try {
            npm install
            if (Test-Path (Join-Path $claudePingDir "package.json")) {
                $pkg = Get-Content (Join-Path $claudePingDir "package.json") -Raw | ConvertFrom-Json
                if ($pkg.scripts.build) {
                    npm run build
                }
            }
        } finally {
            Pop-Location
        }
    }

# ---------------------------------------------------------------------------
# Step 4: Verify .mcp.json is in place
# ---------------------------------------------------------------------------
Write-Step "MCP server configuration (.mcp.json)"

$mcpJson = Join-Path $REPO_ROOT ".mcp.json"

Invoke-Step -Label ".mcp.json present" `
    -Check  { Test-Path $mcpJson } `
    -Action {
        # Should already be in the repo — if missing, write a minimal one
        $minimal = @{
            mcpServers = @{
                "claude-ping" = @{
                    type    = "stdio"
                    command = "node"
                    args    = @("claude-ping/dist/mcp/server.js")
                }
                "memory" = @{
                    type    = "stdio"
                    command = "npx"
                    args    = @("-y", "@modelcontextprotocol/server-memory")
                }
            }
        }
        $minimal | ConvertTo-Json -Depth 5 | Set-Content $mcpJson -Encoding UTF8
    }

# ---------------------------------------------------------------------------
# Step 5: Claude plugins
# ---------------------------------------------------------------------------
Write-Step "Claude plugins"

$requiredPlugins = @(
    "context7@claude-plugins-official"
    "playwright@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "typescript-lsp@claude-plugins-official"
    "pyright-lsp@claude-plugins-official"
    "claude-md-management@claude-plugins-official"
    "claude-code-setup@claude-plugins-official"
)

$installedPluginsRaw = claude plugin list 2>&1
foreach ($plugin in $requiredPlugins) {
    $shortName = $plugin -replace '@claude-plugins-official',''
    $alreadyInstalled = $installedPluginsRaw | Select-String -Pattern [regex]::Escape($shortName) -Quiet
    Invoke-Step -Label "plugin: $plugin" `
        -Check  { $alreadyInstalled } `
        -Action {
            Write-Info "Installing $plugin..."
            # claude plugin install is interactive — wrap with --yes if supported
            $result = claude plugin install $plugin 2>&1
            Write-Info $result
        }
}

# ---------------------------------------------------------------------------
# Step 6: Verify install with doctor
# ---------------------------------------------------------------------------
Write-Step "Doctor verification"

$doctorScript = Join-Path $PSScriptRoot "doctor.ps1"
if (Test-Path $doctorScript) {
    Write-Info "Running doctor..."
    & $doctorScript
} else {
    Write-Skip "doctor.ps1 not found — skipping"
    $script:skip++
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===============================================" -ForegroundColor White
Write-Host "  Install complete" -ForegroundColor White
Write-Host "  Pass: $($script:pass)  Skip: $($script:skip)  Fail: $($script:fail)" -ForegroundColor $(if ($script:fail -gt 0) { "Red" } elseif ($script:skip -gt 0) { "Yellow" } else { "Green" })
Write-Host "===============================================" -ForegroundColor White
Write-Host ""

if ($script:fail -gt 0) {
    Write-Host "  Some steps failed. Fix the issues above and re-run:" -ForegroundColor Red
    Write-Host "    .\scripts\install.ps1"
    Write-Host ""
    exit 1
}

Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Start BarcaTeam against your target repo(s):"
Write-Host "         .\start.ps1 <repo-name-or-path>"
Write-Host ""
Write-Host "    2. Check install health any time:"
Write-Host "         .\scripts\doctor.ps1"
Write-Host ""
Write-Host "    3. Configure WhatsApp (claude-ping):"
Write-Host "         Open a Claude session with BarcaTeam — claude-ping will prompt you to scan a QR code."
Write-Host ""
Write-Host "  See CLAUDE.md for advanced configuration."
Write-Host ""
