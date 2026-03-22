# Sprint 2 — Mortgage Manager / Lending Underwriter Review

**Persona**: Mortgage Manager
**Date**: 2026-03-19
**Sprint**: Model Accuracy Sprint 2
**Reports Reviewed**: Natiivo (Miami), Vista Cay (Orlando), Club at Brickell Bay (Miami)
**Prior Review**: `reviews/mortgage_manager_review.md` (Sprint 1, 2026-03-09)

---

## Confidence Score: 7 / 10

A meaningful improvement from Sprint 1. The model now produces numbers I could use for a preliminary screening call, not a credit memo, but enough to decide whether a deal merits further diligence. Sprint 1 was a 3-4 at best. The gap to an 8 is addressable, and I detail the remaining issues below.

---

## Executive Assessment

Sprint 2 has resolved the most damaging credibility problems from my original review. Interest rates and loan terms are now disclosed. DSCR context labels now match lending reality. Variable costs scale with revenue across scenarios. Management fees reflect market rates. The model no longer presents a uniformly rosy picture that collapses under basic scrutiny.

Where the model improved most is in its ability to differentiate deal quality. The three test properties range from borderline-viable (Natiivo, DSCR 1.57x) to obvious declines (Orlando 0.36x, Brickell 0.03x), and the model correctly identifies and labels each. This is the single most important capability for preliminary screening: the model does not mislead a borrower into thinking a bad deal is fundable.

That said, I still have concerns that would prevent me from using these reports as-is for formal underwriting. They are detailed below.

---

## Property-by-Property Underwriting Assessment

### 1. Natiivo Miami (159 NE 6th St #4307) — Borderline Viable

| Metric | Base | Optimistic | Conservative | Lender Threshold |
|--------|------|-----------|-------------|-----------------|
| DSCR | 1.57x | 1.88x | 1.16x | 1.25x minimum |
| NOI | $57,199 | $68,550 | $42,521 | Positive required |
| Cap Rate | 9.38% | 11.24% | 6.97% | 5-7% typical FL |
| Cash-on-Cash | 12.1% | 18.7% | 3.5% | 8%+ target |
| Net Cash Flow | $20,674 | $32,025 | $5,995 | Positive required |
| Occupancy | 78.9% | 82.5% | 70.7% | Market: 26% |
| ADR | $375 | $413 | $338 | Market avg: $237 |
| OpEx Ratio | 47.1% | 44.8% | 51.2% | 40-50% target |

**Lending assessment**: The base case DSCR of 1.57x clears the 1.25x lender minimum comfortably. Even the conservative scenario at 1.16x, while below minimum, still services debt. This is a deal I would advance to full underwriting. The break-even occupancy of 63.8% provides a 15-point cushion versus base, which is adequate.

**Remaining concern**: The 3-night minimum stay penalty is correctly applied (occupancy and ADR both reduced), but the conservative scenario DSCR of 1.16x sits in what the model now correctly labels "Below Lender Minimum." A borrower needs to understand that the conservative case would not qualify for most DSCR loan products — the deal works only if base-case assumptions hold.

**Verdict improvement**: Sprint 1 showed this property at DSCR 1.11x with no lending context. Sprint 2 shows 1.57x with correct penalties applied and the conservative scenario properly flagged. This is a fundamentally different and more accurate picture.

---

### 2. Vista Cay Orlando (5049 Shoreway Loop) — Clear Decline

| Metric | Base | Optimistic | Conservative | Lender Threshold |
|--------|------|-----------|-------------|-----------------|
| DSCR | 0.36x | 0.49x | 0.19x | 1.25x minimum |
| NOI | $13,449 | $18,438 | $7,146 | Positive required |
| Cap Rate | 2.15% | 2.95% | 1.14% | 5-7% typical FL |
| Cash-on-Cash | -13.7% | -10.8% | -17.3% | 8%+ target |
| Net Cash Flow | -$23,974 | -$18,986 | -$30,277 | Positive required |
| Occupancy | 52.3% | 54.8% | 47.1% | Market: 31% |
| ADR | $248 | $272 | $223 | Market avg: $186 |
| OpEx Ratio | 71.6% | 66.2% | 81.3% | 40-50% target |
| Break-even Occ | 78.8% | — | — | Never achievable |

