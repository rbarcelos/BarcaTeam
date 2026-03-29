---
name: pane-health-check
description: Check all tmux agent panes are alive, report dead ones, and optionally respawn. Designed to run via /loop after TeamCreate.
---

# Pane Health Check

Monitors all tmux agent panes in the `barcateam` session and reports status. Dead panes are flagged for respawn.

## When to Run

- **Automatically via `/loop 5m /pane-health-check`** — started after every `TeamCreate`
- **Manually** — when the user asks to check pane health

## Procedure

1. List all panes:
   ```bash
   tmux list-panes -t barcateam:0 -F "#{pane_index}: #{pane_current_command} (pid #{pane_pid})"
   ```

2. For each pane (skip pane 0 — that's the lead), capture output:
   ```bash
   tmux capture-pane -t barcateam:0.N -p -S -5 | tail -5
   ```

3. Classify each pane:
   - **ALIVE** — Shows Claude Code UI (`@agentname`, `bypass permissions`, or active tool output)
   - **DEAD** — Shows bare PowerShell prompt (`PS C:\...>`), error messages, or is empty

4. Report status with timestamp:
   ```
   HH:MM Pane health check:
   - Pane 1 (@engineer): ALIVE
   - Pane 2 (@pm): DEAD — bare pwsh prompt
   ```

5. For DEAD panes:
   - Read the team config at `~/.claude/teams/<team-name>/config.json` to find the agent details
   - Apply the tmux send-keys workaround to relaunch:
     ```bash
     tmux send-keys -t barcateam:0.N C-c C-u
     tmux send-keys -t barcateam:0.N "\$env:CLAUDECODE='1'; \$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS='1'; claude --agent-id <name>@<team> --agent-name <name> --team-name <team> --agent-color <color> --parent-session-id <LEAD_SESSION_ID> --agent-type <type> --dangerously-skip-permissions --model sonnet" Enter
     ```
   - Verify the relaunched pane is alive after 5 seconds

## Integration with TeamCreate

After every `TeamCreate`, the lead MUST start this loop:
```
/loop 5m /pane-health-check
```

This is documented in CLAUDE.md under the Pre-Spawn Checklist.
