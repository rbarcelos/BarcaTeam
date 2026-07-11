<#
.SYNOPSIS
    Syncs custom-agent definitions into the location the Copilot CLI spawns from.

.DESCRIPTION
    GitHub Copilot CLI (v1.0.69-2) DISCOVERS custom agents from
    `.github/agents/*.agent.md` (they show up in the agent picker / task tool),
    but LOADS the agent body at spawn time from `.claude/agents/<name>.md`.
    If the second location is missing, spawning a custom agent fails with:
        ENOENT: .claude\agents\<name>.md

    This script regenerates `.claude/agents/<name>.md` from every
    `.github/agents/<name>.agent.md` so both locations stay in sync.
    Run it after adding or editing any agent definition.

    `.github/agents/*.agent.md` remains the single source of truth — never edit
    the `.claude/agents/*.md` copies by hand.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repoRoot '.github\agents'
$dst = Join-Path $repoRoot '.claude\agents'

if (-not (Test-Path $src)) { throw "Source agents dir not found: $src" }
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# Remove stale copies so deleted agents don't linger.
Get-ChildItem $dst -Filter *.md -ErrorAction SilentlyContinue | Remove-Item -Force

$count = 0
Get-ChildItem $src -Filter *.agent.md | ForEach-Object {
    $name = $_.Name -replace '\.agent\.md$', '.md'
    Copy-Item $_.FullName (Join-Path $dst $name) -Force
    $count++
}

Write-Host "Synced $count agent definition(s) -> .claude\agents\" -ForegroundColor Green
