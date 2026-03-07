@echo off
REM Sync agents then launch Copilot CLI.
REM Usage: start-copilot.cmd <repo1> [repo2] [repo3] ...
REM Example: start-copilot.cmd C:\Users\rbarcelo\dev\ifai\investFlorida.ai C:\Users\rbarcelo\dev\ifai\str_simulation

call "%~dp0sync-agents.cmd"

if "%~1"=="" (
    echo Usage: start-copilot.cmd ^<repo1^> [repo2] [repo3] ...
    echo Example: start-copilot.cmd C:\path\to\repo1 C:\path\to\repo2
    exit /b 1
)

set ADD_DIRS=
:loop
if "%~1"=="" goto launch
set ADD_DIRS=%ADD_DIRS% --add-dir "%~1"
shift
goto loop

:launch
copilot %ADD_DIRS%
