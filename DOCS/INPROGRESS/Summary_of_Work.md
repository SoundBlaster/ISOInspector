# Summary of Work — E3 Advisory Ordering Rule

## Completed Tasks
- **E3 — Warn on Unusual Top-Level Ordering**: Added `TopLevelOrderingAdvisoryRule` to `BoxValidator` so CLI/JSON streams flag atypical `ftyp`/`moov` sequences while keeping streaming layouts advisory-only, and expanded live pipeline tests to cover the new warnings.

## Verification
- `swift test`【90aa08†L1-L196】

## Follow-Ups
- None.
