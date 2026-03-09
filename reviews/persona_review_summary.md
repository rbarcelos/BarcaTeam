# Unified Persona Review Summary

**Property**: 159 NE 6th St #4307, Miami, FL 33132 (Natiivo)
**Report Version**: v2 (Generated March 9, 2026)
**Reviewed By**: 6 Persona Agents (Power User, Buyer Agent, International Investor, Mortgage Manager, Regulatory Compliance, STR Operator)
**Date**: 2026-03-09

---

## Aggregate Findings

| Severity | Count | Unique Issues |
|----------|-------|---------------|
| Critical | 15 mentions | 8 unique issues |
| Major | 22 mentions | 12 unique issues |
| Minor | 14 mentions | 11 unique issues |
| Suggestion | 9 mentions | 8 unique issues |
| **Total** | **60 mentions** | **39 unique issues** |

---

## Grouped Findings (similar issues merged)

### GROUP 1: Broken Expense Ratios in AI Narrative
**Severity: Critical** | Reported by: 5/6 personas (Power User, Buyer Agent, Intl Investor, Mortgage Mgr, STR Operator)

The AI-generated Cash Flow tab reports nonsensical expense percentages:
- "OpEx is 6,424.1% of revenue"
- "HOA 1,160.1% of revenue"
- "Property tax 991.8%; management 2,000.0%; STR tax 1,200.0%"

The actual math is ~64% OpEx ratio ($73,094 / $113,781). The AI correctly computes this in the same paragraph, creating a confusing contradiction. Likely cause: a units/scaling bug in the data passed to the LLM (monthly costs divided by wrong base, or values in basis points).

**Impact**: Every persona flagged this as credibility-destroying. The Buyer Agent said: "If I emailed this to a client, they'd call me within 5 minutes." This is the #1 fix priority.

---

### GROUP 2: Contradictory Risk Assessment ("No Risks" vs CAUTION)
**Severity: Critical** | Reported by: 5/6 personas (Power User, Buyer Agent, Mortgage Mgr, Regulatory Compliance, STR Operator)

The Risk & Confidence tab shows:
- "LOW RISK" badge with "0 critical, 0 manageable"
- "No Significant Investment Risks Detected"

While simultaneously:
- Executive Summary verdict is "CAUTION" at 66/100
- Market Data Confidence: 0/100, Seasonality Confidence: 0/100
- AI narrative says "Moderate Risk" and "6-7/10 reliability"
- Compliance tab shows 2 conflicts and VERIFY REQUIRED
- DSCR 1.11x (below lending minimums), CoC 2.4% (target 8%+)
- Conservative and market-average scenarios show negative cash flow

The Mortgage Manager noted this could create **liability exposure** for the platform.

---

### GROUP 3: Occupancy 80% vs Market Reality
**Severity: Critical** | Reported by: 4/6 personas (Power User, Buyer Agent, Mortgage Mgr, STR Operator)

The report models 80% base occupancy while its own data shows:
- Market Occupancy Rate: 26%
- Guest Demand Score: 38/100 (Grade F)
- Comp average (airroi): 75.4%

The STR Operator notes that with a **3-night minimum** on a 505 sqft 1BD, realistic occupancy is 68-73%. The break-even is 77%, meaning the property likely doesn't cash-flow under realistic assumptions.

The Mortgage Manager flagged that no lender would accept a 3x gap between market (26%) and projected (80%) without extensive justification.

---

### GROUP 4: Market Data Confidence 0/100 Undermines All Scores
**Severity: Critical** | Reported by: 4/6 personas (Power User, Buyer Agent, Mortgage Mgr, STR Operator)

Market Data Confidence, Seasonality Confidence, and STR Listing Detection Confidence are all **0/100**, yet:
- Market & Location score is 82/100 (the highest dimension score)
- Only 2 core comparable properties support the revenue model
- The inconsistency between 2 "direct comps" and "49 area comps" is never explained

When confidence is 0/100, this should trigger a prominent banner on the executive summary, not be buried in tab details.

---

### GROUP 5: 3-Night Minimum Not Modeled in Revenue
**Severity: Major** | Reported by: 3/6 personas (Buyer Agent, Regulatory Compliance, STR Operator)

