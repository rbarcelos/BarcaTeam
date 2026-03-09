# Mortgage/Lending Professional Review

**Persona**: Mortgage Manager / Lending Underwriter
**Report Reviewed**: `159_NE_6th_St_4307_Miami_FL_20260309_040517_v2.html`
**Property**: 159 NE 6th St #4307, Miami, FL 33132
**Date**: 2026-03-09

---

## Executive Assessment

From a lending perspective, this report presents a property that would be **difficult to underwrite** for an investment property mortgage. The DSCR is dangerously thin, income projections rely on optimistic assumptions unsupported by market data, and several critical underwriting inputs are either missing or inadequately disclosed. A loan officer reviewing this report would flag multiple items before proceeding.

---

## Findings

### 1. DSCR Is Below Conventional Lending Thresholds

**Severity: Critical**

The report shows a DSCR of **1.11x** (line 542, 902-903), labeled as "Financing Feasible" with an amber warning of "tight margins, sensitive to rate changes." Most DSCR loan programs for investment properties require a **minimum 1.20x-1.25x DSCR**. At 1.11x, this property would **fail to qualify** for the majority of non-QM DSCR loan products available today.

> Report states: `"DSCR 1.11 - tight margins, sensitive to rate changes"` (line 542)

**What I'd expect**: The report should explicitly state that 1.11x DSCR falls below typical lender minimums (1.20x-1.25x). The "Financing Feasible" label with an amber indicator is misleading — this should be flagged as **Financing At Risk** or **Below Lender Minimum**. The report should also model what purchase price or down payment would be needed to achieve a 1.25x DSCR.

---

### 2. Interest Rate and Loan Terms Are Not Disclosed

**Severity: Critical**

The report shows a mortgage of $457,500 (75% LTV) with a monthly payment of $3,044/mo ($36,525/yr annual debt service), but **nowhere does it disclose the assumed interest rate, loan term, or amortization schedule**. These are the most fundamental inputs for any financing analysis.

> Report shows: `Mortgage (75.0%) → $457,500`, `Monthly Payment → $3,044/mo` (lines 2894-2899)

Back-calculating: $3,044/mo on a $457,500 loan implies roughly a **7.0% rate on a 30-year fixed**, which is a reasonable current-market assumption, but it should be explicitly stated and stress-tested.

**What I'd expect**: Clear disclosure of assumed interest rate, loan term, amortization type, and whether this is a conventional, DSCR, or portfolio loan assumption. A rate sensitivity table showing DSCR and cash flow at +50bps and +100bps rate increases is standard practice.

---

### 3. Conservative Scenario Shows Deep Negative Cash Flow

**Severity: Critical**

The scenario matrix (lines 1907-1962) reveals that:
- **Conservative scenario**: Cash flow = **-$17,096/yr** (NOI $19,429 vs. debt service $36,525)
- **Market Average scenario**: Cash flow = **-$12,088/yr** (NOI $24,437 vs. debt service $36,525)
- Only the **Base** and **Optimistic** scenarios produce positive cash flow

This means under market-average conditions (ADR $354, Occ 75%), the borrower would need to **subsidize the property by $1,007/month out of pocket**. This is a severe underwriting concern.

> Report states conservative cash flow: `$-17,096` and market average: `$-12,088` (lines 1957, 1960)

**What I'd expect**: The report should prominently warn that the property is cash-flow negative under market-average conditions. The "Base" scenario ($388 ADR, 80% occupancy) that produces the thin positive result must be justified against actual comparable performance data — which the report itself admits is weak (Market Data Confidence: 0/100).

---

### 4. Revenue Projections Lack Market Data Support

**Severity: Critical**

The report's own Risk & Confidence section (lines 2982-3002) reveals devastating gaps:
- **Market Data Confidence: 0/100**
- **Seasonality Confidence: 0/100**
- **STR Listing Detection Confidence: 0/100**
- **Market Occupancy Rate: 26%** vs. the projected **80% base occupancy**
- **Guest Demand Score: 38/100 (Grade F)**
- Only **2 Comparable Properties** in the core comp set

