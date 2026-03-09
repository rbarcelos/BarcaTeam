# Persona Review Fixes - Architecture & Code Trace

**Source**: Unified persona review of Natiivo 159 NE 6th St #4307 report (v2, 2026-03-09)
**Traced by**: Architect agent
**Date**: 2026-03-09

---

## P0 Fixes (Data Bugs - Fix Immediately)

### GROUP 1: Broken Expense Ratios (6,424%) Fed to LLM

**Severity**: Critical | 5/6 personas flagged

**Root Cause**: Double-multiplication of percentage values.

The expense percentages are computed in `property_analyzer.py:4647-4658` with `* 100`:
```python
total_opex_pct = (annual_opex / annual_revenue * 100) if annual_revenue > 0 else 0
hoa_pct = (analysis.operating_costs.hoa_monthly * 12 / annual_revenue * 100) if annual_revenue > 0 else 0
# ... same pattern for property_tax_pct, insurance_pct, management_pct, str_tax_pct
```

These values (e.g., `64.24`) are stored in `ExpenseAnalysis` fields (`investment_context.py:920-1019`) whose metadata uses format string `{:.1%}`:
```python
total_opex_pct: float = field(
    default=0.0,
    metadata=tab_metric(tabs=["economics"], display="Total OpEx % of Revenue", format_str="{:.1%}", importance="high")
)
```

Python's `{:.1%}` format multiplies by 100 again: `64.24 * 100 = 6424.1%`.

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/pipeline/property_analyzer.py` | 4647-4658 | Remove `* 100` from all percentage calculations. Store as decimals (e.g., `0.6424` not `64.24`) |

**Before**: `total_opex_pct = (annual_opex / annual_revenue * 100)`
**After**: `total_opex_pct = (annual_opex / annual_revenue)`

Same fix for: `hoa_pct`, `property_tax_pct`, `insurance_pct`, `insurance_ho6_pct`, `insurance_liability_pct`, `management_pct`, `str_tax_pct`, `maintenance_pct`, `utilities_pct`.

**Verification**: The `{:.1%}` format will then correctly render `0.6424` as `"64.2%"`.

**Impact downstream**: Check `ExpenseAnalysis.validate_against_benchmarks()` (around line 1050+) which may compare these values against benchmark ranges — those benchmarks in `financial_assumptions.py:100-163` are already expressed as decimals (e.g., `0.60` for 60%).

---

### GROUP 2: Contradictory Risk Assessment ("No Risks" vs CAUTION)

**Severity**: Critical | 5/6 personas flagged

**Root Cause**: Risk lists are never populated from scenario analysis.

The template `_tab_confidence.html:113-118` (both v1 and v2) shows "No Significant Investment Risks Detected" when:
```jinja
{% if not context.data.risk.major_risks and not context.data.risk.manageable_risks %}
```

These lists are populated at `property_analyzer.py:6388-6595`. The population logic relies on TWO sources:

1. **`investment_score.key_risks`** (line 6520-6525) - This attribute is typically empty or absent on `InvestmentScore` because `calculate_investment_score()` in `investment_scoring_service.py` never sets `key_risks`.

2. **Hard gate failures** (lines 6564-6571) - Only adds risks for `noi_gate_failed`, `pricing_gate_failed`, `regulatory_gate_failed`.

**Missing**: The `ScenarioService.assess_risk_level()` results (`risk_warnings` at line 4236) are computed but **never wired** into the `major_risks`/`manageable_risks` lists at line 6388-6595. The variable `risk_warnings` is used only for logging.

Additionally, `assess_risk_level()` correctly detects:
- `scenario_service.py:357-358`: "MODERATE: Tight debt coverage in base scenario (DSCR < 1.2)" — would fire for DSCR 1.11
- `scenario_service.py:361-362`: High break-even occupancy warnings

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/pipeline/property_analyzer.py` | ~6388-6525 | Wire `risk_warnings` from scenario analysis into `major_risks`/`manageable_risks` lists |
| `investFlorida.ai/src/models/investment_score.py` | Model definition | Consider adding `key_risks: List[str]` field populated by `calculate_investment_score()` |
| `investFlorida.ai/src/services/investment_scoring_service.py` | `calculate_investment_score()` | Generate risk warnings based on computed metrics (DSCR < 1.25, CoC < 5%, high break-even) |

