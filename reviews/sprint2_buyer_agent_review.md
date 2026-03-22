# Sprint 2 Buyer Agent Review: Model Accuracy

**Persona**: Real Estate Buyer Agent (Investor-Focused, STR Properties)
**Reviewer**: Buyer Agent Persona (Phase 4 Stakeholder Review Panel)
**Date**: 2026-03-19
**Sprint**: Model Accuracy Sprint 2
**Reports Reviewed**: 3 (Natiivo CAUTION, Orlando NO-GO, Brickell NO-GO)
**Prior Review**: `reviews/buyer_agent_review.md` (Sprint 1 findings)

---

## Confidence Score: 7 / 10

Up from what would have been a 4/10 based on my Sprint 1 review. The structural fixes are real and substantial. The model now catches bad deals, surfaces deal-breakers visibly, and the core financial math is defensible. I would not yet stake my license on these reports without a final review pass, but I am close -- closer than I expected after Sprint 1.

---

## Executive Assessment

### What Changed Since Sprint 1 (The Good)

The two Critical findings from my first review are addressed:

1. **Garbage expense percentages: FIXED.** The Natiivo Cash Flow AI insights now show "47.1% of revenue" for OpEx and "18.0% of revenue" for management. The old "6,424.1% of revenue" nonsense that would have gotten me laughed off a call is gone. This alone makes the reports dramatically more presentable.

