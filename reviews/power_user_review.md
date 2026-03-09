# Power User Persona Review: investFlorida.ai Report

**Persona**: AI-Savvy Power User / Product Stress-Tester
**Report**: 159 NE 6th St #4307, Miami, FL 33132 (v2, generated 2026-03-09)
**Review Date**: 2026-03-09

---

## Executive Assessment

The report delivers an impressive breadth of analysis — location scoring, event-driven revenue modeling, scenario ranges, and compliance checks. However, several critical data integrity issues undermine the AI-generated insights, and contradictory signals across sections erode trust for a user who reads carefully. The product is visually polished but needs tighter data hygiene before it can be treated as decision-grade.

---

## Findings

### 1. Garbled Expense Ratios Fed to AI — Hallucinated Percentages in Cash Flow Tab

**Severity: Critical**

The AI-generated Cash Flow insights contain wildly incorrect percentage figures that appear to come from broken data passed to the LLM:

> "The operating expense status is flagged as VERY_HIGH, and total OpEx is listed as 6,424.1% of revenue"
> "HOA is 1,160.1% of revenue"
> "property tax 991.8%; management 2,000.0%; STR tax 1,200.0%"

The actual math is straightforward: $73,094 / $113,781 = ~64% OpEx ratio. The AI itself correctly computes this ("OpEx ratio ≈ $73,094 / $113,781 ≈ 64% of revenue") but then _also_ reports the garbled numbers it was fed, creating a confusing contradiction within the same paragraph.

**Expected**: The LLM context should contain correctly computed ratios. If the data pipeline passes monthly costs as percentage-of-monthly-revenue (e.g., $1,100 HOA / ~$9,482 monthly revenue ≈ 11.6%), there's likely a units/scaling bug producing the 1,160% figure (off by 100x).

**Impact**: A power user who reads the AI narrative loses trust in the entire analysis. A less careful user might take the "6,424% OpEx" at face value and make wrong decisions.

---

### 2. Contradictory Risk Assessment: "LOW RISK" vs. Multiple 0/100 Confidence Scores

**Severity: Critical**

The Risk & Confidence tab simultaneously presents:

- **Risk badge**: "LOW RISK — 0 critical · 0 manageable"
- **Green banner**: "No Significant Investment Risks Detected"

But the _same tab's_ AI narrative says:
> "Market Data Confidence: 0/100, Seasonality Confidence: 0/100, and STR Listing Detection Confidence: 0/100 are major gaps"
> "treat this as a directional analysis, not definitive—maybe 6–7/10 reliability"

Meanwhile, the executive verdict is "CAUTION" with a 66/100 score. These three signals are irreconcilable.

**Expected**: The structured risk assessment (the "LOW RISK" badge) should reflect the same data the AI narrative analyzes. If multiple confidence dimensions are 0/100, "No Significant Investment Risks Detected" is misleading.

---

### 3. Market Data Confidence: 0/100 Undermines 82/100 Market Score

**Severity: Major**

The Market & Location tab scores 82/100, but the AI narrative within that same tab reveals:

> "Market Data Confidence: 0/100"
> "Only 2 Comparable Properties"
> "Guest Demand Score: 38/100 (Grade F)"
> "Market Occupancy Rate: 26%"

A 26% market occupancy rate vs. the 80% base projection for this property is a massive gap. The report projects this unit as a 3x outperformer of its market, but never explicitly calls out or justifies this divergence.

**Expected**: When market confidence is 0/100, the Market score should be penalized, or a prominent caveat should appear. The gap between 26% market occupancy and 80% projected occupancy deserves a dedicated explanation, not just an AI side-mention.

---

### 4. Evidence Artifacts All Show "30% conf" — Likely Placeholder

**Severity: Major**

All four evidence artifacts in the Compliance tab show identical "30% conf" values:
- vacation_rental_licenses: 30% conf
- web_research: 30% conf
- building_discovery: 30% conf
- str_activity: 30% conf

This uniformity suggests a default/fallback value rather than genuine confidence scoring. Additionally, web_research shows contradictory evidence: `"web_research allows STR (conf: 65%); web_research restricts STR (conf: 65%)"` — identical confidence for opposing conclusions.

**Expected**: Confidence scores should vary by source quality. If the system can't compute real confidence, display "unscored" rather than a misleading uniform number.

---

### 5. Scenario Modeling: Expenses Frozen Across All Scenarios

**Severity: Major**

The scenario comparison table shows expenses at exactly $73,094 across Conservative, Base, Optimistic, and Market Average scenarios. In reality:
- Lower occupancy (conservative) would reduce variable costs like management fees, cleaning, and STR taxes
- Higher occupancy (optimistic) would increase these variable costs

The report's own cost breakdown classifies $3,034/mo as variable. Yet scenarios don't adjust them.

**Expected**: Variable costs should scale with occupancy. A conservative scenario with 73% occupancy should have ~9% lower variable costs than the 80% base. This would narrow the cash flow spread and make the conservative scenario less dire (and the optimistic less rosy).

---

### 6. Score Calculation Weighting is Opaque

**Severity: Major**

The score breakdown shows:
- Market & Location: 82/100
- Revenue Forecast: 57/100
- Costs & Cash Flow: 56/100
- Price Analysis: 50/100