**Proposed fix at `property_analyzer.py`**: After line ~4236 where `risk_warnings` is computed, store it on `analysis` or pass it forward. Then at line ~6388, merge:
```python
# After line 6525:
# Wire scenario risk warnings into risk lists
if risk_warnings:
    for risk in risk_warnings:
        if "CRITICAL" in risk.upper() or "HIGH" in risk.upper():
            major_risks.append(risk)
        else:
            manageable_risks.append(risk)
```

---

## P1 Fixes (Credibility Killers - Fix Before Launch)

### GROUP 3: 80% Occupancy vs 26% Market Reality

**Severity**: Critical | 4/6 personas flagged

**Root Cause**: `base_occupancy` comes from airroi API comp data unvalidated.

The flow:
1. `property_analyzer.py:1184` calls `_get_adr_baseline()` which uses `ADRStrategyService`
2. `adr_strategy.py:669`: `base_occupancy = market.get("base_occupancy", 0.65)` — comes from API
3. The airroi API returns comp-based occupancy (e.g., 80% from 2 comps averaging 75.4%)
4. Meanwhile, market occupancy (26%) comes from a different data source (market statistics / demand score)
5. **No validation** reconciles these two figures

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/pipeline/property_analyzer.py` | ~1947-1955 | After extracting `base_occupancy` from baseline, validate against market data |
| `investFlorida.ai/src/services/adr_strategy.py` | ~669 | Add market occupancy cross-check |

**Proposed fix**: After extracting `base_occupancy`, check if market occupancy data is available. If market occupancy < 50% of base_occupancy, add a prominent warning and consider capping:
```python
if market_occupancy is not None and base_occupancy > market_occupancy * 2.0:
    logger.warning(f"Base occupancy {base_occupancy:.0%} is >2x market occupancy {market_occupancy:.0%}")
    # Add to risk warnings
    # Consider: base_occupancy = min(base_occupancy, max(market_occupancy * 1.5, comp_avg * 0.9))
```

---

### GROUP 5: 3-Night Minimum Not Modeled in Revenue

**Severity**: Major | 3/6 personas flagged

**Root Cause**: `min_nights_per_booking` exists in `OperatingCosts` model but has no revenue impact.

The `OperatingCosts` model (`operating_costs.py:69-73`) has:
```python
min_nights_per_booking: int = Field(default=1, ge=1)
avg_nights_per_booking: float = Field(default=3.0, ge=1.0)
```

These are used only for `estimated_turnovers_monthly` (line 111-120). They have **zero effect** on revenue projections.

The revenue projection in `revenue_projection_service.py` uses `base_adr * base_occupancy * 365` without any min-stay penalty.

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/services/revenue_projection_service.py` | Revenue calculation | Apply min-stay revenue penalty when `min_stay > 1` |
| `investFlorida.ai/src/pipeline/property_analyzer.py` | Scenario construction ~4100-4150 | Pass `minimum_stay_days` and apply occupancy/ADR adjustment |
| `str_simulation/src/services/investment_service.py` | Projection engine | Accept min_stay parameter and adjust revenue |

**Proposed penalty model** (industry research):
- min_stay=2: -3% occupancy, -1% ADR
- min_stay=3: -7% occupancy, -3% ADR
- min_stay=7: -15% occupancy, -5% ADR (but higher ADR per booking due to longer stays)
- min_stay=30: -25% occupancy, +5% ADR (monthly rental market)

---

### GROUP 6: HOA Status Contradictory (Confirmed vs Verify)

**Severity**: Major | 2/6 personas flagged

**Root Cause**: Prerequisites template treats gate `status == 'pass'` as "confirmed" regardless of confidence.

In `executive_summary.html:416-417` (v2 template):
```jinja
{% if merged_pass %}
    {% set merged_reason = 'Legal + HOA confirmed' %}
```

