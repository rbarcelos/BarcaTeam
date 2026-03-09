# PM Prioritization: InvestmentContext Audit Findings

**Date**: 2026-03-08
**Repo**: `rbarcelo/investFlorida.ai`
**Author**: PM Agent

---

## 1. Duplicate Check Against Open Issues

### #902 "Architectural Improvements: Extract Business Logic from Templates"
- **Overlaps with Finding 4** (Calculations in wrong layer). Issue #902 likely covers the same concern: Metric.value extraction repeated 50+ times in templates, score conversions done in analyzers instead of models, and expense breakdown logic in the report generator instead of the financial model.
- **Finding 4 should NOT be filed as a new issue.** Instead, these specific examples should be added as evidence/sub-tasks to #902.

### #883 "Refactor _context_to_dict()"
- **Overlaps with Finding 3** (Inconsistent field naming) and **Finding 5** (Deprecated fields still accessed). The `_context_to_dict()` method is the bridge between the typed model and the template layer. Inconsistent field names and deprecated field access are likely symptoms of what #883 aims to fix.
- **Partial overlap with Finding 4** as well, since `_context_to_dict()` is where some calculation/transformation logic may be misplaced.
- **Findings 3 and 5 should reference #883** but may still warrant their own issues since the scope is different (naming standardization and deprecation cleanup are distinct from the refactoring of the dict conversion).

### #868 "Property fields always null"
- **Overlaps with Finding 2** (Data gaps). The "property fields always null" issue describes the same class of problem: fields that are expected to be populated but arrive as None, leading to downstream NaN or crashes.
- **Finding 2 is broader than #868.** Issue #868 appears focused on property fields specifically (address, year_built, etc.), while Finding 2 covers financial calculations that break on missing data. The property-specific gaps from Finding 2 should be linked to #868; the financial calculation guards deserve a separate issue.

### Existing doc context: `INVESTMENT_CONTEXT_CENTRALIZATION_PROPOSAL.md` and `.github/issue_investmentcontext_restructure.md`
- These documents describe a restructuring of InvestmentContext that, when completed, would address parts of Findings 3, 5, and 6. The `ProcessingState` class already implements a form of pre-render validation (Finding 6), but it is not enforced as a gate before template rendering.
- The `data-arch-006-flatten-property-intelligence.md` proposal directly addresses Finding 5 (deprecated `property_intelligence` dict).

---

## 2. Severity Assessment

| Finding | Severity | User Impact | Effort | Rationale |
|---|---|---|---|---|
| **1: Unsafe attribute chains** | **Critical (P0)** | Reports crash with unhandled exceptions on partial data. Users see 500 errors instead of a degraded report. | Medium | Many call sites across analyzers and report_generator.py. Each needs a null guard or safe accessor. Tedious but straightforward. |
| **2: Data gaps (NaN/crash)** | **Critical (P0)** | ValueError/NaN in financial projections produces either a crash or silently wrong numbers (e.g., infinite ROI). Both outcomes erode trust. | Medium | Requires defensive checks at ~5 known hot spots. Some already have partial guards. The financial-impact items (division by zero, missing ADR) are the highest risk. |
| **3: Inconsistent field naming** | **Medium (P2)** | No direct user crash, but creates maintenance burden and subtle bugs when one name is checked but the other is populated. Cascading `.get()` workarounds mask the problem. | Medium | Requires choosing canonical names, migrating all access sites, and adding backward-compat aliases during transition. |
| **4: Calculations in wrong layer** | **Medium (P2)** | No direct user impact today, but high maintenance cost. Every new template or analyzer must rediscover the same conversion patterns. Bug fixes must be applied in multiple places. | Large | 50+ call sites for Metric.value alone. Requires adding model properties/methods and updating all consumers. Best done alongside #902. |
| **5: Deprecated fields still accessed** | **Low (P3)** | No user impact as long as deprecated fields are still populated. Risk is that a future cleanup removes the deprecated data while code still reads it, causing silent data loss. | Small | grep for the 3 deprecated fields, replace with canonical accessors. Linked to data-arch-006 proposal. |
| **6: No pre-render validation** | **High (P1)** | Templates receive None for required sections, producing either TemplateUndefinedError (crash) or silently empty report sections. Users cannot tell if data is missing vs. genuinely zero. | Medium | Requires a validation gate before report rendering. The `ProcessingState.is_complete()` infrastructure exists but is not enforced. |

---

## 3. Recommended Issue Grouping

### Issue Group A: "Defensive data access -- prevent crashes on partial data" (NEW)
**Combines: Finding 1 + the crash-path items from Finding 2**

- Unsafe attribute chains (Finding 1)
- ValueError on missing `monthly_factors` (Finding 2, line 4092)
- Division by zero / NaN from missing `price`, `average_adr`, `average_occupancy`, `net_cashflow` (Finding 2)

