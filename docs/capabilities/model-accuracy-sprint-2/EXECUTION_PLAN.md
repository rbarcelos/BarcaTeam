# Execution Plan: Model Accuracy Sprint 2

**Capability**: `model-accuracy-sprint-2`
**Date**: 2026-03-19
**Status**: READY FOR APPROVAL
**Estimated Duration**: 2-3 weeks (3 phases)

---

## Summary

12 model accuracy issues remain from persona reviews. Cumulative error: **-$12K to -$22K/year overstated cash flow** — enough to flip marginal deals from positive to negative. This sprint fixes them across 3 phases in dependency order.

**Inputs**: PM Brief, STR Revenue Model Assessment, Architecture doc (all in this directory)

---

## Phase 0: Build Model Impact Tool — Day 1-2

Before any code changes, build a **permanent, reusable tool** that captures model output and diffs it against any previous snapshot. This becomes standard infrastructure for understanding the impact of ANY change to either repo — not just this sprint.

### 0A. Build the Model Impact Tool
**Location**: `investFlorida.ai/src/tools/model_impact.py` (permanent, versioned, importable)
**MCP Tool**: Also exposed as an MCP tool `run_model_impact` in str_simulation so agents can invoke it
**CLI**: `python -m src.tools.model_impact snapshot|diff|report`

**Design principles:**
- **Generic** — captures ALL key metrics from the full pipeline, not sprint-specific ones
- **Deterministic** — same property set, same order, reproducible results
- **Extensible** — adding new metrics is a one-line addition to the metric registry
- **Fast** — runs the pipeline on N properties, extracts metrics, done in < 5 minutes
- **Diffable** — any two snapshots can be compared regardless of when they were taken

**Three modes:**

**1. `snapshot`** — Capture current model state
```bash
python -m src.tools.model_impact snapshot --name "before-sprint-2"
# → saves to validation/snapshots/before-sprint-2_2026-03-19.json
```

**2. `diff`** — Compare any two snapshots
```bash
python -m src.tools.model_impact diff --before before-sprint-2 --after after-phase-1
# → prints diff table to stdout + saves to validation/diffs/
```

**3. `report`** — Generate a full markdown impact report
```bash
python -m src.tools.model_impact report --before before-sprint-2 --after after-phase-1
# → saves to validation/reports/impact_2026-03-19.md
```

**Metrics registry (all captured per property):**

| Category | Metrics |
|----------|---------|
| Revenue | Annual revenue (base/conservative/optimistic), monthly ADR, occupancy rate, RevPAR |
| Expenses | Total OpEx, fixed costs, variable costs (per scenario), management fee, STR tax, insurance |
| Returns | NOI, DSCR, CoC return, cap rate, monthly cash flow, annual cash flow |
| Tax | Effective STR tax rate, state/county/city breakdown, tax source |
| Scoring | Overall score, verdict, prerequisite pass count, confidence score |
| Risk | Deal-breaker count + descriptions, major risk count, manageable risk count |
| Compliance | Regulatory gate score, compliance score, min-stay detected, min-stay penalty applied |
| Scenarios | Revenue spread (optimistic - conservative), expense spread, DSCR spread |

**Diff output format:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ MODEL IMPACT DIFF: before-sprint-2 → after-phase-1                        │
│ Date: 2026-03-20  Properties: 6  Metrics: 42                              │
├──────────────────┬────────────┬──────────┬──────────┬─────────┬───────────┤
│ Property         │ Metric     │ Before   │ After    │ Delta   │ Flag      │
├──────────────────┼────────────┼──────────┼──────────┼─────────┼───────────┤
│ Natiivo 1BD      │ Revenue    │ $113,296 │ $101,966 │ -10.0%  │           │
│ Natiivo 1BD      │ DSCR       │ 1.10     │ 0.85     │ -0.25   │ ⚠ CROSS  │
│ Natiivo 1BD      │ Verdict    │ PROCEED  │ NO-GO    │ CHANGED │ ⚠ FLIP   │
│ Natiivo 1BD      │ Tax Rate   │ 12.0%    │ 14.0%    │ +2.0pp  │           │
│ 3900 Biscayne    │ Risk Count │ 0        │ 3        │ +3      │           │
│ Strong Property  │ Verdict    │ PROCEED  │ PROCEED  │ —       │ ✓ STABLE │
└──────────────────┴────────────┴──────────┴──────────┴─────────┴───────────┘

