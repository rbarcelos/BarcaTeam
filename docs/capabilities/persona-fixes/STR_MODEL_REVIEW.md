# STR Revenue Model Review & Recommendations

**Reviewer**: STR Revenue Strategist Agent
**Property**: 159 NE 6th St #4307, Miami, FL 33132 (Natiivo, 1BD/1BA, 505 sqft)
**Date**: 2026-03-09
**Sources**: Persona review summary, STR Operator review, Mortgage Manager review, codebase analysis

---

## 1. Occupancy 80% vs Market 26%

### Assessment: The 80% default is unjustified. The 26% market figure is also misleading.

The 26% "market occupancy" likely reflects the entire Miami-Dade STR market including seasonal/part-time listings, not professional full-time STRs. It is not a valid baseline. However, the comp average (airroi) of 75.4% *is* a valid reference -- and the model then adds to it, reaching 80%, which overshoots for this unit type.

**Why 80% fails for this specific property:**
- 505 sqft 1BD has a narrow guest profile (couples, solo business travelers). No families, no groups.
- 3-night minimum eliminates the highest-RevPAR segment: weekend 2-nighters (Fri-Sun).
- Purpose-built STR building means 200+ competing units in the same building, creating internal cannibalization.
- Guest Demand Score of 38/100 (Grade F) contradicts top-quartile occupancy.

**Correct methodology:**
1. Start with comp median occupancy for matching bedroom count and location (75.4% from airroi).
2. Apply a **3-night minimum penalty**: -5 to -8pp (eliminates ~15-20% of urban booking demand from 1-2 night stays).
3. Apply a **1BD size penalty**: -2 to -3pp (smaller guest pool, lower group capacity).
4. Apply a **building saturation adjustment**: -1 to -2pp (200+ competing units in Natiivo).
5. Do NOT apply the "+5% STR Building Boost" -- the building infrastructure helps margins, not occupancy.

**Recommended default**: **67-70% base occupancy** for a 1BD/505sqft with 3-night minimum in downtown Miami.

**Model change:**
- `OperatingCosts.expected_occupancy_rate` default: keep at 0.65 (already conservative)
- The revenue modeling agent should derive occupancy from comp data with explicit adjustment factors, not hardcode 80%
- Add adjustment factors as named parameters: `min_stay_penalty`, `unit_size_penalty`, `building_competition_penalty`
- Display: show the waterfall (comp baseline -> adjustments -> final) in the report

---

## 2. Missing Cleaning/Turnover Costs

### Assessment: Critical omission. This is the #1 line item missing from the model.

The `OperatingCosts` model has no `cleaning_cost_per_turn` field. The config has `default_supplies_cost_per_turn: $30` (toiletries/consumables) but that's not a cleaning cost -- it's restocking.

**Realistic cleaning costs for a 1BD in Miami (2026):**
- Professional cleaning service: **$100-$140 per turnover** (505 sqft, 1BD/1BA)
- Deep clean (every 5th turnover): **$180-$220**
- Laundry service (linens, towels): **$25-$35 per turnover** (often separate from cleaning)
- Supplies/restocking: **$25-$35 per turnover** (already partially modeled)

**At 70% occupancy, 3-night avg stay: ~7 turnovers/month**
- Gross cleaning cost: 7 x $130 = **$910/month**
- Guest cleaning fee revenue: 7 x $85 = **$595/month** (typical Airbnb cleaning fee for 1BD Miami)
- **Net cleaning cost: ~$315/month** ($3,780/year)
- Laundry: 7 x $30 = **$210/month** ($2,520/year)
- **Total net turnover cost: ~$525/month** ($6,300/year)

**Should it be in OpEx or offset by guest fees?**
Both. Model it as:
- **Gross cleaning expense** in Variable Costs (scales with turnovers)
- **Guest cleaning fee income** as a revenue offset line (separate from ADR revenue)
- **Net cleaning cost** shown in the summary

