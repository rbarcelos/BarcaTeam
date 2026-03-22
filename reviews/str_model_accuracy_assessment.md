# STR Revenue Model Accuracy Assessment

**Assessor**: STR Revenue Modeling Strategist (Principal)
**Date**: 2026-03-19
**Scope**: All remaining model accuracy issues from 6 persona reviews + revalidations
**Properties Analyzed**: 159 NE 6th St #4307 (Natiivo Miami), 3900 Biscayne Blvd S-304
**Code Reviewed**: `str_simulation` (revenue engine), `investFlorida.ai` (financial model)

---

## Executive Summary

After reviewing 6 persona reviews (39 unique issues, ~20 fixed in Sprint 1), and auditing the actual model code in both repos, I identify **6 issues that materially affect investment decisions**, **4 issues that are acceptable MVP simplifications**, and **5 issues that are feature requests for future iterations**.

The most consequential model error is the **simultaneous top-quartile ADR + top-quartile occupancy assumption** — this alone can overstate revenue by 10-18% and flip a marginal deal from "barely positive" to "deeply negative" cash flow. Combined with an unmodeled min-stay penalty, the cumulative error on a property like the Natiivo 1BD is **$8,000-$15,000/year in overstated cash flow**.

### Impact Classification

| Priority | Count | Description |
|----------|-------|-------------|
| **P0 — Model Error** | 2 | Produces materially wrong investment decisions |
| **P1 — Significant Gap** | 4 | Degrades credibility or misses real costs by >$2K/yr |
| **P2 — Acceptable MVP** | 5 | Simplification with known bounds, acceptable for launch |
| **P3 — Future Feature** | 5 | Enhancement that adds value but isn't a model error |

---

## P0 — MODEL ERRORS (Fix Before Any User Relies on Output)

### P0-1: ADR × Occupancy Correlation Not Modeled (GROUP 3, 17)

**Reported by**: STR Operator, Power User, Buyer Agent, Mortgage Manager

**The Problem in Code**:
The str_simulation engine estimates ADR and occupancy independently:
- ADR comes from AIRROI ML model → comp-anchored rebase → calibration rings
- Occupancy comes from AIRROI ML model → comp-anchored rebase → calibration rings
- These are **independent pipelines** with no cross-constraint

The scenario engine then applies independent multipliers:
```
optimistic:   ADR × 1.10, OCC × 1.05
base:         ADR × 1.00, OCC × 1.00
conservative: ADR × 0.90, OCC × 0.90
```

**Why This Is Wrong**:
In real STR markets, ADR and occupancy are **inversely correlated** at the property level. This is the fundamental pricing curve of hospitality:
- Price high → fewer bookings → lower occupancy
- Price low → more bookings → higher occupancy
- Revenue is maximized at an intermediate point on the curve

The comp data for the Natiivo property demonstrates this clearly:
- Comps at $257-$299 ADR → 79-93% occupancy
- Comps at $365-$394 ADR → 65-90% occupancy (wide variance)
- Comps at $450-$515 ADR → 53-74% occupancy

Modeling $388 ADR (60th percentile) with 80% occupancy (75th+ percentile) simultaneously assumes the property operates at the efficient frontier — achievable only by a top-tier operator with perfect pricing, exceptional reviews (100+), professional photography, and 12+ months of listing maturity.

**Magnitude of Error**:
| Scenario | ADR | OCC | Annual Revenue | Delta vs. Base |
|----------|-----|-----|---------------|----------------|
| Model base case | $388 | 80% | $113,296 | — |
| Realistic (high ADR path) | $388 | 72% | $101,966 | -$11,330 (-10%) |
| Realistic (high OCC path) | $350 | 80% | $102,200 | -$11,096 (-10%) |
| Conservative realistic | $370 | 73% | $98,573 | -$14,723 (-13%) |

On a property where base-case cash flow is only $347/mo ($4,164/yr), a 10-13% revenue overstatement **flips the investment thesis from positive to negative cash flow**.

**What AirDNA/Mashvisor Do**: AirDNA's Rentalizer uses a **revenue optimization curve** that models the ADR-occupancy tradeoff explicitly. Mashvisor uses comp-derived revenue (ADR × OCC × 365) as a single metric, never separating them. Professional underwriters use **RevPAR** (Revenue Per Available Night = ADR × OCC) as the primary metric precisely because it captures this tradeoff.

