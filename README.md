# BarcaTeam — AI Agent Orchestration Hub

BarcaTeam is a multi-agent software-delivery harness for **GitHub Copilot CLI**. You describe a problem; the `lead` agent discovers context, selects the right specialists, plans the work, drives implementation, validates the result, and delivers across one or more repositories.

The orchestration entry point is `.github/agents/lead.agent.md`. Users can start with `@lead`, or simply describe the problem in a BarcaTeam Copilot session and let the lead coordinate the flow: **Discover → Understand → Plan → Build → Validate → Deliver**.

## Get Started (one command)

Install the harness:

```powershell
# Windows (PowerShell)
.\scripts\install.ps1
```

```bash
# Linux / macOS
./scripts/install.sh
```

The installer verifies Node, GitHub CLI access, Copilot CLI, repo agents, skills, and MCP configuration. Copilot CLI is installed from npm package `@github/copilot`; the binary is `copilot`.

Launch BarcaTeam against one or more target repos:

```powershell
# Windows
.\start.ps1 C:\path\to\repo1 C:\path\to\repo2
```

```bash
# Linux / macOS
./start.sh /path/to/repo1 /path/to/repo2
```

The launchers run `copilot --add-dir <repo> ...`, so the lead agent can inspect and coordinate work across every repo you pass in.

## Health check

```powershell
.\scripts\doctor.ps1
```

```bash
./scripts/doctor.sh
```

The doctor script reports installed components, missing prerequisites, stale configuration, and copy-paste fixes. Use it after setup, after upgrading Copilot CLI, or whenever agents or skills do not appear as expected.

## Usage

Start BarcaTeam, then describe the outcome you want:

```text
@lead Add a search bar to the dashboard that queries the listings API.
```

You can also use Copilot CLI directly:

```powershell
copilot --add-dir C:\path\to\repo -p "@lead Investigate why the mobile login page crashes" --allow-all
```

Useful Copilot commands in this harness:

| Command | Use |
|---|---|
| `/fleet` | Run multiple subagents in parallel. |
| `/subagents` | Inspect and manage available subagents. |
| `/tasks` | Track delegated work. |
| `/skills` | See loaded project skills. |
| `/mcp` | Inspect MCP servers. |
| `/plugin` | Manage Copilot plugins. |
| `/memory` | Store and retrieve durable context. |
| `/review` | Run a code review pass. |
| `/security-review` | Run a security-focused review. |
| `/rubber-duck` | Talk through a problem. |
| `/lsp` | Use language-server support. |
| `/delegate` | Delegate cloud PR work. |

Custom agents are invoked by `@mention`, for example `@pm`, `@architect`, `@senior-engineer`, or `@qa`.

## How It Works

```text
  You: "Add search to the dashboard"
         │
         ▼
  ┌─────────────────────────────────────┐
  │  1. DISCOVER — Lead reads repos     │
  └──────────────┬──────────────────────┘
                 ▼
  ┌─────────────────────────────────────┐
  │  2. UNDERSTAND (parallel fleet)     │
  │  Domain agents + PM analyze the     │
  │  problem from multiple perspectives │
  │  ┌────┐ ┌────┐ ┌────┐              │
  │  │ DA │ │ PM │ │ UX │  in parallel  │
  │  └────┘ └────┘ └────┘              │
  └──────────────┬──────────────────────┘
                 ▼
  ┌─────────────────────────────────────┐
  │  3. PLAN — Lead merges findings,    │
  │  selects team, proposes approach    │
  └──────────────┬──────────────────────┘
                 ▼
  ┌─────────────────────────────────────┐
  │  4. DESIGN & BUILD (sequential)     │
  │  Architect ──→ Engineer             │
  │  gated by scope and design checks   │
  └──────────────┬──────────────────────┘
                 ▼
  ┌─────────────────────────────────────┐
  │  5. VALIDATE (parallel fleet)       │
  │  Same agents who discovered needs   │
  │  now verify the solution meets them │
  │  ┌────┐ ┌────┐ ┌────┐              │
  │  │ QA │ │ DA │ │ PM │  in parallel  │
  │  └────┘ └────┘ └────┘              │
  └──────────────┬──────────────────────┘
                 ▼
  ┌─────────────────────────────────────┐
  │  6. DELIVER — Lead aggregates       │
  │  results, evidence, and follow-ups  │
  └─────────────────────────────────────┘
```

