# Revalidation Review — 3900 Biscayne Blvd Unit S-304 (v2 report)

Report file: `reports/3900_Biscayne_Blvd_Unit_S-304_20260309_110643_v2.html`
Date: 2026-03-09

---

## 1. Expense ratio displayed as 6,424% instead of ~64%

**RESOLVED** — The report now shows the expense ratio correctly as ~70.7%.
> Evidence: AI narrative states "Operating expense ratio — Total OpEx % of Revenue is 70.7%." (line 2345). Bear case says "Operating expenses take about 71% of revenue" (line 418). No occurrence of "6,424%" anywhere in the report.

## 2. "No Significant Investment Risks" shown despite poor DSCR / CoC

**RESOLVED** — The phrase "No Significant Investment Risks" does not appear anywhere in the report. Instead, the report displays multiple red-flagged risk items.
> Evidence: Report shows "DSCR of 0.81x is below breakeven (1.0x) — income does not cover debt service" (line 3033) and "Negative cash-on-cash return (-4.0%)" (line 3037). DSCR tile reads "0.81x / Below Breakeven" (line 368) and CoC tile reads "-4.0%" (line 373).

## 3. Score weights not visible

**RESOLVED** — Score weight breakdown is now displayed beneath the investment score.
> Evidence: `<div ... title="Score = 25% Market + 25% Profit + 20% Regulatory + 15% Value + 15% Confidence">25% mkt · 25% profit<br>20% reg · 15% val · 15% conf</div>` (lines 348-349).

## 4. Cap rate missing from executive summary metrics grid

**RESOLVED** — Cap Rate now appears as a tile in the executive summary metrics grid.
> Evidence: Tile reads "Cap Rate / 4.9% / NOI / Price" (lines 377-379), positioned in the `grid-cols-2 md:grid-cols-5` layout alongside List Price, DSCR, and CoC.

## 5. Low data confidence banner when market/seasonality confidence < 20

**RESOLVED** — A prominent amber warning banner is displayed when confidence is low.
> Evidence: Banner reads "Low Data Confidence — Market data confidence: 0/100 | Seasonality confidence: 0/100. Revenue projections may be unreliable — verify with local market data before investing." (lines 387-391). Additionally, a red risk flag reiterates: "Market and/or seasonality data confidence is 0/100 — revenue projections are unreliable" (line 3041).

## 6. Interest rate and loan terms missing from Deal Structure

**STILL PRESENT** — The Deal Structure "Financing & Returns" column (lines 2858-2890) shows mortgage amount ($404,250), monthly payment ($2,689/mo), DSCR, CoC, and cash flow, but does NOT display the interest rate or loan term (e.g., "7.0% / 30-year fixed"). The user cannot verify the assumptions behind the monthly payment figure.
> Evidence: No line in the Deal Structure section contains "interest", "rate", "loan term", "30-year", or "fixed". The closest is "Down Payment (25.0%)" and "Mortgage (75.0%)" which show LTV but not rate/term.

## 7. AI narrative quality and data transparency

**RESOLVED** — The AI narrative is high quality: clear, actionable, and transparent about data limitations.
> Evidence: Executive summary narrative (lines 402-430) provides a direct verdict ("This deal does not work as an STR investment"), structured bull/bear cases with specific numbers (71% expense ratio, 82% breakeven occupancy), and actionable advice ("Target buildings with HOA fees under $1,000"). The Risks & Confidence tab (lines 2984-3001) transparently discloses "Market Data Confidence is 0/100 and Seasonality Confidence is 0/100" and lists specific areas needing due diligence.

---

## Summary

| # | Issue | Status |
|---|-------|--------|
| 1 | Expense ratio 6,424% bug | RESOLVED |
| 2 | "No Significant Risks" despite poor metrics | RESOLVED |
| 3 | Score weights not visible | RESOLVED |
| 4 | Cap rate missing from exec summary | RESOLVED |
| 5 | Low data confidence banner | RESOLVED |
| 6 | Interest rate & loan terms in Deal Structure | STILL PRESENT |
| 7 | AI narrative quality & transparency | RESOLVED |

**6 of 7 issues resolved. 1 remaining: interest rate and loan term need to be added to the Deal Structure section.**
