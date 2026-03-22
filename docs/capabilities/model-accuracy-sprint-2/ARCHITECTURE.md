# Architecture: Model Accuracy Sprint 2
**Slug**: `model-accuracy-sprint-2`
**Date**: 2026-03-19
**Author**: Architect Agent

## Overview

Sprint 2 addresses five categories of model accuracy issues that 5/6 persona reviewers flagged as credibility-destroying. All fixes target the calculation pipeline (`str_simulation`) and the report display layer (`investFlorida.ai`). No new infrastructure is required — this is surgical correction of existing logic.

The fixes span two repos, three architectural layers (simulation core, financial service, report template), and have a strict dependency order due to cascading data contracts.

---

## Issue Inventory & File Map

### ISSUE 1: Min-Stay Penalty on Revenue

**Problem**: When HOA enforces a 3-night minimum, the revenue model only reduces turnover count (cleaning cycles). It does NOT reduce occupancy or ADR, despite the fact that min-stay requirements:
- Kill weekend 2-nighters (highest RevPAR segment — ~35% of bookings in urban markets)
- Reduce bookable demand pool → lower effective occupancy
- Longer stays command lower nightly ADR (typically -5% to -15% vs 1-night pricing)

**Current code path**:
```
str_simulation/src/core/simulation.py:140-145
    effective_stay_length = max(params.minimum_length_of_stay, 3) if params.minimum_length_of_stay else 3
    num_turns = occupied_nights // effective_stay_length  # ← Only turnover affected
    room_revenue = occupied_nights * effective_adr         # ← Revenue unchanged
```

| Repo | Layer | File | Function/Line | Change Type |
|------|-------|------|---------------|-------------|
| str_simulation | Core | `src/core/simulation.py` | `simulate()` L140-145 | Modified |
| str_simulation | Core | `src/core/models.py` | `SimulationParameters` | Modified (add penalty config) |
| str_simulation | Service | `src/apps/financials/service.py` | `_calculate_single_scenario()` | Modified (pass penalty) |
| str_simulation | Tests | `tests/unit/test_financials.py` | New test cases | New |
| str_simulation | Tests | `tests/core/` | New `test_minstay_penalty.py` | New |

**Design prescription**:
1. Add `min_stay_occupancy_penalty` and `min_stay_adr_discount` fields to `SimulationParameters`
2. Default penalty table (configurable, overridable):
   - 1-night min: 0% OCC penalty, 0% ADR discount (baseline)
   - 2-night min: -2% OCC, -2% ADR
   - 3-night min: -5% OCC, -5% ADR (kills weekend 2-nighters)
   - 7-night min: -12% OCC, -10% ADR (kills short getaways)
   - 30-night min: -25% OCC, -20% ADR (monthly rental territory)
3. Apply BEFORE seasonality multipliers in `simulate()`:
   ```python
   adjusted_occ = params.occupancy_rate * (1 - occ_penalty)
   adjusted_adr = params.average_daily_rate * (1 - adr_discount)
   ```
4. Surface the penalty in the scenario response so the report can display it

**Regression risk**: MEDIUM. Changes base revenue calculation. Every test using `simulate()` or `calculate_scenarios()` will see different values. Run full test suite. Existing tests in `test_financials.py` (534 lines) cover scenarios but not min-stay impact.

---

### ISSUE 2: Variable Cost Scaling Across Scenarios

**Problem**: Two bugs — one in calculation, one in display.

**Bug A — Calculation (str_simulation)**: `_calculate_single_scenario()` receives `annual_operating_expenses` as a static parameter. The same dollar amount is used for conservative, base, and optimistic scenarios. Variable costs (management fees = % of revenue, OTA commission = % of revenue, cleaning = f(turnovers), STR taxes = % of revenue) should scale with each scenario's revenue/occupancy.