**Correct Model**:
1. **Short-term fix**: Use comp-derived RevPAR as the anchor, then decompose into ADR/OCC. If comp median RevPAR is $280/night, model ($350 ADR, 80% OCC) OR ($388 ADR, 72% OCC) — not ($388, 80%).
2. **Medium-term fix**: Implement a pricing curve constraint: when ADR exceeds comp median by X%, reduce occupancy by f(X%) based on observed elasticity in comp data.
3. **Long-term fix**: Model the revenue optimization frontier from comp scatter data and place the subject property on the curve based on listing quality signals.

**Verdict**: **REAL PROBLEM — P0**. This is the #1 model accuracy issue. Every professional underwriter I've worked with would reject projections that assume simultaneous top-quartile ADR and occupancy without explicit justification.

---

### ~~P0-2: Missing Cleaning/Turnover Costs (GROUP 10)~~ → RECLASSIFIED P2-5

**Reported by**: STR Operator
**Reclassified**: 2026-03-19 — per domain expert correction

**Original Concern**: Cleaning costs absent from OperatingCosts model.

**Correction**: In the Florida STR market, cleaning fees are **guest-paid** — charged as a separate line item on Airbnb/VRBO and collected directly from the guest at booking. The operator pays the cleaner from these guest-collected fees, making cleaning a **pass-through cost, not an operator expense**. The OperatingCosts model is correct to exclude it.

The `estimated_turnovers_monthly` field in the model serves an informational/operational planning purpose, not a cost-modeling purpose. This is consistent with how most STR operators account for cleaning — as a revenue offset, not an expense line.

**Remaining nuance**: In competitive markets, some operators reduce or eliminate guest cleaning fees to improve listing attractiveness, absorbing cleaning as an operator cost. This is a pricing strategy choice, not a model default. The current model correctly assumes standard market practice (guest-paid cleaning).

**Verdict**: **ACCEPTABLE MVP — P2**. Model is correct for standard STR operations. Could add an optional "operator-absorbed cleaning" toggle for advanced users in a future release.

---

### P0-2: Min-Stay Penalty Not Applied to Revenue Projections (GROUP 5, Reg Compliance #5)

**Reported by**: STR Operator, Buyer Agent, Regulatory Compliance

**The Problem in Code**:
The str_simulation codebase has extraction logic for min-stay requirements (LLM scans building policy docs), and the data is stored in the Building model. However, **it is never consumed by the estimate pipeline**. The revalidation confirms: "Min Stay: 1 night (default)" with "no penalty applied to projections."

The code has no min-stay adjustment factor in `core_estimate_service.py`, `estimate_calibrator.py`, or the scenario engine.

**Why This Is Wrong**:
A 3-night minimum fundamentally changes the STR revenue profile:

| Impact | Magnitude | Mechanism |
|--------|-----------|-----------|
| Occupancy reduction | -5 to -10pp | Gap nights between bookings are harder to fill with 3-night blocks; eliminates profitable Fri-Sat 2-nighters |
| ADR reduction | -3% to -5% | Must discount midweek nights to fill 3+ night blocks; loses premium weekend-only pricing |
| Revenue reduction | -8% to -15% | Combined occupancy + ADR effect |
| Booking pattern shift | Significant | Shifts from weekend-heavy (high ADR) to midweek-heavy (lower ADR) |

For a 1BD in downtown Miami, weekend 2-nighters at $400-$500/night are the highest-RevPAR segment. A 3-night minimum eliminates this entirely. The comp data used for calibration likely includes unrestricted 1-night listings, inflating the baseline.

**Magnitude of Error**: On $113K base revenue, a 10% min-stay penalty = **$11,300/year** in overstated revenue.

**What Professional Underwriters Do**: Any underwriter who sees a min-stay restriction adjusts projected occupancy down by 5-10pp and ADR down by 3-5%. This is standard in DSCR loan underwriting for restricted properties.

**Correct Model**:
```
Penalty factors by min-stay:
  1 night: 0% (no penalty)
  2 nights: -2% OCC, -1% ADR
  3 nights: -7% OCC, -4% ADR
  7 nights: -15% OCC, -8% ADR
  30 nights: -25% OCC, -15% ADR (effectively mid-term rental)
```

