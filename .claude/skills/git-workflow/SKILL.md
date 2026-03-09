---
name: git-workflow
description: Complete git conventions for capability implementation — cap branch lifecycle, agent worktree operations, commit messages, PRs, and cleanup.
---

# Git Workflow

---

## Branch Naming

| Branch | Pattern | Owner | Purpose |
|---|---|---|---|
| Cap branch | `cap/<cap_slug>` | Lead | Shared integration branch for the capability |
| Agent branch | `agent/<agent-name>/<cap_slug>` | Each agent | Isolated work branch, merged into cap |
| Hotfix | `fix/<short-description>` | Engineer | Quick fixes outside a capability |

Never commit directly to `main` or `cap/*`. Always work in an agent branch.

---

## Capability Branch Lifecycle

```
main
 └── cap/<cap_slug>                        ← Lead creates, one per repo
      ├── agent/architect/<cap_slug>        ← architect's worktree
      ├── agent/senior-engineer/<cap_slug>  ← engineer's worktree
      └── agent/ux-engineer/<cap_slug>      ← etc.
           ↓ each merges into cap/<cap_slug> as work completes
 └── main  ← cap/<cap_slug> merged via PR LAST, after QA signs off
```

---

## Operations

### CREATE — Cap Branch (Lead, before any agent starts)

```bash
CAP_SLUG="<cap_slug>"

for REPO_DIR in <repo1> <repo2> ...; do
  REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
  MAIN=$(git -C "$REPO_ROOT" remote show origin | awk '/HEAD branch/{print $NF}')

  git -C "$REPO_ROOT" fetch origin

  if git -C "$REPO_ROOT" ls-remote --heads origin "cap/$CAP_SLUG" | grep -q .; then
    echo "EXISTS: cap/$CAP_SLUG on $(basename $REPO_ROOT)"
    continue
  fi

  git -C "$REPO_ROOT" checkout -b "cap/$CAP_SLUG" "origin/$MAIN"
  git -C "$REPO_ROOT" push origin "cap/$CAP_SLUG"
  git -C "$REPO_ROOT" checkout "$MAIN"
  echo "CREATED: cap/$CAP_SLUG on $(basename $REPO_ROOT)"
done
```

### CREATE — Agent Worktrees (Lead, before spawning each teammate)

The lead creates a worktree for each agent it is about to spawn, then passes the worktree path in the spawn prompt. Agents do not create their own worktrees.

```bash
# Run once per agent per repo before spawning that agent
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

# Guard: skip if already exists
if git -C "$REPO_ROOT" worktree list | grep -q "$WORKTREE"; then
  echo "EXISTS: $WORKTREE"
else
  git -C "$REPO_ROOT" fetch origin
  mkdir -p "$(dirname "$WORKTREE")"
  git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WORKTREE" "origin/cap/$CAP_SLUG"
  echo "CREATED: $WORKTREE (branch: $BRANCH)"
fi

# Include in spawn prompt:
# "Your working directory is: $WORKTREE
#  Your branch is: $BRANCH
#  Base all changes in this worktree. Do not work outside it."
```

### RESUME — Existing Worktree

When resuming after a restart or picking up an existing worktree:

```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

if ! git -C "$REPO_ROOT" worktree list | grep -q "$WORKTREE"; then
  echo "NOT FOUND: run CREATE first."
  exit 1
fi

cd "$WORKTREE"
git fetch origin
git rebase "origin/cap/$CAP_SLUG"
echo "RESUMED: $WORKTREE (rebased onto origin/cap/$CAP_SLUG)"
```

### MERGE — Agent Branch → Cap Branch (after agent's work is complete)

```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

cd "$WORKTREE"
git fetch origin
git rebase "origin/cap/$CAP_SLUG"

cd "$REPO_ROOT"
git fetch origin
git checkout "cap/$CAP_SLUG"
git merge --no-ff "$BRANCH" -m "feat(${CAP_SLUG}): merge ${AGENT_NAME} work"
git push origin "cap/$CAP_SLUG"
echo "MERGED: $BRANCH → cap/$CAP_SLUG"
```

