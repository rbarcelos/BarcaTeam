# QA E2E Report — Persona Fix Verification
**Report:** `159_NE_6th_St_4307_Miami_FL_20260309_040517_v2.html`
**Generated:** March 09, 2026 at 12:05 AM EDT
**QA Date:** 2026-03-09
**Verdict in report:** CAUTION | Score: 66/100 | DSCR: 1.11x | CoC: 2.4%

---

## Executive Finding

**The report was generated BEFORE most template/pipeline fixes were applied.** Template fixes (Fixes 4, 5, 6, 7, 8, 9, 12) exist in the current source but are NOT reflected in this report. Code-level (data) fixes (Fixes 2 mod, 13, variable-cost scaling, min-stay penalty) ARE present in current pipeline code but only apply to newly-generated reports.

---

## Fix-by-Fix Verification

### Fix 1 — Expense Ratio Normalization
**STATUS: FAIL (report contains bad data)**

The report contains the corrupt expense ratios:
- Line 2365: `total OpEx is listed as 6,424.1% of revenue`
- Line 2373: `HOA is 1,160.1% of revenue`
- Line 2379: `ratios (HOA 1,160.1%; property tax 991.8%; management 2,000.0%; STR tax 1,200.0%)`

These appear in the LLM-generated narrative for the confidence/audit tab. The underlying financial metrics (NOI $40,687, Cash Flow $4,162) are sane, but the AI narrative was generated from corrupted ratio data — possibly a division-by-monthly-revenue instead of annual, or costs passed in wrong units. This LLM narrative is frozen in the report.

**Note:** Bear case text at line 406 correctly states "Operating costs consume roughly 64% of revenue" — correct ratio exists elsewhere.

---

### Fix 2 — "No Significant Investment Risks" Gate
**STATUS: FAIL (showing despite DSCR 1.11 + CoC 2.4%)**

Report line 3034 displays:
> "No Significant Investment Risks Detected"

The pipeline fix (`property_analyzer.py:6606-6617`) correctly populates `manageable_risks` for DSCR < 1.25 and CoC < 5%. However, the report's risk register shows "0 critical · 0 manageable" — meaning this risk data was not populated when this report was generated (pre-fix). The template condition at `_tab_confidence.html:113` correctly suppresses the green banner when `manageable_risks` is non-empty. Regenerating will fix this.

---

### Fix 3 — "Legal + HOA confirmed" Conflict Warning
**STATUS: FAIL (shows confirmation despite compliance conflict)**

Report line 535 shows the green badge `Legal + HOA confirmed`, but the verdict reason at line 348 states: "Compliance conflict: Building allows STR but HOA 3-night minimum. Verify HOA rules before proceeding."

The template fix (`executive_summary.html:462-468`) correctly checks `context.data.compliance.merge_flags` for `'conflicting_signals'` and downgrades `merged_pass → False`, `merged_warn → True`. However, the compliance data serialized into this report does not include `merge_flags = ['conflicting_signals']` — so the downgrade never triggers. This is a data-population gap: the compliance merge logic sets the verdict reason correctly but does not write `conflicting_signals` into the `merge_flags` field for the template to consume.

---

### Fix 4 — DSCR "Thin" → "Below Lender Min" Label
**STATUS: FAIL (report still shows "Thin")**

Report line 376: `<div class="text-xs text-gray-500">Thin</div>`

Current template (`executive_summary.html:79`): `{% if dscr_value >= 1.25 %}Strong{% elif dscr_value >= 1.0 %}Below Lender Min{% else %}Below Breakeven{% endif %}`

The template is fixed, but this report was generated before the fix was applied. DSCR = 1.11 falls in the 1.0–1.25 range and would now correctly render "Below Lender Min".

---

### Fix 5 — Interest Rate / Loan Term in Deal Structure
**STATUS: FAIL (not rendered in this report)**

Report lines 2886–2916 (Deal Structure / Financing & Returns) show List Price, Mortgage amount, Monthly Payment, DSCR, CoC, and Monthly Cash Flow — but NO interest rate or loan term row.

