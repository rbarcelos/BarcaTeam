# PM Brief: API Call Tracking & Cost Observability
**Slug**: `api-cost-observability`
**Date**: 2026-04-03
**Author**: PM Agent
**GH Issue**: rbarcelos/investFlorida.ai#1534

## Context (Discovery Summary)

The investFlorida.ai codebase is a Python monorepo (FastAPI backend, Next.js frontend) serving STR investment analysis. Key findings from discovery:

1. **CallTracker already exists** (`packages/utils/call_tracker.py`) -- a global singleton that records LLM calls (model, tokens in/out, duration, cache_hit, phase) and API calls (type, endpoint, duration, cache_hit). It already has `estimate_cost()` with a MODEL_COSTS pricing table and `to_dict()` serialization. It is used in the pipeline CLI (`property_analyzer.py`) and the main `LLMClient` (`packages/utils/llm_client.py`).
2. **ProviderCache** (`packages/core/providers/cache.py`) is the shared disk-based caching layer used by ~50 services. It tracks hits/misses in-memory via `CacheStats` and increments per-request counters via `analysis_id.py` middleware contextvars.
3. **analysis_id middleware** (`packages/core/middleware/analysis_id.py`) already uses `contextvars` for `session_id`, `analysis_id`, `user_id`, and a `RequestSummary` dataclass with `provider_calls`, `cache_hits`, `cache_misses` -- all per-request.
4. **usage_events table** (migration 006) exists for high-level analytics events (analysis_started, report_generated, scenario_run) via `AnalyticsService`. It is user-level, event-type keyed, with a metadata_json blob. It was designed for metering/billing, not per-call observability.
5. **CallTracker is in-memory only** -- it resets on every `start_execution()` call and has no persistence layer. Data is lost after each pipeline run or server restart.
6. **PropertyCard.tsx** currently has a hover-reveal delete button (with inline confirm) and links the entire card to `/session/{id}`. There is no "..." kebab menu.
7. **MODEL_COSTS in call_tracker.py is outdated** -- missing gpt-5.1, gpt-5.1-mini, and the pricing is labeled "2024".

## Problem Statement

Each listing session triggers 20-30+ external API calls (STR Simulation API, OpenAI LLM, web scraping, optional enrichment APIs) plus dozens of cache lookups, but there is zero per-session cost visibility. The existing `CallTracker` collects the right data in-memory during pipeline execution, but:

- Data is never persisted to the database
- Data is not linked to a chat session_id
- There is no API endpoint to retrieve it
- There is no UI surface for users to see it
- The LLM pricing table is stale

This blocks three business needs:
1. **Unit economics** -- understanding cost-per-listing to inform pricing decisions
2. **Cache optimization** -- identifying which providers have low hit rates and should be tuned
3. **Operational awareness** -- detecting cost spikes from model changes or broken caches

## Goals

1. Persist per-session API call tracking data so it survives server restarts and is queryable
2. Expose per-session cost and usage data via a REST endpoint
3. Surface cost/usage information in the frontend UI for session owners
4. Update LLM pricing to reflect current models (gpt-5.1, gpt-5.1-mini, o1, o3)
5. Bridge the gap between the existing CallTracker (pipeline) and the chat session flow

## Non-Goals

- Real-time cost alerts or budget caps (future feature)
- Per-user billing or Stripe metering integration (usage_events + subscription_plans handle this separately)
- Tracking internal financials endpoints (only external paid APIs and LLM calls)
- Admin dashboard or aggregate analytics across all sessions (this is per-session only)
- Changing the CallTracker singleton pattern itself (we extend it, not replace it)

## Personas

| Persona | Category | Description | Key Needs |
|---|---|---|---|
| Investor (end user) | Direct user | Uses the platform to analyze STR properties via chat | Understand what the analysis "costs" them; see how fresh vs cached the data is |
| Product Owner | Operator | Decides pricing, monitors unit economics | Per-listing cost breakdown to inform tier pricing; aggregate cost trends |
| Engineer (debugging) | Operator | Diagnoses slow or expensive sessions | Call-level detail: which providers were slow, which cache missed, which LLM calls consumed the most tokens |

## User Stories

- As an **Investor**, I want to see a cost summary for my analyzed property so that I understand the value being delivered per analysis.
- As a **Product Owner**, I want to query per-session API costs so that I can calculate unit economics and set pricing tiers.
- As an **Engineer**, I want to see per-call detail (provider, latency, cache status, tokens) for any session so that I can diagnose performance or cost issues.

