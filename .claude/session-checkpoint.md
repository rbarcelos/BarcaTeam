# Session Checkpoint — 2026-05-23

## Status: PAUSED (wave 2 V7 blocked on data provider)

## Active focus
Mock-to-prod V7 Taxes & Compliance — 3-PR split (PR-A merged, PR-B/C blocked on data provider #2782).

## Shipped today (9 PRs to main)
| PR | Title | Commit |
|---|---|---|
| #2768 | ppsf + listing_status canonical reads | — |
| #2769 | whatif editor affordance | — |
| #2770 | InsightPanel split (refactor #1) | 05920f10 |
| #2771 | PropertyAnalyzer decompose (refactor #5) | 77ceadd9 |
| #2772 | StrTaxResult canonical contract | f78d464f |
| #2774 | calculate_str_tax caller migration (refactor #2 retarget) | (squash) |
| #2779 | SoldCompsCard empty state (#2766) | 7889941e |
| #2780 | mcp_server decompose (refactor #3) | 66cda188 |
| #2781 | V7 Wave 2 PR-A — orphan reads (#2775) | f55ec4a1 |

Plus direct push: `f5cd57b4` — V7 Wave 1 (Zones 1+2, heuristic defects fixed by #2781)

## Refactor leverage analysis status
| # | Item | Status |
|---|---|---|
| 1 | InsightPanel split | shipped |
| 2 | calculate_str_tax consolidation | shipped |
| 3 | mcp_server.py decompose (3,835 → 225 LOC) | shipped |
| 4 | _build_investment_context | deferred per user ("leave it") |
| 5 | PropertyAnalyzer decompose | shipped |

## Mock-to-prod V7 Taxes & Compliance progress
| Zone | Status |
|---|---|
| Zone 1 (KPIs) | Wave 1 scaffold (placeholders); rewire to real data in PR-C |
| Zone 2 (Tax Stack + provenance) | shipped (Wave 1 + PR-A real field reads) |
| Zone 3 (Property Tax + 5-yr forecast) | BLOCKED on #2782 (no assessed_value + millage provider) |
| Zone 4 (International — FIRPTA/W-8ECI/ITIN) | queued PR-C |
| Zone 5 (Depreciation Shield + MACRS) | queued PR-C |
| Zone 6 (Filing Calendar) | dropped per user |

## Open issues filed today
- **#2775** closed by #2781 — wave 1 orphan defect fix
- **#2776** paused — Wave 2 PR-B Zone 3 (blocked on #2782)
- **#2777** paused — Wave 2 PR-C Zones 4+5+Zone1 (depends on PR-B)
- **#2778** deferred — special_assessments real provider
- **#2782** BLOCKER — no provider for assessed_value + millage_rate

## Critical decisions made
- Miami +2% city resort tax lifted to canonical override table (Option A) — #2772
- Wave 2 split into 3 sequential PRs (A→B→C) — user approved after agent escalation
- FIRPTA threading: through `RulesTabData`, not new context route — user decision
- Zone 6 (Filing Calendar) dropped from V7 — user decision
- Special-assessments provider deferred (empty stub now) — user decision
- Refactor #4 (_build_investment_context) deferred — user said "leave it"

## Memory rules saved this session
- `feedback_verify_pr_base_branch` — dispatched agents must verify PR base = main (refactor #2 was merged into defunct sibling)
- `feedback_dispatched_agents_must_use_pr_gate` — dispatched agents must open PR + route through pr-merger (wave 1 direct-pushed to main)

## Next session — first moves
1. Read this checkpoint
2. **#2782 PIVOTED to US-wide** (product is WhatIfInvestments.ai, not Florida-only). FL cap math dropped. Per-county scraping infeasible nationally (~3000 counties). Lead decision: explore free/aggregate sources FIRST before paid providers.
3. Free sources to scope: Lincoln Institute (state effective rates), Census ACS B25103 (county median property tax), big-metro open-data portals, RealtyMole free tier.
4. Paid fallback if coverage insufficient: ATTOM Data (~$2-5k/mo, ~155M properties, best coverage).
5. Zone 1 shock banner deferred indefinitely — needs per-state reassessment rule data (CA Prop 13 vs TX resets vs most-states no-shock). Separate follow-up to be filed.
6. PR-C Zones 4+5 are federal (FIRPTA, MACRS, W-8ECI) — nation-agnostic, can ship without #2782. Zone 1 ships with shock-banner placeholder + working depreciation/after-tax-IRR halves.

## In-flight worktrees / branches
- Local `.claude/worktrees/refactor-str-tax-consolidate-retry/` still has the unsquashed copy of #2773's work (now redundant — #2774 cherry-pick is on main). Safe to `git worktree remove`.
- Multiple locked worktrees from prior sessions in `.claude/worktrees/agent-*` — clean up next session.

## GitNexus
Index refreshed this session post-merge cluster. Re-run `npx gitnexus analyze --embeddings` next session before any cross-file work.
