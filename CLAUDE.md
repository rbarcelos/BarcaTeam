# BarcaTeam — Claude Code Instructions

When a user describes a problem or asks a question, delegate to the **lead** agent.
The lead agent handles context discovery, agent selection, planning, and execution.

For simple questions that don't need a team, answer directly.

## Claude-Specific Configuration

### Agent Teams
This project uses Claude Code Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
The lead agent coordinates via shared task list, task dependencies, and plan approval gates.

### Controls
- `Ctrl+T` — toggle shared task list
- `Shift+Down` — cycle through teammates
- `Enter` — view a teammate's session
- `Escape` — interrupt a teammate's turn
- `Shift+Tab` — delegate mode (lead coordinates, doesn't implement)

### Skills
Agents reference skills from `.claude/skills/` for shared procedures.