**Current code path**:
```
str_simulation/src/apps/financials/service.py:267-308
    def _calculate_single_scenario(
        name: str,
        base_adr: float,
        base_occupancy: float,
        annual_operating_expenses: float,  # ← STATIC across all scenarios
        annual_debt_service: float,
        ...
    ):
        total_expenses = annual_operating_expenses + annual_debt_service  # ← Same for all
```

**Bug B — Template (investFlorida.ai)**: All three scenario columns render `scenarios.base.annual_operating_expenses`.

**Current code path**:
```
investFlorida.ai/src/reports/templates/v1_report/sections/investment_analysis/_tab_revenue.html:359-361
    Line 359: scenarios.base.annual_operating_expenses  ← WRONG (should be conservative)
    Line 360: scenarios.base.annual_operating_expenses  ← Correct
    Line 361: scenarios.base.annual_operating_expenses  ← WRONG (should be optimistic)
```

| Repo | Layer | File | Function/Line | Change Type |
|------|-------|------|---------------|-------------|
| str_simulation | Service | `src/apps/financials/service.py` | `_calculate_single_scenario()` L267-308 | Modified |
| str_simulation | Service | `src/apps/financials/service.py` | `calculate_scenarios()` (caller) | Modified |
| str_simulation | Core | `src/core/simulation.py` | `simulate()` expense lines L148-247 | Reference (expense classification exists here) |
| str_simulation | Core | `src/core/models/expense.py` | `ExpenseType`, `ScalingModel` enums | Reference (classification already modeled) |
| str_simulation | Tests | `tests/unit/test_financials.py` | `TestScenarios` class | Modified (assert cost variation) |
| investFlorida.ai | Template | `_tab_revenue.html` | Lines 359-361 | Modified |

**Design prescription**:
1. `_calculate_single_scenario()` must accept expense breakdown (fixed + variable separately), not a single total
2. Recompute variable expenses based on scenario revenue:
   ```python
   scenario_variable = base_variable * (scenario_revenue / base_revenue)
   scenario_total_opex = fixed_expenses + scenario_variable
   ```
3. The expense classification already exists in `src/core/models/expense.py` (`ExpenseType.FIXED`, `VARIABLE`, `VOLATILE`) and `simulation.py` (lines 148-247). Use it.
4. Template fix is trivial: replace `scenarios.base` with `scenarios.conservative` / `scenarios.optimistic` per column

**Regression risk**: MEDIUM-HIGH for calculation change (affects NOI, DSCR, cash flow, cap rate for all non-base scenarios). LOW for template fix. The `TestScenarios` class in `test_financials.py` will need updating to expect different expenses per scenario.

---

### ISSUE 3: ADR-OCC Inverse Coupling

**Problem**: `SCENARIO_FACTORS` treats ADR and occupancy as independent multipliers. The optimistic scenario boosts BOTH ADR (+10%) AND occupancy (+5%). In real markets, higher ADR suppresses occupancy (price elasticity). Modeling top-quartile ADR AND top-quartile occupancy simultaneously is what the STR Operator persona called an "operator trap."

**Current code path**:
```
str_simulation/src/apps/financials/service.py:86-91
    SCENARIO_FACTORS = {
        "optimistic": (1.10, 1.05),      # Both UP — unrealistic
        "base": (1.00, 1.00),
        "conservative": (0.90, 0.90),     # Both DOWN — also unrealistic
        "worst_case": (0.80, 0.80),
    }
```

| Repo | Layer | File | Function/Line | Change Type |
|------|-------|------|---------------|-------------|
| str_simulation | Service | `src/apps/financials/service.py` | `SCENARIO_FACTORS` L86-91 | Modified |
| str_simulation | Service | `src/apps/financials/service.py` | `_calculate_single_scenario()` | Modified (coupling logic) |
| str_simulation | Config | `src/config/` | New `elasticity_config.py` | New |
| str_simulation | Tests | `tests/unit/test_financials.py` | `TestScenarios` | Modified |