**Model change:**
- Add to `OperatingCosts`: `cleaning_cost_per_turn: float = 130.0`, `laundry_cost_per_turn: float = 30.0`, `guest_cleaning_fee: float = 85.0`
- Add to `AnalysisConfig`: `default_cleaning_cost_per_turn: float = 130.0`, `default_laundry_cost_per_turn: float = 30.0`
- Computed field: `net_turnover_cost_monthly = estimated_turnovers_monthly * (cleaning_cost_per_turn + laundry_cost_per_turn + supplies_cost_per_turn - guest_cleaning_fee)`
- Include in `to_breakdown_dict()` and report display

---

## 3. ADR + Occupancy Both at Top-Quartile

### Assessment: This is the classic "operator trap." You cannot sustain both simultaneously.

The comp data shows a clear inverse relationship:
- $257-$299 ADR -> 79-93% occupancy
- $365-$394 ADR -> 65-90% occupancy (wide variance)
- $450-$515 ADR -> 53-74% occupancy

**The correct approach is to model the ADR-occupancy curve, not pick both at the top.**

For this property at $388 ADR (which is reasonable given comp positioning):
- Expected occupancy at $388 ADR: **70-75%** (before 3-night min penalty)
- After 3-night min penalty (-5 to -8pp): **62-70%**
- **Realistic pairing: $388 ADR at 67-70% occupancy**

Alternatively, to achieve 80% occupancy:
- Required ADR reduction: **$320-$345 ADR**
- This would produce similar or worse total revenue ($320 x 0.80 x 365 = $93,440 vs $388 x 0.68 x 365 = $96,299)

**Model change:**
- Implement an ADR-occupancy elasticity curve derived from comp scatter data
- When base ADR is above comp median, automatically reduce occupancy from comp median proportionally
- Formula: `adjusted_occ = comp_median_occ - elasticity_factor * (subject_adr - comp_median_adr) / comp_median_adr`
- Suggested `elasticity_factor`: 0.4 to 0.6 (meaning a 10% ADR premium reduces occupancy by 4-6pp)
- Display both the "unconstrained" and "elasticity-adjusted" scenarios

---

## 4. 3-Night Minimum Impact on Revenue

### Assessment: The impact is significant and currently unmodeled.

The compliance section identifies the HOA 3-night minimum, but `OperatingCosts.min_nights_per_booking` defaults to 1 and the revenue model uses `Min Stay: 1 night (default)`.

**Quantified impact of 3-night minimum vs unrestricted:**

| Metric | Unrestricted (1-night min) | 3-Night Minimum | Delta |
|--------|---------------------------|-----------------|-------|
| Occupancy | 75% (comp avg) | 67-70% | -5 to -8pp |
| ADR | $388 | $370-$380 | -2 to -5% |
| Avg stay length | 2.8 nights | 3.8-4.2 nights | +1.0-1.4 nights |
| Monthly turnovers | ~8 | ~5.5 | -30% |
| Weekend premium capture | Full | Partial (no 2-nighters) | Lost segment |
| Gap nights (unrentable) | ~2/month | ~4-5/month | Revenue leakage |

**Why the ADR drops too (not just occupancy):**
- 3-night stays attract price-sensitive mid-week guests, not premium weekend travelers
- Longer stays command lower per-night rates (length-of-stay discounts are standard)
- You lose the "event premium" on single high-rate nights (Art Basel, Ultra, etc.)

**Model change:**
- When `min_nights_per_booking >= 3`, auto-apply:
  - Occupancy penalty: `-max(0, (min_nights - 1) * 2.5)` pp (so 3-night min = -5pp, 7-night min = -15pp, capped at -20pp)
  - ADR penalty: `-max(0, (min_nights - 1) * 1.5)` % (so 3-night min = -3%, 7-night min = -9%)
  - Adjust `avg_nights_per_booking` to `max(min_nights, comp_avg_stay + 0.5)`