## Key Insights

1. **Understand before planning.** Domain agents and PM analyze the problem in parallel before the lead creates a plan.
2. **Domain-first, PM as fallback.** If domain specialists fit the repo, they lead discovery. PM is always included as the generalist perspective.
3. **Same agents validate as discover.** The agents that identified needs re-check the final result against those needs.
4. **Agents are generic until launch.** They learn the target stack from the repos you pass with `--add-dir`: README files, docs, project instructions, tests, and code.
5. **Cross-file safety matters.** GitNexus is optional, but recommended as a standalone impact-analysis CLI before edits to shared types, helpers, prompts, extraction contracts, or status fields.

## Architecture

BarcaTeam is intentionally thin. Copilot CLI supplies the agent runtime; this repo supplies the operating manual, agent catalog, skills, launch scripts, and MCP configuration.

```text
barcaTeam/
├── .github/
│   ├── copilot-instructions.md      # canonical operating manual
│   ├── agents/*.agent.md            # 32 Copilot custom agents
│   └── skills/*/SKILL.md            # 21 Copilot skills
├── AGENTS.md                        # concise agent catalog
├── .mcp.json                        # project MCP config; memory server only
├── scripts/
│   ├── install.ps1 / install.sh     # install and configure the harness
│   └── doctor.ps1 / doctor.sh       # health checks and repair hints
├── start.ps1 / start.sh             # launch Copilot with --add-dir repos
├── docs/                            # migration notes and supporting docs
└── README.md
```

Copilot auto-discovers repo agents from `.github/agents/*.agent.md`, project skills from `.github/skills/*/SKILL.md`, and MCP servers from `.mcp.json`. There is no sync step.

## Agents

BarcaTeam currently includes **32 agents**.

### Core Team

| Agent | Role | Writes Code? | When Used |
|---|---|---:|---|
| `lead` | Orchestrator: discovers context, selects agents, plans, coordinates, delivers | No | Always; entry point for non-trivial requests |
| `pm` | Scope, acceptance criteria, PM briefs, issue framing | No | New capabilities, requirements, triage |
| `architect` | Solution design, contracts, technical decisions, sign-off | No | New capabilities, refactors, design reviews |
| `senior-engineer` | Execution plan, GitHub issues, implementation | Yes | Any task that changes code |
| `qa` | Acceptance validation, production readiness, test evidence | No | After implementation, before merge |
| `pr-merger` | Pre-merge gate using review and typecheck evidence | No | Before merging larger PRs |
| `docs-resolver` | Current library and SDK documentation | No | Before coding against fast-moving libraries |
| `mcp-infrastructure-engineer` | MCP API and tool ecosystem design | No | MCP servers, tool schemas, agent-facing APIs |

### Real Estate Domain Agents

| Agent | Role |
|---|---|
| `str-revenue-strategist` | STR revenue modeling, comp analysis, and investment underwriting |
| `persona-power-user` | AI-savvy investor evaluator for depth and explainability |
| `persona-international-investor` | International investor perspective |
| `persona-mortgage-manager` | Lending and financing perspective |
| `persona-buyer-agent` | Real estate buyer-agent perspective |
| `persona-regulatory-compliance` | STR regulatory, zoning, HOA, and tax perspective |
| `persona-str-operator` | Property operations and occupancy realism perspective |

### Quality, Strategy, and UX Agents

Examples include `ceo`, `investor`, `marketing-brand-strategist`, `copy-editor`, `security-reviewer`, `accessibility-reviewer`, `data-quality-auditor`, `competitor-analyst`, `information-architect`, `design-system-architect`, `ux-engineer`, `ux-critic`, `usability-reviewer`, `live-visual-qa`, `ux-qa-tester`, and `prompt-engineer`.

