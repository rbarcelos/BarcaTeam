# BarcaTeam — Claude Code Instructions

Agent teams are enabled. Ask Claude to spawn a team and describe what you want in natural language.

## Routing Rules

- **Every task in this repo is team work.** Always invoke `@lead`, always use `TeamCreate` with tmux panes. Never use background `Agent` subagents — the user needs visible panes to watch progress.
- If the user wanted solo work, they would be in the solution repo (`investFlorida.ai`, `str_simulation`) directly — not here.
- The lead orchestrates: spawns teammates, creates tasks, coordinates, and never implements directly.

## Controls

- `Ctrl+T` — toggle shared task list
- `Shift+Down` — cycle through teammates
- `Enter` — view a teammate's session
- `Escape` — interrupt a teammate's turn
- `Shift+Tab` — delegate mode (lead coordinates, doesn't implement)

## Skills

Agents reference skills from `.claude/skills/` for shared procedures.

# currentDate
Today's date is 2026-03-08.
