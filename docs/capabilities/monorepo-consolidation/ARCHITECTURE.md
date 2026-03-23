# Architecture: Monorepo Consolidation Evaluation
**Slug**: `monorepo-consolidation`
**Date**: 2026-03-22
**Author**: Architect Agent

---

## Overview

This document evaluates the ideal structure if `investFlorida.ai` (pipeline/chat/frontend), `str_simulation` (MCP server/REST API/data providers), and the report generation layer were consolidated into a single repository. It maps the current duplication, proposes a target structure, and lays out a phased migration strategy.

The core thesis: **these two repos are already one system** that has been artificially split, resulting in identical files maintained in both places. Merging them eliminates the single largest source of drift bugs (event rank=0, chat tool divergence) while preserving the ability to deploy the MCP server independently.

---

## Current State Analysis

### Quantified Duplication

| Component | investFlorida.ai | str_simulation | Identical? |
|---|---|---|---|
| `investment_context.py` (2722 lines) | `src/models/investment_context.py` | `src/orchestration/models/investment_context.py` | Yes (import path differs) |
| All 21 model files | `src/models/*.py` | `src/orchestration/models/*.py` | Yes |
| Chat system (15+ files) | `src/chat/**` | `src/chat/**` | Structurally identical, diverged content |
| `tool_executor.py` | 4304 lines (28 tools) | 749 lines (6 tools) | Common base, investFlorida.ai is superset |
| `hydration_service.py` | `src/chat/services/` | `src/chat/services/` | Near-identical (cleaning_fee default differs) |
| Report system (8 files) | `src/reports/**` | `src/orchestration/reports/**` | Yes |
| Tab analyzers (6 files) | `src/services/analyzers/` | `src/orchestration/services/analyzers/` | Yes |
| Financial calculations | `src/services/financial_calculations.py` | `src/orchestration/services/financial_calculations.py` | Yes |
| Agent system prompt | `src/chat/prompts/agent_system.md` | `src/chat/prompts/agent_system.md` | Diverged |
| Context bridge/adapter | `src/chat/services/context_bridge.py` | `src/orchestration/context_adapter.py` | Same purpose, different implementations |

**Estimated duplicated code: ~15,000+ lines across 50+ files.**

### Communication Pattern Today

```
Frontend (Next.js :3000)
    |  /api/v1/* rewrite
    v
investFlorida.ai Chat API (:8000 -- Dockerfile.api)
    |  HTTP calls to STR_SIMULATION_API_URL
    v
str_simulation REST API (:8000 -- server.py)
    |  Also exposes /mcp/mcp for MCP protocol
    v
Data Providers (RentCast, AIRROI, PredictHQ, Google)
```

Key observations:
1. The investFlorida.ai chat API makes **HTTP calls over localhost** to str_simulation for every tool execution. This is an HTTP round-trip for what could be a function call.
2. str_simulation has its **own copy** of the chat system that calls itself at `http://127.0.0.1:8000` (the `mcp_client.py` pattern).
3. Both repos can generate reports -- investFlorida.ai via `context_bridge.py`, str_simulation via `context_adapter.py`.
4. The `property_analyzer.py` (8732 lines) in investFlorida.ai is the legacy full-pipeline runner. The chat system has largely replaced it for the interactive flow.

### Dependency Graph (Current)

```
investFlorida.ai
  src/models/*  -----(copy)----> str_simulation/src/orchestration/models/*
  src/chat/*    -----(copy)----> str_simulation/src/chat/*
  src/reports/* -----(copy)----> str_simulation/src/orchestration/reports/*
  src/services/property_intelligence_client.py ---(HTTP)---> str_simulation/src/apps/analytics/*
  src/services/financials_client.py            ---(HTTP)---> str_simulation/src/apps/financials/*
  src/services/building_intelligence_client.py ---(HTTP)---> str_simulation/src/apps/buildings/*
  src/chat/services/tool_executor.py           ---(HTTP)---> str_simulation (via MCP client)
```