**Design prescription**:
1. Replace static SCENARIO_FACTORS with an elasticity-aware model:
   ```python
   # Optimistic: Higher ADR, lower OCC (price-up strategy)
   # Conservative: Lower ADR, slightly higher OCC (discount strategy)
   SCENARIO_FACTORS = {
       "optimistic":    (1.10, 0.97),   # +10% ADR, -3% OCC (net revenue up)
       "base":          (1.00, 1.00),
       "conservative":  (0.90, 1.03),   # -10% ADR, +3% OCC (net revenue down)
       "worst_case":    (0.80, 0.95),   # -20% ADR, -5% OCC (market downturn)
   }
   ```
2. The elasticity coefficient (-0.3 default: 10% ADR increase → 3% OCC decrease) should be configurable via `elasticity_config.py`
3. Document the trade-off in the scenario response metadata so the report can explain it to users

**Regression risk**: MEDIUM. Changes optimistic and conservative scenario outputs. The `worst_case` scenario should remain both-down (market downturn = both drop). Existing scenario tests will need updating.

**ADR-1: ADR-OCC Elasticity Approach**
- **Status**: Proposed
- **Context**: Real STR markets show price elasticity — raising ADR reduces bookings. Current model ignores this, producing unrealistically optimistic projections.
- **Decision**: Apply a configurable elasticity coefficient (default -0.3) where `occ_adjustment = 1 + (elasticity * (adr_factor - 1))`. Keep worst_case as both-down (systemic market downturn).
- **Consequences**: Optimistic scenario revenue decreases modestly (~5-7% vs current). Conservative scenario revenue increases slightly (discount strategy captures more bookings). More realistic projections that STR operators and mortgage managers will trust.

---

### ISSUE 4: Risk Assessment Overhaul (DB-2)

**Problem**: Multi-layered failure in risk communication:
1. "No Significant Risks" badge renders when `major_risks` AND `manageable_risks` are empty — but these lists aren't populated from viability gate results
2. DSCR 0.81x triggers WARN (not BLOCK) because threshold is < 0.8 for BLOCK
3. Confidence 0/100 doesn't generate risk factors
4. 8/12 months negative cash flow not surfaced as a risk
5. Regulatory gate can show PASS (74/100) while overall verdict is NO-GO

**Current code paths**:

Risk badge display:
```
investFlorida.ai/src/reports/templates/v1_report/sections/investment_analysis/_tab_confidence.html:144-154
    {% if not context.data.risk.major_risks and not context.data.risk.manageable_risks %}
        "No Significant Investment Risks Detected"  # ← Shows when lists empty
```

Viability gates:
```
str_simulation/src/services/viability_service.py:173-214
    DSCR < 0.8 → BLOCK
    DSCR 0.8-1.0 → WARN
    DSCR 1.0-1.25 → WARN (advisory)
    DSCR >= 1.25 → PASS
```

Risk population:
```
investFlorida.ai/src/pipeline/property_analyzer.py:5835-5840
    # Only CRITICAL/HIGH severity risk factors become deal_breakers
    if severity in ["CRITICAL", "HIGH"]:
        deal_breakers_list.append(rf.description)
```

Regulatory gate contradiction:
```
investFlorida.ai/src/pipeline/compliance_scoring.py:62-72
    if recommendation == Recommendation.PROCEED:
        # PROCEED overrides gate warnings → high score possible with NO-GO verdict
```

| Repo | Layer | File | Function/Line | Change Type |
|------|-------|------|---------------|-------------|
| str_simulation | Service | `src/services/viability_service.py` | Gate evaluators L173-261 | Modified |
| str_simulation | Models | `src/core/models/viability.py` | `GateResult`, `EconomicResilience` | Modified |
| investFlorida.ai | Pipeline | `src/pipeline/property_analyzer.py` | Risk factor population ~L5835 | Modified |
| investFlorida.ai | Pipeline | `src/pipeline/compliance_scoring.py` | `compute_regulatory_score()` L17-74 | Modified |
| investFlorida.ai | Template | `_tab_confidence.html` | Lines 144-154 | Modified |
| investFlorida.ai | Models | `src/models/investment_context.py` | `RiskAssessment` L2182-2210 | Modified |
| investFlorida.ai | Tests | `tests/test_e2e_compliance_scoring.py` | Existing tests | Modified |
| str_simulation | Tests | `tests/` | `test_str_viability.py` | Modified |

