[CmdletBinding()]
param(
    [switch]$ApplyNow
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Cmd {
    param([Parameter(Mandatory)] [string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-ParentDir {
    param([Parameter(Mandatory)] [string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Ensure-File {
    param([Parameter(Mandatory)] [string]$Path)
    Ensure-ParentDir -Path $Path
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

function Backup-IfExists {
    param([Parameter(Mandatory)] [string]$Path)
    if (Test-Path $Path) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $Path "$Path.bak.$stamp" -Force
    }
}

function Read-Text {
    param([Parameter(Mandatory)] [string]$Path)
    if (Test-Path $Path) {
        return Get-Content -Path $Path -Raw
    }
    return ""
}

function Append-Line-IfMissing {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Line
    )

    Ensure-File -Path $Path
    $content = Read-Text -Path $Path
    if ($content -notmatch [regex]::Escape($Line)) {
        if ($content.Length -gt 0 -and -not $content.EndsWith("`r`n") -and -not $content.EndsWith("`n")) {
            Add-Content -Path $Path -Value ""
        }
        Add-Content -Path $Path -Value $Line
    }
}

function Has-GlobalOption {
    param(
        [Parameter(Mandatory)] [string]$Text,
        [Parameter(Mandatory)] [string]$OptionName
    )

    $pattern = '(?im)^\s*set(?:-option)?\s+-(?:g|sg)\s+' + [regex]::Escape($OptionName) + '\b'
    return $Text -match $pattern
}

function Append-ManagedBlock {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Marker,
        [Parameter(Mandatory)] [string[]]$Lines
    )

    Ensure-File -Path $Path
    $content = Read-Text -Path $Path
    $startMarker = "# >>> psmux-managed: $Marker >>>"
    $endMarker   = "# <<< psmux-managed: $Marker <<<"

    if ($content -match [regex]::Escape($startMarker)) {
        return
    }

    $block = @()
    $block += ""
    $block += $startMarker
    $block += $Lines
    $block += $endMarker

    Add-Content -Path $Path -Value $block
}

function Upgrade-Psmux {
    $used = $null

    if (Test-Cmd winget) {
        try {
            & winget upgrade --name psmux --exact --silent --accept-source-agreements --accept-package-agreements | Out-Host
            $used = "winget"
        } catch {
            Write-Warning "winget upgrade failed: $($_.Exception.Message)"
        }
    }

    if (-not $used -and (Test-Cmd scoop)) {
        try {
            & scoop update psmux | Out-Host
            $used = "scoop"
        } catch {
            Write-Warning "scoop update failed: $($_.Exception.Message)"
        }
    }

    if (-not $used -and (Test-Cmd choco)) {
        try {
            & choco upgrade psmux -y | Out-Host
            $used = "choco"
        } catch {
            Write-Warning "choco upgrade failed: $($_.Exception.Message)"
        }
    }

    if (-not $used -and (Test-Cmd cargo)) {
        try {
            & cargo install psmux --locked --force | Out-Host
            $used = "cargo"
        } catch {
            Write-Warning "cargo install failed: $($_.Exception.Message)"
        }
    }

    if (-not $used) {
        Write-Warning "No supported package manager found. Skipping binary upgrade."
    } else {
        Write-Host "Binary upgrade path used: $used" -ForegroundColor Green
    }
}

# 1) Upgrade psmux binary
Upgrade-Psmux

# 2) Detect active config based on psmux lookup order
$configCandidates = @(
    (Join-Path $HOME ".psmux.conf"),
    (Join-Path $HOME ".psmuxrc"),
    (Join-Path $HOME ".tmux.conf"),
    (Join-Path $HOME ".config\psmux\psmux.conf")
)

$activeConfig = $null
foreach ($candidate in $configCandidates) {
    if (Test-Path $candidate) {
        $activeConfig = $candidate
        break
    }
}

if (-not $activeConfig) {
    $activeConfig = $configCandidates[0]
    Ensure-File -Path $activeConfig
    Write-Host "Created new base config: $activeConfig" -ForegroundColor Yellow
} else {
    Write-Host "Using existing active config: $activeConfig" -ForegroundColor Cyan
}

$managedDir  = Join-Path $HOME ".config\psmux"
$managedFile = Join-Path $managedDir "capabilities.managed.conf"

# 3) Back up files before editing
Backup-IfExists -Path $activeConfig
if (Test-Path $managedFile) {
    Backup-IfExists -Path $managedFile
}

# 4) Ensure the managed include exists exactly once
Ensure-ParentDir -Path $managedFile
Ensure-File -Path $managedFile

$managedFileUnix = $managedFile -replace '\\','/'
$includeComment = '# psmux-managed include'
$includeLine    = 'source-file "' + $managedFileUnix + '"'

Append-Line-IfMissing -Path $activeConfig -Line $includeComment
Append-Line-IfMissing -Path $activeConfig -Line $includeLine

# 5) Add missing capabilities only; never overwrite existing options
$capabilities = @(
    @{
        Name  = "history-limit"
        Lines = @(
            "set -g history-limit 5000"
        )
    },
    @{
        Name  = "escape-time"
        Lines = @(
            "set -g escape-time 10"
        )
    },
    @{
        Name  = "status-interval"
        Lines = @(
            "set -g status-interval 5"
        )
    },
    @{
        Name  = "focus-events"
        Lines = @(
            "set -g focus-events on"
        )
    },
    @{
        Name  = "monitor-activity"
        Lines = @(
            "set -g monitor-activity on"
        )
    },
    @{
        Name  = "renumber-windows"
        Lines = @(
            "set -g renumber-windows on"
        )
    },
    @{
        Name  = "remain-on-exit"
        Lines = @(
            "set -g remain-on-exit on"
        )
    },
    @{
        Name  = "prediction-dimming"
        Lines = @(
            "set -g prediction-dimming off"
        )
    },
    @{
        Name  = "env-shim"
        Lines = @(
            "set -g env-shim on"
        )
    },
    @{
        Name  = "claude-code-fix-tty"
        Lines = @(
            "set -g claude-code-fix-tty on"
        )
    },
    @{
        Name  = "claude-code-force-interactive"
        Lines = @(
            "set -g claude-code-force-interactive on"
        )
    }
)

$combinedText = (Read-Text -Path $activeConfig) + "`n" + (Read-Text -Path $managedFile)
$added = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]

foreach ($cap in $capabilities) {
    if (Has-GlobalOption -Text $combinedText -OptionName $cap.Name) {
        $skipped.Add($cap.Name) | Out-Null
        continue
    }

    Append-ManagedBlock -Path $managedFile -Marker $cap.Name -Lines $cap.Lines
    $added.Add($cap.Name) | Out-Null

    # refresh combined text so the script stays idempotent within the same run
    $combinedText = (Read-Text -Path $activeConfig) + "`n" + (Read-Text -Path $managedFile)
}

# 6) Optionally apply without restarting, only if psmux is available and a server is running
if ($ApplyNow -and (Test-Cmd psmux)) {
    try {
        & psmux source-file $activeConfig | Out-Host
        Write-Host "Applied config to running psmux server." -ForegroundColor Green
    } catch {
        Write-Warning "Could not apply live. Restart psmux or run: psmux source-file `"$activeConfig`""
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Active config : $activeConfig"
Write-Host "Managed config: $managedFile"
Write-Host "Added         : $($added -join ', ')"
Write-Host "Skipped       : $($skipped -join ', ')"