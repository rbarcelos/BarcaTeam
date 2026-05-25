---
name: e2e-live-qa
description: Run Playwright critical-flow E2E tests against the live investFlorida.ai dev server (port 3000). Manual on-demand. 17 scenarios cover landing rendering, demo chips, anonymous quota gate, allowlist + non-allowlist sign-in, session tabs, WhatIf dirty guard, sign-out flow, the "money path" cluster (address submit, Redfin URL paste, verdict pill), and the "trust signal" cluster (source dots coverage, cash-flow formula integrity, listing cross-check), plus the "backend/auth" cluster (anon→authed migration, quota OAuth handoff, cookie middleware regression guard). Per epics rbarcelos/investFlorida.ai#2883, #2894.
---

# E2E Live QA

On-demand Playwright critical-flow runner. The skill drives the test suite at `investFlorida.ai/frontend/e2e/critical-flows/` against a running dev server. Use this BEFORE merging risky PRs and AFTER user-reported regressions to confirm the live app still works.

## Trigger

The skill activates when:
- User types `/e2e-live-qa` — runs **all 17 scenarios**
- User types `/e2e-live-qa <scenario>` — runs **one scenario** by name (without `.spec.ts`)
- User says "run e2e tests", "run the critical-flow suite", "test the landing page", "verify sign-in still works", or similar

## Arguments

- `SCENARIO` (optional): One of the scenario slugs listed below. Omit or pass `all` to run the full suite.

## Available scenarios

