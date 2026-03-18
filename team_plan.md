# BarcaTeam Plan: True MCP Server for str_simulation + Client Migration

**Date**: 2026-03-13
**Status**: APPROVED -- IMPLEMENTING
**Capability slug**: `mcp-server`

---

## Problem

str_simulation is a FastAPI REST API with ~45 endpoints for STR analytics, financial modeling, and property intelligence. investFlorida.ai calls it via direct HTTP REST. The existing `cap/mcp-api-migration-v1-server` branch restructured the REST API into clean MCP-style sub-apps with Pydantic models, operation_ids, and service layers -- but no actual MCP protocol transport exists. The goal is to build a true MCP (Model Context Protocol) server using the `mcp` Python SDK, then migrate investFlorida.ai from REST to MCP client calls.

## Confirmed Decisions (from user)

1. **True MCP server** using `mcp` Python SDK (FastMCP) with **streamable-http** transport
2. **Fold v1-server branch** into `cap/mcp-server` (do NOT merge v1-server to main separately)
3. **Keep REST API alongside MCP** -- both transports wrap the same service layer
4. **investFlorida.ai switches to MCP client** -- uses `mcp.client.streamable_http.streamablehttp_client` + `ClientSession`
5. **streamable-http transport** (newer MCP transport, HTTP-based, remote-friendly)
6. **All 32 tools** -- implement everything, not just the ones investFlorida.ai actively uses
7. **Include Claude Desktop config** example for connecting Claude Desktop to the MCP server

---

## Architecture Proposal

### High-Level Design

```
                    ┌────────────────────────────────┐
                    │       str_simulation            │
                    │       (single process)          │
                    │                                 │
                    │  ┌─────────────────────────┐    │
                    │  │   Service Layer          │    │
                    │  │   (business logic)       │    │
                    │  │   financials/service.py   │    │
                    │  │   str_mcp/service.py      │    │
                    │  │   buildings/service.py     │    │
                    │  │   markets_mcp/service.py   │    │
                    │  │   extraction/service.py    │    │
                    │  │   compliance/service.py    │    │
                    │  └──────────┬────────────────┘    │
                    │             │                     │
                    │       ┌─────┴─────┐               │
                    │       │           │               │
                    │  ┌────▼────┐ ┌────▼────────┐      │
                    │  │ FastAPI │ │ MCP Server   │      │
                    │  │ REST    │ │ (FastMCP)    │      │
                    │  │ /str/*  │ │ SSE on       │      │
                    │  │ /fin/*  │ │ /mcp/sse     │      │
                    │  │ /mkt/*  │ │              │      │
                    │  └────┬────┘ └────┬─────────┘      │
                    │       │           │               │
                    │  port 8000   mounted on           │
                    │  (main app)  same app              │
                    └───────┬───────────┬───────────────┘
                            │           │
                    REST clients    MCP clients
                    (legacy)       (investFlorida.ai,
                                    Claude Desktop,
                                    AI agents)
```

### Key Architecture Decision: Mount MCP on Same FastAPI App

The `mcp` SDK's `FastMCP.sse_app()` returns a Starlette app. Since FastAPI is built on Starlette, we can **mount the MCP SSE app directly onto the existing FastAPI app** at a sub-path (e.g., `/mcp`). This means:

- **Single process, single port** (8000)
- REST and MCP coexist on the same server
- Shared service layer initialization (providers, factory, orchestrator)
- No separate deployment needed
- Health check at `GET /health` covers both transports

### MCP Server Implementation

**Location**: `src/mcp_server.py` (new file, ~400-600 LOC)

The MCP server uses `FastMCP` from the `mcp` Python SDK. Each tool wraps a service function from the existing service layer.

```python
# src/mcp_server.py (conceptual structure)
from mcp.server.fastmcp import FastMCP

mcp = FastMCP(
    name="str-simulation",
    instructions="STR investment analysis platform. Provides revenue estimation, "
                 "financial modeling, market intelligence, and compliance scoring.",
)

# Example tool definition wrapping existing service
@mcp.tool(
    name="calculate_mortgage",
    description="Calculate monthly mortgage payment, total interest, LTV ratio, "
                "and annual debt service for a property purchase.",
)
async def calculate_mortgage(
    property_price: float,
    down_payment_pct: float = 0.25,
    interest_rate: float = 0.065,
    loan_term_years: int = 30,
) -> dict:
    """Wraps financials/service.py::calculate_mortgage()"""
    from src.apps.financials.models import MortgageRequest
    from src.apps.financials.service import calculate_mortgage as calc
    request = MortgageRequest(
        property_price=property_price,
        down_payment_pct=down_payment_pct,
        interest_rate=interest_rate,
        loan_term_years=loan_term_years,
    )
    result = calc(request)
    return result.model_dump()
```

