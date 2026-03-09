# Listing Extraction MCP Endpoint — Architecture Design

**Status:** Design
**Date:** 2026-03-09
**Scope:** New `POST /listing/extract` endpoint on str_simulation server

---

## 1. Problem Statement

Today the investFlorida.ai client performs listing extraction locally:

1. `WebFetcher.fetch_property_page(url)` — HTTP fetch with retry (tenacity)
2. `WebFetcher.clean_html_for_llm(html)` — BS4 cleanup, JSON-LD extraction, token truncation
3. `LLMExtractionService.extract_property_data(html, url, fields)` — LLM structured extraction
4. `PropertyData.from_extraction(data)` — validation & normalization

This couples the client to HTTP fetching, HTML parsing (BeautifulSoup), prompt management, and direct LLM access. Moving this to the server:

- Centralizes LLM cost tracking and caching
- Lets the client stay thin (URL in, structured data out)
- Enables server-side caching at both the HTML and extraction layers
- Allows the server to evolve extraction logic without client releases

---

## 2. Server-Side Directory Layout

Following existing str_simulation conventions:

```
str_simulation/
  src/
    apps/analytics/routes/
      listing_extract.py          # NEW — FastAPI route (POST /listing/extract)
    services/
      listing_page_service.py     # NEW — orchestrates fetch → clean → extract
    models/
      listing_extract_models.py   # NEW — Pydantic request/response models
    prompts/
      listing_extraction.md       # NEW — LLM extraction prompt (from investFlorida.ai)
```

**Rationale:**
- Route file follows the `router = APIRouter(...)` + module-level service setter pattern used by `properties.py`, `investment.py`, etc.
- Service file keeps business logic out of the route, following the existing separation (`investment_service.py`, `property_service.py`).
- Models file follows the `investment_service.py` pattern where Pydantic request/response models are co-located with (or near) the service.
- Prompt lives in a `.md` file per the CLAUDE.md LLM rule: "Prompts MUST live in `.md` files."

---

## 3. API Contract

### 3.1 Endpoint

```
POST /listing/extract
Content-Type: application/json
```

### 3.2 Request Model

```python
class ListingExtractRequest(BaseModel):
    """Request to extract structured property data from a listing URL."""

    url: str = Field(
        ...,
        description="Full URL of the property listing page",
        examples=["https://www.redfin.com/FL/Miami/3900-Biscayne-Blvd-S304"],
    )
    bypass_cache: bool = Field(
        default=False,
        description="If True, bypass both HTML fetch cache and LLM extraction cache",
    )
    fields: Optional[List[str]] = Field(
        default=None,
        description=(
            "Specific field names to extract. If None, extracts all standard fields "
            "defined by the server's field registry. "
            "Examples: ['price', 'beds', 'baths', 'sqft', 'amenities', 'hoa_fee']"
        ),
    )
    max_html_tokens: Optional[int] = Field(
        default=None,
        ge=1000,
        le=120000,
        description=(
            "Override max token limit for cleaned HTML sent to LLM. "
            "Server default: 80000. Increase for complex listings."
        ),
    )
```

**Design decisions:**
- `url` is the only required field — minimal friction for the client.
- `fields` is optional; when omitted the server uses its full `FieldDefinitions` registry (derived from `PropertyData` model). This means the client doesn't need to maintain field lists.
- `max_html_tokens` is optional for edge cases; server default (80k) works for 95% of listings.

### 3.3 Response Model

```python
class ExtractionMetadata(BaseModel):
    """Timing, cache, and quality metadata for the extraction."""

    listing_url: str
    from_cache: bool = Field(description="True if HTML was served from cache")
    extraction_cached: bool = Field(description="True if LLM extraction result was cached")
    fetch_time_seconds: float = Field(description="Wall time for HTML fetch (0 if cached)")
    extraction_time_seconds: float = Field(description="Wall time for LLM extraction (0 if cached)")
    total_time_seconds: float = Field(description="Total wall time for the request")
    fields_extracted: int = Field(description="Number of fields returned by LLM")
    fields_with_value: int = Field(description="Number of fields with non-null values")
    avg_confidence: float = Field(ge=0.0, le=1.0, description="Mean confidence across all fields")
    html_tokens: int = Field(description="Token count of cleaned HTML sent to LLM")
    model_used: str = Field(description="LLM model identifier used for extraction")


class ListingExtractResponse(BaseModel):
    """Structured property data extracted from a listing URL."""

    success: bool
    property_data: Optional[Dict[str, Any]] = Field(
        default=None,
        description=(
            "Extracted property fields. Keys match PropertyData field names: "
            "address, price, beds, baths, sqft, year_built, hoa_fee, property_tax, "
            "amenities, city, state, zip_code, county, property_type, has_hoa, "
            "hoa_community_name, str_allowed, min_rental_days, rental_restrictions, "
            "str_features_critical, str_features_premium, str_features_standard, "
            "listing_description, walkability_score, transit_score, bike_score, etc."
        ),
    )
    confidence_scores: Optional[Dict[str, float]] = Field(
        default=None,
        description="Per-field confidence scores (0.0-1.0). Keys match property_data keys.",
    )
    metadata: Optional[ExtractionMetadata] = None
    error: Optional[str] = Field(
        default=None,
        description="Error message when success=False",
    )
```