| # | Slug | What it verifies |
|---|------|-------------------|
| 1 | `landing-renders` | Anonymous lands on `/`, all 10 sections render, no console errors |
| 2 | `demo-chip-loads` | Brickell chip click → `/session/<id>` loads, quota cookie unchanged |
| 3 | `anonymous-quota-gate` | 1st real submit succeeds; 2nd → 403 + sign-in CTA shown |
| 4 | `allowlist-signin` | `rbarcelos@gmail.com` dev-login → reaches `/app` |
| 5 | `non-allowlist-signin` | `someone@gmail.com` dev-login → redirected to `/waitlist` |
| 6 | `session-tabs-render` | Signed-in user opens session, all 5 tabs render with data |
| 7 | `whatif-dirty-guard` | Edit WhatIf field → switch scenario → DiscardEditsDialog fires |
| 8 | `signout-flow` | Sign out from `/app` → returns to `/` cleanly (no `?next=`) |
| 9 | `address-submit-real` | Anonymous types a real (non-demo) address → `/session/<id>` with rendered verdict or dollar data |
| 10 | `listing-url-paste` | Anonymous pastes a Redfin URL → `/session/<id>` with Redfin link preserved |
| 11 | `verdict-pill-renders` | Brickell demo chip → `/session/<id>` → verdict badge shows "Go" or "Caution" |
| 12 | `source-dots-coverage` | Brickell demo session renders ≥5 SourceBadgeDots with non-empty, recognised tooltip labels (catches silent fallback chain regressions) |
| 13 | `cash-flow-formula-integrity` | Brickell demo session Cash flow tab: cap rate plausible [1–20%], implied monthly debt > 0 (no sign error), gross annual revenue in plausible range |
| 14 | `listing-cross-check` | Brickell demo session Property tab values match backend session context (price ±$1, beds exact, baths ±0.5, sqft ±5, HOA ±$25) |
| 15 | `anon-to-authed-migration` | Anonymous session created before sign-in migrates to authed user's list after dev-login (guards #2787 `migrate_anonymous_data`) |
| 16 | `quota-cta-starts-oauth` | After quota hit, form shows sign-in CTA; clicking it navigates to `/auth/google/login` (guards conversion path) |
| 17 | `cookie-middleware-regression` | Fresh anon POST → 201 + HttpOnly cookie; same jar second POST → 403 + sign_in_required; fresh jar still succeeds (guards #2896 CookieIdentityMiddleware) |

If a scenario in the list isn't yet implemented in `frontend/e2e/critical-flows/`, treat it as a skipped row in the report and continue with the rest.

---

## Execution flow

### Step 1 — Prerequisites (mandatory, fail fast)

Run these checks in order. **Stop and report to the user on the first failure** — do NOT attempt to silently start anything.

1. **Dev server reachable on port 3000.**
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "DOWN"
   ```
   Must return `200`. If not, message the user: "Dev server not responding on :3000. Start it with `cd /c/Users/rbarcelo/repo/investFlorida.ai && npm run dev` and re-invoke."

2. **Backend reachable on port 8000.**
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || echo "DOWN"
   ```
   Must return `200`. If not, message the user: "Backend FastAPI not responding on :8000. Start it with `cd /c/Users/rbarcelo/repo/investFlorida.ai/backend && uvicorn server.app:app --reload` and re-invoke."

3. **`ENABLE_DEV_LOGIN=true` in the backend's environment.**
   The dev-login endpoint lives on the FastAPI backend (`apps/chat/api/routes/auth.py`) — NOT the Next.js frontend. It is gated by `_dev_login_enabled()` and returns 404 when `ENABLE_DEV_LOGIN` is unset or in production. The skill cannot enable it for a server that's already running — it must be set when the backend boots. To check, hit the backend dev-login route with an invalid payload:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/auth/dev-login -H "Content-Type: application/json" -d '{}'
   ```
   - `400` or `422` → endpoint live (dev-login enabled). Proceed.
   - `404` → dev-login disabled. Tell the user: "`ENABLE_DEV_LOGIN=true` is not set on the **backend**. Stop uvicorn, then in the same PowerShell window run `$env:ENABLE_DEV_LOGIN=\"true\"; uvicorn server.app:app --reload` (from the backend root), and re-invoke."

4. **Local `master` is up-to-date with `origin/master` in investFlorida.ai.**
   ```bash
   cd /c/Users/rbarcelo/repo/investFlorida.ai && git fetch && git status -sb | head -1
   ```
   If `behind` appears, run `git pull --ff-only` before testing. Stale code is the #1 source of false-alarm bug reports.

### Step 2 — Run the test(s)

Always operate from the investFlorida.ai frontend directory. Use absolute paths.

**The critical-flows suite has its own Playwright config** (`playwright.critical-flows.config.ts`) — it disables the root config's `webServer` block (which boots a `next start` on :3002), pins `workers: 1`, sets `retries: 1`, and points `baseURL` at the live `:3000` dev server. **You MUST pass `--config=playwright.critical-flows.config.ts`** — without it, the root config takes over and every test fails with `ECONNREFUSED 127.0.0.1:3002`.

**Run a single scenario:**
```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai/frontend && npx playwright test --config=playwright.critical-flows.config.ts <scenario>
```
(The slug filters the testname; the config already restricts `testDir` to `e2e/critical-flows`.)

**Run all scenarios:**
```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai/frontend && npx playwright test --config=playwright.critical-flows.config.ts
```

Capture full stdout. Playwright writes:
- HTML report → `frontend/playwright-report/index.html`
- Test artifacts (traces, screenshots, video) → `frontend/test-results/<scenario-name>/`

Failures dump a `trace.zip` and screenshots automatically; the skill does not need to configure additional flags.

### Step 3 — Report

Produce a structured report in this exact format. Always include the summary table; only include the failure detail block when failures occur.

```markdown
## E2E Live QA Report — <YYYY-MM-DD HH:MM>

**Scenarios run:** <N>   |   **Pass:** <P>   |   **Fail:** <F>   |   **Skipped:** <S>

| # | Scenario | Result | Duration | Artifact |
|---|----------|--------|----------|----------|
| 1 | landing-renders | PASS | 2.3s | — |
| 2 | demo-chip-loads | FAIL | 8.1s | test-results/demo-chip-loads/trace.zip |
| ... |

### Failure details

#### 2. demo-chip-loads — FAIL
**Error (first 20 lines of Playwright output):**
```
<paste exactly the first 20 lines of the error block from stdout>
```
**Screenshot:** `frontend/test-results/demo-chip-loads/test-failed-1.png`
**Trace viewer:** `npx playwright show-trace frontend/test-results/demo-chip-loads/trace.zip`

### Suggested follow-ups
- File GH issue for `demo-chip-loads` regression? (yes/no — recommend yes if PASS → FAIL since last green run)
- Rerun a specific test in headed mode for diagnosis: `npx playwright test e2e/critical-flows/demo-chip-loads.spec.ts --headed --debug`
- Open HTML report: `npx playwright show-report frontend/playwright-report/`
```

### Step 4 — Cleanup

After the run completes (pass or fail):

1. **Drop any dev-login session cookies** the test created from the user's browser profile. Playwright tests use isolated browser contexts by default, but if a spec stored auth state to `frontend/e2e/.auth/`, prune anything older than 1 hour:
   ```bash
   cd /c/Users/rbarcelo/repo/investFlorida.ai/frontend && find e2e/.auth -name "*.json" -mmin +60 -delete 2>/dev/null || true
   ```

2. **Prune stale Playwright traces** to keep disk usage bounded. Keep only the most recent run's `test-results/`:
   ```bash
   cd /c/Users/rbarcelo/repo/investFlorida.ai/frontend && find test-results -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
   ```

3. **Do NOT clear** `playwright-report/` — the user may want to open it to inspect a failure.

---

## Failure-mode triage

| Symptom | Likely cause | Next step |
|---------|--------------|-----------|
| All specs fail with `connect ECONNREFUSED 127.0.0.1:3000` | Dev server died mid-run | Restart dev server, re-invoke |
| `allowlist-signin` fails with 404 on `/auth/dev-login` | `ENABLE_DEV_LOGIN` not set or got unset | Re-check Step 1.3 |
| One spec times out at `page.goto` | Backend on :8000 hung | Restart backend, re-invoke |
| All specs fail with TypeScript compile errors | Stale node_modules or breaking type change on master | `npm install` then retry |
| `non-allowlist-signin` redirects to `/app` instead of `/waitlist` | Allowlist regression — file a GH issue immediately | See "Filing follow-up issues" below |

## Filing follow-up issues

If a previously-passing scenario fails, file a GH issue against `rbarcelos/investFlorida.ai` using the Bug Report template from the `issue-templates` skill. Include:
- Scenario slug
- Error excerpt (first 20 lines)
- Screenshot path
- Trace zip path
- Last-known-good commit if available (`git log --oneline -5`)

Label with `type:bug` and severity based on the flow:
- `priority:P0` — landing, allowlist-signin, signout (anything blocking new-user entry)
- `priority:P1` — session tabs, WhatIf guard, quota gate
- `priority:P2` — demo-chip, non-allowlist

---

## Adding a new scenario

1. **File location:** `investFlorida.ai/frontend/e2e/critical-flows/<slug>.spec.ts`
2. **Naming:** kebab-case slug describing the flow (`new-tab-renders`, `compare-table-sort`). The slug must match what the user types after `/e2e-live-qa`.
3. **Use existing helpers:** sign-in flows should call the shared `devLogin(page, email)` helper from `frontend/e2e/helpers/auth.ts` (created in Part A of the epic). Do not paste OAuth bootstrapping into individual specs.
4. **Single behavior per spec.** One scenario asserts one user-visible outcome. Multi-step flows are fine, but the assertion at the end should be a single observable state ("user is on `/app`", "DiscardEditsDialog is visible", "no console error fired").
5. **Update the "Available scenarios" table** in this SKILL.md when adding a new slug — the table is the source of truth for `/e2e-live-qa <slug>` autocomplete.
6. **Capture trace on first run** before committing: `npx playwright test e2e/critical-flows/<slug>.spec.ts --trace on` so the reviewer can verify the flow.

---

## Out of scope

This skill does NOT:
- Boot the dev server (the user owns server lifecycle)
- Run in CI (see follow-up issue for GitHub Actions workflow)
- Do visual regression diffs (Phase 2 follow-up)
- Test against Firefox/Safari (Phase 2 follow-up — Chromium only for now)
- Run on a schedule (manual invocation only)

---

## Related

- Epic (money path): `rbarcelos/investFlorida.ai#2883`
- Epic (trust signal cluster): `rbarcelos/investFlorida.ai#2894`
- Allowlist gate: `rbarcelos/investFlorida.ai#2787`
- Orphan dev-server detection: `rbarcelos/investFlorida.ai#2835`
- Listing cross-check bugs: `rbarcelos/investFlorida.ai#2864`
- Skill author: senior-engineer agent — Co-author: Opus 4.7