2. **Contradictory risk assessment: PARTIALLY FIXED.** The NO-GO reports (Orlando and Brickell) now properly suppress the "No Significant Investment Risks Detected" green badge and instead show deal-breaker banners with specific reasons (DSCR below breakeven, negative CoC). However, the Natiivo CAUTION report still shows "No Significant Investment Risks Detected" (see Finding #1 below).

3. **Deal-breaker banners work.** Both NO-GO reports render prominent red "Why This Failed" sections with specific deal-breakers: "DSCR below breakeven (0.36x)" for Orlando and "DSCR below breakeven (0.03x)" for Brickell. These are exactly the kind of clear, defensible signals I can show a client to explain why I am recommending they pass.

4. **Variable cost scaling works.** Natiivo shows different OpEx across scenarios: base $50,871, optimistic $55,735, conservative $44,580. This is realistic and defensible -- expenses scale with revenue as they should in a real business.

5. **DSCR lending context is excellent.** The "Lender view" annotation below DSCR is exactly what a buyer agent needs. Orlando shows "Below breakeven -- does not cover debt service" in red; Natiivo shows "Meets preferred threshold (>=1.25x)" in green. I can point a client to this and say "here is what a lender would see."

6. **18% management fee is correct.** The detailed expense breakdowns in all three reports correctly use 18% management fee (`management_fee_pct: 0.18`). This matches market rate for South Florida STR management.

7. **NO-GO verdicts are now bold and unmistakable.** Red border, stop-sign icon, "NO-GO" in large red text, score of 55/100 and 59/100. No client would confuse these for recommendations. The Orlando verdict reason -- "Profitability severely negative (10/100)" -- is the kind of plain language that prevents bad decisions.

### What Still Needs Attention (The Remaining Issues)

---

## Findings

### 1. Natiivo CAUTION Report Still Shows "No Significant Investment Risks Detected"
**Severity: Blocker**

The Natiivo report (CAUTION verdict, 72/100 score) displays a green box with a checkmark stating "No Significant Investment Risks Detected" in the Risk & Confidence tab. This property has:

- A compliance conflict (Building vs. HOA on min-stay policy)
- Investment Value score of only 50/100 ("Insufficient market data")
- A 3-night minimum stay restriction that limits booking flexibility
- Zero deal-breakers and zero major risks populated in the JSON data

AC-12 says the "No Significant Risks" badge should only appear when all gates PASS and confidence is above 50. The Natiivo report has a compliance conflict and the viability score shows pricing concerns (50/100). If I email this to a client who opens the Risk tab, sees the green "No Significant Risks" banner, and then later discovers the HOA min-stay restriction, I look like I did not read my own report.

The NO-GO reports correctly show "Risk Assessment Incomplete" instead. The badge guard logic appears to work for severe cases but fails for borderline (CAUTION) properties where the risk data arrays are empty even though risks clearly exist.

**What I need**: If a property has a CAUTION verdict, compliance conflicts, or any viability gate below 60, this green badge must not appear. A yellow "Review Required" or an itemized risk list is appropriate.

---

### 2. AI Narrative States "20% Management Fee" When Model Uses 18%
**Severity: Important**

Two of three reports contain AI-generated executive narrative text claiming "20% management fees":

- Natiivo (line 349): "Management alone takes 20% of revenue"
- Brickell (line 340): "driven by maintenance, taxes, and 20% management fees"

The actual model uses 18% (`management_fee_pct: 0.18`), and the detailed Cash Flow AI insights correctly state "18.0% of revenue ($19,453)." This means the executive summary and the detailed breakdown contradict each other within the same report.

Sprint 2 specifically changed the default management fee from 20% to 18% (AC-4). The AI-generated prose appears to be using stale prompt context or rounding up rather than reading the actual computed value. For a buyer agent, the executive summary is the part I show to clients first. If it says 20% but the details say 18%, I have to explain the discrepancy -- which undermines the tool's purpose of saving me time.

**What I need**: AI narrative text must reference the actual computed management fee percentage from the model data, not a hardcoded or approximate value.

---

### 3. AI Pricing Narrative Cites Fabricated Cap Rate and Cash Flow for Natiivo
**Severity: Important**

The Natiivo pricing tab AI narrative states:

> "the base cap rate (annual net operating income / price) is only 5.16%, and cash flow is negative at -$5,064/year"

But the JSON model data shows:
- Base cap rate: **9.38%** (NOI $57,199 / Price $610,000)
- Base net cash flow: **+$20,674/year**

The numbers "5.16%" and "-$5,064" do not appear anywhere in the report JSON data. The AI appears to have computed its own version of these metrics using a different formula or different inputs, and the results directly contradict the structured model output displayed elsewhere in the same report.

This is the most dangerous type of error for a buyer agent. If a client reads the executive summary showing +$20,674 cash flow and then reads the pricing analysis saying -$5,064, they will either lose trust in the report entirely or -- worse -- anchor on the wrong number. I cannot forward a report that gives two completely different answers to "does this property make money?"

**What I need**: AI-generated narratives must source financial metrics exclusively from the computed model data. If the AI performs its own calculations, those calculations must be verified against the structured output and flagged if they diverge.

---

### 4. Miami STR Tax Shows 12% Instead of 14%
**Severity: Important**

Both Miami properties (Natiivo and Brickell) show `total_str_tax: 0.12` in the JSON and "Tax Rate ~12%" in the HTML. The JSON shows `local_option_tax: null` for both.

The CAP_REVIEW states AC-3 PASS (14%), and Sprint 2 specifically built a Florida DOR tax lookup to capture Miami's 2% city resort tax. Yet the actual reports generated post-sprint still show 12%.

At 12% on $108K revenue (Natiivo), the STR tax is $12,968. At the correct 14%, it would be $15,130 -- a $2,162/year difference. For a property with already-tight margins in the conservative scenario, this understates expenses enough to matter.

For Orlando (Orange County), the 12% may or may not be correct depending on local TDT rates. The point is: this was a specific acceptance criterion for Sprint 2 that appears to not be reflected in the actual generated reports.

**What I need**: Confirmation that the tax lookup is actually being invoked during report generation, not just passing in QA tests. If the lookup is failing to resolve Miami's local option tax, the report should flag this rather than silently defaulting to 12%.

---

### 5. NO-GO Reports Show Green "LOW RISK" Badge in Risk Assessment Section
**Severity: Important**

Both the Orlando and Brickell NO-GO reports display a green "LOW RISK" badge with "0 critical, 0 manageable" in the Risk Assessment supporting data section. This appears below the "Risk Assessment Incomplete" yellow banner.

While the deal-breaker banners in the executive summary are strong and correct, a client who scrolls to the detailed Risk tab sees:

1. Green circle with "LOW RISK" label
2. "0 critical, 0 manageable" count
3. Yellow "Risk Assessment Incomplete" banner

For a property with -$24K/year cash flow (Orlando) or -$64K/year cash flow (Brickell), displaying a green "LOW RISK" badge anywhere in the report is misleading. The deal-breakers are surfaced in `risk.deal_breakers` but are not counted in the "critical" or "manageable" risk tallies.

**What I need**: When deal-breakers exist, the risk badge should reflect them. A report with deal-breakers should never display a green "LOW RISK" badge. The deal_breakers array content should flow into the risk counts.

---

### 6. Interest Rate and Loan Term Not Displayed in Deal Structure
**Severity: Nice-to-have**

AC-7 states "Interest rate and loan term displayed: PASS." The JSON data contains `interest_rate: 0.07` and `loan_term_years: 30`. However, the HTML Deal Structure section only shows:

- "Mortgage (75.0%)" -- the LTV
- "$3,044/mo" -- the payment

It does NOT explicitly display "7.0% interest rate" or "30-year term." The rate and term are fundamental assumptions that drive the entire cash flow analysis. An investor receiving this report cannot see what rate was assumed without diving into the JSON.

**What I need**: A line item in the Financing & Returns section reading "Rate: 7.0% / 30-yr fixed" or similar. Many investor clients will want to recalculate using their own rate expectations.

---

### 7. Cap Rate Not in Executive Summary Metrics Grid
**Severity: Nice-to-have**

The executive summary grid shows four metrics: Cash Flow, NOI, DSCR, Cash-on-Cash. Cap rate -- arguably the single most commonly requested metric by real estate investors -- is absent. The JSON contains `cap_rate` values for all scenarios (9.38% base for Natiivo, 2.15% for Orlando, 0.19% for Brickell).

This was flagged in my Sprint 1 review. The data exists in the model but is not surfaced in the most visible part of the report.

**What I need**: Cap rate as a fifth metric in the executive summary grid, or replace one of the existing four. Every investor I work with asks for cap rate within the first 30 seconds.

---

### 8. HOA Fees Show $0 for All Three Properties
**Severity: Nice-to-have**

All three reports show `hoa_fees: 0.0` in the expense breakdown. These are all condos in managed communities:
- Natiivo Miami (purpose-built STR condo)
- Vista Cay Orlando (resort condo community)
- The Club at Brickell Bay (luxury condo)

All of these buildings charge HOA fees. Natiivo units typically run $800-1,200/month. The Sprint 1 review of the same Natiivo unit noted $1,100/month HOA. If the model does not capture HOA fees from the listing data, this understates monthly expenses by $800-1,200+ per month -- potentially $10,000-14,000+ per year -- which would dramatically change the cash flow picture for Natiivo (turning its positive cash flow negative).

This is listed as nice-to-have because it was not specifically in Sprint 2 scope, but it remains a significant accuracy issue for condo analysis. The Natiivo base case cash flow of +$20,674 could flip to approximately +$6,674 to -$7,326 with a realistic $1,100/mo HOA included.

---

## Report-by-Report Assessment

### 1. Natiivo (159 NE 6th St #4307) -- CAUTION

| Metric | Value | My Take |
|--------|-------|---------|
| Verdict | CAUTION (72/100) | Directionally right |
| Base Cash Flow | +$20,674/yr | Likely overstated (missing HOA, understated tax) |
| Base DSCR | 1.57x | Healthy if cash flow is accurate |
| Cap Rate | 9.38% | Unusually high for Miami 1BR condo; AI says 5.16% -- conflict |
| Management Fee | 18% | Correct in model; AI exec says 20% |
| STR Tax | 12% | Should be 14% per Sprint 2 fixes |
| Min-Stay | 3-night (HOA) | Correctly identified and flagged |

**Would I email this?** Not yet. The cap rate contradiction (9.38% vs AI-stated 5.16%) and the "No Significant Risks" green badge on a CAUTION property would require me to add disclaimers that defeat the purpose of the tool. Close, but not there.

### 2. Orlando (5049 Shoreway Loop) -- NO-GO

| Metric | Value | My Take |
|--------|-------|---------|
| Verdict | NO-GO (55/100) | Absolutely correct |
| Base Cash Flow | -$23,974/yr | Clearly bad deal |
| Base DSCR | 0.36x | Lender would reject |
| Cap Rate | 2.15% | Terrible for STR investment |
| Deal-Breakers | 2 displayed | Clear and specific |

**Would I email this?** Almost. The deal-breaker banners and NO-GO verdict are exactly what I need to show a client why we are passing. The green "LOW RISK" badge in the risk details section is the only thing that would trip me up -- I would need to either not show the risk tab or explain the inconsistency.

### 3. Brickell (1200 Brickell Bay Dr #2202) -- NO-GO

| Metric | Value | My Take |
|--------|-------|---------|
| Verdict | NO-GO (59/100) | Absolutely correct |
| Base Cash Flow | -$63,747/yr | Catastrophic |
| Base DSCR | 0.03x | Essentially zero coverage |
| Cap Rate | 0.19% | Dead on arrival |
| Deal-Breakers | 2 displayed | Clear and specific |
| STR Tax | 12% | Should be 14% for Miami |

**Would I email this?** Same as Orlando -- the NO-GO verdict and deal-breaker display are client-ready. The "LOW RISK" badge in the risk tab is the remaining contradiction.

---

## Comparison with Sprint 1 Review

| Sprint 1 Finding | Sprint 2 Status | Notes |
|------------------|-----------------|-------|
| #1 Garbage expense % (6,424%) | FIXED | Now shows correct 47.1% |
| #2 Contradictory risk assessment | PARTIALLY FIXED | NO-GO reports improved; CAUTION still shows green badge |
| #3 Market confidence 0/100 not flagged | PARTIALLY FIXED | AI narratives mention confidence levels; still not prominent banner |
| #4 Missing cap rate | NOT FIXED | Still absent from exec summary grid |
| #5 No offer price recommendation | IMPROVED | Negotiation analysis present in AI narrative |
| #6 1BR prerequisite not prominent | UNCHANGED | Still small red X in prerequisites |
| #7 Conservative negative cash flow no warning | IMPROVED | Scenario ranges now visible |
| #8 Seasonal cash reserve connection | IMPROVED | Monthly profitability chart clear |
| #9 Timestamp oddity | FIXED | Now shows consistent timestamp |
| #10 3-night min not modeled in revenue | PARTIALLY FIXED | Min-stay identified; revenue adjustments visible but unclear magnitude |
| #11 No comparable sales data | UNCHANGED | Still zero sale comps |
| #12 No print/PDF export | UNCHANGED | Print button still commented out |

---

## Go/No-Go Recommendation: CONDITIONAL GO

**Proceed to Chat MVP with the following conditions:**

1. **Must fix before client-facing launch** (Blockers):
   - Fix the "No Significant Risks" badge on CAUTION properties (Finding #1)
   - Fix the green "LOW RISK" badge appearing on NO-GO properties (Finding #5)

2. **Must fix before broad rollout** (Important):
   - Ensure AI narrative text references actual computed values, not approximations (Findings #2, #3)
   - Verify Miami STR tax rate is actually 14% in production, not just in tests (Finding #4)

3. **Should fix in next sprint** (Nice-to-have):
   - Add interest rate and loan term to Deal Structure display
   - Add cap rate to executive summary grid
   - Investigate HOA fee ingestion from listing data

**Rationale**: The core model improvements are substantial and real. Sprint 2 turned reports that would embarrass me professionally into reports that are close to client-ready. The deal-identification logic is now sound -- bad deals get NO-GO, borderline deals get CAUTION, and the reasoning is clearly communicated. The remaining issues are presentation-layer contradictions between structured data and AI-generated narratives, plus some badge/guard logic edge cases. These are fixable without touching the underlying model.

---

## Client-Readiness Assessment

**Would I stake my reputation on these reports?**

For NO-GO properties: nearly yes. The verdicts are clear, the deal-breakers are prominent, and the financial metrics are all red where they should be. If a client asks "why did you tell me to skip this one?" I can point to the report and feel confident.

For CAUTION/borderline properties: not quite. The contradictions between AI narrative text and structured model data (cap rate, management fee, cash flow figures) create the kind of inconsistencies that sophisticated investors notice. I would need to manually review and annotate these before forwarding, which reduces the speed advantage the tool is supposed to provide.

For GO/PROCEED properties (not in this test set): unknown. The real test will be whether a strong property gets accurate, consistent positive signals across all sections.

**Bottom line**: Sprint 2 moved this tool from "not usable" to "almost usable." One more focused pass on narrative-data consistency and badge logic, and I would be comfortable making this a standard part of my investor presentation workflow.
