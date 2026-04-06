# Architecture: API Call Tracking & Cost Observability
**Slug**: `api-cost-observability`
**Date**: 2026-04-03
**Author**: Architect Agent
**GH Issue**: investFlorida.ai#1534

## Overview

Instrument all backend external calls (MCP/provider API calls + LLM completions) per
session to enable per-listing cost visibility, cache optimization, and unit-economics
analysis. The design extends the existing `contextvars`-based observability infrastructure
(`analysis_id.py`) rather than introducing new propagation mechanisms, and logs call
metadata to a new SQLite table with session affinity.

## Context: Existing Infrastructure to Build On

The codebase already has:

1. **`packages/core/middleware/analysis_id.py`** -- `contextvars` for `session_id`,
   `analysis_id`, `property_id`, `user_id`, plus `RequestSummary` with aggregate
   counters (`provider_calls`, `cache_hits`, `cache_misses`). Set by
   `AnalysisIDMiddleware` per request.

2. **`ProviderCache`** (`packages/core/providers/cache.py`) -- disk-based JSON cache
   with `provider_id` already stored in each cache entry. Calls
   `increment_cache_hits()`/`increment_cache_misses()` on the contextvars summary.

3. **`CacheableService`** (`packages/simulation/cacheable_service.py`) -- mixin that
   wraps `cache.get()` -> `fetch_fn()` -> `cache.set()` with stale fallback.

4. **`LLMClient`** (`packages/core/providers/implementations/llm_client.py`) -- returns
   `LLMResponse` with `.usage` dict containing `prompt_tokens`, `completion_tokens`,
   `total_tokens` already parsed from the OpenAI response.

5. **`STRSimulationMCPClient`** (`packages/services/mcp/mcp_client.py`) -- sync httpx
   client wrapping `_post()`/`_get()` to the market API. All hydration calls go through
   this.

6. **Background threading** -- hydration steps 2-6 run in `threading.Thread` with
   `ThreadPoolExecutor(max_workers=4)`. These threads are **not** async; they call
   sync MCP methods directly.

## Technology Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Context propagation | Extend existing `contextvars` in `analysis_id.py` | Already has `session_id_context`, `RequestSummary`. No new mechanism needed. |
| Instrumentation layer | Decorator on `STRSimulationMCPClient._post`/`_get` + hook in `LLMClient.complete` | Single chokepoint for all MCP calls; LLM already returns usage metadata. |
| Storage | New `api_call_log` table in existing `chat_sessions.db` | Same DB, same WAL mode, same connection pattern. Separate DB not justified yet. |
| Write strategy | Synchronous insert per call | At 8-12 calls per session, batch buffering adds complexity for negligible gain. |
| Cost estimation | Hardcoded pricing dict, versioned in code | Good enough for unit-economics analysis; real billing reconciliation is a v2 concern. |
| Thread safety for contextvars | Copy context vars into background thread at spawn site | Python `contextvars` do NOT auto-propagate to `threading.Thread`. Explicit copy required. |

## Impacted Areas

| Repo | Layer | Files/Modules | Change Type |
|---|---|---|---|
| investFlorida.ai | Middleware | `packages/core/middleware/analysis_id.py` | Modified -- add call log accumulator |
| investFlorida.ai | Observability | `packages/core/observability/call_tracker.py` | **New** -- TrackedCall dataclass + logging helpers |
| investFlorida.ai | MCP Client | `packages/services/mcp/mcp_client.py` | Modified -- instrument `_post`/`_get` |
| investFlorida.ai | LLM Client | `packages/core/providers/implementations/llm_client.py` | Modified -- emit TrackedCall after successful completion |
| investFlorida.ai | DB Schema | `apps/chat/db/schema.sql` | Modified -- add `api_call_log` table |
| investFlorida.ai | DB Repo | `apps/chat/db/call_log_repo.py` | **New** -- insert/query call logs |
| investFlorida.ai | API Routes | `apps/chat/api/routes/sessions.py` | Modified -- propagate context vars to background threads, flush call log at hydration end |
| investFlorida.ai | API Routes | `apps/chat/api/routes/usage.py` | **New** -- `GET /sessions/{id}/usage` endpoint |
| investFlorida.ai | Pricing | `packages/core/observability/pricing.py` | **New** -- hardcoded cost table |

