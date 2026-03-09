# Revalidation: Regulatory Compliance Issues

**Report:** `3900_Biscayne_Blvd_Unit_S-304_20260309_110643_v2.html`
**Date:** 2026-03-09

---

## Issue 1: "Legal + HOA confirmed" green badge despite HOA 3-night minimum

**Status: PARTIALLY RESOLVED**

The old green "confirmed" badge has been replaced with an amber/warning badge. The prerequisites section (line 560-561) now shows:

> `STR Allowed` with amber icon and note: "Compliance sources conflict -- verify HOA rules independently"

However, the regulatory narrative (line 827) still states: *"No minimum stay requirement is documented at either the HOA or city level"* -- which contradicts the previous review's finding that the HOA imposes a 3-night minimum. The badge downgrade is correct, but the narrative text does not acknowledge the 3-night restriction at all.

---

## Issue 2: Deal-breaker banner missing for properties with blocked prerequisites

**Status: STILL PRESENT**

The HTML contains a comment placeholder at line 535 (`<!-- Deal Breakers (NO-GO/CAUTION only) -->`) but renders nothing beneath it -- the section is empty. Despite the investment verdict being **NO-GO** (score 53/100, line 334-335) and prerequisites showing **0/3 passed** (line 547), no deal-breaker banner is rendered to visually alert the investor.

> Evidence: Line 535-538 shows empty `<!-- Deal Breakers -->` and `<!-- Feasibility Assessment -->` comment blocks with no rendered content.

---

## Issue 3: STR tax calculation missing Miami city resort tax (2%)

**Status: STILL PRESENT**

The report shows `Tax Rate ~12%` (line 1013) labeled "Combined state + local lodging tax." Miami-Dade STR tax should be approximately **13%** (6% FL sales tax + 5% Miami-Dade TDT + 2% Miami city resort tax). The 2% city resort tax appears to still be missing from the calculation.

> Evidence: Line 1013: `"Tax Rate ~12%"` with subtitle `"Combined state + local lodging tax"`.

---

## Issue 4: Regulatory gate accuracy -- do compliance verdicts correctly reflect restrictions?

**Status: PARTIALLY RESOLVED**

The compliance section now correctly flags conflicting signals (line 932-933: *"Compliance Conflicts Detected"*) and shows an amber "Conditional" verdict (line 902) rather than a clean pass. The prerequisites correctly show amber warnings.

However, the Go/No-Go gate at line 640-645 still shows:

> `PASS` with `Compliance: 74/100` check mark

This contradicts the 0/3 prerequisites and NO-GO verdict. The compliance gate passes despite conflicting signals and unresolved HOA restrictions, which is inconsistent.

---

## Issue 5: Min-stay penalty not reflected in occupancy/ADR projections

**Status: STILL PRESENT**

The revenue projections use `Min Stay: 1 night (default)` (line 1807-1809) with no adjustment for the HOA's 3-night minimum. Occupancy is projected at 72.1% and ADR at $290/night (lines 1801-1803, 1795-1797) with no min-stay penalty in the adjustments table (line 1814). The seasonality data also shows no min-stay impact on occupancy or ADR figures.

> Evidence: Line 1808-1809: `"Min Stay: 1 night (default)"` -- no penalty applied to projections.

---

## Summary

| # | Issue | Status |
|---|-------|--------|
| 1 | Green badge downgrade | PARTIALLY RESOLVED (badge amber, but narrative ignores 3-night min) |
| 2 | Deal-breaker banner | STILL PRESENT (empty despite NO-GO + 0/3 prereqs) |
| 3 | Miami resort tax (2%) | STILL PRESENT (shows 12% instead of ~13%) |
| 4 | Regulatory gate accuracy | PARTIALLY RESOLVED (conflicts flagged, but gate still shows PASS) |
| 5 | Min-stay penalty in projections | STILL PRESENT (uses 1-night default, no penalty) |
