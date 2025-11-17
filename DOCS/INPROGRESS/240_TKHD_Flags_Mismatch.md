# Bug Report 240: `tkhd` Flags Mismatch Should Accept Bitmask Combination

## Objective
Capture the potential false-positive integrity issue where the `tkhd` atom expects flags value `0x000007` but encounters `0x000001`, even though flags represent a bitmask combination.

## Symptoms
- Integrity checks log an error: “tkhd flags mismatch: expected 0x000007 but found 0x000001”.
- `tkhd` flags are bitmasks (track enabled, in movie, in preview). Value `0x000007` combines all three, while `0x000001` indicates only the first bit.
- The tool treats the difference as an outright error, though some files legitimately set subsets of flags.

## Environment
- ISOInspector integrity checking pipeline (likely Swift parsing of MP4 atoms).
- Applies when analyzing tracks whose `tkhd` flags do not match the strict constant.

## Reproduction Steps
1. Open an MP4/ISO file whose track header flags equal `0x000001`.
2. Run integrity analysis.
3. Observe the mismatch error reported.

## Expected vs. Actual
- **Expected:** Integrity checker should validate presence/absence of required bits rather than enforcing a single combined value, or at least provide context before marking it as error.
- **Actual:** Any deviation from `0x000007` triggers an error, even when the bitmask combination is acceptable.

## Open Questions
- Which flag bits are truly required? Are tracks valid if only some bits are set?
- Should we downgrade to warning unless mandatory bits are missing?
- Do we have specs or references validating acceptable flag patterns?

## Scope & Hypotheses
- Front of work: Integrity rules for MP4 `tkhd` atom within parser/validator modules.
- Hypothesis: Validator compares against constant rather than performing bitwise checks.
- Need to review MP4 specs and update the rule to ensure compliance.

## Diagnostics Plan
1. Locate the validator logic for `tkhd` flags (search for `tkhd` or `TrackHeaderBox`).
2. Confirm current comparison is equality vs. bitmask evaluation.
3. Identify mandatory bits from spec references to refine rule.

## TDD Testing Plan
- Unit tests covering various flag combinations, ensuring only missing required bits produce errors.
- Regression test to ensure `0x000001` and other legitimate values no longer trigger false positives.
- Test verifying detailed messaging when actual invalid combinations occur.

## PRD Update
- **Customer Impact:** False-positive errors reduce trust in the tool and may block certification workflows.
- **Acceptance Criteria:** Validator allows valid bit combinations per spec; errors only when required bits absent; message clarifies actual vs. expected bits.
- **Technical Approach:** Replace strict equality with bitmask checks referencing MP4 spec.

## Status
Awaiting engineering analysis; no code touched.