**Design prescription**:

**4a. Viability gate → risk factor bridge** (str_simulation):
- Every gate that returns WARN or BLOCK must generate a corresponding `RiskFactor` in the viability response
- Add `risk_factors: List[RiskFactor]` to `ViabilityResult`
- DSCR WARN at 0.81x → RiskFactor(severity=HIGH, category="financing", description="DSCR 0.81x below 1.25x lending minimum")
- Low confidence → RiskFactor(severity=MAJOR, category="data_quality", description="Market data confidence 0/100")

**4b. Risk factor flow-through** (investFlorida.ai):
- `property_analyzer.py` must propagate viability risk_factors into `RiskAssessment.major_risks` and `manageable_risks`
- Don't rely solely on `/building/assess` CRITICAL/HIGH for deal_breakers
- Viability BLOCK gates → deal_breakers
- Viability WARN gates → major_risks
- Negative monthly cash flow pattern (>6 months) → manageable_risks

**4c. Template guard fix** (investFlorida.ai):
- The "No Significant Risks" badge should ONLY render when viability gates ALL pass AND risk_factors is empty AND confidence > 50
- When risk lists are empty but viability data suggests problems, render "Risk Assessment Incomplete" instead

**4d. Regulatory gate consistency** (investFlorida.ai):
- `compute_regulatory_score()` must not produce a PASS score when the overall verdict is NO-GO
- If ANY structural gate is BLOCK, compliance score should cap at 30 (matching viability score cap)
- Remove the PROCEED override that allows high compliance scores to coexist with gate warnings

**4e. DSCR lending threshold table** (cherry-pick from CEO review):
- Add DSCR qualification buckets to the report: 1.0x (minimum viable), 1.20x (standard DSCR loan), 1.25x (preferred)
- Display which bucket the property falls into and what it means for financing

**Regression risk**: HIGH. This touches the risk pipeline end-to-end. Both repos affected. Must be tested with multiple property profiles (strong, borderline, weak). Existing compliance scoring tests (`test_e2e_compliance_scoring.py`) and viability tests (`test_str_viability.py`) provide partial coverage but will need expansion.

---

### ISSUE 5: Unresolved Regulatory Items (3)

#### 5a. Deal-Breaker Banner Empty Despite NO-GO Verdict

**Problem**: The executive summary deal-breaker banner only fires when `compliance.deal_breakers` is populated. That list is only populated from `/building/assess` risk_factors with CRITICAL/HIGH severity. Viability gate BLOCKs don't populate it.

| Repo | Layer | File | Change Type |
|------|-------|------|-------------|
| investFlorida.ai | Pipeline | `src/pipeline/property_analyzer.py` ~L5835 | Modified |
| investFlorida.ai | Template | `sections/executive_summary.html` ~L379-399 | Modified |

**Fix**: When the overall verdict is NO-GO (or viability < 30), auto-generate a deal_breaker entry describing the blocking gate(s). This overlaps with Issue 4b.

#### 5b. STR Tax Rates Resolved via External API (not hardcoded)

**Problem**: `DEFAULT_LOCAL_OPTION_TAX = 0.0` in str_simulation. Miami's 2% city resort tax is never applied. `STRTaxRequest` already has `city`, `county`, `zip_code` fields but `calculate_str_tax()` ignores them. Hardcoding city rates won't scale beyond Florida.

