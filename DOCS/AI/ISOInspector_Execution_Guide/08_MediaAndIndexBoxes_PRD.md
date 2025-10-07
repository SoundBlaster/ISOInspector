# PRD: Enumerated Media & Index Box Codes (`mdat`, `sidx`, `styp`)

## 1. Objective & Scope
- **Problem Statement:** Core workflows (validators, streaming heuristics, summaries) still depend on raw string literals for
  the `mdat`, `sidx`, and `styp` boxes. This undermines the benefits introduced by `FourCharContainerCode`, duplicating values
  and increasing typo risk for frequently referenced non-container structures.
- **Goal:** Define an implementation-ready plan to migrate these three structural boxes into strongly typed enum cases that can
  be reused across ISOInspectorKit without direct string comparisons.
- **In-Scope:**
  - Creating a dedicated enum (or extending an existing one when appropriate) that represents media payload (`mdat`) and
    streaming index markers (`sidx`, `styp`).
  - Updating validation, streaming detection, and documentation to consume the enum instead of raw strings.
  - Ensuring the enum interoperates with `FourCharCode`, `BoxHeader`, and other parsing primitives.
- **Out-of-Scope:**
  - Broader refactors of unrelated validation rules or CLI formatting.
  - Adding full parsing of `sidx`/`styp` payload bodies (only identification and classification is targeted).

## 2. Success Criteria
- Source no longer references `"mdat"`, `"sidx"`, or `"styp"` literals outside of the enum declaration and sanctioned fixture
  builders.
- Validators and streaming heuristics rely on enum-driven helpers for ordering decisions and streaming indicator detection.
- Tests cover conversion and classification logic for the new enum, including fixture generation and live pipeline usage.
- Documentation updates describe the enum and how it is used within ordering rules and streaming contexts.

## 3. Assumptions & Constraints
- Existing behaviour—`mdat` skipped but tracked, `sidx`/`styp` treated as streaming signals—must remain unchanged.
- Enum should remain lightweight, ideally a `String`-backed type to preserve compatibility with current APIs and serialization
  patterns.
- Backwards compatibility is critical: public API adjustments require careful consideration or typealiases to avoid breaking
  downstream packages.
- Tooling (SwiftPM, lint scripts, markdown formatting) remains the same as in prior tasks.

## 4. Stakeholders & Impact
- **Primary Users:** ISOInspectorKit maintainers who add validation rules or streaming heuristics.
- **Secondary Users:** CLI/UI surfaces depending on validator messaging consistency.
- **Impact:** Reduced maintenance overhead, easier onboarding for future contributors, and improved alignment with the enum-based
  architecture established for container boxes.

## 5. Implementation Plan & Work Breakdown

### 5.1 Phases
1. **Design Enum Structure** – Decide whether to extend `FourCharContainerCode` or introduce a sibling enum (e.g.
   `FourCharStructuralCode`) covering media/index boxes with associated helpers.
2. **Integrate Into Workflows** – Replace raw strings in validators, heuristics, and parsing utilities with the enum.
3. **Quality Assurance** – Update unit/integration tests and documentation to reflect the new enum-driven approach.