Apply as a post-calibration adjustment in the estimate pipeline when Building.min_stay > 1.

**Verdict**: **REAL PROBLEM — P0**. When the system knows about a min-stay restriction and has extraction logic but doesn't apply it to projections, the model is producing numbers it knows are wrong. This is the definition of a systematic bias.

---

## P1 — SIGNIFICANT GAPS (Fix Before Launch)

### P1-1: Variable Costs Frozen Across Scenarios (GROUP 9)

**Reported by**: Power User, STR Operator, Mortgage Manager

**Status**: Marked "FIXED THIS SESSION" in revalidation summary (template changed to use per-scenario values). However, the **underlying scenario engine** in `str_simulation/apps/financials/service.py` applies the same `OperatingCosts.total_annual` across all scenarios. The template fix may only be cosmetic unless the backend actually recomputes variable costs per scenario.

**The Problem in Code**:
```python
# apps/financials/service.py lines 267-308
# Same operating expenses, debt service across all scenarios
```

Management fee (20% of revenue) and STR taxes (~12% of revenue) are **percentage-of-revenue costs** that should scale. At conservative revenue ($71,812) vs. optimistic ($103,126), the variable cost delta is:
- Management: $14,362 vs $20,625 = $6,263 difference
- STR tax: $8,617 vs $12,375 = $3,758 difference
- **Total: ~$10,000/year that should vary but doesn't**

**Impact**: Makes the conservative scenario look $5K worse and the optimistic scenario look $5K better than reality. This distorts the risk/reward picture and inflates the apparent downside.

**Verdict**: **SIGNIFICANT GAP — P1**. Variable costs must scale with scenario revenue. The fix is straightforward: recompute management fee and STR tax per scenario.

---

### P1-2: STR Tax Rate Understated by ~1 Percentage Point (GROUP 21, Reg Compliance #3)

**Reported by**: Regulatory Compliance

**The Problem in Code**:
`investFlorida.ai` defaults to:
```
State Sales Tax:    6.0%
County Tourist Tax: 6.0%
City/Local Tax:     0.0%
TOTAL:             12.0%
```

For properties in the **City of Miami** (not just Miami-Dade County), the actual burden is:
- Florida state sales tax: 6.0%
- Miami-Dade Tourist Development Tax: 6.0%
- City of Miami resort tax: 2.0% (Ordinance 13937)
- **TOTAL: ~14.0%** (some sources cite 13% depending on specific surtax applicability)

The code's city tax is hardcoded to 0.0%. Even if the API returns correct rates, the fallback and many cached results use 12%.

**Magnitude of Error**: On $90K annual revenue, the delta between 12% and 14% = **$1,800/year** in understated taxes. Not enormous, but directionally wrong and easy to fix.

**Correct Model**: Add city-level tax lookup. For City of Miami properties, add 2% resort tax. For Miami Beach, also 2%. Most other FL cities have 0%.

**Verdict**: **SIGNIFICANT GAP — P1**. Easy fix, clear error, and regulatory compliance reviewers will always catch this.

---

### P1-3: Deal-Breaker Banner Empty Despite NO-GO Verdict (Reg Compliance #2)

**Reported by**: Regulatory Compliance

**The Problem**: The template has a `<!-- Deal Breakers (NO-GO/CAUTION only) -->` placeholder that renders nothing even when the verdict is NO-GO and 0/3 prerequisites pass. The `deal_breakers` list in the template context is apparently empty.

**Why This Matters**: A NO-GO verdict with no visible deal-breaker explanation is worse than no verdict at all. The user sees "53/100 — NO-GO" but has to hunt through multiple tabs to understand why. The executive summary should immediately state the blocking issues.

**Verdict**: **SIGNIFICANT GAP — P1**. This is a UX/data-flow bug, not a model accuracy issue per se, but it directly affects whether users understand the model's output.

---

### P1-4: Regulatory Gate Shows PASS Despite NO-GO Verdict (Reg Compliance #4)

**Reported by**: Regulatory Compliance

**The Problem**: The Go/No-Go gate shows `PASS` with `Compliance: 74/100` while the overall verdict is NO-GO (53/100) and prerequisites are 0/3. The compliance score threshold for PASS appears disconnected from the overall verdict logic.

