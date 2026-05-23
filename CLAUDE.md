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

1. **Run `/pre-spawn-check`** — validates harness health (stale locks, settings JSON, hook scripts, MEMORY.md size, worktree placement). Stop on any `✗` and remediate before spawning. See `.claude/skills/pre-spawn-check/SKILL.md`. Skipping this is how the lead pane crashed on 2026-04-23.
2. **Re-read the "Psmux Agent Launch Bug" section below.** Agent tool spawns create panes but agents FAIL to start on Windows.
3. **After `Agent` spawns:** immediately run `tmux send-keys` workaround for EACH agent pane (see workaround section below).
4. **Verify each pane is alive:** `tmux capture-pane -t barcateam:0.N -p -S -5` — look for the Claude Code UI, not idle PowerShell prompts.
5. **Never trust "Spawned successfully"** — that message only means the pane was created, not that the agent process started.
6. **Start the pane health loop:** After all agents are verified alive, run `/loop 5m /pane-health-check` to auto-monitor and respawn dead panes every 5 minutes. See `.claude/skills/pane-health-check/SKILL.md`.

## Session Bootstrap

Run on every new lead session, in order:

```bash
git worktree prune                   # clear stale worktrees from prior crashes
ls .claude/session-checkpoint.md     # read it if present (see session-checkpoint skill)
```

Then run `/pre-spawn-check` once before the first `TeamCreate` of the session.

## Commit-First Policy

- **Before making ANY code changes**, commit and push the current state first. This is non-negotiable.
- Flow: new ask → `git status` → if dirty, stage + commit + push → then make edits.
- This ensures a clean checkpoint exists before every change, enabling easy revert and comparison.

## Worktree Policy

