# Execution Plan: Monorepo Consolidation
**Slug**: `monorepo-consolidation`
**Date**: 2026-03-22
**Author**: Architect Agent

---

## Context Summary

Two repos -- `investFlorida.ai` (153 Python source files, ~64k lines) and `str_simulation` (314 Python source files, ~90k lines) -- are being consolidated into one. The investigation revealed:

- **21 model files** are duplicated. ALL 21 differ ONLY in import paths and line endings (CRLF vs LF). Zero semantic divergence.
- **10 report files** are duplicated. 9 of 10 differ only in import paths. `report_generator.py` has real semantic differences (str_simulation version is more robust, with try/except around LLM client init and a `_format_score` helper).
- **18 orchestration service files** are duplicated. ALL 18 differ only in import paths.
- **8 utility files** are duplicated. 7 of 8 differ only in import paths. `llm_client.py` has a minor difference (str_simulation gracefully stubs `call_tracker` when unavailable).
- **Chat system** exists in both repos but diverged significantly. investFlorida.ai is canonical (1329 vs 552 lines in chat_agent, 4416 vs 749 lines in tool_executor).
- **6 data-layer services** exist in both repos with REAL divergence and different line counts.
- **str_simulation has ~160 unique Python files** (core providers, data services, API routes, MCP server, config modules, CLI) that must be brought over wholesale.
- **investFlorida.ai has ~30 unique Python files** (agents, pipeline, validation, HTTP clients, event_transform, etc.).

The bottom line: this migration is ~85% mechanical import-path rewriting and ~15% genuine merge decisions.

---

## File Classification Summary

### Category 1: IMPORT-ONLY DUPLICATES (safe to unify -- pick either copy, rewrite imports)

**58 files total. Zero merge risk.**

| Layer | Count | Source Path Pattern | Notes |
|---|---|---|---|
| Models | 21 | `src/models/*.py` vs `src/orchestration/models/*.py` | Identical content, import paths differ |
| Reports | 9 | `src/reports/**` vs `src/orchestration/reports/**` | Identical content |
| Orchestration Services | 18 | `src/services/*.py` vs `src/orchestration/services/*.py` | Identical content |
| Utils | 7 | `src/utils/*.py` vs `src/orchestration/utils/*.py` | Identical content |
| Chat (structural) | 10 | `src/chat/**` (identical files) | `__init__.py`, `grounding_check.py`, `session_manager.py`, `override_validator.py`, etc. |

### Category 2: SEMANTIC DUPLICATES (need merge decision)

**19 files total. Require careful review.**

| File | iFA Lines | str Lines | Canonical | Merge Notes |
|---|---|---|---|---|
| `reports/report_generator.py` | 814 | 848 | str_simulation | str has `_format_score` helper, try/except LLM init, multi-path template loader |
| `utils/llm_client.py` | varies | varies | str_simulation | str gracefully stubs call_tracker |
| `chat/services/tool_executor.py` | 4416 | 749 | investFlorida.ai | iFA has 28 tools, str has 6 (subset) |
| `chat/services/chat_agent.py` | 1329 | 552 | investFlorida.ai | iFA has persona-aware grounding, full feature set |
| `chat/services/hydration_service.py` | 400 | 332 | investFlorida.ai | iFA has hydration_levels, cleaning_fee default |
| `chat/services/report_service.py` | 252 | 425 | str_simulation | str has more features (report generation) |
| `chat/api/routes/sessions.py` | 498 | 632 | str_simulation | str has more session management features |
| `chat/api/routes/chat.py` | 278 | 285 | Merge needed | Minor differences |
| `chat/api/routes/reports.py` | 202 | 202 | Either | 2-line diff |
| `chat/config.py` | 84 | 83 | investFlorida.ai | 1-line diff |
| `chat/db/session_repo.py` | 571 | 528 | investFlorida.ai | More complete |
| `chat/models/override.py` | 181 | 176 | investFlorida.ai | 5 extra lines |
| `chat/models/session.py` | 178 | 177 | investFlorida.ai | 1 extra line |
| `chat/services/explain_service.py` | 256 | 255 | investFlorida.ai | 5-line diff |
| `chat/services/override_extractor.py` | 201 | 200 | investFlorida.ai | 1-line diff |
| `chat/prompts/agent_system.md` | 60 | 56 | investFlorida.ai | iFA has 4 extra lines |
| `services/building_amenity_service.py` | 230 | 335 | str_simulation | str is more complete |
| `services/building_compliance_service.py` | 465 | 1503 | str_simulation | str has 3x more code |
| `services/building_discovery_service.py` | 309 | 430 | str_simulation | str is more complete |
| `services/comparable_properties_service.py` | 584 | 262 | investFlorida.ai | iFA has 2x more code |
| `services/revenue_projection_service.py` | 709 | 201 | investFlorida.ai | iFA has 3.5x more code |
| `services/str_activity_service.py` | 247 | 388 | str_simulation | str is more complete |

