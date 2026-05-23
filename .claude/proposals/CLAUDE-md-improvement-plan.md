# CLAUDE.md Improvement Plan — barcaTeam

**Generated:** 2026-05-16 (audit)
**Skill applied:** `claude-md-management/claude-md-improver` (claude-plugins-official)
**Target file:** `C:\Users\rbarcelo\repo\barcaTeam\CLAUDE.md` (183 lines)

---

## Quality Report

### Summary
- Files audited: 1 (`./CLAUDE.md`)
- Overall score: **74/100 (Grade: B)**
- Status: solid, but stale in places and missing a couple of operational sections that hooks/skills already expect.

### Scorecard

| Criterion | Score | Notes |
|---|---|---|
| Commands/workflows | 14/20 | Plenty of "what to do" rules, very few actual copy-paste commands (only `tmux send-keys`, `git worktree prune`). No build/test/lint commands for the harness itself. |
| Architecture clarity | 16/20 | Roles (lead, teammates), skills folder, plugins table are clear. Missing a one-paragraph "what is barcaTeam" intro for fresh sessions. |
| Non-obvious patterns | 14/15 | The psmux backslash bug, lead-crash forensic note, and "Spawned successfully" warning are gold. |
| Conciseness | 11/15 | Some duplication: "File GitHub issues for every user-reported bug" appears under both "Issue-First Workflow" and is implied by "Safe Autonomy". The Pre-Spawn Checklist repeats content covered by the linked skill. |
| Currency | 9/15 | Worktree Policy contradicts reality — see Drift #1. Also references a `claude-ping` MCP that may have shifted. |
| Actionability | 10/15 | "Run `/pre-spawn-check`" is actionable; "Evaluate whether to spin off a background agent" is not. |

---

## Drift & Issues Found

### Drift #1 — Worktree Policy contradicts reality (HIGH)

CLAUDE.md says:
> Never create worktrees inside the repo (e.g., `.claude/worktrees/`). This causes nested git state issues and crashes psmux.
> Use a temp directory outside the repo: `$TEMP/barcateam-worktrees/`

Actual `git worktree list`:
```
C:/Users/rbarcelo/repo/barcaTeam/.claude/worktrees/agent-aade11f7f2e2ab90e     [locked]
C:/Users/rbarcelo/repo/barcaTeam/.claude/worktrees/ux-proposals-rules-property
```
`$env:TEMP\barcateam-worktrees\` does not exist. The recent Round 7 polish wave (commit `a8893c9`) and prior `/agent-worktree` flows have been writing under `.claude/worktrees/` for weeks.

**Decision required:** either
- (a) update the policy to match reality (`.claude/worktrees/` is allowed; `.claude/worktrees/` is in `.gitignore`; lead must `git worktree prune` on session start), or
- (b) re-establish the temp-dir rule and migrate the two live worktrees out.

Recommendation: **(a)**. Real-world ergonomics (path completion, IDE indexing, cross-tool path consistency) favour in-repo worktrees, and the original "nested git state crash" rationale has not recurred since psmux v0.x fixes. The skill `agent-worktree` is already marked deprecated and folded into `git-workflow` — that move should be reflected here too.

### Drift #2 — `agent-worktree` skill listed but deprecated (MEDIUM)

CLAUDE.md doesn't reference the skill by name, but the system-loaded skill list shows `agent-worktree: DEPRECATED — merged into git-workflow skill.` The Worktree Policy section is the right place to point at `git-workflow` SKILL.md so agents stop reading the deprecated one.

### Drift #3 — Unfinished/implicit cross-references (MEDIUM)

- "See `.claude/skills/pre-spawn-check/SKILL.md`" — exists, fine.
- "See `.claude/skills/pane-health-check/SKILL.md`" — exists, fine.
- "See `.claude/skills/improvement-loop/SKILL.md`" — exists, fine.
- No reference to `session-checkpoint` skill location (just the skill name). Minor — `.claude/skills/session-checkpoint/` exists.

### Issue #1 — Missing "Quick Start / Session Bootstrap" (MEDIUM)

A new session has no copy-paste opener telling the lead what to do first. Recommended snippet:
```bash
# Session bootstrap (run before any team work)
git worktree prune                          # clean stale worktrees
/pre-spawn-check                            # validate harness
# Read .claude/session-checkpoint.md if present
```

### Issue #2 — Plugins & Skills table references plugins that may not be installed locally (LOW)

The table claims `context7`, `playwright`, `pr-review-toolkit`, `security-guidance`, `typescript-lsp`, `pyright-lsp`, `uupm-*`, `claude-md-management`, `claude-code-setup`. `claude plugin list` should be the source of truth — recommend appending a one-line "Run `claude plugin list` to verify which of these are installed for your user" so agents don't hallucinate plugin invocations.

### Issue #3 — Duplication with global `~/.claude/CLAUDE.md` (LOW)

Several rules (commit-first, snapshot transitions, WhatsApp reply, monitor panes every 30min, session checkpoints, agent-paths) are also in MEMORY.md. This is intentional per the "Memory ↔ CLAUDE.md Sync" rule, but the project file should be the canonical authority and memory should just have pointers. Currently it's 50/50.

### Issue #4 — "Skills" trailing section is empty (LOW)

```
## Skills