- **Use the `git-workflow` skill for all worktree operations.** The `agent-worktree` skill is deprecated — do not read it.
- **Worktrees live under `<repo>/.claude/worktrees/<name>/`.** The directory is gitignored. This matches reality (Agent tool's `isolation: worktree` writes here) and avoids cross-drive path issues that the temp-dir rule caused.
- **Always `git worktree prune` on session start** to clear stale entries from prior crashes.
- **Locked worktrees:** if a worktree shows `[locked]` in `git worktree list`, unlock it (`git worktree unlock <path>`) before re-spawning the agent.

## Session Persistence

- **Use the `session-checkpoint` skill** for all checkpoint operations. It defines when to write, when to read, the format, and the crash recovery protocol.
- **You MUST write a session checkpoint** before `TeamCreate`, before starting `/loop`, and before any autonomous run >20 tool calls. If no checkpoint exists at those boundaries, write one first — no exceptions. Lead-pane crashes are silent: without a checkpoint there is no way to recover state.
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

## Plugins & Skills

Plugins are installed in `~/.claude/plugins/` from the `claude-plugins-official` marketplace. Use them per the routing below.

| Capability | Plugin / Skill | When the lead must invoke it |
|---|---|---|
| **Cross-file impact + call-chain intelligence** | **`gitnexus` CLI + MCP** (skills: `gitnexus-cli`, `gitnexus-debugging`, `gitnexus-exploring`, `gitnexus-impact-analysis`, `gitnexus-pr-review`, `gitnexus-refactoring`, `gitnexus-guide`) | **Mandatory** before any engineer edits a shared type, helper, prompt, or extraction contract. Use `gitnexus impact <symbol>` to surface ALL consumers BEFORE the fix lands — replaces blind grep. The lead MUST cite GitNexus in dispatch prompts for cross-file work. Pre-merge: `gitnexus detect-changes` maps git diff hunks to affected execution flows. Skills auto-trigger on relevant prompts. |
| Current library docs (version-aware) | `context7` (MCP) via `docs-resolver` agent | Before any engineer writes code against an external library that may have changed (Next.js, React, Anthropic SDK, Playwright, FastAPI, SQLAlchemy, Pydantic, OpenAI SDK). Engineer is responsible for invoking; lead reminds in dispatch prompt. |
| Browser automation / live verify | `playwright` plugin OR `webapp-testing` skill | Required for `live-visual-qa`, `ux-qa-tester`. Required for every ux-engineer change before "ready to merge". |
| Pre-merge review gate | `pr-review-toolkit` via `pr-merger` agent | **Mandatory** for every PR > 1 file or > 30 LOC. Route between "engineer reports PR ready" and `gh pr merge`. No exceptions. |
| Security-sensitive edits | `security-guidance` hooks (passive) | Active on any edit touching auth, server endpoints, secrets, subprocess, file system, SQL, prompt construction. Hooks warn passively — engineer must resolve every warning before requesting sign-off. |
| TS / Python symbol intelligence | `typescript-lsp`, `pyright-lsp` | Engineers + architect use for impact analysis, especially when GitNexus / CodeGraph aren't initialized or don't cover a symbol. |
| UI / UX design intelligence | `frontend-design` (built-in), `uupm-design`, `uupm-design-system`, `uupm-brand`, `uupm-banner-design` skills | `ux-engineer`, `design-system-architect`, `ux-critic` reference these when polishing surfaces or evaluating consistency. |
| Repo memory health | `claude-md-management` | Architect runs it quarterly OR after major refactors. Lead invokes it when stale CLAUDE.md is suspected (e.g., agents keep making wrong recommendations). |
| Repo automation audit | `claude-code-setup` | One-shot per repo. Run once to surface hook/skill/MCP gaps; commit recommendations to `docs/claude-code-setup-recommendations.md` for follow-up. |

### GitNexus — first-class capability for cross-file work
GitNexus indexes a repo into a knowledge graph (call chains, dependencies, clusters, execution flows). Once indexed (`gitnexus analyze` from the repo root), every dispatched agent has MCP access to the graph.

**Hard rule:** Before any agent edits a symbol that crosses 2+ files (shared types, helpers, prompts, extraction contracts, status fields, render gates), the dispatch prompt MUST instruct the agent to run `gitnexus impact <symbol>` first. This single check would have prevented the SSOT regression cascade observed across #2658, #2675, #2680, #2709, #2732, #2740, #2746, #2762, #2764 — each was a "fix landed but another consumer reads stale source" pattern.

**Pre-merge pattern:** `gitnexus detect-changes` should run on every PR diff before merge. Catches BASE-mutation and predecessor-fallback regressions that the pre-merge gate alone misses.

**Web UI:** `gitnexus serve` exposes a local server (default `http://localhost:4747`) that `gitnexus.vercel.app` connects to for visual exploration. Useful for ad-hoc questions; not in the autonomous loop.

> Run `claude plugin list` to see which of these are actually installed for your user. Do NOT invoke a plugin that is not in the list.

### Hard rules
- **Never skip the pre-merge gate.** Two regressions in this codebase came from un-reviewed merges (the EarningsCard `-X theirs` overwrite, the dropped `submarketLabel`). The `pr-merger` agent exists to catch this class.
- **Engineers must invoke `docs-resolver` before coding against any fast-moving library.** Training-data API recall is unreliable for libraries that ship breaking changes.
- **Live-verify ALL UI changes before marking a PR ready.** Typecheck alone is insufficient — past PRs passed types but rendered broken UI.
- **GitNexus is mandatory first step for cross-file fixes.** When dispatching any agent whose work touches 2+ files (shared types, helpers, prompts, status fields, render gates, extraction contracts, fallback chains), the lead's dispatch prompt MUST include the boilerplate below. The agent must complete Step 0 and report findings BEFORE proposing or writing code.

### Dispatch-prompt boilerplate (cross-file fixes)

Paste this verbatim into every cross-file fix dispatch:

```
**Step 0 — GitNexus impact + context (mandatory, before any other work):**
1. `gitnexus impact <primary_symbol>` — list every consumer / caller. Surface the BLAST RADIUS.
2. `gitnexus context <primary_symbol>` — 360° view (callers, callees, processes).
3. If your change touches a shape/contract (Pydantic model, TS type, prompt field, status enum): also run `gitnexus impact <field_name>` for the specific field.
4. Report in your final return: (a) consumer list with file:line, (b) any consumers that look like they READ A STALE SOURCE (pattern: `?? someOldField`, `if (!x) x = ...`, deny-list checks), (c) confirmation that ALL consumers are covered by your fix OR a documented decision to skip a specific one with rationale.

If GitNexus is unavailable (CLI errors / not indexed): fall back to a thorough grep but flag the gap clearly in your return. Don't pretend the audit happened.
```

This boilerplate enforces the lesson from the SSOT regression cascade (#2658, #2675, #2680, #2709, #2732, #2740, #2746, #2762, #2764) — every one of those was a missed consumer that `gitnexus impact` would have flagged in seconds.

## Cross-Repo Standards

- **Always read and follow each target repo's `.github/` conventions** before filing issues, making commits, or opening PRs. Specifically:
  - Read `.github/label-schema.md` for required labels
  - Read `.github/commit-conventions.md` for commit format
  - Read `.github/code-review.md` for review process
  - Read `.github/implementation-guidelines.md` for safety gates
  - Read `.github/copilot-instructions.md` for project-specific rules
- These repo-local standards override barcaTeam defaults when working in that repo.

## Improvement Loop

The `/improvement-loop` skill runs an autonomous product improvement cycle. See `.claude/skills/improvement-loop/SKILL.md` for the full 10-step procedure.

**When the user asks to "review feedback", "triage feedback", "find and fix issues", or "run the improvement loop":**
1. Triage thumbs-down feedback from the DB (diagnose pending → file GH issues)
2. Confirm open GH issues are still valid (close already-fixed ones)
3. Optionally gather new signals (UX critic, persona agents)
4. Score and rank all findings by RICE
5. Fix, verify, learn

**Key principle:** Persona and UX critic agents are **signal generators only**. They produce findings. The lead/PM scores and ranks. Engineers fix. QA verifies.

## Safe Autonomy Policy

### Autonomous (no human gate needed)
- Identify issues, generate structured findings
- Query feedback DB, diagnose entries, file GH issues
- Deduplicate and rank by RICE score
- Investigate and fix code issues
- Run tests, linters, validation
- Commit and merge to main
- Update memory, docs, feedback DB status
- Close GH issues when fixes are verified
- Send WhatsApp summary

### Human-gated (requires explicit approval)
- Auth/security-sensitive changes
- Database schema migrations
- New external dependencies or infrastructure costs
- Broad product strategy pivots
- Deleting user data or production databases

## Parallelization Policy

- **Maximize parallelism at all times.** When fixing multiple issues, spin up as many parallel agents as possible via TeamCreate. Never serialize work that can run concurrently.
- **New user-reported issues → immediate background agent.** When the user posts a new issue mid-conversation, file a GH issue immediately, then evaluate whether to spin off a background agent to start fixing it. Never let a new issue block the main conversation thread.
- **Evaluate agent count per issue.** For each new issue, assess: can this be fixed by one agent, or does it need frontend + backend agents in parallel? Spin off the right number.
- **Never block the main thread.** The lead should remain responsive to the user. All implementation work should happen in teammate panes, not in the lead's thread.
- **Batch independent fixes.** When the user asks to fix multiple issues, launch all agents simultaneously — don't wait for one to finish before starting the next.

## Skills Index

All shared procedures live under `.claude/skills/<name>/SKILL.md`. Key ones:

- `pre-spawn-check` — harness health gate before any team spawn
- `pane-health-check` — periodic pane liveness verification (`/loop 5m`)
- `session-checkpoint` — write/read checkpoint before compaction & spawns
- `git-workflow` — worktree lifecycle, commits, PRs (replaces deprecated `agent-worktree`)
- `engineer-workflow` — full execution loop for coding agents
- `improvement-loop` — autonomous product improvement cycle
- `issue-triage` — PM-driven triage of open GH issues
- `mock-to-production` — 7-phase mock parity pipeline
- `team-handoff` — handoff format between PM/Architect/Engineer/QA
- `context-discovery` — standard repo/docs scan before capability work

Run `ls .claude/skills/` for the full set.
