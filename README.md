# BarcaTeam — AI Agent Orchestration Hub

BarcaTeam is an AI-powered software delivery team that lives in a single folder. You describe a problem, and BarcaTeam automatically picks the right agents, creates a plan, and delivers the implementation — across one or more repositories.

It works with **Claude Code** and **GitHub Copilot CLI** using the same agent definitions.

## Quick Start

```bash
# Claude Code (full agent team orchestration)
start-claude.cmd C:\path\to\repo1 C:\path\to\repo2

# Copilot CLI (agents via @mention)
start-copilot.cmd C:\path\to\repo1 C:\path\to\repo2

# Then just describe what you want:
> "Add a search bar to the dashboard that queries the listings API"
```

BarcaTeam will:

1. **Discover context** — reads each repo's README, docs/, project instructions
2. **Understand needs** — spawns domain agents + PM in parallel to analyze the problem from multiple perspectives
3. **Plan** — synthesizes findings, selects the right agents, writes `team_plan.md`, waits for your approval
4. **Design & Build** — architect designs, engineer implements (with lead approval gate before coding)
5. **Validate** — the same agents who identified needs now verify the solution meets them
6. **Deliver** — aggregates results, presents deliverables, asks for feedback

## How It Works

```
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
  │  selects team, writes team_plan.md  │
  │  → waits for user approval          │
  └──────────────┬──────────────────────┘
                 ▼
  ┌─────────────────────────────────────┐
  │  4. DESIGN & BUILD (sequential)     │
  │  Architect ──→ Engineer             │
  │  (lead approval gate before build)  │
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
  │  results, presents to user          │
  └─────────────────────────────────────┘
```

### The Key Insights

1. **Understand before planning.** Domain agents and PM analyze the problem in parallel *before* any plan is created. The lead synthesizes their findings into a unified Needs Summary.

2. **Domain-first, PM as fallback.** If domain agents exist for the project's domain, they lead discovery. PM is always included as the generalist perspective, and serves as the primary analyst when no domain experts apply.

3. **Same agents validate as discover.** The agents who identified the needs re-evaluate the solution against those same needs. This closes the loop and catches drift.

4. **Agents are generic.** They don't know your stack until launch. Context comes from the target repos' own files (`README.md`, `docs/`, project instructions).

## Architecture

```
agents/lead.agent.md             ← Orchestrator agent (platform-agnostic)
CLAUDE.md                        ← Claude-specific: "delegate to @lead"
.github/copilot-instructions.md  ← Copilot-specific: "delegate to @lead"
```

The orchestration logic lives in the **`lead` agent** — a platform-agnostic agent definition that knows how to discover context, classify requests, select agents, plan, execute, and deliver. Each platform's instruction file (`CLAUDE.md`, `.github/copilot-instructions.md`) is a thin wrapper that says "delegate to the lead agent" plus platform-specific controls.

## Agents

### Core Team (any project)

| Agent | Role | Writes Code? | When Used |
|---|---|---|---|
| `lead` | **Orchestrator** — discovers context, selects agents, plans, coordinates | No | Always — entry point for all requests |
| `pm` | Scope, acceptance criteria, PM Brief | No | New capabilities, requirements analysis |
| `architect` | Design, contracts, tech decisions, code review | No | New capabilities, refactoring, design reviews |
| `senior-engineer` | Execution plan, GitHub issues, implementation | **Yes** | Any task that changes code |
| `qa` | Validation, production readiness, test evidence | No | After implementation, before merge |
| `conversational-ux-engineer` | Chat/agentic UX design | No | Conversational UI, chat flows, agent interactions |
| `mcp-infrastructure-engineer` | MCP API and tool ecosystem design | No | API design, tool integration, MCP servers |

### Domain Agents (real estate)

Located in `agents/realstate/`. These are domain experts and stakeholder personas:

| Agent | Role |
|---|---|
| `str-revenue-strategist` | STR revenue modeling and underwriting |
| `persona-power-user` | Evaluates from AI-savvy investor perspective |
| `persona-international-investor` | Foreign investor perspective |
| `persona-mortgage-manager` | Lending/financing perspective |
| `persona-buyer-agent` | Real estate agent perspective |
| `persona-regulatory-compliance` | Regulatory/legal perspective |
| `persona-str-operator` | Property operations perspective |

### Adding Your Own Agents

Create a file in `agents/` with the `.agent.md` extension:

```yaml
---
name: my-agent
description: "What this agent does"
model: sonnet
tools:
  - Read
  - Grep
  - Glob
disallowedTools:
  - Write
  - Edit
---

# My Agent

Instructions for the agent...
```

The `.agent.md` format works with both Claude Code and Copilot CLI. Claude uses the full YAML frontmatter (model, tools, skills, memory). Copilot uses `name` and `description` and ignores the rest.