The gate can be `status=pass` with `confidence=0.3` (low confidence). Meanwhile, the regulatory tab analyzer at `regulatory_tab_analyzer.py:464-476` uses different thresholds:
```python
if hoa_score < 20: hoa_allows_text = "No"
elif hoa_score < 30: hoa_allows_text = "Likely No (uncertain - verification required)"
elif hoa_score >= 50: hoa_allows_text = "Yes"
else: hoa_allows_text = "Possibly Yes (uncertain - verification required)"
```

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/reports/templates/v2_report/sections/executive_summary.html` | 416-429 | Factor confidence into label |
| `investFlorida.ai/src/reports/templates/v1_report/sections/executive_summary.html` | Same section | Same fix |

**Proposed fix**:
```jinja
{% if merged_pass %}
    {% set gate_conf = [str_gate.confidence|default(0), hoa_gate.confidence|default(0)] | min %}
    {% if gate_conf >= 0.7 %}
        {% set merged_reason = 'Legal + HOA confirmed' %}
    {% elif gate_conf >= 0.4 %}
        {% set merged_reason = 'Legal + HOA likely (verify recommended)' %}
    {% else %}
        {% set merged_reason = 'Legal + HOA unclear (verification required)' %}
    {% endif %}
{% endif %}
```

---

### GROUP 9: Expenses Frozen Across Scenarios

**Severity**: Major | 2/6 personas flagged

**Root Cause**: `ScenarioService.calculate_scenario` uses fixed `operating_costs.total_annual` regardless of scenario.

At `scenario_service.py:128`:
```python
annual_operating_expenses = operating_costs.total_annual
```

This same value is used for all scenarios (optimistic, base, conservative, worst_case). Variable costs (management fee = 20% of revenue, STR tax = 12% of revenue) should scale with scenario revenue, while fixed costs (mortgage, property tax, insurance, HOA, utilities) stay constant.

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/services/scenario_service.py` | 82-128 | Split costs into fixed + variable; recalculate variable costs per scenario |
| `investFlorida.ai/src/models/operating_costs.py` | Model | Add `variable_costs_monthly` and `fixed_costs_only_monthly` computed fields |

**Proposed fix**:
```python
# In calculate_scenario():
fixed_costs = (
    operating_costs.mortgage_monthly + operating_costs.property_tax_monthly +
    operating_costs.insurance_monthly + operating_costs.hoa_monthly +
    operating_costs.utilities_monthly + operating_costs.maintenance_monthly
) * 12

# Variable costs recalculated on scenario revenue
variable_costs = annual_gross_revenue * (
    management_fee_rate +  # typically 0.20
    str_tax_rate           # typically 0.12
)

annual_operating_expenses = fixed_costs + variable_costs
```

---

### GROUP 10: Missing Cleaning/Turnover Costs

**Severity**: Critical | 1/6 personas (but operationally devastating)

**Root Cause**: No cleaning cost field or calculation in `OperatingCosts` model or server-side `compute_operating_costs()`.

The `OperatingCosts` model (`operating_costs.py`) computes `estimated_turnovers_monthly` but never multiplies it by a cost-per-turnover. The server-side `compute_operating_costs()` in `str_simulation/src/services/investment_service.py:435-489` calculates 6 items (mortgage, property_tax, insurance, management_fee, utilities, str_tax) — no cleaning.

At 80% occupancy, 3-night average stays: ~8 turnovers/month at $100-150/clean = $800-1,350/month missing.

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/models/operating_costs.py` | Model | Add `cleaning_cost_per_turnover: float` field and `cleaning_costs_monthly` computed field |
| `str_simulation/src/services/investment_service.py` | 435-489 | Add cleaning cost calculator to `compute_operating_costs()` |
| `str_simulation/src/config/financial_config.py` | `OperatingExpenseDefaults` | Already has `CLEANING_PCT_OF_RATE: float = 0.15` but it's unused |

**Proposed model addition** (`operating_costs.py`):
```python
cleaning_cost_per_turnover: float = Field(
    default=0.0, ge=0, description="Cost per turnover/cleaning ($100-150 typical)"
)