**Rationale**: These are all the same class of problem -- code assumes data is present and crashes when it is not. A single issue with a checklist of hot spots is the right scope.

- **Labels**: `type:bug`, `priority:P0`, `domain:reporting`, `domain:financials`
- **Suggested title**: "Guard against null/missing data in report pipeline to prevent crashes and NaN"

### Issue Group B: "Pre-render validation gate" (NEW)
**Maps to: Finding 6**

- Add a required-fields check before template rendering
- Enforce `ProcessingState.is_complete()` or equivalent before calling report generation
- Replace scattered `hasattr()` checks with proper Optional typing

**Rationale**: This is a distinct architectural concern (adding a gate) rather than patching individual access sites. It prevents the class of bugs in Group A from recurring.

- **Labels**: `type:enhancement`, `priority:P1`, `domain:reporting`, `domain:architecture`
- **Suggested title**: "Add pre-render validation gate to reject incomplete InvestmentContext"

### Issue Group C: "Standardize field naming in InvestmentContext" (NEW, references #883)
**Maps to: Finding 3**

- Choose canonical names for the 4 identified pairs
- Migrate all access sites
- Add deprecation warnings on old names during transition
- Update `_context_to_dict()` (#883) to use canonical names

**Rationale**: Field naming is a standalone concern. It interacts with #883 but the scope (choosing names, migrating access) is distinct from refactoring the dict conversion method.

- **Labels**: `type:tech-debt`, `priority:P2`, `domain:architecture`
- **Suggested title**: "Standardize inconsistent field names (property_tax vs property_taxes, etc.)"

### Issue Group D: Add to existing #902
**Maps to: Finding 4**

- Add the specific examples (Metric.value extraction, HOA score conversion, expense breakdown, cap rate conversion, context cleaning) as sub-tasks or evidence to #902.

**Rationale**: #902 already covers this exact scope. Filing a duplicate wastes triage effort.

- **Labels**: (use existing labels on #902)
- **Action**: Comment on #902 with the 5 specific examples from Finding 4.

### Issue Group E: "Remove deprecated field access" (NEW, references data-arch-006)
**Maps to: Finding 5**

- Remove reads of `property_intelligence` dict in report_generator.py and context_helpers.py
- Remove reads of `market_intelligence` dict
- Replace `hoa_restrictions` access with `hoa_info` in context_helpers.py

**Rationale**: Small, self-contained cleanup. Low risk since canonical replacements already exist.

- **Labels**: `type:tech-debt`, `priority:P3`, `domain:architecture`
- **Suggested title**: "Remove deprecated field access (property_intelligence, market_intelligence, hoa_restrictions)"

---

## 4. Priority Order for Implementation

| Priority | Issue Group | Why This Order |
|---|---|---|
| **1st** | **Group A** (Defensive data access) P0 | Active crash paths in production. Users see errors or silently wrong numbers. Highest user impact, moderate effort. |
| **2nd** | **Group B** (Pre-render validation gate) P1 | Prevents the entire class of Group A bugs from recurring. Should follow immediately after Group A so that the defensive patches are backed by a structural gate. |
| **3rd** | **Group D** (Add examples to #902) P2 | No new issue needed -- just enrich an existing issue. Can be done in minutes as a comment. Actual implementation of #902 is Medium priority. |
| **4th** | **Group C** (Field naming standardization) P2 | Important for maintainability but has workarounds today (cascading `.get()`). Should coordinate with #883 timing. |
| **5th** | **Group E** (Deprecated field cleanup) P3 | No user impact today. Do this when the canonical replacements are fully stable, or batch it with the data-arch-006 migration. |

---

## 5. Summary Table

| Group | Findings | New Issue or Existing? | Priority | Labels | Effort |
|---|---|---|---|---|---|
| A | 1 + 2 (crash paths) | NEW | P0 | `type:bug`, `priority:P0`, `domain:reporting`, `domain:financials` | Medium |
| B | 6 | NEW | P1 | `type:enhancement`, `priority:P1`, `domain:reporting`, `domain:architecture` | Medium |
| C | 3 | NEW (ref #883) | P2 | `type:tech-debt`, `priority:P2`, `domain:architecture` | Medium |
| D | 4 | Add to #902 | P2 | (existing) | Large |
| E | 5 | NEW (ref data-arch-006) | P3 | `type:tech-debt`, `priority:P3`, `domain:architecture` | Small |

---

## Open Questions

1. **Is `ProcessingState.is_complete()` currently called anywhere before report generation?** If yes, Group B may be smaller scope (just tighten the gate). If no, it needs to be wired in.
2. **Has #868 been resolved?** If the property-null-fields fix landed, some items in Finding 2 may already be covered. Need to verify before filing Group A.
3. **Is there a migration timeline for data-arch-006?** If imminent, Group E can be folded into that work instead of filed separately.
4. **Does #902 have an assignee or target milestone?** This affects whether Finding 4 examples are actionable soon or just backlog enrichment.