## Detailed Design

### 1. TrackedCall Dataclass

```python
# packages/core/observability/call_tracker.py
from dataclasses import dataclass, field
from typing import Optional
import time

@dataclass
class TrackedCall:
    provider: str            # "mcp", "openai", "rentcast", "google_places", etc.
    endpoint: str            # "/properties/lookup", "chat/completions", etc.
    cache_status: str        # "hit", "miss", "bypass", "n/a"
    latency_ms: int          # wall-clock milliseconds
    status_code: Optional[int] = None
    error: Optional[str] = None
    # LLM-specific
    model: Optional[str] = None
    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    total_tokens: Optional[int] = None
    prompt_category: Optional[str] = None  # "dedup", "system", etc.
    # Metadata
    session_id: Optional[str] = None
    timestamp: str = ""      # ISO-8601, set at creation
```

### 2. Context Propagation (answering Question 1)

**Decision: Use existing `contextvars`, but copy them explicitly into background threads.**

Python `contextvars` do NOT auto-propagate to `threading.Thread`. The current code
spawns `threading.Thread(target=_run_hydration_background, ...)` which means all
`contextvars` are empty inside the background thread. This is actually already
a latent bug -- `increment_cache_hits()` calls inside `ProviderCache.get()` during
background hydration silently no-op because `_request_summary_context` is `None`.

**Required fix:**

```python
# In sessions.py, before spawning background thread:
import contextvars
ctx_copy = contextvars.copy_context()

thread = threading.Thread(
    target=ctx_copy.run,
    args=(_run_hydration_background, session_id, step1_ctx, address),
    daemon=True,
)
```

This propagates `session_id_context`, `analysis_id_context`, and any new call-log
accumulator into the background thread AND into the nested `ThreadPoolExecutor`
workers (since `ThreadPoolExecutor.submit` inherits context from the submitting thread
in Python 3.12+).

**Note:** For Python < 3.12, `ThreadPoolExecutor` does NOT copy context. If the
runtime is < 3.12, use `ctx_copy.run(fn)` wrappers in the executor submit calls
as well. Check the project's Python version and handle accordingly.

### 3. Instrumentation Strategy (answering Questions 2 and 4)

**Decision: Instrument at the MCP client chokepoint, NOT at ProviderCache.**

Rationale:
- `ProviderCache.get()` does not know which provider or endpoint is being served
  (Question 4). Adding that context would require threading provider/endpoint info
  through every `.get()` call across all providers -- high surface area, high risk.
- `STRSimulationMCPClient._post()` and `._get()` are the single chokepoint for ALL
  MCP calls from hydration. Instrumenting here captures provider+endpoint naturally
  from the path argument.
- Cache hit/miss status is already tracked by `ProviderCache` via the existing
  `increment_cache_hits()`/`increment_cache_misses()` counters. For per-call
  cache attribution, the MCP client can check response headers or wrap calls.

**Implementation: Decorate `_post` and `_get`**

```python
# In mcp_client.py
import time
from packages.core.observability.call_tracker import TrackedCall, record_call

def _post(self, path: str, json: dict) -> dict:
    start = time.monotonic()
    try:
        resp = self._http.post(path, json=json)
        resp.raise_for_status()
        latency = int((time.monotonic() - start) * 1000)
        record_call(TrackedCall(
            provider="mcp",
            endpoint=path,
            cache_status="n/a",  # MCP doesn't cache at this layer
            latency_ms=latency,
            status_code=resp.status_code,
        ))
        return resp.json()
    except Exception as exc:
        latency = int((time.monotonic() - start) * 1000)
        record_call(TrackedCall(
            provider="mcp",
            endpoint=path,
            cache_status="n/a",
            latency_ms=latency,
            status_code=getattr(getattr(exc, 'response', None), 'status_code', None),
            error=str(exc)[:200],
        ))
        raise
```

