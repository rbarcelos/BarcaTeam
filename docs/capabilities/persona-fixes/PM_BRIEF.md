# PM Brief: Persona Review Findings & Roadmap

**Property Reviewed**: 159 NE 6th St #4307, Miami, FL 33132 (Natiivo)
**Source**: 6-persona review (Power User, Buyer Agent, Intl Investor, Mortgage Manager, Regulatory Compliance, STR Operator)
**Date**: 2026-03-09
**Total Unique Issues**: 39 (across 60 mentions)

---

## Categorized Findings

### 1. Data Bug (engineering fix)

Issues where the code produces wrong output, contradictory signals, or missing data fields.

| # | Group | Issue | Effort | Impact | Sprint |
|---|-------|-------|--------|--------|--------|
| DB-1 | G1 | **Expense ratio bug**: LLM fed "6,424.1% of revenue" instead of ~64%. Likely units/scaling bug in data pipeline (monthly costs / wrong base, or basis points). | S | **High** | Sprint 1 |
| DB-2 | G2 | **Risk badge says "LOW RISK / 0 critical" while exec summary says CAUTION 66/100**, AI narrative says "Moderate Risk", and 0/100 confidence scores exist. Structured risk assessment ignores financial metrics entirely. | M | **High** | Sprint 1 |
| DB-3 | G6 | **HOA status contradictory**: Prerequisites shows "STR Allowed - Legal + HOA confirmed" (green check) while Compliance says "Verify HOA rules" with 2 conflicts. | S | **High** | Sprint 1 |
| DB-4 | G12 | **Interest rate / loan terms not disclosed**: $457,500 mortgage at $3,044/mo but no rate, term, or amortization shown. Back-calculates to ~7.0%/30yr but must be explicit. | S | **High** | Sprint 1 |
| DB-5 | G11 | **DSCR label wrong**: 1.11x labeled "Financing Feasible" but most DSCR loans require 1.20-1.25x minimum. Should say "Financing At Risk" or "Below Lender Minimum." | S | **High** | Sprint 1 |
| DB-6 | G7 | **Evidence artifacts all show 30% confidence** (placeholder). Web research shows identical 65% confidence for BOTH "allows STR" and "restricts STR." | M | **Medium** | Sprint 2 |
| DB-7 | G30 | **Timestamp inconsistency**: Header says "12:05 AM" but filename says "040517" (4:05 AM). | S | **Low** | Backlog |

### 2. Model Improvement (requires STR domain expertise)

The revenue/expense model needs tuning. These affect the core financial projections.

| # | Group | Issue | Effort | Impact | Sprint |
|---|-------|-------|--------|--------|--------|
| MI-1 | G3 | **Occupancy 80% vs market 26%**: Report models 80% base while own data shows market at 26%, comps at 75.4%, Guest Demand Grade F. With 3-night min on 505sqft 1BD, realistic is 68-73%. Break-even is 77%. | M | **High** | Sprint 1 |
| MI-2 | G10 | **Missing cleaning/turnover costs**: ~8-9 turnovers/mo at $100-150/clean = $800-$1,350/mo absent from OpEx. Alone could flip $347/mo positive to $50-$1,000/mo loss. | S | **High** | Sprint 1 |
| MI-3 | G5 | **3-night minimum not modeled in revenue**: Revenue uses "Min Stay: 1 night (default)" despite HOA 3-night rule. Kills weekend 2-nighters, reduces OCC by 5-10pp and ADR by 3-5%. | M | **High** | Sprint 2 |
| MI-4 | G9 | **Expenses frozen across scenarios**: Variable costs ($3,034/mo) don't scale with occupancy. Conservative looks worse than reality, optimistic looks better. | M | **Medium** | Sprint 2 |
| MI-5 | G17 | **ADR + Occupancy both top-quartile**: Comp data shows inverse ADR/OCC relationship. Can't model $388 ADR AND 80% OCC simultaneously. Should pick one. | M | **Medium** | Sprint 2 |
| MI-6 | G21 | **Tax rate understated**: Report shows ~12% but actual is likely 13-14% (state 6% + county TDT 6% + city resort 2%). No breakdown by authority. | S | **Medium** | Sprint 2 |
| MI-7 | G27 | **Scenarios use arbitrary +/-10%** instead of comp-derived P25/P75 bands from the 49 comps available. | L | **Medium** | Backlog |
| MI-8 | G26 | **5-year projections use generic growth rates** (2%/2.5%/3%) with no pessimistic scenario. No HOA special assessment risk. | M | **Low** | Backlog |
| MI-9 | G31 | **Furnishing budget low** ($15K vs realistic $20-25K), no CapEx reserve in 5-year projection ($3-5K/yr starting Year 2). | S | **Low** | Backlog |

### 3. UX / Presentation

Information exists in the report but is poorly surfaced, buried, or contradictory across sections.

