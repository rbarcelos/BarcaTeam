---
name: automated-ux-audit
description: Run the full automated UX audit suite (accessibility, visual regression, interactive element health) against the investFlorida.ai frontend.
---

# Automated UX Audit

Runs three categories of automated checks against the Next.js frontend:

| Category | Tool | What it catches |
|---|---|---|
| Accessibility | axe-core (WCAG 2.1 AA) | Missing labels, contrast, keyboard traps, ARIA violations |
| Visual regression | Playwright `toHaveScreenshot` | Layout regressions across desktop / tablet / mobile |
| Interactive health | Playwright + `elementFromPoint` | Overlapping elements, z-index blocking, focus order |

---

## How to run

```bash
# From repo root
cd /c/Users/rbarcelo/repo/investFlorida.ai/frontend

# Full suite
npx playwright test e2e/ux-audit.spec.ts

# Headed (see the browser)
npx playwright test e2e/ux-audit.spec.ts --headed

# Single category
npx playwright test e2e/ux-audit.spec.ts --grep "Accessibility"
npx playwright test e2e/ux-audit.spec.ts --grep "Visual Regression"
npx playwright test e2e/ux-audit.spec.ts --grep "Interactive Element"
```

---

## Updating visual baselines

Run with `--update-snapshots` when layout changes are **intentional**:

```bash
npx playwright test e2e/ux-audit.spec.ts --update-snapshots
```

Snapshots are stored in `frontend/e2e/ux-audit.spec.ts-snapshots/`. Commit them alongside the code change so CI has an up-to-date baseline.

**When NOT to update baselines:**
- Unintentional layout shifts
- Regressions introduced by a new feature
- Mobile layout broken by desktop-only changes

---

## Interpreting results

### Accessibility failures
- Test logs the full violation list (id, impact, element selectors) to console.
- Only `critical` and `serious` violations fail the test. `moderate` and `minor` are logged but non-blocking.
- Fix by addressing the selector printed in the violation's `nodes` field.

### Visual regression failures
- Playwright diffs are saved to `frontend/test-results/`.
- Open the HTML report: `npx playwright show-report`
- Diff shows expected (baseline) vs actual side-by-side.

### Interactive element failures
- `overlapped` failures mean an element is covering a button/input at its center point.
- Check CSS `z-index`, `position: absolute`, and overlay components (modals, tooltips, banners).

---

## Integration with solution-review cycle

Add the UX audit as a gate in the solution-review loop:

1. **Before filing a UX fix PR** — run the audit to get a baseline failure list.
2. **After implementing the fix** — re-run and confirm all previously-failing checks now pass.
3. **Update visual baselines** — only if the visual change is intentional and approved.
4. **Include audit output** in the PR description under `## Test plan`.

Example PR checklist entry:
```markdown
- [ ] `npx playwright test e2e/ux-audit.spec.ts` passes with no new failures
- [ ] Visual baselines updated if layout intentionally changed
```

---

## Adding new checks

- **New page** → add an accessibility test block and three visual regression tests (one per viewport) in `ux-audit.spec.ts`.
- **New interactive component** → add a clickability/focusability test in the relevant `Interactive Element Health` describe block.
- Keep mock setup consistent with `MOCK_SESSION` at the top of the spec file.

---

## Key files

| File | Purpose |
|---|---|
| `frontend/e2e/ux-audit.spec.ts` | The audit test suite |
| `frontend/e2e/ux-audit.spec.ts-snapshots/` | Visual regression baselines |
| `frontend/playwright.config.ts` | Playwright config (baseURL, timeout, reporter) |
| `frontend/package.json` | `@playwright/test` and `@axe-core/playwright` dependencies |