**For ProviderCache-level instrumentation** (to distinguish cache hit vs live call):
Rather than modifying ProviderCache itself, add an optional `provider_label` and
`endpoint_label` parameter to `CacheableService._cached_execute()`. The mixin
already wraps the cache-check + fetch cycle and knows whether the result came from
cache. This keeps ProviderCache generic and puts the context where it belongs.

**For LLM calls:**
`LLMClient.complete()` already parses usage. Add a `record_call()` after line 218
(the successful return path):

```python
record_call(TrackedCall(
    provider="openai",
    endpoint="chat/completions",
    cache_status="miss",  # or "hit" from the early-return path
    latency_ms=latency,
    model=self.model,
    prompt_tokens=usage.get("prompt_tokens"),
    completion_tokens=usage.get("completion_tokens"),
    total_tokens=usage.get("total_tokens"),
))
```

### 4. Call Log Accumulator

A new contextvar accumulates `TrackedCall` instances during a request/session lifecycle:

```python
# In call_tracker.py
import contextvars
from typing import List

_call_log: contextvars.ContextVar[List[TrackedCall]] = contextvars.ContextVar(
    "call_log", default=None
)

def init_call_log() -> None:
    _call_log.set([])

def record_call(call: TrackedCall) -> None:
    log = _call_log.get()
    if log is not None:
        call.session_id = call.session_id or session_id_context.get()
        call.timestamp = call.timestamp or datetime.now(timezone.utc).isoformat()
        log.append(call)

def get_call_log() -> List[TrackedCall]:
    return _call_log.get() or []
```

Call `init_call_log()` at two sites:
1. In `AnalysisIDMiddleware.dispatch()` -- for request-scoped tracking
2. At the top of `_run_hydration_background()` -- for background thread tracking

Call `flush_call_log(session_id)` at:
1. End of request in middleware (for sync request calls)
2. End of `_run_hydration_background()` (for background hydration calls)

### 5. Database Schema (answering Question 3)

```sql
-- New table in apps/chat/db/schema.sql
CREATE TABLE IF NOT EXISTS api_call_log (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id      TEXT NOT NULL REFERENCES sessions(session_id) ON DELETE CASCADE,
    provider        TEXT NOT NULL,        -- 'mcp', 'openai', 'rentcast', etc.
    endpoint        TEXT NOT NULL,        -- '/properties/lookup', 'chat/completions'
    cache_status    TEXT NOT NULL,        -- 'hit', 'miss', 'bypass', 'n/a'
    latency_ms      INTEGER NOT NULL,
    status_code     INTEGER,
    error           TEXT,
    -- LLM-specific (nullable for non-LLM calls)
    model           TEXT,
    prompt_tokens   INTEGER,
    completion_tokens INTEGER,
    total_tokens    INTEGER,
    prompt_category TEXT,
    -- Cost (computed at insert time from pricing table)
    estimated_cost_usd REAL,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_call_log_session
    ON api_call_log(session_id);

CREATE INDEX IF NOT EXISTS idx_call_log_provider
    ON api_call_log(provider, created_at);
```

**On table growth (Question 3):**

Volume analysis: ~8-12 MCP calls per hydration + 0-5 LLM calls per chat turn.
At 1000 sessions/month with 3 chat turns average = ~25,000 rows/month.

This is very manageable for SQLite with WAL mode. Recommended approach:
- **Indexes** on `session_id` and `(provider, created_at)` -- already specified above
- **Periodic cleanup**: Add a maintenance endpoint or cron that DELETEs rows older than
  90 days. No partitioning needed.
- **Separate DB**: NOT recommended at this scale. It would mean a second connection pool,
  second WAL, and cross-DB joins become impossible. Revisit only if call_log exceeds
  ~1M rows (which at current growth would take 3+ years).