**Lending assessment**: Immediate decline. DSCR of 0.36x means the property generates roughly one-third of what is needed to cover debt service. Even the optimistic scenario (0.49x) cannot service the loan. The property would require the borrower to inject approximately $24K/year out of pocket in the base case. No DSCR loan program would touch this.

**Model accuracy**: The deal-breakers are correctly identified: "DSCR below breakeven (0.36x)" and "Negative cash-on-cash return (-13.7%)." The NO-GO verdict is appropriate. The 5-year projection correctly shows cumulative negative cash flow of -$142,401, confirming this deal never turns positive.

**Risk warning quality**: The risk warnings are well-calibrated:
- "CRITICAL: Negative cashflow in base scenario" — correct
- "HIGH: Cannot service debt in conservative scenario" — correct
- "MODERATE: Requires 79% occupancy to break even" — correct, and the model correctly labels break-even confidence as "Never"

---

### 3. Club at Brickell Bay (1200 Brickell Bay Dr #2202) — Catastrophic Decline

| Metric | Base | Optimistic | Conservative | Lender Threshold |
|--------|------|-----------|-------------|-----------------|
| DSCR | 0.03x | 0.10x | -0.06x | 1.25x minimum |
| NOI | $2,118 | $6,778 | -$3,830 | Positive required |
| Cap Rate | 0.19% | 0.62% | -0.35% | 5-7% typical FL |
| Cash-on-Cash | -20.7% | -19.2% | -22.6% | 8%+ target |
| Net Cash Flow | -$63,747 | -$59,087 | -$69,695 | Positive required |
| Occupancy | 44.7% | 46.6% | 40.3% | Market: 28% |
| ADR | $275 | $303 | $247 | Market avg: $216 |
| OpEx Ratio | 95.3% | 86.9% | 110.5% | 40-50% target |
| Break-even Occ | 100%+ | — | — | Never achievable |

**Lending assessment**: This is the clearest decline I have seen in any automated property analysis tool. A DSCR of 0.03x means the property generates approximately 3 cents of NOI for every dollar of debt service. The conservative scenario produces a **negative NOI** (-$3,830), meaning operating expenses alone exceed revenue before debt service is even considered. The 5-year projection shows cumulative losses of -$385,231.

**Model accuracy**: The model correctly identifies this as NO-GO with deal-breakers: "DSCR below breakeven (0.03x)" and "Negative cash-on-cash return (-20.7%)." The break-even occupancy is correctly calculated at 100% (meaning even at full occupancy, the property cannot break even at current ADR and expense levels). This is precisely the kind of analysis that protects borrowers from catastrophic decisions.

**Conservative scenario with negative NOI**: This is a strong validation of the variable cost scaling fix. In the conservative scenario, expenses ($40,186) exceed revenue ($36,356), producing negative NOI. This makes sense: even with reduced variable costs, the high fixed-cost burden ($9,790 property tax, $11,000 maintenance) overwhelms a property generating only $3,030/month. The model gets this right.

---

## What Sprint 2 Fixed (From My Original 13 Findings)

