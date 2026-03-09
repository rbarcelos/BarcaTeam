# Revalidation: Mortgage Manager Perspective

**Report:** 3900 Biscayne Blvd Unit S-304 (v2, 2026-03-09)
**Reviewer:** mortgage-manager agent
**Date:** 2026-03-09

---

## Issue-by-Issue Findings

### 1. DSCR Label "Thin" -> "Below Lender Min" for 1.0-1.25 range

**RESOLVED** (not applicable in current report — DSCR changed to 0.81x)

The current report shows DSCR 0.81x labeled **"Below Breakeven"** (line 369), which is correct for a sub-1.0 DSCR. The original "Thin" label issue for 1.0-1.25 range cannot be validated here because the DSCR no longer falls in that band. The labeling logic for 0.81x is appropriate.

> Evidence: `<div class="text-xl font-bold text-red-700">0.81x</div>` / `<div class="text-xs text-gray-500">Below Breakeven</div>`

---

### 2. "No Significant Investment Risks" despite weak DSCR

**RESOLVED**

The report now shows **"HIGH RISK"** with **3 critical risks** and explicitly flags the DSCR problem.

> Evidence: `<span class="text-sm font-bold text-red-700">HIGH RISK</span>` and `DSCR of 0.81x is below breakeven (1.0x) — income does not cover debt service`

---

### 3. Interest rate and loan terms missing from Deal Structure

**STILL PRESENT**

The Deal Structure section (lines 2824-2896) lists mortgage amount ($404,250), monthly payment ($2,689/mo), and LTV (75%), but does **not** display the interest rate or loan term (e.g., "7.0% / 30-year"). A mortgage professional cannot evaluate the deal without knowing the rate assumption.

> Evidence: Deal Structure "Financing & Returns" subsection contains `Mortgage (75.0%)`, `Monthly Payment $2,689/mo`, `DSCR`, `Cash-on-Cash Return` — no interest rate or term row present.

---

### 4. Cap rate absent from executive summary

**RESOLVED**

Cap Rate is now displayed as the 5th metric tile in the executive summary stats bar.

> Evidence: `<div class="text-xs text-gray-500 uppercase font-semibold mb-1">Cap Rate</div>` / `<div class="text-xl font-bold text-yellow-700">4.9%</div>`

---

### 5. Expense ratios as 6,424% -> should be ~64%

**RESOLVED**

The expense ratio is now reported as **70.7%**, which is a plausible operating expense ratio.

> Evidence: `Total OpEx % of Revenue is 70.7%. That means $0.71 of every $1 collected goes to operating costs`

---

### 6. Variable costs (management fee, STR tax) not scaling with scenario revenue

**STILL PRESENT**

In the scenario comparison table, expenses are **identical across all four scenarios** at ($63,348), even though revenue ranges from $71,812 (Conservative) to $103,126 (Optimistic). Management fee (20% of revenue) and STR lodging tax (~12%) should scale proportionally. At $103,126 optimistic revenue, variable costs alone should increase by ~$4,300+ vs. base, but expenses remain flat.

> Evidence: `<td class="py-2 px-3 text-gray-500">- Expenses</td>` followed by `($63,348)` in all four scenario columns (Conservative, Base, Optimistic, Market Avg).

---

### 7. Debt service coverage analysis quality for lending decisions

**PARTIALLY RESOLVED**

Improvements observed:
- DSCR is prominently shown with correct color-coding (red for sub-1.0)
- A "Max Purchase Price (1.25x DSCR)" metric shows $351,395, giving the lender a clear ceiling
- The risk section explicitly flags DSCR below breakeven
- Financing feasibility note states "DSCR 0.81 < 1.0 - negative cash flow"

Still missing:
- No interest rate or term shown (see issue #3), so a lender cannot verify the debt service calculation
- No sensitivity table showing DSCR at different rate assumptions (e.g., rate +0.5%, +1.0%)

> Evidence: `Max (1.25x DSCR) $351,395` and `DSCR 0.81 < 1.0 - negative cash flow`

---

## Summary

| # | Issue | Status |
|---|-------|--------|
| 1 | DSCR label "Thin" | RESOLVED (N/A — DSCR now 0.81, labeled "Below Breakeven") |
| 2 | "No Significant Risks" despite weak DSCR | RESOLVED |
| 3 | Interest rate / loan terms missing | STILL PRESENT |
| 4 | Cap rate absent from exec summary | RESOLVED |
| 5 | Expense ratio 6,424% | RESOLVED |
| 6 | Variable costs not scaling with scenarios | STILL PRESENT |
| 7 | DSCR analysis quality | PARTIALLY RESOLVED (good flags, missing rate/term & sensitivity) |

**Overall: 4 resolved, 2 still present, 1 partially resolved.**
