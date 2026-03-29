# Execution Plan: Feedback Loop Frontend

**Agent:** eng-frontend
**Epic:** #1068
**Work Items:** WB-5, WB-6, WB-7, WB-8, WB-10
**Status:** COMPLETE

---

## Files Created

| File | Purpose |
|------|---------|
| `frontend/lib/feedback-context.tsx` | Session provider + MCP stripping utilities (WB-10) |
| `frontend/components/FeedbackButton.tsx` | Thumbs-down button + inline form trigger (WB-5) |
| `frontend/components/FeedbackForm.tsx` | Inline form: "What's wrong?", Submit, Cancel (WB-6) |

## Files Modified

| File | Change |
|------|--------|
| `frontend/lib/types.ts` | Added `ComponentType`, `FeedbackSubmitRequest`, `FeedbackSubmitResponse` |
| `frontend/lib/api.ts` | Added `submitFeedback(sessionId, body)` (WB-7) |
| `frontend/components/ModuleCard.tsx` | Added `feedbackSlot?: ReactNode` prop + `CardHeader` slot |
| `frontend/app/session/[sessionId]/page.tsx` | Wrapped `SessionContent` with `FeedbackSessionProvider` |
| `frontend/components/ChatMessage.tsx` | Added FeedbackButton (hover-reveal, assistant-only, non-streaming) |
| `frontend/components/cards/EarningsCard.tsx` | Added FeedbackButton via `feedbackSlot` |
| `frontend/components/cards/RiskCard.tsx` | Added FeedbackButton via `feedbackSlot` |
| `frontend/components/cards/RegulationsCard.tsx` | Added FeedbackButton via `feedbackSlot` |
| `frontend/components/cards/FinancingCard.tsx` | Added FeedbackButton in header section |
| `frontend/components/DecisionSurface.tsx` | Added FeedbackButton next to CopyButton |
| `frontend/components/cards/ScenarioCard.tsx` | Added FeedbackButton (ready status only) |

---

## Architecture Decisions

### FeedbackSessionProvider
Wraps `SessionContent` in `page.tsx`. Extracts from `SessionState`:
- `listing_url` from `session.context` (tries `listing_url`, `zillow_url`, `property_url`)
- Property facts (beds, baths, sqft, price, type) from `session.context`
- `sessionContextJson` — context with all `_mcp_*` keys stripped (AC-4)
- `overridesJson` — full override log history (AC-5)
- `dataFreshnessSeconds` — from `session.updated_at` (AC-7)

### FeedbackButton
- Self-contained: manages open/submitted state
- Click-outside dismissal via `mousedown` listener on container ref
- Fire-and-forget: `submitFeedback().catch(() => {})` — never blocks UI
- Dev-mode 400KB size warning (§5.2 advisory pre-check)
- Returns `null` if no session context (safe when provider absent / session loading)

### ModuleCard feedbackSlot
Cards pass `feedbackSlot={data && <FeedbackButton ... />}` — only renders when data is available.
`CardHeader` wraps slot in `onClick.stopPropagation()` so clicks don't trigger card collapse.
Slot hidden when `isSelectMode` is true (AC-18).

### Hover vs always-visible
Parents control visibility via wrapper classes. For `ChatMessage`, the button sits inside the existing `opacity-0 group-hover:opacity-100` wrapper. For card headers (ModuleCard, FinancingCard, DecisionSurface, ScenarioCard), buttons are always visible.

---

## AC Coverage

| AC | Status |
|----|--------|
| AC-1 (all surfaces) | Done — 7 surfaces wired |
| AC-2 (property context) | Done — FeedbackSessionProvider extracts all facts |
| AC-3 (monthly breakdown) | Done — `data as-is` passes all backend fields including any monthly_breakdown |
| AC-4 (_mcp_* stripping) | Done — `stripMcpKeys()` in feedback-context.tsx |
| AC-5 (override history) | Done — full `session.overrides` array |
| AC-7 (data_freshness) | Done — from session.updated_at |
| AC-15 (hover/visible) | Done |
| AC-16 (inline form) | Done — FeedbackForm.tsx, no modals |
| AC-17 (submit animation) | Done — `fill-current` on submitted icon |
| AC-18 (hidden states) | Done — streaming/select mode handled in each component |

---

## TypeScript
`tsc --noEmit` passes with exit 0. No type errors.