| # | Group | Issue | Effort | Impact | Sprint |
|---|-------|-------|--------|--------|--------|
| UX-1 | G4 | **Market Data Confidence 0/100 not surfaced**: Buried in tab details while Market score shows 82/100 (highest!). Should trigger a banner on exec summary. | S | **High** | Sprint 1 |
| UX-2 | G8 | **7-8 months negative cash flow not highlighted**: Property bleeds cash May-Nov. The $55K reserve requirement isn't connected to this pattern. | S | **Medium** | Sprint 1 |
| UX-3 | G18 | **1BR fails prerequisites but report continues without deal-breaker warning**: Prerequisites show 1/3 passed (needs 2+ BR, parking) but analysis proceeds as normal. | M | **Medium** | Sprint 2 |
| UX-4 | G23 | **Score weighting formula hidden**: Market 82 + Revenue 57 + Costs 56 + Price 50 = 66 (not 61.25 avg). Weights not disclosed. | S | **Medium** | Sprint 2 |
| UX-5 | G28 | **STR vs LTR comparison placeholder renders nothing**: Revenue tab has the section but it's empty. | M | **Medium** | Backlog |
| UX-6 | G29 | **Inconsistent comp count** (2 direct vs 49 area) without explanation. | S | **Low** | Backlog |

### 4. New Feature

Capabilities that don't exist yet but were requested by personas.

| # | Group | Issue | Effort | Impact | Sprint |
|---|-------|-------|--------|--------|--------|
| NF-1 | G15 | **Cap rate not displayed**: NOI $40,687 / $610K = ~6.7%. "Every investor asks this in the first 30 seconds." Simple calculation from existing data. | S | **High** | Sprint 1 |
| NF-2 | G16 | **No structured offer price recommendation**: AI mentions $550-580K in prose but no first-class "Recommended Offer Range" section. | M | **Medium** | Sprint 2 |
| NF-3 | G13, G14, G24, G25 | **International Investor Module**: FIRPTA (15% withholding on sale), federal income tax on ECI, estate tax ($60K NRA threshold), foreign financing (30-40% down, +1-2% rate), LLC structuring, currency risk. Would add $15-30K+/yr in costs. Critical for Miami market. | L | **High** | Backlog |
| NF-4 | G36 | **Print/PDF export**: Print button commented out in HTML. Agents need to email reports to clients. | M | **Medium** | Backlog |
| NF-5 | G41 | **Loan product guidance**: No guidance on DSCR vs conventional vs portfolio loans. Natiivo's STR-by-design may make it non-warrantable. | L | **Medium** | Backlog |

### 5. Content / Copy

Misleading labels, confusing wording, optimistic spin.

| # | Group | Issue | Effort | Impact | Sprint |
|---|-------|-------|--------|--------|--------|
| CC-1 | G37 | **Cost rigidity spins 50% fixed as "flexible"**: "50% of costs are fixed, providing reasonable flexibility to scale down" is backwards. | S | **Low** | Sprint 2 |
| CC-2 | G22 | **Management fee not contextualized**: 20% is high-end for purpose-built STR buildings (15-18% typical). Difference = $474/mo = doubles cash flow. | S | **Low** | Sprint 2 |
| CC-3 | G34 | **US-specific terminology without glossary**: DSCR, HOA, DBPR, HO6 never defined. Barrier for international users. | S | **Low** | Backlog |

### 6. Out of Scope

Nice-to-have but not addressable in near-term sprints.

| # | Group | Issue | Effort | Impact |
|---|-------|-------|--------|--------|
| OS-1 | G19 | Zoning district not identified (would need GIS/planning dept integration) | L | Medium |
| OS-2 | G20 | City of Miami STR registration specifics (Ordinance 13937, annual fees, 2% resort tax) | L | Medium |
| OS-3 | G38 | Platform-specific compliance guidance (Airbnb/VRBO requirements) | L | Low |
| OS-4 | G39 | Pending regulatory changes / outlook section | L | Low |
| OS-5 | G40 | Remote management discussion for absentee owners | S | Low |
| OS-6 | G32 | STR insurance requirements in regulatory section | M | Low |
| OS-7 | G33 | Fire/safety/inspection requirements | M | Low |
| OS-8 | G42 | Repatriation of profits guidance | S | Low |
| OS-9 | G43 | HOA special assessments discussion | S | Low |
| OS-10 | G35 | Cash reserves assumption for foreign holders | S | Low |

---

## Phased Roadmap

### Sprint 1 -- This Week (Fix Credibility Killers)

**Theme**: No user should see broken numbers or contradictory signals.