### Category 3: UNIQUE TO str_simulation (must bring over)

**~160 files total.**

| Directory | Count | What It Is |
|---|---|---|
| `src/core/providers/` | 25 | RentCast, AIRROI, PredictHQ, Google, Mapbox, static providers |
| `src/core/providers/implementations/` | 17 | Provider implementation files |
| `src/core/evidence/` | 6 | Evidence collector, PDF extractor, source scorer |
| `src/core/web_search/` | 5 | Google CSE, SerpAPI, Tavily providers |
| `src/core/utils/` | 13 | address_parser, json_parser, http_client, sanity_checks, etc. |
| `src/core/middleware/` | 2 | AnalysisID middleware |
| `src/core/*.py` | 7 | simulation.py, breakeven.py, rate_boosters.py, etc. |
| `src/core/models/` | 9 | api_models, confidence, expense, location, etc. |
| `src/services/` (unique) | 33 | event_service, expense_engine, geocoding, HOA, insurance, etc. |
| `src/services/insurance_estimate/` | 5 | Insurance estimation sub-package |
| `src/services/adapters/` | 2 | HOA registry adapter |
| `src/apps/` | 75 | All API route modules (analytics, buildings, financials, etc.) |
| `src/config/` | 10 | api_config, cache_config, constants, elasticity_config, etc. |
| `src/cli/` | 3 | CLI cache manager |
| `src/main_app.py` | 1 | FastAPI main app |
| `src/mcp_server.py` | 1 | MCP server |
| `src/models/listing_extract_models.py` | 1 | Listing extraction models |
| `src/providers/tax_rate_provider.py` | 1 | Tax rate provider |
| `config/` (YAML/JSON/prompts) | 33 | api_strategy.yaml, event_config.yaml, 28 prompt .md files |
| `data/` | 3+ | static_events.json, insideairbnb data, eval results |
| `tests/` | 111 | Full test suite |

### Category 4: UNIQUE TO investFlorida.ai (stays in place)

**~30 files total.**

| Directory | Count | What It Is |
|---|---|---|
| `src/agents/` | 6 | LLM pipeline agents (legacy) |
| `src/pipeline/` | 5 | property_analyzer.py (8732 lines), compliance_scoring, etc. |
| `src/validation/` | 2 | data_consistency |
| `src/config/` | 4 | settings.py, sample_listings, verbosity_profiles |
| `src/chat/services/` (unique) | 3 | adjusted_estimate.py, context_bridge.py, hydration_levels.py |
| `src/chat/tests/` (extra) | 4 | persona_coverage, tool_grounding, tool_integration, tool_wiring |
| `src/services/` (unique) | 20 | HTTP clients (to be retired), event_transform, cache_service, etc. |
| `frontend/` | many | Next.js app (untouched) |

### Category 5: TO BE RETIRED AFTER MIGRATION

**7 files -- HTTP client wrappers that become direct imports.**

| File | Lines | Replacement |
|---|---|---|
| `property_intelligence_client.py` | 2798 | Direct calls to `packages/services/` |
| `building_intelligence_client.py` | 1288 | Direct calls to `packages/services/` |
| `financials_client.py` | 466 | Direct calls to `packages/services/` |
| `str_simulation_client.py` | 13 | Direct calls to `packages/services/` |
| `mcp_client.py` (str_simulation) | varies | Direct calls to `packages/services/` |
| `cache_service.py` | varies | Replaced by `packages/core/providers/cache.py` |
| `caching_mixin.py` | varies | Replaced by `packages/core/cacheable_service.py` |

---

## Phase-by-Phase Execution

### Phase 0: Preparation (No Code Changes)

