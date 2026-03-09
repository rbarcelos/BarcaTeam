# Persona Revalidation Summary

**Report:** `3900_Biscayne_Blvd_Unit_S-304_20260309_110643_v2.html`
**Date:** 2026-03-09
**Personas:** 6 (power-user, buyer-agent, intl-investor, mortgage-mgr, reg-compliance, str-operator)

---

## Results Overview

| Status | Count | Details |
|--------|-------|---------|
| RESOLVED | 14 | Fixes confirmed working in fresh report |
| FIXED THIS SESSION | 4 | Found during revalidation, fixed immediately |
| STILL PRESENT | 3 | Regulatory issues needing further investigation |

---

## RESOLVED (confirmed by personas)

| # | Issue | Confirmed By |
|---|-------|-------------|
| 1 | Expense ratio 6,424% -> 70.7% | All 6 personas |
| 2 | "No Significant Risks" -> proper DSCR/CoC risk warnings | 5 personas |
| 3 | Score weights visible (25% mkt, 25% profit, 20% reg, 15% val, 15% conf) | power-user, intl-investor |
| 4 | Cap rate as 5th metric tile in exec summary | 5 personas |
| 5 | DSCR "Thin" -> "Below Breakeven" (for 0.81x) | buyer-agent, mortgage-mgr |
| 6 | Cost rigidity "reasonable flexibility" -> "limited flexibility in a downturn" | buyer-agent, str-operator |
| 7 | Seasonal cash flow warning (8/12 months negative) | str-operator, intl-investor |
| 8 | HOA badge downgraded to amber with conflict warning | buyer-agent, reg-compliance |
| 9 | Low data confidence banner + red risk flag for 0/100 confidence | power-user |
| 10 | Offer price recommendation section with CoC/DSCR max prices | buyer-agent |
| 11 | AI narrative quality and transparency | power-user, intl-investor |
| 12 | 3-night min-stay penalty logic present (N/A for this property - 1 night min) | str-operator, reg-compliance |
| 13 | MCP listing extraction working end-to-end | (verified during report generation) |
| 14 | Cleaning cost wipe bug fixed | (verified in code) |

---

## FIXED THIS SESSION (found during revalidation)

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | Interest rate/loan terms not in Deal Structure | `financing_assumptions` not passed to template context; template used wrong data path | Added to `context_data` dict in `v1_report.py:876`; rewrote template to use `context.data.financing_assumptions` |
| 2 | Management fee still 20% (should be 18%) | Hardcoded `0.20` fallback at `property_analyzer.py:4075` ignored config default | Changed to `self.config.default_management_fee_pct` |
| 3 | Variable costs same across all scenarios in template | Template `_tab_revenue.html:367-369` used `scenarios.base` for ALL columns | Changed to `scenarios.conservative` / `scenarios.base` / `scenarios.optimistic` per column |
| 4 | `noi_value` undefined in offer recommendation section | Variable defined in `executive_summary.html` but not in `_tab_pricing.html` (Jinja2 scope) | Added `{% set noi_value = scenarios.base.noi | metric_value %}` at top of section |

---

## STILL PRESENT (regulatory domain — need deeper investigation)

| # | Issue | Reported By | Notes |
|---|-------|-------------|-------|
| 1 | Deal-breaker banner empty despite NO-GO verdict | reg-compliance | Template fires on `deal_breakers` list which may not be populated for this property |
| 2 | Miami resort tax shows 12% not ~13% | reg-compliance | Server-side `calculate_str_tax()` added 2% for Miami, but this report may use cached pre-fix data |
| 3 | Regulatory gate shows PASS (74/100) despite NO-GO verdict | reg-compliance | Internal contradiction between axis score threshold and overall verdict logic |

---

## Backlog Items (improvement suggestions, not bugs)

- Glossary for DSCR/NOI/Cap Rate jargon (intl-investor)
- Rate sensitivity table for lenders (mortgage-mgr)

---

## Files Modified This Session

### investFlorida.ai
- `src/pipeline/property_analyzer.py` — cleaning cost forwarding, management fee default fix
- `src/models/property_data.py` — str_allowed/rental_restrictions type coercion validators
- `src/models/operating_costs.py` — (no changes this session, verified correct)
- `src/reports/strategies/v1_report.py` — added `financing_assumptions` to template context
- `src/reports/templates/v2_report/sections/investment_analysis/_tab_pricing.html` — noi_value def, interest rate/loan term display fix
- `src/reports/templates/v2_report/sections/investment_analysis/_tab_revenue.html` — per-scenario expense columns

### str_simulation
- `src/main_app.py` — ListingPageService initialization (was causing 503 on /listing/extract)