### 5.2 Detailed Task Table
| ID | Task | Description | Priority | Effort | Dependencies | Tools / Inputs | Acceptance Criteria |
|----|------|-------------|----------|--------|--------------|----------------|---------------------|
| T1 | Enumerate Codes | Define enum cases for `mdat`, `sidx`, `styp` with spec-referenced documentation. Ensure the type conforms to `String`, `CaseIterable`, `Codable`, `Hashable`, and `Sendable` (where available). | High | 2 | `FourCharCode` utilities | Swift docs, MP4RA references | Enum compiles; raw values match spec names; doc comments render. |
| T2 | Provide Conversion APIs | Add initialisers from `String`, `FourCharCode`, and `BoxHeader` plus helper sets (e.g. `streamingIndicators`, `mediaPayloads`). | High | 2 | T1 | SwiftPM | Helpers verified via unit tests; membership queries constant time. |
| T3 | Refactor Validators | Update `FileTypeOrderingRule` and `MovieDataOrderingRule` (and any related heuristics) to utilise the enum instead of literal strings. | High | 2 | T1, T2 | Source files, `rg` | Validators compile; logic mirrors previous behaviour; diff removes string literals. |
| T4 | Update Fixtures & Builders | Adjust test helpers and fixtures referencing these codes to use enum-provided constants, only leaving raw strings where protocol-level byte arrays are required. | Medium | 1 | T1 | Test suite | Tests compile with new helpers; fixtures remain readable. |
| T5 | Testing | Extend unit/integration tests to cover enum conversions, streaming indicator detection, and ordering behaviours. | High | 2 | T3, T4 | `swift test` | All tests pass; new assertions verify enum adoption. |
| T6 | Documentation | Document enum usage in README, execution guide, and in-progress summaries; update backlog/todo references if needed. | Medium | 1 | T3 | Markdown editors | Docs mention enum; guidance consistent with implementation. |

### 5.3 Parallelisation Notes
- T1 must complete before T2–T6.
- T3 and T4 can proceed once the enum skeleton and helpers are in place.
- Testing and documentation updates (T5, T6) should follow integration refactors.

## 6. Functional Requirements
1. **Enum Definition:**
   - Cases: `mediaData` (`"mdat"`), `segmentIndex` (`"sidx"`), `segmentType` (`"styp"`).
   - Provide static sets categorising cases (e.g. `streamingIndicators` containing `sidx`/`styp`, `mediaPayloads` containing `mdat`).
   - Expose `.fourCharCode` and conversion initialisers akin to `FourCharContainerCode` for API consistency.
2. **Integration Hooks:**
   - `BoxValidator` ordering rules leverage helper methods such as `isMediaPayload(_:)` and `isStreamingIndicator(_:)` to determine
     rule triggers.
   - Streaming pipeline heuristics (e.g. `ParsePipelineLiveTests` fixtures, CLI summarisation) reference the enum when emitting
     events or filtering boxes.
   - Fixture builders may continue to accept raw strings for binary payload creation, but should rely on enum raw values when
     specifying types.
3. **Testing:**
   - Unit tests cover conversion from raw strings and headers to enum cases, plus negative cases for unknown codes.
   - Integration tests assert that validators still issue VR-004/VR-005 messages under the correct conditions while using the
     enum-based helpers.

## 7. Non-Functional Requirements
- **Performance:** Membership checks must remain O(1); prefer cached `Set` representations inside the enum for classification.
- **Maintainability:** Enum should mirror the documentation style of `FourCharContainerCode` for easy extension and discoverability.
- **Code Quality:** Follow Swift API guidelines, ensuring descriptive names and doc comments for each case and helper.
- **Compatibility:** Avoid breaking public APIs; if public surfaces change, document migration steps and consider typealiases.

## 8. Edge Cases & Error Handling
- Enum initialisers must gracefully return `nil` for unknown raw values to prevent accidental classification.
- Ensure validators ignore cases where `mdat` appears after `moov` even when the enum is used, preserving existing streaming
  exceptions.
- Guard against misclassifying `styp`/`sidx` in files where they do not signal streaming (tests should cover baseline sequential
  MP4s).

## 9. Acceptance & Verification
- `swift test` passes without additional warnings.
- Static analysis (if configured) or lint scripts show no stray literals for the targeted codes.
- Manual review of validator outputs confirms VR-004/VR-005 behave identically after migration.
- Documentation updates merged alongside code changes with references to enum usage.

## 10. Open Questions & Follow-Ups
- Should the new enum live alongside `FourCharContainerCode` (e.g. `FourCharStructuralCode`) or should the container enum be
  extended with metadata describing whether a case is a container? Decision impacts ergonomics for future expansions (`free`,
  `skip`, `uuid`).
- Would additional boxes like `ssix`, `prft`, or `tfra` benefit from the same enum in this iteration, or should they remain
  literals pending further research?
- Consider whether CLI/JSON outputs should surface enum names directly, and if so, plan a backwards-compatible rollout strategy.
