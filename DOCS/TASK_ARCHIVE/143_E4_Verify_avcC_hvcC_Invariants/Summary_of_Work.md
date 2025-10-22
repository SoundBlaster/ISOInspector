# Summary of Work — 2025-10-22

## Completed Tasks
- **E4 — Verify avcC/hvcC Invariants**: Added `CodecConfigurationValidationRule` to `BoxValidator` so ISOInspectorKit validates `lengthSizeMinusOne`, parameter-set counts, and HEVC NAL array integrity. The rule inspects protected sample entries, checks for zero-length NAL units, and flags truncated payloads with contextual messages shared across CLI/JSON outputs.

## Verification
- `swift test --filter BoxValidatorTests`

## Follow-ups
- Expand end-to-end ParsePipeline and CLI/JSON snapshot coverage to exercise new codec warnings once broader validation suites are updated.