These yield a final score of 66/100, but the weighting formula is not disclosed. A simple average of 82+57+56+50 = 61.25. The displayed 66 implies non-equal weights, but the user cannot verify or understand the methodology.

**Expected**: Show the weights explicitly (e.g., "Market 30%, Revenue 25%, Costs 25%, Price 20%") so users can assess whether they agree with the emphasis.

---

### 7. 5-Year Projection Uses Fixed Growth Assumptions Without Sensitivity

**Severity: Minor**

The 5-year table assumes:
- 2.0% revenue growth
- 2.5% expense inflation
- 3.0% property appreciation

These produce attractive summary numbers ($31,691 total cash flow, 15.1% annualized return, 2.02x multiple). But no sensitivity analysis shows what happens if appreciation is 0% (flat market) or expenses grow at 4% (inflation spike). Given that Year 0 cash flow is only $4,162, small assumption changes could flip cumulative returns negative.

**Expected**: At minimum, show a pessimistic growth scenario (e.g., 0% revenue growth, 3.5% expense inflation, 0% appreciation) alongside the base projection.

---

### 8. Conservative/Optimistic Scenarios Use Symmetric ±10% Adjustments

**Severity: Minor**

Conservative: -10% ADR, -10% OCC. Optimistic: +10% ADR, +5% OCC. These appear to be static multipliers rather than market-derived probability bands.

**Expected**: Scenarios should ideally be derived from comparable property variance (the report has 49 comps with ADR from $257-$515 and OCC from 53%-93%). Using actual percentile bands (e.g., P25/P75) would be more credible than arbitrary ±10%.

---

### 9. STR vs. LTR Comparison Absent

**Severity: Minor**

The Revenue tab has a placeholder for "STR vs LTR Quick Verdict" but it renders nothing. For a $610K 1BR condo in downtown Miami, the LTR alternative is a critical benchmark. An investor wants to know: if STR underperforms, can I pivot to long-term rental and still cover costs?

**Expected**: Show estimated LTR monthly rent, LTR cash flow, and the STR premium multiple.

---

### 10. Inconsistent Comparable Count: "2" vs. "49"

**Severity: Minor**

The AI narrative in Market tab states "Only 2 Comparable Properties" but also references "Comparables Count: 49." The comp distribution chart shows "49 comps." This inconsistency is confusing.

**Expected**: Clarify the distinction (e.g., "2 direct building comps, 49 area comps within 3 mi") so the user understands data depth at each level.

---

### 11. Cost Rigidity Insight Contradicts Its Own Data

**Severity: Suggestion**

The Cost Rigidity Insight states:
> "50.0% of costs are fixed or volatile, providing reasonable flexibility to scale down if needed."

This is backwards. If 50% of costs are fixed/volatile (i.e., not reducible), that means limited flexibility, not "reasonable flexibility." The phrasing optimistically spins a concerning metric.

**Expected**: Reframe as: "50% of costs are fixed — in a downturn, you can only reduce half your cost base."

---

### 12. Monthly Profitability Shows 8 Months of Negative Cash Flow

**Severity: Suggestion**

The profitability chart data reveals negative net cash flow in 8 of 12 months (May through Nov), with positive months only in Apr, Dec, Feb, and Mar. The cumulative line goes as deep as -$5,771. This J-curve pattern is important but not explicitly called out — the report leads with the annual positive cash flow of $4,162.

**Expected**: Add a callout: "Cash flow is negative 8 of 12 months — you'll need reserves to ride through the off-season. Peak season (Dec-Mar) generates all annual profit."

---

## Summary Table

| # | Finding | Severity |
|---|---------|----------|
| 1 | Garbled expense ratios in AI Cash Flow narrative | Critical |
| 2 | "LOW RISK" contradicts 0/100 confidence scores and CAUTION verdict | Critical |
| 3 | Market score 82/100 despite Market Data Confidence 0/100 | Major |
| 4 | All evidence artifacts show identical 30% confidence (placeholder) | Major |
| 5 | Variable expenses not adjusted across scenarios | Major |
| 6 | Score weighting formula not disclosed | Major |
| 7 | 5-year projection lacks pessimistic growth scenario | Minor |
| 8 | Scenarios use arbitrary ±10% instead of comp-derived bands | Minor |
| 9 | STR vs LTR comparison missing (placeholder only) | Minor |
| 10 | Inconsistent comp count (2 vs 49) without explanation | Minor |
| 11 | Cost rigidity insight spins 50% fixed costs as "flexible" | Suggestion |
| 12 | 8/12 months negative cash flow not prominently disclosed | Suggestion |

**Critical**: 2 | **Major**: 4 | **Minor**: 4 | **Suggestion**: 2

---

## Bottom Line

As a power user, I'd describe this report as "impressive scaffolding with data plumbing leaks." The architecture is strong — the 6-tab model, event-driven revenue, score breakdown, and scenario ranges demonstrate serious product thinking. But the two Critical findings (garbled LLM inputs, contradictory risk assessment) would make me question _all_ the AI-generated text across the report. Fix the data pipeline feeding the LLM, reconcile the structured risk assessment with the narrative, and this becomes a genuinely trustworthy tool.