| Repo | Layer | File | Change Type |
|------|-------|------|-------------|
| str_simulation | Provider | `src/providers/tax_rate_provider.py` | New |
| str_simulation | Service | `src/apps/financials/service.py` L61-63, L176-197 | Modified |
| str_simulation | Models | `src/apps/financials/models.py` L61-75 | Modified (add tax_source to response) |
| investFlorida.ai | Pipeline | `src/pipeline/property_analyzer.py` | Modified (pass city/county/zip to MCP tax tool) |

**Design prescription**:
1. Create a `TaxRateProvider` following the existing provider pattern (like RentCast, AIRROI providers)
2. The provider resolves STR/lodging tax rates by address, city, county, or ZIP using an external API
3. Candidate APIs to evaluate: Avalara MyLodgeTax (lodging-specific), Zip-Tax (sales tax by ZIP), state DOR published rate databases
4. `calculate_str_tax()` calls the provider when `city`/`county`/`zip_code` is present on the request
5. Cache aggressively — 30-day TTL minimum (tax rates change ~annually)
6. Fallback: if API unavailable, use current defaults (6%/6%/0%) with `tax_source: "default_fallback"` in response and a logged warning
7. Add `tax_source` and `tax_breakdown` fields to `STRTaxResponse` for transparency
8. investFlorida.ai pipeline passes the property's city/county/zip when calling the MCP `calculate_str_tax` tool
9. **No hardcoded city/county tax rates** — all rates come from the provider

**Open decision**: Which external tax API to use. Needs research spike on:
- Coverage: does it include STR/lodging-specific taxes (TDT, resort tax) or just general sales tax?
- Cost: per-lookup pricing vs subscription
- Accuracy: does it distinguish county TDT from city resort tax?
- Geographic scope: US-wide? Florida-only would be insufficient for expansion

#### 5c. Regulatory Gate Score vs Verdict Contradiction

**Problem**: `compute_regulatory_score()` allows PROCEED recommendation to override gate warnings, producing a compliance score of 74/100 while the overall verdict is NO-GO.

| Repo | Layer | File | Change Type |
|------|-------|------|-------------|
| investFlorida.ai | Pipeline | `src/pipeline/compliance_scoring.py` L62-72 | Modified |

**Fix**: Remove the PROCEED override exception. If ANY viability gate is BLOCK, compliance score caps at 30. If ANY gate is WARN, compliance score caps at 60. This overlaps with Issue 4d.

---

## Dependency Graph & Critical Path

```
                    ┌──────────────────────┐
                    │  ISSUE 1: Min-Stay   │
                    │  Penalty on Revenue  │
                    │  (str_simulation)    │
                    └──────────┬───────────┘
                               │ changes base occupancy/ADR
                               ▼
              ┌─────────────────────────────────┐
              │  ISSUE 2: Variable Cost Scaling  │
              │  (str_simulation + investFL.ai)  │◄── Template fix (5b) is independent
              └──────────┬──────────────────────┘
                         │ changes expense model interface
                         ▼
              ┌──────────────────────────┐
              │  ISSUE 3: ADR-OCC        │ ◄── Can run in PARALLEL with Issue 2
              │  Inverse Coupling        │     (different code paths)
              │  (str_simulation)        │
              └──────────┬───────────────┘
                         │ changes scenario outputs
                         ▼
    ┌────────────────────────────────────────────┐
    │  ISSUE 4: Risk Assessment Overhaul (DB-2)  │
    │  (str_simulation + investFlorida.ai)        │
    │  Depends on correct scenarios being          │
    │  computed by Issues 1-3                      │
    └──────────────────┬─────────────────────────┘
                       │
                       ▼
    ┌────────────────────────────────────────────┐
    │  ISSUE 5: Regulatory Items                 │
    │  5a: Deal-breaker banner (overlaps 4b)     │
    │  5b: Miami resort tax (independent)        │
    │  5c: Gate contradiction (overlaps 4d)      │
    └────────────────────────────────────────────┘
```

