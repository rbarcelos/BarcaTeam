# STR Operator & Property Manager Review

**Persona**: Experienced Short-Term Rental Operator / Property Manager
**Report Reviewed**: 159 NE 6th St #4307, Miami, FL 33132 (v2 report, generated 2026-03-09)
**Property**: 1BD/1BA, 505 sqft condo in Natiivo (purpose-built STR building), listed at $610,000

---

## Finding 1: Occupancy Assumption is Aggressive for a 1BD/505sqft Unit with 3-Night Minimum

**Severity: Critical**

The report models a **base-case occupancy of 80%** for this unit, while the market data it cites shows:
- Market Occupancy Rate: **26%**
- Guest Demand Score: **38/100 (Grade F)**
- Market average from comps source (airroi): **75.4%**

> "Realistically, expect ~$105K-$115K/year, centered on the $113,781 base case, assuming ADR of ~$388 and ~80% occupancy. This is well above local market averages (~$237 ADR, 26% occupancy), so your unit is modeled as a top performer."

As an operator, modeling a unit at **80% occupancy** while acknowledging the market average is **26%** is a massive disconnect. Even accounting for the "STR Building Boost" (+5% OCC) and event adjustments (+2.6% avg), jumping from a 75.4% comp average to 80% for a **505 sqft 1-bedroom with a 3-night minimum stay** is not realistic in my experience. The 3-night minimum kills weekend warrior bookings (Fri-Sun 2-nighters) which are the bread and butter of urban STR occupancy.

**What I'd expect**: Base-case occupancy of **68-73%** for a 1BD in downtown Miami with a 3-night minimum. The break-even is at 77% -- meaning the base case should probably already be below break-even when realistically modeled.

---

## Finding 2: Missing Cleaning Costs -- A Major Operational Line Item

**Severity: Critical**

The operating expense breakdown lists:
- Fixed: HOA ($1,100), Property Tax ($940), HO6 Insurance ($148), Liability ($67)
- Variable: Management Fee ($1,896), STR/Tourist Tax ($1,138)
- Volatile: Utilities ($293), Maintenance ($508)
- **Total OpEx: $6,091/mo**

**Cleaning/turnover costs are entirely absent.** At 80% occupancy with a 3-night average stay, you'd have roughly **8-9 turnovers per month**. At $100-$150 per clean for a 1BD (standard Miami rate), that's **$800-$1,350/month** missing from the model. Even if some of this is passed to guests via cleaning fees, the net cost after platform commission on those fees still represents $400-$700/month of real operator expense.

This omission alone could turn the $347/mo positive cash flow into a **$50-$1,000/month loss**.

**What I'd expect**: A dedicated "Cleaning / Turnover" line item under Variable Costs at $800-$1,200/month, with a note about whether guest-paid cleaning fees offset this.

---

## Finding 3: ADR of $388 is Optimistic for Sustained 80% Occupancy

**Severity: Major**

The comp scatter plot shows 49 nearby STR comps ranging from $257-$515 ADR. Critically, the data shows a clear **inverse relationship between ADR and occupancy** across comps:
- Comps at $257-$299 ADR achieve **79-93% occupancy**
- Comps at $365-$394 ADR achieve **65-90% occupancy** (wide variance)
- Comps at $450-$515 ADR achieve **53-74% occupancy**

The report assumes **both** a top-quartile ADR ($388, ~51st percentile position on the ADR range) **and** top-quartile occupancy (80%). In reality, you can have one or the other, not both simultaneously at steady state.

> "ADR looks closer to proven comp levels than the very strong occupancy does."

The report itself admits this but then still uses 80% as the base case.

**What I'd expect**: Either model $388 ADR at ~72-75% occupancy, or model 80% occupancy at ~$340-$360 ADR. Running both at their upper bounds is an operator trap.

---

## Finding 4: Expense Ratio Bug -- "6,424.1% of Revenue" and "HOA 1,160.1%"