### 6. Write Strategy (answering Question 5)

**Decision: Synchronous insert per flush, NOT per individual call.**

Calls are accumulated in memory via the contextvar list during the request/hydration
lifecycle, then batch-inserted in a single transaction at the end:

```python
def flush_call_log(session_id: str, db: ChatDB) -> None:
    calls = get_call_log()
    if not calls:
        return
    with db.connection() as conn:
        conn.executemany(
            """INSERT INTO api_call_log
               (session_id, provider, endpoint, cache_status, latency_ms,
                status_code, error, model, prompt_tokens, completion_tokens,
                total_tokens, prompt_category, estimated_cost_usd)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            [(session_id, c.provider, c.endpoint, c.cache_status, c.latency_ms,
              c.status_code, c.error, c.model, c.prompt_tokens, c.completion_tokens,
              c.total_tokens, c.prompt_category,
              estimate_cost(c)) for c in calls]
        )
    _call_log.set([])  # Reset after flush
```

This gives us:
- Zero per-call DB overhead during the critical hydration path
- One atomic batch write at the end
- No risk of partial writes if hydration crashes mid-way (calls are just lost, which
  is acceptable for observability data)

### 7. Usage Endpoint

```
GET /api/v1/chat/sessions/{session_id}/usage
```

**Response:**
```json
{
  "session_id": "abc-123",
  "total_calls": 14,
  "total_latency_ms": 8200,
  "total_estimated_cost_usd": 0.0342,
  "cache_hit_rate": 0.42,
  "by_provider": [
    {
      "provider": "mcp",
      "call_count": 8,
      "cache_hits": 3,
      "cache_misses": 5,
      "avg_latency_ms": 450,
      "estimated_cost_usd": 0.0012
    },
    {
      "provider": "openai",
      "call_count": 6,
      "total_tokens": 12400,
      "prompt_tokens": 10200,
      "completion_tokens": 2200,
      "avg_latency_ms": 1200,
      "estimated_cost_usd": 0.0330
    }
  ],
  "calls": [
    {
      "provider": "mcp",
      "endpoint": "/properties/lookup",
      "cache_status": "miss",
      "latency_ms": 1200,
      "status_code": 200,
      "estimated_cost_usd": 0.0002,
      "created_at": "2026-04-03T14:30:00Z"
    }
  ]
}
```

The `by_provider` aggregation is computed via SQL `GROUP BY provider`. The `calls`
array is the raw log. For the frontend "Usage & Costs" panel, the aggregated view
is primary; raw calls are secondary (collapsible detail).

### 8. Pricing Table (answering Question 6)

**Decision: Hardcoded pricing dict, NOT real billing API.**

```python
# packages/core/observability/pricing.py
PRICING_V1 = {
    "openai": {
        "gpt-4o-mini": {"input_per_1k": 0.000150, "output_per_1k": 0.000600},
        "gpt-4o":      {"input_per_1k": 0.00250,  "output_per_1k": 0.01000},
    },
    "mcp": {
        # MCP calls hit our own market API which calls external providers.
        # Cost is the downstream provider cost, not the MCP call itself.
        # Approximate per-call costs based on provider pricing.
        "/properties/lookup":     0.0002,   # RentCast ~$0.20/1000 calls
        "/buildings/assess":      0.0010,   # LLM + web search
        "/str/compliance":        0.0005,
        "/str/revenue":           0.0003,
        "/insurance/defaults":    0.0000,   # Static data, no external cost
        "/utilities/estimate":    0.0000,   # Static data
        "default":                0.0003,
    },
}

def estimate_cost(call: TrackedCall) -> float:
    if call.provider == "openai" and call.model:
        rates = PRICING_V1["openai"].get(call.model, {})
        input_cost = (call.prompt_tokens or 0) / 1000 * rates.get("input_per_1k", 0)
        output_cost = (call.completion_tokens or 0) / 1000 * rates.get("output_per_1k", 0)
        return round(input_cost + output_cost, 6)
    elif call.provider == "mcp":
        if call.cache_status == "hit":
            return 0.0  # Cache hits have zero marginal cost
        return PRICING_V1["mcp"].get(call.endpoint, PRICING_V1["mcp"]["default"])
    return 0.0
```