**Goal**: Normalize line endings, resolve the 2 semantic diffs, document all HTTP call sites.

**Files affected**: 0 new, ~60 modified (line ending normalization)

| Step | Action | Details |
|---|---|---|
| 0.1 | Normalize line endings | Run `dos2unix` on all investFlorida.ai `.py` files (currently CRLF) to match str_simulation (LF). This eliminates the fake diffs. |
| 0.2 | Merge `report_generator.py` | Take str_simulation version (has `_format_score`, safer LLM init), add back investFlorida.ai's `profitability_metrics` overlay |
| 0.3 | Merge `llm_client.py` | Take str_simulation version (graceful call_tracker stub), add investFlorida.ai's `call_tracker` import |
| 0.4 | Document HTTP seams | Create a mapping file listing every HTTP call site in investFlorida.ai that calls str_simulation, with the target service class name |
| 0.5 | Create branch | `git checkout -b cap/monorepo-consolidation` |

**Estimated time**: 2-3 hours
**Risk**: Low. Line ending changes are cosmetic. The 2 semantic merges are small.
**Test gate**: `git diff --stat` shows only whitespace changes + 2 files with real changes. Existing tests pass.
**Rollback**: `git checkout master`

---

### Phase 1: Create packages/ Layer (Shared Code)

**Goal**: Establish the `packages/` directory with deduplicated models, services, reports, utils, and core infrastructure.

**Total files to create/move: ~180**

#### Phase 1A: packages/models/ (21 files)

Take the investFlorida.ai copies (canonical per ADR-3), rewrite imports to use `packages.models.*`.

| Source | Destination | Action |
|---|---|---|
| `investFlorida.ai/src/models/*.py` (21 files) | `packages/models/*.py` | Copy, rewrite imports |
| `str_simulation/src/core/models/api_models.py` | `packages/models/api_models.py` | Copy (unique to str) |
| `str_simulation/src/core/models/confidence.py` | `packages/models/confidence.py` | Copy (unique to str) |
| `str_simulation/src/core/models/expense.py` | `packages/models/expense.py` | Copy (unique to str) |
| `str_simulation/src/core/models/location.py` | `packages/models/location.py` | Copy (unique to str) |
| `str_simulation/src/core/models/provenance.py` | `packages/models/core_provenance.py` | Copy (name-clash with orchestration provenance) |
| `str_simulation/src/core/models/registry.py` | `packages/models/registry.py` | Copy (unique to str) |
| `str_simulation/src/core/models/str_signals.py` | `packages/models/str_signals.py` | Copy (unique to str) |
| `str_simulation/src/core/models/viability.py` | `packages/models/viability.py` | Copy (unique to str) |
| `str_simulation/src/models/listing_extract_models.py` | `packages/models/listing_extract_models.py` | Copy (unique to str) |
| NEW | `packages/models/event_input.py` | Create canonical EventInput dataclass |
| NEW | `packages/models/hydration.py` | Create HydrationLevel enum |

**Files**: 33 total (21 copied from iFA, 10 from str, 2 new)
**Risk**: Low. All content-identical. Mechanical import rewriting.
**Test gate**: `from packages.models.investment_context import InvestmentContext` works. All model unit tests pass.

#### Phase 1B: packages/core/ (70 files)

These are ALL unique to str_simulation. Straight copy with import path rewrite.

| Source | Destination | Action |
|---|---|---|
| `str_simulation/src/core/providers/` | `packages/core/providers/` | Copy entire tree |
| `str_simulation/src/core/evidence/` | `packages/core/evidence/` | Copy entire tree |
| `str_simulation/src/core/web_search/` | `packages/core/web_search/` | Copy entire tree |
| `str_simulation/src/core/middleware/` | `packages/core/middleware/` | Copy entire tree |
| `str_simulation/src/core/utils/` | `packages/core/utils/` | Copy entire tree |
| `str_simulation/src/core/simulation.py` | `packages/core/simulation.py` | Copy |
| `str_simulation/src/core/breakeven.py` | `packages/core/breakeven.py` | Copy |
| `str_simulation/src/core/rate_boosters.py` | `packages/core/rate_boosters.py` | Copy |
| `str_simulation/src/core/min_stay_penalty.py` | `packages/core/min_stay_penalty.py` | Copy |
| `str_simulation/src/core/market_models.py` | `packages/core/market_models.py` | Copy |
| `str_simulation/src/core/cacheable_service.py` | `packages/core/cacheable_service.py` | Copy |
| `str_simulation/src/core/models.py` | `packages/core/models.py` | Copy (if not empty barrel) |

