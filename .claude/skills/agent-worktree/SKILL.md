---
name: agent-worktree
description: Five callable operations (create, switch, refactor, merge, cleanup) for isolated agent work in git worktrees, including conflict protocol.
---

# Worktree Manager

Provides five callable operations for isolated agent work. Call them in order: **create → (switch) → refactor → merge → cleanup**.

---

## Naming Conventions (used by all operations)

```
Branch  : agent/<agent-name>/<cap-slug>
Path    : <repo-root>/../worktrees/<cap-slug>/<agent-name>/
```

---

## OPERATION: create

**When**: Before touching any files. Run once per agent per repo per capability.

**Inputs**
| Variable | Example |
|---|---|
| `REPO_DIR` | `/mnt/c/repos/my-app` |
| `CAP_SLUG` | `checkout-flow` |
| `AGENT_NAME` | `senior-engineer` |
| `BASE_BRANCH` | *(optional)* `cap/checkout-flow-my-app` or `main` |

**Steps**
```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

# Guard: skip if worktree already exists
if git -C "$REPO_ROOT" worktree list | grep -q "$WORKTREE"; then
  echo "EXISTS: worktree already at $WORKTREE (branch: $BRANCH)"
  exit 0
fi

git -C "$REPO_ROOT" fetch origin

# Resolve base: prefer cap branch → main
CAP_BRANCH="${BASE_BRANCH:-cap/${CAP_SLUG}-${REPO_NAME}}"
MAIN=$(git -C "$REPO_ROOT" remote show origin | awk '/HEAD branch/{print $NF}')
BASE=$(git -C "$REPO_ROOT" ls-remote --heads origin "$CAP_BRANCH" \
        | grep -q . && echo "origin/$CAP_BRANCH" || echo "origin/$MAIN")

mkdir -p "$(dirname "$WORKTREE")"
git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WORKTREE" "$BASE"

echo "CREATED: $WORKTREE  (branch: $BRANCH, base: $BASE)"
```

**Output**: Prints `CREATED: <path>  (branch: <branch>, base: <base>)`. All subsequent work happens inside `$WORKTREE`.

---

## OPERATION: switch

**When**: Resuming work on an existing worktree (e.g. agent restarted, different session).

**Inputs**: `REPO_DIR`, `CAP_SLUG`, `AGENT_NAME`

**Steps**
```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

# Verify the worktree exists and is registered
if ! git -C "$REPO_ROOT" worktree list | grep -q "$WORKTREE"; then
  echo "NOT FOUND: run create first."
  exit 1
fi

# Pull in upstream changes without disrupting uncommitted work
cd "$WORKTREE"
git fetch origin

CAP_BRANCH="cap/${CAP_SLUG}-$(basename $REPO_ROOT)"
UPSTREAM=$(git ls-remote --heads origin "$CAP_BRANCH" \
            | grep -q . && echo "origin/$CAP_BRANCH" \
            || echo "origin/$(git remote show origin | awk '/HEAD branch/{print $NF}')")

git rebase "$UPSTREAM"

echo "SWITCHED: $WORKTREE  (branch: $BRANCH, rebased onto: $UPSTREAM)"
```

**Output**: Prints `SWITCHED: <path>  (branch: <branch>, rebased onto: <upstream>)`. Work in `$WORKTREE`.

---

## OPERATION: refactor

**When**: Inside your worktree, ready to make a focused, isolated set of changes.

**Inputs**: `WORKTREE` (path), `DESCRIPTION` (short string for commit message)

**Steps**
```bash
cd "$WORKTREE"

# Verify clean baseline (no uncommitted carry-over from prior tasks)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "DIRTY: commit or stash existing changes before starting a new refactor."
  exit 1
fi

# ── MAKE YOUR CHANGES HERE ──
# Edit files, run tests/lints after each logical unit.
# Example commands (replace with actual work):
#   <edit files>
#   <run tests>
#   <run linter>

# After each logical unit, commit:
git add -p                        # stage only related hunks
git commit -m "refactor(<scope>): $DESCRIPTION"

# Keep current with upstream between units:
git fetch origin
CAP_BRANCH="cap/..."              # fill in cap branch name
git rebase "origin/$CAP_BRANCH"

echo "REFACTOR COMMITTED: $(git log -1 --oneline)"
```

**Rules**
- Never leave the worktree dirty overnight — commit WIP: `git commit -m "chore: WIP $DESCRIPTION"`
- One logical concern per commit. Do not batch unrelated changes.
- Tests and lints must pass before committing (not just at the end).

---

## OPERATION: merge

**When**: Task is complete, all commits are clean and tested.

**Inputs**: `REPO_DIR`, `CAP_SLUG`, `AGENT_NAME`

**Steps**
```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
CAP_BRANCH="cap/${CAP_SLUG}-${REPO_NAME}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

# Final rebase to minimise conflicts
cd "$WORKTREE"
git fetch origin
git rebase "origin/$CAP_BRANCH" 2>/dev/null \
  || git rebase "origin/$(git remote show origin | awk '/HEAD branch/{print $NF}')"

# Switch to the cap branch (use main workdir to avoid detached-HEAD in worktree)
cd "$REPO_ROOT"
git fetch origin
git checkout "$CAP_BRANCH" 2>/dev/null \
  || git checkout -b "$CAP_BRANCH" "origin/$(git remote show origin | awk '/HEAD branch/{print $NF}')"

git merge --no-ff "$BRANCH" -m "feat(${CAP_SLUG}): merge ${AGENT_NAME} work"
git push origin "$CAP_BRANCH"

echo "MERGED: $BRANCH → $CAP_BRANCH and pushed."
```

**No cap branch?** Open a PR from `$BRANCH` directly to main instead of merging locally.

---

## OPERATION: cleanup

**When**: Your branch has been merged (confirmed by lead or PR merged).

**Inputs**: `REPO_DIR`, `CAP_SLUG`, `AGENT_NAME`

**Steps**
```bash
REPO_ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel)
BRANCH="agent/${AGENT_NAME}/${CAP_SLUG}"
WORKTREE="${REPO_ROOT}/../worktrees/${CAP_SLUG}/${AGENT_NAME}"

# Safety: confirm branch is fully merged before removing
cd "$REPO_ROOT"
MERGED=$(git branch --merged | grep "$BRANCH" || true)
if [ -z "$MERGED" ]; then
  echo "WARNING: $BRANCH does not appear merged into current HEAD. Confirm before cleanup."
  exit 1
fi

git worktree remove "$WORKTREE" --force
git branch -d "$BRANCH"
git worktree prune

echo "CLEANED: worktree and branch $BRANCH removed."
```

---

## Conflict Protocol

When two agents need to edit the same file simultaneously:
1. **Stop** — do not edit the file.
2. **Message the lead** with: which file, which agents, what changes each needs.
3. Lead assigns ownership: one agent proceeds, the other waits.
4. Waiting agent rebases after the first agent's commit is merged: `git rebase origin/<cap-branch>`.
5. If rebase conflict is unresolvable, message the **architect**.

Never force-push a shared branch (`cap/*` or `main`).

---

## Quick Reference

| Operation | Command to invoke |
|---|---|
| Create isolated worktree | `create` with REPO_DIR, CAP_SLUG, AGENT_NAME |
| Resume existing worktree | `switch` with REPO_DIR, CAP_SLUG, AGENT_NAME |
| Make isolated changes | `refactor` inside WORKTREE with DESCRIPTION |
| Merge completed work | `merge` with REPO_DIR, CAP_SLUG, AGENT_NAME |
| Remove after merge | `cleanup` with REPO_DIR, CAP_SLUG, AGENT_NAME |
