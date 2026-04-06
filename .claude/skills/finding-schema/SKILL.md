# Finding Schema

Canonical schema for all agent-generated findings. Every signal-generator agent (UX critic, personas, auditors, reviewers) outputs findings in this format. The improvement loop, solution review, and triage processes consume this format.

## Schema

```yaml
- id: "{source}-{sequential}"          # e.g., "ux-001", "dq-003", "sec-012"
  title: "<one-line summary>"           # concise, scannable
  problem_statement: "<what's wrong from user perspective>"
  evidence:
    - "<concrete observation with file:line reference>"
  affected_component: "<component or module name>"
  affected_flow: "<user flow or pipeline stage>"
  category: "<trust|accuracy|usability|security|performance|accessibility|copy|competitive>"
  severity: "critical|high|medium|low"
  confidence: <0.0-1.0>                # how certain is the agent
  user_impact: "<who is affected and how>"
  suggested_fix: "<concrete fix hypothesis>"
  acceptance_criteria:
    - "<how to verify the fix>"
  affected_files:
    - "<file path>"
  source_agent: "<agent type that produced this>"
  impacted_persona: "<persona most affected>"
  dedupe_key: "<component:category:signature>"  # for deduplication
  gh_issue: <number|null>               # linked GH issue if exists
  rice_score: <number|null>             # filled by triage, not by source agent
```

## Field Guidelines

### severity
| Level | Definition | Action |
|-------|-----------|--------|
| **critical** | Blocks core functionality, produces wrong financial data, or exposes security vulnerability | Fix immediately, file P0 GH issue |
| **high** | Significant barrier to task completion, inconsistency that erodes trust, missing critical information | Fix this cycle, file P1 GH issue |
| **medium** | Degraded experience but functional, could-be-better patterns, minor inconsistencies | Fix when prioritized by RICE, file P2 GH issue |
| **low** | Polish, best-practice violations, cosmetic issues | Defer, file P3 GH issue if worth tracking |

### confidence
- **1.0** — Verified in code with evidence
- **0.8** — High confidence from code reading, not runtime-tested
- **0.6** — Reasonable inference from patterns observed
- **0.4** — Educated guess, needs investigation
- **0.2** — Speculation based on limited evidence

### dedupe_key
Format: `{component}:{category}:{3-word-signature}`
Example: `DecisionSurface:accuracy:score-scale-mismatch`

Used by the improvement loop's DEDUP step to merge identical findings from different agents.

### rice_score
**Not filled by source agents.** Computed during triage by the lead/PM:
```
RICE = (Reach × Impact × Confidence) / Effort
```
Source agents provide severity and confidence; the triager adds Reach, Impact, and Effort.

## Agent-Specific Extensions

Agents may add extra fields relevant to their domain:

| Agent | Extra Fields |
|-------|-------------|
| `data-quality-auditor` | `stage`, `metric_affected` |
| `accessibility-reviewer` | `wcag_criterion`, `level` |
| `security-reviewer` | `owasp`, `cvss_estimate`, `attack_vector` |
| `copy-editor` | `surface`, `current_text`, `suggested_text`, `rationale` |
| `competitor-analyst` | `competitor`, `feature`, `differentiation` |

## Consumers

| Consumer | How They Use Findings |
|----------|----------------------|
| **Improvement Loop** (step 4-6) | Ingests, deduplicates, RICE-scores, selects batch |
| **Solution Review** (step 4) | PM consolidates into unified spec |
| **Issue Triage** | PM converts to GH issues with labels |
| **Lead** | Prioritizes and assigns to engineers |

## Rules

- Every finding MUST have evidence — no findings without code references
- Source agents set severity and confidence; triagers set RICE
- dedupe_key must be specific enough to distinguish similar-but-different findings
- If an existing GH issue tracks the same problem, link it in `gh_issue` instead of filing a duplicate
- Findings are immutable once produced — triage annotates but doesn't modify the original