Agents reference skills from `.claude/skills/` for shared procedures.
```
This is a stub. Either delete the heading or list the skills (there are 24 in `.claude/skills/`) with a one-liner per skill, so agents can discover them without `ls`.

---

## Top 3 Recommended Changes

1. **Reconcile Worktree Policy with reality.** Either flip the rule to "in-repo `.claude/worktrees/` is allowed; gitignored; prune on session start", or migrate live worktrees and keep the temp-dir rule. Today's mismatch silently teaches every spawned agent to do the wrong thing.
2. **Add a "Session Bootstrap" quick-start block** with the 3 commands every new lead session should run (`git worktree prune`, `/pre-spawn-check`, read checkpoint).
3. **Replace the empty "Skills" section** with a one-line-per-skill index (or remove it). Same for the half-empty "Plugins & Skills" — append the `claude plugin list` source-of-truth hint.

---

## Proposed Diff

````diff
@@ ## Worktree Policy @@
-## Worktree Policy
-
-- **Never create worktrees inside the repo** (e.g., `.claude/worktrees/`). This causes nested git state issues and crashes psmux.
-- **Use a temp directory outside the repo** for worktrees: `$TEMP/barcateam-worktrees/` (or `$env:TEMP\barcateam-worktrees\` on PowerShell).
-- Clean up stale worktrees on session start with `git worktree prune`.
+## Worktree Policy
+
+- **Use the `git-workflow` skill for all worktree operations.** The `agent-worktree` skill is deprecated — do not read it.
+- **Worktrees live under `.claude/worktrees/<name>/`** in this repo. The directory is gitignored.
+- **Always `git worktree prune` on session start** to clear stale entries from prior crashes.
+- **Locked worktrees:** if a worktree is locked, the lead must unlock it (`git worktree unlock`) before re-spawning the agent.

@@ after "## Routing Rules" — add new section @@
+## Session Bootstrap
+
+Run on every new lead session, in order:
+
+```bash
+git worktree prune                  # clear stale worktrees from prior crashes
+# Read .claude/session-checkpoint.md if present (see session-checkpoint skill)
+```
+Then run `/pre-spawn-check` once before the first `TeamCreate` of the session.

@@ ## Plugins & Skills — append a note @@
 | Repo automation audit | `claude-code-setup` | One-shot per repo. ... |
+
+> Run `claude plugin list` to see which of these are actually installed for your user. Do not invoke a plugin that is not in the list.

@@ ## Skills (trailing stub) @@
-## Skills
-
-Agents reference skills from `.claude/skills/` for shared procedures.
+## Skills Index
+
+All shared procedures live under `.claude/skills/<name>/SKILL.md`. Key ones:
+
+- `pre-spawn-check` — harness health gate before any team spawn
+- `pane-health-check` — periodic pane liveness verification (`/loop 5m`)
+- `session-checkpoint` — write/read checkpoint before compaction & spawns
+- `git-workflow` — worktree lifecycle, commits, PRs (replaces deprecated `agent-worktree`)
+- `engineer-workflow` — full execution loop for coding agents
+- `improvement-loop` — autonomous product improvement cycle
+- `issue-triage` — PM-driven triage of open GH issues
+- `mock-to-production` — 7-phase mock parity pipeline
+- `team-handoff` — handoff format between PM/Architect/Engineer/QA
+- `context-discovery` — standard repo/docs scan before capability work
+
+Run `ls .claude/skills/` for the full set.
````

---

## Out of Scope (not changing)

- Routing Rules, Commit-First, Issue-First, Parallelization, Safe Autonomy — all current and matched by behaviour. No change.
- Psmux Agent Launch Bug section — still load-bearing on Windows. No change.
- WhatsApp / claude-ping section — still accurate.