**Mounting in main_app.py:**

```python
# src/main_app.py — addition
from src.mcp_server import mcp as mcp_server

# Mount MCP SSE transport alongside REST
app.mount("/mcp", mcp_server.sse_app())
```

### MCP Tool Catalog (50+ tools)

Tools map 1:1 to existing operation_ids from the v1-server branch. Grouped by domain:

#### Financial Tools (7 tools)
| MCP Tool Name | Wraps Service Function | Input Model |
|---|---|---|
| `calculate_mortgage` | `financials/service.calculate_mortgage` | MortgageRequest |
| `estimate_property_tax` | `financials/service.calculate_property_tax` | PropertyTaxRequest |
| `calculate_str_tax` | `financials/service.calculate_str_tax` | STRTaxRequest |
| `calculate_management_fee` | `financials/service.calculate_management_fee` | ManagementFeeRequest |
| `estimate_utilities` | `financials/service.calculate_utilities` | UtilitiesRequest |
| `simulate_financial_scenarios` | `financials/service.calculate_scenarios` | ScenarioRequest |
| `project_five_year_financials` | `investment_service.compute_projection` | InvestmentProjectionRequest |

#### STR Analytics Tools (12 tools)
| MCP Tool Name | Wraps | Input Model |
|---|---|---|
| `estimate_str_revenue_detailed` | `core_estimate_service.get_core_estimate` | EstimateRequest |
| `search_str_comparable_properties` | orchestrator via str_mcp/app | ComparablesRequest |
| `detect_str_market_signals` | `str_signal_service` | SignalsRequest |
| `score_str_viability` | `viability_service` | ViabilityRequest |
| `estimate_str_event_impact` | `rate_boosters.compute_monthly_boosters` | RateBoosterRequest |
| `calculate_str_monthly_rates` | `rate_boosters.compute_monthly_rates` | MonthlyRatesRequest |
| `calculate_str_breakeven` | `breakeven.calculate_breakeven` | BreakEvenRequest |
| `project_str_revenue` | `simulation.simulate` | ProjectionRequest |
| `estimate_str_expenses` | expense estimate impl | ExpenseEstimateRequest |
| `search_local_events` | `event_service` | EventsSearchRequest |
| `analyze_str_competition` | orchestrator competition | STRCompetitionRequest |
| `score_guest_profile_location` | `location_score_service` | LocationScoreRequest |

#### Market Tools (4 tools)
| MCP Tool Name | Wraps | Input |
|---|---|---|
| `get_market_statistics` | `markets_mcp/service` | zip_code |
| `search_active_listings` | `markets_mcp/service` | zip_code, filters |
| `analyze_market_trends` | `markets_mcp/service` | zip_code |
| `analyze_market_competition` | `markets_mcp/service` | location |

#### Property Tools (4 tools)
| MCP Tool Name | Wraps | Input |
|---|---|---|
| `estimate_property_value` | `properties/service` | address |
| `estimate_ltr_rent` | `properties/service` | address, bedrooms |
| `search_property_comparables` | `properties/service` | address |
| `analyze_property_competition` | `properties/service` | address |

#### Building Tools (3 tools)
| MCP Tool Name | Wraps | Input |
|---|---|---|
| `assess_building_compliance` | `buildings/service` | address |
| `search_building_listings` | `buildings/service` | building name |
| `score_institutional_grade` | `buildings/service` | address |

#### Compliance Tools (1 tool)
| MCP Tool Name | Wraps | Input |
|---|---|---|
| `score_regulatory_compliance` | `compliance_scoring/service` | address |

#### Extraction Tools (1 tool)
| MCP Tool Name | Wraps | Input |
|---|---|---|
| `extract_listing` | `extraction/service` | url |

**Total: ~32 tools** (covering all domain endpoints)

### investFlorida.ai MCP Client

**New file**: `src/services/mcp_client.py` (~200-300 LOC)

Replaces `PropertyIntelligenceClient` and `BuildingIntelligenceClient` with a single MCP-based client.