**Tradeoffs:**
- Pro: Simple, no external API dependency, works offline, fast
- Con: Drifts when providers change pricing
- Mitigation: Version the dict (`PRICING_V1`), log a warning when unknown models
  appear, add a `pricing_version` column if needed later
- Real billing reconciliation (OpenAI usage API, RentCast dashboard) is a v2 feature
  that validates the estimates

### 9. Simpler 80% Approach (answering Question 7)

If the full implementation feels too heavy for the first iteration, here is the
minimal version that still delivers most of the value:

**Skip the `api_call_log` table entirely.** Instead:
1. Instrument `mcp_client._post`/`._get` and `LLMClient.complete` to emit structured
   log lines (JSON) at INFO level with provider, endpoint, latency, cache_status,
   tokens.
2. Use the existing `RequestSummary` counters (already accumulated per-request) and
   expose them via a new field on `GET /sessions/{id}` response.
3. For cost estimation, compute it in a post-hoc log analysis script.

This gives you cost visibility via log aggregation (e.g., grep + jq) without any
schema changes. The downside is no per-session queryable data in the DB and no
frontend panel. I recommend the full approach since the incremental cost of the
table + endpoint is small and the payoff (frontend panel, per-listing unit economics)
is the stated goal.

## Error Model

| Code | Name | Retryable | Description |
|---|---|---|---|
| 404 | SESSION_NOT_FOUND | No | Session ID does not exist |
| 500 | CALL_LOG_WRITE_FAILED | Yes | Failed to flush call log to DB (non-fatal, log and continue) |

Call log failures MUST NOT break the hydration pipeline or API responses. The
`flush_call_log()` function wraps its DB write in a try/except and logs a WARNING
on failure. Observability data is best-effort.

## Caching Strategy

No new caching introduced. The feature reads and logs existing cache behavior.
The `cache_status` field on `TrackedCall` captures whether the originating call
was served from cache, which is the primary signal for cache optimization.

| Key Pattern | TTL | Invalidation |
|---|---|---|
| (no new cache keys) | -- | -- |

## Logging & Observability

| Event | Level | Context Fields |
|---|---|---|
| API call tracked | DEBUG | provider, endpoint, cache_status, latency_ms, session_id |
| Call log flushed | INFO | session_id, call_count, total_latency_ms, estimated_cost_usd |
| Call log flush failed | WARNING | session_id, error (full message per project convention) |
| Unknown model in pricing | WARNING | model, provider |

## Test Strategy

| Type | Scope | Location |
|---|---|---|
| Unit | TrackedCall creation, cost estimation, pricing table | `packages/core/observability/tests/test_call_tracker.py` |
| Unit | Call log accumulator (contextvar lifecycle) | `packages/core/observability/tests/test_call_tracker.py` |
| Unit | CallLogRepo insert/query | `apps/chat/db/tests/test_call_log_repo.py` |
| Integration | MCP client instrumentation emits TrackedCall | `apps/chat/tests/test_mcp_instrumentation.py` |
| Integration | Full hydration produces call log entries | `apps/chat/tests/test_hydration_call_log.py` |
| Integration | `/sessions/{id}/usage` returns correct aggregation | `apps/chat/tests/test_usage_endpoint.py` |

## Migration / Rollout Plan

1. **Schema migration**: Add `api_call_log` table via `schema.sql` update. SQLite
   `CREATE TABLE IF NOT EXISTS` is idempotent -- no migration script needed.
2. **Feature flag**: Not needed. Call tracking is backend-only, non-breaking, and
   the `/usage` endpoint is additive.
3. **Rollout**: Ship backend instrumentation first. Frontend "Usage & Costs" panel
   can follow in a separate PR once the endpoint is live and producing data.
