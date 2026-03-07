@echo off
REM BarcaTeam — Launch Claude Code inside a tmux session with Agent Teams.
REM Usage: start-claude.cmd <repo1> [repo2] [repo3] ...
REM Example: start-claude.cmd C:\path\to\repo1 C:\path\to\repo2

if "%~1"=="" (
    echo Usage: start-claude.cmd ^<repo1^> [repo2] [repo3] ...
    echo Example: start-claude.cmd C:\path\to\repo1 C:\path\to\repo2
    exit /b 1
)

REM Build --add-dir flags and convert Windows paths to WSL paths
set ADD_DIRS=
:loop
if "%~1"=="" goto launch
for /f "delims=" %%P in ('wsl -d Ubuntu -- wslpath -u "%~1"') do set WSL_PATH=%%P
set ADD_DIRS=%ADD_DIRS% --add-dir %WSL_PATH%
shift
goto loop

:launch
REM Launch tmux session in WSL with BarcaTeam Lead (Claude) inside it
echo.
echo  BarcaTeam — Starting agent orchestration hub...
echo  Repos: %ADD_DIRS%
echo.
wsl -d Ubuntu -- bash -c "export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && cd /mnt/c/Users/rbarcelo/ifAI-agent && tmux new -s barcateam 'claude --teammate-mode tmux %ADD_DIRS%'"
