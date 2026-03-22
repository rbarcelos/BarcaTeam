# Execution Plan: Sprint 3 Pre-Chat Fixes
**Slug**: `sprint3-pre-chat-fixes`
**Date**: 2026-03-19
**Author**: Senior Engineer Agent

## Context

Five critical issues identified in the CEO Sprint 2 review that must be fixed before Chat MVP. Commit `dc4de8f` addressed I-3/I-4 partially but issues I-1 (viability gates null in JSON), I-2 (risk arrays empty), N-3 (HOA fees $0 on condos), and the badge issue remain.

**Repo**: `C:\Users\rbarcelo\repo\investFlorida.ai`

## Streams

| Stream | Repo | Can Parallelize With | Estimated Complexity |
|---|---|---|---|
| S3-1: HOA unknown flag | investFlorida.ai | S3-2 | S |
| S3-2: Risk badge guard | investFlorida.ai | S3-1 | S |
| S3-3: AI narrative grounding | investFlorida.ai | all | M (already partially done in dc4de8f) |
| S3-4: Viability gates JSON | investFlorida.ai | S3-5 | S |
| S3-5: Risk detail arrays | investFlorida.ai | S3-4 | M |

## Implementation Order

1. **S3-4: Viability gates null** — Read `_fetch_str_viability` result to understand when gates_data is empty; build synthetic gates from known financial data when API returns no gates.
2. **S3-5: Risk detail arrays** — Verify that major_risks/manageable_risks are populated correctly after `dc4de8f`; add population for CAUTION cases (not just NO-GO).
3. **S3-1: HOA unknown flag** — In `report_generator.py::_build_financial_assumptions`, detect unknown HOA for condos and show "Unknown (condo — verify)" instead of $0; also surface as a manageable risk.
4. **S3-2: Risk badge guard** — The "Hard Gates PASS" text shows green on CAUTION when compliance passes but financials are bad; investigate exact template location and fix.
5. **S3-3: AI narrative** — Verify `dc4de8f` fix is working; if narrative still contradicts, ensure ground truth is injected correctly.

## Files to Modify

| File | Issue | Change |
|---|---|---|
| `src/pipeline/property_analyzer.py` | S3-4, S3-5 | Ensure viability gates are synthetically populated when API returns empty; ensure risk arrays populated for CAUTION |
| `src/reports/report_generator.py` | S3-1 | Show "Unknown (condo)" for HOA when condo property has no HOA data |
| `src/reports/templates/v1_report/sections/investment_analysis/_header.html` | S3-2 | Gate badge color should reflect financial verdict, not just gate pass/fail |
| `src/reports/templates/v2_report/sections/investment_analysis/_header.html` | S3-2 | Same as v1 |
| `src/pipeline/compliance_scoring.py` | S3-4 | Ensure gate wiring is complete |

## Test Plan

| Test | Type | Command | Covers |
|---|---|---|---|
| HOA unknown flag | unit | `pytest tests/test_hoa_flag.py -v` | S3-1 |
| Viability gates populated | unit | `pytest tests/test_viability_gates.py -v` | S3-4 |
| Risk arrays populated | unit | `tests/test_viability_risk_flow_through.py` | S3-5 |
| Narrative grounding | unit | `pytest tests/test_narrative_grounding.py -v` | S3-3 |
| All unit tests | unit | `pytest tests/ -q --ignore=tests/validation --ignore=tests/integration --ignore=tests/benchmarks` | regression |

## Deviations from Architecture

| What | Why | Impact |
|---|---|---|
| No architectural doc for this sprint | Tactical bug-fix sprint, not capability | All fixes are bug fixes, no new contracts |
