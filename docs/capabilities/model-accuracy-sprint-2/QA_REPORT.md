# QA Report: Model Accuracy Sprint 2
**Slug**: `model-accuracy-sprint-2`
**Date**: 2026-03-19
**Author**: QA Agent
**Commit (str_simulation)**: `5e88ad7` (cap/model-accuracy-sprint-2)
**Commit (investFlorida.ai)**: `e98bd0b` (cap/model-accuracy-sprint-2) + uncommitted stash changes

---

## Executive Summary

**Overall Verdict: BLOCKED — 2 Critical Issues, 1 Major Issue**

| Blocker | Severity | Description |
|---|---|---|
| Phase 3C/3D/3E not committed | Critical | Compliance gate, badge guard, and deal-breaker population changes exist only as an unstashed working-tree diff — NOT committed to cap branch |
| AC-14 FAIL: Miami tax 12% not 14% | Major | investFlorida.ai pipeline uses `scrape_tax_rates` (web search) which misses Miami's 2% city resort tax; `calculate_str_tax` MCP tool (FloridaDORProvider) returns 14% but isn't used in the tax-fetch path |

The sprint is **not production-ready** until Phase 3C/3D/3E changes are committed and AC-14 is resolved.

---

## Acceptance Criteria Results

| AC-ID | Description | Status | Severity | Evidence |
|---|---|---|---|---|
| AC-1 | Min-stay > 1 → OCC decreases by penalty table | PASS | — | 50 unit tests pass: `tests/core/test_minstay_penalty.py` all 50 PASS |
| AC-2 | Min-stay > 1 → ADR decreases (~2%/night, capped -8%) | PASS | — | Same 50 tests; test_min_stay_3_adr_reduced_by_5pct, test_seven_night_penalty_magnitude all PASS |
| AC-3 | ADR and OCC cannot both exceed 75th percentile | PASS | — | 2 elasticity unit tests + 134 ADR/OCC tests pass in str_simulation |
| AC-4 | Optimistic: higher ADR with dampened OCC (not both max) | PASS | — | 134 ADR/OCC tests pass; ADR-OCC coupling tests 2/2 PASS |
| AC-5 | Mgmt fee, STR tax, OTA commission differ across scenarios proportionally | PASS | — | Snapshot: expense_spread non-zero for all properties; `test_financial_calculations.py` 30/30 PASS |
| AC-6 | Conservative < base < optimistic variable costs | PASS | — | `scenarios.expense_spread` > 0 confirmed in all 6 snapshot properties |
| AC-7 | NO-GO → deal-breaker banner renders with ≥1 entry | PASS | — | Snapshot: brickell(NO-GO)=2, orlando(NO-GO)=2, edgewater(NO-GO)=2 deal_breakers |
| AC-8 | NO-GO → no individual gate shows green PASS | CANNOT VERIFY | Minor | Risk factor flow-through (Phase 3B) committed; gate display not directly testable from snapshot |
| AC-9 | Deal-breakers generated for profitability failures (DSCR<1.0, CoC<0) | PASS | — | Brickell: DSCR=0.03, CoC=-20.7% → 2 deal_breakers; Edgewater: DSCR=0.62, CoC=-8.1% → 2 deal_breakers |
| AC-10 | Deal structure shows interest rate and loan term | PASS | — | Phase 2C committed; `tests/models/test_context_models.py` pass |
| AC-11 | Default mgmt fee = 18% | PASS | — | `config.default_management_fee_pct = 0.18`; snapshot: all 6 properties show 18.0% |
| AC-12 | DSCR 1.0-1.25x → "Below Lender Minimum" label | CANNOT VERIFY | Minor | Phase 3F/3G/3H committed (92dccc2); report template not directly testable without live report |
| AC-13 | DSCR section shows lending threshold context (1.0x, 1.20x, 1.25x buckets) | PASS | — | Phase 3F-H committed; `tests/test_e2e_compliance_scoring.py` 34/34 PASS |
| AC-14 | Miami STR tax ≥ 13% (incl. city resort 2%), resolved via external API | **FAIL** | Major | `calculate_str_tax` MCP tool (FloridaDOR) returns 14% ✅; but `_fetch_api_tax_rates()` calls `scrape_tax_rates` (web search) which returns 12% ❌ — 2% city resort missed |
| AC-15 | Min-stay restriction → regulatory narrative acknowledges it | CANNOT VERIFY | Minor | Snapshot shows min_stay_detected=False for Natiivo (labeled "min-stay") — possible data or metric extraction issue |
| AC-16 | Evidence confidence scores are genuine (no static 30%) | PASS | — | Snapshot shows Analysis Confidence 60-85% varying by property; logs show event confidence 20-50% varying |

---

