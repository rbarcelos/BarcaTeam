# Issue Templates

Standard GitHub issue formats for implementation tasks and bug reports.

## Implementation Task

```markdown
## Context
**Capability**: `<cap_slug>`
**Stream**: <stream name from EXECUTION_PLAN.md>
**Acceptance Criteria**: <AC-IDs this covers>

## Description
<What needs to be implemented and why>

## Technical Approach
<Key design decisions from ARCHITECTURE.md that apply>

## File Hints
| File | Change |
|---|---|
| `<path>` | New / Modified — <what changes> |

## Checklist
- [ ] Implementation complete
- [ ] Unit tests added
- [ ] Integration tests added (if applicable)
- [ ] Lint passes
- [ ] Build passes
- [ ] Docs updated (if applicable)

## Definition of Done
- [ ] All checklist items complete
- [ ] PR opened and linked to this issue
- [ ] Architect review requested
```

## Bug Report (QA)

```markdown
## Summary
<One-line description of the bug>

## Severity
**Critical / Major / Minor**

## Acceptance Criterion
<AC-ID that this violates, if applicable>

## Reproduction Steps
1. <step 1>
2. <step 2>
3. <step 3>

## Expected Behavior
<What should happen>

## Actual Behavior
<What happens instead>

## Evidence
<Paste test output, logs, screenshots, or error messages>

## Environment
- Repo: `<owner/repo>`
- Branch: `<branch>`
- Commit: `<sha>`

## Suggested Fix
<Optional — where the bug likely lives and how to fix it>
```

## Follow-up Issue (QA/Architect)

```markdown
## Context
**Capability**: `<cap_slug>`
**Source**: QA_REPORT.md / Architect Review
**Related Issue**: #<original issue>

## Description
<What was discovered and why it needs a separate follow-up>

## Priority
**High / Medium / Low**

## Suggested Action
<What should be done>
```