| Original Finding | Severity | Status | Notes |
|-----------------|----------|--------|-------|
| 1. DSCR below lending thresholds — no context | Critical | **FIXED** | DSCR lending threshold buckets now displayed, 1.0-1.25x correctly labeled "Below Lender Minimum" |
| 2. Interest rate / loan terms not disclosed | Critical | **FIXED** | 7% rate, 30-year term, 25% down now visible in mortgage assumptions |
| 3. Conservative scenario shows negative cash flow | Critical | N/A (data, not model) | Model now correctly displays scenario spread. Variable costs scale properly. |
| 4. Revenue projections lack market data support | Critical | **PARTIALLY FIXED** | Evidence confidence is no longer static 30%. Still shows market occ 26% vs projected 79% without reconciliation. |
| 5. Break-even analysis shows thin margins | Major | **IMPROVED** | Natiivo now shows 63.8% break-even vs 78.9% projected — a 15pp cushion. Orlando and Brickell correctly show "Never." |
| 6. Monthly cash flow seasonality risk | Major | **UNCHANGED** | Monthly detail still present but no reserve draw-down modeling. Lower priority for screening. |
| 7. Operating expense ratio high | Major | **FIXED** | Management fee corrected to 18%. OpEx ratios now properly differentiated (47% Natiivo, 72% Orlando, 95% Brickell). |
| 8. Cash-on-Cash return below target | Major | **IMPROVED** | Now ranges from 12.1% (Natiivo base) to -20.7% (Brickell), with clear labeling. |
| 9. Risk assessment contradicts financial reality | Major | **FIXED** | Deal-breakers now surfaced. "No Significant Risks" only appears when justified. Orlando/Brickell correctly show deal-breakers. |
| 10. 5-year projection aggressive | Minor | **UNCHANGED** | Still uses 2% revenue growth, 3% appreciation. Acceptable for screening. |
| 11. HOA min-stay not reflected in financials | Minor | **FIXED** | Min-stay penalty now applies -5% to both occupancy and ADR for 3-night minimum. |
| 12. No loan product guidance | Suggestion | **UNCHANGED** | Still no guidance on DSCR vs conventional vs portfolio loan types. |
| 13. Erroneous expense ratio percentages | Suggestion | **FIXED** | Expense percentages now show correct values (e.g., management 18%, property tax 5% for Natiivo). |

**Score: 8 of 13 original findings addressed (4 fixed, 4 improved/partially fixed, 5 unchanged/not applicable)**

---

## Remaining Issues

### Issue 1: Miami STR Tax Rate Still Shows 12%, Not 14%
**Severity: Important**

The Sprint 2 CAP_REVIEW states that Miami tax rates were updated via Florida DOR and should now show >= 13% combined STR tax (AC-3 says PASS at 14%). However, both Miami reports (Natiivo and Brickell) still show `total_lodging_tax: 0.12` and `str_tax_rate: 0.12` in the JSON data. The tax breakdown shows `state_sales_tax: 0.06` and `tourist_development_tax: 0.06` but no `local_option_tax`.

**Impact**: At 12% instead of 14%, STR taxes are understated by approximately $180/month on Natiivo ($108K revenue) and $75/month on Brickell ($45K revenue). For Natiivo, this would reduce base NOI from $57,199 to approximately $55,039 and DSCR from 1.57x to approximately 1.51x. Not deal-breaking, but inaccurate.

**Action required**: Verify whether the 14% rate is applied at the simulation level but displayed differently in the JSON, or whether the tax lookup is not flowing through to report generation for these specific properties.

---

### Issue 2: NOI Gate Flag Is False on Properties with Failing NOI
**Severity: Important**

Both Orlando (NOI $13K vs. $37K debt service) and Brickell (NOI $2K vs. $66K debt service) show `noi_gate_failed: false` in their axis_scores. The profitability gate correctly catches these (revenue_potential: 10/100), but the NOI-specific gate should also be flagging. This creates a data inconsistency that could confuse downstream consumers of the JSON data.

The final verdict is correct (NO-GO), so this does not change the outcome, but the gate metadata should be consistent with the financial reality.

---

### Issue 3: Projected Occupancy vs. Market Occupancy Gap Still Unexplained
**Severity: Important**

Natiivo projects 78.9% base occupancy against a market average of 26%. Orlando projects 52.3% against 31%. Brickell projects 44.7% against 28%. While the model may have legitimate reasons for these projections (property-specific advantages, purpose-built STR designation, comparable STR data), the report does not reconcile the gap.