## Critical Finding: Phase 3C/3D/3E Changes Not Committed

**Severity: Critical — blocks release**

Phases 3C (No-Risks Badge Guard), 3D (Regulatory Gate Consistency), and 3E (Deal-Breaker Population) were marked as completed in the task system but their code changes were **never committed to `cap/model-accuracy-sprint-2`**.

The changes exist as an unstashed working-tree diff on `investFlorida.ai` (exposed by popping `stash@{0}`):

| File | Phase | Change |
|---|---|---|
| `src/pipeline/compliance_scoring.py` | 3D | Simplified gate cap logic: ANY BLOCK→≤30, ANY WARN→≤60 (removed PROCEED override) |
| `src/pipeline/property_analyzer.py` | 3E | Auto-generates deal_breakers for NO-GO when list empty (DSCR<1.0, CoC<0) |
| `src/reports/templates/v2_report/sections/investment_analysis/_tab_confidence.html` | 3C | "No Risks" badge guard: only shows when viability_score>50 AND no deal_breakers |
| `tests/test_e2e_compliance_scoring.py` | 3D | 34 new compliance scoring tests (all PASS with stash applied) |

**Evidence**: `git diff HEAD --stat` shows 110+ line changes; `git log` shows no Phase 3C/3D/3E merge commits.

**Required action**: Senior Engineer must commit and push these changes to cap branch before merging to main.

---

## Test Results

| Repo | Command | Result | Output |
|---|---|---|---|
| str_simulation | `pytest tests/ -q --ignore=tests/test_phase1_events.py --ignore=tests/unit/test_str_signals.py` | **2088 PASS / 31 FAIL / 88 ERR** | 31 failures are pre-existing (event_curation, phase3_market_enhancements); 88 errors are integration tests needing live server |
| str_simulation | `pytest tests/unit/test_tax_rate_provider.py tests/core/test_minstay_penalty.py tests/unit/test_financials.py` | **143/143 PASS** | All sprint-2 unit tests pass |
| investFlorida.ai | `pytest tests/ -q` | **822 PASS / 3 FAIL / 21 SKIP** | 3 failures are pre-existing (bypass_cache in test_mcp_client.py, STRActivityService) |
| investFlorida.ai | `pytest tests/models/test_viability_risk_flowthrough.py tests/services/test_financial_calculations.py tests/services/test_management_fee.py tests/services/test_str_tax_calculation.py` | **101/101 PASS** | All sprint-2 targeted tests pass |
| investFlorida.ai | `pytest tests/test_e2e_compliance_scoring.py` | **34/34 PASS** | Passes with Phase 3D stash changes applied |

### Pre-existing failures (NOT introduced by this sprint)

| Test | Repo | Failure Reason |
|---|---|---|
| `test_event_curation.py` (7 tests) | str_simulation | Pre-existing on main branch |
| `test_event_service.py` (8 tests) | str_simulation | Pre-existing on main branch |
| `test_phase3_market_enhancements.py` (10 tests) | str_simulation | Pre-existing on main branch |
| `test_mcp_client.py::test_get_str_estimate` (2 tests) | investFlorida.ai | Pre-existing `bypass_cache` param mismatch on main |
| `test_str_activity_service.py::test_detect_activity_bypass_cache` | investFlorida.ai | Pre-existing on stash baseline |

---

## Log Cleanliness Gate

**Commit tested**: `e98bd0b` (investFlorida.ai) + stash changes
**Run**: Model Impact snapshot `after-sprint-2-final` (2026-03-19 ~03:10 - 05:53)
**Properties tested**: 6 (deerfield, biscayne, natiivo, orlando, brickell, edgewater)

### ERROR/WARNING Analysis

| Log Message | Count | Classification | Verdict |
|---|---|---|---|
| `ERROR: MCP tool scrape_str_compliance failed — No STR compliance data found` | 1 | Expected (graceful fallback; city compliance unavailable) | PASS |
| `WARNING: STR compliance fetch failed` | 1 | Expected (handled by pipeline) | PASS |
| `ERROR: address_parser failed to parse '#-formatted' addresses` | 4 | Pre-existing (unit-style addresses not parsed) | Minor |
| `ERROR: MCP tool get_property_sale_history failed — RentCast 404` | 2 | Expected (property not in RentCast) | PASS |
| `WARNING: Market inventory search failed: 'str' object has no attribute 'get'` | 2 | Pre-existing bug in market inventory path | Minor |
| `ERROR: MCP tool analyze_market_trends failed — RentCast DNS error` | 1 | External service unavailable | PASS |
| `ERROR: MCP tool search_active_listings transport error (9,402,842ms)` | 1 | **CONCERN**: ~2.6hr timeout on one property's active listings | Major |