## Request Types

BarcaTeam classifies your request and picks agents accordingly:

| You Say | Classification | Agents Used |
|---|---|---|
| "Build a search feature" | New Capability | PM → Architect → Engineer → QA |
| "The login page crashes on mobile" | Bug Fix | Engineer → QA |
| "Refactor the API to use REST" | Refactor | Architect → Engineer → QA |
| "How does auth work in this repo?" | Research | PM (or just answers directly) |
| "Review the database schema design" | Design Review | Architect |
| "Evaluate the UX of the chat flow" | Domain Evaluation | conversational-ux-engineer |
| "Get feedback from stakeholder personas" | Domain Evaluation | persona agents (in parallel) |

## Setup

### Prerequisites

- **Claude Code**: [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- **Copilot CLI**: [GitHub Copilot in the CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) installed
- **Windows**: WSL with Ubuntu + tmux (for Claude's split-pane mode)
- Developer Mode enabled (for symlinks)

### First-Time Setup

```bash
# Clone this repo
git clone <this-repo-url>
cd BarcaTeam

# For Copilot: sync agents to user directory
sync-agents.cmd
```

### Launch

```bash
# Option A: Claude Code (full agent team orchestration, tmux split-panes)
start-claude.cmd C:\path\to\repo1 C:\path\to\repo2

# Option B: Copilot CLI (agents via @mention, sequential coordination)
start-copilot.cmd C:\path\to\repo1 C:\path\to\repo2
```

## Platform Comparison

| Feature | Claude Code | Copilot CLI |
|---|---|---|
| Agent definitions | ✅ Shared `.agent.md` | ✅ Shared `.agent.md` |
| Orchestrator workflow | ✅ `ORCHESTRATOR.md` | ✅ `ORCHESTRATOR.md` |
| Agent Teams (auto-coordination) | ✅ Native | ❌ Manual via @mentions |
| Task dependencies | ✅ Built-in | ❌ Lead coordinates order |
| tmux split-panes | ✅ Yes | ❌ No |
| Skills | ✅ `.claude/skills/` | ❌ Not supported |
| Agent memory | ✅ Persists across sessions | ❌ Not supported |

## Project Structure

```
BarcaTeam/
├── CLAUDE.md                    # Claude-specific: delegates to lead agent
├── README.md                    # This file
├── start-claude.cmd             # Launch Claude in tmux with Agent Teams
├── start-copilot.cmd            # Launch Copilot CLI with synced agents
├── sync-agents.cmd              # Sync agents to Copilot user dir
├── tmux-cheatsheet.md           # tmux keyboard reference
├── .github/
│   └── copilot-instructions.md  # Copilot-specific: delegates to lead agent
├── agents/                      # Agent definitions (shared format)
│   ├── lead.agent.md            # Orchestrator — entry point
│   ├── pm.agent.md
│   ├── architect.agent.md
│   ├── senior-engineer.agent.md
│   ├── qa.agent.md
│   ├── conversational-ux-engineer.agent.md
│   ├── mcp-infrastructure-engineer.agent.md
│   └── realstate/               # Domain-specific agents
│       ├── str-revenue-strategist.agent.md
│       └── persona-*.agent.md   # Stakeholder personas
└── .claude/
    ├── agents -> ../agents/     # Symlink for Claude agent discovery
    └── skills/                  # Skills (Claude-specific)
        ├── context-discovery.md
        ├── document-templates.md
        ├── git-workflow.md
        ├── code-review-checklist.md
        ├── issue-templates.md
        └── team-handoff.md
```

## Skills (Claude-specific)

Skills are reusable instruction sets that agents reference. They eliminate duplication and ensure consistency:

| Skill | Used By | Purpose |
|---|---|---|
| `context-discovery` | All agents | Standardized repo discovery procedure |
| `document-templates` | PM, Architect, Engineer, QA | Canonical output templates |
| `git-workflow` | Engineer | Worktrees, commits, PRs, branching |
| `code-review-checklist` | Architect, Engineer | 8-category review checklist with severity |
| `issue-templates` | Engineer, QA | GitHub issue formats for tasks and bugs |
| `team-handoff` | All agents | What to include when passing work to next agent |

## Adding Domain Agent Packs

Create a subdirectory under `agents/` for each domain:

```
agents/
├── fintech/
│   ├── risk-analyst.agent.md
│   └── persona-trader.agent.md
├── healthcare/
│   ├── hipaa-reviewer.agent.md
│   └── persona-clinician.agent.md
└── realstate/
    └── ... (existing)
```

BarcaTeam Lead will discover and use domain agents when they're relevant to the repos being worked on.

## License

MIT
