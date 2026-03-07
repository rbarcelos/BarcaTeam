# BarcaTeam — Copilot CLI Instructions

When a user describes a problem or asks a question, invoke the **@lead** agent.
The lead agent handles context discovery, agent selection, planning, and execution.

For simple questions that don't need a team, answer directly.

## Copilot-Specific Behavior

### Agent Invocation
Agents are available via `@agent-name` mentions. The lead agent coordinates the pipeline by invoking other agents sequentially:
1. `@lead <describe the problem>` — starts orchestration
2. Lead will call `@pm`, `@architect`, `@senior-engineer`, `@qa` as needed

### Limitations
Copilot CLI does not support native agent teams, so the lead agent coordinates manually by invoking agents one at a time in dependency order and passing deliverables between them.
