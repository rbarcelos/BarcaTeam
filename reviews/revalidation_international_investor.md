# Revalidation: International Investor Persona

**Report:** `3900_Biscayne_Blvd_Unit_S-304_20260309_110643_v2.html`
**Date:** 2026-03-09

---

## Issue-by-Issue Revalidation

### 1. Score weights hidden — should show weight breakdown under the score

**RESOLVED**

Evidence: Below the score box (line 348-349), the report now displays:
`25% mkt · 25% profit · 20% reg · 15% val · 15% conf`
Additionally, a "How is this score calculated?" collapsible (line 600-660) shows the full breakdown with Base Fundamentals, Risk Profile multiplier, Hard Gates, and final calculation formula (`54/100 x 1.0 = 53/100`).

---

### 2. Interest rate and loan terms missing from Deal Structure

**STILL PRESENT**

Evidence: The "Deal Structure > Financing & Returns" section (lines 2859-2889) lists List Price, Mortgage (75.0%), Monthly Payment ($2,689/mo), DSCR, Cash-on-Cash Return, and Monthly Cash Flow — but does **not** show the interest rate or loan term (e.g., "7.0% / 30-year fixed"). An investor cannot verify or adjust the mortgage assumption without this.

---

### 3. Cap rate absent from executive summary metrics

**RESOLVED**

Evidence: The executive summary financial metrics grid (line 377-380) now includes:
`Cap Rate — 4.9% — NOI / Price`

---

### 4. Expense ratios displayed as thousands of percent (6,424%) instead of ~64%

**RESOLVED**

Evidence: The AI-generated economics insight (line 2344-2345) now displays:
`Total OpEx % of Revenue is 70.7%. That means $0.71 of every $1 collected goes to operating costs, leaving only about 29.3% as operating margin before debt service and capital reserves.`
No malformed percentage values were found anywhere in the report.

---

### 5. "No Significant Investment Risks" shown for weak deal — should show DSCR/CoC warnings

**RESOLVED**

Evidence: The Risks & Confidence tab (lines 3015-3042) now shows "HIGH RISK" with "3 critical · 0 manageable" and lists three explicit critical issues:
- `DSCR of 0.81x is below breakeven (1.0x) — income does not cover debt service`
- `Negative cash-on-cash return (-4.0%)`
- `Market and/or seasonality data confidence is 0/100 — revenue projections are unreliable`

---

### 6. Seasonal cash flow warning missing despite multiple negative months

**RESOLVED**

Evidence: The Scenario Dashboard section (lines 520-531) now shows:
`Seasonal Cash Flow Risk — Cash flow is negative 8 of 12 months — you'll need cash reserves to ride through the off-season. Budget for at least 8 months of carrying costs before STR income recovers.`

---

### 7. Transparency of assumptions and ease of understanding for non-US investor

**PARTIALLY RESOLVED**

Evidence of improvements:
- Score calculation breakdown is transparent with a collapsible explainer (line 600-660).
- AI insights use plain language (e.g., "you're effectively working to support the condo, not the other way around").
- Bull/Bear case format (lines 407-430) with actionable "What Would Make This Work" section is clear.
- Compliance section explains licensing steps in plain terms (line 840-843).
- Data confidence warnings are prominent (lines 383-395).

Still missing:
- **No glossary or jargon explanation** for terms like DSCR, NOI, Cap Rate, Cash-on-Cash — a non-US investor unfamiliar with US real estate jargon may not understand these.
- **Interest rate and loan term are not stated** (see Issue #2), making it impossible for a foreign investor to evaluate financing assumptions or compare against their own lending options.
- **No currency or tax context** for international buyers (e.g., FIRPTA withholding, non-resident tax implications).

---

## Summary

| # | Issue | Status |
|---|-------|--------|
| 1 | Score weights hidden | RESOLVED |
| 2 | Interest rate and loan terms missing | STILL PRESENT |
| 3 | Cap rate absent from exec summary | RESOLVED |
| 4 | Expense ratios displayed as thousands of % | RESOLVED |
| 5 | "No Significant Risks" for weak deal | RESOLVED |
| 6 | Seasonal cash flow warning missing | RESOLVED |
| 7 | Transparency for non-US investor | PARTIALLY RESOLVED |

**Overall: 5/7 fully resolved, 1 still present, 1 partially resolved.**

The most impactful remaining gap is the missing interest rate and loan term in Deal Structure — a single line item fix that would significantly improve transparency for any investor, especially international ones unfamiliar with US mortgage defaults.