### Critical Path (sequential):
1. **Issue 1** (min-stay penalty) — changes base revenue, all downstream calculations shift
2. **Issue 2** (variable cost scaling) — depends on stable base revenue from Issue 1
3. **Issue 4** (risk overhaul) — depends on correct scenario outputs from Issues 1-3

### Parallelizable:
- **Issue 3** (ADR-OCC coupling) can be done in parallel with Issue 2 — they modify different code paths in `service.py`
- **Issue 5b** (Miami tax) is fully independent — different service function, different config
- **Issue 2 template fix** (investFlorida.ai `_tab_revenue.html` lines 359-361) is independent of the calculation fix
- **Issue 5a/5c** overlap with Issue 4 and should be done together

### Recommended execution order:
| Phase | Issues | Repo | Parallelizable? |
|-------|--------|------|-----------------|
| Phase 1 | Issue 1 (min-stay) + Issue 5b (Miami tax) | str_simulation | Yes (different files) |
| Phase 2 | Issue 2 (variable costs calc) + Issue 3 (ADR-OCC) | str_simulation | Yes (different functions) |
| Phase 2b | Issue 2 (template fix) | investFlorida.ai | Yes (with Phase 2) |
| Phase 3 | Issue 4 (risk overhaul) + Issue 5a + Issue 5c | Both repos | No (depends on Phase 1-2) |

---

## Data Contracts

### Modified: ScenarioResult (str_simulation → investFlorida.ai)

**Current response** from `calculate_scenarios()`:
```json
{
  "scenarios": {
    "conservative": {
      "annual_revenue": "float",
      "annual_operating_expenses": "float — SAME value as base (BUG)",
      "noi": "float",
      "dscr": "float",
      "cap_rate": "float",
      "cash_on_cash": "float"
    }
  }
}
```

**Required response** (after fixes):
```json
{
  "scenarios": {
    "conservative": {
      "annual_revenue": "float — adjusted by scenario factors",
      "annual_fixed_expenses": "float — constant across scenarios",
      "annual_variable_expenses": "float — scales with scenario revenue",
      "annual_operating_expenses": "float — fixed + variable (varies per scenario)",
      "noi": "float",
      "dscr": "float",
      "cap_rate": "float",
      "cash_on_cash": "float",
      "occupancy_adjustments": {
        "min_stay_penalty": "float — occupancy reduction from min-stay",
        "adr_occ_elasticity": "float — occupancy adjustment from ADR coupling"
      }
    }
  }
}
```

**Backward compatibility**: Add new fields (`annual_fixed_expenses`, `annual_variable_expenses`, `occupancy_adjustments`) as additive. Existing `annual_operating_expenses` continues to work but now varies per scenario. No breaking change — investFlorida.ai already reads per-scenario objects.

### Modified: ViabilityResult (str_simulation → investFlorida.ai)

**Current response**:
```json
{
  "viability_score": "int 0-100",
  "label": "string",
  "gates": { "str_legal": {...}, "financing_feasible": {...}, ... },
  "economics": { "noi_margin": {...}, "debt_sensitivity": {...}, ... }
}
```

**Required response** (after Issue 4):
```json
{
  "viability_score": "int 0-100",
  "label": "string",
  "gates": { ... },
  "economics": { ... },
  "risk_factors": [
    {
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "category": "financing | data_quality | cash_flow | regulatory",
      "description": "string",
      "source": "gate_name or metric_name"
    }
  ]
}
```

**Backward compatibility**: `risk_factors` is additive. Existing consumers ignore unknown fields.

### Modified: STRTaxResponse (str_simulation)

**Current**:
```json
{
  "state_tax": "float",
  "county_tax": "float",
  "city_tax": "float — always 0 unless override",
  "total_tax": "float",
  "effective_rate": "float"
}
```

**Required** (after Issue 5b):
```json
{
  "state_tax": "float",
  "county_tax": "float",
  "city_tax": "float — auto-applied for known cities",
  "total_tax": "float",
  "effective_rate": "float",
  "tax_breakdown": {
    "state_sales": "6.0%",
    "county_tdt": "6.0%",
    "city_resort": "2.0% — (Miami)"
  }
}
```