**No unexpected tax fallback messages** (no `default_fallback` source in tax logs).
**No Python tracebacks** beyond the handled MCP tool error tracebacks.
**No CRITICAL level messages.**

### Tax Provider Log Check (AC-14)
```
INFO [src.services.financial_calculations] Using API STR tax rates: state=6.0%, tourist=6.0%, local=0.0%
INFO [src.pipeline.property_analyzer] ✅ Tax rates reused from FinancialCalculationAgent: STR_tax=12.00%
```
The tax rate source log confirms: **12% is being applied for Miami**, not 14%. City resort 2% missing.

---

## Model Impact Diff Summary

**Snapshots**: `before-sprint-2_2026-03-18` vs `after-sprint-2-final_2026-03-19`
**Diff file**: `validation/diffs/before-sprint-2_vs_after-sprint-2-final.json`

| Stat | Value |
|---|---|
| Properties | 6 (4 new + 2 with before data) |
| Total Metrics | 228 |
| FLIPs | 6 (4 new properties + 2 verdict changes) |
| Threshold Crossings | 3 |
| Regressions | 23 |

### Verdict Changes on Pre-Existing Properties

| Property | Before | After | Driver |
|---|---|---|---|
| Deerfield Beach | PROCEED | NO-GO | Higher STR tax (7%→12%), variable costs 27%→30%, mgmt fee 20%→18%; major revenue drop (API data change) |
| Natiivo (min-stay) | PROCEED | CAUTION | STR tax 7%→12%, variable costs 27%→30%, mgmt fee 20%→18%; financial metrics improved |

**Note**: The dramatic revenue change for Deerfield Beach (~52% drop, $89K→$42K) likely reflects different STR API data on the run date rather than purely code changes. PROCEED→NO-GO verdicts triggered by the new stricter financial scoring.

### Sprint Impact Confirmed
- Management fee: 20% → 18% for all properties ✅
- STR tax: 7% → 12% for FL properties (FloridaDOR minimum) ✅
- Variable costs: 27% → 30% ✅
- Deal breakers populated for all NO-GO properties ✅

---

## Production Readiness Checklist

- [x] Management fee 18% default documented in config with code comment
- [x] FloridaDORProvider wired into `/financials/str/tax` endpoint
- [x] Min-stay penalty logic tested with 50 unit tests
- [x] Risk factor flow-through from str_simulation to investFlorida.ai committed
- [x] DSCR lending context (3F-H) committed
- [ ] **Phase 3C/3D/3E changes NOT committed** — missing from cap branch
- [ ] **AC-14 (Miami 14% tax)**: `scrape_tax_rates` path returns 12%, not 14%
- [ ] `search_active_listings` transport timeout (~2.6hr) needs investigation

---

## Regression Check

| Area | Test | Result |
|---|---|---|
| Financial calculations (investFlorida.ai) | `test_financial_calculations.py` 30 tests | PASS |
| Revenue modeling | `test_revenue_modeling.py` 32 tests | PASS |
| STR tax calculation | `test_str_tax_calculation.py` 41 tests | PASS |
| Compliance scoring (with stash) | `test_e2e_compliance_scoring.py` 34 tests | PASS |
| Viability risk flow-through | `test_viability_risk_flowthrough.py` 16 tests | PASS |
| STR simulation core | `tests/core/`, `tests/unit/`, `tests/services/` | 1964/1984 PASS (20 pre-existing failures) |
| Pre-existing failures | N/A | Confirmed pre-existing on main branch (no new regressions) |

---

## Follow-up Issues

| Issue | Repo | Severity | Description |
|---|---|---|---|
| TBD-1 | investFlorida.ai | Critical | Commit Phase 3C/3D/3E stash changes (compliance_scoring.py, property_analyzer.py, _tab_confidence.html) to cap branch |
| TBD-2 | investFlorida.ai | Major | `_fetch_api_tax_rates()` must use `calculate_str_tax` path (FloridaDORProvider) not `scrape_tax_rates` (web search) to achieve AC-14 ≥13% Miami tax |
| TBD-3 | investFlorida.ai | Minor | `search_active_listings` transport error — investigate why one property's MCP call hung for 2.6 hours |
| TBD-4 | investFlorida.ai | Minor | `compliance.compliance_score` metric in model_impact extracts from `str_viability.legal_compliance.score` which is always 0 — field not populated by pipeline |
| TBD-5 | str_simulation | Minor | 2 pre-existing collection errors: `test_phase1_events.py` (missing `get_event_booster`) and duplicate `test_str_signals.py` basename |

---

## Architect Sign-off
- **Status**: Pending
- **Date**: —
- **Notes**: Two blockers must be resolved before this can be approved. See Critical Finding above and Follow-up TBD-1 and TBD-2.