**Design decisions:**
- `property_data` is `Dict[str, Any]` rather than a rigid Pydantic model so the server can evolve fields without breaking the client contract. The client-side `PropertyData.from_extraction()` already handles normalization.
- `confidence_scores` is a separate top-level field (not nested inside `property_data`) matching the current `ExtractionResult` pattern.
- `metadata` bundles all operational info; the client can log/display cache status and timing without polluting property data.
- `model_used` in metadata enables the client to track which LLM produced the extraction (important for cost and quality monitoring).

### 3.4 Example Request/Response

**Request:**
```json
{
  "url": "https://www.redfin.com/FL/Miami/3900-Biscayne-Blvd-unit-S304/home/171234567",
  "bypass_cache": false
}
```

**Response (success):**
```json
{
  "success": true,
  "property_data": {
    "address": "3900 Biscayne Blvd Unit S304, Miami, FL 33137",
    "price": 520000.0,
    "beds": 2,
    "baths": 2.0,
    "sqft": 1150,
    "year_built": 2020,
    "hoa_fee": 750.0,
    "property_type": "Condo",
    "amenities": ["Pool", "Gym", "Concierge", "Rooftop Terrace", "EV Chargers"],
    "city": "Miami",
    "state": "FL",
    "zip_code": "33137",
    "county": "Miami-Dade",
    "has_hoa": true,
    "hoa_community_name": "QUADRO",
    "str_allowed": "yes",
    "str_features_premium": ["pool", "rooftop", "gym", "concierge"],
    "walkability_score": 87.0,
    "listing_status": "Active"
  },
  "confidence_scores": {
    "address": 0.98,
    "price": 0.99,
    "beds": 0.99,
    "baths": 0.99,
    "sqft": 0.95,
    "hoa_fee": 0.85,
    "amenities": 0.80,
    "str_allowed": 0.60
  },
  "metadata": {
    "listing_url": "https://www.redfin.com/FL/Miami/3900-Biscayne-Blvd-unit-S304/home/171234567",
    "from_cache": false,
    "extraction_cached": false,
    "fetch_time_seconds": 2.31,
    "extraction_time_seconds": 4.87,
    "total_time_seconds": 7.18,
    "fields_extracted": 18,
    "fields_with_value": 16,
    "avg_confidence": 0.88,
    "html_tokens": 42350,
    "model_used": "gpt-4o-2024-08-06"
  },
  "error": null
}
```

**Response (failure — fetch error):**
```json
{
  "success": false,
  "property_data": null,
  "confidence_scores": null,
  "metadata": {
    "listing_url": "https://example.com/bad-listing",
    "from_cache": false,
    "extraction_cached": false,
    "fetch_time_seconds": 5.02,
    "extraction_time_seconds": 0.0,
    "total_time_seconds": 5.02,
    "fields_extracted": 0,
    "fields_with_value": 0,
    "avg_confidence": 0.0,
    "html_tokens": 0,
    "model_used": ""
  },
  "error": "Failed to fetch listing page after 3 attempts: Timeout"
}
```

---

## 4. Error Handling Strategy

| Scenario | HTTP Status | `success` | `error` value |
|----------|-------------|-----------|---------------|
| Happy path | 200 | `true` | `null` |
| Fetch failed (timeout, 403, 404, connection) | 200 | `false` | Descriptive message |
| LLM extraction failed (parse error, timeout) | 200 | `false` | Descriptive message |
| Invalid request (bad URL format, bad field names) | 422 | N/A | FastAPI validation detail |
| Service not initialized | 503 | N/A | "ListingPageService not available" |
| Unexpected server error | 500 | N/A | "Internal server error" |

**Key design choice:** Fetch and extraction failures return HTTP 200 with `success=false`. This follows the pattern used by `ExtractionResult.failure()` on the client — the caller can distinguish "the endpoint worked but the listing couldn't be extracted" from "the server is broken." The client already handles `success=false` in `PropertyListingAgent.extract_properties()`.

---

## 5. Service Architecture

```
┌─────────────────────────────────────────────────────┐
│  POST /listing/extract                              │
│  listing_extract.py (route)                         │
│  - Validates ListingExtractRequest                  │
│  - Calls ListingPageService.extract(request)        │
│  - Returns ListingExtractResponse                   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  ListingPageService                                 │
│  listing_page_service.py                            │
│  - Orchestrates the 3-step pipeline:                │
│    1. fetch_html(url, bypass_cache)                 │
│    2. clean_html(raw_html, max_tokens)              │
│    3. extract_fields(cleaned_html, url, fields)     │
│  - Manages two cache layers:                        │
│    • HTML cache (ProviderCache, TTL=1h)             │
│    • Extraction cache (LLMClient, key=url+fields)   │
│  - Dependencies (injected):                         │
│    • httpx.AsyncClient (for async fetch)            │
│    • LLMClient (for extraction)                     │
│    • PromptManager (for extraction prompt)           │
│    • ProviderCache (for HTML caching)               │
└─────────────────────────────────────────────────────┘
```

