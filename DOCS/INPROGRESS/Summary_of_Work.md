# Summary of Work — 2025-10-19

## Completed Tasks

- **C9 — `stsz/stz2` sample size parser**
  - Added dedicated parsers for the `stsz` and `stz2` boxes, capturing per-sample byte ranges and truncation status while registering them with the shared `BoxParserRegistry`.
  - Extended `ParsedBoxPayload` and the JSON exporter to surface structured sample size data for CLI/UI consumers, updating the baseline snapshot fixture accordingly.
  - Introduced focused unit coverage (`StszSampleSizeParserTests`, `Stz2CompactSampleSizeParserTests`) to exercise constant, variable, and malformed sample tables.

## Validation

- `swift test`

## Follow-Ups

- @todo #15 — correlate `stsc`, `stsz/stz2`, and upcoming `stco/co64` data during validation once chunk offset parsing is available.