## Skills

BarcaTeam currently includes **21 skills** in `.github/skills/`. Copilot auto-loads relevant skills from their descriptions.

| Skill | Use |
|---|---|
| `context-discovery` | Standard repo, docs, and history discovery before capability work. |
| `document-templates` | Templates for PM briefs, architecture notes, execution plans, and QA reports. |
| `git-workflow` | Branch, worktree, commit, PR, and cleanup conventions. |
| `code-review-checklist` | Structured self-review and architecture sign-off checklist. |
| `engineer-workflow` | End-to-end implementation workflow for coding agents. |
| `issue-triage` | Triage open issues and produce labels, comments, closures, and summary. |
| `improvement-loop` | Autonomous product improvement cycle from signal to fix to validation. |
| `issue-templates` | Standard issue formats for tasks, bugs, and follow-ups. |
| `team-handoff` | Handoff format between PM, architect, engineer, QA, and specialists. |
| `automated-ux-audit` | Accessibility, visual, and interactive-element audit workflow. |

Other available skills include `accessibility-audit`, `ask-user-question`, `capability-init`, `competitor-benchmark`, `data-pipeline-audit`, `e2e-live-qa`, `finding-schema`, `mock-to-production`, `security-audit`, `solution-review`, and `ux-proposals`.

## Request Types

BarcaTeam classifies your request and picks agents accordingly:

| You Say | Classification | Typical Agents |
|---|---|---|
| "Build a search feature" | New capability | `pm` → `architect` → `senior-engineer` → `qa` |
| "The login page crashes on mobile" | Bug fix | `senior-engineer` → `qa` |
| "Refactor the API to use REST" | Refactor | `architect` → `senior-engineer` → `qa` |
| "How does auth work in this repo?" | Research | `lead`, `pm`, or a relevant specialist |
| "Review the database schema design" | Design review | `architect`, `data-quality-auditor` |
| "Evaluate the UX of the chat flow" | UX evaluation | `conversational-ux-engineer`, `ux-critic`, `ux-qa-tester` |
| "Get feedback from stakeholder personas" | Domain evaluation | Persona agents in parallel |
| "Audit for security risks" | Security review | `security-reviewer` plus `/security-review` |

## Adding Your Own Agents

Create a file named `.github/agents/<name>.agent.md`:

```markdown
---
name: my-agent
description: "What this agent does and when Copilot should use it."
---

# My Agent

You are responsible for ...

When invoked:
1. Discover relevant context.
2. Produce a clear plan.
3. Execute or review within your role.
4. Return concise evidence and follow-ups.
```

Copilot reads `name` and `description` from the frontmatter and uses the body as the agent's instructions. Agents inherit the session's available tools and project context; keep permissions and workflow rules in the instructions rather than adding unsupported frontmatter fields.

## Adding Domain Agent Packs

Domain packs let BarcaTeam adapt to a specific industry without changing the core workflow.

1. Add one or more agents in `.github/agents/` with focused domain roles.
2. Give each agent a clear `description` that explains when it should be used.
3. Add matching skills in `.github/skills/<skill-name>/SKILL.md` only when the domain needs reusable procedures.
4. Update `AGENTS.md` and this README if the pack should be visible to future users.
5. Run `./scripts/doctor.sh` or `.\scripts\doctor.ps1` to verify discovery.

A good domain pack includes both expert reviewers and stakeholder personas. The lead can then use `/fleet` to gather parallel signals before planning or validating work.

## MCP and Memory

Project MCP configuration lives in `.mcp.json`. BarcaTeam currently configures only the `memory` MCP server:

```json
{
  "mcpServers": {
    "memory": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "tools": ["*"]
    }
  }
}
```

Use Copilot's `/mcp` command to inspect server status and `/memory` for durable context.

## License

MIT
