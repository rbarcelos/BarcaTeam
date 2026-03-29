---
name: session-checkpoint
description: Write and recover session checkpoints before/after team spawns and major milestones. Prevents context loss on crashes. Uses shadow-copy for corruption safety.
---

# Session Checkpoint

Persistent checkpoint that survives psmux/terminal crashes. Triggered automatically by the lead agent at specific moments in the workflow.

## Write Triggers (exhaustive)

| # | Moment | What to capture |
|---|--------|-----------------|
| 1 | **Before `TeamCreate`** | Plan, agent names, task assignments, issue numbers |
| 2 | **After agent completion handoff** | Update issue statuses, mark agent done, note deliverables |
| 3 | **After a GH issue is closed** | Update the issue tracker row (status → closed) |
| 4 | **After a PR is merged** | Record merge commit, update capability status |
| 5 | **On plan change** | If the user redirects mid-session, capture the new direction |
| 6 | **Before shutdown** | Final state snapshot so next session can cold-start |

## Read Triggers

| # | Moment | Action |
|---|--------|--------|
| 1 | **Session start** (first thing, before any work) | Read checkpoint, diff against reality (GH issues, git log) |
| 2 | **User asks to resume / "what were you doing"** | Read and summarize checkpoint |

## Storage: Shadow-Copy Pattern

**Primary file:** `~/.claude/projects/<project-key>/memory/project_session_checkpoint.md`
**Shadow file:** `~/.claude/projects/<project-key>/memory/project_session_checkpoint_prev.md`

Before every write:
1. Copy current `project_session_checkpoint.md` → `project_session_checkpoint_prev.md` (overwrite)
2. Write the new checkpoint to `project_session_checkpoint.md`

On read, if the primary file is missing or looks corrupted (empty, truncated, no frontmatter):
1. Fall back to `project_session_checkpoint_prev.md`
2. Log that the primary was corrupted

This gives one clean rollback without circular-buffer complexity.

## Checkpoint Format

```markdown
---
name: session-checkpoint
description: Last active work session state — read on startup to recover from crashes
type: project
---

## Active Capability: <cap-slug>

**Last updated:** <YYYY-MM-DDTHH:MM>
**Status:** <In progress | Blocked | Completed | Resuming after crash>

### Plan (summary)
<Numbered list of the agreed plan steps>

### Issue Tracker
| # | Priority | Type | Title | Status | Owner |
|---|----------|------|-------|--------|-------|
<All tracked issues with current status>

### Active Execution
**Team:** <team-name>
<Table of agents: name, task #, what they're working on>

### If Crashed — Recovery Steps
1. Read this checkpoint
2. Check which GH issues are still open: `gh issue list --label "<cap-label>" --state open`
3. Check git log on target repo: `git log --oneline -10`
4. Diff checkpoint state against reality
5. Respawn only agents whose issues are still open
6. Update this checkpoint with new agent names
```

## Recovery Protocol

When resuming after a crash:

1. Read `project_session_checkpoint.md` (fall back to `_prev` if corrupted)
2. Run `gh issue list` to see what's still open vs closed
3. Run `git log --oneline -10` on target repo for recent commits
4. Diff the checkpoint state against reality — identify what completed during the crash
5. Respawn only agents whose work is incomplete
6. Write a new checkpoint with updated agent names and statuses

## Rules

- The checkpoint is a **memory file**, not a task list — it captures session-level state
- Keep it concise — one screen of text max
- Always include recovery steps so a fresh session can pick up
- **Update, don't append** — the checkpoint reflects current state, not history
- The shadow copy is the only "history" — one level deep, no log accumulation
