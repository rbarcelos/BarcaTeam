# Improvement Loop

Autonomous closed-loop product improvement cycle. User-invoked. Gathers signals from multiple sources (thumbs-down feedback, UX critique, persona evaluation, open GH issues), triages, prioritizes, fixes, verifies, and learns.

## Trigger

User says: `/improvement-loop`, "run the improvement loop", "find and fix issues", or similar.

## Prerequisites

- Target repo must have `docs/product-context.md` (product mission, personas, UX principles)
- Finding schema at `.claude/schemas/finding.yaml` defines the canonical output format

## The Loop (10 steps)

---

### STEP 1: TRIAGE THUMBS-DOWN FEEDBACK

Query the feedback DB for unresolved entries. Diagnose any still pending, then file GH issues for anything not yet tracked.

```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai && python -c "
import sqlite3, json, sys
sys.stdout.reconfigure(encoding='utf-8')
conn = sqlite3.connect('chat_sessions.db')
conn.row_factory = sqlite3.Row
rows = conn.execute(\"SELECT feedback_id, user_message, diagnosis_status, diagnosis_json, component_type, property_address, gh_issue_number, created_at FROM feedback WHERE diagnosis_status NOT IN ('resolved') ORDER BY created_at DESC\").fetchall()
for r in rows:
    d = dict(r)
    print(json.dumps(d, indent=2, default=str))
    print('---')
"
```

For each entry:
1. If `diagnosis_status = 'pending'` → run diagnosis (analyze user_message + component_data to determine root cause and category)
2. If `diagnosis_status = 'diagnosed'` and `gh_issue_number IS NULL` → file a GH issue, link it
3. If `diagnosis_status = 'diagnosed'` and `gh_issue_number IS NOT NULL` → already tracked, carry forward
4. Mark all processed entries as `triaged`

---

### STEP 2: CONFIRM OPEN GH ISSUES

Fetch all open issues and confirm each is still valid:

```bash
gh issue list --state open --json number,title,body,labels,createdAt --limit 50
```

For each open issue:
1. **Read the issue** — understand the problem
2. **Check if already fixed** — grep the codebase, check recent commits. If fixed, close with comment.
3. **Check if still reproducible** — read the relevant code. If the root cause is gone, close.
4. **Confirm valid** — if the problem still exists in the code, keep it open and carry forward to scoring.

This prevents wasting effort fixing issues that are already resolved.

---

### STEP 3: GATHER NEW SIGNALS (optional, if deep evaluation requested)

Run additional signal generators in parallel:

**Source A — UX Critic agent:**
Spawn `ux-critic` to evaluate the product frontend and backend surfaces.
Input: product-context.md + frontend code + module data models.
Output: structured findings per finding schema.

**Source B — Persona agents:**
Spawn 2-3 relevant persona agents to evaluate from stakeholder perspective.
Output: structured findings per finding schema.

Skip this step if the user only asked to triage and fix existing feedback/issues.

---

### STEP 4: INGEST

Normalize all sources into the canonical finding schema:
- Feedback DB entries → extract `user_message`, `diagnosis_json`, `component_type`
- UX Critic output → already in schema format
- Persona output → already in schema format
- Confirmed GH issues → map title/body/labels to schema fields

Produce a unified findings list.

---

### STEP 5: DEDUP

Deduplicate by `dedupe_key` (component:category:signature):
1. **Exact match** — same dedupe_key → merge, keep highest severity
2. **Fuzzy match** — similar problem_statement on same component → merge
3. **GH issue match** — if an open GH issue already tracks this → link, don't duplicate

---

### STEP 6: SCORE

For each unique finding, compute RICE score:

```
RICE = (Reach × Impact × Confidence) / Effort
```

| Factor | Scale | Anchors |
|--------|-------|---------|
| **Reach** | 1-10 | 10=every user every session, 7=most users, 4=some users, 1=edge case |
| **Impact** | 1-10 | 10=wrong financial decision from bad data, 7=feature broken, 4=confusing but usable, 1=cosmetic |
| **Confidence** | 0.0-1.0 | From diagnosis or agent evaluation |
| **Effort** | 1-10 | 1=one-liner, 3=single file, 5=2-3 files, 7=cross-cutting, 10=architectural |

Sort by RICE descending. Present ranked backlog.

---

### STEP 7: SELECT

Pick the batch for this cycle:
- Start from highest RICE score
- Group related issues (same root cause → fix together)
- No artificial scope limits — fix what needs fixing

---

### STEP 8: FIX

For each selected issue:
1. **Investigate** — read the relevant code, understand the root cause
2. **Plan** — determine exact files and approach
3. **Implement** — make code changes, add tests
4. **Commit** to main with `fix(<scope>): <description> (#issue)`
5. **Close** the GH issue

Use worktree isolation when fixing multiple issues in parallel.
Spawn engineer agents for parallelism when there are 3+ independent issues.

---

### STEP 9: VERIFY

**QA check** each fix:
- Does the original user problem no longer occur?
- Are there regressions?
- Is the fix complete or just partial?
- Run tests: `cd /c/Users/rbarcelo/repo/investFlorida.ai && python -m pytest tests/ -x -q`

If verification fails → loop back to STEP 8 with feedback.

---

### STEP 10: LEARN

After fixes are merged and verified:

1. **Update feedback DB** — mark fixed entries as resolved:
   ```bash
   cd /c/Users/rbarcelo/repo/investFlorida.ai && python -c "
   import sqlite3
   conn = sqlite3.connect('chat_sessions.db')
   conn.execute(\"UPDATE feedback SET diagnosis_status='resolved' WHERE gh_issue_number IN (N1, N2, ...)\")
   conn.commit()
   "
   ```

2. **Update docs** — if new UX patterns or principles emerged, update `docs/product-context.md`

3. **Save to memory** — any recurring root causes or architectural patterns worth remembering

4. **WhatsApp summary** — send a concise summary of what was fixed via `whatsapp_send`

---

## Output

At the end of the loop, produce a summary:

```markdown
## Improvement Loop Summary

**Cycle date:** YYYY-MM-DD
**Feedback triaged:** N
**GH issues confirmed:** N open, N closed as already-fixed
**New findings:** N
**After dedup:** N
**Issues fixed:** N
**Issues deferred:** N (with reasons)

### Fixed
| # | Title | RICE | Files Changed |
|---|-------|------|---------------|

### Deferred
| # | Title | RICE | Reason |
|---|-------|------|--------|

### Lessons Learned
- <pattern or insight>
```

---

## Rules

- Persona and UX critic agents are **signal generators only** — they never decide priority
- The lead/PM scores and ranks — this is the authority for "what to fix next"
- Always **confirm GH issues are still valid** before working on them — don't fix already-fixed issues
- Always **triage thumbs-down feedback first** — this is the primary signal from real users
- Commit and merge to main directly — no PR workflow required
- Always verify fixes solve the **original user problem**, not just change code
- Always update feedback DB status after fixing linked entries
- Always send WhatsApp summary at end of cycle
