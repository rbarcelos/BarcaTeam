# Accessibility Audit

Structured WCAG 2.1 AA compliance audit for frontend components. Used by the `accessibility-reviewer` agent.

## Trigger

Used by agents with `accessibility-audit` in their skills list, or when accessibility concerns are raised.

## Procedure

### STEP 1: DISCOVER FRONTEND STRUCTURE

```bash
cd /c/Users/rbarcelo/repo/investFlorida.ai

# Page routes
ls frontend/app/
find frontend/app -name "page.tsx" 2>/dev/null

# Components
ls frontend/components/
ls frontend/components/cards/ 2>/dev/null

# Layout
cat frontend/app/layout.tsx | head -30
```

### STEP 2: AUTOMATED CHECKS

Run static analysis checks that can be done from code:

#### 2a. Semantic HTML
```bash
# Find non-semantic interactive elements (divs with onClick, spans with onClick)
grep -rn "onClick" frontend/ --include="*.tsx" | grep -v "button\|Button\|<a " | head -20

# Find images without alt text
grep -rn "<img" frontend/ --include="*.tsx" | grep -v "alt=" | head -20

# Find inputs without labels
grep -rn "<input" frontend/ --include="*.tsx" | grep -v "aria-label\|aria-labelledby\|id=" | head -20
```

#### 2b. ARIA Usage
```bash
# Check for aria attributes
grep -rn "aria-" frontend/ --include="*.tsx" | wc -l
grep -rn "role=" frontend/ --include="*.tsx" | head -20

# Check for aria-live regions (dynamic content)
grep -rn "aria-live" frontend/ --include="*.tsx"

# Check for aria-expanded (collapsible sections)
grep -rn "aria-expanded" frontend/ --include="*.tsx"
```

#### 2c. Color Contrast
```bash
# Find text color classes to manually verify contrast
grep -rn "text-\(slate\|gray\|zinc\)" frontend/ --include="*.tsx" | head -20

# Find small/light text that might fail contrast
grep -rn "text-xs.*opacity\|opacity.*text-xs\|text-sm.*opacity\|text-\w*-[345]00" frontend/ --include="*.tsx" | head -20
```

#### 2d. Focus Management
```bash
# Check for focus management
grep -rn "focus\|tabIndex\|tab-index" frontend/ --include="*.tsx" | head -20

# Check for outline-none (focus indicator removal)
grep -rn "outline-none\|focus:outline-none" frontend/ --include="*.tsx" | head -20
```

### STEP 3: COMPONENT-BY-COMPONENT REVIEW

For each critical component, read the full source and evaluate:

1. **DecisionSurface.tsx** — Score badge, verdict, metric tiles, breakdown popup
2. **Chat interface** — Message list, input field, streaming, tool results
3. **Cards** — Overview, Earnings, Financing, Regulations, Comparison
4. **HydrationBanner.tsx** — Loading states, progress indicators
5. **Report templates** — HTML report sections

For each, check:
- [ ] Keyboard navigable (all interactive elements reachable via Tab)
- [ ] Screen reader accessible (labels, roles, live regions)
- [ ] Color not sole indicator (status communicated via text too)
- [ ] Focus visible (clear focus ring on all interactive elements)
- [ ] Touch targets adequate (44x44px minimum on mobile)

### STEP 4: FLOW-LEVEL ASSESSMENT

Trace keyboard-only navigation through key user flows:
1. **Property analysis flow**: Homepage → address input → submit → loading → results
2. **Chat interaction**: Focus input → type → send → read response → follow suggestion
3. **Score exploration**: See verdict → open breakdown → read details → close
4. **Scenario modeling**: Open what-if → adjust slider → see impact → compare

### STEP 5: PRODUCE FINDINGS

Write findings using the accessibility-reviewer's output format (see agent config). Include WCAG criterion reference for each finding.

## WCAG Quick Reference (AA Level)

### Must-Fix (Level A)
- 1.1.1 Non-text content needs alt text
- 1.3.1 Info conveyed by semantic structure
- 2.1.1 All functionality via keyboard
- 2.4.1 Skip navigation links
- 4.1.2 Custom components need ARIA name/role/value

### Should-Fix (Level AA)
- 1.4.3 Text contrast 4.5:1 (3:1 for large text)
- 1.4.11 Non-text contrast 3:1
- 2.4.7 Focus visible
- 2.4.11 Focus not obscured by fixed elements
- 1.4.4 Content readable at 200% zoom

## Rules

- Reference specific WCAG criteria for every finding
- Provide specific fix code (aria-label, role, etc.) not just "add accessibility"
- Prioritize components that handle financial decision data
- Check both desktop and mobile layouts
- Color-only indicators for GO/CAUTION/NO-GO are critical to fix — investors may be color-blind