@computed_field
@property
def cleaning_costs_monthly(self) -> float:
    return self.estimated_turnovers_monthly * self.cleaning_cost_per_turnover
```

Then include `cleaning_costs_monthly` in `total_monthly` calculation.

---

### GROUP 11: DSCR Label Wrong ("Financing Feasible" at 1.11x)

**Severity**: Critical | 1/6 personas (but blocks financing)

**Root Cause**: Multiple layers of labeling with different thresholds.

1. **Template label** (`executive_summary.html:75-76`): Labels DSCR 1.0-1.25 as "Thin" — this is reasonable.

2. **Server-side gate** (`str_simulation/src/services/viability_service.py:189-194`): Correctly returns `WARN` status with reason "tight margins" for DSCR 1.0-1.25.

3. **Prerequisites section** (`executive_summary.html:432-437`): Shows `financing_feasible` gate. When status is `warn`, it shows a yellow warning badge, but the gate name still reads "Financing Feasible" which implies it's feasible.

4. **Server constants** (`str_simulation/src/config/constants.py:85-88`):
```python
DSCR_PASS_THRESHOLD: float = 1.25    # Healthy
DSCR_WARN_THRESHOLD: float = 1.00    # Negative cash flow begins
DSCR_BLOCK_THRESHOLD: float = 0.80   # Severely negative
```

The thresholds are correct (1.25 pass), but the label shown in the report for a `warn` gate still reads as "feasible" because it's the gate *name*.

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/reports/templates/v2_report/sections/executive_summary.html` | ~432 | Display gate reason instead of gate name when status is `warn` |
| `investFlorida.ai/src/reports/templates/v1_report/sections/executive_summary.html` | Same | Same fix |

**Proposed fix**: In the prerequisites loop, when a gate has `warn` status, show the reason text (e.g., "DSCR 1.11 - tight margins") instead of the generic gate name "Financing Feasible".

---

### GROUP 12: Interest Rate / Loan Terms Not Disclosed

**Severity**: Critical | 1/6 personas

**Root Cause**: The data IS available in the operating costs response but not surfaced in the report template.

The server returns `MortgageResponse` with `rate` and `term_years` (`investment_service.py:113-116`). The client stores these in `FinancingAssumptions` in the report data model. But the report templates don't display them.

**Files to change**:
| File | Lines | Change |
|------|-------|--------|
| `investFlorida.ai/src/reports/templates/v2_report/sections/executive_summary.html` | Near DSCR card | Add financing assumptions disclosure |
| `investFlorida.ai/src/reports/templates/v2_report/sections/investment_analysis/_tab_pricing.html` | Deal structure section | Add rate/term/amort type |

---

## P2 Fixes (Quality Improvements)

### GROUP 4: Market Data Confidence 0/100 Not Surfaced

The 0/100 confidence scores exist in the data but are not prominently shown. The executive summary should display a warning banner when any confidence dimension is below a threshold (e.g., 20/100).

**Files to change**: `executive_summary.html` templates (both v1/v2) — add confidence banner logic.

### GROUP 7: Evidence Artifacts at 30% (Placeholder)

All evidence artifacts show 30% confidence. This comes from `source_confidence.py` defaults. Need to verify whether the evidence collector is properly scoring sources.

**Files to investigate**: `str_simulation/src/core/evidence/source_scorer.py`

### GROUP 8: Monthly Seasonality Not Prominently Surfaced

The 7-8 month negative cash flow pattern is in the data but not called out. Add a "Seasonal Cash Flow Warning" callout when >4 months are negative.

### GROUP 15: No Cap Rate Displayed

Cap rate IS calculated in `scenario_service.py:155-156` but not shown in executive summary. Add it to the financial metrics cards.

### GROUP 23: Score Weighting Not Disclosed

Weights are in `investment_scoring_service.py:633`:
```python
base = 0.25 * S_market + 0.25 * S_profit + 0.20 * S_regulatory + 0.15 * S_value + 0.15 * S_conf
```
Add a methodology disclosure section to the report.