---

## Proposed Monorepo Structure

```
investflorida/                          # Repository root
|
+-- packages/
|   +-- models/                         # SHARED: All Pydantic/dataclass models
|   |   +-- investment_context.py       # THE single source of truth
|   |   +-- property_data.py
|   |   +-- revenue_models.py
|   |   +-- compliance.py
|   |   +-- metric.py
|   |   +-- ... (21 model files, one copy)
|   |   +-- event_input.py             # NEW: canonical EventInput schema
|   |   +-- api_models.py              # From str_simulation/src/core/models/api_models.py
|   |   +-- __init__.py
|   |
|   +-- core/                           # SHARED: Provider infrastructure + simulation engine
|   |   +-- providers/                  # From str_simulation/src/core/providers/
|   |   |   +-- implementations/       # RentCast, AIRROI, PredictHQ, Google, etc.
|   |   |   +-- orchestrator.py
|   |   |   +-- registry.py
|   |   |   +-- factory.py
|   |   |   +-- cache.py
|   |   +-- simulation.py              # STR revenue simulation engine
|   |   +-- breakeven.py
|   |   +-- rate_boosters.py
|   |   +-- evidence/                   # Evidence collector, source scorer
|   |   +-- web_search/                 # Google CSE, SerpAPI, Tavily
|   |   +-- middleware/                 # AnalysisID middleware
|   |   +-- utils/                      # address_parser, json_parser, etc.
|   |
|   +-- services/                       # SHARED: Business logic services
|   |   +-- event_service.py
|   |   +-- event_transform.py         # THE one event transformer
|   |   +-- financial_calculations.py  # THE one financial calc module
|   |   +-- property_service.py
|   |   +-- geocoding_service.py
|   |   +-- revenue_projection_service.py
|   |   +-- comparable_properties_service.py
|   |   +-- market_intelligence_service.py
|   |   +-- building_discovery_service.py
|   |   +-- building_compliance_service.py
|   |   +-- investment_scoring_service.py
|   |   +-- scenario_service.py
|   |   +-- confidence_assessment_service.py
|   |   +-- expense_engine.py
|   |   +-- ... (all services, deduplicated)
|   |
|   +-- reports/                        # SHARED: Report generation
|   |   +-- report_generator.py
|   |   +-- report_data_model.py
|   |   +-- strategies/
|   |   |   +-- v1_report.py
|   |   |   +-- v2_report.py
|   |   +-- validators/
|   |   |   +-- anti_regression.py
|   |   +-- templates/                 # HTML/Jinja templates
|   |
|   +-- utils/                          # SHARED: Cross-cutting utilities
|       +-- logger.py
|       +-- llm_client.py
|       +-- prompt_manager.py
|       +-- context_helpers.py
|       +-- token_utils.py
|
+-- apps/
|   +-- api/                            # REST API (FastAPI) — what is today str_simulation
|   |   +-- main.py                     # FastAPI app with lifespan, mounts routers
|   |   +-- routes/
|   |   |   +-- analytics.py           # /str/*, /analytics/*
|   |   |   +-- properties.py          # /properties/*
|   |   |   +-- financials.py          # /financials/*
|   |   |   +-- buildings.py           # /buildings/*
|   |   |   +-- markets.py             # /markets/*
|   |   |   +-- compliance.py          # /compliance/*
|   |   |   +-- confidence.py          # /confidence/*
|   |   |   +-- extraction.py          # /extraction/*
|   |   |   +-- insurance.py           # /insurance/*
|   |   +-- mcp_server.py              # MCP tool exposure (40+ tools)
|   |   +-- server.py                   # Uvicorn entrypoint
|   |   +-- Dockerfile
|   |
|   +-- chat/                           # Chat Orchestrator — ONE copy
|   |   +-- api/
|   |   |   +-- app.py                 # FastAPI sub-app for /api/v1/chat/*
|   |   |   +-- deps.py
|   |   |   +-- routes/
|   |   |       +-- sessions.py
|   |   |       +-- chat.py
|   |   |       +-- reports.py
|   |   +-- services/
|   |   |   +-- chat_agent.py          # THE one chat agent
|   |   |   +-- tool_executor.py       # THE one tool executor (28 tools)
|   |   |   +-- hydration_service.py   # THE one hydration service
|   |   |   +-- session_manager.py
|   |   |   +-- override_extractor.py
|   |   |   +-- override_validator.py
|   |   |   +-- grounding_check.py
|   |   |   +-- explain_service.py
|   |   |   +-- report_service.py
|   |   |   +-- context_bridge.py      # Consolidated context_bridge + context_adapter
|   |   |   +-- adjusted_estimate.py
|   |   +-- models/
|   |   |   +-- session.py
|   |   |   +-- override.py
|   |   +-- db/
|   |   |   +-- connection.py
|   |   |   +-- session_repo.py
|   |   +-- prompts/
|   |   |   +-- agent_system.md        # THE one system prompt
|   |   +-- config.py
|   |   +-- Dockerfile
|   |
|   +-- frontend/                       # Next.js app (unchanged)
|   |   +-- app/
|   |   +-- components/
|   |   +-- lib/
|   |   +-- e2e/
|   |   +-- package.json
|   |   +-- next.config.ts
|   |   +-- Dockerfile
|   |
|   +-- pipeline/                       # Legacy pipeline (property_analyzer.py)
|       +-- property_analyzer.py
|       +-- compliance_scoring.py
|       +-- config.py
|       +-- display.py
|       +-- agents/                     # LLM agents (revenue modeling, etc.)
|
+-- config/                             # Shared configuration
|   +-- prompts/                        # All LLM prompts (from str_simulation/config/prompts/)
|   +-- api_strategy.yaml
|   +-- event_config.yaml
|   +-- scoring_thresholds.json
|   +-- services_config.yaml
|   +-- guest_profiles.json
|
+-- tests/
|   +-- unit/                           # Pure unit tests
|   |   +-- models/
|   |   +-- services/
|   |   +-- core/
|   |   +-- chat/
|   +-- integration/                    # Tests that hit the API
|   |   +-- api/
|   |   +-- chat/
|   +-- e2e/                            # Full end-to-end
|   |   +-- persona_reviews/
|   +-- benchmarks/
|   +-- conftest.py
|
+-- data/                               # Static data files
+-- docker-compose.yml                  # Orchestrates api + chat + frontend
+-- pyproject.toml                      # Single Python project config
+-- requirements.txt                    # Consolidated Python deps
+-- README.md
```

