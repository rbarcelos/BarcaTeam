# Engineer Task: Wire Listing Extraction to MCP API

## Your Working Directory
`C:/Users/rbarcelo/repo/worktrees/listing-extract-mcp/senior-engineer`

## Your Branch
`agent/senior-engineer/listing-extract-mcp`

Base all changes in this worktree. Do not work outside it.

## Architecture Document
Read: `docs/capabilities/listing-extract-mcp/ARCHITECTURE.md` in your worktree.

## Team Plan
Read: `C:/Users/rbarcelo/repo/barcaTeam/team_plan.md`

## What to implement

You need to make 3 changes across 3 files. Follow investFlorida.ai CLAUDE.md Gate 1 rules (max 3 files, max 120 LOC, max 50 LOC per function).

### Change 1: Add `extract_listing()` to PropertyIntelligenceClient

File: `src/services/property_intelligence_client.py`

Add a new method `extract_listing()` that calls `POST /listing/extract` on the server. Follow the exact same pattern as other methods in this class (e.g., `get_str_viability()`, `get_str_estimate()`):

```python
def extract_listing(
    self,
    url: str,
    fields: Optional[List[str]] = None,
    bypass_cache: Optional[bool] = None,
) -> Optional[Dict[str, Any]]:
    """
    Extract structured property data from a listing URL via server-side LLM.

    Calls POST /listing/extract on str_simulation. The server fetches the listing
    page, cleans HTML, and extracts structured property data using LLM.

    Args:
        url: Full listing page URL (Zillow, Redfin, Realtor.com, etc.)
        fields: Specific fields to extract. None = extract all standard fields.
        bypass_cache: Whether to bypass server-side HTML + LLM caches.

    Returns:
        Response dict with keys: success, property_data, confidence_scores, metadata, error.
        Returns None on network/API failure.
    """
    payload = {"url": url}
    if fields is not None:
        payload["fields"] = fields
    if bypass_cache is not None:
        payload["bypass_cache"] = bypass_cache
    elif self._bypass_cache:
        payload["bypass_cache"] = True

    try:
        response = self._request(
            "POST",
            "/listing/extract",
            json_data=payload,
            timeout=60,  # server has 45s internal timeout, add margin
        )
        if response and response.get("success"):
            meta = response.get("metadata", {})
            logger.info(
                "Listing extraction via server: %d fields, avg_confidence=%.2f, %.2fs",
                meta.get("fields_with_value", 0),
                meta.get("avg_confidence", 0),
                meta.get("total_time_seconds", 0),
            )
        elif response:
            logger.warning(
                "Server listing extraction failed: %s",
                response.get("error", "unknown error"),
            )
        return response
    except Exception as e:
        logger.error("Listing extraction request failed: %s", e)
        return None
```

### Change 2: Add server-first extraction to PropertyListingAgent

File: `src/agents/property_listing_agent.py`

1. Add optional `api_client` parameter to `__init__`:
   ```python
   def __init__(
       self,
       llm_service: LLMExtractionService,
       web_fetcher: WebFetcher,
       api_client: Optional["PropertyIntelligenceClient"] = None,
   ) -> None:
       super().__init__("PropertyListingAgent")
       self.llm_service = llm_service
       self.web_fetcher = web_fetcher
       self.api_client = api_client
   ```

2. Add a private method `_try_server_extraction()` that calls the API and maps the response:
   ```python
   def _try_server_extraction(self, url: str, fields: List[str]) -> Optional[Dict[str, Any]]:
       """Try extracting via server API. Returns agent-format result or None."""
       if self.api_client is None:
           return None
       response = self.api_client.extract_listing(url=url, fields=fields)
       if response is None or not response.get("success"):
           return None
       property_data_dict = response.get("property_data")
       confidence_scores = response.get("confidence_scores", {})
       if not property_data_dict:
           return None
       meta = response.get("metadata", {})
       return {
           "property_data": property_data_dict,
           "confidence_scores": confidence_scores,
           "from_cache": meta.get("from_cache", False),
           "fetch_time_seconds": meta.get("fetch_time_seconds", 0),
           "extraction_time_seconds": meta.get("extraction_time_seconds", 0),
           "fields_extracted": meta.get("fields_extracted", 0),
           "fields_with_value": meta.get("fields_with_value", 0),
           "avg_confidence": meta.get("avg_confidence", 0),
           "source": "server_api",
       }
   ```

3. Modify `extract_properties()` to try server first, then fall back:
   At the beginning of `extract_properties()`, BEFORE the existing local extraction code, add:
   ```python
   required_fields = [d.name for d in self.get_typical_properties()]

   # Try server-side extraction first (MCP API)
   server_result = self._try_server_extraction(property_url, required_fields)
   if server_result is not None:
       logger.info("Using server-side listing extraction for %s", property_url[:80])
       raw_data = server_result["property_data"].copy()
       raw_data["confidence_scores"] = server_result["confidence_scores"]
       extraction_data = server_result["property_data"].copy()
       extraction_data["confidence"] = server_result["confidence_scores"]
       extraction_data["listing_url"] = property_url
       property_data = PropertyData.from_extraction(extraction_data, raw_data=raw_data)
       return {
           "source": "property_listing_agent",
           "data": {
               "property_data": property_data.model_dump(exclude_none=True),
               "confidence_scores": server_result["confidence_scores"],
           },
           "metadata": {
               "property_url": property_url,
               "from_cache": server_result["from_cache"],
               "fetch_time_seconds": server_result["fetch_time_seconds"],
               "extraction_time_seconds": server_result["extraction_time_seconds"],
               "fields_extracted": server_result["fields_extracted"],
               "fields_with_value": server_result["fields_with_value"],
               "avg_confidence": server_result["avg_confidence"],
               "extraction_source": "server_api",
           },
       }

   logger.info("Server extraction unavailable, using local extraction for %s", property_url[:80])
   # ... existing local extraction code continues below ...
   ```

IMPORTANT: The existing local extraction code must remain exactly as-is after this new block. The only structural change is adding the server-first attempt at the top of `extract_properties()`.

### Change 3: Pass api_client to PropertyListingAgent in property_analyzer.py

File: `src/pipeline/property_analyzer.py`

In the method that creates the `PropertyListingAgent` (around line 1275), add the `api_client` parameter. The `PropertyIntelligenceClient` should already be available as `self.intelligence_client` or similar in the analyzer. Find where the agent is constructed and add:

```python
agent = PropertyListingAgent(
    llm_service=llm_service,
    web_fetcher=web_fetcher,
    api_client=self.intelligence_client,  # or whatever the existing instance name is
)
```

You need to find the actual instance variable name by reading the file. Look for `PropertyIntelligenceClient` instantiation in the class.

## Verification Steps

After implementing all 3 changes:

1. Syntax check all modified files:
   ```bash
   python -m py_compile src/services/property_intelligence_client.py
   python -m py_compile src/agents/property_listing_agent.py
   python -m py_compile src/pipeline/property_analyzer.py
   ```

2. Commit each logical change separately with conventional commit messages.

3. After all commits, confirm with `git log --oneline -5`.

## Constraints

- Max 3 files modified
- Max 120 LOC total across all changes
- Max 50 LOC per function
- Follow existing code patterns exactly
- Do NOT delete or modify existing local extraction code (it becomes the fallback)
- Do NOT import anything that isn't already available in the module
- Use `from __future__ import annotations` if needed for forward references
