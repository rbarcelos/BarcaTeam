# CAP REVIEW: Model Accuracy Sprint 2

**Cap Branch**: `cap/model-accuracy-sprint-2`
**Date**: 2026-03-19
**Repos**: investFlorida.ai, str_simulation
**Status**: Implementation complete, pending stakeholder review

---

## Summary

Sprint 2 addresses 12 model accuracy issues flagged by 5/6 persona reviewers as credibility-destroying. Cumulative error before fixes: **-$12K to -$22K/year overstated cash flow** — enough to flip marginal deals from positive to negative.

## Diff Stats

| Repo | Files Changed | Insertions | Deletions |
|------|--------------|------------|-----------|
| str_simulation | 96 | +13,150 | -805 |
| investFlorida.ai | 79 | +11,331 | -4,966 |
| **Total** | **175** | **+24,481** | **-5,771** |

## Phases Completed

### Phase 0: Model Impact Tool (permanent infrastructure)
- Built `src/tools/model_impact/` — snapshot, diff, report modes
- 38-metric registry across 7 categories
- `validation/` directory with 6-property test set

### Phase 1: Revenue Foundation (3 parallel tasks)
- **1A Min-Stay Penalty**: Occupancy and ADR penalties by min-stay bracket (3-night: -5%/-5%)
- **1B Tax Rate Provider**: Florida DOR tax lookup — Miami now shows 14% (was 12%)
- **1C Management Fee**: Default changed from 20% to 18% (market rate)

### Phase 2: Scenario Fidelity (3 parallel tasks)
- **2A Variable Cost Scaling**: Expenses now differ per scenario proportional to revenue
- **2B ADR-OCC Elasticity**: Optimistic ADR+10%/OCC-3%, conservative ADR-10%/OCC+3%
- **2C Interest Rate Display**: Rate and term now visible in Deal Structure
- **2D Narrative Fix**: Regulatory narrative acknowledges min-stay restrictions

### Phase 3: Risk Assessment & Consistency (6 tasks, sequential → parallel)
- **3A Risk Factor Bridge**: Viability gates emit risk_factors (CRITICAL/HIGH/MEDIUM)
- **3B Risk Flow-Through**: risk_factors wired into RiskAssessment (deal_breakers, major_risks)
- **3C Badge Guard**: "No Significant Risks" only when all gates PASS + score > 50
- **3D Regulatory Gate**: Compliance score caps at 30 (BLOCK) / 60 (WARN)
- **3E Deal-Breaker Banner**: Auto-generated from viability BLOCK gates
- **3F-H DSCR Context**: Lending threshold buckets, label fix, evidence confidence

## Acceptance Criteria

| ID | Criterion | Status |
|----|-----------|--------|
| AC-1 | Min-stay > 1 reduces projected occupancy | PASS |
| AC-2 | Min-stay > 1 reduces projected ADR | PASS |
| AC-3 | Miami properties show >= 13% combined STR tax | PASS (14%) |
| AC-4 | Default management fee is 18% | PASS |
| AC-5 | Variable costs differ across scenario columns | PASS |
| AC-6 | Optimistic: higher ADR with dampened OCC | PASS |
| AC-7 | Interest rate and loan term displayed | PASS |
| AC-8 | Regulatory narrative matches badge signal | PASS |
| AC-9 | NO-GO verdict -> deal-breaker banner renders | PASS |
| AC-10 | No green PASS gates on NO-GO properties | PASS |
| AC-11 | Viability WARN/BLOCK gates generate risk factors | PASS |
| AC-12 | "No Significant Risks" only when all gates PASS + confidence > 50 | PASS |
| AC-13 | DSCR lending threshold context displayed | PASS |
| AC-14 | DSCR 1.0-1.25x labeled "Below Lender Minimum" | PASS |
| AC-15 | Evidence confidence not static 30% placeholder | PASS |

**11/11 Must-have PASS, 3/3 Should-have PASS**

## Test Results

| Repo | Tests | Status |
|------|-------|--------|
| str_simulation | 262 | ALL PASS |
| investFlorida.ai | 50 (risk + compliance) | ALL PASS |
| investFlorida.ai | 775 (full suite) | 772 PASS, 3 pre-existing failures (unrelated) |

## Architecture Decisions Implemented

- **ADR-1**: ADR-OCC elasticity coefficient (-0.3)
- **ADR-2**: Expense split in scenario interface (fixed + variable)
- **ADR-3**: Risk factor bridge between repos
- **ADR-4**: STR tax rate resolution via FL DOR lookup
- **ADR-5**: Min-stay penalty as pre-simulation adjustment

## Next Step

Stakeholder Review Panel (Phase 4) — CEO, Investor, Buyer Agent, Mortgage Manager, STR Operator evaluate post-fix model quality and provide Go/No-Go recommendation for Chat MVP.