The compliance section identifies the HOA 3-night minimum, but:
- Revenue model uses "Min Stay: 1 night (default)"
- Comp data likely collected from unrestricted listings
- The 3-night min kills weekend 2-nighters (highest RevPAR segment)
- Reduces occupancy by 5-10pp and ADR by 3-5% vs unrestricted

The STR Operator estimates this alone makes the base case fall below break-even.

---

### GROUP 6: HOA Status Contradictory (Confirmed vs Verify)
**Severity: Major** | Reported by: 2/6 personas (Regulatory Compliance, Buyer Agent)

The Prerequisites section marks "STR Allowed - Legal + HOA confirmed" (green checkmark), while the Compliance section says "Verify HOA rules before proceeding" and flags 2 compliance conflicts. These are irreconcilable signals.

---

### GROUP 7: Evidence Artifacts All Show 30% Confidence (Placeholder)
**Severity: Major** | Reported by: 2/6 personas (Power User, Regulatory Compliance)

All four evidence artifacts show identical 30% confidence. The web_research source shows "allows STR (conf: 65%); restricts STR (conf: 65%)" — identical confidence for opposing conclusions. This suggests default/placeholder values rather than genuine scoring.

The Regulatory Compliance reviewer noted that the DBPR license gets a **green checkmark** despite only 30% confidence — giving false assurance.

---

### GROUP 8: Monthly Seasonality — 7-8 Months Negative Cash Flow
**Severity: Major** | Reported by: 4/6 personas (Power User, Buyer Agent, Mortgage Mgr, STR Operator)

The property is cash-flow negative for 7-8 consecutive months (May through November), with cumulative net going as deep as -$5,771. The entire year's profit depends on a strong Dec-Mar season.

This is mentioned in data but not prominently called out. The $54,809 reserve is well-calibrated but the connection between "you'll bleed cash May-Nov" and "here's why you need $55K reserves" isn't made explicit.

---

### GROUP 9: Expenses Frozen Across Scenarios
**Severity: Major** | Reported by: 2/6 personas (Power User, STR Operator)

Variable costs ($3,034/mo) don't scale with occupancy across scenarios. Lower occupancy should reduce management fees, cleaning, and STR taxes. This makes the conservative scenario look worse than it should be, and the optimistic scenario look better.

---

### GROUP 10: Missing Cleaning/Turnover Costs
**Severity: Critical** | Reported by: 1/6 personas (STR Operator) — but operationally devastating

At 80% occupancy with 3-night average stays: ~8-9 turnovers/month at $100-$150/clean = **$800-$1,350/month** completely absent from OpEx. Even after guest-paid cleaning fees, net cost is $400-$700/month.

This alone could turn the $347/mo positive cash flow into a **$50-$1,000/month loss**.

---

### GROUP 11: DSCR Below Lending Minimums
**Severity: Critical** | Reported by: 1/6 personas (Mortgage Mgr) — but blocks financing

DSCR of 1.11x is labeled "Financing Feasible" but most DSCR loan products require **1.20-1.25x minimum**. The property would **fail to qualify** for majority of non-QM DSCR products. The label should say "Financing At Risk" or "Below Lender Minimum."

The Mortgage Manager's underwriting summary:

| Metric | Report Value | Lender Minimum | Status |
|--------|-------------|----------------|--------|
| DSCR | 1.11x | 1.20-1.25x | FAIL |
| Cash-on-Cash | 2.4% | 5-8% | FAIL |
| Break-even Cushion | 3pp | 15-20pp | FAIL |
| Expense Ratio | 64% | 40-50% | FAIL |
| Market Data Support | 0/100 | N/A | FAIL |

---

### GROUP 12: Interest Rate / Loan Terms Not Disclosed
**Severity: Critical** | Reported by: 1/6 personas (Mortgage Mgr)

The report shows $457,500 mortgage at $3,044/mo but never states the assumed interest rate, loan term, or amortization type. Back-calculating suggests ~7.0% / 30yr fixed, but this should be explicit and stress-tested at +50bps and +100bps.

---

### GROUP 13: No Foreign Investor Tax Treatment (FIRPTA, Withholding)
**Severity: Critical** | Reported by: 1/6 personas (Intl Investor) — but critical for Miami market

