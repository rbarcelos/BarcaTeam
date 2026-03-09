# Engineer Verification: InvestmentContext Audit Findings

**Date**: 2026-03-09
**Author**: Senior Engineer Agent
**Repo**: `investFlorida.ai`
**PM Prioritization**: `docs/triage/pm_prioritization.md`

---

## Context

Verified 6 audit findings against actual code in `src/` of `investFlorida.ai`. Key files:
- `src/reports/report_generator.py` (796 lines)
- `src/pipeline/property_analyzer.py` (8940 lines)
- `src/models/investment_context.py` (2719 lines)
- `src/services/analyzers/*.py` (6 analyzer files)
- `src/utils/context_helpers.py`
- `src/reports/strategies/base.py`

---

## Finding 1: Unsafe Attribute Chains

**Verdict: CONFIRMED — 2 real crash paths, 1 partial**

### 1a. `context.data.property.address` — unguarded (CONFIRMED CRASH)

**File**: `src/reports/report_generator.py`, line 614

```python
logger.info(f"Generating report for: {context.data.property.address}")
```

This is the **first line** of `ReportGenerator.generate()`. There is no null check on `context.data.property` before this call. If `context.data.property` is `None`, this raises `AttributeError` before any report generation begins. The same pattern appears at line 787:

```python
address = context.data.property.address or "property"
```

Line 787 also has no guard on `context.data.property`, though the `or "property"` fallback handles a `None` address value — it does not handle a `None` property object.

**Note**: The audit described `context.data.compliance.str_compatibility` and the `financials.scenarios.base.adr.value` chain as unguarded. The code has partially addressed these:

- `base.adr.value` (line 286): Safe — the function returns `None` early at line 216 if `base is None`, and `base.adr` is declared `Metric` (non-optional) in `ScenarioCase`, so `.value` is always present when `base` exists.
- `context.data.financials.scenarios` (line 214): Partially guarded. The expression `context.data.financials.scenarios.base if context.data.financials.scenarios else None` is safe only because `context.data.financials` is confirmed non-None by the earlier check at line 185. However, this guard pattern (checking `.financials` in one place, `.scenarios` in another) is fragile and not consistent.
- `compliance.str_compatibility` (regulatory_tab_analyzer.py line 106): Guarded — `str_compat = compliance.str_compatibility if compliance else None`.

### 1b. `context.data.financials.scenarios` — inconsistent guarding (CONFIRMED)

**File**: `src/reports/report_generator.py`, lines 214 vs 699

```python
# Line 214 — financials guard missing (inside a function that already checks financials at line 185, so indirect)
base = context.data.financials.scenarios.base if context.data.financials.scenarios else None

# Line 699 — correct double-guard
base = context.data.financials.scenarios.base if (context.data.financials and context.data.financials.scenarios) else None
```

The inconsistency means that at line 214, if `context.data.financials` is somehow `None` despite line 185's check (e.g., due to code path divergence), it would crash with `AttributeError: 'NoneType' object has no attribute 'scenarios'`.

### Summary of Finding 1

| Location | Code | Risk | Confirmed? |
|---|---|---|---|
| `report_generator.py:614` | `context.data.property.address` | AttributeError crash | YES |
| `report_generator.py:787` | `context.data.property.address or "property"` | AttributeError crash | YES |
| `report_generator.py:214` | `context.data.financials.scenarios.base if context.data.financials.scenarios` | Fragile indirect guard | PARTIAL |
| `report_generator.py:286` | `base.adr.value` | Safe — base is None-checked above | NO |
| `regulatory_tab_analyzer.py:106` | `compliance.str_compatibility if compliance` | Guarded | NO |

---

## Finding 2: Data Gaps — NaN/Crash

**Verdict: CONFIRMED — 2 real crash paths, 1 logic error, 1 overstatement**

### 2a. `analysis.adr_baseline['monthly_factors']` — line 4092 (CONFIRMED, intentional ValueError)

**File**: `src/pipeline/property_analyzer.py`, lines 4092–4097

```python
if not analysis.adr_baseline or not analysis.adr_baseline.get('monthly_factors'):
    raise ValueError(
        "[PropertyAnalyzer._calculate_scenarios] monthly_factors missing from adr_baseline. "
        "Server requires monthly_distributions for /str/project (Issue #869)."
    )
monthly_factors = analysis.adr_baseline['monthly_factors']
```

The ValueError is intentional — it enforces a hard requirement from Issue #869. However, this is a crash path that surfaces to users as an unhandled exception. The audit finding is confirmed: missing `monthly_factors` from an API response causes a crash. The question is whether the crash is caught and handled gracefully in the calling code. If not, users see a 500 error instead of a degraded report.