4. **Backward compat**: No breaking changes. No existing APIs modified. New table
   and endpoint only.

## Architecture Decisions (ADR)

### ADR-1: Instrument at MCP Client, Not ProviderCache
- **Status**: Accepted
- **Context**: ProviderCache.get() does not know which provider or endpoint is
  being served (it only has a cache key hash). Adding provider context to every
  cache.get() call would require modifying all ~15 provider implementations.
  Meanwhile, STRSimulationMCPClient._post()/_get() is the single chokepoint for
  all hydration API calls and naturally has the path (endpoint) in its arguments.
- **Decision**: Instrument _post/_get on the MCP client. For provider-level cache
  attribution, extend CacheableService._cached_execute() with optional labels.
- **Consequences**: MCP-layer instrumentation captures 100% of hydration calls.
  Direct provider cache interactions (e.g., LLMClient's own cache check) need
  separate instrumentation in LLMClient.complete(). This is acceptable because
  LLMClient is the only provider that manages its own cache outside the MCP path.

### ADR-2: Explicit Context Copy for Background Threads
- **Status**: Accepted
- **Context**: `_run_hydration_background()` runs in `threading.Thread`, which does
  NOT inherit contextvars from the spawning thread. This means session_id, analysis_id,
  and the new call_log accumulator are all None in background hydration. This is
  actually a pre-existing bug: the `increment_cache_hits()` calls in ProviderCache
  silently no-op during background hydration because `RequestSummary` is None.
- **Decision**: Use `contextvars.copy_context()` at the thread spawn site and run
  the target function via `ctx.run()`. Apply this pattern at all 5 `threading.Thread`
  spawn sites in the chat app (sessions.py x3, assumptions.py, feedback.py,
  scenarios.py, workspaces.py).
- **Consequences**: Fixes the latent bug. All background work now participates in
  context-scoped observability. Slight increase in memory per thread (context copy),
  negligible at current concurrency levels.

### ADR-3: Accumulate in Memory, Batch Flush to DB
- **Status**: Accepted
- **Context**: Hydration makes 8-12 MCP calls. Inserting one DB row per call means
  8-12 SQLite write transactions during the performance-critical hydration window.
  SQLite WAL mode allows concurrent reads but serializes writes.
- **Decision**: Accumulate TrackedCall instances in a contextvar list during the
  lifecycle. Flush once at the end via executemany() in a single transaction.
- **Consequences**: Zero write overhead during hydration. One atomic batch at the
  end. Trade-off: if the process crashes mid-hydration, call log data is lost.
  Acceptable for observability data.

### ADR-4: Hardcoded Pricing Over Billing API
- **Status**: Accepted
- **Context**: OpenAI's usage API provides real billing data but requires additional
  API calls, authentication, and has rate limits. For the goal of understanding
  unit economics per listing, approximate costs computed from published pricing
  are sufficient.
- **Decision**: Hardcoded `PRICING_V1` dict with per-model token rates and per-
  endpoint MCP costs. Cache hits are costed at $0.00.
- **Consequences**: Costs may drift as providers update pricing. Mitigation: version
  the dict, log warnings for unknown models. Real billing reconciliation deferred
  to v2.

### ADR-5: Same DB, Indexed, With Periodic Cleanup
- **Status**: Accepted
- **Context**: api_call_log could reach ~300K rows/year at current usage. Options:
  (a) same SQLite DB with indexes, (b) separate SQLite DB, (c) external time-series
  DB.
- **Decision**: Same DB (`chat_sessions.db`) with indexes on `session_id` and
  `(provider, created_at)`. Add a 90-day cleanup endpoint.
- **Consequences**: Simplest approach. No cross-DB join issues. SQLite handles
  300K rows trivially. The `ON DELETE CASCADE` on session_id means deleting old
  sessions automatically cleans up call logs. If growth exceeds expectations, the
  table can be moved to a separate DB as a non-breaking change.
