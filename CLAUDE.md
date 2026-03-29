# BarcaTeam — Claude Code Instructions

Agent teams are enabled. Ask Claude to spawn a team and describe what you want in natural language.

## Timestamps

- **Always include timestamps** in status updates, pane checks, and agent lifecycle events.
- Format: `HH:MM` (e.g., `11:25 — launching PM validator in pane 1`).
- Use `$(date +%H:%M:%S)` prefix in Bash commands for timing visibility.
- This applies to: agent spawns, task completions, pane health checks, milestone updates, and any user-facing status message.

## Routing Rules

- **Every task in this repo is team work.** Always invoke `@lead`, always use `TeamCreate` with tmux panes. Never use background `Agent` subagents — the user needs visible panes to watch progress.
- If the user wanted solo work, they would be in the solution repo (`investFlorida.ai`, `str_simulation`) directly — not here.
- The lead orchestrates: spawns teammates, creates tasks, coordinates, and never implements directly.
- **Monitor agent panes every ~30 minutes** during team sessions. Run `psmux list-panes` or `tmux list-panes` to verify all teammate panes are alive. Respawn any agents whose panes have crashed or been recycled.
- **Snapshot panes on every agent transition.** When an agent completes a task, starts a new task, or is shut down, capture a timestamped snapshot of all active panes: `tmux capture-pane -t barcateam:0.N -p -S -8 | tail -8`. This gives the user visibility into progress without switching panes.

### Pre-Spawn Checklist (MANDATORY before every Agent spawn)

The lead MUST execute this checklist before spawning any agents:

1. **Re-read the "Psmux Agent Launch Bug" section below.** Agent tool spawns create panes but agents FAIL to start on Windows.
2. **After `Agent` spawns:** immediately run `tmux send-keys` workaround for EACH agent pane (see workaround section below).
3. **Verify each pane is alive:** `tmux capture-pane -t barcateam:0.N -p -S -5` — look for the Claude Code UI, not idle PowerShell prompts.
4. **Never trust "Spawned successfully"** — that message only means the pane was created, not that the agent process started.
5. **Start the pane health loop:** After all agents are verified alive, run `/loop 5m /pane-health-check` to auto-monitor and respawn dead panes every 5 minutes. See `.claude/skills/pane-health-check/SKILL.md`.

## Worktree Policy

