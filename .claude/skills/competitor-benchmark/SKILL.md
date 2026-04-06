# Competitor Benchmark

Structured competitive intelligence gathering and analysis for STR investment tools. Used by the `competitor-analyst` agent and during strategic reviews.

## Trigger

Used by agents with `competitor-benchmark` in their skills list, or when lead requests competitive analysis.

## Procedure

### STEP 1: LOAD PRODUCT CONTEXT

```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai && cat docs/product-context.md
```

Understand our product's mission, personas, JTBD, and current capabilities before evaluating competitors.

### STEP 2: INVENTORY OUR CAPABILITIES

Scan the codebase to build a feature inventory:

```bash
# Module types (analysis capabilities)
grep -r "module_type" apps/chat/services/module_factory.py | head -20

# API routes (user-facing endpoints)
grep -r "@router" apps/ --include="*.py" | grep -v "__pycache__"

# Frontend components (UI surfaces)
ls frontend/components/

# MCP tools (analytical tools)
grep -r "def " packages/core/ --include="*.py" | head -30
```

Document what we actually ship, not what we plan.

### STEP 3: RESEARCH COMPETITORS

For each competitor in the landscape:

1. **WebSearch** for: `{competitor} features`, `{competitor} pricing`, `{competitor} reviews`
2. **WebFetch** their marketing pages, pricing pages, help docs
3. **WebSearch** for user reviews: `{competitor} review site:biggerpockets.com`, `{competitor} reddit`
4. Document:
   - Features available (verified, not claimed)
   - Pricing tiers
   - Data sources they use
   - User sentiment (what users love/hate)
   - Recent product updates

### STEP 4: BUILD FEATURE MATRIX

Create a comparison matrix with these dimensions:

| Dimension | Sub-features |
|-----------|-------------|
| **Data Input** | URL paste, address search, manual entry, batch import |
| **Property Data** | Auto-extraction, property details, photos, tax history |
| **Revenue Estimation** | ADR, occupancy, seasonality, comp analysis, dynamic pricing |
| **Expense Modeling** | Operating costs, management fees, taxes, insurance, reserves |
| **Financial Analysis** | Cash flow, ROI, cap rate, DSCR, CoC return, IRR |
| **Scenario Modeling** | What-if, sensitivity analysis, bull/bear/base, stress testing |
| **Regulatory** | STR compliance, zoning, HOA restrictions, permit info |
| **Market Intelligence** | Neighborhood stats, market trends, supply/demand, comps |
| **Comparison** | Multi-property comparison, portfolio view |
| **Conversational** | Chat/AI interface, natural language queries |
| **Reports** | PDF export, shareable links, client-ready reports |
| **Collaboration** | Team sharing, client portals, agent tools |
| **Mobile** | Native app, responsive web, offline access |
| **Integrations** | CRM, accounting, property management, MLS |
| **Pricing** | Free tier, price point, enterprise, per-query |

Rate each: `full` | `partial` | `none` | `planned` | `unknown`

### STEP 5: CLASSIFY DIFFERENTIATION

For each feature we offer:
- **Unique** — Only we do this (e.g., agentic chat for STR analysis, regulatory compliance integration)
- **Advantage** — We do it better (evidence required)
- **Parity** — Table stakes, everyone has it
- **Gap** — They have it, we don't

### STEP 6: IDENTIFY STRATEGIC OPPORTUNITIES

From the gaps and user sentiment, identify:
1. **Quick wins** — Gaps we can close with small effort that users vocally want
2. **Moat builders** — Features that deepen our unique advantages
3. **Category expansion** — Adjacent capabilities that expand our market
4. **Threats** — Competitor moves that could erode our position

### STEP 7: PRODUCE REPORT

Write the benchmark report to the output path specified by the caller, using the format defined in the competitor-analyst agent config.

## Output

The benchmark report goes to `docs/competitive/benchmark-{date}.md` in the target repo unless the caller specifies otherwise.

## Rules

- Verify features through actual observation (websites, docs, screenshots), not marketing claims
- Always note when information couldn't be verified ("claimed but unverified")
- Include pricing with dates — prices change
- User reviews are gold — prioritize real user sentiment over feature lists
- Our inventory must come from actual code, not planned features
- Update the competitor landscape table in the agent config when significant changes are found
