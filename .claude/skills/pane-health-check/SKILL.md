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

2. For **every** pane including pane 0 (the lead), capture output:
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

5. For DEAD teammate panes (pane 1+):
   - Read the team config at `~/.claude/teams/<team-name>/config.json` to find the agent details
   - Apply the tmux send-keys workaround to relaunch:
     ```bash
     tmux send-keys -t barcateam:0.N C-c C-u
     tmux send-keys -t barcateam:0.N "\$env:CLAUDECODE='1'; \$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS='1'; claude --agent-id <name>@<team> --agent-name <name> --team-name <team> --agent-color <color> --parent-session-id <LEAD_SESSION_ID> --agent-type <type> --dangerously-skip-permissions --model sonnet" Enter
     ```
   - Verify the relaunched pane is alive after 5 seconds

## Lead Pane Recovery

If **pane 0 (the lead) is DEAD**, the teammate running the health-check loop must revive it. The lead does not auto-recover from CLI crashes (e.g., the `kXH → ek → kXH` render recursion that killed the lead on 2026-04-23).

Recovery procedure:

1. **Read the checkpoint** at `~/.claude/projects/C--Users-rbarcelo-repo-barcaTeam/memory/project_session_checkpoint.md`. This is the resume context.
2. **Run pre-spawn-check** — `.claude/skills/pre-spawn-check/SKILL.md`. The lead likely died because something in that list was broken; do not respawn into the same trap.
3. **Respawn the lead** in pane 0:
   ```bash
   tmux send-keys -t barcateam:0.0 C-c C-u
   tmux send-keys -t barcateam:0.0 "claude --dangerously-skip-permissions --model opus" Enter
   ```
   Once the UI appears, send the resume prompt (a two-line summary of the checkpoint plus "resume from checkpoint"):
   ```bash
   tmux send-keys -t barcateam:0.0 "Lead pane recovered after crash. Read project_session_checkpoint.md and resume." Enter
   ```
4. **Do not touch teammate panes.** They are still alive and will reconnect to the lead when it comes back up. Killing them loses in-flight work.

### Self-Referential Gotcha

The agent running `/pane-health-check` is itself on a teammate pane, so it *can* detect lead death. The failure mode is when the lead is the only thing running the loop (e.g., the user started `/loop` in the lead before spawning teammates). Mitigation: always start the loop from a teammate pane after `TeamCreate`, and fall back to the user manually invoking `/pane-health-check` from any surviving pane if the loop stops firing.

## Integration with TeamCreate

After every `TeamCreate`, the lead MUST start this loop:
```
/loop 5m /pane-health-check
```

This is documented in CLAUDE.md under the Pre-Spawn Checklist.
