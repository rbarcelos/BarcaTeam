@echo off
REM Sync generic agents to platform-specific locations.
REM
REM Claude Code:  handled automatically via .claude/agents → agents/ symlink (project-level)
REM Copilot CLI:  needs user-level symlinks since Copilot has no project-level agent discovery
REM
REM Run once after cloning, or after adding/removing agents.
REM Requires Developer Mode enabled (Settings > Developer Settings > Enable) for symlinks.

set AGENTS_DIR=%~dp0agents
set COPILOT_AGENTS=%USERPROFILE%\.copilot\agents

echo === Agent sync
echo.
echo  Source: %AGENTS_DIR%
echo  Claude: .claude\agents\ (directory symlink, already set up)
echo  Copilot: %COPILOT_AGENTS% (creating file symlinks)
echo.

REM Create Copilot agents dir if needed
if not exist "%COPILOT_AGENTS%" mkdir "%COPILOT_AGENTS%"

REM Symlink each .agent.md to Copilot user-level
for %%F in ("%AGENTS_DIR%\*.agent.md") do (
    if exist "%COPILOT_AGENTS%\%%~nxF" del "%COPILOT_AGENTS%\%%~nxF"
    mklink "%COPILOT_AGENTS%\%%~nxF" "%%F"
)

echo.
echo === Done.
echo.
echo  Edit agents in:  %AGENTS_DIR%
echo  Both platforms see the same files.
echo.
echo  Verify:
echo    dir "%AGENTS_DIR%\*.agent.md"
echo    dir ".claude\agents\*.agent.md"
echo    dir "%COPILOT_AGENTS%\*.agent.md"