**Files**: 70
**Risk**: Low. No merge conflicts -- this code only exists in str_simulation.
**Imports to rewrite**: `from src.core.` -> `from packages.core.` and `from src.orchestration.models.` -> `from packages.models.`
**Test gate**: `from packages.core.providers.orchestrator import Orchestrator` works. Provider unit tests pass.

#### Phase 1C: packages/services/ (~50 files)

Merge services from both repos. For the 6 that overlap, take the canonical version as identified above.

| Source | Destination | Action |
|---|---|---|
| `str_simulation/src/services/*.py` (33 unique files) | `packages/services/*.py` | Copy |
| `str_simulation/src/services/insurance_estimate/` | `packages/services/insurance_estimate/` | Copy entire sub-package |
| `str_simulation/src/services/adapters/` | `packages/services/adapters/` | Copy |
| `investFlorida.ai/src/services/event_transform.py` | `packages/services/event_transform.py` | Copy (unique to iFA) |
| Overlapping services (6 files) | `packages/services/*.py` | Take canonical version (see table above) |
| iFA orchestration services (18 files) | `packages/services/` | Already accounted for -- these are the import-only dups |

Overlap resolution for the 6 diverged data-layer services:

| File | Take From | Reason | Missing from chosen version |
|---|---|---|---|
| `building_amenity_service.py` | str_simulation (335L) | More complete | None identified |
| `building_compliance_service.py` | str_simulation (1503L) | 3x more code | None identified |
| `building_discovery_service.py` | str_simulation (430L) | More complete | None identified |
| `comparable_properties_service.py` | investFlorida.ai (584L) | 2x more features | May need str_simulation's newer filter logic |
| `revenue_projection_service.py` | investFlorida.ai (709L) | 3.5x more code | None identified |
| `str_activity_service.py` | str_simulation (388L) | More complete | None identified |

**Files**: ~53
**Risk**: Medium for the 6 overlapping services. Low for the rest.
**Test gate**: Service unit tests from both repos pass. Integration tests for comparables, revenue projection still pass.

#### Phase 1D: packages/reports/ (10 files)

Take the merged `report_generator.py` from Phase 0. Rest are import-only dups.

**Files**: 10
**Risk**: Low (already merged in Phase 0).
**Test gate**: Report generation produces valid HTML output.

#### Phase 1E: packages/utils/ (8 files + extras)

Take merged `llm_client.py` from Phase 0. Rest are import-only dups. Also bring:
- `investFlorida.ai/src/utils/call_tracker.py` (unique to iFA)
- `investFlorida.ai/src/utils/message_utils.py` (unique to iFA)
- `investFlorida.ai/src/utils/logger.py` (both have one, iFA canonical)

**Files**: ~13
**Risk**: Low.

#### Phase 1F: Import Alias Layer

Create re-export shims so old import paths continue to work during transition:

```
investFlorida.ai/src/models/__init__.py  ->  re-exports from packages.models.*
investFlorida.ai/src/services/*.py       ->  re-exports where applicable
str_simulation/src/orchestration/models/ ->  re-exports from packages.models.*
```

Add deprecation warnings to each re-export.

**Files**: ~5 shim files
**Risk**: Low. This is a safety net, not a code change.

---

**Phase 1 Totals**:
- **Files created/moved**: ~180
- **Estimated time**: 6-8 hours (mostly mechanical)
- **Risk**: Low to Medium overall
- **Rollback**: Delete `packages/` directory, remove shims

---

### Phase 2: Consolidate Apps

**Goal**: Create `apps/api/`, `apps/chat/`, `apps/pipeline/`, move frontend reference.

#### Phase 2A: apps/api/ (str_simulation's API layer)