From a lending perspective, I would use the lower of projected or market-supported occupancy. A 3x gap (Natiivo: 79% projected vs 26% market) requires explicit justification. The comparable STR data in the report shows similar properties achieving 60-90% occupancy on platforms like AirDNA/AirROI, which supports the projections being reasonable for STR-active properties, but this reconciliation is not surfaced to the reader.

**Recommendation**: Add a "Projection Justification" callout when base-case occupancy exceeds market average by more than 50%, citing the comparable STR evidence that supports the higher figure.

---

### Issue 4: Operating Expenses Identical Across Months Within a Scenario
**Severity: Nice-to-have**

Monthly operating expenses are flat at $4,239/month for Natiivo across all 12 months ($2,826 for Orlando, $3,561 for Brickell). While variable costs correctly scale across scenarios (confirmed: Natiivo base $50,871 vs. optimistic $55,735 vs. conservative $44,580), within a single scenario they are treated as constant monthly amounts.

In reality, STR operating costs vary by month (higher cleaning/maintenance costs in peak season, lower in off-season). This is a refinement, not a blocker for screening — lenders evaluate annual figures for preliminary DSCR calculations.

---

### Issue 5: HOA Fees Show as $0 on All Three Properties
**Severity: Nice-to-have**

All three properties show `hoa_fees: 0.0` in the expense breakdown. Natiivo Miami is a luxury condo with HOA fees typically $800-1,500/month. Vista Cay is a resort community with HOA typically $300-600/month. Club at Brickell Bay likely has HOA of $600-1,200/month.

If HOA is being captured elsewhere (e.g., included in maintenance or a separate field), this needs clarification. If HOA is genuinely not being captured, this understates expenses by $3,600-$18,000/year and correspondingly overstates NOI and DSCR. For Natiivo, adding a $1,100/month HOA would reduce NOI from $57,199 to approximately $44,000 and DSCR from 1.57x to approximately 1.20x — a material change that would push the property from comfortably above to barely at the lending minimum.

**Note**: My Sprint 1 review of Natiivo showed HOA at $1,100/month ($13,200/year). If this data was available for that report, its absence now is a regression.

---

### Issue 6: Insurance Estimates Are Identical Across All Three Properties
**Severity: Nice-to-have**

All three properties show the same insurance estimates: HO6 at $1,875/year and liability at $800/year. A 1-bedroom condo in downtown Miami (Natiivo, $610K) and a 3-bedroom unit in Brickell ($1.1M) would not carry the same insurance premiums. Coverage should scale with property value, bedroom count, and location-specific risk factors (flood zone, coast distance).

---

## Scenario Analysis — Do the Assumptions Make Sense?

### ADR-Occupancy Elasticity
The optimistic and conservative scenarios now apply inverse ADR-OCC adjustments, which is consistent with market behavior. For Natiivo:
- Optimistic: ADR $413 (+10%), Occupancy 82.5% (-3.6pp from base)
- Conservative: ADR $338 (-10%), Occupancy 70.7% (-8.2pp from base)

The conservative scenario applies a larger occupancy penalty than the optimistic scenario gains, which is appropriately asymmetric. However, the conservative OCC drop of -8.2pp is larger than the stated -3% elasticity rule would suggest. This could mean additional penalties (min-stay, seasonality) are being stacked, which would be correct modeling behavior.

### Variable Cost Scaling
Confirmed working correctly. For Natiivo:
- Base expenses: $50,871 (47.1% of $108K revenue)
- Optimistic expenses: $55,735 (44.8% of $124K revenue)
- Conservative expenses: $44,580 (51.2% of $87K revenue)

Expenses move with revenue but at a lower ratio in the optimistic case and higher ratio in the conservative case, which reflects fixed costs becoming a larger share as revenue declines. This is exactly how it should work.

### Debt Service Fixed Across Scenarios
All three reports correctly hold debt service constant across scenarios ($36,525/year for Natiivo, $37,423 for Orlando, $65,865 for Brickell). Debt service does not change with occupancy or ADR — this is correct.

---