- Display the penalty explicitly in the report: "3-night minimum reduces projected occupancy by X pp and ADR by Y%"

---

## 5. Variable Costs Frozen Across Scenarios

### Assessment: This is a modeling error that makes conservative scenarios look worse and optimistic scenarios look better than reality.

Currently, all scenarios use the same $6,091/mo total OpEx. The costs that should scale with occupancy:

| Cost Item | Current Monthly | Type | Should Scale? | Scaling Formula |
|-----------|----------------|------|---------------|-----------------|
| Management Fee | $1,896 | Variable | Yes | `revenue * mgmt_rate` |
| STR/Tourist Tax | $1,138 | Variable | Yes | `revenue * tax_rate` |
| Cleaning (to add) | ~$910 | Variable | Yes | `turnovers * cost_per_turn` |
| Utilities | $293 | Semi-variable | Partially | `$150 base + $143 * (occ/0.80)` |
| Maintenance | $508 | Semi-variable | Partially | `$300 base + $208 * (occ/0.80)` |
| HOA | $1,100 | Fixed | No | Constant |
| Property Tax | $940 | Fixed | No | Constant |
| Insurance | $215 | Fixed | No | Constant |

**Model change:**
- Classify each cost in `OperatingCosts` as `fixed`, `variable`, or `semi_variable`
- Variable costs recalculate per scenario: `management = scenario_revenue * mgmt_rate`, `str_tax = scenario_revenue * tax_rate`
- Semi-variable: split into base + variable component
- Add method: `recalculate_for_scenario(scenario_revenue: float, scenario_occupancy: float) -> OperatingCosts`
- This will make the conservative scenario look ~$400-$600/mo better (lower management + lower taxes) and the optimistic scenario ~$300-$500/mo worse

---

## 6. Management Fee 20%

### Assessment: 20% is the high end. For Natiivo specifically, 15-18% is more appropriate.

**Market range for Miami STR management (2026):**

| Management Type | Fee Range | Notes |
|----------------|-----------|-------|
| Full-service (standalone condo) | 20-25% | Includes guest comms, cleaning coord, maintenance |
| Full-service (purpose-built STR bldg) | 15-18% | Building provides concierge, key exchange, some coordination |
| Hybrid (owner handles some tasks) | 10-15% | Owner does guest comms, manager handles turnover |
| Self-managed (with automation) | 3-5% | Software fees, channel manager, dynamic pricing tools |
| Self-managed (manual) | 0% | Owner does everything |

**Why Natiivo warrants 15-18%, not 20%:**
- Purpose-built STR = lobby concierge, package handling, guest check-in kiosk
- Building-level cleaning services (often negotiated at lower bulk rates)
- Built-in key/lock infrastructure (no lockbox coordination needed)
- Standardized units reduce management per-unit overhead

**Impact on cash flow:**
- At 20%: management = $1,896/mo -> annual cash flow = $4,162
- At 18%: management = $1,707/mo -> annual cash flow = $6,430 (+54%)
- At 15%: management = $1,422/mo -> annual cash flow = $9,850 (+137%)

**Model change:**
- Change `default_management_fee_pct` from `0.20` to `0.18` in `AnalysisConfig` (config.py:71)
- Add logic: if building is tagged as purpose-built STR (`building_type == "str_purpose_built"`), use 0.15-0.18
- Always show a management fee sensitivity row in the scenario dashboard
- The env var `DEFAULT_MANAGEMENT_FEE_PCT` already allows override -- document this

---

## 7. DSCR 1.11x Labeled "Financing Feasible"

### Assessment: This label is dangerously misleading. 1.11x fails most DSCR loan products.

**Industry-standard DSCR thresholds:**