---

## Module Dependency Graph

```
                    +------------------+
                    |   packages/models |  <-- Every other module depends on this
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
    +---------v---------+         +---------v---------+
    |   packages/core    |         |  packages/services |
    | (providers, sim)   |---------| (business logic)   |
    +--------+----------+         +---------+----------+
              |                             |
              +--------------+--------------+
                             |
              +--------------+--------------+
              |              |              |
    +---------v---+  +-------v------+ +----v-----------+
    |  apps/api   |  |  apps/chat   | | apps/pipeline  |
    | (REST+MCP)  |  | (orchestrator)| | (legacy batch) |
    +-------------+  +--------------+ +----------------+
                             |
                    +--------v---------+
                    |  apps/frontend    |
                    | (Next.js -- HTTP) |
                    +------------------+

Dependency rules:
  packages/*  --> packages/models (allowed)
  packages/*  --> packages/utils (allowed)
  packages/services --> packages/core (allowed)
  apps/*      --> packages/* (allowed)
  apps/*      --> apps/* (NOT allowed -- no cross-app imports)
  packages/*  --> apps/* (NOT allowed -- packages are app-agnostic)
```

---

## Data Model Consolidation Plan

### InvestmentContext (Single Source of Truth)

**Location**: `packages/models/investment_context.py`