### 2b. `analysis.property_data.price * 0.25` when price is 0 — line 6447 (CONFIRMED, NaN risk)

**File**: `src/pipeline/property_analyzer.py`, lines 6447–6448

```python
cash_invested = analysis.property_data.price * 0.25  # 25% down
```

If `analysis.property_data.price` is `0` (which is a valid sentinel for "price unknown"), this sets `cash_invested = 0`. Any downstream division by `cash_invested` (e.g., cash-on-cash = annual_cashflow / cash_invested) would produce `ZeroDivisionError` or `inf`. No guard is present here.

### 2c. 5-year projection with missing `base_case` fields — lines 5023–5025 (CONFIRMED, silent NaN)

**File**: `src/pipeline/property_analyzer.py`, lines 5023–5025

```python
five_year_projection = self._fetch_investment_projection(
    base_adr=self._get_metric_value(base_case.average_adr) if hasattr(base_case, 'average_adr') else 0.0,
    base_occupancy=self._get_metric_value(base_case.average_occupancy) if hasattr(base_case, 'average_occupancy') else 0.0,
    base_operating_costs=self._get_metric_value(base_case.annual_operating_expenses),
```

If `base_case.average_adr` or `base_case.average_occupancy` are `None` (returning `0.0` via `_get_metric_value`), the 5-year projection uses `base_adr=0.0` and `base_occupancy=0.0`. This produces a silently wrong projection (zero revenue), not a crash. The `_get_metric_value` helper at line 926–941 handles `None` by returning `0.0`, so no exception, but the output is meaningless. Also note: `hasattr(base_case, 'average_adr')` checks attribute existence, not whether the value is non-None — the guard only prevents AttributeError, not the silent-zero issue.

### 2d. `_get_metric_value(base.net_cashflow) / 0.05` — line 7006 (OVERSTATEMENT)

**File**: `src/pipeline/property_analyzer.py`, line 7006

```python
reduction_needed = abs(self._get_metric_value(base.net_cashflow)) / 0.05 if self._get_metric_value(base.net_cashflow) < 0 else 0
```

The divisor is the constant `0.05` — this cannot be zero. There is no inf/nan risk from this line itself. The audit finding is an overstatement. However, if `base.net_cashflow` is itself `NaN` or `inf` (from upstream), it would propagate here. The root cause is upstream (Finding 2b), not this line.

### Additional instance not in the audit

**File**: `src/reports/report_generator.py`, line 239

```python
insurance_monthly = insurance_ho6_monthly + insurance_liability_monthly or (annual_opex * 0.10 / 12)
```

Due to Python operator precedence, this evaluates as `(insurance_ho6_monthly + insurance_liability_monthly) or (annual_opex * 0.10 / 12)`. If both insurance values are `0`, the sum is `0` (falsy), so the fallback `annual_opex * 0.10 / 12` is used — which is correct behavior. However, the expression is misleading and would silently use the fallback whenever either insurance value is `0` rather than missing. This is a logic error, not a crash.

---

## Finding 3: Inconsistent Field Naming

**Verdict: CONFIRMED — 2 of 4 pairs confirmed, 2 are nuanced**

### 3a. `property_tax` vs `property_taxes` — CONFIRMED

**File**: `src/reports/report_generator.py`, lines 153–154, 236

```python
# Line 153-154 in expense display name mapping
'property_tax': 'Property Tax',
'property_taxes': 'Property Tax',

# Line 236 — cascading get() workaround
property_tax_monthly = expense_breakdown.get('property_tax', 0) or expense_breakdown.get('property_taxes', 0) or (annual_opex * 0.15 / 12)
```

Both field names exist in the codebase simultaneously. The model (`investment_context.py`) uses `property_tax` internally (line 1088), but external data sources (expense breakdown from API) may use either. The cascading `.get()` at line 236 is a direct symptom of the naming inconsistency.

### 3b. `hoa_fees` vs `hoa` — CONFIRMED

**File**: `src/reports/report_generator.py`, line 240

```python
hoa_monthly = expense_breakdown.get('hoa_fees', 0) or expense_breakdown.get('hoa', 0) or 0
```

The model uses `hoa_fees` (line 1087: `'hoa_fees': ...`), but the API or builder may emit `hoa`. Same cascading `.get()` pattern.

### 3c. `hoa_community_name` vs `hoa` for HOA name — CONFIRMED (additional instance)

**File**: `src/services/analyzers/regulatory_tab_analyzer.py`, line 142

```python
'hoa_name': context.data.property.hoa_community_name if context.data.property else 'Unknown HOA',
```