**Why This Matters**: A user reading "Compliance: PASS" alongside "Verdict: NO-GO" receives contradictory signals. The compliance gate at 74/100 is above the 50 threshold for pass, but the overall score is dragged down by profitability and confidence axes.

**Correct Model**: The regulatory gate should fail if prerequisites show blocking issues (0/3 passed). Gate logic should consider prerequisite pass rate, not just the aggregate compliance score.

**Verdict**: **SIGNIFICANT GAP — P1**. Internal contradictions erode trust in all model outputs.

---

## P2 — ACCEPTABLE MVP SIMPLIFICATIONS

### P2-1: Management Fee Default at 18-20% Without Sensitivity (GROUP 22)

**Reported by**: STR Operator

**Assessment**: The management fee was 20% (hardcoded fallback), now changed to use `config.default_management_fee_pct` (18%). The STR Operator argues 15-18% is more appropriate for purpose-built STR buildings.

**My Expert View**: 18% is a **reasonable default** for a full-service property management company in Florida. The actual range is:
- Self-managed: 0%
- Co-host/hybrid: 8-12%
- Full-service (small operator): 18-22%
- Full-service (institutional): 15-18%
- Purpose-built STR (Sonder, etc.): 20-25% (they provide more services)

18% as a base case is defensible. The missing piece is a sensitivity table, not a different default.

**Magnitude**: Difference between 15% and 18% on $90K revenue = $2,700/year. Meaningful but the user can mentally adjust.

**Verdict**: **ACCEPTABLE MVP — P2**. 18% is a reasonable default. Add a management fee sensitivity toggle in a future release, not a launch blocker.

---

### P2-2: Scenario Multipliers Are Symmetric/Arbitrary (GROUP 27)

**Reported by**: Power User

**Assessment**: Scenarios use fixed factors:
```
Optimistic:    ADR +10%, OCC +5%
Conservative:  ADR -10%, OCC -10%
```

The Power User argues these should be comp-derived bands. I partially agree — comp-derived would be better — but the current approach is **standard industry practice for MVP tools**:

- AirDNA Rentalizer uses ±10-15% scenarios
- Mashvisor uses similar fixed bands
- Most DSCR lenders stress-test at -10% to -25%

The asymmetry (conservative is -10%/-10% = -19% revenue, optimistic is +10%/+5% = +15.5% revenue) actually shows **healthy pessimism bias**, which is appropriate.

**Verdict**: **ACCEPTABLE MVP — P2**. Fixed scenario bands are industry-standard for consumer tools. Comp-derived bands would be a meaningful upgrade for v2.

---

### P2-3: 5-Year Projections Use Generic Growth Rates (GROUP 26)

**Reported by**: Power User, Mortgage Manager, STR Operator

**Assessment**: The model uses:
- 2.0% revenue growth
- 2.5% expense inflation
- 3.0% property appreciation

These are conservative national averages. Miami-specific factors (supply growth from new STR buildings, regulatory evolution, insurance market volatility) aren't modeled.

**My Expert View**: 5-year projections are inherently speculative. The current rates are **reasonable defaults** and actually show healthy conservatism (expenses grow faster than revenue, creating natural margin compression). No consumer STR tool I'm aware of models market-specific growth curves.

**Verdict**: **ACCEPTABLE MVP — P2**. Generic growth rates are fine for directional 5-year outlooks. Add a disclaimer that rates are national averages and local conditions may differ.

---

### P2-4: Evidence Artifacts All Show 30% Confidence / Placeholder (GROUP 7)

**Reported by**: Power User, Regulatory Compliance

**Assessment**: The uniform 30% confidence across all compliance evidence sources suggests a fallback value. The contradictory web_research (65% allows STR AND 65% restricts STR) is a real problem in the compliance scoring logic.

However, the **revenue model doesn't depend on these confidence scores**. The compliance confidence feeds into the regulatory axis of the investment score (20% weight) and triggers hard gates below 30. The revenue projections use ADR/OCC from the simulation engine, not from compliance data.

**Impact on Investment Decisions**: The 30% placeholder may cause the regulatory score to be inaccurately low or high, affecting the overall investment score by ±5-10 points. Not ideal, but the score is already labeled CAUTION/NO-GO territory.