No changes to the model itself. The only change is the **import path**. Today:
- investFlorida.ai: `from src.models.investment_context import InvestmentContext`
- str_simulation: `from src.orchestration.models.investment_context import InvestmentContext`

After: `from packages.models.investment_context import InvestmentContext`

### EventInput (New Canonical Schema)

Today `event_transform.py` exists only in investFlorida.ai and was reimplemented inline in str_simulation. Create a single canonical type:

**Location**: `packages/models/event_input.py`

```python
@dataclass
class EventInput:
    """Canonical event shape for /str/event-impact and all consumers."""
    title: str
    start_date: str          # ISO 8601
    end_date: str             # ISO 8601
    category: str
    rank: int                 # 1-5, from impact.rank
    distance_miles: float
    predicted_attendance: int
```

`packages/services/event_transform.py` converts raw `/str/events` responses into `List[EventInput]`.

### HydrationLevel Enum

Today hydration status is a string (`"complete"`, `"partial"`, `"failed"`). Formalize:

**Location**: `packages/models/hydration.py`

```python
class HydrationLevel(str, Enum):
    FAILED = "failed"       # Step 1 (property lookup) failed
    PARTIAL = "partial"     # Step 1 OK, some optional steps failed
    COMPLETE = "complete"   # All steps succeeded
```

### Models Sync Strategy

One copy in `packages/models/`. No sync needed. Any change is immediately visible to all apps.

---

## Chat Architecture: Single Tool Executor

### The Problem

investFlorida.ai `tool_executor.py` (4304 lines, 28 tools) is the **production version**. str_simulation `tool_executor.py` (749 lines, 6 tools) is a minimal subset that was created for the str_simulation standalone chat. They share a common ancestor but have diverged.

### The Solution

One `tool_executor.py` in `apps/chat/services/tool_executor.py` with 28 tools. The key architecture change: **tool_executor calls services directly instead of making HTTP calls**.

Today:
```python
# investFlorida.ai tool_executor -- calls str_simulation over HTTP
resp = requests.post(f"{STR_API_URL}/str/comparables", json=payload)
```

After:
```python
# Unified tool_executor -- calls service directly
from packages.services.comparable_properties_service import ComparablePropertiesService
result = self._comparables_service.get_comparables(address, beds, baths)
```

This eliminates:
- HTTP serialization/deserialization overhead per tool call
- Port conflicts between the two servers
- The need for `STR_SIMULATION_API_URL` config in chat
- The `mcp_client.py` wrapper in str_simulation

### Progressive Hydration with InvestmentContext

The hydration pipeline stays as-is architecturally but calls services directly:

```
HydrationService
  Step 1: PropertyService.lookup()         -> ctx["property_*"]
  Step 2: BuildingDiscoveryService.find()  -> ctx["building_*"]
  Step 3: ComplianceService.check()        -> ctx["compliance_*"]
  Step 4: RevenueService.estimate()        -> ctx["adr", "occupancy_pct"]
  Step 5: ExpenseEngine.estimate()         -> ctx["utilities", "insurance"]
  Step 6: Pricing defaults                 -> ctx["offer_price"]
```

Each step enriches the flat session dict. `context_bridge.py` converts this flat dict into a typed `InvestmentContext` for report generation. Having one copy of both `hydration_service.py` and `context_bridge.py`/`context_adapter.py` (merged) eliminates the cleaning_fee default discrepancy already observed.

---

## Build & Deploy Strategy

### Three Deployable Artifacts from One Repo

| Artifact | Entrypoint | Dockerfile | What it runs |
|---|---|---|---|
| **API Server** | `apps/api/main.py` | `apps/api/Dockerfile` | REST endpoints + MCP server (standalone-capable) |
| **Chat Orchestrator** | `apps/chat/api/app.py` | `apps/chat/Dockerfile` | Chat API + SSE + report generation |
| **Frontend** | `apps/frontend/` | `apps/frontend/Dockerfile` | Next.js app |