| Priority | Item | Category | Effort |
|----------|------|----------|--------|
| P0 | DB-1: Fix expense ratio bug feeding garbled % to LLM | Data Bug | S |
| P0 | DB-2: Reconcile risk badge with actual data (use financial metrics) | Data Bug | M |
| P0 | DB-3: Fix HOA confirmed vs verify contradiction | Data Bug | S |
| P0 | DB-5: Fix DSCR label (1.11x != "Financing Feasible") | Data Bug | S |
| P0 | DB-4: Show interest rate, loan term, amortization in report | Data Bug | S |
| P1 | MI-1: Reduce default occupancy or add prominent justification for gap | Model | M |
| P1 | MI-2: Add cleaning/turnover costs to OpEx model | Model | S |
| P1 | UX-1: Surface 0/100 confidence as exec summary banner | UX | S |
| P1 | UX-2: Add seasonal cash flow warning (7-8 months negative) | UX | S |
| P1 | NF-1: Add cap rate to exec summary metrics | New Feature | S |

**Estimated total**: ~10 items, mostly S effort. Core data pipeline fix (DB-1) is the single most important item.

### Sprint 2 -- Next Week (Model & Presentation Polish)

**Theme**: Make the financial model more realistic and the presentation more honest.

| Priority | Item | Category | Effort |
|----------|------|----------|--------|
| P1 | MI-3: Model 3-night minimum impact on revenue/occupancy | Model | M |
| P1 | MI-4: Scale variable costs across scenarios | Model | M |
| P2 | MI-5: Don't model ADR + OCC both at top quartile | Model | M |
| P2 | MI-6: Fix tax rate (13-14% not 12%) and add breakdown | Model | S |
| P2 | DB-6: Replace placeholder 30% confidence with real scores or "unscored" | Data Bug | M |
| P2 | UX-3: Add deal-breaker warning when prerequisites fail | UX | M |
| P2 | UX-4: Show score weighting formula | UX | S |
| P2 | NF-2: Add structured offer price recommendation section | New Feature | M |
| P3 | CC-1: Fix cost rigidity spin language | Content | S |
| P3 | CC-2: Contextualize management fee (15-18% typical for purpose-built STR) | Content | S |

### Backlog (Prioritized)

| Priority | Item | Category | Effort |
|----------|------|----------|--------|
| P2 | UX-5: Implement STR vs LTR comparison (placeholder exists) | UX | M |
| P2 | MI-7: Derive scenarios from comp P25/P75 bands | Model | L |
| P3 | NF-3: International Investor Module (FIRPTA, foreign financing, LLC, currency) | New Feature | L |
| P3 | NF-4: Print/PDF export | New Feature | M |
| P3 | MI-8: 5-year pessimistic scenario | Model | M |
| P3 | NF-5: Loan product guidance | New Feature | L |
| P4 | MI-9: Adjust furnishing budget, add CapEx reserve | Model | S |
| P4 | CC-3: Add glossary for US-specific terms | Content | S |
| P4 | UX-6: Clarify comp count (2 direct vs 49 area) | UX | S |
| P4 | DB-7: Fix timestamp inconsistency | Data Bug | S |
| -- | OS-1 through OS-10: Regulatory depth, platform guidance, etc. | Out of Scope | -- |

---

## Impact Summary

| Category | Count | Sprint 1 | Sprint 2 | Backlog |
|----------|-------|----------|----------|---------|
| Data Bug | 7 | 5 | 1 | 1 |
| Model Improvement | 9 | 2 | 4 | 3 |
| UX/Presentation | 6 | 2 | 2 | 2 |
| New Feature | 5 | 1 | 1 | 3 |
| Content/Copy | 3 | 0 | 2 | 1 |
| Out of Scope | 10 | -- | -- | -- |
| **Total** | **40** | **10** | **10** | **10** |

---

## Key Takeaways

1. **The #1 fix is DB-1 (expense ratio bug)**. 5 of 6 personas flagged it. It's likely a single scaling/units bug in the data pipeline feeding the LLM. Small code fix, massive credibility impact.

2. **The risk assessment system (DB-2) is fundamentally broken**. It ignores financial metrics (DSCR, CoC, break-even cushion, expense ratio) and only looks at regulatory/market signals -- and even those are wrong (showing "0 risks" when confidence is 0/100). This needs a rethink of what populates the risk badge.

3. **The revenue model is optimistic by design**. Three separate model issues (MI-1, MI-2, MI-3) compound: aggressive occupancy + missing cleaning costs + unmodeled 3-night minimum. Together they likely flip the property from $347/mo positive to $500-$1,500/mo negative. The report's CAUTION verdict is correct but for the wrong reasons.

4. **International investor support is a major product gap for Miami**. 4 findings (G13, G14, G24, G25) from a single persona, but Miami's buyer pool is 30-50% international. This is a backlog item due to effort (L) but should be the first major feature after the bug/model fixes land.

5. **The product architecture is strong**. Every persona praised the 6-tab structure, event calendar, scenario dashboard, and overall analytical framework. The issues are data plumbing and calibration, not design. Fixing Sprint 1 items alone would dramatically improve report credibility.

---

## Risk: Liability Exposure

The Mortgage Manager persona explicitly flagged that a report showing "No Significant Investment Risks Detected" for a property with 1.11x DSCR, 2.4% CoC, and 0/100 market confidence could create **platform liability**. DB-2 is not just a UX issue -- it's a legal risk. Prioritize accordingly.