**Severity: Critical**

The Costs & Cash Flow AI analysis contains clearly broken calculations:

> "The operating expense status is flagged as VERY_HIGH, and total OpEx is listed as 6,424.1% of revenue, indicating serious structural or data issues."
> "HOA is 1,160.1% of revenue. This is massively excessive"
> "the extreme ratios (HOA 1,160.1%; property tax 991.8%; management 2,000.0%; STR tax 1,200.0%)"

These percentages are mathematically impossible given the actual numbers ($73,094 expenses on $113,781 revenue = 64%). This appears to be a **data bug** where the AI was fed monthly costs as percentages of some other base (perhaps monthly vs annual mismatch, or costs expressed in basis points). The AI then faithfully reported these nonsensical numbers alongside the correct absolute dollar figures.

This destroys credibility for any operator reading the Costs & Cash Flow tab, even though the absolute dollar figures appear correct.

**What I'd expect**: Correct percentage calculations: HOA ~12% of revenue, Management ~20%, Property Tax ~10%, etc. The AI narrative should be consistent with the actual math.

---

## Finding 5: Management Fee at 20% is High and Not Contextualized

**Severity: Major**

The report models management at **$1,896/mo (20% of revenue)** and acknowledges this in the executive summary:

> "Operating costs consume roughly 64% of revenue, with management alone taking 20%"
> "Explore self-management or a lower-fee operator to cut the 20% management cost."

While 20% is within range for full-service STR management in Miami, it's the **high end**. Many operators in purpose-built STR buildings like Natiivo charge 15-18% because the building infrastructure (concierge, cleaning coordination, key exchange) reduces management overhead. The report doesn't model alternative management scenarios (self-managed at 0%, hybrid at 10%, or competitive market rate at 15%).

Given that the deal barely cash-flows, the difference between 20% and 15% management ($1,896 vs $1,422/mo = **$474/mo or $5,688/yr**) would more than double the annual cash flow from $4,162 to ~$9,850.

**What I'd expect**: At minimum, a sensitivity table showing cash flow at 15%, 20%, and self-managed rates. For a purpose-built STR building, 15-18% should be the base assumption.

---

## Finding 6: No Furnishing/Setup CapEx Amortization in Year 0-1

**Severity: Minor**

The deal structure correctly identifies $15,250 for initial furnishing (2.5% of purchase price). However:

1. For a 505 sqft 1BD in a premium downtown Miami building, $15,250 is on the low side. Guests at $388/night expect quality furnishings, linens, kitchenware, smart home tech, etc. Realistic budget is $18,000-$25,000.
2. Furniture refresh/replacement is not modeled in the 5-year projection. STR furniture takes heavy wear -- expect $3,000-$5,000/year in replacement items starting Year 2.

**What I'd expect**: Furnishing estimate of $20K-$25K for a luxury-positioned 1BD, with $3K-$5K annual CapEx reserve for replacements starting Year 2.

---

## Finding 7: Contradictory Risk Assessment

**Severity: Major**

The Risk & Confidence tab simultaneously states:
- Market Data Confidence: **0/100**
- Seasonality Confidence: **0/100**
- STR Listing Detection Confidence: **0/100**
- Only **2 core comparable properties**

Yet the risk assessment section displays:

> "No Significant Investment Risks Detected"
> "No major financial, regulatory, or market red flags were identified"

This is contradictory and dangerous for an operator. Having **zero confidence** in market data and seasonality while declaring "no significant risks" is irresponsible. An operator relying on this would not understand that the revenue projections are built on extremely thin data.

**What I'd expect**: Clear risk flags for: (1) insufficient market data, (2) unvalidated seasonality assumptions, (3) only 2 core comps underpinning the entire revenue model.

---

## Finding 8: 3-Night Minimum Impact Underestimated

**Severity: Major**

