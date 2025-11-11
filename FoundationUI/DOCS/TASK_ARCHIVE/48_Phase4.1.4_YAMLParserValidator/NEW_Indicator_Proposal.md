# New Feature Proposal: Indicator

## Summary
Indicator is a compact status dot that mirrors Badge semantics without text or iconography. It conveys the same levels (info, warning, error, success) using DS color tokens and surfaces the underlying message through platform tooltips or a fallback badge presentation. This fills a gap for dense layouts where full badges are visually heavy while preserving clarity and accessibility expectations.

## Analysis Results

### Layer Classification
- **Layer**: 2 — Reusable Component
- **Priority**: P0 (extends core status vocabulary needed across Inspector and Sidebar patterns)

### Dependencies
- `BadgeLevel` enum (existing source of semantic levels)
- `BadgeChipStyle` (color mapping + DS token usage for status semantics)
- `DS.Colors.{infoBG|warnBG|errorBG|successBG}` for fill/background colors
- `DS.Spacing` tokens to derive dot diameters and padding
- `.copyable(text:showFeedback:)` modifier for Copyable protocol compliance
- System tooltip/menu presentation APIs (`.help(_:)` on macOS, `contextMenu`/`hoverEffect` triggers on iOS/iPadOS)

### Existing Components Review
- **Badge** (Layer 2) already exposes the visual + semantic mapping for status. Indicator will reuse `BadgeLevel` and token-driven color logic but omit text/icon.
- **BadgeChipStyle** (Layer 1) centralizes DS color usage for status surfaces. Indicator can extract core fill + outline values here to avoid duplication.
- **CopyableText/Copyable** (Layer 2) demonstrate how Copyable protocol behaviors are layered via the `.copyable` modifier. Indicator will piggyback on the same modifier to expose copy interactions (e.g., copying the underlying reason string).
- **AgentDescribable** support already serializes badges; Indicator should hook into the same schema once implemented to guarantee agent parity (follow-up once component exists).

## Documentation Updates

### Task Plan
- Added a new Phase 2.2 task for implementing the Indicator component, decreasing completion percentage for Phase 2 and overall totals.
- Updated global progress counters and Phase 2 progress block to account for the new backlog item.

### PRD
- Documented Indicator in the Core Components table and added an API specification detailing usage, platform adaptations, and tooltip behavior expectations.

### Test Plan
- Introduced Indicator coverage requirements across unit, snapshot, accessibility, integration, and performance sections, mirroring Badge expectations.

## Next Steps
1. Define shared styling helpers in `BadgeChipStyle` (or a new internal utility) so Indicator reuses token-backed fills/borders.
2. Implement `Indicator` component with size variants, optional outline, tooltip bindings, and Copyable integration.
3. Author unit, snapshot, accessibility, and performance tests covering all levels, size variants, and tooltip interactions.
4. Extend AgentDescribable schema/examples to cover Indicator once implementation stabilizes.

## Open Questions
- Should Indicator expose a configurable outline (e.g., for unavailable/unknown states) or strictly follow filled-dot semantics?
- What is the default copy payload when Copyable is enabled—raw status key ("error") or localized reason text supplied by the caller?
- For iOS/iPadOS, do we standardize on `contextMenu` with a Badge preview, or fall back to a textual tooltip to avoid heavy UI in compact contexts?

---
**Proposal Date**: 2025-11-10
