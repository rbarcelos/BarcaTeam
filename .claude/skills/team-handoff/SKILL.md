---
name: team-handoff
description: Standard handoff message format and matrix for passing work between PM, Architect, Senior Engineer, and QA agents, including escalation rules.
---

# Team Handoff Protocol

Standard protocol for passing work between agents in the PM → Architect → Engineer → QA pipeline.

## Handoff Message Format

When your phase is complete, send a handoff message to the next agent containing:

```
## Handoff: <Your Role> → <Next Role>
**Capability**: `<cap_slug>`
**Document**: <path to your output document>

### Key Decisions
1. <Most important decision or finding>
2. <Second most important>
3. <Third>

### Open Questions
- <Anything unresolved that the next agent needs to decide>

### Watch Out For
- <Risks, edge cases, or known issues the next agent should be aware of>

### Acceptance Criteria Summary
<List the AC-IDs most relevant to the next agent's work>
```

## Handoff Matrix

### PM → Architect
Include:
- Final list of acceptance criteria (AC-1..AC-n) with priority levels
- Key scope decisions (what's in, what's explicitly out)
- User personas and their primary needs
- Risks that may affect architecture choices
- Any prior art found in closed issues

### Architect → Senior Engineer
Include:
- Technology prescriptions (what to use, what NOT to use)
- Data contract schemas (exact field names, types, validation rules)
- Migration/rollout strategy (feature flags, dual endpoints, compat layers)
- Test strategy (what tests to write, where)
- Files/modules most likely to be affected
- ADRs for any non-obvious decisions

### Senior Engineer → QA
Include:
- Summary of what changed (files, endpoints, behaviors)
- How to test it (commands, endpoints to hit, expected outputs)
- Tests that were added and what they cover
- Known risks or areas with lower confidence
- PR links and issue links
- Any deviations from Architecture doc (with justification)

### QA → Lead (final report)
Include:
- PASS/FAIL for each acceptance criterion with evidence
- Regression test results
- Production readiness assessment (ready / blocked — with blockers)
- Follow-up issues filed (with links)
- Architect sign-off status
- Fallback inventory (what's behind compat layers)

## Escalation

If an agent finds an issue that belongs to a PREVIOUS phase:
- **Minor**: Note it in your output document, continue working
- **Major**: Message the responsible agent directly AND the lead
- **Critical**: Message the lead immediately, STOP current work until resolved