---

## Error Model

| Code | Name | Retryable | Description |
|------|------|-----------|-------------|
| INVALID_MIN_STAY | Invalid minimum stay configuration | No | min_stay_days must be >= 1 |
| UNKNOWN_CITY_TAX | City tax rate not in lookup table | No | Falls back to 0% with warning |
| ELASTICITY_OUT_OF_RANGE | ADR-OCC elasticity coefficient invalid | No | Must be between -1.0 and 0.0 |
| EXPENSE_SPLIT_MISMATCH | Fixed + variable != total expenses | No | Validation error in expense breakdown |

---

## Test Strategy

| Type | Scope | Location | Status |
|------|-------|----------|--------|
| Unit | Min-stay penalty math | `str_simulation/tests/core/test_minstay_penalty.py` | New |
| Unit | Variable cost scaling per scenario | `str_simulation/tests/unit/test_financials.py:TestScenarios` | Modified |
| Unit | ADR-OCC elasticity | `str_simulation/tests/unit/test_financials.py` | New test class |
| Unit | City tax lookup | `str_simulation/tests/unit/test_financials.py:TestSTRTax` | Modified |
| Unit | Viability risk_factors generation | `str_simulation/tests/test_str_viability.py` | Modified |
| Integration | Risk factor flow-through | `investFlorida.ai/tests/test_e2e_compliance_scoring.py` | Modified |
| Integration | Regulatory score consistency | `investFlorida.ai/tests/test_e2e_compliance_scoring.py` | Modified |
| E2E | Full report with min-stay property | Manual — generate report for property with HOA min-stay | Manual |
| E2E | Full report with weak DSCR property | Manual — verify risk badges reflect actual risk | Manual |
| Regression | All existing scenario tests | `str_simulation/tests/unit/test_financials.py` (534 lines) | Must pass (with updated assertions) |
| Regression | Break-even tests | `str_simulation/tests/core/test_breakeven.py` | Must pass unchanged |

---

## Logging & Observability

| Event | Level | Context Fields |
|-------|-------|----------------|
| min_stay_penalty_applied | INFO | property_id, min_stay_days, occ_penalty_pct, adr_discount_pct |
| variable_cost_scaled | DEBUG | scenario_name, base_variable, scaled_variable, revenue_ratio |
| elasticity_applied | INFO | scenario_name, adr_factor, occ_factor_before, occ_factor_after, elasticity |
| city_tax_resolved | INFO | city, state, city_rate, source (lookup vs override vs default) |
| risk_factor_generated | INFO | gate_name, severity, category, description |
| risk_assessment_empty | WARN | property_id, viability_score, gates_summary — when no risks generated despite low score |

---

## Architecture Decisions (ADR)

### ADR-1: ADR-OCC Elasticity Coefficient
- **Status**: Proposed
- **Context**: Real STR markets exhibit price elasticity — higher ADR reduces booking frequency. The current model treats ADR and occupancy as independent, producing unrealistically optimistic projections.
- **Decision**: Apply a configurable elasticity coefficient (default -0.3) to scenarios. Formula: `occ_adjustment = 1 + (elasticity * (adr_factor - 1))`. Keep `worst_case` as both-down (systemic market downturn, not a pricing strategy).
- **Consequences**: Optimistic scenario net revenue decreases ~5-7%. Conservative scenario net revenue increases slightly. More realistic projections. The elasticity coefficient should eventually be derived from comp data, but a configurable constant is the right first step.

