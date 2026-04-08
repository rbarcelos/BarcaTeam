# Mock-to-Production Visual Convergence

100% fidelity implementation of an HTML mock into production React/Tailwind components. Uses an iterative convergence loop — audit, fix, verify, repeat — until every section, property, and data field matches exactly.

## Trigger

User says: `/mock-to-production`, "implement this mock", "match this mock", or provides a mock HTML file path.

## Arguments

- `MOCK_PATH` (required): Path to the mock HTML file (e.g., `reviews/left-panel-mock.html`)
- `SPEC_PATH` (optional): Path to a spec/parity-report markdown file for additional context
- `TARGET_DIR` (optional): Directory containing production components (default: `frontend/components/`)

## Philosophy

Mocks are contracts, not suggestions. Every pixel delta is a bug. The mock HTML is the absolute source of truth — it wins unless code comments explicitly mark a functional constraint.

**Key principle:** Our mocks are living HTML with inspectable CSS. This is more precise than screenshot diffing. We extract exact CSS properties from the mock DOM and compare them 1:1 against production.

---

## THE CONVERGENCE LOOP

```
┌─────────────────────────────────────────────────┐
│                                                   │
│   PHASE 1: SECTION INVENTORY (once)               │
│   ↓                                               │
│   PHASE 2: AUDIT (each round)                     │
│   ↓                                               │
│   PHASE 3: FIX (highest-priority mismatches)      │
│   ↓                                               │
│   PHASE 4: VERIFY (re-audit, check stop cond.)    │
│   ↓                                               │
│   ┌── PASS? ──→ PHASE 5: DATA + RESPONSIVE GATE   │
│   │             ↓                                  │
│   │             DONE                               │
│   │                                                │
│   └── FAIL ──→ back to PHASE 2                     │
│                                                   │
└─────────────────────────────────────────────────┘
```

---

### PHASE 1: SECTION INVENTORY (run once)

**Agent: ux-qa-tester** (reviewer role — never implements)

Read the mock HTML and produce two artifacts:

#### 1A. Section Checklist (`reviews/section-checklist.md`)

Every visually distinct section in the mock, in order:

```markdown
# Canonical Sections — [Screen Name]

1. [ ] Hero / Property Identity Header
2. [ ] Listing Details (price, status, HOA, listing link)
3. [ ] Projections Row (KPI strip)
4. [ ] Scenario Pill Bar
5. [ ] Module Cards (Earnings, Financing, Regulations, Risk, Scenario)
6. [ ] Decision Surface
7. [ ] What-If Editor
8. [ ] Compare Table
9. [ ] Chat Panel (header, messages, composer, suggestions)

## Notes
- Projections Row must appear directly below Listing Details
- Module cards order: Earnings → Financing → Regulations → Risk → Scenario
- Chat suggestions must be grouped by category (Scenarios, Explore, Risk)
```

This checklist is the **primary stop condition** — all sections must be present and in order before any polish work begins.

#### 1B. Property Inventory (`reviews/mock-decomposition.md`)

For each section, extract **every CSS property** from the mock HTML:

```markdown
### Section: [Name] — .[css-class]
**Layout:** display, grid/flex, gap, padding, margin, width, height
**Typography:** font-family, font-size, font-weight, color, letter-spacing, line-height, text-transform
**Visual:** background, border, border-radius, box-shadow, opacity
**Interaction:** hover states, transitions, animations, cursor
**Data fields:** [list every dynamic value shown]
**Content:** [exact text labels, button labels, placeholder text]
```

---

### PHASE 2: AUDIT (each convergence round)

**Agent: ux-qa-tester** (reviewer role)

Compare mock properties against production components. Produce a **round report** with:

#### 2A. Section Status

```markdown
## Section Status — Round N

| # | Section | Status | Notes |
|---|---------|--------|-------|
| 1 | Hero | PRESENT | — |
| 2 | Listing Details | PRESENT | price/status/HOA on same line ✓ |
| 3 | Projections Row | PRESENT | deltas not showing on scenario click |
| 4 | Module Cards | PARTIAL | Earnings card structure wrong |
```

Status values: `PRESENT` | `PARTIAL` (exists but structure wrong) | `MISSING` | `EXTRA` (in production but not in mock)

#### 2B. Property Comparison

For **every section that is PRESENT or PARTIAL**, compare each CSS property:

```markdown
### [Section Name]
**Mock:** .[css-class]
**Production:** [ComponentName] in [file.tsx]

| Property | Mock Value | Production Value | Line | Status |
|----------|-----------|-----------------|------|--------|
| font-size | 11px | text-[12px] | 42 | MISMATCH |
| color | #536580 | text-[#536580] | 43 | MATCH |
| padding | 5px 14px | px-[14px] py-[5px] | 40 | MATCH |
```

Status: `MATCH` | `MISMATCH` | `MISSING` (in mock but not in production) | `EXTRA` (in production but not in mock)

#### 2C. Content Comparison

Compare text labels, button text, placeholder text:

```markdown
### Content Mismatches
| Element | Mock Text | Production Text | File:Line |
|---------|-----------|-----------------|-----------|
| Button | "Run What-If" | "Apply" | WhatIfTab.tsx:245 |
| Label | "Loan Structure" | "Financing Details" | FinancingCard.tsx:88 |
```

#### 2D. Round Verdict

```markdown
## Verdict — Round N

**Section coverage:** 9/10 present, 1 missing, 0 partial
**Property matches:** 342/380 (90%)
**Content matches:** 28/30 (93%)
**Missing sections:** [list]
**Structural mismatches:** [list]

**STOP CONDITION: FAIL**
Reason: 1 missing section, 38 property mismatches, 2 content mismatches

### Priority for next round (by severity):
**P0 — Missing sections:** [list]
**P1 — Structural mismatches:** [component has wrong layout/wrong children]
**P2 — Property mismatches:** [list top 10 by visual impact]
**P3 — Content mismatches:** [list]
**P4 — Polish:** [minor spacing, transitions, hover states]
```

---

### PHASE 3: FIX

**Agent: senior-engineer** (multiple in parallel for independent components)

Execute fixes based on the priority list from Phase 2D:

#### Priority Rules

1. **P0 first, always.** Missing sections must be implemented before any other work.
2. **P1 before P2.** Structural layout fixes before individual property tweaks.
3. **Parallel by component.** One agent per component — never two agents touching the same file.
4. **Atomic commits per component** with issue references.
5. **Include data pipeline changes** when a mock field requires new backend data.
6. **Include MCP tool changes** when a mock feature requires new agent capabilities.
7. **Run `npx tsc --noEmit`** after each component to catch type errors immediately.

#### What counts as a "fix"

- CSS property change (Tailwind class or inline style)
- Layout restructure (flex → grid, column reorder, wrapping behavior)
- Component restructure (new sub-components, removed sections, reordered children)
- Data field wiring (frontend reads new field, backend populates it)
- Content change (button label, placeholder text, section header)
- New component creation (section exists in mock but has no production counterpart)
- MCP tool addition/modification (mock shows data that requires a new tool)
- Backend integration (mock shows data from a new source — e.g., Walk Score API)

---

### PHASE 4: VERIFY (re-audit)

**Agent: ux-qa-tester** (same reviewer as Phase 2 — never the implementer)

Re-run the full Phase 2 audit. Compare the new round report against the previous round:

```markdown
## Verification — Round N → Round N+1

**Previous:** 342/380 matches (90%)
**Current:** 370/380 matches (97%)
**Improvement:** +28 matches, 0 regressions

**Regressions detected:** [list any property that was MATCH and is now MISMATCH]
```

#### Stop Conditions (ALL must be true)

1. **All canonical sections PRESENT** — zero MISSING, zero PARTIAL
2. **Section order matches mock** — no reordering
3. **Property match rate ≥ 98%** — remaining mismatches are documented edge cases
4. **Zero content mismatches** — all text labels, button labels, placeholders match
5. **Zero P0 or P1 issues** — no missing sections, no structural mismatches
6. **Zero regressions** — nothing got worse since last round

If **any stop condition fails** → back to Phase 2 with the new round report.

If **all stop conditions pass** → proceed to Phase 5 (final gate).

#### Regression Protocol

If a fix in round N+1 breaks something that was correct in round N:
1. **Revert the regression immediately** (git checkout the specific file)
2. **Analyze root cause** — why did fixing X break Y?
3. **Re-implement with awareness** of the dependency
4. **Never proceed** with a regression in place

---

### PHASE 5: FINAL GATE (run once, after convergence)

Three checks before declaring done:

#### 5A. Data Pipeline Trace

**Agent: architect**

For each data field in the mock, trace end-to-end:
- API/MCP tool → backend computation → session context → component prop → rendered DOM
- Verify the value is correct, not just present
- Flag any field that shows a placeholder/estimate when real data should be available

#### 5B. Responsive Checkpoint

**Agent: ux-qa-tester**

Verify the production components don't break at key breakpoints:
- Desktop: 1440px+ (primary target)
- Laptop: 1200px
- Tablet: 1024px (if mock has responsive variants)

Check for: overflow, clipped text, collapsed sections, broken card stacking, unusable spacing.

#### 5C. Interactive Behavior Audit

**Agent: ux-qa-tester**

Verify every interactive behavior from the mock:
- Hover states match
- Click handlers fire correctly
- Transitions/animations present
- Expand/collapse behavior works
- Keyboard navigation (Tab, Enter, Escape)

---

## PRIORITY HIERARCHY

When deciding what to fix first, follow this strict order:

| Priority | Category | Description | Example |
|----------|----------|-------------|---------|
| **P0** | Missing sections | Section in mock but absent in production | No Regulations card at all |
| **P1** | Structural mismatch | Section exists but has wrong layout or children | FinancingCard has 2x2 grid instead of flat rows |
| **P2** | Property mismatch (high-impact) | Wrong font-size, wrong color, wrong spacing on key elements | Price font 30px instead of 22px |
| **P3** | Content mismatch | Wrong text label, button label, placeholder | "Apply" instead of "Run What-If" |
| **P4** | Property mismatch (low-impact) | Wrong letter-spacing, wrong transition, minor gap difference | letter-spacing 0.04em vs 0.02em |
| **P5** | Polish | Hover states, animations, micro-interactions | Missing hover:bg-[#EEF4FF] on pills |

**Rule:** Never start P(N+1) while any P(N) issues remain.

---

## CRITICAL RULES

1. **The mock is the source of truth.** If the mock says `font-size: 10.5px`, production must be exactly `10.5px` — not `11px`, not `text-xs`.

2. **CSS class names are not visual properties.** `text-slate-400` is NOT the same as `#536580`. Always compare the **computed hex/px value**, not the Tailwind class name.

3. **No silent failures.** If a Tailwind class doesn't resolve (e.g., `text-panel-s400`), it renders as nothing — this is a bug.

4. **Inline styles when Tailwind can't match.** When the mock uses a specific value without a Tailwind equivalent, use `style={{}}`.

5. **Data flows must be traced end-to-end.** "The field exists in the type definition" ≠ "the backend populates it."

6. **Content differences are bugs.** "Market" ≠ "Market Health". "Apply" ≠ "Run What-If".

7. **The reviewer never implements.** The ux-qa-tester produces findings. The senior-engineer implements fixes. This separation prevents "good enough" drift.

8. **No premature "done."** The convergence loop runs until ALL stop conditions pass. "Close enough" is not 100%.

9. **Regressions are P0.** If fixing one thing breaks another, revert and re-approach.

10. **Parallel agents, not serial rounds.** Fix multiple components simultaneously — one agent per component. The bottleneck is verification, not implementation.

---

## AGENT ORCHESTRATION

| Phase | Agent(s) | Role | Output |
|-------|----------|------|--------|
| 1. Inventory | ux-qa-tester | Reviewer | section-checklist.md, mock-decomposition.md |
| 2. Audit | ux-qa-tester | Reviewer | round-N-audit.md |
| 3. Fix | senior-engineer (×N parallel) | Implementer | Code changes + commits |
| 4. Verify | ux-qa-tester | Reviewer | round-N+1-audit.md (checks stop conditions) |
| 5A. Data | architect | Reviewer | data-readiness.md |
| 5B. Responsive | ux-qa-tester | Reviewer | responsive-audit.md |
| 5C. Interactive | ux-qa-tester | Reviewer | interaction-audit.md |

**Phase 1** runs once. **Phases 2-4 loop** until convergence. **Phase 5** runs once after convergence.

---

## GH ISSUE INTEGRATION

Before Phase 3 (first round only):
1. File an **epic** for the overall mock parity effort
2. File **child issues** per component, referencing the epic
3. Each issue includes exact changes from Phase 2 audit

During Phase 3 (each round):
- Reference issue numbers in commits: `fix(earnings): restructure to match mock layout (#1234)`
- Close issues when the component passes verification

---

## CONVERGENCE METRICS

Track across rounds to prove the loop is converging:

```markdown
## Convergence Tracker

| Round | Sections OK | Properties Match | Content Match | P0 | P1 | P2+ | Status |
|-------|-------------|-----------------|---------------|----|----|-----|--------|
| 0 | 7/10 | 280/380 (74%) | 22/30 (73%) | 3 | 5 | 15 | FAIL |
| 1 | 9/10 | 342/380 (90%) | 28/30 (93%) | 1 | 2 | 8 | FAIL |
| 2 | 10/10 | 370/380 (97%) | 30/30 (100%) | 0 | 0 | 5 | FAIL |
| 3 | 10/10 | 378/380 (99%) | 30/30 (100%) | 0 | 0 | 2 | PASS |
```

If metrics plateau (no improvement across 2 rounds), escalate to user with a report of what's stuck and why.

---

## SCOPE: BEYOND CSS

100% mock parity sometimes requires changes beyond frontend CSS:

| What the mock shows | What may need to change |
|---------------------|------------------------|
| Data field not in session context | Backend: add field to context builder |
| Data from a new API source | Backend: new provider + MCP tool |
| Interactive behavior (e.g., scenario click updates projections) | Frontend: state management + event wiring |
| New component not in production | Frontend: create component from scratch |
| Different data visualization (e.g., bar chart vs table) | Frontend: restructure component |
| Different text content | Frontend: update labels, copy editor review |

The skill handles ALL of these — not just CSS tweaks.

---

## RECOVERY

If the conversation runs out of context mid-execution:
1. **Section checklist** and **round audit reports** survive in `reviews/`
2. **GH issues** track all remaining work
3. **Convergence tracker** shows where we left off
4. On resume: read the latest round audit, check which issues are still open, continue from the appropriate phase

---

## EXAMPLE INVOCATION

```
/mock-to-production reviews/left-panel-mock.html
```

or:

```
User: "implement this mock to 100% parity"
→ Skill activates with mock path from context
```

With spec:

```
/mock-to-production reviews/left-panel-mock.html --spec reviews/left-panel-spec.md
```
