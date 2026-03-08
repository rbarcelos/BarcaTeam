---
name: document-templates
description: Canonical templates for PM_BRIEF.md, ARCHITECTURE.md, EXECUTION_PLAN.md, and QA_REPORT.md capability documents.
---

# Document Templates

Canonical templates for capability documents. Use these exact structures for consistency.

---

## PM_BRIEF.md

```markdown
# PM Brief: <Capability Name>
**Slug**: `<cap_slug>`
**Date**: <YYYY-MM-DD>
**Author**: PM Agent

## Problem Statement
<What problem are we solving and why does it matter?>

## Goals
1. <Goal 1>
2. <Goal 2>

## Non-Goals
- <What we are explicitly NOT doing>

## Personas
| Persona | Description | Key Needs |
|---|---|---|
| <name> | <who they are> | <what they need> |

## User Stories
- As a <persona>, I want <action> so that <benefit>.

## Acceptance Criteria
| ID | Criterion | Priority |
|---|---|---|
| AC-1 | <description> | Must-have |
| AC-2 | <description> | Must-have |
| AC-3 | <description> | Nice-to-have |

Priority levels: Must-have, Should-have, Nice-to-have

## Edge Cases & Risks
| Risk | Impact | Mitigation |
|---|---|---|
| <risk> | <high/med/low> | <mitigation> |

## Success Metrics
- <How we measure success>

## Rollout Notes
- <Phasing, feature flags, migration considerations>
```

---

## ARCHITECTURE.md

```markdown
# Architecture: <Capability Name>
**Slug**: `<cap_slug>`
**Date**: <YYYY-MM-DD>
**Author**: Architect Agent

## Overview
<Brief summary of the design approach>

## Technology Decisions
| Decision | Choice | Rationale |
|---|---|---|
| <what> | <chosen tech> | <why> |

## Impacted Areas
| Repo | Layer | Files/Modules | Change Type |
|---|---|---|---|
| <repo> | <API/service/UI> | <paths> | New / Modified |

## Data Contracts

### <Endpoint/Tool Name>
**Request:**
```json
{ "field": "type — description" }
```
**Response:**
```json
{ "field": "type — description" }
```

## Error Model
| Code | Name | Retryable | Description |
|---|---|---|---|
| <code> | <name> | Yes/No | <description> |

## Caching Strategy
| Key Pattern | TTL | Invalidation |
|---|---|---|
| <pattern> | <duration> | <trigger> |

## Logging & Observability
| Event | Level | Context Fields |
|---|---|---|
| <event> | INFO/WARN/ERROR | <fields> |

## Test Strategy
| Type | Scope | Location |
|---|---|---|
| Unit | <what> | <where> |
| Integration | <what> | <where> |
| E2E | <what> | <where> |

## Migration / Rollout Plan
<Feature flags, dual endpoints, compat layers, phasing>

## Architecture Decisions (ADR)
### ADR-1: <Title>
- **Status**: Accepted
- **Context**: <Why this decision was needed>
- **Decision**: <What we decided>
- **Consequences**: <Tradeoffs>
```

---

## EXECUTION_PLAN.md

```markdown
# Execution Plan: <Capability Name>
**Slug**: `<cap_slug>`
**Date**: <YYYY-MM-DD>
**Author**: Senior Engineer Agent

## Streams
| Stream | Repo | Can Parallelize With | Estimated Complexity |
|---|---|---|---|
| <stream name> | <repo> | <other streams> | S/M/L |

## GitHub Issues
| Issue # | Title | Repo | Stream | AC Mapping |
|---|---|---|---|---|
| #<num> | <title> | <repo> | <stream> | AC-1, AC-2 |

## Implementation Order
1. <Step 1 — what and why first>
2. <Step 2>
3. ...

## Worktrees
| Repo | Branch | Path |
|---|---|---|
| <repo> | `cap/<slug>-<repo>` | <path> |

## Test Plan
| Test | Type | Command | Covers |
|---|---|---|---|
| <name> | unit/integration/e2e | <command> | AC-1 |

## Deviations from Architecture
| What | Why | Impact |
|---|---|---|
| <deviation> | <reason> | <impact> |
```

---

## QA_REPORT.md

```markdown
# QA Report: <Capability Name>
**Slug**: `<cap_slug>`
**Date**: <YYYY-MM-DD>
**Author**: QA Agent

## Acceptance Criteria Results
| AC-ID | Description | Status | Severity | Evidence |
|---|---|---|---|---|
| AC-1 | <description> | PASS/FAIL | —/Critical/Major/Minor | <evidence or link> |

## Test Results
| Repo | Command | Result | Output |
|---|---|---|---|
| <repo> | <command> | PASS/FAIL | <summary or link> |

## Production Readiness Checklist
- [ ] Feature flags documented
- [ ] Environment variables documented
- [ ] Monitoring/alerting in place
- [ ] Deployment config updated
- [ ] Backward compatibility verified
- [ ] Rollback plan documented

## Regression Check
| Area | Test | Result |
|---|---|---|
| <existing feature> | <what was tested> | PASS/FAIL |

## Fallback Inventory
| Feature | Compat Layer | Removal Criteria | Status |
|---|---|---|---|
| <feature> | <description> | <criteria> | Active/Ready to remove |

## Follow-up Issues
| Issue # | Title | Repo | Severity |
|---|---|---|---|
| #<num> | <title> | <repo> | Critical/Major/Minor |

## Architect Sign-off
- **Status**: Pending / APPROVED / REJECTED
- **Date**: <date>
- **Notes**: <findings summary>
```