The compliance section correctly identifies the HOA-imposed 3-night minimum stay, but the revenue model doesn't adequately account for its operational impact:

> "The 3-night minimum stay means you must price and market around longer bookings, which can lower turnover costs but limits ultra-short, high-rate stays."

In practice, a 3-night minimum in a 1BD downtown Miami condo:
- Eliminates the highest-RevPAR segment (weekend 2-nighters at premium rates)
- Reduces occupancy by 5-10pp vs unrestricted minimums because 3-night blocks leave more gap nights
- Requires significantly different pricing strategy (midweek discounts to fill Sun-Wed)
- The "Min Stay: 1 night (default)" shown in the Revenue Starting Point suggests the comp data was collected from **unrestricted** listings, meaning the entire baseline is inflated

**What I'd expect**: A dedicated adjustment factor reducing baseline occupancy by 5-8pp and ADR by 3-5% to account for the 3-night minimum constraint. The comp baseline should explicitly note whether comps had similar restrictions.

---

## Finding 9: Seasonality Model Looks Reasonable but Lacks Off-Season Strategy

**Severity: Suggestion**

The monthly seasonality data shows:
- Peak: Mar-27 at $477 ADR / 90.6% OCC
- Trough: Sep-26 at $323 ADR / 73.0% OCC

This seasonal pattern is directionally correct for Miami. However, for a 1BD at $388 avg ADR, the September trough at $323/night and 73% occupancy means monthly revenue of ~$7,074 against ~$9,135 in monthly costs (OpEx + debt service). **September is cash-flow negative by ~$2,000.**

The report mentions dynamic pricing in the optimization section but doesn't model the cash reserve needed to survive 3-4 negative months (Aug-Oct roughly).

**What I'd expect**: A monthly cash flow table (which appears to exist in the data but wasn't surfaced clearly) with explicit callouts of which months are cash-flow negative and the cumulative trough.

---

## Finding 10: 5-Year Projection Assumptions are Mechanistic

**Severity: Minor**

The 5-year outlook uses:
- 2.0% revenue growth
- 2.5% expense inflation
- 3.0% property appreciation

These are generic assumptions that don't account for:
- Miami STR supply growth (new buildings coming online that compete directly)
- Potential regulatory changes (Miami STR regulation is evolving)
- HOA special assessments (common in newer condo buildings as reserves build)
- The fact that Natiivo is brand new (2024-built) and the market may not have fully absorbed its supply yet

**What I'd expect**: A note that these are placeholder growth rates and that the Miami STR market has specific supply-side risks from new purpose-built STR buildings in the pipeline.

---

## Summary Assessment

| # | Finding | Severity |
|---|---------|----------|
| 1 | 80% occupancy assumption unrealistic with 3-night min & market at 26% | Critical |
| 2 | Cleaning/turnover costs completely missing from OpEx | Critical |
| 3 | ADR and occupancy both modeled at top-quartile simultaneously | Major |
| 4 | Expense ratio percentages are broken (6,424% of revenue) | Critical |
| 5 | 20% management fee not contextualized for purpose-built STR | Major |
| 6 | Furnishing budget low, no CapEx reserve in projections | Minor |
| 7 | "No risks detected" contradicts 0/100 market data confidence | Major |
| 8 | 3-night minimum impact on revenue not properly modeled | Major |
| 9 | Off-season cash-flow negative months not highlighted | Suggestion |
| 10 | 5-year projections use generic growth rates | Minor |

**Bottom Line**: As an STR operator, I would **not** rely on this report to make a purchase decision. The three Critical findings (missing cleaning costs, broken expense ratios, and aggressive occupancy assumption) mean the true cash flow is likely **negative** at asking price. The report's verdict of "CAUTION" is directionally correct, but the actual situation is worse than presented. An operator would need to re-run the numbers with realistic occupancy (70-73%), include cleaning costs ($800-1,200/mo), and verify whether 15% management is achievable before this deal could work.
