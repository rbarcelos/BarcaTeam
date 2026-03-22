# Sprint 2 Stakeholder Review — Consolidated

**Date**: 2026-03-19
**Sprint**: Model Accuracy Sprint 2
**Properties Reviewed**: Natiivo (borderline), Orlando (weak), Brickell (NO-GO)
**Decision**: **CONDITIONAL GO** for Chat MVP

---

## Scores

| Reviewer | Role | Score | Verdict |
|----------|------|-------|---------|
| CEO | Strategic readiness | 7/10 | CONDITIONAL GO |
| Investor | Business viability | 7/10 | CONDITIONAL GO |
| Buyer Agent | Client-readiness | 7/10 | CONDITIONAL GO |
| Mortgage Manager | Underwriting credibility | 7/10 | GO (conditional) |
| STR Operator | Operational realism | 6.5/10 | CONDITIONAL GO |
| **Average** | | **6.9/10** | **CONDITIONAL GO** |

Per the decision framework: Average confidence 5-7/10, no unanimous blockers → **CONDITIONAL GO**.
Fix blockers (1 week max), then proceed to Chat MVP.

---

## Blockers (Must Fix Before Chat MVP)

### B-1: Miami STR Tax Shows 12%, Should Be 14%
**Flagged by**: All 5 reviewers
**Impact**: $900-$2,200/year understated taxes per Miami property
**Root cause**: Florida DOR data file has the correct rates. `TaxRateProvider.total_rate` computes 14%. But the city resort tax component (`local_option_tax`) is dropped in the handoff to the financial calculation — reports show `local_option_tax: null`.
**AC-3 status**: FAIL (was reported as PASS in CAP_REVIEW)
**Affects**: All Miami, Miami Beach, Surfside, Bal Harbour, Bay Harbor Islands, North Bay Village, Key Biscayne properties.

### B-2: HOA Fees $0 on All Condo Properties
**Flagged by**: Mortgage Manager, STR Operator, Buyer Agent
**Impact**: $10,000-$18,000/year potential expense gap. Natiivo showed $1,100/mo HOA in Sprint 1.
**Root cause**: TBD — may be a data extraction regression or HOA field not being captured from Redfin.
**Risk**: Makes the one "positive" deal (Natiivo) likely cash-flow negative when corrected.

### B-3: Risk Badges Incorrect on Borderline/NO-GO Properties
**Flagged by**: Buyer Agent
**Impact**: CAUTION deal shows "No Significant Investment Risks Detected" green badge. NO-GO deals show "LOW RISK" with "0 critical, 0 manageable".
**Root cause**: Badge guard logic (Phase 3C) works at the viability level but the v2 report template risk assessment section has separate badge logic that wasn't updated.
**Note**: This directly contradicts Sprint 2's core goal of preventing misleading risk signals.

---

## Important Issues (Fix in Sprint 3 or Chat MVP Sprint)

### I-1: Viability Gates Null in Report JSON
**Flagged by**: CEO
**Detail**: `viability_index.gates: null`, `score: 0`, `label: "UNKNOWN"` on all three reports. Gate work produces correct verdicts but structured gate data absent from report payload. Chat MVP orchestrator needs this data programmatically.

### I-2: Risk Detail Arrays Empty
**Flagged by**: CEO
**Detail**: `major_risks`, `manageable_risks`, `risk_narratives`, `mitigation_strategies` all empty even on NO-GO properties. Deal-breaker banners render correctly, but the structured risk data is missing.

### I-3: AI Narrative Contradicts Model Data
**Flagged by**: Buyer Agent
**Detail**: AI-generated text says "20% management fees" when model uses 18%. AI pricing narrative fabricates "5.16% cap rate" and "-$5,064 cash flow" for Natiivo when actual model shows 9.38% and +$20,674. The LLM appears to compute its own numbers diverging from structured data.

### I-4: ADR-OCC Elasticity Possibly Inverted
**Flagged by**: STR Operator
**Detail**: Optimistic scenario appears to show higher ADR AND higher OCC; conservative shows lower both. Documented behavior is inverse coupling (ADR up → OCC down). Needs verification — may be a reporting artifact vs. actual calculation issue.

### I-5: Cleaning/Turnover Costs Absent
**Flagged by**: STR Operator (second sprint flagged)
**Detail**: No cleaning fees, turnover supplies, or guest amenities in expense breakdown. Typical $100-$200/turnover for a 1BD, $150-$300 for 3BD. Could be $3,000-$15,000/year depending on occupancy.

### I-6: Min-Stay Penalty Not Visibly Applied
**Flagged by**: STR Operator
**Detail**: Natiivo has 3-night HOA restriction detected, but the min-stay penalty application (-5% OCC, -5% ADR) is not visible in the report output. Calculation may be correct but user can't verify.

---

## What Sprint 2 Fixed Well (Reviewer Consensus)

- **Bad deals are now identified as bad deals** — NO-GO verdicts accurate with specific deal-breaker reasons
- **Variable cost scaling works correctly** — expenses differ proportionally across scenarios
- **DSCR lending context is clear** — threshold buckets, "Below Lender Minimum" labels
- **Management fee at 18%** — confirmed in all structured data
- **Deal-breaker banners render** — specific, quantified, prominent
- **"Credibility-destroying" → "Defensible"** — qualitative shift from Sprint 1

---

## Decision

**CONDITIONAL GO** — Proceed to Chat MVP after fixing blockers B-1, B-2, B-3.

**Recommended Sprint 3 scope** (1 week max):
1. Fix Miami STR tax handoff (B-1) — wire city resort tax through financial calculation
2. Investigate and fix HOA fee extraction regression (B-2)
3. Fix risk badge logic in v2 report template (B-3)
4. Wire viability gates into report JSON (I-1) — needed for Chat MVP
5. Populate risk detail arrays (I-2) — needed for Chat MVP

Issues I-3 through I-6 can be addressed during Chat MVP development or in a subsequent sprint.

---

## Individual Reviews

- [CEO Review](sprint2_ceo_review.md)
- [Investor Review](sprint2_investor_review.md)
- [Buyer Agent Review](sprint2_buyer_agent_review.md)
- [Mortgage Manager Review](sprint2_mortgage_manager_review.md)
- [STR Operator Review](sprint2_str_operator_review.md)
