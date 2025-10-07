# PRD: Enumerated Four-Character Container Codes

## 1. Objective & Scope
- **Problem Statement:** Replace ad-hoc `Set<String>` usage for MP4/ISO BMFF container box detection with a strongly-typed enum encompassing all known four-character container codes.
- **Goal:** Provide an implementation-ready specification for introducing a `FourCharContainerCode` enum (string-backed) that centralizes allowed values, simplifies usage, and enforces compile-time safety across parsing utilities.
- **In-Scope:**
  - Defining the enum and associated helpers within the ISOInspectorKit Swift sources.
  - Refactoring existing code (e.g., `StreamingBoxWalker.shouldParseChildren`) to leverage the enum.
  - Updating tests, documentation, and serialization logic that depend on container code literals.
- **Out-of-Scope:**
  - Adding new box parsing logic beyond enum integration.
  - Changing IO or CLI behaviour unrelated to container detection.

## 2. Success Criteria
- All container detection logic uses the enum cases rather than raw string literals.
- Central source of truth for four-character codes exists with documentation for each case.
- Tests cover enum mapping and ensure no regression in traversal logic.
- Static analysis / linting succeeds with no string literal references remaining for these codes.

## 3. Assumptions & Constraints
- Swift version and tooling remain unchanged (SwiftPM project).
- Existing four-character codes list is authoritative; additional codes must be reviewed with product owner.
- Enum must be usable anywhere a `String` raw value is expected (e.g., bridging to Set/Dictionary keys).
- Backwards compatibility: API changes should maintain external behaviour (public API adjustments must be versioned if needed).

## 4. Stakeholders & Impact
- **Primary Users:** Developers maintaining ISOInspectorKit parsing logic.
- **Secondary:** Automated agents executing traversal/testing workflows.
- **Impact:** Improved maintainability, fewer typos, easier feature additions for new container types.

## 5. Implementation Plan & Work Breakdown

### 5.1 Phases
1. **Design Enum & Utilities** – create enum, document cases, add helper APIs.
2. **Integrate Into Parsing Logic** – replace string literals, adapt data structures.
3. **Quality Assurance** – add/update tests, ensure documentation alignment.

### 5.2 Detailed Task Table
| ID | Task | Description | Priority | Effort | Dependencies | Tools / Inputs | Acceptance Criteria |
|----|------|-------------|----------|--------|--------------|----------------|---------------------|
| T1 | Enumerate Codes | Define `enum FourCharContainerCode: String, CaseIterable` capturing all existing four-character values with doc comments referencing ISO/IEC standard context. Provide static collections for convenience (e.g., `allCasesSet`). | High | 2 | None | Existing code list, Swift docs | Enum compiles, raw values match prior strings, doc comments generated. |
| T2 | Add Parsing Helpers | Implement helper methods (e.g., initializer from `BoxType`/`String`, computed property returning raw value) and ensure fallbacks for unknown codes. | High | 2 | T1 | SwiftPM | Helpers validated with unit tests for valid/invalid conversions. |
| T3 | Refactor `StreamingBoxWalker` | Replace `containerTypes` set with enum-driven logic (e.g., `Set(FourCharContainerCode.allCases.map(\.rawValue))` or direct membership check). Ensure readability and performance. | High | 1 | T1, T2 | Source file | All references use enum, tests/build succeed. |
| T4 | Update Related Modules | Search and replace other occurrences of these strings across project (tests, docs) to use enum or centralized constant. | Medium | 2 | T1 | `rg`, SwiftPM tests | No stray literals found; code references compile with enum. |
| T5 | Testing & Validation | Add/extend unit tests verifying traversal still processes known container boxes, and tests for enum conversions. | High | 2 | T3 | SwiftPM test suite | `swift test` passes; new tests cover success/failure cases. |
| T6 | Documentation Update | Update developer docs / READMEs referencing container codes to mention enum usage. | Medium | 1 | T3 | Markdown editors | Docs mention new enum; references consistent. |

### 5.3 Parallelization Notes
- T1 must precede all other tasks.
- T2 and T3 can begin once enum skeleton exists.
- T4, T5, T6 can run in parallel after refactor is stable.

## 6. Functional Requirements
1. **Enum Definition:**
   - Provide `FourCharContainerCode` with cases for each existing string: `moov`, `trak`, `mdia`, `minf`, `dinf`, `stbl`, `edts`, `mvex`, `moof`, `traf`, `mfra`, `tref`, `udta`, `strk`, `strd`, `sinf`, `schi`, `stsd`, `meta`, `ilst`.
   - Enum must conform to `String`, `CaseIterable`, `Codable`, `Hashable`, and `Sendable` if available.
   - Include initializer `init?(rawValue:)` (inherited) plus convenience init from `BoxType`/`BoxHeader` types used in the codebase.

2. **Lookup & Validation:**
   - Provide static method `isContainer(_:)` accepting `BoxType`/`String` returning boolean via enum membership.
   - Provide computed property `.rawValue` to maintain compatibility with string-based APIs.

3. **Integration:**
   - Update `StreamingBoxWalker.shouldParseChildren` to call `FourCharContainerCode(rawValue:)` rather than referencing a `Set<String>`.
   - Remove redundant `Set<String>` constants.
   - Update any other data structures (e.g., filtering sets) to leverage the enum or derived set.

4. **Testing:**
   - Add unit tests verifying conversion from `BoxType` to enum cases and rejection of unknown codes.
   - Regression tests ensuring traversal of nested boxes works using the enum-based check.

## 7. Non-Functional Requirements
- **Performance:** Membership checks must remain O(1); prefer caching a `Set<FourCharContainerCode>` or using dictionary keyed by enum rawValue.
- **Maintainability:** Enum should be easy to extend with new cases and central documentation; avoid scattering raw strings.
- **Code Quality:** Follow Swift API design guidelines; include doc comments for each case referencing container purpose.
- **Compatibility:** Ensure no public API breakage unless version bump is planned; provide fallback wrappers if necessary.

## 8. Edge Cases & Error Handling
- Unknown box types should not crash; helper initializers must return `nil` while traversal defaults to non-container behaviour.
- Empty or malformed strings should be safely rejected.
- Ensure enum remains synchronized with spec updates; include TODO note in docs for review cycle.

## 9. Acceptance & Verification
- All unit tests (`swift test`) pass without modifications.
- Static analysis (if configured) passes with no warnings about unused strings.
- Manual walkthrough verifying `StreamingBoxWalker` still processes nested containers correctly with sample files.
- Documentation updates merged alongside code changes and cross-referenced in CHANGELOG if applicable.

## 10. Open Questions & Follow-Ups
- Confirm whether other modules (CLI, UI) rely on raw strings externally; if so, create compatibility layer rather than direct enum exposure.
- Determine if more four-character codes should be included (consult MP4 spec) and schedule follow-up PRD if expansion required.

