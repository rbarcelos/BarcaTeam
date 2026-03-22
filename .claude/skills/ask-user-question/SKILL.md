---
name: ask-user-question
description: Standard format and protocol for agents to ask the user questions via AskUserQuestion tool. Ensures questions are clear, contextualized, and actionable.
---

# AskUserQuestion Protocol

Standard protocol for agents to ask the user questions. Follow this format every time you use the `AskUserQuestion` tool.

## When to Ask

- You need a decision that affects scope, direction, or approach
- You've found conflicting requirements and need a tiebreaker
- You're at a fork where both paths are reasonable
- You need domain knowledge that isn't in the codebase
- You've completed a review/analysis and need approval to proceed

## When NOT to Ask

- The answer is in the code, docs, or git history — look first
- It's a trivial implementation detail you can decide yourself
- You're asking just to confirm something obvious
- You already asked the same question earlier in the conversation

## Question Format

**ALWAYS follow this structure:**

### 1. Context (1-2 sentences)
State the project, current task, and what you're working on. Assume the user hasn't looked at this window in 20 minutes.

### 2. The Situation (plain English)
Explain the problem in plain language. No raw function names, no internal jargon. Use concrete examples. Say what it DOES, not what it's called.

### 3. Recommendation
```
RECOMMENDATION: Choose [X] because [one-line reason]
```
Always lead with your recommendation. If you don't have a preference, say so and explain why.

### 4. Options
Lettered options with clear descriptions:
```
A) [Option] — [what happens if chosen]
B) [Option] — [what happens if chosen]
C) [Option] — [what happens if chosen]
```

## Rules

- **One question at a time.** Never batch multiple decisions into one AskUserQuestion call.
- **Always recommend.** Don't punt the decision — give your best judgment and let the user override.
- **Be specific.** "Should we proceed?" is bad. "Should we add the 3 missing override fields (min_stay, pet_policy, parking_fee) to the chat agent's tool definitions?" is good.
- **Include consequences.** Each option should say what happens downstream if chosen.
- **Respect the answer.** Once the user decides, execute without re-litigating unless new information emerges.

## Example

```
**Context:** Reviewing the Agentic Chat MVP architecture for investFlorida.ai.

**Situation:** The architecture proposes SQLite for session persistence, but we already
have a PostgreSQL instance running for the main app. Using SQLite means a second database
to manage; using PostgreSQL means more setup but unified infrastructure.

**RECOMMENDATION:** Choose A — SQLite is simpler for MVP and can be migrated later.

A) SQLite for MVP — zero infrastructure overhead, easy to embed, migrate to Postgres later if needed
B) PostgreSQL now — unified infrastructure, but adds connection pooling and migration complexity to MVP scope
C) In-memory only — no persistence, sessions lost on restart (fastest to ship, but poor UX)
```