| DSCR Range | Label | Lending Reality |
|------------|-------|-----------------|
| >= 1.50x | Strong | Qualifies for best rates, all products |
| 1.25x - 1.49x | Adequate | Meets most DSCR loan minimums |
| 1.20x - 1.24x | Marginal | Meets minimum for some products, rate premium |
| 1.10x - 1.19x | Below Minimum | Fails most DSCR products, requires larger down payment or rate buy-down |
| 1.00x - 1.09x | Break-Even | Does not qualify, cash-flow neutral |
| < 1.00x | Negative | Cannot service debt |

**Recommended label thresholds for the report:**

| DSCR | Badge Color | Label |
|------|-------------|-------|
| >= 1.50 | Green | "Strong Coverage" |
| 1.25 - 1.49 | Green | "Financing Comfortable" |
| 1.20 - 1.24 | Yellow | "Financing Tight" |
| 1.10 - 1.19 | Orange | "Below Lender Minimum" |
| 1.00 - 1.09 | Red | "At Break-Even" |
| < 1.00 | Red | "Cannot Service Debt" |

**Model change:**
- Update `financing_feasible` gate logic in `property_analyzer.py` (~line 6865-6874):
  - `dscr >= 1.25` -> pass (green)
  - `1.20 <= dscr < 1.25` -> warn (yellow), label "Financing Tight"
  - `1.10 <= dscr < 1.20` -> fail (orange), label "Below Lender Minimum -- most DSCR products require 1.20-1.25x"
  - `dscr < 1.10` -> fail (red), label "Cannot Service Debt" or "At Break-Even"
- Add to report: "To achieve 1.25x DSCR, purchase price would need to be $X or down payment would need to be Y%"

---

## 8. Expense Ratio 64%

### Assessment: 64% is high but not unrealistic for a 1BD urban luxury STR -- however it's missing cleaning costs, which would push it to ~70%.

**Benchmarks for urban luxury 1BD STR (2025-2026):**

| Market | Expense Ratio (excl. debt) | Notes |
|--------|---------------------------|-------|
| Miami (purpose-built STR) | 55-65% | High HOA, high taxes, moderate management |
| Miami (standard condo) | 60-70% | Higher management, more maintenance |
| Austin / Nashville (1BD) | 45-55% | Lower HOA/taxes |
| NYC (luxury 1BD) | 65-75% | Very high HOA, regulations |

**This property's actual expense ratio (correcting for missing costs):**
- Current OpEx (excl. mortgage): $6,091/mo = $73,094/yr
- Missing cleaning (net): +$525/mo = +$6,300/yr
- Missing laundry: included in above
- **Corrected OpEx: $6,616/mo = $79,394/yr**
- **Corrected expense ratio: $79,394 / $113,781 = 69.8%**
- At corrected occupancy (68%): Revenue drops to ~$96,300/yr -> expense ratio = **~75%** (with proportionally lower variable costs ~$74,500 -> **77%**)

This means the property's true expense ratio is in the **70-77% range**, which is critically high. The 64% in the report is already concerning; the real number is worse.

**Model change:**
- After adding cleaning costs (item 2), the expense ratio will self-correct
- Add benchmark comparison in report: "Your expense ratio of X% compares to the Miami 1BD STR benchmark of 55-65%"
- Flag expense ratios above 65% as "High" and above 75% as "Critical"

---

## 9. 5-Year Growth Assumptions (2% rev, 2.5% exp, 3% appreciation)

### Assessment: Directionally reasonable but mechanistic. Need Miami-specific calibration and a stress scenario.

**Current defaults** (from `config.py:78-80`):
- `revenue_growth_rate: 0.02` (2%)
- `expense_growth_rate: 0.025` (2.5%)
- `property_appreciation_rate: 0.03` (3%)

**Miami-specific reality check:**