### 5.1 Key Implementation Notes

1. **Async fetch:** Use `httpx.AsyncClient` instead of `requests.Session` since the server is async FastAPI. Port the retry logic using `tenacity` (already a server dependency) with the same 3-attempt exponential backoff.

2. **HTML cleaning:** Port `WebFetcher.clean_html_for_llm()` logic (BS4 boilerplate removal, JSON-LD extraction, token truncation). This is ~130 lines of pure transformation — no external dependencies beyond `beautifulsoup4` and the token utils.

3. **LLM extraction:** Use the server's existing `LLMClient` (OpenAI-based) with the extraction prompt ported from `investFlorida.ai/src/prompts/llm_extraction_service.md`. The prompt + field definitions define the extraction contract.

4. **Caching strategy:**
   - **HTML layer:** Cache raw HTML by URL in `ProviderCache` (TTL=1 hour). This avoids redundant fetches when the same listing is analyzed multiple times.
   - **Extraction layer:** Cache LLM output by `{model}:{url}:{sorted_fields}` key (same stable-key approach as current `LLMExtractionService`). LLM cache TTL = 24 hours (extraction results are stable for a listing).
   - `bypass_cache=true` skips reading from both caches but still writes results.

5. **Field definitions:** Port `FieldDefinitions` class (reads from `PropertyData` model fields). Or, simpler: define the field list + descriptions in the extraction prompt `.md` file and keep a static list in the service. The server doesn't need the full `PropertyData` Pydantic model — it returns raw extracted dict.

6. **Timeout:** Route-level `asyncio.wait_for(timeout=45.0)` — accounts for fetch (up to 30s with retries) + LLM call (10-15s).

### 5.2 Dependency Injection

Following the `properties.py` setter pattern:

```python
# listing_extract.py
_listing_page_service: Optional[ListingPageService] = None

def set_listing_page_service(service: ListingPageService):
    global _listing_page_service
    _listing_page_service = service

def get_listing_page_service() -> ListingPageService:
    if _listing_page_service is None:
        raise HTTPException(status_code=503, detail="ListingPageService not available")
    return _listing_page_service
```

Wire in `__init__.py` `configure_services()` and app startup.

---

## 6. Client-Side Changes (investFlorida.ai)

After the server endpoint is deployed, the client refactor (Task #2) replaces:

```python
# BEFORE (3 local steps)
fetch_result = self.web_fetcher.fetch_property_page(url)
cleaned_html = self.web_fetcher.clean_html_for_llm(fetch_result.html)
extraction_result = self.llm_service.extract_property_data(cleaned_html, url, fields)
```

With:

```python
# AFTER (1 MCP call)
response = self.pi_client.extract_listing(url, bypass_cache=False)
# response is already ListingExtractResponse-shaped dict
```

A new method on `PropertyIntelligenceClient`:

```python
async def extract_listing(
    self, url: str, bypass_cache: bool = False, fields: list[str] | None = None
) -> dict:
    return await self._post("/listing/extract", {
        "url": url,
        "bypass_cache": bypass_cache,
        "fields": fields,
    })
```

`PropertyListingAgent.extract_properties()` consumes the response and feeds it into `PropertyData.from_extraction()` exactly as it does today — the response shape is designed to be a drop-in replacement.

---

## 7. Migration & Rollback Strategy

1. **Phase 1 — Server deploy:** Ship the new endpoint. No client changes. Both paths work independently.
2. **Phase 2 — Client feature flag:** Add `USE_MCP_LISTING_EXTRACTION=true` env var. When true, `PropertyListingAgent` calls the MCP endpoint. When false (default), uses local extraction. This enables gradual rollout and A/B comparison.
3. **Phase 3 — Remove local extraction:** Once MCP extraction is validated (confidence scores match, timing acceptable), remove `WebFetcher`, `LLMExtractionService`, and related local dependencies from the client.

**Rollback:** Set `USE_MCP_LISTING_EXTRACTION=false` at any point to revert to local extraction. No code changes needed.

---

## 8. Open Questions

1. **Rate limiting:** Should the endpoint have per-client rate limits? Fetching external listing pages at high volume could trigger anti-bot measures on Redfin/Zillow. Consider a server-side queue or concurrency limit (e.g., max 3 concurrent fetches).

2. **URL allowlist:** Should we restrict to known listing sites (redfin.com, zillow.com, realtor.com) or accept any URL? Security consideration: SSRF risk if the server fetches arbitrary URLs. Recommend an allowlist.

3. **Trafilatura vs BS4:** The client has both `clean_html_for_llm()` (BS4) and `clean_html_for_llm_trafilatura()`. Which to port? Recommend starting with BS4 (proven, no extra dependency) and adding trafilatura as an optional enhancement later.