---

## Server-Side Issues (str_simulation)

### Missing City Resort Tax (relates to GROUP 21)

`financial_config.py` and `investment_service.py` both set `DEFAULT_LOCAL_OPTION_TAX = 0.0`. Miami charges a 2% city resort tax (Ordinance 13937). The `city_str_tax_rate` in `financial_assumptions.py:84-89` also defaults to `0.00`.

**Fix**: Add Miami city resort tax (2%) to the tax calculation when city is "Miami". This could be a lookup table in `investment_service.py` or passed by the client.

### Cleaning Cost Calculator Missing (relates to GROUP 10)

`OperatingExpenseDefaults` in `financial_config.py:157-158` defines `CLEANING_PCT_OF_RATE: float = 0.15` but it's never used in `compute_operating_costs()`. Wire it in as the 7th calculator.

---

## Summary: Fix Priority & Effort Matrix

| # | Group | Fix | Repo | Effort | Risk |
|---|-------|-----|------|--------|------|
| 1 | G1 | Remove `*100` from expense pct calcs | investFlorida.ai | S (1 file, ~12 lines) | Low |
| 2 | G2 | Wire risk_warnings into risk lists | investFlorida.ai | S (1 file, ~15 lines) | Low |
| 3 | G11 | Show gate reason not name when warn | investFlorida.ai | S (2 templates) | Low |
| 4 | G6 | Factor confidence into prereq labels | investFlorida.ai | S (2 templates) | Low |
| 5 | G12 | Surface financing assumptions in template | investFlorida.ai | S (1-2 templates) | Low |
| 6 | G3 | Add occupancy cross-validation | investFlorida.ai | M (2-3 files) | Medium |
| 7 | G10 | Add cleaning cost calculator | Both repos | M (3-4 files) | Medium |
| 8 | G9 | Split fixed/variable costs in scenarios | investFlorida.ai | M (2 files) | Medium |
| 9 | G5 | Model min-stay revenue penalty | Both repos | L (3-4 files) | Medium |
| 10 | G21 | Add city resort tax | str_simulation | S (1-2 files) | Low |

**S** = Small (<30 LOC), **M** = Medium (30-80 LOC), **L** = Large (80+ LOC)

Items 1-5 are straightforward data/template fixes with low risk.
Items 6-9 require calculation logic changes and should include test coverage.
Item 10 is a server-side config fix.

---

## Architectural Notes

### Data Flow for Expense Ratios (GROUP 1)
```
Server: /investment/operating-costs → OperatingCostsResponse (absolute $)
    ↓
Client: property_analyzer.py → calculates pct = (cost / revenue * 100)  ← BUG: *100
    ↓
Model: investment_context.py → ExpenseAnalysis (stores pct values)
    ↓
Extractor: smart_metric_extractor.py → reads annotated fields
    ↓
Format: {:.1%} applied → 64.24 becomes "6424.1%"  ← DOUBLE MULTIPLICATION
    ↓
LLM: economics_tab_analyzer.py → sends garbled ratios to LLM prompt
```

### Data Flow for Risk Assessment (GROUP 2)
```
Scenario Service: assess_risk_level() → risk_warnings (list of strings)
    ↓
property_analyzer.py:4236 → risk_warnings stored locally  ← NEVER FORWARDED
    ↕  (gap — not connected)
property_analyzer.py:6388 → major_risks = [], manageable_risks = []
    ↓ (populated only from investment_score.key_risks which is empty)
Template: _tab_confidence.html → "No Significant Investment Risks Detected"
```

### Data Flow for Occupancy (GROUP 3)
```
airroi API → comp_avg_occupancy (e.g., 75.4% from 2 comps)
    ↓
/str/estimate → base_occupancy (e.g., 80% after adjustments)
    ↓
adr_strategy.py → ADRBaseline.base_occupancy = 0.80
    ↓
property_analyzer.py → uses 80% for all projections
    ↕  (no cross-check)
Market API → market_occupancy = 26% (from different source)
    ↓
Template: displayed as "Market Occupancy: 26%" with no reconciliation warning
```