The entire financial model assumes US-resident tax treatment. Missing:
- FIRPTA: 15% withholding on gross sale price at exit
- Federal income tax on rental ECI (up to 37% or 30% flat)
- Estate tax exposure ($60K threshold for NRAs vs $12.92M for US persons)
- ITIN requirement

The Intl Investor estimates this would add **$15-30K+/year** in costs and **$60K+** in additional upfront capital.

---

### GROUP 14: US-Centric Financing Assumptions
**Severity: Critical** | Reported by: 1/6 personas (Intl Investor)

Foreign nationals face 30-40% down (not 25%), rates 1-2% higher, and different loan products. The $347/mo positive cash flow would turn deeply negative under realistic international financing terms.

---

### GROUP 15: No Cap Rate Displayed
**Severity: Major** | Reported by: 1/6 personas (Buyer Agent)

NOI of $40,687 and price of $610,000 implies ~6.7% cap rate, but this is never shown. The Buyer Agent notes: "Every investor asks 'what's the cap rate?' within the first 30 seconds."

---

### GROUP 16: No Structured Offer Price Recommendation
**Severity: Major** | Reported by: 1/6 personas (Buyer Agent)

AI narrative mentions "5-8% discount, ~$560K-$580K" and exec summary suggests "~$550K" but there's no structured "Recommended Offer Range" section with justification by target return metrics.

---

### GROUP 17: ADR + Occupancy Both at Top Quartile
**Severity: Major** | Reported by: 1/6 personas (STR Operator)

Comp data shows inverse ADR/occupancy relationship. At $388 ADR, comps achieve 65-90% occupancy (wide variance). Modeling both top-quartile ADR and top-quartile occupancy simultaneously is an "operator trap." Should model either $388 ADR at 72-75% OCC, or 80% OCC at $340-$360 ADR.

---

### GROUP 18: 1BR Fails Prerequisites but Report Continues Without Deal-Breaker Warning
**Severity: Major** | Reported by: 1/6 personas (Buyer Agent)

Prerequisites show 1/3 passed — unit needs 2+ bedrooms and parking. Report proceeds with full analysis without treating this as a potential deal-breaker.

---

### GROUP 19: Zoning District Not Identified
**Severity: Critical** | Reported by: 1/6 personas (Regulatory Compliance)

Report says "Zoning Status Unclear" but never states the actual zoning code (likely T6-36a-O under Miami 21). For a $610K investment, this is a blocking unknown.

---

### GROUP 20: City of Miami STR Registration Missing
**Severity: Critical** | Reported by: 1/6 personas (Regulatory Compliance)

No mention of City of Miami STR registration program (Ordinance 13937), annual fees, or the 2% city resort tax.

---

### GROUP 21: Tax Rate Understated
**Severity: Major** | Reported by: 1/6 personas (Regulatory Compliance)

Report shows ~12% combined tax. Actual burden is likely 13-14% (state 6% + county TDT 6% + city resort 2%). No breakdown of which taxes apply or who collects them.

---

### GROUP 22: Management Fee Not Contextualized
**Severity: Major** | Reported by: 1/6 personas (STR Operator)

20% management is the high end for purpose-built STR buildings where infrastructure reduces overhead. 15-18% is more typical. The difference ($474/mo) would more than double annual cash flow.

---

### GROUP 23: Score Weighting Formula Not Disclosed
**Severity: Major** | Reported by: 1/6 personas (Power User)

Market 82, Revenue 57, Costs 56, Price 50 → Final 66. Simple average would be 61.25. The weighting is hidden, so users can't verify the methodology.

---

### GROUP 24: No Foreign Ownership Structure Guidance
**Severity: Major** | Reported by: 1/6 personas (Intl Investor)

No guidance on LLC structuring, tax treaty benefits, or estate tax planning — critical for the significant international buyer segment in Miami.

---

### GROUP 25: No Currency Risk Context
**Severity: Major** | Reported by: 1/6 personas (Intl Investor)

All figures in USD only. A 5% USD depreciation would wipe out the entire 2.4% CoC return for a foreign investor.

---

### Minor & Suggestions (consolidated)

