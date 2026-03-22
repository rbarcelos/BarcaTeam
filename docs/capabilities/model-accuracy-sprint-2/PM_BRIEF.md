# PM Brief: Model Accuracy Sprint 2
**Slug**: `model-accuracy-sprint-2`
**Date**: 2026-03-19
**Author**: PM Agent

## Context

Sprint 1 resolved 20 of 40 issues found across 6 persona reviews. Revalidation confirmed 14 fixes plus 4 fixed during the session. However, **12 distinct issues remain open** -- concentrated in revenue model accuracy, scenario fidelity, risk assessment consistency, and regulatory correctness.

Both the CEO and Investor strategic reviews identified model accuracy as the **#1 prerequisite** before any user-facing work. The CEO wrote: *"If we ship a chat interface on top of a model that sophisticated users don't trust, we've built a beautiful front door to a house with a cracked foundation."* The Investor added: *"If you launch with inaccurate projections, your first 5 users will tell their networks that the tool cannot be trusted."*

**Repos**: investFlorida.ai (report pipeline, templates, scoring), str_simulation (revenue engine, simulation core, financials)
**Prior art**: 6 persona reviews, 6 revalidation reviews, CEO sequence review, Investor sequence review
**Closed issues scanned**: 30 on each repo (investFlorida.ai #895-#934, str_simulation #392-#452)

---

## Problem Statement

The investment report model produces numbers that sophisticated users -- buyer agents, mortgage managers, STR operators -- can pick apart in minutes. Specific defects:

1. **Revenue projections ignore minimum-stay restrictions.** A 3-night HOA minimum kills weekend bookings (the highest RevPAR segment), but the model doesn't reduce occupancy or ADR. str_simulation only adjusts turnover count, not occupancy itself (`simulation.py:140-144`).

2. **Scenario analysis is misleading.** Variable costs (management fee, STR tax) are frozen at base-case values across all scenarios. Expenses show $63,348 across conservative-to-optimistic despite revenue ranging $71K-$103K. This makes bear cases too pessimistic and bull cases too generous.

3. **ADR and occupancy can both be top-quartile simultaneously.** No inverse coupling exists in the code. Both move in the same direction in `rate_boosters.py`. Empirically, comp data shows an inverse relationship -- high ADR correlates with lower occupancy.

4. **Risk system sends contradictory signals.** A NO-GO property (53/100, 0/3 prerequisites) shows "Compliance: 74/100 PASS" in the viability gate. The deal-breaker banner renders empty because `deal_breakers` list is never populated for profitability-driven NO-GO verdicts.

5. **Financial assumptions are opaque.** Interest rate and loan term are computed (7%/30yr in config) but never displayed. Investors cannot verify the debt service calculation. Management fee defaults to 20% when market data for purpose-built STR buildings suggests 15-18%.

6. **Tax calculations understate burden.** Miami properties show ~12% STR tax when actual burden is ~13% (missing 2% city resort tax). Code defaults city tax to 0% when API doesn't provide it (`financial_calculations.py:562-587`).

These defects combine to produce reports where the buyer agent persona said: *"If I emailed this to a client, they'd call me within 5 minutes."*

---

## Goals

1. Every scenario comparison reflects realistic cost scaling -- variable costs move with revenue
2. Min-stay restrictions reduce occupancy and ADR projections proportionally
3. ADR and occupancy are inversely coupled, preventing simultaneous top-quartile modeling
4. Risk assessment verdicts are internally consistent -- no "PASS" gates on NO-GO properties
5. Financial assumptions (rate, term, management fee) are transparent and market-appropriate
6. Tax calculations include all applicable local taxes for Florida municipalities

---

## Non-Goals

- **International investor module** (FIRPTA, foreign financing, currency context) -- separate capability
- **PT-BR localization** -- separate capability
- **New report sections or layouts** -- we fix existing sections, not add new ones
- **Chat interface or web frontend** -- downstream capabilities that depend on this sprint
- **LTR comparison** -- Phase 3.6, separate capability
- **Glossary for financial terms** -- nice-to-have, not a model accuracy issue
- **Rate sensitivity tables** -- backlog improvement, not a credibility bug

---

## Personas

| Persona | Description | Key Needs |
|---|---|---|
| Buyer Agent | Licensed agent who emails reports to investor clients | Numbers must survive client scrutiny; contradictions cause callbacks |
| Mortgage Manager | Lending professional using reports for preliminary DSCR underwriting | Must see interest rate, loan term, and realistic expense scaling to assess financing feasibility |
| STR Operator | Experienced vacation rental manager who knows real operational numbers | Revenue projections must account for min-stay penalties; management fee must match market |
| Regulatory Compliance Reviewer | Expert in STR regulations, zoning, HOA rules | Compliance verdicts must be internally consistent; tax rates must include all applicable authorities |
| Power User | Tech-savvy analyst who stress-tests data quality | Scenario models must be mathematically correct; assumptions must be transparent |
| International Investor | Foreign buyer evaluating Florida STR purchases | Financing assumptions must be visible; deal viability signals must be unambiguous |

---

## User Stories

- As a **buyer agent**, I want scenario comparisons with realistic expense scaling so that I can show clients credible best/worst case outcomes.
- As a **mortgage manager**, I want to see the assumed interest rate and loan term so that I can verify the DSCR calculation.
- As an **STR operator**, I want min-stay restrictions to reduce projected occupancy so that revenue estimates reflect real booking constraints.
- As a **regulatory compliance reviewer**, I want the viability gate to match the overall verdict so that compliance status is unambiguous.
- As a **power user**, I want ADR and occupancy to reflect their inverse empirical relationship so that projections don't simultaneously assume best-case for both.
- As an **international investor**, I want a deal-breaker banner on NO-GO properties so that the stop signal is impossible to miss.

---

## Issue Catalog

Each issue traced back to persona reviews, revalidation findings, and code verification.

### CRITICAL -- Credibility-Destroying

| ID | Issue | What's Broken | Why It Matters | Flagged By | Code Location |
|---|---|---|---|---|---|
| DB-1 | Variable costs frozen across scenarios | Expenses identical ($63,348) across all 4 scenarios despite revenue range $71K-$103K. Management fee (20%) and STR tax (~12%) should scale with revenue. | Conservative scenario too pessimistic, optimistic too generous. Misleads scenario-based investment decisions. | Power User, STR Operator, Mortgage Manager | `investFlorida.ai/src/services/scenario_service.py:73-121`; template `_tab_revenue.html` partially fixed but pipeline still sends base costs |
| DB-2 | Min-stay penalty not modeled | str_simulation only adjusts turnover count when min_stay>1 (`simulation.py:140-144`). Occupancy and ADR remain unchanged. 3-night min kills weekend 2-nighters. | Overstates revenue by 5-15% for restricted properties. STR Operator estimates this alone can flip cash-flow positive to negative. | Buyer Agent, Regulatory Compliance, STR Operator | `str_simulation/src/core/simulation.py:140-144`; `investFlorida.ai/src/pipeline/property_analyzer.py:841-928` |
| DB-3 | ADR-OCC not inversely coupled | Both ADR and occupancy move in the same direction in all multiplier code. Scenario factors apply independently. No trade-off curve enforced. | Creates "operator trap" -- modeling $388 ADR at 80% occupancy when comps show this combination doesn't exist. | STR Operator | `str_simulation/src/core/rate_boosters.py:174-197, 295-303`; `str_simulation/src/apps/financials/service.py:86-91` |
| DB-4 | Deal-breaker banner empty on NO-GO | Template checks `compliance.deal_breakers` list but it's never populated for profitability-driven or overall-score-driven NO-GO verdicts. Banner renders empty despite 0/3 prerequisites. | Investor sees full analysis without a visual stop sign. NO-GO verdict buried in score tile. | Regulatory Compliance | `investFlorida.ai/src/services/investment_scoring_service.py:597-605, 668-674`; template `executive_summary.html:378-410` |
| DB-5 | Regulatory gate shows PASS on NO-GO property | Viability gate shows "Compliance: 74/100" with checkmark despite overall NO-GO (53/100). Contradicts 0/3 prerequisites and conflicting compliance signals. | Sends mixed signal: "compliance passed" next to "do not invest." Undermines entire gate-based framework. | Regulatory Compliance | `investFlorida.ai/src/services/investment_scoring_service.py:634`; template viability gate section |
### HIGH -- Misleading

| ID | Issue | What's Broken | Why It Matters | Flagged By | Code Location |
|---|---|---|---|---|---|
| HI-1 | Interest rate / loan terms not displayed | `financing_assumptions` added to context (Sprint 1 fix) but template never renders rate or term. Shows mortgage amount + monthly payment without assumptions. | Mortgage professional cannot evaluate the deal. Back-calculation required. 3 personas flagged independently. | Mortgage Manager, Power User, International Investor | `investFlorida.ai/src/pipeline/config.py:69-71` (values exist); template `_tab_pricing.html` (missing render) |
| HI-2 | Management fee defaults to 20% | `config.py` has `default_management_fee_pct = 0.20`. Sprint 1 partially fixed (`property_analyzer.py:4075` now reads config) but config value still 20%. Market for purpose-built STR buildings is 15-18%. | Overstates operating costs. At $89K revenue, 20% vs 18% = $1,788/year difference. Could double annual cash flow on marginal deals. | STR Operator | `investFlorida.ai/src/pipeline/config.py:71` |
| HI-3 | City/local STR tax not resolved (~12% vs ~14% in Miami) | `calculate_str_tax()` ignores `city`/`county`/`zip_code` fields on `STRTaxRequest`. Defaults `local_option_tax` to 0%. No external tax rate API integration. | Understates tax burden by ~$1,800/year on $90K revenue. Won't scale to other regions. Regulatory compliance reviewer flagged as factual error. | Regulatory Compliance | `str_simulation/src/apps/financials/service.py:61-63,176-197` |
| HI-4 | Regulatory narrative contradicts badge | Badge correctly downgraded to amber (Sprint 1 fix), but narrative says "No minimum stay requirement documented at either the HOA or city level." | Text contradicts visual signal. Reader sees amber badge but text says everything's fine. | Regulatory Compliance | `investFlorida.ai` compliance narrative generation |

### MEDIUM -- Inaccurate but Not Misleading

| ID | Issue | What's Broken | Why It Matters | Flagged By |
|---|---|---|---|---|
| MD-1 | Evidence artifacts all show 30% confidence | All 4 regulatory evidence sources show identical 30% confidence. Web research shows 65% for both "allows" and "restricts." Placeholder values. | Reduces trust in evidence-based compliance system. | Power User, Regulatory Compliance |
| MD-2 | DSCR "Thin" label for 1.0-1.25x untested | Fixed for sub-1.0 ("Below Breakeven"). But 1.0-1.25x range still labeled "Thin" -- should say "Below Lender Minimum" (most products require 1.20-1.25x). | Mislabels marginal DSCR deals as merely "thin" when they'd actually fail to qualify for most non-QM products. | Mortgage Manager |
| MD-3 | DSCR lending threshold context missing | No structured table showing what DSCR levels qualify for which loan products (1.0x/1.2x/1.25x buckets). CEO cherry-pick recommendation. | Buyer agents and mortgage managers don't know the lending implications of the DSCR number. | Mortgage Manager (+ CEO recommendation) |

---

## Work Packages

### WP-1: Revenue Model Accuracy (str_simulation + investFlorida.ai)
**Issues**: DB-2 (min-stay penalty), DB-3 (ADR-OCC coupling)
**Priority**: Must-have

Changes required in **str_simulation**:
- `simulation.py`: Add occupancy reduction when `minimum_length_of_stay > 1` (not just turnover adjustment). Research-backed penalty: ~5pp occupancy reduction per night above 1, capped at -15pp for 7+ nights. ADR reduction: ~2% per night above 1, capped at -8%.
- `rate_boosters.py`: Implement ADR-OCC inverse coupling. When ADR multiplier exceeds a threshold (e.g., top 25% of market), apply a dampening factor to occupancy. When occupancy multiplier exceeds threshold, dampen ADR. The product of ADR x OCC should be bounded by comp-observed revenue-per-available-night ranges.
- `financials/service.py`: Ensure scenario factors respect inverse coupling (optimistic: higher ADR OR higher occupancy, not both at maximum).

Changes required in **investFlorida.ai**:
- `property_analyzer.py`: Ensure min-stay value is correctly extracted and passed through the pipeline.
- Verify `revenue_projection_service.py` passes min-stay to all relevant API calls.

**Acceptance Criteria**: See AC-1 through AC-4.

---

### WP-2: Scenario Cost Scaling (investFlorida.ai + str_simulation)
**Issues**: DB-1 (variable costs frozen)
**Priority**: Must-have

Changes required:
- `investFlorida.ai/src/services/scenario_service.py`: When building scenarios, recalculate variable costs (management fee, STR tax, OTA commission) using each scenario's revenue, not base-case revenue.
- `str_simulation/src/apps/financials/service.py`: Verify the `/financials/scenarios` endpoint computes per-scenario expenses correctly (the simulation engine in `simulation.py:162-177` already scales costs -- the issue may be in how investFlorida.ai consumes and forwards the data).
- Template `_tab_revenue.html`: Already partially fixed in Sprint 1 to use per-scenario data. Verify end-to-end that different numbers appear in each column.

**Acceptance Criteria**: See AC-5, AC-6.

---

### WP-3: Risk Assessment & Verdict Consistency (investFlorida.ai)
**Issues**: DB-4 (deal-breaker banner), DB-5 (regulatory gate contradiction)
**Priority**: Must-have

Changes required:
- `investment_scoring_service.py`: Populate `deal_breakers` list from ALL NO-GO sources, not just regulatory. When `S_profit < 30` or `S_overall < 50`, generate deal-breaker entries describing the profitability or overall assessment failure.
- `investment_scoring_service.py`: Viability gate logic -- if overall verdict is NO-GO, individual gates should not show green PASS checkmarks. A gate can pass independently but must show amber/red context when the overall verdict contradicts it.
- Template `executive_summary.html`: Verify deal-breaker banner renders when `deal_breakers` list has entries.

**Acceptance Criteria**: See AC-7 through AC-9.

---

### WP-4: Financial Transparency (investFlorida.ai)
**Issues**: HI-1 (interest rate display), HI-2 (management fee default), MD-2 (DSCR labels), MD-3 (DSCR lending table)
**Priority**: Must-have (HI-1, HI-2); Should-have (MD-2, MD-3)

Changes required:
- Template `_tab_pricing.html` or Deal Structure section: Add row showing "Interest Rate: 7.0% | Term: 30-year fixed" from `financing_assumptions` context data.
- `config.py`: Change `default_management_fee_pct` from `0.20` to `0.18`. Add code comment explaining market basis (purpose-built STR buildings in FL).
- Report template DSCR labels: Add "Below Lender Minimum" for 1.0-1.25x range (currently only handled for < 1.0).
- **Cherry-pick (CEO recommendation)**: Add DSCR lending threshold context -- a small structured display showing 1.0x (breakeven), 1.20x (standard DSCR minimum), 1.25x (preferred) qualification thresholds.

**Acceptance Criteria**: See AC-10 through AC-13.

---

### WP-5: Regulatory Accuracy (investFlorida.ai + str_simulation)
**Issues**: HI-3 (Miami resort tax), HI-4 (narrative contradiction), MD-1 (evidence confidence)
**Priority**: Must-have (HI-3, HI-4); Should-have (MD-1)

Changes required:
- `str_simulation`: Build a `TaxRateProvider` that resolves STR/lodging tax rates via external API (e.g., Avalara MyLodgeTax, Zip-Tax). `calculate_str_tax()` must use the `city`/`county`/`zip_code` fields already on `STRTaxRequest` to query the provider. Cache with 30-day TTL. Fallback to current defaults when API unavailable. No hardcoded city rates -- must scale to any US jurisdiction.
- Compliance narrative generation: When min-stay restriction is detected in HOA analysis, ensure the narrative reflects it rather than stating "No minimum stay requirement documented."
- Evidence confidence scoring: Replace static 30% values with actual confidence outputs from the LLM analysis, or display "Unscored" when genuine confidence cannot be determined.

**Acceptance Criteria**: See AC-14 through AC-16.

---

## Acceptance Criteria

| ID | Criterion | Priority | Work Package |
|---|---|---|---|
| AC-1 | When `minimum_length_of_stay > 1`, projected occupancy decreases by a research-backed penalty (target: ~3-5pp per additional night above 1, capped). | Must-have | WP-1 |
| AC-2 | When `minimum_length_of_stay > 1`, projected ADR decreases (target: ~2% per additional night above 1, capped at -8%). | Must-have | WP-1 |
| AC-3 | ADR and occupancy cannot both exceed the 75th percentile of comp data simultaneously. When one is top-quartile, the other is dampened toward median. | Must-have | WP-1 |
| AC-4 | Scenario optimistic case applies higher ADR with dampened occupancy, OR higher occupancy with dampened ADR -- not both at maximum. | Must-have | WP-1 |
| AC-5 | In the scenario comparison table, management fee, STR tax, and OTA commission differ across columns proportionally to each scenario's revenue. | Must-have | WP-2 |
| AC-6 | Conservative scenario shows lower variable costs than base; optimistic shows higher. The difference is proportional to the revenue difference. | Must-have | WP-2 |
| AC-7 | When overall verdict is NO-GO, the deal-breaker banner renders with at least one deal-breaker entry describing why. | Must-have | WP-3 |
| AC-8 | When overall verdict is NO-GO, no individual viability gate shows a green PASS checkmark. Gates that passed individually show amber with "overall NO-GO" context. | Must-have | WP-3 |
| AC-9 | Deal-breaker entries are generated for profitability failures (S_profit < 30, DSCR < 1.0, negative CoC) in addition to regulatory failures. | Must-have | WP-3 |
| AC-10 | Deal Structure section displays assumed interest rate and loan term (e.g., "7.0% / 30-year fixed"). | Must-have | WP-4 |
| AC-11 | Default management fee is 18% (not 20%) with code comment citing market basis. | Must-have | WP-4 |
| AC-12 | DSCR between 1.0-1.25x is labeled "Below Lender Minimum" (not "Thin"). | Should-have | WP-4 |
| AC-13 | DSCR section includes lending threshold context: 1.0x breakeven, 1.20x standard minimum, 1.25x preferred -- showing which bucket the property falls into. | Should-have | WP-4 |
| AC-14 | STR tax for Miami properties includes city resort tax (2%), showing ~13% total instead of ~12%. Tax rates resolved via external API, not hardcoded. Works for any US jurisdiction. | Must-have | WP-5 |
| AC-15 | When min-stay restriction is detected, regulatory narrative acknowledges it (does not state "No minimum stay requirement documented"). | Must-have | WP-5 |
| AC-16 | Evidence confidence scores are genuine outputs from analysis or display "Unscored" -- no static 30% placeholders. | Should-have | WP-5 |

**Summary**: 11 Must-have, 3 Should-have, 0 Nice-to-have.

---

## Edge Cases & Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Min-stay penalty values are wrong for some property types (resort vs urban) | High | Calibrate against 20+ properties with known min-stay restrictions. Use comp data to derive penalty rather than fixed formula. |
| ADR-OCC coupling is too aggressive, collapsing revenue projections | High | Use configurable dampening factor. Start with gentle coupling (75th percentile cap). Validate against known comp revenue ranges. |
| Changing management fee default from 20% to 18% breaks existing saved reports | Low | Reports are generated fresh each time. No saved state to break. Document the change in report metadata. |
| City tax lookup table becomes stale as municipalities change rates | Medium | Use API as primary source, hardcoded table as fallback only. Add timestamp to tax data source. Review quarterly. |
| deal_breakers list population creates false-positive deal-breakers on marginal properties | Medium | Only populate for clear threshold violations (DSCR < 1.0, CoC < 0%, S_overall < 50). Don't flag "thin" metrics as deal-breakers. |
| str_simulation API changes break investFlorida.ai pipeline | Medium | Both repos are under our control. Coordinate API contract changes. Add integration test that runs full pipeline. |

---

## Success Metrics

- **Scenario fidelity**: Variable costs differ across scenarios by at least the percentage proportional to revenue differences (within 2% tolerance).
- **Min-stay impact**: Properties with min-stay > 1 show measurably lower occupancy and ADR vs. identical properties with no restriction.
- **Risk consistency**: Zero instances of green PASS gates on NO-GO properties across 20-property validation run.
- **Financial transparency**: Interest rate and loan term visible in 100% of generated reports.
- **Tax accuracy**: Miami properties show >= 13% combined STR tax rate.
- **Validation target (Investor recommendation)**: Run 10 property analyses against manual agent analyses; key metrics (NOI, cash flow, cap rate) within 10% of manual calculation.

---

## Rollout Notes

- **No feature flags needed** -- these are accuracy corrections, not new features. All changes apply to every report going forward.
- **No migration needed** -- reports are generated fresh. No persisted state to update.
- **Validation run required** before marking sprint complete: generate reports for 10+ diverse properties (different cities, min-stay rules, property types) and verify each AC.
- **str_simulation changes should be deployed before investFlorida.ai changes** -- the pipeline calls the API, so API must handle min-stay penalty and ADR-OCC coupling before the client sends the parameters.
- WP-1 and WP-2 can proceed in parallel (different code areas). WP-3 is independent. WP-4 and WP-5 are independent of each other and of WP-1/2/3.
- **Estimated duration**: 2-3 weeks (aligns with CEO estimate).