**Verdict**: **ACCEPTABLE MVP — P2**. The placeholder doesn't affect revenue projections. Fix it to improve compliance scoring accuracy, but it's not a model accuracy emergency.

---

## P3 — FUTURE FEATURES (Not Model Errors)

### P3-1: No FIRPTA / Foreign Investor Tax Treatment (GROUP 13, 14, 24, 25)

**Reported by**: International Investor

**Assessment**: The International Investor persona correctly identifies that foreign nationals face:
- FIRPTA: 15% withholding on gross sale price
- Federal tax on rental ECI: up to 37%
- Estate tax exposure: $60K threshold (vs $12.92M for US persons)
- Higher financing costs: 30-40% down, rates +1-2%
- Currency risk on USD-denominated returns

**My Expert View**: These are **real costs that dramatically change the investment thesis for foreign buyers**. However, they are not a model accuracy issue — they are a missing user segment. The model correctly computes returns for a US-resident buyer. It just doesn't have an international buyer mode.

For Miami specifically, ~30% of condo buyers are international. This is a **high-value feature** but architecturally it's a new financing/tax module, not a fix to existing calculations.

**Verdict**: **FUTURE FEATURE — P3**. Build an "International Investor" toggle that adjusts financing assumptions, adds withholding tax estimates, and flags FIRPTA. Not a model error — it's a missing persona.

---

### P3-2: No Structured Offer Price Recommendation (GROUP 16)

**Status**: RESOLVED in Sprint 1 (offer section with CoC/DSCR max prices added). No further action needed.

---

### P3-3: Zoning District Not Identified (GROUP 19)

**Reported by**: Regulatory Compliance

**Assessment**: The report says "Zoning Status Unclear" without stating the likely zoning code (T6-36a-O under Miami 21 for downtown). This is a data enrichment gap, not a revenue model error. The revenue projections don't depend on zoning — they depend on comps and market data.

**Verdict**: **FUTURE FEATURE — P3**. Add zoning district lookup from county GIS data. Important for compliance but doesn't affect revenue accuracy.

---

### P3-4: City of Miami STR Registration Requirements (GROUP 20)

**Reported by**: Regulatory Compliance

**Assessment**: Missing City of Miami Ordinance 13937 details (registration program, annual fees). This is a compliance data gap. The annual registration fee (~$150) is negligible in the financial model.

**Verdict**: **FUTURE FEATURE — P3**. Add to compliance module. Not a financial model error.

---

### P3-5: Furnishing Budget Low / No CapEx Reserve (GROUP 31)

**Reported by**: STR Operator

**Assessment**: $15,250 (2.5% of purchase price) for furnishing a 505sqft 1BD is on the low side for a $388/night listing. Realistic range is $18K-$25K. Additionally, no furniture replacement reserve in 5-year projections.

**My Expert View**: The furnishing estimate affects upfront cash needed but not ongoing cash flow. A $5K-$10K underestimate on initial furnishing is meaningful but not recurring. The CapEx reserve ($3K-$5K/year starting Year 2) is a valid concern for 5-year projections but is partially covered by the 1% maintenance reserve ($6,100/year).

**Verdict**: **FUTURE FEATURE — P3**. Refine furnishing estimate and add furniture replacement to 5-year model. Not a recurring revenue model error.

---

## Cumulative Error Analysis

For the Natiivo 1BD property at $610,000 asking price, here is the cumulative impact of all P0+P1 issues:

| Issue | Annual Revenue Impact | Annual Cost Impact | Net Cash Flow Error |
|-------|----------------------|-------------------|-------------------|
| ADR×OCC correlation (P0-1) | -$11,000 to -$15,000 | — | -$11,000 to -$15,000 |
| Min-stay penalty (P0-2) | -$8,000 to -$14,000 | — | -$8,000 to -$14,000 |
| Frozen variable costs (P1-1) | — | ±$5,000 (distortion) | ±$5,000 per scenario |
| Tax understatement (P1-2) | — | +$1,800 | -$1,800 |
| **CUMULATIVE** | **-$19K to -$29K** | **+$1.8K** | **-$21K to -$31K** |