### MERGE — Cap Branch → Main (Lead, after QA PASS + architect sign-off + user approval)

**Step 1 — Generate PR Review and present to user (BEFORE opening any PR)**

Produce a `CAP_REVIEW.md` and present it to the user for approval:

```markdown
# Capability Review — `<cap_slug>`

## What Was Built
<2-3 sentence summary of the capability>

## Acceptance Criteria
| AC | Description | Status |
|---|---|---|
| AC-1 | <criterion> | ✅ PASS / ❌ FAIL |
| AC-2 | <criterion> | ✅ PASS |

## Changes by Repo
### `<repo-name>`
- `<file>` — <what changed>
- `<file>` — <what changed>

```bash
# Full diff summary per repo:
git -C <repo> diff main...cap/<cap_slug> --stat
```

## QA Sign-off
- Unit tests: PASS (`<command>`)
- Integration tests: PASS (`<command>`)
- E2E: PASS (`<command>`)
- Regressions: none

## Architect Sign-off
✅ Approved — <architect's verdict>

## Follow-up Issues Filed
- #<N> — <title>

## Known Risks / Notes
<anything the reviewer should be aware of>
```

Present to user and **STOP**. Do not open any PR until the user explicitly approves.

**Step 2 — After user approves, open PRs**

```bash
CAP_SLUG="<cap_slug>"

for REPO_DIR in <repo1> <repo2> ...; do
  REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
  MAIN=$(git -C "$REPO_ROOT" remote show origin | awk '/HEAD branch/{print $NF}')
  REPO_NAME=$(gh repo view -C "$REPO_ROOT" --json nameWithOwner -q .nameWithOwner)

  gh pr create \
    --repo "$REPO_NAME" \
    --head "cap/$CAP_SLUG" \
    --base "$MAIN" \
    --title "feat($CAP_SLUG): merge capability to main" \
    --body-file "CAP_REVIEW.md"

  echo "PR OPENED: cap/$CAP_SLUG → $MAIN on $(basename $REPO_ROOT)"
done
```

**If user requests changes:** loop back to the appropriate step, fix, re-run QA, regenerate CAP_REVIEW.md.

Never merge cap → main without explicit user approval. Always via PR, never direct push.

### CLEANUP — After PR Merged

```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

# Confirm branch is merged before removing
cd "$REPO_ROOT"
if ! git branch --merged | grep -q "$BRANCH"; then
  echo "WARNING: $BRANCH not yet merged. Confirm before cleanup."
  exit 1
fi

git worktree remove "$WORKTREE" --force
git branch -d "$BRANCH"
git push origin --delete "cap/$CAP_SLUG" 2>/dev/null || true
git worktree prune
echo "CLEANED: $WORKTREE and branches removed."
```

---

## Commit Messages

Use conventional commits:

```
<type>(<scope>): <short description>

<optional body — what and why, not how>

Refs: #<issue>, AC-<N>
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

**Rules:**
- Commit after each logical unit of work, not at end of day.
- Each commit must build and pass lints.
- Never leave the worktree dirty — commit WIP: `git commit -m "chore: WIP <description>"`
- One logical concern per commit. Do not batch unrelated changes.

---

## PR Template

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

---

## Conflict Protocol

When two agents need to edit the same file simultaneously:
1. **Stop** — do not edit the file.
2. **Message the lead** with: which file, which agents, what changes each needs.
3. Lead assigns ownership — one agent proceeds, the other waits.
4. Waiting agent rebases after first agent's commit is merged: `git rebase origin/cap/<cap_slug>`
5. If rebase conflict is unresolvable, message the **architect**.

Never force-push a shared branch (`cap/*` or `main`).
