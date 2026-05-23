# UX Proposals

Multi-agent UX exploration cycle. Parallel proposals from diverse perspectives, PM consolidation, peer review, and a production-ready HTML mock as the final deliverable.

## Trigger

User says: `/ux-proposals`, "explore UX options", "come up with proposals for", or describes a UX problem needing multi-perspective exploration.

## Arguments

- `GOAL` (required): The UX question, design problem, or interaction to explore.
- `CONTEXT` (optional): Current state, files, constraints, screenshots, or prior art.

## Philosophy

Good UX decisions come from divergent thinking followed by convergent synthesis. No single perspective is complete. The cycle produces a single HTML mock that the user can open in a browser and evaluate visually — not abstract recommendations in markdown.

---

## THE CYCLE

```
PHASE 1: SCOPE & CAST              (Lead — 1 turn)
   ↓
PHASE 2: PARALLEL PROPOSALS         (N agents — concurrent)
   ↓
PHASE 3: CONSOLIDATION              (PM + Sr UX — sequential)
   ↓
PHASE 4: PEER REVIEW                (All original agents — concurrent)
   ↓
PHASE 5: FINAL PROPOSAL + HTML MOCK (PM → UX Engineer — sequential)
   ↓
USER REVIEW                         (User approves / iterates)
```

---

### PHASE 1: SCOPE & CAST

The lead analyzes the goal and selects 2-5 agents from this roster based on what the goal touches:

| Signal in Goal | Agent Types to Consider |
|---|---|
| Layout, visual, component design | `ux-engineer` |
| Content hierarchy, navigation, tabs, IA | `information-architect` |
| Copy, labels, microcopy, tone | `copy-editor` |
| Data display, metrics, numbers | `data-quality-auditor` |
| Domain-specific metrics (STR, finance) | `str-revenue-strategist` |
| Competitive patterns | `competitor-analyst` |
| Accessibility, keyboard, ARIA | `accessibility-reviewer` |
| End-user validation | `persona-buyer-agent`, `persona-power-user`, `persona-mortgage-manager`, `persona-str-operator` |
| Architecture, API, data availability | `architect` |

**Rules:**
- Minimum 2 agents, maximum 5
- PM and UX Engineer are always part of Phase 3/5 — they don't need to be in the proposal set
- Each agent gets the same brief but brings their own lens
- Read relevant existing code/components before writing the brief so proposals are grounded in reality

**Output:** `reviews/ux-proposals/{sprint-name}/roster.md`

---

### PHASE 2: PARALLEL PROPOSALS

Each selected agent receives the same brief:

```
## UX Exploration Brief

**Goal:** {GOAL}

**Context:** {CONTEXT}

**Current implementation:** {what exists today — read from code}

**Your role:** {AGENT_TYPE}

**Deliverable:** Write to reviews/ux-proposals/{sprint-name}/{agent_type}-proposal.md

**Format:**
1. **Problem** (1-2 sentences — what's broken or missing from your perspective)
2. **Proposal** (concrete, specific, implementable)
   - Layout: describe component hierarchy, grid/flex, spacing
   - Content: what data fields, labels, values
   - Interaction: hover states, click behavior, transitions
   - What to add, what to remove, what to move
3. **Rationale** (why this approach, what alternatives you rejected)
4. **Trade-offs** (what you're sacrificing, risks)
5. **Scope** (S/M/L)
```

All agents run **concurrently**. No agent sees another's proposal.

---

### PHASE 3: CONSOLIDATION

**PM agent** reads all proposals and produces a consolidated draft:
1. Identify convergence — where do multiple agents agree?
2. Identify conflicts — pick winners with rationale
3. Synthesize into a single unified proposal
4. Flag open questions for user

**UX Engineer** reviews the PM's draft for visual coherence and feasibility.

**Output:** `reviews/ux-proposals/{sprint-name}/consolidated-proposal.md`

---

### PHASE 4: PEER REVIEW

Each original proposal agent reviews the consolidated proposal:

```
**Verdict:** APPROVE / APPROVE_WITH_CHANGES / REJECT
**Strengths:** what the consolidation got right
**Concerns:** what was lost or doesn't work
**Suggested changes:** specific, actionable
```

All reviewers run **concurrently**.

**Output:** `reviews/ux-proposals/{sprint-name}/{agent_type}-review.md`

---

### PHASE 5: FINAL PROPOSAL + HTML MOCK

**PM** incorporates review feedback into a final spec.

**UX Engineer** builds a **standalone HTML mock** that:
- Opens in any browser with no build step
- Uses inline CSS (no external dependencies except Google Fonts)
- Shows realistic data (not lorem ipsum)
- Includes all relevant states (loading, empty, populated, error if applicable)
- Matches the existing product's design language when context is provided
- Is inspectable — reviewers can open DevTools and see exact CSS values
- Includes an annotation section at the bottom explaining key design decisions

**Output:**
- `reviews/ux-proposals/{sprint-name}/FINAL-PROPOSAL.md` — implementation spec
- `reviews/ux-proposals/{sprint-name}/mock.html` — the HTML mock (**primary deliverable**)

The lead presents the mock path to the user so they can open it in a browser.

---

## FILE STRUCTURE

```
reviews/ux-proposals/{sprint-name}/
  roster.md                          # Phase 1
  {agent_type}-proposal.md           # Phase 2 (one per agent)
  consolidated-proposal.md           # Phase 3
  {agent_type}-review.md             # Phase 4 (one per agent)
  FINAL-PROPOSAL.md                  # Phase 5
  mock.html                          # Phase 5 — PRIMARY DELIVERABLE
```

`{sprint-name}` is a kebab-case slug derived from the goal (e.g., `adr-breakdown`, `what-if-editor`, `empty-states`).

---

## TIMING

| Phase | Duration | Parallelism |
|-------|----------|-------------|
| 1. Scope | ~1 min | Sequential |
| 2. Propose | ~3-5 min | All concurrent |
| 3. Consolidate | ~3 min | PM → UX sequential |
| 4. Review | ~2-3 min | All concurrent |
| 5. Final + Mock | ~5 min | PM → UX sequential |
| **Total** | **~15-20 min** | |

---

## RECOVERY

All artifacts persist in `reviews/ux-proposals/{sprint-name}/`. To resume:
1. Check which phase files exist
2. Resume from the next incomplete phase
3. Phases are idempotent — re-running overwrites output

---

## EXAMPLES

```
/ux-proposals How should the ADR/OCC derivation breakdown be displayed? Currently too dense in EarningsCard.
```

```
/ux-proposals Redesign the What-If editor for better discoverability.
```

```
/ux-proposals How should empty states look across all tabs when data is loading or unavailable?
```