Template fix (`_tab_pricing.html:120-134`) correctly renders these rows when `context.data.financials.assumptions.get('financing', {})` is populated with `interest_rate` / `loan_term` keys. The data path may not be populated in this report's context, or the report predates the fix.

---

### Fix 6 — Cap Rate in Executive Summary Metrics Grid
**STATUS: FAIL (report has 4-column grid, template has 5)**

Report line 362: `<div class="grid grid-cols-4 gap-3 mb-4">` — only Cash Flow, NOI, DSCR, Cash-on-Cash.

Current template (`executive_summary.html:65`): `<div class="grid grid-cols-5 gap-3 mb-4">` — adds Cap Rate as 5th tile.

Template is fixed; report predates it. With NOI $40,687 and price $610,000, cap rate = 6.67% — would render in yellow (4–6% threshold).

---

### Fix 7 — Score Weights Visible
**STATUS: FAIL (weights not shown in report)**

Report lines 352–358: Score box shows "66 /100" only — no weight breakdown.

Current template (`executive_summary.html:57-59`):
```
<div class="text-[9px] text-gray-400 mt-1 ...">
  25% mkt · 25% profit<br>20% reg · 15% val · 15% conf
</div>
```

Template is fixed; report predates it.

---

### Fix 8 — Low Data Confidence Banner
**STATUS: NOT TRIGGERED (data confidence values not low enough, or data missing)**

No low-confidence banner found in the report. Template fix (`executive_summary.html:94-112`) fires when `market_confidence < 20` or `seasonality_confidence < 20`. No evidence the data for this property is low-confidence — or the `data_sources` field is not populated in the report context.

---

### Fix 9 — Seasonal Cash Flow Warning
**STATUS: FAIL (warning not shown despite 7 negative months)**

The report's JavaScript chart data (`profitData.net` at line 3057) shows 7 months with negative net cash flow:
- May: −$532, Jun: −$832, Jul: −$354, Aug: −$1,394, Sep: −$2,035, Oct: −$535, Nov: −$735

The template fix (`executive_summary.html:257-270`) fires when `negative_months > 4` via `context.data.financials.monthly_detail | selectattr('net_income', 'lt', 0)`. The monthly net data exists in the chart JS object but likely not in `context.data.financials.monthly_detail` with an `net_income` attribute — suggesting the data path is not populated or the report predates the fix.

---

### Fix 10 — Deal-Breaker Banner for Blocked Prerequisites
**STATUS: CONDITIONAL PASS (not applicable for CAUTION verdict)**

Report lines 510–512 contain empty conditional comments:
```
<!-- Deal Breakers (NO-GO/CAUTION only) -->
<!-- Feasibility Assessment (NO-GO/CAUTION only) -->
```

The template at `executive_summary.html:280` fires when `context.data.compliance.deal_breakers` is non-empty. This property has CAUTION verdict, not NO-GO. The deal_breakers list appears empty for this property, so no banner is expected. This fix is N/A for this specific report — it would fire for a truly blocked property.

---

### Fix 11 — Offer Price Recommendation Section
**STATUS: FAIL (section not present in report)**

The template fix (`_tab_pricing.html:162-173`) adds a "Recommended Offer Range" section that computes max offer price from NOI and required CoC/DSCR thresholds. This section is NOT present in the generated report — predates the fix.

With NOI $40,687, the formula would compute a meaningful offer ceiling below $610,000, which aligns with the AI narrative at line 414 recommending "Negotiate purchase price down toward ~$550K."

---

### Fix 12 — Cost Rigidity "reasonable flexibility" → "limited flexibility"
**STATUS: FAIL (old text still shows)**

Report line 2610: `<span class="text-green-700 font-medium">providing reasonable flexibility</span>`

Current template (`_tab_economics.html:239-245`):
- If rigidity ≥ 60%: "limiting downside flexibility"
- Else: "limited flexibility to reduce costs in a downturn"

Rigidity = 50.0% → falls in else branch → correct new text is "limited flexibility to reduce costs in a downturn". The report was generated from the old template that used "providing reasonable flexibility" unconditionally, with a green text color. The fix changes both the wording AND makes the message more cautionary.