- **Never create worktrees inside the repo** (e.g., `.claude/worktrees/`). This causes nested git state issues and crashes psmux.
- **Use a temp directory outside the repo** for worktrees: `$TEMP/barcateam-worktrees/` (or `$env:TEMP\barcateam-worktrees\` on PowerShell).
- Clean up stale worktrees on session start with `git worktree prune`.

## Session Persistence

- **Use the `session-checkpoint` skill** for all checkpoint operations. It defines when to write, when to read, the format, and the crash recovery protocol.
- **Before spawning teams or starting major work**, write a session checkpoint to memory (`project_session_checkpoint.md`) with: active capability, current plan, issue status, and next steps.
- **On session start**, read the checkpoint to recover context from any prior crash.
- **Update the checkpoint** after every major milestone (issue closed, PR merged, plan changed).
- **CRITICAL: Before context compaction**, always trigger the `session-checkpoint` skill to write a snapshot. Context compaction loses conversation history — the checkpoint is the only way to recover state. This applies to both automatic compaction (approaching context limits) and manual compaction.

## Memory ↔ CLAUDE.md Sync

- When saving anything to memory, **evaluate whether it also belongs in CLAUDE.md**. Memory is personal recall across sessions; CLAUDE.md is the shared instruction set for all agents. If the information is a rule, convention, or process that agents need to follow, it goes in both places.

## Controls

- `Ctrl+T` — toggle shared task list
- `Shift+Down` — cycle through teammates
- `Enter` — view a teammate's session
- `Escape` — interrupt a teammate's turn
- `Shift+Tab` — delegate mode (lead coordinates, doesn't implement)

## WhatsApp (claude-ping)

- The `claude-ping` MCP server connects Claude to the user's WhatsApp.
- **Always check for incoming WhatsApp messages** periodically during long tasks using `whatsapp_receive`.
- **Always reply** to every WhatsApp message via `whatsapp_send`. Never read a message and leave it unanswered.
- At session start, call `whatsapp_login` to reconnect (should auto-authenticate without QR if session is saved).
- **Send a task summary via WhatsApp** at the end of every completed task using `whatsapp_send`. Keep it concise — what was done, key outcomes, and any follow-ups needed.

## Issue-First Workflow (MANDATORY)

- **Every user ask MUST start with a GitHub issue.** Before doing any design, implementation, or spawning agents, file a GH issue as an epic to track the request. Then break it into work items based on design and classification. This is non-negotiable — no work happens without a tracking issue.
- **Flow:** User ask → file epic issue → design/classify → file child work items → spawn agents referencing issue numbers.
- **File GitHub issues for every user-reported bug.** When the user reports a bug, unexpected behavior, or improvement, immediately file a GH issue with clear description, expected vs actual behavior, location, and acceptance criteria. Never let a report go untracked.
- **Close issues when fixed.** When implementing a fix for a tracked issue, reference the issue number in the commit and close it upon verification.
- **Only log warnings on final failure.** When a fallback chain exists (e.g., try live → try cache → fail), only log a WARNING if the entire chain fails. Log intermediate failures at DEBUG level.

## Cross-Repo Path Rules

- When spawning agents that target a different repo, **always include explicit absolute path instructions** in the agent prompt:
  - **Read/Write/Edit/Glob tools**: Windows backslash paths — `C:\Users\rbarcelo\repo\<repo>\...`
  - **Bash commands**: `cd /c/Users/rbarcelo/repo/<repo> && <command>` (single-line only, never standalone `cd`)
- **Never use PowerShell** (`Set-Location`, etc.) inside agents — bash only.
- Without explicit paths, agents concatenate the target path onto the primary working directory, producing broken paths.

## Psmux Agent Launch Bug (Windows) — MUST READ

**Bug:** psmux strips ALL backslashes from Windows paths when generating pane launch commands. This breaks both the `cd` path and the Claude CLI path. Result: TeamCreate/Agent spawns panes that immediately fail — agents never start.

**Do NOT try:** sending `bash` to fix panes — it opens WSL bash (not Git Bash), where `/c/` paths don't exist.

### Required Workaround

After `TeamCreate` + `Agent` spawns (which will create panes but fail to launch agents), **manually launch each agent** via `tmux send-keys` using PowerShell syntax:

```bash
tmux send-keys -t barcateam:0.N "\$env:CLAUDECODE='1'; \$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS='1'; claude --agent-id <name>@<team-name> --agent-name <name> --team-name <team-name> --agent-color <color> --parent-session-id <LEAD_SESSION_ID> --agent-type <type> --dangerously-skip-permissions --model sonnet" Enter
```

**Key details:**
- `claude` (CLI) IS in the PowerShell PATH — use it directly, not the full node path
- Escape the `$` as `\$` because the `tmux send-keys` command runs from bash
- `--parent-session-id` is the lead's own session ID (printed during TeamCreate)
- Colors: `blue`, `green`, `yellow`, `magenta` (one per agent)
- If a pane dies, recreate it with `tmux split-window -t barcateam:0 -v`
- Verify agents are running: `tmux capture-pane -t barcateam:0.N -p -S -5`

## Cross-Repo Standards

- **Always read and follow each target repo's `.github/` conventions** before filing issues, making commits, or opening PRs. Specifically:
  - Read `.github/label-schema.md` for required labels
  - Read `.github/commit-conventions.md` for commit format
  - Read `.github/code-review.md` for review process
  - Read `.github/implementation-guidelines.md` for safety gates
  - Read `.github/copilot-instructions.md` for project-specific rules
- These repo-local standards override barcaTeam defaults when working in that repo.

## Skills

Agents reference skills from `.claude/skills/` for shared procedures.