```python
# src/services/mcp_client.py (conceptual structure)
from mcp.client.sse import sse_client
from mcp.client.session import ClientSession

class STRSimulationMCPClient:
    """MCP client for str_simulation server."""

    def __init__(self, server_url: str = "http://localhost:8000/mcp/sse"):
        self._server_url = server_url
        self._session: ClientSession | None = None

    async def connect(self):
        """Establish MCP session."""
        self._read_stream, self._write_stream = await sse_client(self._server_url).__aenter__()
        self._session = ClientSession(self._read_stream, self._write_stream)
        await self._session.initialize()

    async def call_tool(self, tool_name: str, arguments: dict) -> dict:
        """Call an MCP tool and return the result."""
        result = await self._session.call_tool(tool_name, arguments)
        return result

    # Convenience methods matching current PropertyIntelligenceClient API:
    async def get_str_estimate(self, address: str, bedrooms: int, ...) -> dict:
        return await self.call_tool("estimate_str_revenue_detailed", {...})

    async def calculate_mortgage(self, property_price: float, ...) -> dict:
        return await self.call_tool("calculate_mortgage", {...})
```

**Migration approach**: The new `STRSimulationMCPClient` provides the same method signatures as `PropertyIntelligenceClient` and `BuildingIntelligenceClient`, so callers (agents, pipeline) change only the import and instantiation.

**Fallback strategy**: The compatibility layer (`MCPCompatLayer` if it exists, or a new wrapper) tries MCP first, falls back to REST on connection failure.

### Transport Details

- **Server transport**: SSE via `FastMCP.sse_app()` mounted at `/mcp`
- **Endpoints exposed**:
  - `GET /mcp/sse` -- SSE event stream for MCP protocol
  - `POST /mcp/messages` -- Client-to-server messages
- **Client transport**: `mcp.client.sse.sse_client` connecting to `{MCP_API_BASE_URL}/mcp/sse`
- **Authentication**: None for now (same trust model as current REST -- internal network)
- **Timeout**: 300s SSE read timeout (configurable), 30s per tool call

---

## Rollout Strategy

### Phase 1: MCP Server in str_simulation (no client changes yet)
1. Merge `cap/mcp-api-migration-v1-server` into `main` (prerequisite -- clean service layer)
2. Add `mcp` to `requirements.txt`
3. Create `src/mcp_server.py` with all tool definitions
4. Mount MCP SSE app in `main_app.py` at `/mcp`
5. Add tests for MCP tool discovery and basic tool calls
6. REST API continues working unchanged

### Phase 2: MCP Client in investFlorida.ai
1. Add `mcp` to investFlorida.ai `requirements.txt`
2. Create `src/services/mcp_client.py`
3. Add `MCP_TRANSPORT` env var (`mcp` | `rest`, default `rest` for safety)
4. Update `PropertyIntelligenceClient` and `BuildingIntelligenceClient` callers to use MCP client when `MCP_TRANSPORT=mcp`
5. Test end-to-end with MCP transport

### Phase 3: Validation + Cutover
1. Run full test suite on both repos
2. Run e2e demo with MCP transport
3. Flip default to `MCP_TRANSPORT=mcp`
4. Keep REST as fallback (do NOT delete REST endpoints)

### Coexistence Model

```
MCP_TRANSPORT=rest   → PropertyIntelligenceClient (HTTP/REST, current behavior)
MCP_TRANSPORT=mcp    → STRSimulationMCPClient (MCP/SSE, new behavior)
```

Both paths call the same server-side service layer. The feature flag allows gradual migration and instant rollback.

---

## Risks and Trade-offs

| Risk | Impact | Mitigation |
|---|---|---|
| MCP SDK is relatively new (v1.26) | Medium -- API may evolve | Pin version in requirements.txt; wrap in thin adapter |
| SSE transport adds connection overhead | Low -- persistent connection amortizes | Connection pooling in client; reconnect on failure |
| Merging v1-server branch first is a prerequisite | Medium -- large diff (~7,400 lines) | Branch has 35+ tests; review carefully before merge |
| Tool definitions are boilerplate-heavy (~32 tools) | Low -- tedious but straightforward | Code generation from existing Pydantic models |
| investFlorida.ai is sync (requests), MCP client is async | Medium -- requires async bridge | Use `asyncio.run()` wrapper or migrate callers to async |
| Some tools need ProviderOrchestrator (injected at startup) | Medium -- MCP tools need access to shared state | Use FastMCP lifespan context or module-level singleton |

