# Bug Report 241: Box Details Cards Use Non-Monospaced Font

## Objective
Document the styling inconsistency where certain cards within Box Details render using the system proportional font instead of the intended monospaced typeface.

## Symptoms
- Some cards show values (offsets, sizes, flags) using SF Pro or default system font.
- Other cards properly use the monospaced font, leading to inconsistent alignment.
- Makes it harder to scan numerical fields.

## Environment
- Box Details UI in ISOInspector on macOS.
- Affects specific card types (to be enumerated during implementation).

## Reproduction Steps
1. Open a file and navigate to Box Details.
2. Compare cards showing numeric metadata.
3. Observe that some cards use monospaced font while others use proportional font.

## Expected vs. Actual
- **Expected:** All cards intended for structured numeric data use the monospaced font for alignment.
- **Actual:** A subset of cards fall back to the default system font.

## Open Questions
- Which cards should explicitly use monospaced styling? All numeric? Hex only?
- Is the style defined in a shared modifier that some cards forgot to apply?

## Scope & Hypotheses
- Front of work: Box Details card components and shared typography modifiers.
- Hypothesis: Some card views bypass the shared `MonoTextStyle` or apply `.font(.body)` overriding it.
- Need to audit style definitions and ensure consistent application.

## Diagnostics Plan
1. Review card view implementations to see where fonts are set.
2. Identify whether `MonoTextStyle` or similar modifier exists but not used.
3. Determine if dynamic type or accessibility adjustments interfere with monospaced rendering.

## TDD Testing Plan
- Snapshot/UI tests confirming all card variants render with monospaced fonts for numeric text.
- Unit test for shared modifier to ensure it sets `.monospacedDigit()` or equivalent.
- Visual regression checks to prevent reintroducing proportional fonts.

## PRD Update
- **Customer Impact:** Inconsistent typography reduces readability of technical data.
- **Acceptance Criteria:** Every Box Details card that displays numeric/structured data uses the monospaced font consistently across light/dark mode.
- **Technical Approach:** Centralize font styling and apply to all relevant cards.

## Status
Bug documented; awaiting prioritization before code changes.
