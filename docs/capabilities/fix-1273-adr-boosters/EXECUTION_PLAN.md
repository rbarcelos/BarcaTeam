# Execution Plan: ADR Booster Fix
**Slug**: `fix-1273-adr-boosters`
**Date**: 2026-03-29
**Author**: Senior Engineer Agent

## Streams
| Stream | Repo | Can Parallelize With | Estimated Complexity |
|---|---|---|---|
| mcp_client market context | investFlorida.ai | adjusted_estimate logging | S |
| adjusted_estimate city/state + logging | investFlorida.ai | mcp_client | S |
| tests | investFlorida.ai | — (after impl) | S |

## GitHub Issues
| Issue # | Title | Repo | Stream | AC Mapping |
|---|---|---|---|---|
| #1273 | Building boosters and location adjustments not applied to chat ADR | investFlorida.ai | all | AC-1,2,3,4 |

## Implementation Order
1. Add `/str/market` parallel fetch to `estimate_str_revenue_full` — this is the biggest base ADR gap
2. Pass `city`/`state` to `get_location_score` in `adjusted_estimate.py` — fixes silent location-score skip
3. Add diagnostic logging throughout booster fetch paths — makes future debugging easy
4. Write tests covering all three fixes

## Worktrees
| Repo | Branch | Path |
|---|---|---|
| investFlorida.ai | `fix/1273-adr-boosters` | C:\Users\rbarcelo\repo\investFlorida.ai |

## Test Plan
| Test | Type | Command | Covers |
|---|---|---|---|
| test_adr_boosters.py (10 tests) | unit | `pytest tests/unit/chat/test_adr_boosters.py -v` | AC-1,2,3,4 |
| test_adjusted_estimate_wiring.py (15 tests) | unit | `pytest tests/unit/chat/test_adjusted_estimate_wiring.py -v` | wiring regression |
| test_hydration_service.py | unit | `pytest tests/unit/chat/test_hydration_service.py -v` | regression |

## Root Cause Summary

Two independent causes for ADR gap (chat $223 vs report $375):

1. **Base ADR not anchored to market data**: `estimate_str_revenue_full` called `/str/estimate`
   without `market_context`. The pipeline's `APIADRStrategy` fetches `/str/market` first (AirDNA
   anchors) and passes it to `/str/estimate` for a higher base ADR. Fix: parallel `/str/market`
   fetch in `mcp_client.estimate_str_revenue_full`.

2. **Location score silently failing**: `_fetch_location_score` in `adjusted_estimate.py` did not
   pass `city`/`state` to the geocoding API. Ambiguous addresses without city/state may fail to
   geocode, returning empty results → no location adjustment applied. Fix: forward `city`/`state`
   from session context.

## Deviations from Architecture
| What | Why | Impact |
|---|---|---|
| Used ThreadPoolExecutor in mcp_client | estimate_str_revenue_full is sync; /str/comparables and /str/market are independent — parallel saves ~200ms per hydration | Same latency pattern as adjusted_estimate.py already uses |

## PR
https://github.com/rbarcelos/investFlorida.ai/pull/1277
