# AGENTS.md — BarcaTeam

BarcaTeam is a multi-agent software-delivery harness for **GitHub Copilot CLI**.

**Start here:** delegate any non-trivial task to the **lead** agent. See `.github/copilot-instructions.md` for the full operating manual.

## Agent catalog

Agents are defined in `.github/agents/*.agent.md` and auto-discovered by Copilot CLI.

**Core team:** `lead` (orchestrator), `pm`, `architect`, `senior-engineer`, `qa`, `conversational-ux-engineer`, `ux-engineer`, `mcp-infrastructure-engineer`.

**Strategy:** `ceo`, `investor`, `marketing-brand-strategist`.

**Domain (real estate):** `str-revenue-strategist` + persona evaluators (`persona-power-user`, `persona-international-investor`, `persona-mortgage-manager`, `persona-buyer-agent`, `persona-regulatory-compliance`, `persona-str-operator`).

**Quality & audit:** `ux-critic`, `usability-reviewer`, `accessibility-reviewer`, `competitor-analyst`, `data-quality-auditor`, `copy-editor`, `security-reviewer`, `pr-merger`, `docs-resolver`, `design-system-architect`, `information-architect`, `prompt-engineer`, `live-visual-qa`, `ux-qa-tester`.

## Conventions

- **Skills:** `.github/skills/*/SKILL.md`, auto-loaded by relevance.
- **MCP servers:** `~/.copilot/mcp-config.json`.
- **Issue-first + commit-first:** file a GH issue before work; commit current state before editing.
- **Pre-merge gate:** run `pr-merger` before merging any PR > 1 file / > 30 LOC.