| Source | Destination | Action |
|---|---|---|
| `str_simulation/src/main_app.py` | `apps/api/main.py` | Copy, rewrite imports |
| `str_simulation/src/mcp_server.py` | `apps/api/mcp_server.py` | Copy, rewrite imports |
| `str_simulation/src/apps/analytics/` | `apps/api/routes/analytics/` | Restructure |
| `str_simulation/src/apps/buildings/` | `apps/api/routes/buildings/` | Restructure |
| `str_simulation/src/apps/compliance_scoring/` | `apps/api/routes/compliance/` | Restructure |
| `str_simulation/src/apps/confidence/` | `apps/api/routes/confidence/` | Restructure |
| `str_simulation/src/apps/extraction/` | `apps/api/routes/extraction/` | Restructure |
| `str_simulation/src/apps/financials/` | `apps/api/routes/financials/` | Restructure |
| `str_simulation/src/apps/insurance/` | `apps/api/routes/insurance/` | Restructure |
| `str_simulation/src/apps/listings/` | `apps/api/routes/listings/` | Restructure |
| `str_simulation/src/apps/location_score/` | `apps/api/routes/location_score/` | Restructure |
| `str_simulation/src/apps/markets/` | `apps/api/routes/markets/` | Restructure |
| `str_simulation/src/apps/markets_mcp/` | `apps/api/routes/markets_mcp/` | Restructure |
| `str_simulation/src/apps/properties/` | `apps/api/routes/properties/` | Restructure |
| `str_simulation/src/apps/registry/` | `apps/api/routes/registry/` | Restructure |
| `str_simulation/src/apps/str_mcp/` | `apps/api/routes/str_mcp/` | Restructure |
| `str_simulation/src/apps/str_sim/` | `apps/api/routes/str_sim/` | Restructure |
| `str_simulation/Dockerfile` | `apps/api/Dockerfile` | Copy, adjust paths |

**Files**: ~77
**Risk**: Medium. Route imports need careful rewriting. Each `app.py` mounts a FastAPI router.
**Test gate**: `pytest tests/integration/` -- all API routes respond correctly. OpenAPI schema still valid.

#### Phase 2B: apps/chat/ (investFlorida.ai's chat system)

Take investFlorida.ai's chat system as canonical (ADR-3). For files where str_simulation has a more complete version, merge the improvements into the iFA base.

| Source | Destination | Action |
|---|---|---|
| `investFlorida.ai/src/chat/` (entire tree) | `apps/chat/` | Copy as base |
| str_simulation improvements | Merge into `apps/chat/` | See merge list below |

**Merge-in from str_simulation**:

| File | What to Merge |
|---|---|
| `api/routes/sessions.py` | str has 134 more lines -- session listing/filtering features |
| `services/report_service.py` | str has 173 more lines -- more report generation features |
| `api/routes/chat.py` | 11-line diff, minor -- review and pick |

**Files**: ~41 (base) + merge work on 3 files
**Risk**: Medium. Chat is the user-facing system. Merge needs careful testing.
**Test gate**: All chat unit tests pass. Hydration pipeline works end-to-end. Tool executor handles all 28 tools.

#### Phase 2C: apps/pipeline/ (investFlorida.ai legacy)

| Source | Destination | Action |
|---|---|---|
| `investFlorida.ai/src/pipeline/` | `apps/pipeline/` | Copy |
| `investFlorida.ai/src/agents/` | `apps/pipeline/agents/` | Copy |

**Files**: 11
**Risk**: Low. Self-contained legacy code.

#### Phase 2D: apps/frontend/

The frontend already exists at `investFlorida.ai/frontend/`. It does not need to move -- just reference it as `apps/frontend/` in the new structure (or symlink during transition).

**Files**: 0 Python changes. Possibly update `next.config.ts` API rewrite if chat port changes.

---

**Phase 2 Totals**:
- **Files created/moved**: ~130
- **Estimated time**: 8-12 hours
- **Risk**: Medium overall
- **Rollback**: Delete `apps/` directories, revert to old import paths

---

### Phase 3: Eliminate HTTP Indirection

**Goal**: Replace HTTP client calls in tool_executor and hydration_service with direct service imports. This is the highest-value phase.

#### Phase 3A: Map HTTP Call Sites

The following investFlorida.ai files make HTTP calls to str_simulation:

| File | Lines | Calls To | Replacement Service |
|---|---|---|---|
| `property_intelligence_client.py` | 2798 | `/str/*`, `/analytics/*`, `/properties/*`, `/extraction/*` | Multiple `packages.services.*` classes |
| `building_intelligence_client.py` | 1288 | `/buildings/*`, `/compliance/*` | `building_discovery_service`, `building_compliance_service` |
| `financials_client.py` | 466 | `/financials/*` | `packages.services.expense_engine`, etc. |
| `str_simulation_client.py` | 13 | Base URL config | Delete entirely |
| `chat/services/tool_executor.py` | 4416 | Uses above clients | Rewrite to use `packages.services.*` directly |
| `chat/services/hydration_service.py` | 400 | Uses above clients | Rewrite to use `packages.services.*` directly |

#### Phase 3B: Rewrite tool_executor.py

For each of the 28 tools, replace the HTTP client call pattern:

```python
# BEFORE
result = await self._pi_client.get_comparables(address, beds, baths)

# AFTER
from packages.services.comparable_properties_service import ComparablePropertiesService
result = self._comparables_svc.get_comparables(address, beds, baths)
```

This is the single most impactful change in the migration. Each tool call saves 50-200ms of HTTP overhead.

**Files modified**: 2 (tool_executor.py, hydration_service.py)
**Files deleted**: 4 (property_intelligence_client.py, building_intelligence_client.py, financials_client.py, str_simulation_client.py)
**Risk**: High. Each of the 28 tool rewrites must be tested. Service signatures may not match client method signatures 1:1.
**Mitigation**: Do this tool-by-tool, not all at once. Test each tool individually.
**Test gate**: Full E2E chat test passes WITHOUT the str_simulation API server running. Each tool returns correct data.

#### Phase 3C: Remove mcp_client.py

str_simulation's `mcp_client.py` calls `http://127.0.0.1:8000` to reach its own API. In the monorepo, this becomes a direct service call.

**Files deleted**: 1
**Risk**: Low after Phase 3B is done.

---

**Phase 3 Totals**:
- **Files modified**: ~5
- **Files deleted**: ~5
- **Estimated time**: 10-15 hours (most complex phase)
- **Risk**: High
- **Rollback**: Revert tool_executor.py and hydration_service.py to HTTP client versions, re-add client files

---

### Phase 4: Configuration and Data Consolidation

#### Phase 4A: Config Files

| Source | Destination | Action |
|---|---|---|
| `str_simulation/config/api_strategy.yaml` | `config/api_strategy.yaml` | Copy |
| `str_simulation/config/event_config.yaml` | `config/event_config.yaml` | Copy |
| `str_simulation/config/guest_profiles.json` | `config/guest_profiles.json` | Copy |
| `str_simulation/config/poi_taxonomy.json` | `config/poi_taxonomy.json` | Copy |
| `str_simulation/config/scoring_thresholds.json` | `config/scoring_thresholds.json` | Copy |
| `str_simulation/config/services_config.yaml` | `config/services_config.yaml` | Copy |
| `str_simulation/config/registry_sources.yaml` | `config/registry_sources.yaml` | Copy |
| `str_simulation/config/prompts/` (28 files) | `config/prompts/` | Copy entire directory |
| `str_simulation/src/config/*.py` (10 files) | `packages/core/config/` | Copy Python config modules |

**Files**: ~45
**Risk**: Low. These are static files.

#### Phase 4B: Data Files

| Source | Destination | Action |
|---|---|---|
| `str_simulation/data/static_events.json` | `data/static_events.json` | Copy (1.7MB) |
| `str_simulation/data/insideairbnb/` | `data/insideairbnb/` | Copy compressed CSV files |
| `str_simulation/data/eval_results/` | `data/eval_results/` | Copy or skip (historical) |

**Files**: ~20
**Risk**: Low. Static data.

#### Phase 4C: Dependencies (requirements.txt / pyproject.toml)

Merge dependencies. str_simulation requires packages not in investFlorida.ai:

| Package | In iFA? | In str? | Action |
|---|---|---|---|
| `pandas` | No | Yes | Add |
| `httpx` | No | Yes | Add |
| `aiohttp` | No | Yes | Add |
| `googlemaps` | No | Yes | Add |
| `numpy` | No | Yes | Add |
| `pdfminer.six` | No | Yes | Add |
| `google-search-results` | No | Yes | Add |
| `tavily-python` | No | Yes | Add |
| `mcp>=1.26.0` | No | Yes | Add |
| `openpyxl` | No | Yes | Add |
| `numpy-financial` | Both | Both | Keep (already in both) |
| `openai` | Both | Both | Use `>=1.0` (str's pin is broader than iFA's `>=2.0`) -- use `>=2.0.0` |

