---
name: engineer-workflow
description: Standard execution workflow for all coding agents — worktree setup, planning, implementation, self-review, E2E gate, commit+merge, and handoff. Follow this in order for every capability.
---

# Engineer Workflow

Follow these steps in order for every capability. Do not skip steps.

## A) Execution Plan
- Produce `EXECUTION_PLAN.md` using the **document-templates** skill.
- Identify which work streams can run in parallel without file collisions.
- Create GitHub issues using the **Implementation Task** template from **issue-templates**.
- Link all issues from EXECUTION_PLAN.md.

## B) Worktree
Your worktree was created by the lead before you were spawned. Check your spawn prompt for `WORKTREE` and `BRANCH` — work exclusively in that path. Never work in the main repo directory.

If no worktree was provided, message the lead before touching any files.

## C) Implementation (test-first)
- Write or update tests BEFORE or alongside implementation, not after.
- Implement clean, minimal code following the Architecture doc.
- Run builds/tests/lints after each significant change.
- Commit after each logical unit of work — never at end of day.
- Use `explore` subagent for codebase investigation.
- Follow commit message conventions from **git-workflow**.

## D) Self-Review
Before requesting sign-off, run through the **code-review-checklist** skill:
- Fix any Critical or Major issues found.
- Document Minor issues in the PR description.

## E) E2E Gate
- Identify the key entrypoints and happy-path commands.
- Run them end-to-end and capture output as evidence.
- All must pass before proceeding.

## F) Commit & Merge to Cap Branch (REQUIRED before handoff)
1. Check for uncommitted changes: `git -C "$WORKTREE" status`
2. Commit anything remaining: `git -C "$WORKTREE" add -A && git commit -m "chore: finalise <cap_slug>"`
3. Run the **MERGE** operation from **git-workflow** — merge your agent branch into `cap/<cap_slug>` and push.
4. Open a PR per repo using the **PR Template** from **git-workflow**.
5. Verify the PR is open before sending handoff.

Never send a handoff with uncommitted or unmerged work.

## G) Handoff
Follow the **team-handoff** skill. Include in your message:
- Summary of what changed
- PR link(s)
- Test commands and evidence
- Known risks or deviations from Architecture doc