SUMMARY: 6 properties, 14 metrics changed, 1 verdict flip, 0 unexpected regressions
```

**Automatic flags in diff:**
- `⚠ FLIP` — verdict changed (PROCEED → NO-GO or vice versa)
- `⚠ CROSS` — metric crossed a critical threshold (DSCR below 1.0, CoC below 0%)
- `⚠ REGRESS` — metric moved in unexpected direction for a property that should be unaffected
- `✓ STABLE` — no changes on a property expected to be unaffected

**Test property set (configurable, stored in `validation/properties.json`):**
- Default set: 6-10 diverse properties covering different cities, min-stay rules, DSCR ranges, property types
- Users can add/remove properties from the set
- Each property defined by its input params (address/URL, bedrooms, price, etc.)

### 0B. Standard Workflow Integration
This tool becomes part of the development workflow for BOTH repos:

1. **Before any model change**: `model_impact snapshot --name "before-{change-name}"`
2. **After the change**: `model_impact diff --before before-{change-name} --after current`
3. **PR review**: Impact diff attached to every PR that touches calculation logic
4. **QA gate**: No merge without impact diff reviewed

Document this workflow in both repos' CLAUDE.md files.

### 0C. Capture Sprint 2 Baseline
Run the first snapshot against the current (unfixed) codebase:
```bash
python -m src.tools.model_impact snapshot --name "pre-sprint-2"
```
This becomes the "before" for all Phase 1/2/3 diffs.

**Duration**: 1-2 days (this is permanent infrastructure, worth the investment)

---

## Phase 1: Revenue Foundation (str_simulation) — Week 1

Fix the base revenue calculation. Everything downstream depends on this.

### 1A. Min-Stay Penalty on Revenue
**Files**: `src/core/simulation.py:140-145`, `src/core/models.py`
**Issue**: 3-night HOA minimum kills weekend 2-nighters but model doesn't reduce OCC or ADR
**Fix**: Apply pre-simulation penalty:
- 1-night: 0% (baseline)
- 2-night: -2% OCC, -2% ADR
- 3-night: -5% OCC, -5% ADR
- 7-night: -12% OCC, -10% ADR
- 30-night: -25% OCC, -20% ADR
**AC**: Properties with min-stay > 1 show measurably lower occupancy and ADR
**Tests**: New `tests/core/test_minstay_penalty.py`

### 1B. STR Tax Rate Resolution via External API (parallel with 1A)
**Files**: `src/apps/financials/service.py:61-63,176-197`, `src/apps/financials/models.py:61-75`, new `src/providers/tax_rate_provider.py`
**Issue**: City tax defaults to 0%. Miami charges 2% resort tax → reports show 12% not ~14%. Hardcoding rates won't scale to other regions.
**Fix**: Build a tax rate provider that resolves STR/lodging tax rates via external API:
1. Create `TaxRateProvider` using the existing provider pattern in str_simulation
2. The provider accepts address, city, county, or ZIP and returns state + county + city tax rates
3. `calculate_str_tax()` calls the provider using the `city`/`county`/`zip_code` already on `STRTaxRequest` (currently ignored)
4. Cache results aggressively (tax rates change ~annually) — 30-day TTL minimum
5. Fallback: if API is unavailable, use current defaults (6%/6%/0%) with a logged warning and `tax_source: "default"` in response
6. Candidate APIs: Avalara MyLodgeTax (lodging-specific), Zip-Tax (sales tax by ZIP), or state DOR published rate databases
**AC**: Miami properties show >= 13% combined STR tax rate. Tax rates resolved dynamically — no hardcoded city rates. Works for any US jurisdiction, not just Florida.
**Tests**: Modified `tests/unit/test_financials.py:TestSTRTax` + new provider tests with mocked API responses
**Note**: API selection is an open decision — needs research on cost, coverage, and accuracy for STR/lodging-specific rates vs general sales tax

### 1C. Management Fee Default
**Files**: `investFlorida.ai/src/pipeline/config.py:71`
**Issue**: Default 20%, market is 15-18% for purpose-built STR
**Fix**: Change `default_management_fee_pct` from `0.20` to `0.18`
**AC**: Reports use 18% management fee
**Tests**: Existing tests pass with updated assertion

---

## Phase 2: Scenario Fidelity (str_simulation + investFlorida.ai) — Week 1-2

Fix how scenarios are computed and displayed. Can parallelize 2A and 2B.

### 2A. Variable Cost Scaling Across Scenarios
**Files**: `str_simulation/src/apps/financials/service.py:267-308` (calc), `investFlorida.ai/_tab_revenue.html:359-361` (template)
**Issue**: Same expenses ($63,348) across all scenarios. Management fee (% of revenue) and STR tax should scale.
**Fix**:
- Split `_calculate_single_scenario()` to accept fixed + variable expenses separately
- Recompute: `scenario_variable = base_variable * (scenario_revenue / base_revenue)`
- Template: replace `scenarios.base.annual_operating_expenses` with per-scenario values
**AC**: Conservative shows lower variable costs; optimistic shows higher. Difference proportional to revenue.
**Tests**: Modified `tests/unit/test_financials.py:TestScenarios` — assert expenses differ

### 2B. ADR-OCC Inverse Coupling (parallel with 2A)
**Files**: `str_simulation/src/apps/financials/service.py:86-91` (SCENARIO_FACTORS)
**Issue**: Optimistic boosts BOTH ADR (+10%) and OCC (+5%). Real markets: higher ADR → lower OCC.
**Fix**: Apply elasticity coefficient (-0.3 default):
```
optimistic:    ADR × 1.10, OCC × 0.97  (+10% ADR, -3% OCC)
base:          ADR × 1.00, OCC × 1.00
conservative:  ADR × 0.90, OCC × 1.03  (-10% ADR, +3% OCC)
worst_case:    ADR × 0.80, OCC × 0.95  (market downturn — both down)
```
**AC**: Optimistic cannot have both ADR and OCC above base simultaneously (except worst_case)
**Tests**: New test class in `test_financials.py`

### 2C. Interest Rate / Loan Term Display
**Files**: `investFlorida.ai` template `_tab_pricing.html`
**Issue**: Financing assumptions exist in context but never rendered
**Fix**: Add row showing "Interest Rate: 7.0% | Term: 30-year fixed"
**AC**: Deal Structure section displays assumed rate and term
**Tests**: Template rendering test

### 2D. Regulatory Narrative Contradiction
**Files**: `investFlorida.ai` compliance narrative generation
**Issue**: Amber badge but text says "No minimum stay requirement documented"
**Fix**: When min-stay restriction detected, narrative must acknowledge it
**AC**: Narrative matches badge signal
**Tests**: E2E compliance scoring test

---

## Phase 3: Risk Assessment & Consistency (both repos) — Week 2-3

Depends on Phases 1-2 producing correct scenarios.

### 3A. Viability → Risk Factor Bridge (str_simulation)
**Files**: `src/services/viability_service.py:173-261`, `src/core/models/viability.py`
**Issue**: Gate WARN/BLOCK results don't generate risk factors
**Fix**: Add `risk_factors: List[RiskFactor]` to `ViabilityResult`. Every WARN/BLOCK gate emits a risk factor:
- DSCR 0.81x → HIGH severity, "Below 1.25x lending minimum"
- Confidence 0/100 → MAJOR severity, "Insufficient market data"
- 8/12 months negative cash flow → HIGH severity
**AC**: Viability response includes risk_factors for all WARN/BLOCK gates
**Tests**: Modified `test_str_viability.py`

### 3B. Risk Factor Flow-Through (investFlorida.ai)
**Files**: `src/pipeline/property_analyzer.py:~5835`, `src/models/investment_context.py:2182-2210`
**Issue**: `RiskAssessment.major_risks` and `deal_breakers` lists empty despite bad viability
**Fix**: Merge viability risk_factors into RiskAssessment:
- BLOCK gates → `deal_breakers`
- WARN gates → `major_risks`
- Pattern issues (>6 months negative cash flow) → `manageable_risks`
**AC**: NO-GO verdict always has at least one deal-breaker entry
**Tests**: Integration test for risk factor propagation

### 3C. "No Significant Risks" Badge Guard
**Files**: `investFlorida.ai/_tab_confidence.html:144-154`
**Issue**: Badge shows when risk lists are empty, regardless of viability score
**Fix**: Only render "No Risks" when ALL gates PASS AND risk_factors empty AND confidence > 50. Otherwise render "Risk Assessment Incomplete"
**AC**: Zero instances of "No Significant Risks" on NO-GO properties
**Tests**: Template rendering with various risk states

### 3D. Regulatory Gate Consistency
**Files**: `investFlorida.ai/src/pipeline/compliance_scoring.py:62-72`
**Issue**: Compliance gate shows 74/100 PASS while overall verdict is NO-GO
**Fix**: If ANY gate is BLOCK → compliance score caps at 30. If ANY gate is WARN → caps at 60. Remove PROCEED override.
**AC**: No green PASS gates on NO-GO properties
**Tests**: Modified `test_e2e_compliance_scoring.py`

### 3E. Deal-Breaker Banner Population
**Files**: `src/pipeline/property_analyzer.py:~5835`, `sections/executive_summary.html:379-399`
**Issue**: Banner empty despite NO-GO and 0/3 prerequisites
**Fix**: Auto-generate deal_breaker entries from viability BLOCK gates + profitability failures (DSCR < 1.0, CoC < 0%, S_overall < 50)
**AC**: NO-GO properties render deal-breaker banner with blocking reasons
**Tests**: E2E test with weak property profile

### 3F. DSCR Lending Threshold Context (Should-have, CEO cherry-pick)
**Files**: Report template DSCR section
**Fix**: Add qualification buckets: 1.0x (breakeven), 1.20x (standard minimum), 1.25x (preferred). Show which bucket the property falls into.
**AC**: DSCR section shows lending threshold context
**Tests**: Template test

### 3G. DSCR Label Fix (Should-have)
**Fix**: Relabel 1.0-1.25x range from "Thin" to "Below Lender Minimum"

### 3H. Evidence Confidence Placeholders (Should-have)
**Fix**: Replace static 30% values with actual LLM confidence or display "Unscored"

---

## Execution Summary

| Phase | Issues | Repo | Duration | Parallelizable |
|-------|--------|------|----------|----------------|
| **0** | Model Impact Tool (permanent infra) + baseline capture | Both repos | 1-2 days | — |
| **1** | 1A (min-stay) + 1B (tax API) + 1C (mgmt fee) | str_simulation + config | 3-4 days | 1A ∥ 1B ∥ 1C |
| **1✓** | Re-run snapshot, review Phase 1 diff + **log cleanliness gate** (run reports, verify zero unexpected logs) | Both repos | 0.5 day | — |
| **2** | 2A (variable costs) + 2B (ADR-OCC) + 2C (display) + 2D (narrative) | Both repos | 3-4 days | 2A ∥ 2B, 2C ∥ 2D |
| **2✓** | Re-run snapshot, review Phase 2 diff + **log cleanliness gate** | Both repos | 0.5 day | — |
| **3** | 3A-3H (risk overhaul + regulatory + cherry-picks) | Both repos | 4-5 days | 3A → 3B → 3C/3D/3E (sequential), 3F ∥ 3G ∥ 3H |
| **3✓** | Final snapshot, full diff review + **full log cleanliness gate** (all test properties) | Both repos | 0.5 day | — |
| **4** | Stakeholder Review Panel — CEO, Investor, 3 personas evaluate post-fix reports | barcaTeam | 1 day | — |

**Total**: ~14-17 working days (~3 weeks, including tool build + validation + stakeholder review)

---

## Acceptance Criteria Summary

| ID | Criterion | Priority | Phase |
|----|-----------|----------|-------|
| AC-1 | Min-stay > 1 reduces projected occupancy by penalty table | Must-have | 1 |
| AC-2 | Min-stay > 1 reduces projected ADR by penalty table | Must-have | 1 |
| AC-3 | Miami properties show >= 13% combined STR tax | Must-have | 1 |
| AC-4 | Default management fee is 18% | Must-have | 1 |
| AC-5 | Variable costs differ across scenario columns proportional to revenue | Must-have | 2 |
| AC-6 | Optimistic scenario: higher ADR with dampened OCC (not both up) | Must-have | 2 |
| AC-7 | Interest rate and loan term displayed in Deal Structure | Must-have | 2 |
| AC-8 | Regulatory narrative matches badge signal on min-stay | Must-have | 2 |
| AC-9 | NO-GO verdict → deal-breaker banner renders with blocking reasons | Must-have | 3 |
| AC-10 | No green PASS gates on NO-GO properties | Must-have | 3 |
| AC-11 | Viability WARN/BLOCK gates generate risk factors | Must-have | 3 |
| AC-12 | "No Significant Risks" only when all gates PASS + confidence > 50 | Must-have | 3 |
| AC-13 | DSCR lending threshold context displayed | Should-have | 3 |
| AC-14 | DSCR 1.0-1.25x labeled "Below Lender Minimum" | Should-have | 3 |
| AC-15 | Evidence confidence not static 30% placeholder | Should-have | 3 |

**11 Must-have, 3 Should-have**

---

## Validation Gate

### Per-Phase Review (after each phase)
1. Run `python scripts/validation_snapshot.py --diff validation/baseline_*.json`
2. Review the before/after diff table — verify changes match expected direction and magnitude
3. Flag any unexpected regressions (e.g., strong property verdict changed, metrics moved wrong direction)
4. User approves phase diff before proceeding to next phase

### Log Cleanliness Gate (after each phase)
The str_simulation server runs on localhost and auto-restarts on code changes — no need to spin up a new server. After each phase:
1. Trigger a full report generation for at least 2 test properties (one strong, one weak)
2. Capture all server logs during the run
3. Verify **zero unexpected log messages**: no tracebacks, no unhandled exceptions, no new warnings, no deprecation notices
4. Expected log messages (INFO-level request/response, known deprecation warnings) are whitelisted — anything else is a blocker
5. If unexpected logs appear → fix before proceeding to next phase

**What counts as unexpected:**
- Any `ERROR` or `CRITICAL` level log entry
- Any Python traceback / exception
- Any `WARNING` not present in the pre-sprint baseline logs
- Any "fallback" or "default" messages from the tax provider (unless API is intentionally unavailable)
- Any log line referencing missing data, null values, or failed lookups that weren't there before

### Final Technical Validation (after Phase 3, before stakeholder review)
1. Run full before/after diff across all test properties — all phases combined
2. Verify all 11 Must-have AC pass across all property profiles
3. Run full test suites on both repos (1295 + 786 tests)
4. **Run report generation for all test properties, capture full server logs, verify zero unexpected messages** (same criteria as per-phase log gate, but across the full property set)
5. Archive final snapshot as `validation/sprint2_final_YYYY-MM-DD.json`

---

## Phase 4: Stakeholder Review Panel — Go/No-Go for Chat MVP

After all fixes are deployed and technically validated, run a full stakeholder review to assess whether the model is now trustworthy enough to build a user-facing product on top of.

### Setup
1. Generate fresh reports for 3 diverse properties using the fixed model:
   - **Borderline deal** (the Natiivo 1BD or similar — min-stay, marginal DSCR)
   - **Strong deal** (clear positive cash flow, no restrictions)
   - **Weak deal** (NO-GO, poor DSCR, regulatory issues)
2. Attach the Model Impact diff (pre-sprint-2 → post-sprint-2) for context

### Review Panel (team of agents, visible tmux panes)

| Agent | Role in Review | Key Questions They Answer |
|-------|---------------|--------------------------|
| **CEO** | Strategic readiness | Are we ready to build the chat MVP on this foundation? Any remaining trust gaps? Does the model's output match the 12-month product vision? |
| **Investor** | Business viability | Would an agent pay for reports at this quality level? Are there credibility issues that would block adoption? Confidence level (1-10) for proceeding to chat MVP? |
| **Buyer Agent** (persona) | Distribution channel test | "Can I email this to a client without getting a callback?" Review all 3 reports for client-readiness. Flag anything that would embarrass them. |
| **Mortgage Manager** (persona) | Underwriting credibility | Are the financial metrics (DSCR, NOI, cap rate, debt service) now accurate enough for preliminary screening? Do scenarios make sense? |
| **STR Operator** (persona) | Operational realism | Do revenue projections reflect real market conditions? Are min-stay penalties, ADR-OCC coupling, and cost scaling believable? |

### Deliverables
Each reviewer produces:
1. **Confidence score (1-10)**: How confident are you that this model is ready for real users?
2. **Remaining issues**: Any new issues found (with severity: blocker / important / nice-to-have)
3. **Go/No-Go recommendation**: Should we proceed to Chat MVP, or is another sprint needed?

### Decision Framework

| Outcome | Criteria | Next Step |
|---------|----------|-----------|
| **GO** | Average confidence >= 7/10, zero blockers, CEO + Investor both recommend GO | Proceed to Chat MVP capability |
| **CONDITIONAL GO** | Average confidence 5-7/10, no blockers but important issues remain | Fix important issues (1 week max), then proceed to Chat MVP |
| **NO-GO** | Any reviewer scores < 4/10, OR any blocker found | Sprint 3 scoped from blocker list, re-review after |

### Output
- `reviews/sprint2_stakeholder_review.md` — consolidated review with all scores, issues, and recommendation
- Clear go/no-go decision on Chat MVP
- If GO: the review doc becomes input to the Chat MVP PM Brief

---

## Data Contract Changes (all additive, backward compatible)

| Contract | New Fields | Breaking? |
|----------|-----------|-----------|
| ScenarioResult | `annual_fixed_expenses`, `annual_variable_expenses`, `occupancy_adjustments` | No |
| ViabilityResult | `risk_factors[]` | No |
| STRTaxResponse | `tax_breakdown` | No |

---

## Deploy Order

0. Build snapshot tool + capture baseline → `validation/baseline_*.json` + **capture baseline server logs**
1. str_simulation Phase 1 fixes → deploy → **run snapshot + run reports against localhost, verify zero unexpected logs, review Phase 1 diff with user**
2. str_simulation Phase 2 fixes → deploy
3. investFlorida.ai Phase 2 template fixes → deploy → **run snapshot + log cleanliness gate, review Phase 2 diff with user**
4. str_simulation Phase 3A (viability risk factors) → deploy
5. investFlorida.ai Phase 3B-3H (risk flow-through + regulatory) → deploy → **run final snapshot + full log cleanliness gate (all properties), full diff review with user**
6. Final validation gate (test suites + full log gate + snapshot archived)