---

## Code-Level Fix Verification (Data Fixes — Require New Report)

These fixes affect pipeline logic, not templates. The generated report cannot reflect them — a fresh run is required.

### Cleaning Costs (Fix from Stream B)
**CODE PRESENT:** `OperatingCosts` model (`operating_costs.py`) has `cleaning_cost_per_turn`, `laundry_cost_per_turn`, `cleaning_guest_fee_offset`, and `estimated_turnovers_monthly` computed fields. Net cleaning cost is properly calculated and included in `operating_expenses_monthly`.

**POTENTIAL ISSUE:** `_update_operating_costs_from_api()` at `property_analyzer.py:1694` creates a new OperatingCosts without preserving `cleaning_cost_per_turn`, `laundry_cost_per_turn`, or `cleaning_guest_fee_offset`. These fields reset to 0.0 on API update. Net cleaning cost = $0 in updated costs. **This is a bug — cleaning costs silently drop after API cost update.**

### 3-Night Minimum Stay Penalty (Fix 11 in pipeline)
**CODE PRESENT:** `property_analyzer.py:1970-1986` correctly applies occupancy and ADR penalties when `minimum_stay_days >= 3`. Formula: OCC penalty = (min_nights - 1) × 2.5pp (cap 20pp), ADR penalty = (min_nights - 1) × 1.5% (cap 15%). For this property with HOA 3-night minimum, penalty = 5pp OCC + 3% ADR.

### Variable Cost Scaling (Fix 12 in pipeline)
**CODE PRESENT:** `scenario_service.py:262-276` correctly splits fixed vs variable costs and rescales management fee + STR tax to scenario revenue for conservative/optimistic scenarios.

### Occupancy Gap Warning (Fix 6 in pipeline)
**CODE PRESENT:** `property_analyzer.py:6619-6631` adds a manageable risk when property occupancy exceeds market by > 20pp.

---

## Rendering Issues Found

| Issue | Location | Severity |
|-------|----------|----------|
| Corrupt expense ratios in LLM narrative | Lines 2365–2379 | High — misleading to user |
| "No Significant Investment Risks" shown for DSCR 1.11 + CoC 2.4% | Line 3034 | High — false reassurance |
| "Legal + HOA confirmed" shown despite compliance conflict | Line 535 | High — misleading status |
| "Thin" label for DSCR (should be "Below Lender Min") | Line 376 | Medium — inaccurate labeling |
| "providing reasonable flexibility" (should be "limited flexibility") | Line 2610 | Medium — understates risk |
| Cap rate missing from exec metrics grid | Lines 362–383 | Medium — key metric absent |
| Interest rate / loan term missing from Deal Structure | Lines 2886–2916 | Low — transparency gap |
| Score weights not shown | Lines 352–358 | Low — transparency gap |
| Seasonal cash flow warning absent (7 negative months) | N/A | Medium — risk undisclosed |
| Offer price recommendation absent | N/A | Low — useful feature missing |

No Jinja2 UndefinedErrors, broken HTML, `$0` dollar values, or `None` strings were found. The report renders cleanly.

---

## Summary

- **Fixes confirmed in templates (code):** 2 (partial), 3, 4, 6, 7, 8, 9, 11, 12 — all in current source
- **Fixes confirmed in pipeline code:** variable scaling, min-stay penalty, occupancy gap warning, DSCR/CoC risk population
- **Fixes visible in THIS report:** 0 template fixes (report predates them); pipeline data fixes also not yet reflected
- **Root cause:** The report was generated before template and pipeline fixes were committed. A fresh run against the same property will be required to validate all 12 fixes end-to-end.
- **New bug found:** Cleaning costs (`cleaning_cost_per_turn`, `laundry_cost_per_turn`, `cleaning_guest_fee_offset`) are silently dropped in `_update_operating_costs_from_api()` at `property_analyzer.py:1694–1708` — these fields are not forwarded to the rebuilt `OperatingCosts` object.