The **API Server** remains independently deployable. External MCP clients (Claude Desktop, Claude Code) connect to it directly. The Chat Orchestrator imports services from `packages/` directly -- no HTTP calls to the API server.

### docker-compose.yml (Simplified)

```yaml
services:
  api:
    build: { context: ., dockerfile: apps/api/Dockerfile }
    ports: ["8000:8000"]
    # Serves REST + MCP for external consumers

  chat:
    build: { context: ., dockerfile: apps/chat/Dockerfile }
    ports: ["8001:8001"]
    # Chat API -- calls packages/* directly, NOT api over HTTP

  frontend:
    build: { context: ., dockerfile: apps/frontend/Dockerfile }
    ports: ["3000:3000"]
    environment:
      - NEXT_PUBLIC_API_URL=http://chat:8001
    depends_on: [chat]
```

Or for local development, a single combined server:

```python
# dev_server.py
from apps.api.main import create_api_app
from apps.chat.api.app import create_chat_app

app = create_api_app()
app.mount("/api/v1/chat", create_chat_app())
# One process, port 8000, everything works
```

### pyproject.toml

```toml
[project]
name = "investflorida"
version = "1.0.0"

[tool.pytest.ini_options]
testpaths = ["tests"]
markers = ["slow", "integration", "e2e"]

[tool.coverage.run]
source = ["packages", "apps"]
```

---

## Testing Strategy

### Current Pain

- investFlorida.ai tests mock HTTP calls to str_simulation
- str_simulation tests mock HTTP calls to itself (`http://127.0.0.1:8000`)
- Chat tests exist in BOTH repos and test nearly identical code
- No cross-repo integration tests

### Monorepo Simplification

| Test Layer | What it Tests | How it Simplifies |
|---|---|---|
| **Unit** (`tests/unit/`) | Individual services, models, providers | No HTTP mocks needed -- just call the service |
| **Integration** (`tests/integration/`) | API routes with real services | One test suite instead of two |
| **Chat** (`tests/unit/chat/`) | Chat agent, tool executor, hydration | One copy of all chat tests |
| **E2E** (`tests/e2e/`) | Full flow from address to report | No multi-server orchestration needed |
| **Persona reviews** (`tests/e2e/persona_reviews/`) | Stakeholder validation matrices | Single test runner |

The 3-layer validation harness (unit -> integration -> persona review) collapses to a single `pytest` invocation against one codebase.

---

## Migration Strategy

### Phase 0: Preparation (Low risk, no code changes)

1. **Audit divergence** between the duplicate files. Generate a diff report for each of the 50+ duplicated files. Identify which repo has the "newer" version of each file.
2. **Resolve the tool_executor gap**. The investFlorida.ai version has 28 tools, str_simulation has 6. Decide: are the 22 extra tools needed in the standalone MCP chat? If not, the investFlorida.ai version is canonical.
3. **Resolve the hydration defaults gap**. investFlorida.ai has `cleaning_fee: 75.0`, str_simulation does not. Pick one.
4. **Document all HTTP call sites** in investFlorida.ai that call str_simulation endpoints. These are the seams that become direct imports.

### Phase 1: Create the Monorepo Shell (Medium risk)

1. Create a new repo `investflorida` (or rename `investFlorida.ai`).
2. Move `packages/models/` -- copy the model files from investFlorida.ai (canonical). Update all import paths.
3. Move `packages/core/` -- copy `str_simulation/src/core/` (providers, simulation engine). This is str_simulation-native code.
4. Move `packages/services/` -- merge services from both repos. Where both exist, take the one with more features and reconcile.
5. Move `packages/reports/` -- copy from investFlorida.ai (canonical).
6. Move `packages/utils/` -- merge, deduplicate.

**Test gate**: All unit tests from both repos pass after import path updates.

### Phase 2: Consolidate Apps (Medium risk)