| # | Issue | Personas | Severity |
|---|-------|----------|----------|
| 26 | 5-year projections use generic growth rates, no pessimistic scenario | PU, MM, STR | Minor |
| 27 | Scenarios use arbitrary +-10% instead of comp-derived bands | PU | Minor |
| 28 | STR vs LTR comparison placeholder renders nothing | PU | Minor |
| 29 | Inconsistent comp count (2 vs 49) without explanation | PU | Minor |
| 30 | Timestamp inconsistency (12:05 AM vs 04:05 filename) | BA | Minor |
| 31 | Furnishing budget low ($15K), no CapEx reserve in 5-year | STR | Minor |
| 32 | No STR insurance requirements in regulatory section | RC | Minor |
| 33 | No fire/safety/inspection requirements | RC | Minor |
| 34 | US-specific terminology without glossary (DSCR, HOA, DBPR, HO6) | II | Minor |
| 35 | Cash reserves assumption unexplained for foreign holders | II | Minor |
| 36 | No print/PDF export functionality | BA | Suggestion |
| 37 | Cost rigidity insight spins 50% fixed costs as "flexible" | PU | Suggestion |
| 38 | No platform-specific compliance guidance (Airbnb/VRBO requirements) | RC | Suggestion |
| 39 | No pending regulatory changes / outlook section | RC | Suggestion |
| 40 | No remote management discussion for absentee owners | II | Suggestion |
| 41 | No loan product guidance or qualification analysis | MM | Suggestion |
| 42 | Repatriation of profits not addressed | II | Suggestion |
| 43 | No discussion of HOA special assessments in new construction | MM, STR | Suggestion |

---

## Priority Action Items

### P0 — Fix Immediately (Data Bugs)
1. **Fix expense ratio calculation bug** feeding garbled percentages to LLM (Group 1)
2. **Reconcile risk assessment** — "No Risks" badge must reflect actual data (Group 2)

### P1 — Fix Before Launch (Credibility Killers)
3. **Reduce base occupancy** or justify the 80% vs 26% market gap prominently (Group 3)
4. **Surface 0/100 confidence** as a banner on executive summary (Group 4)
5. **Model 3-night minimum** impact on revenue and occupancy (Group 5)
6. **Resolve HOA contradiction** — can't be both "confirmed" and "verify" (Group 6)
7. **Add cleaning/turnover costs** to OpEx (Group 10)
8. **Fix DSCR label** — 1.11x should not say "Financing Feasible" (Group 11)
9. **Disclose interest rate and loan terms** (Group 12)

### P2 — Improve for Quality
10. **Add cap rate** to executive summary metrics (Group 15)
11. **Scale variable costs** across scenarios (Group 9)
12. **Replace placeholder 30% confidence** with real scores or "unscored" (Group 7)
13. **Highlight seasonal cash flow pattern** — 7-8 months negative (Group 8)
14. **Show score weighting formula** (Group 23)
15. **Add structured offer price recommendation** (Group 16)

### P3 — International Investor Module (New Feature)
16. **Add "International Investor Considerations"** section covering FIRPTA, foreign financing, LLC structuring, currency risk, and repatriation (Groups 13, 14, 24, 25)

### P4 — Regulatory Depth
17. **Resolve zoning district** or flag as blocking unknown (Group 19)
18. **Add City of Miami STR registration** specifics (Group 20)
19. **Break down tax rate** by authority (Group 21)

---

## What Works Well (Positives from All Personas)

Every persona acknowledged strong product foundations:
- Executive summary verdict + bull/bear case format
- Location scoring with walk/transit/bike scores
- Event calendar with ADR impact (standout feature)
- Scenario dashboard with range bars
- Guest Profile Fit section
- 5-Year Investment Outlook table structure
- Deal Structure section with total cash needed
- Compliance tab concept and multi-source evidence approach
- Monthly seasonality data (needs better surfacing)

---

*Individual persona reviews available in:*
- `reviews/power_user_review.md`
- `reviews/buyer_agent_review.md`
- `reviews/international_investor_review.md`
- `reviews/mortgage_manager_review.md`
- `reviews/regulatory_compliance_review.md`
- `reviews/str_operator_review.md`
