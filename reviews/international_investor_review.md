# International STR Investor Review

**Persona:** International investor evaluating US short-term rental properties from abroad (non-US resident, non-US citizen)
**Report Reviewed:** `159 NE 6th St #4307, Miami, FL 33132` — V2 HTML Report (generated March 9, 2026)
**Review Date:** 2026-03-09

---

## Summary

This report provides a solid analytical framework for a US-based STR investor but has significant blind spots for an international buyer. Foreign investors face a fundamentally different cost structure, tax regime, financing landscape, and regulatory burden — none of which are addressed. An international investor relying solely on this report would make decisions based on incomplete financial projections and could face unexpected costs of $15,000–$30,000+ annually.

---

## Findings

### 1. No Foreign Investor Tax Treatment (FIRPTA, Withholding, ECI)

**Severity: Critical**

The report's entire financial model assumes US-resident tax treatment. For a non-resident alien (NRA) investor, the tax picture is dramatically different:

- **FIRPTA (Foreign Investment in Real Property Tax Act):** Upon sale, the buyer must withhold 15% of the gross sale price and remit to the IRS. The 5-year projection showing "$124,005 total equity gain" (line ~2761) and "2.02x investment multiple" (line ~2766) makes no mention of this massive withholding obligation at exit.
- **Federal income tax on rental income:** NRA investors pay federal tax on "effectively connected income" (ECI) from US rental property at graduated rates (up to 37%), or 30% flat withholding on gross rents if no tax election is made. Neither scenario is modeled.
- **State income tax:** Florida has no state income tax, which is actually an advantage for international investors — but the report never highlights this benefit or contrasts it with other US states.
- **No mention of ITIN requirement:** Foreign investors need an Individual Taxpayer Identification Number to file US taxes, open bank accounts, and obtain financing.

**What's shown:** "Tax Rate ~12% — Combined state + local lodging tax" (line ~977)
**What I'd expect:** A separate "International Investor Tax Considerations" section showing: lodging/tourist taxes (~12%), federal income tax on net rental income (10-37% graduated or 30% flat), FIRPTA withholding at sale (15%), and treaty benefits if applicable. The cash flow projections should include a toggle or note for NRA tax impact.

---

### 2. Financing Assumptions Are US-Centric

**Severity: Critical**

The report assumes standard US financing: "Mortgage (75.0%) — $457,500" at ~7.5% with "Monthly Payment $3,044/mo" (lines ~2894–2899). International investors face a completely different financing reality:

- Most US lenders require 30-40% down payment for foreign nationals (not 25%)
- Interest rates for foreign nationals are typically 1-2% higher than domestic rates
- Many lenders require DSCR loans (debt service coverage ratio loans), which have different terms
- Some foreign nationals must purchase all-cash

**Impact on projections:** If down payment increases from 25% to 35%, that's an additional $61,000 in upfront capital needed ($213,500 vs $152,500). If the rate increases from ~7.5% to ~9%, monthly debt service rises from $3,044 to approximately $3,680, turning the already-thin $347/mo positive cash flow (line ~2914) into a significant monthly loss.

**What I'd expect:** At minimum, a note that financing terms shown are for US-resident borrowers. Ideally, a foreign-buyer financing scenario with higher down payment and rate assumptions.

---

### 3. No Foreign Ownership Structure Guidance

**Severity: Major**

The report provides no guidance on entity structuring, which is one of the most consequential decisions for an international investor:

- **LLC vs. direct ownership:** Most international investors are advised to hold US property through a US LLC to limit liability and simplify tax filing. This has cost implications (formation, registered agent, annual reports).
- **Tax treaty benefits:** Depending on the investor's home country, bilateral tax treaties may reduce withholding rates. No mention anywhere.
- **Estate tax exposure:** Non-resident aliens face US estate tax on US-sited assets above $60,000 (vs $12.92M for US persons). A $610,000 property creates massive estate tax exposure. This is not mentioned.

**What I'd expect:** A brief section or callout box: "International Buyers: Consult a cross-border tax advisor. Key considerations include entity structuring (LLC recommended), estate tax exposure, and tax treaty benefits."

---

### 4. All Figures in USD Only — No Currency Context

**Severity: Major**

Every financial figure is in US dollars with no acknowledgment that the reader may be evaluating in a different base currency:

- "List Price: $610,000" (line ~81)
- "TOTAL CASH NEEDED: $240,859" (line ~2880)
- "Cash Flow: $4,162/yr" (line ~365)
- All 5-year projections in USD

For an international investor, currency fluctuation can dominate returns. A 5% USD depreciation against the investor's home currency could wipe out the entire 2.4% cash-on-cash return.

**What I'd expect:** At minimum, a disclaimer that returns are in USD and subject to currency risk. Ideally, a note explaining that investors should factor in hedging costs or currency volatility when comparing to domestic investment alternatives.

---

### 5. Regulatory Section Lacks Foreign-Specific Licensing Requirements

**Severity: Major**

The regulatory tab states: "You will need to: (1) obtain the required Miami-Dade County and City of Miami vacation rental licenses/registrations, (2) register and pay all STR taxes..." (line ~815). This is correct but incomplete for foreign investors:

- Some jurisdictions require a US mailing address or registered agent for licensing
- Florida DBPR vacation rental license may require an ITIN or EIN
- Sales tax registration with FL DOR requires specific forms for foreign entities
- Property management companies may need to act as the license holder for foreign owners

**What I'd expect:** A note under "What You Need to Do to Comply" that flags additional requirements for non-US owners, or at least a disclaimer that requirements may differ for foreign nationals.

---

### 6. Confusing/Erroneous Expense Ratios in AI Analysis

**Severity: Major**

The Costs & Cash Flow AI-generated insight contains alarming and clearly erroneous metrics:

> "The operating expense status is flagged as VERY_HIGH, and total OpEx is listed as 6,424.1% of revenue"
> "HOA is 1,160.1% of revenue"
> "property tax 991.8%; management 2,000.0%; STR tax 1,200.0%"

(Lines ~2366–2379)

These percentages are nonsensical — HOA at $1,100/mo is ~11.6% of $113,781 annual revenue, not 1,160%. This appears to be a bug where monthly costs are being compared to monthly revenue incorrectly (possibly dividing monthly cost by a much smaller number). For any reader this is confusing; for an international investor less familiar with US cost structures, it could be deeply misleading or erode trust in the entire analysis.

**What I'd expect:** Correct expense ratios. The actual OpEx ratio of ~64% is already high and worth flagging; the erroneous 6,424% figure undermines the report's credibility.

---

### 7. No Discussion of Remote Property Management

**Severity: Minor**

The report mentions a 20% management fee ($1,896/mo) but doesn't discuss what this covers or whether it's adequate for absentee/international ownership. Key questions for international investors:

- Does the 20% fee include full-service management (guest communication, cleaning coordination, maintenance, restocking)?
- Who handles emergencies or guest issues in the owner's absence?
- Is the Natiivo building's hotel-program management an option, and at what fee?

**What I'd expect:** A brief note on management scope, especially since the report's own "What Would Make This Work" section suggests "Explore self-management or a lower-fee operator" (line ~415) — which is impractical for an international owner.

---

### 8. US-Specific Terminology Without Glossary

**Severity: Minor**

The report uses numerous US-specific financial and real estate terms without explanation:

- **DSCR** (Debt Service Coverage Ratio) — mentioned as "1.11x" with label "Thin" (line ~376) but never defined
- **NOI** (Net Operating Income) — used throughout
- **Cash-on-Cash Return** — shown as "2.4%" with "Target 8%+" (line ~381)
- **HO6 Property Policy** — listed as a cost (line ~2465) with no explanation of what HO6 insurance is
- **HOA** — used extensively but never spelled out as Homeowners Association
- **DBPR** — referenced in licensing (line ~965) without expansion

**What I'd expect:** Either inline definitions on first use (e.g., "DSCR (Debt Service Coverage Ratio — measures whether rental income covers debt payments)") or a glossary section. This is important for non-US investors who may not be familiar with these acronyms.

---

### 9. Cash Reserves Assumption Not Explained

**Severity: Minor**

The Deal Structure shows "Cash Reserves (6 months) — $54,809" (line ~2876). For an international investor:

- Where should these reserves be held? US bank account? (Requires ITIN or EIN to open)
- Is 6 months sufficient given the distance and inability to quickly respond?
- Does this account for potential vacancy during initial setup/furnishing period?

**What I'd expect:** A note that reserves should be held in a US bank account, with guidance that international investors may want to hold 8-12 months of reserves given operational distance.

---

### 10. Repatriation of Profits Not Addressed

**Severity: Suggestion**

The report projects positive cash flow ($4,162/yr base) and 5-year equity gains, but never discusses how an international investor actually receives these funds:

- Wire transfer fees from US to foreign accounts
- Potential withholding on outbound transfers
- Currency conversion costs
- Compliance with both US and home-country reporting requirements (FBAR, CRS)

**What I'd expect:** A brief note acknowledging that profit repatriation involves costs and compliance obligations, suggesting the investor budget 1-2% annually for cross-border banking and compliance costs.

---

## Overall Assessment

The report is well-structured, visually clear, and provides genuine analytical value for evaluating STR investment fundamentals — location scoring, revenue modeling, event impact, and cost breakdowns are all strong. However, it is **designed entirely for a US-domestic investor audience**. An international investor using this report as their primary decision tool would:

1. **Underestimate total costs** by $15,000–$30,000+/yr (federal income tax, higher financing costs, entity maintenance, cross-border compliance)
2. **Underestimate upfront capital** by $60,000+ (higher down payment requirements)
3. **Miss critical legal obligations** (FIRPTA, estate tax, entity structuring)
4. **Overestimate net returns** since the 2.4% cash-on-cash and $347/mo cash flow would likely turn negative under realistic international investor assumptions

**Recommendation:** Add an "International Investor Considerations" callout section (or toggle) that addresses tax treatment, financing differences, entity structuring, currency risk, and repatriation. This would make the report genuinely useful for the significant segment of Miami STR buyers who are non-US investors.
