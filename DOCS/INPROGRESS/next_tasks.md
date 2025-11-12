# Next Tasks

## Active

### Core Work (Current Priority)
- [ ] **T6.3 — SDK Tolerant Parsing Documentation** (Priority: Medium, Effort: 1 day)
  - Create DocC article `TolerantParsingGuide.md` in `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/`
  - Add code examples for tolerant parsing setup and `ParseIssueStore` usage
  - Update inline documentation for `ParsePipeline.Options`, `.strict`, `.tolerant`
  - Link new guide from main `Documentation.md` Topics section
  - Verify examples with test file in `Tests/ISOInspectorKitTests/`
  - See `DOCS/INPROGRESS/211_T6_3_SDK_Tolerant_Parsing_Documentation.md` for full PRD

### FoundationUI Integration (New Feature)
**See detailed plan in:** `DOCS/INPROGRESS/FoundationUI_Integration_Strategy.md`

#### Phase 0: Setup & Verification (Upcoming)
**Duration:** 3-4 days | **Priority:** P0 (blocks all following phases)

- [ ] **I0.1 — Add FoundationUI Dependency** (Effort: 0.5d)
  - Add FoundationUI as dependency in ISOInspectorApp Package.swift
  - Verify builds with FoundationUI target
  - Update Package.swift platform requirements if needed

- [ ] **I0.2 — Create Integration Test Suite** (Effort: 0.5d)
  - Create `Tests/ISOInspectorAppTests/FoundationUI/` directory structure
  - Set up XCTest framework for FoundationUI tests
  - Create test templates for snapshot/unit/integration patterns

- [ ] **I0.3 — Build Component Showcase** (Effort: 1.5d)
  - Create SwiftUI view: `ComponentShowcase.swift`
  - Add tabs for each FoundationUI layer (Foundation, Components, Patterns, Contexts)
  - Render all components from FoundationUI for visual testing
  - Make scrollable and searchable for development velocity

- [ ] **I0.4 — Document Integration Patterns** (Effort: 0.5d)
  - Add "FoundationUI Integration" section to `03_Technical_Spec.md`
  - Document architecture patterns for wrapping FoundationUI components
  - Add code examples for badge, card, pattern wrappers

- [ ] **I0.5 — Update Design System Guide** (Effort: 0.5d)
  - Update `10_DESIGN_SYSTEM_GUIDE.md` with integration checklist
  - Document migration path: old UI → FoundationUI
  - Add quality gates per phase

#### Phase 1: Foundation Components (Weeks 2-3)
**Subtasks to be created after Phase 0 completion**
- I1.1 Badge & Status Indicators (1-2d)
- I1.2 Card Containers & Sections (2-3d)
- I1.3 Key-Value Rows & Metadata (2-3d)

#### Future Phases (4-6)
See detailed breakdown in `FoundationUI_Integration_Strategy.md`:
- Phase 2: Interactive Components (Week 4)
- Phase 3: Layout Patterns (Weeks 5-7)
- Phase 4: Platform Adaptation & Contexts (Week 8)
- Phase 5: Advanced Features (Week 9)
- Phase 6: Full Integration & Validation (Week 10)

## Blocked (Hardware)

- [ ] Run the lenient-versus-strict benchmark on macOS hardware with Combine enabled using the 1 GiB fixture:
  - Export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`.
  - Invoke `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`.
  - Archive the printed runtime and RSS metrics under `Documentation/Performance/` alongside the existing 32 MiB results.
  - Cross-check results against the archived Linux baseline in `Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log` and note deviations in the summary log.

## Notes

- FoundationUI Integration is tracked separately to avoid mixing with SDK documentation work (T6.3)
- Phase 0 is a critical blocker for all integration phases
- Each phase gates on test coverage ≥80%, accessibility ≥95%, performance baselines
- Roadmap: 9 weeks total (45 working days) if executing serially
- Can parallelize T6.3 (documentation) with FoundationUI Phase 0 (setup)
