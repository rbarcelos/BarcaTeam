# Solution Review

Multi-persona correctness audit with score tracking. User-invoked. Spawns all available reviewer agents in parallel, collects free-form assessments, tracks scores over time for convergence analysis. Based on [#1094](https://github.com/rbarcelos/investFlorida.ai/issues/1094).

## Trigger

User says: `/solution-review`, "run a full review", "review the product", "audit the solution", or similar.

## Philosophy

- **Reviews are free-form first, scores second.** Reviewers write their honest assessment without constraints. Scores are extracted as a structured byproduct at the end — never as a limiting framework.
- **Scores track trends, not truth.** A 7.5 today vs 7.0 last week tells a story. The absolute number matters less than the direction.
- **Every reviewer type is auto-loaded.** The skill discovers all available agent types and spawns them — no hardcoded list to maintain.
- **Fix while reviewing.** When early reviewers surface P0 bugs, spawn fix agents immediately — don't wait for all 12 reviews.

## Prerequisites

- Target repo must have `docs/product-context.md` (product mission, personas, UX principles)
- Review history lives at `docs/review-history/scores.json` in the target repo

## Acceptance Criteria (per cycle)

- [ ] All selected reviewers have submitted written assessments
- [ ] PM has produced a single consolidated spec with deduplicated, prioritized findings
- [ ] P0/P1 findings have GH issues filed
- [ ] Spec is committed to `docs/review-history/YYYY-MM-DD/UNIFIED_SPEC.md`
- [ ] Score history updated in `docs/review-history/scores.json`
- [ ] P0 fixes either landed or in-flight before cycle ends

## Deliverables

1. **Individual review documents** from each reviewer agent — one `.md` per agent
2. **PM-authored unified spec** — deduplicated, RICE-scored, prioritized findings
3. **Filed GH issues** for all P0/P1 findings not already tracked
4. **Score history update** — appended to `scores.json` for trend analysis
5. **WhatsApp summary** — score trend + P0 count sent to user

---

## The Review (7 steps)

### STEP 1: DISCOVER REVIEWERS

Auto-discover all available reviewer agent types. The canonical set:

**Persona agents (domain correctness):**

| Agent Type | Evaluates | Key Files to Review |
|-----------|-----------|-------------------|
| `persona-buyer-agent` | Speed of analysis, metric credibility, client-facing quality | DecisionSurface, OverviewCard, EarningsCard, ComparisonView, scoring logic |
| `persona-international-investor` | Transparency, regulatory clarity, realistic income modeling | InternationalBuyerCard, FinancingCard, defaults.py, WhatIfTab |
| `persona-mortgage-manager` | Conservative underwriting, stress-tested projections, DSCR | FinancingCard, defaults.py, DSCR/debt_service computation, scenario stress tests |
| `persona-power-user` | Data quality, transparency, explainability, scenario depth | Scoring formula (property_analyzer.py), agent system prompt, DecisionSurface, all data pipelines |
| `persona-regulatory-compliance` | STR regulations, zoning, HOA, tax accuracy | RegulationsCard, compliance/regulation logic in pipeline, risk assessment, disclaimers |
| `persona-str-operator` | Occupancy realism, cost assumptions, demand patterns | defaults.py (ALL expense assumptions), earnings computation, scenario presets, seasonality |

**Strategic agents (architecture & business):**

| Agent Type | Evaluates | Key Files to Review |
|-----------|-----------|-------------------|
| `architect` | Architecture, scalability, data contracts, code quality | Project structure (apps/, frontend/, packages/), API routes, DB layer, SSE streaming, data models |
| `ceo` | Product-market fit, ambition, strategic alignment | product-context.md, home page, session page, agent system prompt, competitive landscape |
| `investor` | Business viability, monetization, competitive positioning | product-context.md, data pipeline costs, auth/pricing (if any), growth vectors |
| `str-revenue-strategist` | Revenue model accuracy, comp analysis, underwriting | defaults.py, ADR estimation, occupancy modeling, expense calculation, scenario presets, sensitivity analysis |
| `conversational-ux-engineer` | Chat experience, agent orchestration, interaction quality | agent_system.md, ChatMessage, ChatTranscript, session page, tool definitions, streaming |
| `qa` | Test coverage, security, production readiness | Run pytest + vitest, test/ structure vs app/ structure, security headers, error handling, TypeScript health |

**Quality & audit agents (pipeline integrity, compliance, competitive):**

| Agent Type | Evaluates | Key Files to Review |
|-----------|-----------|-------------------|
| `competitor-analyst` | Feature gaps, competitive positioning, market differentiation | product-context.md, all user-facing features, pricing, data sources |
| `data-quality-auditor` | Data accuracy, pipeline integrity, cross-surface consistency | providers/, hydration, context_bridge, module_factory, workspace_compute, all display components |
| `accessibility-reviewer` | WCAG 2.1 AA compliance, keyboard nav, screen readers, contrast | All frontend components, report templates, chat interface |
| `copy-editor` | User-facing text clarity, terminology consistency, tone, disclaimers | agent_system.md, all components with text, error messages, report templates |
| `security-reviewer` | OWASP, secrets, auth, LLM security, data handling, privacy | API routes, DB queries, env config, system prompts, CORS, dependencies |

**Optional scope flags** (user can narrow the review):
- `--domain-only` — run only persona agents
- `--strategic-only` — run only strategic agents
- `--agent <name>` — run a single specific agent
- Default: run all 12

### STEP 2: PREPARE REVIEW CONTEXT

Before spawning, assemble the review context each agent needs:

```bash
# Verify prerequisites exist
cat docs/product-context.md     # Product context
git log --oneline -20            # Recent changes
gh issue list --state open --limit 20  # Open issues for context

# Load previous cycle scores (if any) — for lead's consolidation only, NOT shared with reviewers
cat docs/review-history/scores.json 2>/dev/null || echo '{"cycles":[]}'
```

Create the output directory for this cycle:

```bash
CYCLE_DATE=$(date +%Y-%m-%d)
mkdir -p docs/review-history/$CYCLE_DATE
```

### STEP 3: SPAWN REVIEWERS

Spawn all selected agents in parallel using the Agent tool with `run_in_background: true`. Each agent receives:

1. **Product context** — path to `docs/product-context.md`
2. **Review scope** — specific files/areas from the "Key Files to Review" column above
3. **Output instructions** — write assessment to `docs/review-history/$CYCLE_DATE/<agent-name>.md`
4. **Assessment format** — the template below (free-form first, scores as appendix)

**IMPORTANT:** Do NOT share previous scores with reviewers — it biases them. They review blind.

**Assessment format** (each reviewer writes free-form with this structure):

```markdown
# <Agent Name> Review
**Date:** YYYY-MM-DD
**Reviewer:** <agent type>

## Assessment
<Free-form, unconstrained evaluation from this persona's perspective.
Write as much or as little as needed. No format restrictions.
Focus on what matters most from YOUR viewpoint.
Call out what's good, what's broken, what's missing, what's dangerous.>

## Findings
<Numbered list of specific issues/improvements, each with:>
- **Severity:** P0/P1/P2/P3
- **Description:** What's wrong or missing
- **Impact:** Why it matters from this persona's perspective
- **Recommendation:** What to do about it

## Scores
<!-- These scores are for trend tracking only. They do NOT limit your assessment above. -->
| Dimension | Score (1-10) | Notes |
|-----------|-------------|-------|
| Overall | X | One-line summary |
| Data Accuracy | X | Are the numbers right? |
| User Experience | X | Is it usable and clear? |
| Trust & Safety | X | Would you bet money on this? |
| Completeness | X | What's missing? |

## Verdict
<One paragraph: your bottom-line recommendation>
```

**Key rule:** The free-form Assessment and Findings sections are the PRIMARY output. Scores are a structured appendix for tracking — reviewers must NOT constrain their assessment to fit the scoring dimensions.

### STEP 4: COLLECT & CONSOLIDATE (PM produces unified spec)

After all agents complete, **spawn a PM agent** to read all assessments and produce the unified spec.

**File:** `docs/review-history/$CYCLE_DATE/UNIFIED_SPEC.md`

This is the **single aggregate document** that summarizes, maps, and consolidates all reviewer results. Engineers, the lead, and future review cycles all work from this document — nobody should need to read individual review files.

Contents:
1. **Executive Summary** — overall product state, average scores, trend vs previous cycle
2. **Score Matrix** — all reviewers x all dimensions in one table
3. **Deduplicated Findings** — merge overlapping findings, keep highest severity. If 3 reviewers found the same bug, it's ONE entry citing all sources.
4. **Prioritized Backlog** — RICE-scored list of all unique findings (P0 → P1 → P2 → P3), each with severity, description, impact, recommendation, and mapped GH issue number
5. **Cross-Cutting Themes** — patterns the PM noticed across multiple reviewers (e.g., "screening vs underwriting gap", "multi-market imperative")
6. **Delta from Previous Review** — what improved, what regressed, what's new
7. **GH Issue Map** — table mapping every P0/P1 finding to its GH issue number (existing or newly filed)

### STEP 5: FILE ISSUES & ACT

- File GH issues for all P0 and P1 findings not already tracked
- Reference the unified spec in each issue
- If there are P0 findings, flag them for immediate fix (can trigger `/improvement-loop`)

### STEP 6: UPDATE SCORE HISTORY

Append this cycle's scores to the tracking file:

**File:** `docs/review-history/scores.json`

```json
{
  "cycles": [
    {
      "date": "2026-03-31",
      "commit": "87ce18f",
      "reviewers": {
        "buyer-agent": { "overall": 7.5, "data_accuracy": 8, "user_experience": 7, "trust_safety": 7, "completeness": 6 },
        "international-investor": { "overall": 7.0, "data_accuracy": 7, "user_experience": 6, "trust_safety": 6, "completeness": 5 },
        ...
      },
      "averages": { "overall": 7.2, "data_accuracy": 7.5, "user_experience": 7.0, "trust_safety": 6.8, "completeness": 6.2 },
      "p0_count": 2,
      "p1_count": 8,
      "issues_filed": [1396, 1397, ...]
    }
  ]
}
```

**Trend analysis:** When displaying results, always compare to the previous cycle:

```
Overall: 7.2 (+0.2 from 7.0 on 2026-03-26)
Data Accuracy: 7.5 (+0.5)  -- improving
Trust & Safety: 6.8 (+0.0)  -- stalled
Completeness: 6.2 (+1.2)   -- big jump (comparison view, PDF, intl)
P0 count: 2 (-2 from 4)    -- improving
```

---

## Output

At the end, produce a summary:

```markdown
## Solution Review Summary

**Cycle:** YYYY-MM-DD | **Commit:** <sha>
**Reviewers:** N agents | **Findings:** N total (N P0, N P1, N P2, N P3)

### Score Trend
| Dimension | Previous | Current | Delta |
|-----------|----------|---------|-------|
| Overall | X.X | X.X | +/-X.X |
| Data Accuracy | X.X | X.X | +/-X.X |
| User Experience | X.X | X.X | +/-X.X |
| Trust & Safety | X.X | X.X | +/-X.X |
| Completeness | X.X | X.X | +/-X.X |

### P0 Findings (blockers)
| # | Finding | Source | Issue |
|---|---------|--------|-------|

### P1 Findings (high priority)
| # | Finding | Source | Issue |
|---|---------|--------|-------|

### Convergence
<Are scores trending up? Which dimensions are stalling? What's driving improvement?>
```

---

## Rules

- **Free-form first, scores second.** Never tell reviewers to "score these dimensions" upfront. They write their assessment, THEN fill in scores.
- **Scores are 1-10 integers.** No half-points for tracking simplicity.
- **Every agent type gets spawned.** Don't skip agents because "they reviewed last time." Fresh eyes on fresh code.
- **Previous scores are context, not anchors.** Don't show reviewers their previous scores — it biases them.
- **Convergence tracking is descriptive, not prescriptive.** "Scores are going up" is an observation. "We need scores above 8" is a goal — goals belong in product-context.md, not here.
- **Always compare to last cycle.** If no previous cycle exists, note "first review — no baseline."
- **File issues for P0/P1 immediately.** Don't batch them for later.
- **PM MUST produce the Unified Spec.** This is the single aggregate document that maps all reviewer results. No next step should require reading individual review files — the unified spec is the source of truth for what was found.
- **Send WhatsApp summary** at end of cycle with score trend and P0 count.