1. Move `apps/api/` -- this is str_simulation's `main_app.py` + `src/apps/` + `mcp_server.py`.
2. Move `apps/chat/` -- take investFlorida.ai's chat system (it has 28 tools vs 6).
3. Move `apps/frontend/` -- copy investFlorida.ai's `frontend/` unchanged.
4. Move `apps/pipeline/` -- copy investFlorida.ai's `src/pipeline/` (legacy path).

**Test gate**: Integration tests pass. Chat hydration works with direct service calls.

### Phase 3: Eliminate HTTP Indirection (High value, medium risk)

1. Replace `PropertyIntelligenceClient` HTTP calls with direct `packages.services` imports in `apps/chat/services/tool_executor.py`.
2. Replace `FinancialsClient` HTTP calls similarly.
3. Replace `mcp_client.py` HTTP calls in chat hydration with direct service calls.
4. Remove the HTTP client classes (`property_intelligence_client.py`, `financials_client.py`, `str_simulation_client.py`, `mcp_client.py`).
5. Keep the REST API (`apps/api/`) intact for external consumers.

**Test gate**: Full E2E test -- address input to report generation -- passes without the API server running.

### Phase 4: Cleanup (Low risk)

1. Delete `str_simulation/src/orchestration/` (all duplicate models, services, reports).
2. Delete `str_simulation/src/chat/` (duplicate chat system).
3. Consolidate `config/` directories.
4. Unify test suites.
5. Archive the old repos.

### What Does NOT Change

- **barcaTeam** stays as a separate repo. It is an orchestration/meta-repo, not part of the application.
- **Frontend** stays as a Next.js workspace inside `apps/frontend/`. It communicates via HTTP (rewrite proxy), which is correct for a JS/Python boundary.
- **MCP server** stays independently deployable. `apps/api/mcp_server.py` can run standalone.
- **REST API** stays as a separate deployable. External tools that call `/str/comparables` etc. are unaffected.

---

## Architecture Decisions (ADR)

### ADR-1: Merge into Monorepo, Not Create a Shared Package

- **Status**: Proposed
- **Context**: Two options exist -- (a) create a shared Python package (`investflorida-models`) that both repos depend on, or (b) merge into a monorepo. Option (a) adds a third repo, a publishing pipeline, version pinning complexity, and still requires coordinated releases. Option (b) eliminates all coordination overhead.
- **Decision**: Monorepo. Both repos already share >50 identical files and deploy together. The overhead of a third package repo is not justified for a team of this size.
- **Consequences**: Git history from str_simulation would need to be merged (via `git subtree add` or similar). Contributors need to learn the new directory layout.

### ADR-2: Chat Tool Executor Calls Services Directly, Not Over HTTP

- **Status**: Proposed
- **Context**: Today the chat `tool_executor.py` calls str_simulation via HTTP (`PropertyIntelligenceClient`, `FinancialsClient`). This adds ~50-200ms per tool call in serialization/deserialization overhead and creates coupling to a running API server.
- **Decision**: In the monorepo, `tool_executor.py` imports from `packages.services.*` directly. The REST API continues to exist for external consumers.
- **Consequences**: The chat API can no longer be deployed without the packages. This is acceptable because the chat has always depended on the data services. Deployment becomes simpler (one Docker image for chat + services). The REST API remains independently deployable for MCP/external use.

### ADR-3: investFlorida.ai Chat System is Canonical (Not str_simulation's)

- **Status**: Proposed
- **Context**: Both repos have a chat system. investFlorida.ai has 28 tools, persona-aware grounding checks, adjusted_estimate, and context_bridge. str_simulation has 6 tools. investFlorida.ai is the production system; str_simulation's chat was created as a convenience copy.
- **Decision**: Take investFlorida.ai's chat system as canonical. The 6 tools in str_simulation are a subset already present in the superset.
- **Consequences**: str_simulation's standalone chat mode (via `server.py`) would use the full 28-tool executor. This is fine -- unused tools simply do not get called by the LLM.

### ADR-4: Keep REST API Independently Deployable

