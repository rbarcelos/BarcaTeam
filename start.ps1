# BarcaTeam Workspace Launcher (GitHub Copilot CLI)
# Usage: .\start.ps1 <repo1> [repo2] ...
# Example: .\start.ps1 COEPEMP
#          .\start.ps1 investFlorida.ai str_simulation

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Repos
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $Repos -or $Repos.Count -eq 0) {
    Write-Host "Usage: .\start.ps1 <repo1> [repo2] ..."
    Write-Host "       repo can be a name (sibling dir or `$HOME\repos\<name>) or a full path"
    exit 1
}

$teamDir = $PSScriptRoot

function Test-Cmd {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

if (-not (Test-Cmd copilot)) {
    Write-Host "ERROR: copilot CLI not found on PATH." -ForegroundColor Red
    Write-Host "       Run: .\scripts\install.ps1"
    Write-Host "       Or:  npm install -g @github/copilot"
    exit 1
}

function Resolve-RepoPath {
    param([string]$Repo)

    if ([System.IO.Path]::IsPathRooted($Repo)) {
        $path = $Repo
    } else {
        $siblingPath = Join-Path (Split-Path $teamDir -Parent) $Repo
        if (Test-Path -Path $siblingPath -PathType Container) {
            $path = $siblingPath
        } else {
            $path = Join-Path $HOME "repos\$Repo"
        }
    }

    if (-not (Test-Path -Path $path -PathType Container)) {
        Write-Host "ERROR: repo not found at '$path'" -ForegroundColor Red
        Write-Host "       Clone it first, e.g.: git clone <url> `"$path`""
        exit 1
    }

    return (Resolve-Path $path).Path
}

$repoPaths = @($Repos | ForEach-Object { Resolve-RepoPath $_ })
$copilotArgs = @()
foreach ($repoPath in $repoPaths) {
    $copilotArgs += @("--add-dir", $repoPath)
}

Write-Host ""
Write-Host " BarcaTeam — Starting GitHub Copilot CLI" -ForegroundColor Cyan
Write-Host " Repos: $($repoPaths -join ', ')"
Write-Host ""

Push-Location $teamDir
try {
    & copilot @copilotArgs
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