**Note**: P0-1 and P0-2 partially overlap (the min-stay penalty is one reason ADR×OCC shouldn't both be top-quartile). Accounting for overlap, the realistic cumulative error is **-$12,000 to -$20,000/year in overstated cash flow**.

On a property with a model-projected cash flow of +$4,164/year, the corrected projection is **-$8,000 to -$16,000/year negative cash flow**. This transforms the investment thesis from "marginal positive" to "clear negative" — a fundamentally different investment decision.

---

## Comparison to Industry Tools

| Capability | investFlorida.ai | AirDNA Rentalizer | Mashvisor | DSCR Lender Underwriting |
|-----------|-----------------|-------------------|-----------|-------------------------|
| ADR estimation | Good (comp-anchored, ML-based) | Good (ML + comp) | Basic (area median) | Conservative (comp median) |
| Occupancy estimation | Good engine, bad constraint | Good (correlated with ADR) | Basic (area median) | Conservative (-10% from comp) |
| ADR×OCC correlation | **Missing** | Modeled | Implicit (uses RevPAR) | Explicit (stress test) |
| Cleaning costs | Guest-paid (correct) | Included in expenses | Not itemized | Required line item |
| Min-stay penalty | Extracted, **not applied** | Applied | Not modeled | Manual adjustment |
| Seasonality | Good (AIRROI + power split) | Good | Basic | Not modeled |
| Event impact | Excellent (best-in-class) | Basic | None | None |
| Scenario modeling | Good factors, frozen costs | Similar | Basic | Conservative only |
| Tax accuracy | 12% (should be 14% for Miami) | Not modeled | Not modeled | Manual input |
| Comp methodology | Strong (distance-weighted, trust curves) | Strong | Basic | Manual selection |

**Key Takeaway**: The investFlorida.ai revenue engine is **architecturally strong** — the comp-anchored calibration, confidence scoring, and event impact modeling are genuinely better than most consumer tools. The gaps are in **economic constraint modeling** (ADR×OCC correlation, min-stay penalty) and **cost scaling** (frozen variable costs across scenarios). These are fixable without rearchitecting.

---

## Recommended Fix Sequence

### Sprint 2 (Immediate — before any user relies on output)

1. **P0-2: Apply min-stay penalty** — When Building.min_stay > 1, apply occupancy and ADR penalty factors in the estimate pipeline. Use the penalty table from this document. **Effort: 1-2 days.**

2. **P0-1: RevPAR constraint** — Instead of independent ADR/OCC, anchor scenarios to comp-derived RevPAR. Decompose RevPAR into ADR/OCC pairs that respect the inverse correlation. **Effort: 2-3 days.**

### Sprint 3 (Before launch)

4. **P1-1: Scale variable costs** — Recompute management fee and STR tax per scenario based on scenario revenue, not base revenue. **Effort: 0.5 days.**

5. **P1-2: Fix Miami city tax** — Add 2% city resort tax for City of Miami properties. **Effort: 0.5 days.**

6. **P1-3 + P1-4: Fix deal-breaker banner and gate logic** — Populate deal_breakers list from prerequisite failures; fail regulatory gate when prerequisites are 0/3. **Effort: 1 day.**

### Post-Launch Roadmap

7. P2 items (sensitivity toggles, comp-derived scenario bands, evidence confidence, optional operator-absorbed cleaning toggle)
8. P3 items (international investor module, zoning lookup, CapEx reserves)

---

## Methodology Notes

This assessment is based on:
- **Code audit**: Direct reading of `str_simulation` (estimate_calibrator.py, core_estimate_service.py, financials/service.py, event_impact_config.py, confidence.py) and `investFlorida.ai` (operating_costs.py, scenario_service.py, investment_scoring_service.py, financial_calculations.py, property_analyzer.py)
- **Market knowledge**: Miami-Dade STR market data, purpose-built STR building economics, cleaning cost benchmarks, tax structure
- **Industry benchmarks**: AirDNA, Mashvisor, Rabbu, AllTheRooms methodology comparisons
- **Underwriting standards**: DSCR loan requirements from Visio Lending, Kiavi, Lima One, DSCR Capital
- **Operational experience**: STR cost structures for 1BD condos in urban Florida markets

All dollar estimates assume the Natiivo 1BD test property ($610K, 1BD/1BA, 505sqft, downtown Miami). Magnitudes will differ for other property types and markets, but the directional issues apply universally.