| Metric | Model | Miami Historical (2020-2025) | Miami Forward Estimate | Verdict |
|--------|-------|------------------------------|----------------------|---------|
| Revenue growth | 2.0% | Volatile: +40% (2021), -5% (2023), +8% (2024) | 1-3% (maturing market, supply growth) | Reasonable for stabilized yr 2+ |
| Expense growth | 2.5% | HOA: +5-8%/yr for new construction (reserve funding), Insurance: +10-15%/yr (FL crisis), Taxes: 3-5%/yr | 4-6% blended for new condo | **Too low** |
| Appreciation | 3.0% | 8-12% (2021-2023), 2-4% (2024-2025) | 2-4% (normalizing) | Reasonable |

**Key risks not captured:**
- HOA special assessments in years 3-5 (extremely common in new FL condos post-Surfside)
- Florida insurance crisis: property insurance premiums rising 10-15%/yr
- STR supply growth: 3-4 new purpose-built STR buildings in downtown Miami pipeline
- Regulatory risk: Miami STR regulation is tightening

**Model change:**
- Increase `expense_growth_rate` default from `0.025` to `0.035` (3.5%) -- better reflects FL insurance + new-construction HOA reality
- Keep `revenue_growth_rate` at `0.02` (conservative is appropriate)
- Keep `property_appreciation_rate` at `0.03`
- Add a **stress scenario** to 5-year projections: 0% revenue growth, 5% expense growth, 1% appreciation
- Add env var `EXPENSE_GROWTH_RATE_STRESS` defaulting to `0.05`
- In the report, show both "Base Projection" and "Stress Projection" side by side

---

## Summary of All Recommended Model Changes

| # | Finding | Current Value | Recommended Value | Impact | Priority |
|---|---------|--------------|-------------------|--------|----------|
| 1 | Base occupancy | 80% (from API + boosts) | 67-70% (comp-derived with penalties) | Revenue drops ~15% | P1 |
| 2 | Cleaning costs | Missing ($0) | $525/mo net ($6,300/yr) | Cash flow drops $525/mo | P1 |
| 3 | ADR-OCC coupling | Both top-quartile | Elasticity curve, pick one | Prevents over-optimism | P1 |
| 4 | 3-night min penalty | Not modeled | -5pp OCC, -3% ADR | Revenue drops ~10% | P1 |
| 5 | Variable cost scaling | Frozen across scenarios | Scale mgmt, tax, cleaning with revenue/occ | Conservative scenario improves, optimistic worsens | P2 |
| 6 | Management fee | 20% default | 18% default, 15% for purpose-built STR | Cash flow improves $189-$474/mo | P2 |
| 7 | DSCR labels | "Feasible" at 1.11x | "Below Lender Minimum" at <1.20x | Accurate lending signal | P1 |
| 8 | Expense ratio | 64% (missing costs) | ~70-77% (with cleaning + corrected occ) | Report accuracy | P1 |
| 9 | Expense growth rate | 2.5% | 3.5% base, 5.0% stress | 5-year projection realism | P2 |

**Combined impact on base-case cash flow:**
- Current model: +$347/mo (+$4,162/yr)
- After corrections: approximately **-$600 to -$900/mo** (-$7,200 to -$10,800/yr)
- The property is likely **cash-flow negative** at asking price under realistic assumptions
- This validates the STR Operator's and Mortgage Manager's conclusions

---

## Code Files Requiring Changes

| File | Change |
|------|--------|
| `src/pipeline/config.py` | Add cleaning cost defaults, update expense growth rate, update management fee default |
| `src/models/operating_costs.py` | Add cleaning/laundry/guest-fee fields, add `recalculate_for_scenario()`, add cost classification |
| `src/agents/revenue_modeling_agent.py` | Implement ADR-OCC elasticity, min-stay penalties, occupancy waterfall |
| `src/pipeline/property_analyzer.py` | Update DSCR label thresholds, pass scenario-adjusted costs, add expense ratio benchmarks |
| `src/reports/` (templates) | Display occupancy waterfall, cleaning line item, DSCR labels, expense ratio benchmarks |
