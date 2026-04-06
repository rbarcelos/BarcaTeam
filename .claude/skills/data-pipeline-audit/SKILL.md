# Data Pipeline Audit

Structured procedure for tracing data accuracy from source to screen. Used by the `data-quality-auditor` agent and during improvement loops.

## Trigger

Used by agents with `data-pipeline-audit` in their skills list, or when data quality concerns are raised.

## Procedure

### STEP 1: MAP THE PIPELINE

Read and document the data flow:

```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai

# 1. Extraction layer (data sources)
ls packages/providers/
grep -r "class.*Provider" packages/providers/ --include="*.py"

# 2. Hydration layer (data assembly)
cat apps/chat/services/hydration.py | head -50
grep -r "hydration_step" apps/chat/ --include="*.py"

# 3. Context bridge (data transformation)
cat apps/chat/services/context_bridge.py | head -50
cat apps/chat/services/context_adapter.py | head -50

# 4. Module factory (computation)
grep -r "def _compute" apps/chat/services/module_factory.py

# 5. Display layer (frontend)
ls frontend/components/cards/
ls frontend/components/
```

### STEP 2: SELECT METRICS TO TRACE

Pick at least 3 key financial metrics to trace end-to-end:

| Metric | Why Critical |
|--------|-------------|
| **Cap Rate** | Core investment metric, shown on multiple surfaces |
| **Monthly Cash Flow** | Most user-facing metric, drives GO/CAUTION/NO-GO |
| **DSCR** | Lending viability, used in scoring composite |
| **NOI** | Foundation for cap rate and DSCR — errors here cascade |
| **Occupancy Rate** | Revenue driver, shown in chat and report |
| **Overall Score** | Composite shown on DecisionSurface — must match computation |

### STEP 3: TRACE EACH METRIC

For each selected metric, trace through all 4 stages:

#### 3a. Source (where does the raw value come from?)
```bash
# Find where the metric enters the system
grep -r "cap_rate\|caprate\|cap rate" packages/providers/ --include="*.py"
grep -r "cap_rate" apps/chat/services/hydration.py
```

Document: What API/calculation produces the initial value? What unit/scale?

#### 3b. Transform (how is it processed?)
```bash
# Find transformations
grep -rn "cap_rate" apps/chat/services/context_bridge.py
grep -rn "cap_rate" apps/chat/services/context_adapter.py
grep -rn "cap_rate" apps/chat/services/module_factory.py
grep -rn "cap_rate" apps/chat/services/workspace_compute.py
```

Document: Every place the value is read, transformed, or computed. Note unit changes.

#### 3c. Compute (what formula produces the final value?)
Read the computation code. For cap rate:
- Formula: `cap_rate = noi / purchase_price`
- Verify inputs, units, edge cases (division by zero)

#### 3d. Display (where and how is it shown?)
```bash
# Frontend display
grep -rn "cap_rate\|capRate\|cap-rate" frontend/ --include="*.tsx" --include="*.ts"
# Report templates
grep -rn "cap_rate" packages/reports/templates/ --include="*.html"
# Chat prompts
grep -rn "cap_rate\|cap rate" apps/chat/prompts/
```

Document: Every surface that shows this value. Check formatting, scale, units.

### STEP 4: CROSS-SURFACE CONSISTENCY

For each metric, verify the displayed value is identical (within rounding) across:
- [ ] DecisionSurface.tsx (score badge, metric tiles)
- [ ] OverviewCard.tsx
- [ ] EarningsCard.tsx (if applicable)
- [ ] Chat agent responses
- [ ] HTML/PDF report

Flag any discrepancy with exact file locations and values.

### STEP 5: EDGE CASE SWEEP

For each metric, check behavior when:
- Input is 0 (division by zero → NaN or Infinity?)
- Input is null/undefined/missing
- Input is negative
- Input is extremely large
- All fallbacks triggered (no API data available)

```bash
# Check for division-by-zero guards
grep -n "/ 0\|divide.*zero\|ZeroDivision\|float.*inf" apps/chat/services/workspace_compute.py
grep -n "if.*> 0\|if.*!= 0" apps/chat/services/workspace_compute.py
```

### STEP 6: DEFAULT ASSUMPTION AUDIT

```bash
# Find all defaults
cat packages/core/defaults.py
grep -rn "default\|DEFAULT\|fallback\|FALLBACK" apps/chat/services/ --include="*.py" | head -30
```

For each default:
- Is it documented?
- Is it labeled as a default in the UI?
- Is the value reasonable for current market conditions?
- Can the user override it?

### STEP 7: PRODUCE FINDINGS

Write findings using the data-quality-auditor's output format (see agent config).

## Output

Findings go to the caller (usually the lead or improvement loop). Each finding includes stage, metric, evidence, and fix approach.

## Rules

- Always verify with code, never assume correctness
- A number shown to 2 decimal places must be computed to at least 4
- If a metric is shown on N surfaces, check all N — not just the "main" one
- Scale confusion (0-1 vs 0-100 vs 0-10) is the #1 bug category — always check
- Unit confusion (monthly vs annual) is the #2 category — always check
- Edge cases with 0/null values must produce sensible behavior, never NaN/Infinity shown to user
