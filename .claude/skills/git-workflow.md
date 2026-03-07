# Git Workflow

Standard git conventions for capability implementation.

## Worktree Setup

For a capability `<cap_slug>` with repos discovered during Context Discovery:

```bash
# For each repo:
cd <repo-main-workdir>
git fetch origin
git worktree add -b cap/<cap_slug>-<repo-short-name> <worktrees-dir>/<cap_slug>/<repo-short-name> origin/<main-branch>
```

Work in the worktree, NOT the main workdir. This keeps main clean and avoids conflicts when multiple capabilities are in flight.

## Branching Convention

- Feature branches: `cap/<cap_slug>-<repo-short-name>`
- Hotfix branches: `fix/<short-description>`
- Never commit directly to main.

## Commit Messages

Use conventional commits:

```
<type>(<scope>): <short description>

<optional body — what and why, not how>

<optional footer — issue refs>
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

**Examples**:
```
feat(api): add MCP-friendly tool routing layer

Implements the tool handler registry and canonical request/response
schemas as defined in ARCHITECTURE.md.

Refs: #42, AC-1, AC-3
```

```
test(api): add contract tests for valuation tool

Covers request validation, error responses, and caching behavior.

Refs: #42, AC-5
```

## Commit Discipline

- Commit after each logical unit of work (not at end of day).
- Each commit should build and pass lints.
- Never stash in worktrees — commit WIP if needed: `git commit -m "chore: WIP <description>"`

## PR Template

When opening a PR, include:

```markdown
## Summary
<What this PR does and why>

## Capability
`<cap_slug>` — <brief description>

## Changes
- <change 1>
- <change 2>

## Linked Issues
- Closes #<issue>
- Refs: AC-1, AC-2

## Test Evidence
- [ ] Unit tests pass: `<command>`
- [ ] Integration tests pass: `<command>`
- [ ] Lint passes: `<command>`

## Checklist
- [ ] Follows Architecture doc
- [ ] Tests added/updated
- [ ] Docs updated (if needed)
- [ ] No hardcoded secrets or credentials
```

## Cleanup

When a capability is merged:
```bash
git worktree remove <worktree-path>
git branch -d cap/<cap_slug>-<repo-short-name>
git worktree prune
```