`hoa_community_name` is the field on `PropertyData` (model line 336). Used consistently in the regulatory analyzer. No second name found for this field.

### 3d. `all_amenities` vs `amenities` — NUANCED (not a model inconsistency)

**File**: `src/models/investment_context.py` (via `property_data.py`)

`all_amenities` is a **computed property** on `PropertyData` (defined in `src/models/property_data.py`, line 427), not a stored field. The stored fields are `amenities`, `unit_amenities`, and `building_amenities`. The `all_amenities` property aggregates them. This is not a naming inconsistency — it is a correct architectural separation of stored vs computed data. However, inconsistent access patterns exist:

```python
# property_analyzer.py:225 — defensive dual access
amenities = getattr(property_data, 'all_amenities', None) or getattr(property_data, 'amenities', None)

# context_helpers.py:131 — same defensive pattern
all_amenities = prop.all_amenities if hasattr(prop, 'all_amenities') else (prop.amenities or [])
```

The defensive access is warranted for serialized-to-dict contexts where computed properties are lost, but it creates a maintenance smell. The actual issue is that report templates may receive either raw or deserialized contexts.

### 3e. `rentals_listings` vs `sample_listings` — NOT CONFIRMED

`sample_listings` is the canonical field name in the model (`investment_context.py:1805`). No uses of `rentals_listings` were found anywhere in the codebase. The audit finding is incorrect or refers to a historical field already removed.

---

## Finding 4: Calculations in Wrong Layer