### The Async Challenge

This is the biggest technical risk. The current investFlorida.ai codebase uses synchronous `requests`/`httpx` calls. The MCP client SDK (`sse_client`, `ClientSession`) is fully async. Solutions:

1. **Option A (recommended)**: Create a sync wrapper using `asyncio.run()` for each call. Simple, works with existing sync codebase.
2. **Option B**: Migrate investFlorida.ai callers to async. Higher effort, better long-term.
3. **Option C**: Use a dedicated event loop thread. Most complex, best performance.

Recommendation: **Option A for Phase 2**, with Option B as a follow-up.

---

## Acceptance Criteria

| ID | Criterion | Priority |
|---|---|---|
| AC-1 | str_simulation exposes a working MCP server at `/mcp` with SSE transport | Must-have |
| AC-2 | All 32+ tools are discoverable via `list_tools` MCP call | Must-have |
| AC-3 | Each tool returns correct results matching REST endpoint behavior | Must-have |
| AC-4 | REST API continues working unchanged (backward compatibility) | Must-have |
| AC-5 | investFlorida.ai can call str_simulation via MCP client | Must-have |
| AC-6 | Feature flag `MCP_TRANSPORT` controls REST vs MCP routing | Must-have |
| AC-7 | All existing tests pass on both repos | Must-have |
| AC-8 | MCP tool definitions include proper descriptions and JSON schemas | Should-have |
| AC-9 | Connection failure falls back gracefully (MCP -> REST) | Should-have |
| AC-10 | Claude Desktop / Claude Code can connect to the MCP server | Nice-to-have |

---

## Team & File Boundaries

| Agent | Phase | Scope (files/modules) | Deliverable |
|---|---|---|---|
| pm | Understand + Validate | reads: both repos | Requirements analysis, final sign-off |
| architect | Design | reads: both repos | ARCHITECTURE.md, ADRs |
| mcp-infra-engineer | Design | reads: str_simulation, mcp SDK | Tool definitions, transport config |
| senior-engineer | Build (str_simulation) | writes: src/mcp_server.py, main_app.py, requirements.txt, tests/ | MCP server + tests |
| senior-engineer | Build (investFlorida.ai) | writes: src/services/mcp_client.py, config/settings.py | MCP client + tests |
| qa | Validate | reads: both repos | QA_REPORT.md |

## Execution Phases

### Phase 1: Design (this proposal = design phase)
- [x] **lead**: Context discovery, needs analysis
- [x] **lead**: Architecture proposal with MCP SDK verification
- [ ] **USER APPROVAL REQUIRED** before proceeding

### Phase 2: Build (after approval)

#### Stream A: str_simulation MCP Server
1. Merge `cap/mcp-api-migration-v1-server` into `main` (prerequisite)
2. Create `src/mcp_server.py` with all tool definitions
3. Mount MCP SSE app in `main_app.py`
4. Add `mcp` to `requirements.txt`
5. Add MCP-specific tests

#### Stream B: investFlorida.ai MCP Client (after Stream A)
1. Create `src/services/mcp_client.py`
2. Add feature flag `MCP_TRANSPORT` to settings
3. Wire up callers to use MCP client
4. Add tests

### Phase 3: Validate (after build)
- [ ] **qa-str-simulation**: Run pytest, validate MCP tools
- [ ] **qa-investflorida**: Run pytest, validate MCP client
- [ ] **qa-e2e**: Run demo with MCP transport end-to-end
- [ ] **pm**: Verify acceptance criteria met

---

## Open Questions for User

1. **v1-server branch merge**: Should we merge `cap/mcp-api-migration-v1-server` into `main` as a prerequisite PR first, or incorporate its changes into the new `cap/mcp-server` branch?

2. **Tool count**: The v1-server branch has ~32 distinct operation_ids. Should we expose ALL of them as MCP tools, or start with a subset (e.g., the ~15 that investFlorida.ai actively calls)?

3. **Streamable HTTP vs SSE**: MCP SDK also supports `streamable-http` transport (newer, also HTTP-based). SSE was confirmed but streamable-http may be more future-proof. Any preference?

4. **Claude Desktop config**: Should we include a `claude_desktop_config.json` example for connecting Claude Desktop to this MCP server?