## Stress Test: Would I Use These for a Preliminary Screen?

**Yes, with caveats.** Here is my honest assessment by property:

**Natiivo**: I would advance this to full underwriting. The DSCR spread (1.16x-1.88x) tells me the deal works in base and optimistic cases but is marginal under stress. The break-even occupancy of 63.8% gives enough cushion. I would want to verify the HOA fee situation (Issue 5) before proceeding — if HOA is truly $0 the numbers hold; if it is $1,100/month this deal needs restructuring.

**Orlando**: I would decline immediately. The model correctly tells me this is unfundable at any scenario. DSCR of 0.36x means the property needs nearly 3x more income to service debt. No amount of operational optimization fixes this — it is a pricing problem.

**Brickell**: I would decline immediately. DSCR of 0.03x and negative conservative NOI make this the clearest auto-decline I could ask for. The model's confidence in this verdict (85%) is, if anything, too low — this should be 95%+.

**The model correctly differentiates these three outcomes.** That is the core competency I need for preliminary screening.

---

## Comparison to Sprint 1

| Dimension | Sprint 1 | Sprint 2 | Delta |
|-----------|----------|----------|-------|
| DSCR lending context | None — 1.11x labeled "Financing Feasible" | Threshold buckets with correct labels | Major improvement |
| Interest rate disclosure | Missing — had to back-calculate | 7%, 30-year, 25% down explicitly shown | Critical fix |
| Management fee | 20% (above market) | 18% (at market) | Correct |
| Variable cost scaling | Same expenses across all scenarios | Expenses proportional to revenue | Major improvement |
| Risk assessment | "No Significant Risks" on risky property | Deal-breakers surfaced, badges appropriate | Major improvement |
| Min-stay impact | Not modeled | -5% OCC, -5% ADR for 3-night minimum | New capability |
| Conservative scenario | Expenses same as base | Reduced variable costs, lower revenue | Realistic |
| Evidence confidence | Static 30% placeholder | Dynamic based on actual evidence | Fixed |

---

## Go/No-Go Recommendation

### GO — Proceed to Chat MVP

**Rationale**: The model now produces financial metrics that are directionally accurate and correctly differentiate deal quality. For preliminary screening — the stated use case — this is sufficient. A mortgage professional can look at these reports and make a defensible triage decision (advance, decline, or restructure).

**Conditions**:
1. The HOA fee issue (Issue 5) must be investigated. If HOA fees are genuinely missing from the model, this is a potential blocker — HOA fees are the single largest operating expense for Florida condos and their absence could flip a borderline deal from viable to non-viable.
2. The Miami STR tax discrepancy (Issue 1) should be verified. If the 14% rate is not flowing through to reports, it needs to be fixed before production.
3. The occupancy gap reconciliation (Issue 3) should be added before any user-facing launch to avoid credibility challenges from sophisticated users.

**What this model is ready for**: Screening-level triage. "Should I spend more time on this deal?"

**What this model is NOT ready for**: Formal underwriting, loan committee presentations, or any context where the numbers would be relied upon for a lending decision. That requires verified income data, actual operating statements, and third-party appraisals — none of which an automated model can provide.

---

## Findings Summary

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Miami STR tax shows 12% not 14% | Important | Open |
| 2 | NOI gate flag false on failing properties | Important | Open |
| 3 | Projected vs market occupancy gap unexplained | Important | Open |
| 4 | Monthly OpEx constant within scenario | Nice-to-have | Open |
| 5 | HOA fees $0 on all properties (potential regression) | Important | Investigate |
| 6 | Insurance identical across properties | Nice-to-have | Open |

| Severity | Count |
|----------|-------|
| Blocker | 0 |
| Important | 4 |
| Nice-to-have | 2 |
| **Total** | **6** |

---

*Review completed 2026-03-19 by Mortgage Manager persona. Prior review: `reviews/mortgage_manager_review.md` (Sprint 1). This review covers Sprint 2 model accuracy improvements across 3 test properties.*
