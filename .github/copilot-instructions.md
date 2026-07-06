# BarcaTeam — GitHub Copilot CLI Instructions

BarcaTeam is a multi-agent software-delivery harness for **GitHub Copilot CLI**. You describe a problem; the `lead` agent discovers context, selects the right agents, plans, executes, and delivers — across one or more repositories.

## Entry point

For any non-trivial task, delegate to the **lead** agent (the orchestrator). Say what you want in natural language, e.g.:

> Use the lead agent to add a search bar to the dashboard that queries the listings API.

For simple questions that don't need a team, answer directly.

## How agents work here (Copilot-native)

- **Agents** live in `.github/agents/*.agent.md` and are auto-discovered by Copilot CLI (repository-level custom agents). Invoke them by name in a prompt, via `/agent`, or `copilot --agent=<name>`.
- **Skills** live in `.github/skills/*/SKILL.md` and are auto-loaded by relevance. Agents reference them by capability, not by hard-coded path.
- **Parallel work** uses Copilot's native subagent model — the model delegates to subagents, and `/fleet` runs subagents in parallel. Track progress with `/tasks`. There are **no tmux/psmux panes** — never reference them.
- **MCP servers** are configured in `.mcp.json` (memory) and `~/.copilot/mcp-config.json` (GitNexus, context7). Manage with `/mcp`.
- **Memory** uses Copilot's native `/memory` plus the memory MCP server.
- **Built-ins** replace former Claude plugins: `/review` (code review), `/security-review`, `/rubber-duck`, `/lsp`, `/delegate` (cloud PR).

## Orchestration model

The `lead` runs the pipeline: **Discover → Understand (parallel) → Plan → Design & Build (sequential) → Validate (parallel) → Deliver.** The lead coordinates and never writes code itself — it delegates to subagents.

- **Understand / Validate** phases fan out to multiple agents in parallel (`/fleet` or parallel subagent calls).
- **Design → Build** is sequential (architect → senior-engineer), gated by lead approval before coding.
- Loops between agents (e.g. QA → engineer → architect) are orchestrated by the lead re-invoking agents with feedback, since subagents are one-shot request/response.

## Issue-first workflow

- **Every user ask starts with a GitHub issue** (an epic), then child work items. File issues for every user-reported bug with clear repro, expected vs actual, location, and acceptance criteria.
- Reference issue numbers in commits and close issues when fixes are verified.

## Commit-first policy

- **Before any code change, commit and push the current state first.** Flow: new ask → `git status` → if dirty, stage + commit + push → then edit. This guarantees a clean revert point.

## Git & PR workflow

- Use the **git-workflow** skill for cap branches, worktrees, commits, and PRs.
- Capability work happens on a `cap/<slug>` branch; agents base changes off it.
- **Pre-merge gate:** for every PR touching > 1 file or > 30 LOC, run the **pr-merger** agent (which runs `/review` + a cross-tree typecheck) before `gh pr merge`. Merge only on a GO verdict.
- Include this trailer on commits unless told otherwise:
  `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`

## Cross-file safety

- Before any edit that touches 2+ files (shared types, helpers, prompts, status fields, render gates, extraction contracts), run **`gitnexus impact <symbol>`** first to surface the blast radius. Fall back to a thorough grep only if GitNexus is unavailable, and flag the gap.

## Cross-repo path rules (Windows)

- When an agent targets a different repo, pass explicit absolute paths:
  - File tools: Windows backslash paths — `C:\Users\rbarcelo\repo\<repo>\...`
  - Shell: `cd /c/Users/rbarcelo/repo/<repo> && <command>` (single line).

## Parallelization policy

- Maximize parallelism: partition work so no two agents edit the same files, then run them concurrently. Never serialize independent work.
- New user-reported issues mid-task → file the GH issue immediately and, when useful, start a background subagent to fix it without blocking the main thread.

## Safe autonomy

- **Autonomous (no gate):** identify issues, file/triage GH issues, dedupe & rank, investigate & fix, run tests/lint, commit & merge to `main`, update docs/memory, close verified issues.
- **Human-gated (explicit approval):** auth/security-sensitive changes, DB schema migrations, new external dependencies/infra cost, product-strategy pivots, deleting user data or production databases.

## Cross-repo standards

- Follow each target repo's `.github/` conventions (label schema, commit conventions, code-review, implementation guidelines, `copilot-instructions.md`). Repo-local standards override BarcaTeam defaults when working in that repo.