### ADR-2: Expense Split in Scenario Interface
- **Status**: Proposed
- **Context**: The `_calculate_single_scenario()` function takes a single `annual_operating_expenses` parameter. Variable costs (management fees, OTA commission, cleaning, STR taxes) should scale with scenario revenue, but the interface doesn't support it.
- **Decision**: Change the function signature to accept `fixed_expenses` and `variable_expenses` separately. Recompute variable expenses proportionally: `scenario_variable = base_variable * (scenario_revenue / base_revenue)`. The expense classification in `src/core/models/expense.py` already defines FIXED/VARIABLE/VOLATILE types — use it.
- **Consequences**: Breaking change to `_calculate_single_scenario()` (internal function, not public API). All callers must pass split expenses. Volatile expenses should scale with a dampened factor (e.g., 0.5x the revenue ratio) to reflect their risk-range nature.

### ADR-3: Risk Factor Bridge Between Repos
- **Status**: Proposed
- **Context**: Viability gate results (WARN, BLOCK) in str_simulation don't propagate to investFlorida.ai's `RiskAssessment.major_risks` and `deal_breakers` lists. The template shows "No Risks" when these lists are empty, regardless of viability score.
- **Decision**: str_simulation's viability response will include a `risk_factors` array. investFlorida.ai's property_analyzer will merge these into `RiskAssessment`. Template guard will check viability score + gate results + risk lists (not just risk lists alone).
- **Consequences**: Reports will show accurate risk information. "No Risks" badge becomes rare (only for properties with all gates PASS, score > 70, and confidence > 50). Some previously "clean" reports may now show risk badges — this is correct behavior, not a regression.

### ADR-4: STR Tax Rate Resolution via External API
- **Status**: Proposed
- **Context**: Miami charges 2% city resort tax. Other FL cities have varying local taxes. Currently DEFAULT_LOCAL_OPTION_TAX = 0.0, understating total tax burden by 1-4%. Hardcoding city rates won't scale to other regions.
- **Decision**: Build a `TaxRateProvider` that resolves STR/lodging tax rates via external API (Avalara MyLodgeTax, Zip-Tax, or similar). Use the `city`/`county`/`zip_code` fields already on `STRTaxRequest`. Cache results with 30-day TTL. Fall back to current defaults (6%/6%/0%) with `tax_source: "default_fallback"` when API unavailable. No hardcoded city/county rates.
- **Consequences**: Tax rates are accurate for any US jurisdiction, not just Florida. Enables geographic expansion without code changes. Adds an external API dependency (mitigated by caching + fallback). Requires a research spike to select the right API. Adds `tax_source` and `tax_breakdown` to `STRTaxResponse` for transparency.

### ADR-5: Min-Stay Penalty as Pre-Simulation Adjustment
- **Status**: Proposed
- **Context**: Min-stay restrictions reduce bookable demand (kill short-stay segments) and suppress nightly rates. The penalty should be applied BEFORE seasonality/event multipliers because it represents a structural constraint on the property, not a market condition.
- **Decision**: Apply min-stay penalties as a pre-adjustment to base ADR and base occupancy in `simulate()`, before the seasonality loop. Use a lookup table with configurable overrides. Default: 3-night min → -5% OCC, -5% ADR.
- **Consequences**: All downstream calculations (revenue, expenses, scenarios, viability) automatically reflect the penalty. No changes needed in scenario logic — it inherits the adjusted base. The penalty is transparent and overridable.

---

## Migration / Rollout Plan

No feature flags needed. These are accuracy corrections, not new features. Rollout:

1. **All fixes go to `cap/model-accuracy-sprint-2` branch** in each repo
2. **str_simulation fixes first** — Issues 1, 2 (calc), 3, 5b
3. **investFlorida.ai fixes second** — Issues 2 (template), 4, 5a, 5c
4. **Integration test** — Generate reports for 3 property profiles:
   - Strong property (high DSCR, no min-stay restriction, good data confidence)
   - Borderline property (DSCR ~1.1, 3-night min-stay, moderate confidence)
   - Weak property (DSCR < 1.0, low confidence, regulatory issues)
5. **Merge** after all three profiles produce defensible reports
6. **Re-run persona review** on the borderline property to confirm credibility improvement