- **Status**: Proposed
- **Context**: Some consumers (MCP clients, Postman testing, external integrations) call the REST API directly. The API must remain a standalone deployment target.
- **Decision**: `apps/api/` can be built and deployed as a standalone Docker image. It imports from `packages/*` but does not depend on `apps/chat/` or `apps/frontend/`.
- **Consequences**: The `packages/` layer must not import from `apps/`. This is enforced by the dependency rule: packages are app-agnostic.

### ADR-5: Incremental Migration via Import Aliases

- **Status**: Proposed
- **Context**: A big-bang migration (rename all imports at once) is risky. An incremental approach uses Python package aliases (`src.models` -> `packages.models`) during transition.
- **Decision**: Phase 1 creates `packages/` as the canonical location. During transition, `src/models/__init__.py` in each app re-exports from `packages.models.*`. New code uses the new paths; old code continues to work. A linter rule flags old import paths. After all imports are updated, the re-exports are removed.
- **Consequences**: Brief period of two valid import paths (confusing for new contributors). Mitigated by a deprecation warning in the re-export files and a pre-commit hook.

---

## Trade-offs and Risks

### Benefits

| Benefit | Impact |
|---|---|
| **No more dual-fix bugs** | The event rank=0 fix, tool_executor drift, hydration defaults -- all eliminated. ONE file to change. |
| **Faster tool execution** | Direct service calls instead of HTTP (~50-200ms saved per tool call, 3-8 calls per chat turn = 150-1600ms saved) |
| **Single test suite** | `pytest` runs everything. No "did you run tests in the other repo?" |
| **Atomic commits** | A model change + its consuming code change + its test = one commit, one PR. |
| **Simpler onboarding** | One repo to clone, one venv, one README. |
| **Shared prompts/config** | `config/prompts/` is one directory, not duplicated across repos. |

### Risks

| Risk | Severity | Mitigation |
|---|---|---|
| **Git history complexity** | Medium | Use `git subtree add` to preserve str_simulation history. Or accept a clean merge point and keep the old repo archived. |
| **Large repo size** | Low | The combined repo is ~250MB (mostly cached data files and node_modules). Python source is <5MB. Standard monorepo tooling handles this. |
| **Import path churn** | Medium | Phase 1 uses re-export aliases. Automated refactoring with `rope` or `ast` tooling. |
| **Broken external consumers** | Low | REST API and MCP server stay on the same ports and paths. External consumers are unaffected. |
| **Deployment coupling** | Medium | Mitigated by keeping `apps/api/`, `apps/chat/`, `apps/frontend/` as separate Docker build targets. |
| **Testing setup** | Low | Single `pyproject.toml` with test markers. `pytest -m "not integration"` for fast local runs. |

### What This Does NOT Solve

- The 8732-line `property_analyzer.py` still needs refactoring (separate concern).
- The investFlorida.ai pipeline agents (`src/agents/`) are an older architecture that predates the chat system.
- Frontend type safety (TypeScript types are manually kept in sync with Python models). Consider a shared schema generation step post-migration.

---

## Summary of Key Prescriptions

1. **Models**: One copy in `packages/models/`. InvestmentContext unchanged. Add canonical `EventInput` dataclass.
2. **Chat**: investFlorida.ai version is canonical. 28-tool executor. Direct service calls, no HTTP.
3. **Reports**: One copy in `packages/reports/`. Both `context_bridge.py` and `context_adapter.py` merged into one.
4. **Services**: Deduplicated in `packages/services/`. str_simulation services are canonical for data-layer operations; investFlorida.ai services are canonical for orchestration-layer operations.
5. **API**: str_simulation's `main_app.py` + routers move to `apps/api/`. Independently deployable.
6. **Frontend**: Unchanged. Communicates via HTTP rewrite to the chat API.
7. **Config**: Merged into top-level `config/`. Prompts, YAML configs, scoring thresholds -- one location.
8. **Migration**: 4 phases. Phase 1 (shell + models) is lowest risk and highest value. Phase 3 (eliminate HTTP) is highest value overall.
