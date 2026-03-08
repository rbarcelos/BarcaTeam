---
name: context-discovery
description: Standard procedure for discovering repos, reading project instructions, scanning docs, and mining history before starting any capability work.
---

# Context Discovery

Standard procedure for discovering project context. Run this BEFORE any other work.

## Steps

1. **Find all repos** you have access to:
   - Run `echo $REPOS` — when set, this contains colon-separated WSL paths to every repo passed via `--add-dir` at launch.
   - Parse each path: `IFS=':' read -ra REPO_PATHS <<< "$REPOS"` then inspect each entry.
   - If `$REPOS` is empty, fall back to listing parent/sibling directories and checking for `.git/` folders.

2. **Read project instructions** (in order of priority):
   - `CLAUDE.md` at repo root
   - `README.md` at repo root
   - `.github/copilot-instructions.md`

3. **Scan documentation**:
   - `docs/` directory (architecture decisions, ADRs, conventions)
   - `docs/capabilities/` for prior capability work
   - `CHANGELOG.md` or `HISTORY.md` for recent changes

4. **Identify key facts** and record them:
   - **Repos**: name, GitHub owner/org, local path, purpose (client/server/shared)
   - **Relationships**: how repos communicate (API calls, shared types, message queues)
   - **Tech stack**: languages, frameworks, key libraries
   - **Build/test/lint commands**: exact commands per repo
   - **Branching strategy**: main branch name, feature branch conventions
   - **Worktree conventions**: if documented, where worktrees are created

5. **Check for existing capability work**:
   - Search `docs/capabilities/` for the current capability slug
   - Read any existing PM_BRIEF.md, ARCHITECTURE.md, EXECUTION_PLAN.md, QA_REPORT.md
   - Do NOT overwrite existing work without understanding it first

6. **Mine recent history**:
   - `gh issue list --repo <owner/repo> --state closed --limit 20` for relevant prior decisions
   - `git log --oneline -20` for recent changes in affected areas

## Output
Summarize discovered context in a brief "Context" section at the top of your first message or output document. This ensures all downstream agents/readers have the same foundation.