investFlorida.ai has packages str_simulation does not:
| Package | Action |
|---|---|
| `jinja2` | Keep (needed for reports) |
| `langchain-core` | Keep (used by pipeline agents) |
| `pgeocode` | Keep (used by pipeline) |
| `pytest`, `pytest-cov` | Keep (dev deps) |
| `tenacity` | Keep (retry logic) |

**Files**: 1 (pyproject.toml) or 1 (requirements.txt)
**Risk**: Low. But must verify no version conflicts.

---

**Phase 4 Totals**:
- **Files created/moved**: ~66
- **Estimated time**: 2-3 hours
- **Risk**: Low

---

### Phase 5: Test Suite Consolidation

#### Phase 5A: Bring str_simulation tests

| Source | Destination | Count |
|---|---|---|
| `str_simulation/tests/unit/` | `tests/unit/` | 55 test files |
| `str_simulation/tests/integration/` | `tests/integration/` | 5 test files |
| `str_simulation/tests/services/` | `tests/unit/services/` | 16 test files |
| `str_simulation/tests/core/` | `tests/unit/core/` | 16 test files |
| `str_simulation/tests/routes/` | `tests/integration/routes/` | 1 test file |
| `str_simulation/tests/performance/` | `tests/benchmarks/` | 1 test file |
| `str_simulation/tests/` (root tests) | `tests/integration/` | 8 test files |
| `str_simulation/src/chat/tests/` | `tests/unit/chat/` | 7 test files (merge with iFA's) |
| `investFlorida.ai/src/chat/tests/` | `tests/unit/chat/` | 11 test files |
| `investFlorida.ai/src/tests/` | `tests/` | 4 test files |
| `str_simulation/tests/conftest.py` | `tests/conftest.py` | Merge with iFA conftest |
| `str_simulation/pytest.ini` | Migrate to `pyproject.toml` | Merge settings |

#### Phase 5B: Fix test imports

All tests reference old import paths. Rewrite to use `packages.*` and `apps.*`.

**Files**: ~111 + ~15 = ~126
**Risk**: Medium. Some tests mock HTTP clients that no longer exist.
**Test gate**: `pytest --co` (collect-only) succeeds for all test files. Then `pytest -x` to verify they actually pass.

---

**Phase 5 Totals**:
- **Files created/moved**: ~126
- **Estimated time**: 4-6 hours
- **Risk**: Medium

---

### Phase 6: Cleanup and Finalization

| Step | Action |
|---|---|
| 6.1 | Delete old `investFlorida.ai/src/models/` (replaced by `packages/models/`) |
| 6.2 | Delete old `investFlorida.ai/src/reports/` (replaced by `packages/reports/`) |
| 6.3 | Delete old `investFlorida.ai/src/services/` (replaced by `packages/services/` + `apps/`) |
| 6.4 | Delete old `investFlorida.ai/src/utils/` (replaced by `packages/utils/`) |
| 6.5 | Delete old `investFlorida.ai/src/chat/` (replaced by `apps/chat/`) |
| 6.6 | Delete import alias shims from Phase 1F |
| 6.7 | Remove deprecation warnings |
| 6.8 | Update `docker-compose.yml` for new structure |
| 6.9 | Update `Dockerfile.api` for new paths |
| 6.10 | Update CLAUDE.md and README.md |
| 6.11 | Archive `str_simulation` repo (read-only) |
| 6.12 | Update `.env.example` with consolidated env vars |
| 6.13 | Add pre-commit hook to lint for old import paths |

**Risk**: Low. But only do this AFTER all tests pass.
**Test gate**: Full test suite passes. Docker builds succeed. Frontend communicates with API.

---

## Import Rewiring Reference

### str_simulation import patterns (before -> after)

| Before | After |
|---|---|
| `from src.orchestration.models.*` | `from packages.models.*` |
| `from src.core.providers.*` | `from packages.core.providers.*` |
| `from src.core.*` | `from packages.core.*` |
| `from src.services.*` | `from packages.services.*` |
| `from src.orchestration.services.*` | `from packages.services.*` |
| `from src.orchestration.reports.*` | `from packages.reports.*` |
| `from src.orchestration.utils.*` | `from packages.utils.*` |
| `from src.chat.*` | `from apps.chat.*` |
| `from src.apps.*` | `from apps.api.routes.*` |
| `from src.config.*` | `from packages.core.config.*` |
| `from src.core.models.*` | `from packages.models.*` (or `packages.core.models.*` if API-specific) |

### investFlorida.ai import patterns (before -> after)

| Before | After |
|---|---|
| `from src.models.*` | `from packages.models.*` |
| `from src.services.*` | `from packages.services.*` |
| `from src.reports.*` | `from packages.reports.*` |
| `from src.utils.*` | `from packages.utils.*` |
| `from src.chat.*` | `from apps.chat.*` |
| `from src.pipeline.*` | `from apps.pipeline.*` |
| `from src.agents.*` | `from apps.pipeline.agents.*` |
| `from src.config.*` | `from apps.pipeline.config.*` or `from packages.core.config.*` |

---

## Risk Assessment Summary

| Phase | Risk | Files | Hours | Blocking? |
|---|---|---|---|---|
| Phase 0: Prep | Low | ~60 | 2-3 | No |
| Phase 1: packages/ | Low-Medium | ~180 | 6-8 | Yes (foundation) |
| Phase 2: apps/ | Medium | ~130 | 8-12 | Yes |
| Phase 3: HTTP elimination | High | ~10 | 10-15 | No (can be done incrementally) |
| Phase 4: Config/data | Low | ~66 | 2-3 | No |
| Phase 5: Tests | Medium | ~126 | 4-6 | Yes (validation) |
| Phase 6: Cleanup | Low | ~deletions | 2-3 | No |
| **TOTAL** | | **~590 file operations** | **35-50 hours** | |

---

## Rollback Plan

Each phase has an independent rollback:

| Phase | Rollback Method |
|---|---|
| Phase 0 | `git checkout master` |
| Phase 1 | Delete `packages/` directory |
| Phase 2 | Delete `apps/` directory |
| Phase 3 | Revert tool_executor.py and hydration_service.py, re-add HTTP client files |
| Phase 4 | Delete `config/` and `data/` additions |
| Phase 5 | Delete `tests/` additions |
| Phase 6 | No rollback needed (only cleanup) |

Global rollback at any point: `git reset --hard` to pre-migration commit. str_simulation repo remains untouched until Phase 6.11.

---

## Test Strategy

### After Each Phase

| Phase | Test Command | What It Validates |
|---|---|---|
| 0 | `pytest investFlorida.ai/` | Existing tests still pass after line ending normalization |
| 1A | `python -c "from packages.models.investment_context import InvestmentContext"` | Import paths work |
| 1B | `pytest tests/unit/core/` | Provider infrastructure works |
| 1C | `pytest tests/unit/services/` | Services work with new import paths |
| 2A | `pytest tests/integration/` | API routes respond correctly |
| 2B | `pytest tests/unit/chat/` | Chat system works |
| 3 | Full E2E: address -> hydration -> tool calls -> report (NO API server) | HTTP elimination works |
| 5 | `pytest --co` then `pytest` | All tests collected and passing |
| 6 | `docker-compose build && docker-compose up` | Deployment works |

### Smoke Tests After Full Migration

1. Start the API server: `uvicorn apps.api.main:app --port 8000`
2. Hit `/str/comparables?address=...` -- verify response
3. Start the chat server: `uvicorn apps.chat.api.app:app --port 8001`
4. Send a chat message with an address -- verify hydration completes
5. Request a report -- verify HTML generation
6. Start the MCP server -- verify tool listing
7. Build Docker images for all 3 apps

---

## Implementation Priority Recommendation

If time-constrained, the phases should be executed in this order:

1. **Phase 0 + Phase 1A** (models) -- Lowest risk, highest clarity gain
2. **Phase 1B** (core) -- Unlocks Phase 3
3. **Phase 1C** (services) -- Needed for Phase 3
4. **Phase 3** (HTTP elimination) -- Highest user-facing value (150-1600ms saved per chat turn)
5. **Phase 2** (apps restructure) -- Organizational improvement
6. **Phase 4 + 5 + 6** (config, tests, cleanup) -- Polish

Phases 1-3 deliver 80% of the value. Phases 4-6 are cleanup.
