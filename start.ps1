# BarcaTeam Workspace Launcher (psmux — native Windows)
# Usage: .\start.ps1 [--reset] [-Session <name>] <repo1> [repo2] ...
# Example: .\start.ps1 investFlorida.ai str_simulation
#          .\start.ps1 -Session mywork investFlorida.ai
#          .\start.ps1 --reset investFlorida.ai

param(
    [switch]$Reset,
    [string]$Session = "barcateam",
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Repos
)

# Support --reset (double-dash) in addition to -Reset (PowerShell native)
if ($Repos -contains '--reset') {
    $Reset = $true
    $Repos = @($Repos | Where-Object { $_ -ne '--reset' })
}

if (-not $Repos -or $Repos.Count -eq 0) {
    Write-Host "Usage: .\start.ps1 [--reset] [-Session <name>] <repo1> [repo2] ..."
    Write-Host "       repo can be a name (expanded to `$HOME\repos\<name>) or a full path"
    exit 1
}

$teamDir = $PSScriptRoot

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

# Check psmux
if (-not (Get-Command psmux -ErrorAction SilentlyContinue)) {
    Write-Host "psmux not found. Installing via winget..."
    winget install psmux --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to install psmux. Install manually: winget install psmux"
        exit 1
    }
    # Refresh PATH for this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (Get-Command psmux -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: psmux installed but not on PATH. Restart your terminal and try again."
        exit 1
    }
}

# Check claude CLI
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "claude CLI not found. Installing via npm..."
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: npm not found. Install Node.js first: https://nodejs.org"
        exit 1
    }
    npm install -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to install claude CLI."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Resolve repo arguments to absolute paths
# ---------------------------------------------------------------------------

$repoPaths = @()
foreach ($repo in $Repos) {
    if ([System.IO.Path]::IsPathRooted($repo)) {
        $path = $repo
    } else {
        # Bare name — look in sibling directories (../name) first, then $HOME\repos\<name>
        $siblingPath = Join-Path (Split-Path $teamDir -Parent) $repo
        if (Test-Path -Path $siblingPath -PathType Container) {
            $path = $siblingPath
        } else {
            $path = Join-Path $HOME "repos\$repo"
        }
    }

    if (-not (Test-Path -Path $path -PathType Container)) {
        Write-Host "ERROR: repo not found at '$path'"
        Write-Host "       Clone it first, e.g.: git clone <url> `"$path`""
        exit 1
    }

    $repoPaths += (Resolve-Path $path).Path
}

# ---------------------------------------------------------------------------
# Build claude --add-dir flags
# ---------------------------------------------------------------------------

$addDirFlags = ($repoPaths | ForEach-Object { "--add-dir `"$_`"" }) -join ' '

# ---------------------------------------------------------------------------
# psmux session management
# ---------------------------------------------------------------------------

if ($Reset) {
    psmux kill-session -t $Session 2>$null
}

# Check if session already exists
$null = psmux has-session -t $Session 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Session '$Session' already exists — attaching. Use --reset to restart."
    psmux attach -t $Session
    exit 0
}

Write-Host ""
Write-Host " BarcaTeam — Starting agent orchestration hub (psmux)"
Write-Host " Session : $Session"
Write-Host " Repos   : $($repoPaths -join ', ')"
if ($Reset) { Write-Host " Mode    : --reset (existing session killed)" }
Write-Host ""

# Create detached session with a "lead" window
psmux new-session -d -s $Session -n lead

# Configure session
psmux set-option -g mouse on
psmux set-option -g history-limit 200000

# Launch claude in the lead pane
$launchCmd = "cd `"$teamDir`" && claude $addDirFlags"
psmux send-keys -t "${Session}:lead" "$launchCmd" Enter

# Attach
psmux attach -t $Session
