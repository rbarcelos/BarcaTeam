---
name: code-review-checklist
description: Structured review process covering architecture compliance, data contracts, error handling, security, testing, and code quality for engineer self-review and architect sign-off.
---

# Code Review Checklist

Structured review process for both self-review (engineer) and sign-off (architect).

## Pre-Review: Gather Context

Before reviewing, read:
1. `ARCHITECTURE.md` for this capability (technology decisions, contracts, patterns)
2. The PR description and linked issues
3. The diff itself

## Review Checklist

### 1. Architecture Compliance
- [ ] Uses prescribed technologies from Architecture doc (no competing alternatives introduced)
- [ ] Follows existing infrastructure patterns (caching, logging, error handling)
- [ ] Does not duplicate logic that already exists elsewhere in the codebase
- [ ] New modules/files follow the project's directory structure conventions

### 2. Data Contract Compliance
- [ ] Request/response schemas match Architecture doc definitions
- [ ] Required vs optional fields are correctly enforced
- [ ] Validation rules are implemented as specified
- [ ] Shared models are consistent across repo boundaries

### 3. Error Handling
- [ ] Uses typed error model (not raw exceptions/strings)
- [ ] Error codes are documented and consistent
- [ ] Retryability hints included where applicable
- [ ] No internal details leaked in client-facing error messages
- [ ] Edge cases handled (null, empty, overflow, malformed input)

### 4. Logging & Observability
- [ ] Structured logging with context fields (not plain string messages)
- [ ] Request/response logging on new endpoints with timing
- [ ] Appropriate log levels (DEBUG/INFO/WARN/ERROR)
- [ ] No sensitive data in logs (credentials, PII)

### 5. Caching
- [ ] Uses existing cache infrastructure (not a new caching layer)
- [ ] Cache keys follow documented patterns
- [ ] TTL and invalidation strategy match Architecture doc
- [ ] Cache misses handled gracefully

### 6. Security
- [ ] Input validation on all external inputs
- [ ] No hardcoded secrets or credentials
- [ ] Rate limiting considered for new endpoints
- [ ] Authentication/authorization enforced where required

### 7. Testing
- [ ] Tests added for new behavior
- [ ] Tests updated for changed behavior
- [ ] Edge cases covered (empty input, max values, concurrent access)
- [ ] Test names clearly describe what they verify
- [ ] Tests can run independently (no order dependency)

### 8. Code Quality
- [ ] No dead code or commented-out blocks
- [ ] Functions/methods have clear single responsibility
- [ ] Public API surface is minimal
- [ ] Breaking changes documented and justified

## Review Verdict Format

```
## Review: <APPROVED / CHANGES REQUESTED / BLOCKED>

### Summary
<1-2 sentence overall assessment>

### Issues Found
| # | Severity | File:Line | Description | Fix |
|---|---|---|---|---|
| 1 | Critical/Major/Minor | <location> | <what's wrong> | <how to fix> |

### Positive Notes
- <things done well>
```

**Severity levels**:
- **Critical**: Blocks merge. Security vulnerability, data loss risk, breaks existing functionality.
- **Major**: Should fix before merge. Logic error, missing validation, contract violation.
- **Minor**: Nice to fix. Style, naming, minor optimization. Can merge with follow-up issue.
