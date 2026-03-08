@echo off
REM ============================================================
REM Claude Agent Teams Workspace Launcher (Windows + WSL)
REM ------------------------------------------------------------
REM Usage:   start-claude.cmd [--reset] <repo1> [repo2] ...
REM Example: start-claude.cmd C:\repos\frontend C:\repos\backend
REM          start-claude.cmd --reset C:\repos\frontend
REM
REM  --reset  Kill existing tmux session and start fresh with new repos.
REM           Without it, an existing session is re-attached as-is.
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

if "%~1"=="" (
    echo Usage: start-claude.cmd [--reset] ^<repo1^> [repo2] ...
    exit /b 1
)

REM ---- Configurable settings ----
set DISTRO=Ubuntu
set SESSION=barcateam

REM ---- Check for --reset flag ----
set RESET=0
if "%~1"=="--reset" (
    set RESET=1
    shift
)

if "%~1"=="" (
    echo Error: at least one repo path required.
    exit /b 1
)

REM ---- Convert this script's directory to a WSL path (strip trailing backslash first) ----
set "SCRIPT_PATH=%~dp0"
set "SCRIPT_PATH=!SCRIPT_PATH:~0,-1!"
for /f "delims=" %%P in ('wsl -d %DISTRO% -- wslpath -u "!SCRIPT_PATH!"') do set SCRIPT_DIR=%%P

REM ---- Build $REPOS (colon-separated WSL paths) from all arguments ----
set REPOS=
:loop
if "%~1"=="" goto launch
for /f "delims=" %%P in ('wsl -d %DISTRO% -- wslpath -u "%~1"') do set WSL_PATH=%%P
if "!REPOS!"=="" (set REPOS=!WSL_PATH!) else (set REPOS=!REPOS!:!WSL_PATH!)
shift
goto loop

:launch
echo.
echo  BarcaTeam ^— Starting agent orchestration hub...
echo  Repos: !REPOS!
if "!RESET!"=="1" echo  Mode: --reset ^(existing session will be killed^)
echo.

wsl -d %DISTRO% bash -lc "sed -i 's/\r//' '!SCRIPT_DIR!/launch.sh' && SESSION=%SESSION% REPOS='!REPOS!' RESET=!RESET! TEAM_DIR='!SCRIPT_DIR!' bash '!SCRIPT_DIR!/launch.sh'"