**Verdict: CONFIRMED — matches PM assessment (add to #902)**

### 4a. `Metric.value` extraction in analyzers

Two helper functions perform `Metric.value` extraction inside the analyzer layer:

**File**: `src/services/analyzers/regulatory_tab_analyzer.py`, line 165

```python
return metric.value if hasattr(metric, 'value') else metric
```

**File**: `src/services/analyzers/revenue_tab_analyzer.py`, line 95

```python
return metric.value if hasattr(metric, 'value') else metric if metric else 0
```

These duplicate the pattern in `property_analyzer.py`'s `_get_metric_value` static method (line 926) and in `report_generator.py`'s local lambda (line 516, 661). Four separate implementations of the same logic. `Metric.value` extraction should be a single utility on the `Metric` class itself (e.g., `Metric.extract(value)`).

### 4b. HOA score conversion in `regulatory_tab_analyzer.py` — CONFIRMED

**File**: `src/services/analyzers/regulatory_tab_analyzer.py`, lines 112–113

```python
hoa_score_raw = str_compat.hoa_score if str_compat else 5.0  # Default to 5 (unknown)
hoa_score_display = int(hoa_score_raw * 10)  # 0-10 → 0-100
```

The `STRCompatibilityScore.hoa_score` field is stored on a 0–10 scale (confirmed by model in `compatibility_models.py:338`). The scale conversion (`* 10`) is done in the analyzer layer rather than as a model property. Any other consumer that reads `hoa_score` from `str_compat` directly will get the raw 0–10 value without conversion. This is a calculation-in-wrong-layer bug.

### 4c. Expense breakdown cascading `.get()` in `report_generator.py` — CONFIRMED

**File**: `src/reports/report_generator.py`, lines 236–243

```python
property_tax_monthly = expense_breakdown.get('property_tax', 0) or expense_breakdown.get('property_taxes', 0) or (annual_opex * 0.15 / 12)
hoa_monthly = expense_breakdown.get('hoa_fees', 0) or expense_breakdown.get('hoa', 0) or 0
management_monthly = expense_breakdown.get('management_fee', 0) or expense_breakdown.get('management', 0) or (annual_opex * 0.25 / 12)
```

Presentation-layer code (`ReportGenerator`) is performing expense normalization logic — trying multiple field names and computing proportional fallbacks. This belongs in the financial model or a dedicated expense accessor.

---

## Finding 5: Deprecated Fields Still Accessed

**Verdict: CONFIRMED — 3 deprecated fields, all still actively read**

### 5a. `property_intelligence` — CONFIRMED DEPRECATED, still read

**Model declaration** (`investment_context.py:266`):
```python
property_intelligence: Optional[dict] = None  # DEPRECATED — migrating to typed fields below
```

**Active read** (`report_generator.py:114`):
```python
result = dict(context.data.property_intelligence) if context.data.property_intelligence else {}
```

**Active read** (`regulatory_tab_analyzer.py:172`):
```python
property_intel = context.data.property_intelligence if hasattr(context.data, 'property_intelligence') else None
```

The model comment notes "migrating to typed fields below," but the migration is incomplete. `report_generator.py` uses the deprecated dict as a **fallback base** and overlays typed fields on top (line 114–130). This means if the deprecated dict is eventually removed, the overlay logic breaks. The `regulatory_tab_analyzer.py` access at line 172 uses `hasattr` as a defensive guard — appropriate for a deprecated field but confirms the migration is in progress, not done.

### 5b. `market_intelligence` — CONFIRMED DEPRECATED, still read

**Model declaration** (`investment_context.py:268`):
```python
market_intelligence: Optional[dict] = None  # DEPRECATED — market data now in typed context.data.market
```

**Active reads**:
- `report_generator.py:730` — `context.data.market_intelligence if hasattr(context.data, 'market_intelligence') and context.data.market_intelligence else {}`
- `regulatory_tab_analyzer.py:199, 253` — reads `context.data.market_intelligence`
- `revenue_tab_analyzer.py:135` — reads `context.data.market_intelligence`

All reads use `hasattr` guards, but the deprecated dict is still the data source for the market tab analyzers.

### 5c. `hoa_restrictions` — CONFIRMED DEPRECATED, still read

**Model declaration** (`investment_context.py:2062`):
```python
# HOA restrictions (DEPRECATED - use hoa_info instead)
hoa_restrictions: Optional['HOARestrictions'] = None
```

**Active reads**:
- `regulatory_tab_analyzer.py:116` — `compliance.hoa_restrictions.min_rental_days if compliance and compliance.hoa_restrictions else None`
- `regulatory_tab_analyzer.py:146` — `compliance.hoa_restrictions.rental_restrictions if compliance and compliance.hoa_restrictions else []`
- `tab_content_generator.py:241–242` — reads `compliance.hoa_restrictions.min_rental_days` and `.rental_restrictions`
- `context_helpers.py:59–61` — `context.data.compliance.hoa_restrictions.min_rental_days`

All accesses include null guards on `compliance.hoa_restrictions`, so no crash risk. But the canonical replacement `compliance.hoa_info` (`HOAInfo` from `compatibility_models.py`) exists and is not used in these paths. Five access sites need migration.

---

## Finding 6: No Pre-Render Validation

**Verdict: PARTIALLY CONFIRMED — validation exists in strategies/base.py but NOT in ReportGenerator.generate()**

### The architecture has two report generation paths:

**Path A — `ReportGenerator.generate()` (standalone, used by pipeline):**

`src/reports/report_generator.py`, line 604–614

```python
def generate(self, context: InvestmentContext) -> str:
    logger.info(f"Generating report for: {context.data.property.address}")  # No validation gate
```

**No validation gate.** No `ProcessingState.is_complete()` check, no `validate_context()` call, no guard on `context.data.property` before line 614. The pipeline's `build_context()` method does run `validate_and_log()` at line 8190–8196, but that checks financial consistency, not structural completeness.

**Path B — `ReportStrategy.generate()` (via strategies/base.py):**

`src/reports/strategies/base.py`, lines 147–167

```python
if hasattr(context, 'processing_state') and context.processing_state:
    if not context.processing_state.is_complete():
        pending = context.processing_state.get_pending()
        logger.warning(f"... Pending steps: {', '.join(pending)}. Report will be generated but may be missing data.")
```

This path **does** check `ProcessingState.is_complete()` — but the check only **warns**, it does not block generation. The validation service is also called (`validate_context()`) but exceptions are caught and swallowed (`except Exception as e: logger.warning(...)`), so a broken validation service silently allows invalid contexts through.

### Summary

The audit finding is confirmed for `ReportGenerator.generate()` (Path A). The strategies path has a validation gate but it is advisory-only. `ProcessingState` exists and is populated by the pipeline but:
1. Not checked in the most commonly used `ReportGenerator` path
2. In the strategies path, the check logs a warning but does not block generation
3. The `validate_context()` call in `base.py` can silently fail
4. The 14 scattered `hasattr/getattr` calls in `report_generator.py` are symptoms of the missing gate

---

## Draft GitHub Issues

---

### Issue: Guard against null/missing data in report pipeline to prevent crashes and NaN

**Labels**: `type:bug`, `priority:P0`, `domain:reporting`, `domain:financials`
**Findings covered**: #1, #2

**Body**:

## Context
**Capability**: `defensive-data-access`
**Stream**: Core report pipeline
**Related Issues**: #868 (property fields null), #883 (_context_to_dict refactor)

## Description

Multiple locations in the report pipeline assume data is present and crash or produce silent NaN when it is not. Two confirmed crash paths exist in `ReportGenerator.generate()` before any report content is generated.

## Crash Paths (P0 — fix immediately)

### 1. Unguarded `context.data.property` at report entry point

**File**: `src/reports/report_generator.py`, lines 614 and 787

```python
# Line 614 — first line of generate(), no null check
logger.info(f"Generating report for: {context.data.property.address}")

# Line 787 — filename generation, no null check on property object
address = context.data.property.address or "property"
```

If `context.data.property` is `None`, this raises `AttributeError` before any rendering begins.

**Fix**: Add a guard at the top of `generate()` before line 614:
```python
if not context.data.property:
    raise ValueError("Cannot generate report: context.data.property is None")
```

### 2. `price = 0` causes downstream ZeroDivisionError

**File**: `src/pipeline/property_analyzer.py`, line 6447

```python
cash_invested = analysis.property_data.price * 0.25  # 25% down
```

When `price` is `0` (sentinel for unknown price), `cash_invested` is `0`. Any downstream calculation dividing by `cash_invested` (e.g., cash-on-cash return) produces `ZeroDivisionError` or `inf`. No guard is present.

**Fix**: Guard before this line:
```python
if not analysis.property_data.price:
    self.logger.warning("price is 0 — skipping cash-on-cash calculations")
    cash_invested = None
```
Then guard all downstream divisions by `cash_invested`.

## Silent NaN Paths (high risk, fix in same PR)

### 3. 5-year projection uses silent zero when `average_adr`/`average_occupancy` missing

**File**: `src/pipeline/property_analyzer.py`, lines 5023–5025

```python
base_adr=self._get_metric_value(base_case.average_adr) if hasattr(base_case, 'average_adr') else 0.0,
base_occupancy=self._get_metric_value(base_case.average_occupancy) if hasattr(base_case, 'average_occupancy') else 0.0,
```

`_get_metric_value` returns `0.0` for `None` values. A 5-year projection with `adr=0` and `occupancy=0` produces zero revenue silently. Should validate these inputs are non-zero before calling `_fetch_investment_projection`.

### 4. `ValueError` from missing `monthly_factors` is not caught gracefully

**File**: `src/pipeline/property_analyzer.py`, lines 4092–4097

The `ValueError` on missing `monthly_factors` is intentional (Issue #869 requirement) but propagates to users as a 500 error. The calling code should catch this and return a partial result or user-facing error message.

## File Hints

| File | Change |
|---|---|
| `src/reports/report_generator.py:614` | Add null guard on `context.data.property` |
| `src/reports/report_generator.py:787` | Add null guard on `context.data.property` |
| `src/pipeline/property_analyzer.py:6447` | Guard against `price == 0` |
| `src/pipeline/property_analyzer.py:5023` | Validate `adr`/`occupancy` non-zero before projection |
| `src/pipeline/property_analyzer.py:4092` | Catch `ValueError` and return graceful error to caller |

## Checklist
- [ ] Implementation complete
- [ ] Unit tests added (test with None property, price=0, missing monthly_factors)
- [ ] Regression tests pass
- [ ] Lint passes

## Definition of Done
- [ ] All 5 hot spots addressed
- [ ] No AttributeError or unhandled ValueError propagates to the caller of `generate()`
- [ ] Downstream ZeroDivisionError from `price=0` is impossible
- [ ] PR opened and linked to this issue

---

### Issue: Add pre-render validation gate to reject incomplete InvestmentContext

**Labels**: `type:enhancement`, `priority:P1`, `domain:reporting`, `domain:architecture`
**Findings covered**: #6

**Body**:

## Context
**Capability**: `pre-render-validation`
**Stream**: Report generation architecture
**Related Issues**: Above P0 crash fix issue, #590 (report validation service)

## Description

`ReportGenerator.generate()` has no validation gate before rendering. The strategies path (`ReportStrategy.generate()` in `src/reports/strategies/base.py`) does check `ProcessingState.is_complete()`, but only logs a warning — it does not block generation. Both paths allow templates to render with incomplete or None data, producing either template errors or silently empty report sections.

## Current State

- `ProcessingState` class exists (`investment_context.py:2665`) and is populated by the pipeline
- `ReportStrategy.generate()` checks it but continues anyway (advisory only)
- `ReportGenerator.generate()` (the primary path) does **not** check it
- 14 `hasattr`/`getattr` calls in `report_generator.py` are workarounds for the missing gate
- `validate_and_log()` runs at pipeline end (line 8190) but checks financial consistency, not structural completeness

## Required Changes

### 1. Wire `ProcessingState.is_complete()` into `ReportGenerator.generate()`

```python
def generate(self, context: InvestmentContext) -> str:
    if not context.data.property:
        raise ValueError("Cannot generate report: context.data.property is None")
    if context.processing_state and not context.processing_state.is_complete():
        pending = context.processing_state.get_pending()
        raise ValueError(f"Cannot generate report: processing incomplete. Pending: {pending}")
    ...
```

### 2. Make the strategies path gate hard (not advisory)

In `src/reports/strategies/base.py:148`, change the `logger.warning` to raise `ValueError` (consistent with ReportGenerator).

### 3. Define required-field invariants

Add a `validate_for_rendering()` method to `InvestmentContext` (or `InvestmentData`) that checks:
- `context.data.property` is not None
- `context.data.financials` is not None
- `context.data.financials.scenarios.base` is not None
- `context.data.property.address` is not empty string

This method is called by both report paths.

### 4. Remove scattered `hasattr` workarounds

Once the gate is in place, the 14 `hasattr`/`getattr` calls in `report_generator.py` that work around missing required data can be simplified or removed.

## File Hints

| File | Change |
|---|---|
| `src/reports/report_generator.py:604` | Add required-fields check before rendering |
| `src/reports/strategies/base.py:148` | Make `is_complete()` check hard (raise, not warn) |
| `src/models/investment_context.py` | Add `validate_for_rendering()` method |
| `src/reports/report_generator.py:139–730` | Simplify/remove redundant `hasattr` guards after gate is in place |

## Checklist
- [ ] Implementation complete
- [ ] Unit tests: generate() raises ValueError on incomplete context
- [ ] Unit tests: generate() raises ValueError on None property
- [ ] Integration test: full pipeline with mocked missing fields
- [ ] Lint passes

## Definition of Done
- [ ] Both report paths enforce the same gate
- [ ] Gate raises, not warns
- [ ] PR opened and linked

---

### Issue: Standardize inconsistent field names in InvestmentContext expense breakdown

**Labels**: `type:tech-debt`, `priority:P2`, `domain:architecture`
**Findings covered**: #3

**Body**:

## Context
**Capability**: `field-naming-standardization`
**Stream**: Data model / report layer
**Related Issues**: #883 (_context_to_dict refactor)

## Description

The expense breakdown dict emitted by the pipeline and consumed by the report layer uses inconsistent field names. The report generator works around this with cascading `.get()` calls using multiple alternative names. This creates silent bugs when only one name is populated and the wrong one is checked.

## Confirmed Naming Inconsistencies

### 1. `property_tax` vs `property_taxes`

**Report layer** (`report_generator.py:236`):
```python
property_tax_monthly = expense_breakdown.get('property_tax', 0) or expense_breakdown.get('property_taxes', 0) or ...
```
Also, both names are in the display label map (lines 153–154). The model's internal method (`investment_context.py:1088`) uses `property_tax`.

**Canonical name**: `property_tax` (matches model).

### 2. `hoa_fees` vs `hoa`

**Report layer** (`report_generator.py:240`):
```python
hoa_monthly = expense_breakdown.get('hoa_fees', 0) or expense_breakdown.get('hoa', 0) or 0
```
The model method (`investment_context.py:1087`) emits `hoa_fees`.

**Canonical name**: `hoa_fees` (matches model).

### 3. `management_fee` vs `management`

**Report layer** (`report_generator.py:241`):
```python
management_monthly = expense_breakdown.get('management_fee', 0) or expense_breakdown.get('management', 0) or ...
```

**Canonical name**: `management_fee` (matches model method key pattern).

## Approach

1. Audit all places that produce or consume the expense breakdown dict (pipeline builder, analyzers, templates)
2. Choose canonical names (above) and update all producers
3. Remove cascading `.get()` workarounds in `report_generator.py:236–243` — replace with single `.get()` per field
4. Add a test that asserts the expense breakdown schema (prevents regression)
5. Coordinate with #883 (`_context_to_dict` refactor) — the canonical names must be consistent in both the typed model and the dict representation

## Note on `all_amenities`

The `all_amenities` name is a computed property on `PropertyData` (not a stored field). It is not an inconsistency — it is an aggregation of `amenities`, `unit_amenities`, and `building_amenities`. The defensive `getattr(property_data, 'all_amenities', None) or getattr(property_data, 'amenities', None)` in `property_analyzer.py:225` exists because serialized dicts lose computed properties. This is tracked separately and addressed by the `_context_to_dict` refactor (#883).

## File Hints

| File | Change |
|---|---|
| `src/reports/report_generator.py:236–243` | Remove cascading `.get()`, use canonical names |
| `src/pipeline/property_analyzer.py` | Audit expense breakdown dict production |
| `src/models/investment_context.py` | Ensure `get_expense_breakdown()` emits canonical names |
| `src/tests/` | Add schema test for expense breakdown dict |

## Checklist
- [ ] Canonical names chosen and documented
- [ ] All producers updated to emit canonical names only
- [ ] All consumers updated to use single `.get()` per field
- [ ] Test asserting expense breakdown schema
- [ ] PR opened and linked to #883

---

### Comment for existing issue #902: Specific Metric.value extraction instances to add as sub-tasks

**Labels**: (use existing labels on #902)
**Findings covered**: #4

**Body** (intended as a comment on #902, not a new issue):

## Additional Evidence for #902

Code audit (2026-03-09) identified 4 separate implementations of `Metric.value` extraction across the codebase. Adding these as concrete sub-tasks for #902.

### Duplicate `Metric.value` extraction implementations

| Location | Code |
|---|---|
| `property_analyzer.py:926–941` | `_get_metric_value()` static method — the canonical one |
| `regulatory_tab_analyzer.py:165` | `return metric.value if hasattr(metric, 'value') else metric` |
| `revenue_tab_analyzer.py:95` | `return metric.value if hasattr(metric, 'value') else metric if metric else 0` |
| `report_generator.py:516, 661` | Local lambda `lambda m: m.value if hasattr(m, 'value') else m` |

**Suggested fix**: Add a `Metric.extract(value)` class method or module-level utility in `src/models/metric.py`:
```python
@staticmethod
def extract(value) -> float:
    """Extract numeric value from Metric or raw float. Returns 0.0 for None."""
    if hasattr(value, 'value'):
        return value.value
    return float(value) if value is not None else 0.0
```
Then replace all 4 implementations with calls to this utility.

### HOA score scale conversion in analyzer layer

**File**: `src/services/analyzers/regulatory_tab_analyzer.py:112–113`

```python
hoa_score_raw = str_compat.hoa_score if str_compat else 5.0
hoa_score_display = int(hoa_score_raw * 10)  # 0-10 → 0-100
```

The `STRCompatibilityScore.hoa_score` is stored 0–10. The `* 10` conversion is done in the analyzer. Any other consumer reading `str_compat.hoa_score` directly gets the raw 0–10 value (inconsistent). Should be a model property: `STRCompatibilityScore.hoa_score_display` that returns the 0–100 value.

### Expense proportional fallbacks in report layer

**File**: `src/reports/report_generator.py:236–243`

Lines 242–243 compute `maintenance_monthly` and `utilities_monthly` as proportions of `annual_opex` when the actual value is missing. These are business logic calculations (15% of opex = maintenance, 10% = utilities) that belong in the financial model, not the report generator.

---

### Issue: Remove deprecated field access (property_intelligence, market_intelligence, hoa_restrictions)

**Labels**: `type:tech-debt`, `priority:P3`, `domain:architecture`
**Findings covered**: #5

**Body**:

## Context
**Capability**: `deprecated-field-cleanup`
**Stream**: Data model cleanup
**Related Issues**: data-arch-006 (`flatten-property-intelligence` proposal), #842 (property_intelligence migration)

## Description

Three fields marked `DEPRECATED` in `InvestmentData` are still actively accessed across multiple files. This creates a latent risk: if any of these fields is removed during the data-arch-006 migration, the code silently falls back to empty data rather than failing visibly.

## Deprecated Fields with Active Reads

### 1. `context.data.property_intelligence` (DEPRECATED since Issue #842)

**Model**: `investment_context.py:266`
```python
property_intelligence: Optional[dict] = None  # DEPRECATED — migrating to typed fields below
```

**Active reads**:
- `report_generator.py:114` — used as fallback base dict, overlaid with typed fields
- `regulatory_tab_analyzer.py:172` — `hasattr` guarded read for prompt context

**Canonical replacement**: Use typed fields (`context.data.adr_baseline`, `context.data.str_comparables_data`, `context.data.sale_history_data`, `context.data.property_valuation`). `report_generator.py:116–130` already overlays these — the `property_intelligence` fallback at line 114 can be removed once all callers are migrated.

### 2. `context.data.market_intelligence` (DEPRECATED since Issue #842 Phase 4)

**Model**: `investment_context.py:268`
```python
market_intelligence: Optional[dict] = None  # DEPRECATED — market data now in typed context.data.market
```

**Active reads**:
- `report_generator.py:730` — used as `market_intel` template variable
- `regulatory_tab_analyzer.py:199, 253` — used for LLM prompt context
- `revenue_tab_analyzer.py:135` — used for LLM prompt context

**Canonical replacement**: `context.data.market` (typed `MarketData` object). All 4 read sites use `hasattr` guards, so they degrade gracefully, but they should migrate to `context.data.market`.

### 3. `compliance.hoa_restrictions` (DEPRECATED — use `hoa_info`)

**Model**: `investment_context.py:2062`
```python
# HOA restrictions (DEPRECATED - use hoa_info instead)
hoa_restrictions: Optional['HOARestrictions'] = None
```

**Active reads** (all with null guards):
- `regulatory_tab_analyzer.py:116` — `.min_rental_days`
- `regulatory_tab_analyzer.py:146` — `.rental_restrictions`
- `tab_content_generator.py:241–242` — `.min_rental_days`, `.rental_restrictions`
- `context_helpers.py:59–61` — `.min_rental_days`

**Canonical replacement**: `compliance.hoa_info` (from `HOAInfo` in `compatibility_models.py`). Verify that `HOAInfo` exposes `min_rental_days` and `rental_restrictions` equivalents before migrating.

## Suggested Approach

1. Verify `HOAInfo` has equivalent fields to `HOARestrictions` (or add them)
2. Migrate 5 `hoa_restrictions` access sites to `hoa_info`
3. Migrate `market_intelligence` reads to `context.data.market` (4 sites)
4. Remove `property_intelligence` fallback in `report_generator.py:114` (overlay logic remains)
5. Coordinate with data-arch-006 — do this work as part of or just before the flatten migration

## File Hints

| File | Change |
|---|---|
| `src/reports/report_generator.py:114` | Remove `property_intelligence` fallback, keep overlays |
| `src/reports/report_generator.py:730` | Replace `market_intelligence` with `context.data.market` |
| `src/services/analyzers/regulatory_tab_analyzer.py:116,146,172,199,253` | Migrate to canonical fields |
| `src/services/analyzers/revenue_tab_analyzer.py:135` | Migrate `market_intelligence` to `context.data.market` |
| `src/services/tab_content_generator.py:241–242` | Migrate `hoa_restrictions` to `hoa_info` |
| `src/utils/context_helpers.py:59–61` | Migrate `hoa_restrictions` to `hoa_info` |

## Checklist
- [ ] HOAInfo field equivalence verified (or fields added)
- [ ] All deprecated field reads removed
- [ ] Tests pass after removal
- [ ] PR opened and linked to data-arch-006 milestone

---

## Verification Summary

| Finding | Status | Severity Change | Key Evidence |
|---|---|---|---|
| 1: Unsafe attribute chains | CONFIRMED (2 of 5 instances) | Downscoped — only 2 real crash paths remain unguarded | `report_generator.py:614,787` — unguarded `context.data.property.address` |
| 2: Data gaps / NaN | CONFIRMED (3 of 4 instances) | Finding 2d (net_cashflow / 0.05) is NOT a zero-division risk | `property_analyzer.py:6447` (price*0.25), `5023–5025` (silent zero in projection), `4092–4097` (unhandled ValueError) |
| 3: Inconsistent field naming | CONFIRMED (2 of 4 pairs fully, 1 nuanced, 1 not found) | `rentals_listings` not in codebase — remove from scope | `report_generator.py:236–243` cascading `.get()` confirms `property_tax` and `hoa_fees` |
| 4: Calculations in wrong layer | CONFIRMED | Matches PM assessment | 4 duplicate `Metric.value` extractors; HOA score conversion in analyzer |
| 5: Deprecated fields | CONFIRMED | Accurate — all 3 fields are deprecated and still read | `investment_context.py:266,268,2062` deprecation comments; 10+ active read sites |
| 6: No pre-render validation | PARTIALLY CONFIRMED | Processing state gate exists in strategies/base.py but is advisory and absent from main path | `report_generator.py:604–614` has no gate; `strategies/base.py:147–153` has advisory-only gate |

## Open Questions (for PM/Architect)

1. **Finding 2a (monthly_factors ValueError)**: Is the caller wrapping `_calculate_scenarios` in a try/except that degrades gracefully, or does the ValueError surface to the user? If the latter, this needs a user-facing error path.
2. **Finding 6 (validation gate)**: The PM brief asks "Is `ProcessingState.is_complete()` currently called anywhere before report generation?" — Confirmed: it is called in `strategies/base.py` but only the strategy path uses it, and it only warns. The primary `ReportGenerator` path has no gate.
3. **Finding 5 / data-arch-006**: Is the data-arch-006 migration imminent? If yes, Group E (deprecated field cleanup) should be folded into that work.
4. **Issue #868 status**: PM asked whether #868 is resolved. Finding 1 confirms `context.data.property` can still be None at report entry — if #868 was supposed to fix this, it did not address the `report_generator.py:614` call site.
