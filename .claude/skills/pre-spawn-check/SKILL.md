---
name: pre-spawn-check
description: Pre-flight validation of harness health before spawning teams or starting long autonomous runs. Catches stale locks, malformed settings, missing hook scripts, bloated memory index, and misplaced worktrees — any of which can crash the lead pane.
---

# Pre-Spawn Health Check

Run this BEFORE `TeamCreate`, before starting `/loop`, before any autonomous run longer than ~20 tool calls, and on session start after reading the checkpoint. Stops on the first failure so the cause is obvious.

## Why it exists

On 2026-04-23 the lead pane crashed with a `kXH → ek → kXH` infinite-render recursion inside the Bun-compiled Claude Code CLI. Root cause: `.claude/scheduled_tasks.lock` was git-tracked, so a stale lock from a dead session got committed and poisoned future sessions. Pre-flight validation catches this class of issue before spawning work.

## When to Run

- MANDATORY before every `TeamCreate`
- MANDATORY before `/loop ...`
- MANDATORY before autonomous runs >20 tool calls (improvement loop, review loop, etc.)
- On session start, after reading the session checkpoint

## Portable JSON Validation

This box runs Git Bash on Windows. `jq` is NOT installed, but `node` is. All JSON checks below use node via a helper shim. Define it once at the top of the check session:

```bash
# pjv = portable JSON validator: echoes parsed JSON (or selects a field) or fails
# Usage: pjv FILE            -> validates (exits non-zero if invalid)
#        pjv FILE 'sel.code'  -> prints node's JSON.parse(fs.readFileSync(FILE)).sel.code
pjv() {
  local WIN_PATH
  WIN_PATH=$(cygpath -w "$1" 2>/dev/null || echo "$1")
  if [ -z "$2" ]; then
    node -e "try{JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));process.exit(0)}catch(e){console.error(e.message);process.exit(1)}" "$WIN_PATH"
  else
    node -e "const o=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=(()=>{try{return eval('o.'+process.argv[2])}catch(e){return undefined}})();if(v==null)process.exit(0);if(typeof v==='string')console.log(v);else console.log(JSON.stringify(v))" "$WIN_PATH" "$2"
  fi
}
```

## Procedure

Execute checks in order. Stop on the first `✗` and remediate before continuing.

### Check 1 — Stale `scheduled_tasks.lock`

```bash
LOCK=.claude/scheduled_tasks.lock
if [ -f "$LOCK" ]; then
  PID=$(pjv "$LOCK" 'pid')
  AT=$(pjv "$LOCK" 'acquiredAt')
  NOW_MS=$(($(date +%s) * 1000))
  AGE_MIN=$(( (NOW_MS - AT) / 60000 ))
  if [ -n "$PID" ]; then
    if tasklist //FI "PID eq $PID" 2>/dev/null | grep -q "$PID"; then
      if [ "$AGE_MIN" -gt 60 ]; then
        echo "✗ lock held by live pid $PID for ${AGE_MIN}min (>60) — investigate"
        exit 1
      fi
    else
      echo "  lock pid $PID is dead — removing stale lock"
      rm -f "$LOCK"
    fi
  fi
fi
echo "✓ scheduled_tasks.lock clean"
```

### Check 2 — Settings JSON parses

```bash
for f in ~/.claude/settings.json .claude/settings.json .claude/settings.local.json; do
  [ -f "$f" ] || continue
  pjv "$f" || { echo "✗ malformed JSON in $f"; exit 1; }
done
echo "✓ all settings files parse"
```

### Check 3 — Hook scripts exist

Extract every `command` path referenced by hooks via node, strip shell quoting, verify the file exists.

```bash
HOOK_EXTRACT="const o=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const hooks=o.hooks||{};for(const k of Object.keys(hooks))for(const g of (hooks[k]||[]))for(const h of (g.hooks||[]))if(h.command)console.log(h.command)"
for f in ~/.claude/settings.json .claude/settings.json .claude/settings.local.json; do
  [ -f "$f" ] || continue
  WIN_F=$(cygpath -w "$f" 2>/dev/null || echo "$f")
  node -e "$HOOK_EXTRACT" "$WIN_F" 2>/dev/null | while read -r cmd; do
    script=$(echo "$cmd" | awk '{print $1}' | tr -d '"'"'")
    [ -z "$script" ] && continue
    case "$script" in bash|sh|pwsh|powershell|cmd|node|python|python3) continue ;; esac
    [ -f "$script" ] || { echo "✗ hook script missing: $script (in $f)"; exit 1; }
  done
done
echo "✓ hook scripts resolve"
```

### Check 4 — MEMORY.md index ≤200 lines

```bash
MEM=~/.claude/projects/C--Users-rbarcelo-repo-barcaTeam/memory/MEMORY.md
[ -f "$MEM" ] || { echo "  MEMORY.md not found — skipping"; }
if [ -f "$MEM" ]; then
  LINES=$(wc -l < "$MEM")
  if [ "$LINES" -gt 200 ]; then
    echo "✗ MEMORY.md is ${LINES} lines (>200) — Claude Code truncates past 200, prune stale entries"
    exit 1
  fi
fi
echo "✓ MEMORY.md size ok"
```

### Check 5 — Worktrees outside repo

```bash
BAD=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / {print $2}' | grep -E 'barcaTeam[\\/](\\.claude|worktrees)' || true)
if [ -n "$BAD" ]; then
  echo "✗ worktree inside repo (crashes psmux):"
  echo "$BAD"
  exit 1
fi
echo "✓ worktrees are outside the repo"
```

## Output Format

```
HH:MM Pre-spawn health check:
  ✓ scheduled_tasks.lock clean
  ✓ all settings files parse
  ✓ hook scripts resolve
  ✓ MEMORY.md size ok
  ✓ worktrees are outside the repo
All green — safe to spawn.
```

On any `✗`, stop immediately and print the remediation row.

## Remediation Table

| Failure | Action |
|---|---|
| Stale dead-pid lock | Already removed by Check 1 — re-run |
| Live-pid lock >60min | Identify the process (`tasklist /FI "PID eq <pid>"`); if zombie, kill it and delete the lock |
| Malformed settings JSON | Open the file, fix syntax; `jq .` on the fixed file should succeed |
| Missing hook script | Remove the hook from settings, or restore the script from git history |
| MEMORY.md >200 lines | Prune outdated entries; move detail into per-topic files; keep the index to one-line pointers |
| Worktree inside repo | `git worktree remove <path>`; recreate under `$TEMP/barcateam-worktrees/` |
