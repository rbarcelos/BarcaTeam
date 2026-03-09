---
name: issue-triage
description: PM-driven triage meeting over the last 50 open GitHub issues on a repo. Brings in Senior Engineer for technical assessment and Architect for complex issues. Produces labelled, commented, and closed issues with a triage summary.
---

# Issue Triage Skill

The PM chairs the triage meeting. The lead spawns the team; PM drives it.

## Participants

| Role | Responsibility |
|---|---|
| **PM** (chair) | Reads every issue, makes final triage call, applies outcome |
| **Senior Engineer** | Assesses reproducibility, technical complexity, effort |
| **Architect** | Called in for issues with architectural impact |
| **QA** | Called in when reproduction steps are unclear |

## Triage Outcomes

| Outcome | Label | When |
|---|---|---|
| `confirmed` | `triage:confirmed` | Valid, reproducible, accepted for backlog |
| `requires-more-information` | `triage:needs-info` | Needs more detail before triaging |
| `no-repro` | `triage:no-repro` | Cannot reproduce with provided steps |
| `wont-fix` | `triage:wont-fix` | Valid but out of scope or won't be addressed |
| `closed` | — | Duplicate, already fixed, or invalid — close the issue |

## Workflow

### Step 1 — Fetch Issues
```bash
gh issue list --repo <owner/repo> --state open --limit 50 \
  --json number,title,body,labels,createdAt,author,comments \
  | python3 -c "import json,sys; issues=json.load(sys.stdin); [print(f'#{i[\"number\"]} {i[\"title\"]}') for i in issues]"
```

Read each issue fully:
```bash
gh issue view <number> --repo <owner/repo>
```

### Step 2 — Pre-sort
PM classifies each issue before involving teammates:

- **Clearly invalid** (spam, already fixed, duplicate) → PM closes directly, no meeting needed
- **Simple** (bug report, small request, clear scope) → PM + Senior Engineer
- **Complex** (architectural impact, multi-repo, breaking change, unclear scope) → PM + Senior Engineer + Architect
- **Unclear reproduction** → PM + QA

### Step 3 — Triage Each Issue
For each non-trivial issue, PM messages the relevant teammate:

**To Senior Engineer:**
> "Triage issue #<N>: `<title>`. Can you reproduce this? Is it technically valid? Estimate complexity: trivial / small / medium / large. Flag if it has architectural impact."

**To Architect (complex issues only):**
> "Triage issue #<N>: `<title>`. Does this have architectural impact? Would fixing it require design decisions? Your assessment before we confirm or close."

**To QA (unclear repro):**
> "Triage issue #<N>: `<title>`. Can you follow the reproduction steps? Do they lead to the described behavior?"

Wait for responses before applying outcome.

### Step 4 — Apply Outcome

For each issue, PM applies the outcome via `gh`:

**Add label:**
```bash
gh issue edit <number> --repo <owner/repo> --add-label "triage:confirmed"
```

**Post triage comment:**
```bash
gh issue comment <number> --repo <owner/repo> --body "$(cat <<'EOF'
**Triage outcome: confirmed**

Assessed by: PM, Senior Engineer
Decision: Valid and reproducible. Accepted for backlog.
Priority: medium
Next step: Will be scheduled in upcoming sprint.
EOF
)"
```

**Close if outcome is `closed`, `no-repro`, or `wont-fix`:**
```bash
gh issue close <number> --repo <owner/repo> --comment "Closing: <reason>"
```

### Step 5 — Triage Summary

PM posts a summary comment on a pinned or tracking issue, or writes `docs/triage/TRIAGE_<date>.md`:

```markdown
# Triage Session — <date>

**Repo**: <owner/repo>
**Issues reviewed**: <N>
**Team**: PM, Senior Engineer, [Architect], [QA]

## Results

| Outcome | Count |
|---|---|
| confirmed | X |
| requires-more-information | X |
| no-repro | X |
| wont-fix | X |
| closed | X |

## Confirmed Issues (priority order)
- #<N> — <title> — <priority>
- ...

## Patterns Observed
<Any recurring area, systemic problem, or theme across multiple issues>

## Follow-up Actions
- [ ] <any action items from triage>
```

## Labels Setup

Ensure these labels exist on the repo before triaging:
```bash
gh label create "triage:confirmed"    --repo <owner/repo> --color "0e8a16" --description "Confirmed valid issue"
gh label create "triage:needs-info"   --repo <owner/repo> --color "e4e669" --description "Needs more information"
gh label create "triage:no-repro"     --repo <owner/repo> --color "d93f0b" --description "Cannot reproduce"
gh label create "triage:wont-fix"     --repo <owner/repo> --color "cccccc" --description "Won't be fixed"
```