## Acceptance Criteria

| ID | Criterion | Priority |
|---|---|---|
| AC-1 | Every external API call made during a session is persisted to a new `api_call_log` table with: session_id, provider, endpoint, call_type, cache_status (hit/miss/bypass/stale_fallback), latency_ms, status_code, timestamp | Must-have |
| AC-2 | Every LLM call is persisted with: session_id, model, input_tokens, output_tokens, prompt_category/phase, cache_hit, latency_ms, estimated_cost_usd | Must-have |
| AC-3 | Data is linked to session_id via the existing contextvars infrastructure (no coupling to business logic) | Must-have |
| AC-4 | A `GET /chat/sessions/{id}/usage` endpoint returns aggregated usage: total calls, cache hit rate, total tokens (input/output), estimated cost by provider, call count by provider | Must-have |
| AC-5 | The endpoint also returns the raw call log (paginated) for detailed inspection | Should-have |
| AC-6 | LLM cost pricing table is updated to include gpt-5.1, gpt-5.1-mini, o1, o3, and current 2026 pricing | Must-have |
| AC-7 | External API calls priced at per-call rates where applicable (STR Simulation API calls, Google Maps, RentCast) in the pricing config | Should-have |
| AC-8 | Frontend exposes per-session cost data -- accessible from the session page (not the PropertyCard on the home page) | Must-have |
| AC-9 | UI shows: total estimated cost, cache hit rate, token counts (input/output), and cost breakdown by provider | Must-have |
| AC-10 | UI shows a call log table with: provider, endpoint, cache status, latency, tokens (for LLM), timestamp | Should-have |
| AC-11 | The `usage_events` table continues to work independently -- this does not replace or modify it | Must-have |
| AC-12 | The api_call_log table has proper indexes on session_id and timestamp for query performance | Must-have |
| AC-13 | Persistence is fire-and-forget: tracking failures never block or slow down the analysis pipeline | Must-have |
| AC-14 | Pipeline CallTracker data is flushed to the DB at pipeline completion (batch write, not per-call) | Should-have |

## Scope Adjustments (Answers to Proposal Questions)

### Q1: Is the scope right?

The scope is slightly adjusted from the proposal:

- **Removed**: The "..." kebab menu on PropertyCard. The PropertyCard is a compact navigation element on the home page; adding a menu there adds interaction complexity for minimal value. Usage data belongs on the session detail page where the user is already reviewing their analysis.
- **Retained**: Everything else from the proposal is in scope.
- **Added**: AC-6 (pricing update) and AC-14 (batch persistence) which were implicit but not stated.

### Q2: Usage visibility -- end users or admins only?

**Decision: Visible to session owners.** The investor persona benefits from seeing "this analysis used X API calls and Y LLM tokens, costing approximately $Z" -- it communicates value. The cost shown is estimated platform cost, not a charge to the user (pricing tiers are separate). If this feels too transparent, we can gate it behind a "developer mode" toggle in a follow-up.

### Q3: UI location -- kebab menu vs session detail page?

**Decision: Session detail page.** The cost summary should appear as a collapsible section or tab on the session detail page (`/session/{sessionId}`), not via a kebab menu on the PropertyCard. Rationale:
- The PropertyCard is already dense (photo, price, specs, status badge, delete button)
- Usage data is a drill-down concern, not a glanceable metric
- The session detail page is where the user reviews their analysis -- cost is contextual there

### Q4: Track internal API calls?

**Decision: External calls and LLM only.** Internal financials endpoints (`/financials/*`) are free compute on our own server. Tracking them adds noise without helping unit economics. The CallTracker already distinguishes `REST_API` from `MARKET_API` -- we persist only calls with cost implications.

### Q5: Missing acceptance criteria?

Added:
- AC-11 (usage_events independence)
- AC-12 (DB indexes)
- AC-13 (fire-and-forget)
- AC-14 (batch write)

### Q6: Conflict with usage_events table?

**No conflict -- complementary.** The `usage_events` table (migration 006) tracks high-level lifecycle events (analysis_started, analysis_completed, scenario_run) for metering and billing. The new `api_call_log` table tracks individual API calls for cost observability. They serve different purposes:

| Concern | usage_events | api_call_log (new) |
|---|---|---|
| Granularity | Session lifecycle events | Individual API/LLM calls |
| Purpose | Billing metering | Cost observability |
| Cardinality | ~3-5 rows per session | ~20-40 rows per session |
| Keyed by | user_id + event_type | session_id + timestamp |

## Edge Cases & Risks

| Risk | Impact | Mitigation |
|---|---|---|
| CallTracker is a singleton -- concurrent sessions on the server will mix data | High | The flush-to-DB approach must use session_id from contextvars, not the singleton's aggregated state. Each call should be individually tagged with session_id at recording time, not at flush time. |
| Batch DB write at pipeline completion could lose data on crash | Medium | Accept this for MVP. A follow-up can add periodic intermediate flushes or write-ahead logging. |
| LLM pricing becomes stale again as models change | Low | Store pricing in `config/services_config.yaml` (already used for model config), not hardcoded in Python. Make it a data file, not code. |
| High write volume -- 30+ rows per session could strain SQLite | Low | SQLite easily handles this volume. The chat DB already does multi-table writes per session. Add indexes per AC-12. |
| Cache status taxonomy ambiguity (what counts as "stale_fallback"?) | Medium | Define cache_status enum explicitly: `hit`, `miss`, `bypass`, `stale_fallback`, `disabled`. ProviderCache already distinguishes these states. |
| PropertyCard kebab menu (from proposal) is complex for the card's current role | Medium | Resolved by moving usage UI to session detail page (see Q3 above). |

## Success Metrics

- **Per-session cost data available** for 100% of new sessions within 1 week of launch
- **Average estimated cost per listing** can be calculated from the DB (baseline metric for pricing decisions)
- **Cache hit rate per provider** is visible, enabling targeted cache tuning
- **Zero performance regression**: pipeline latency does not increase by more than 50ms due to tracking overhead
- **Zero data loss in pipeline**: fire-and-forget tracking never throws exceptions that reach the user

## Rollout Notes

- **Phase 1 (this capability)**: Backend persistence + API endpoint + basic frontend display
- **Phase 2 (follow-up)**: Aggregate dashboard for product owner (cross-session cost trends), pricing config moved to YAML
- **No feature flag needed**: This is additive instrumentation. The usage endpoint is new (no breaking changes). The UI is a new section on an existing page.
- **Migration**: New `api_call_log` table added via a new migration file (007 or next available number). No changes to existing tables.
- **Backward compatibility**: Sessions created before this feature will simply have no usage data -- the UI handles this gracefully with an "unavailable" state.

---

## Handoff: PM --> Architect

**Capability**: `api-cost-observability`
**Document**: `C:\Users\rbarcelo\repo\barcaTeam\docs\capabilities\api-cost-observability\PM_BRIEF.md`

### Key Decisions

1. **UI lives on session detail page**, not PropertyCard kebab menu -- reduces card complexity, matches user intent flow
2. **Complementary to usage_events** -- new api_call_log table, different purpose, different granularity
3. **External calls + LLM only** -- no tracking of internal financials endpoints
4. **Fire-and-forget persistence** -- tracking failures must never block the pipeline
5. **Session_id via contextvars** -- already in analysis_id.py middleware, just needs to be set by chat orchestrator

### Open Questions for Architect

- Should the api_call_log table live in the chat SQLite DB or a separate observability DB?
- Should we modify the existing CallTracker singleton to tag calls with session_id at recording time, or create a new session-scoped tracker?
- The ProviderCache.get() increments per-request counters via analysis_id.py -- should call_log writes hook into the same middleware, or be a separate path via CallTracker?
- Should the batch flush happen in a finally block of the pipeline, or via a background task?

### Watch Out For

- The CallTracker singleton pattern is a concurrency hazard for the server (multiple sessions in flight). The architect must address this -- likely by making CallTracker session-scoped or by tagging each record with session_id at recording time.
- MODEL_COSTS is hardcoded as a Python dict. Moving to YAML or config is a should-have but affects architecture.
- The `LLMClient` in `packages/core/providers/implementations/llm_client.py` (event dedup) is a DIFFERENT class from the main `LLMClient` in `packages/utils/llm_client.py`. Both need instrumentation.

### Acceptance Criteria Summary

Must-have: AC-1, AC-2, AC-3, AC-4, AC-6, AC-8, AC-9, AC-11, AC-12, AC-13
Should-have: AC-5, AC-7, AC-10, AC-14
