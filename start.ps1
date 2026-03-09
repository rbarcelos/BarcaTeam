# BarcaTeam Workspace Launcher
# Usage: .\start.ps1 [--reset] [-Session <name>] <repo1> [repo2] ...
# Example: .\start.ps1 investFlorida.ai str_simulation
#          .\start.ps1 -Session mywork investFlorida.ai
#          .\start.ps1 --reset investFlorida.ai

param(
    [switch]$Reset,
    [string]$Session = "barcateam",
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Repos
)

if ($Repos.Count -eq 0) {
    Write-Host "Usage: .\start.ps1 [--reset] <repo1> [repo2] ..."
    exit 1
}

$distro  = "Ubuntu"
$wslUser = "rbarcelo"

# Convert script dir to WSL path.
# PSScriptRoot is e.g. \\wsl.localhost\Ubuntu\home\rbarcelo\repos\barcaTeam
$scriptDir = $PSScriptRoot
if ($scriptDir -match '^\\\\wsl\.localhost\\[^\\]+(.+)$') {
    $wslScriptDir = $matches[1].Replace('\', '/')
} else {
    $wslScriptDir = (wsl -d $distro -u $wslUser -- wslpath -u $scriptDir).Trim()
}

# Build arg list for start.sh
$argList = @()
if ($Reset) { $argList += "--reset" }
if ($Session -ne "barcateam") { $argList += "--session"; $argList += $Session }
foreach ($repo in $Repos) {
    # Convert Windows drive paths (C:\...) to WSL paths; pass repo names as-is
    if ($repo -match '^[A-Za-z]:\\') {
        $repo = (wsl -d $distro -u $wslUser -- wslpath -u $repo).Trim()
    }
    $argList += $repo
}

$argsStr = ($argList | ForEach-Object { "`"$_`"" }) -join ' '
$cmd = "sed -i 's/\r//' '$wslScriptDir/start.sh' && bash '$wslScriptDir/start.sh' $argsStr"

wsl -d $distro -u $wslUser bash -lc $cmd
