@echo off
REM ============================================================
REM BarcaTeam Workspace Launcher (Windows + WSL)
REM ------------------------------------------------------------
REM Usage:   start.cmd [--reset] <repo1> [repo2] ...
REM Example: start.cmd investFlorida.ai str_simulation
REM          start.cmd --reset investFlorida.ai
REM
REM  Repo args can be:
REM    - a name : investFlorida.ai  -> expanded to ~/repos/<name> inside WSL
REM    - a Windows path : C:\repos\myrepo -> converted to WSL path
REM
REM  --reset  Kill existing tmux session and start fresh.
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

if "%~1"=="" (
    echo Usage: start.cmd [--reset] ^<repo1^> [repo2] ...
    exit /b 1
)

REM ---- Configurable settings ----
set DISTRO=Ubuntu
set WSLUSER=rbarcelo

REM ---- Convert this script's directory to a WSL path ----
set "SCRIPT_PATH=%~dp0"
set "SCRIPT_PATH=!SCRIPT_PATH:~0,-1!"
REM wslpath can't handle \\wsl.localhost\<DISTRO>\... UNC paths — strip the prefix manually
set "WSL_PREFIX=\\wsl.localhost\%DISTRO%"
if /i "!SCRIPT_PATH:~0,20!"=="\\wsl.localhost\" (
    set "SCRIPT_DIR=!SCRIPT_PATH:%WSL_PREFIX%=!"
    set "SCRIPT_DIR=!SCRIPT_DIR:\=/!"
) else (
    for /f "delims=" %%P in ('wsl -d %DISTRO% -u %WSLUSER% -- wslpath -u "!SCRIPT_PATH!"') do set SCRIPT_DIR=%%P
)

REM ---- Build args for start.sh (convert Windows paths, pass names as-is) ----
set ARGS=
:loop
if "%~1"=="" goto launch
set ARG=%~1
REM If arg looks like a Windows path (contains backslash or drive letter), convert it
echo !ARG! | findstr /r "^[A-Za-z]:\\" >nul 2>&1
if !errorlevel!==0 (
    for /f "delims=" %%P in ('wsl -d %DISTRO% -u %WSLUSER% -- wslpath -u "!ARG!"') do set ARG=%%P
)
set ARGS=!ARGS! "!ARG!"
shift
goto loop

:launch
wsl -d %DISTRO% -u %WSLUSER% bash -lc "sed -i 's/\r//' '!SCRIPT_DIR!/start.sh' && bash '!SCRIPT_DIR!/start.sh'!ARGS!"