> Report states: `"Market performance and seasonality are essentially unknown (both 0/100)"` (line 2991)
> Report states: `"Very low Market Occupancy Rate: 26%"` (line 1105)

The base case assumes 80% occupancy when the market average is 26%. Even accounting for property-specific premiums, this is a 3x gap that no lender would accept without extensive justification.

**What I'd expect**: A lender would use the **lower of** the property's projected performance or market-supported performance for underwriting. The report should reconcile why this property would achieve 80% occupancy in a market averaging 26%, with verifiable comparable STR data. Without this, the income projections are effectively unsubstantiated.

---

### 5. Break-Even Analysis Shows Dangerously Thin Margins

**Severity: Major**

Break-even occupancy is 77% with only a **+3.0 percentage point cushion** above break-even (lines 1976-1980). Break-even ADR is $374 with only a **+4.0% cushion** (lines 1983-1986). The report labels this as "Tight."

> Report states: `Break-even occupancy: 77.0% (+3.0pp cushion)` (lines 1977-1979)

**What I'd expect**: Most lenders want at least a 15-20% cushion between projected and break-even occupancy. A 3pp cushion means a single bad month could push the property into negative territory. The monthly profitability data confirms this — the property is cash-flow negative for **7 out of 12 months** (Apr-Nov shows cumulative net declining from +$646 to -$5,771 before the winter season rescues it). This extreme seasonality concentration is a significant risk.

---

### 6. Monthly Cash Flow Seasonality Creates Debt Service Risk

**Severity: Major**

The monthly profitability data (line 3057) shows net monthly cash flows of:
- Apr: +$646, May: -$532, Jun: -$832, Jul: -$354, Aug: -$1,394, Sep: -$2,035, Oct: -$535, Nov: -$735
- Dec: +$2,738, Jan: +$1,712, Feb: +$1,280, Mar: +$4,203

The property is **negative for 7 consecutive months** (May through November), requiring the borrower to cover shortfalls of approximately $6,417 during that period. The entire year's profit depends on a strong Dec-Mar season.

**What I'd expect**: A lender would require evidence of sufficient reserves to cover the negative cash flow months. The report does mention a 6-month cash reserve of $54,809 (line 2876), which is adequate, but this should be called out as a **mandatory requirement**, not optional. The reserve draw-down schedule should be modeled explicitly.

---

### 7. Operating Expense Ratio Is Extremely High

**Severity: Major**

Total annual operating expenses are $73,094 against projected revenue of $113,781, yielding an **operating expense ratio of ~64%**. The report's own AI analysis flags this:

> `"Operating costs consume roughly 64% of revenue, with management alone taking 20% and HOA about $1,100 per month."` (line 406)

Key cost drivers:
- HOA: $1,100/mo ($13,200/yr — 11.6% of revenue)
- Property Tax: $940/mo ($11,280/yr — 9.9% of revenue)
- Management Fee: $1,896/mo ($22,752/yr — 20% of revenue)
- STR/Tourist Tax: $1,138/mo ($13,656/yr — 12% of revenue)

**What I'd expect**: A 64% expense ratio leaves very thin margins for debt service. Lenders typically want to see 40-50% expense ratios on STR properties. The report should stress-test what happens if HOA fees increase (which is common in new construction condos) or if management costs rise.

---

### 8. Cash-on-Cash Return Is Far Below Market Expectations

**Severity: Major**

Cash-on-Cash return is **2.4%** with total cash needed of **$240,859** (lines 2907-2908, 2880). The report itself notes the target is 8%+.

> Report shows: `Cash-on-Cash Return: 2.4%` with note `Target 8%+` (lines 379-382)

**What I'd expect**: A 2.4% CoC return does not justify the risk of an STR investment property. A borrower earning 2.4% on $240K invested has significant opportunity cost. This should be more prominently flagged as a deal-breaker for most investors, not just shown in a small metric box.

---

### 9. Risk Assessment Contradicts Financial Reality

**Severity: Major**

The Risk Assessment section (lines 3016-3038) displays:

> `"LOW RISK"` with `"0 critical, 0 manageable"` risks and `"No Significant Investment Risks Detected"`

This directly contradicts:
- The CAUTION verdict in the Executive Summary
- The 1.11x DSCR (below lending minimums)
- Negative cash flow in 7 of 12 months
- 0/100 market data confidence
- 26% market occupancy vs 80% projected
- 2.4% CoC vs 8% target
- Conservative scenario showing -$17K annual loss

**What I'd expect**: The risk section should surface financial risks, not just regulatory/market risks. From a lending perspective, this property has multiple critical financial risks that should be enumerated. The "No Significant Investment Risks Detected" label is misleading and could expose the platform to liability.

---

### 10. 5-Year Projection Assumptions Are Aggressive

**Severity: Minor**

The 5-year projection (lines 2746-2749) assumes:
- 2.0% annual revenue growth
- 2.5% annual expense inflation
- 3.0% annual property appreciation

Revenue growing faster than expenses (net margin expansion) is optimistic for a new construction condo where HOA special assessments are common in years 3-5. The 3% appreciation assumption on a $1,208/sqft condo in downtown Miami may not be conservative enough given current market conditions.

**What I'd expect**: A stress-test scenario with 0% revenue growth and 3-4% expense inflation (reflecting typical HOA increases in new buildings). The 5-year projection should also model a refinance scenario and an exit/sale scenario with transaction costs.

---

### 11. HOA Compliance Conflict Not Addressed in Financing Context

**Severity: Minor**

The report notes a compliance conflict: "Building allows STR but HOA 3-night minimum" (line 348). From a lending perspective, this restriction could reduce bookable nights and revenue, as 1-2 night stays are a significant portion of urban STR demand.

**What I'd expect**: The revenue model should explicitly state whether it accounts for the 3-night minimum restriction. The impact on ADR and occupancy from eliminating short stays should be quantified.

---

### 12. No Loan Product Guidance or Qualification Analysis

**Severity: Suggestion**

The report provides no guidance on what type of financing this property would qualify for. Given it's an STR-designated condo, conventional Fannie/Freddie loans may not be available. DSCR loans, portfolio loans, or commercial loans may be required — each with different rate, term, and qualification implications.

**What I'd expect**: A financing section that outlines likely loan products available, typical rate ranges for STR/investment condo financing, and whether the condo project itself is warrantable (important for conventional financing). The Natiivo building's STR-by-design status may make it non-warrantable for conventional lending.

---

### 13. Expense Ratio Percentages Appear Erroneous

**Severity: Suggestion**

The AI Economics analysis (line 2379) states expense ratios that appear to be data errors:

> `"HOA 1,160.1%; property tax 991.8%; management 2,000.0%; STR tax 1,200.0%"`

These percentages are clearly wrong (HOA of $13,200 is 11.6% of $113,781 revenue, not 1,160%). This appears to be a calculation bug in the AI analysis layer.

**What I'd expect**: These erroneous percentages should be fixed. They undermine confidence in the entire financial analysis. If a borrower or lender sees "1,160% of revenue" for HOA, they will immediately question all other calculations.

---

## Summary for Lending Decision

| Metric | Report Value | Lender Minimum | Status |
|--------|-------------|----------------|--------|
| DSCR | 1.11x | 1.20-1.25x | FAIL |
| LTV | 75% | 75-80% | PASS |
| Cash-on-Cash | 2.4% | 5-8% | FAIL |
| Break-even Cushion | 3pp | 15-20pp | FAIL |
| Expense Ratio | 64% | 40-50% | FAIL |
| Market Data Support | 0/100 | N/A | FAIL |
| Cash Reserves | 6 months | 6 months | PASS |
| Interest Rate Disclosed | No | Required | FAIL |

**Lending Recommendation**: DECLINE or require significant restructuring (larger down payment to achieve 1.25x DSCR, verified comparable income data, interest rate lock confirmation).

---

## Findings Count

| Severity | Count |
|----------|-------|
| Critical | 4 |
| Major | 5 |
| Minor | 2 |
| Suggestion | 2 |
| **Total** | **13** |
