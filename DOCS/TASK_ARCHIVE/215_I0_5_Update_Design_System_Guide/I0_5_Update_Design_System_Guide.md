# I0.5 — Update Design System Guide

## 🎯 Objective

Update the Design System Guide (`10_DESIGN_SYSTEM_GUIDE.md`) with FoundationUI integration checklist, migration path from old UI patterns to FoundationUI components, quality gates per integration phase, and comprehensive accessibility requirements to ensure consistent, accessible UI implementation across all future development phases.

## 🧩 Context

**Phase 0 Status:**
- ✅ I0.1 — FoundationUI Dependency Added
- ✅ I0.2 — Integration Test Suite Created (123 tests)
- ✅ I0.3 — Component Showcase Available (ComponentTestApp)
- ✅ I0.4 — Integration Patterns Documented
- ⏳ **I0.5 — Update Design System Guide** (CURRENT TASK)

**Background:**
- FoundationUI integration is now complete at the infrastructure level
- Phase 1 implementation (Badge, Card, KeyValueRow migration) is blocked on this documentation
- The Design System Guide currently exists but needs FoundationUI-specific guidance
- ComponentTestApp provides live examples of FoundationUI usage patterns
- Integration test suite establishes quality baselines (≥80% coverage, ≥98% accessibility)

**Related Documents:**
- `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md` — Current design system guide
- `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md` — Integration patterns (updated in I0.4)
- `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md` — 9-week phased roadmap
- `Examples/ComponentTestApp/` — Component showcase with 14+ screens
- `Tests/ISOInspectorAppTests/FoundationUI/` — 123 integration tests

## ✅ Success Criteria

### Core Requirements
- [ ] Add "FoundationUI Integration Checklist" section to Design System Guide
- [ ] Document migration path: old UI patterns → FoundationUI components with code examples
- [ ] Add quality gates per integration phase (Phase 0-6)
- [ ] Document accessibility requirements (≥98% WCAG 2.1 AA compliance)
- [ ] Cross-reference ComponentTestApp and integration test suite
- [ ] Ensure all code examples are accurate and testable
- [ ] No broken links or references

### Integration Checklist Content
- [ ] Design token usage verification
- [ ] Component wrapper requirements
- [ ] Testing requirements (unit, snapshot, accessibility, integration)
- [ ] Platform compatibility verification (iOS 17+, macOS 14+, iPadOS 17+)
- [ ] Documentation requirements (DocC, inline comments)
- [ ] Build quality gates (SwiftLint 0 violations, compiler warnings)

### Migration Path Content
- [ ] Old UI pattern → FoundationUI component mapping table
- [ ] Step-by-step migration workflow
- [ ] Code examples: before/after for each component type
- [ ] Common pitfalls and solutions
- [ ] Rollback strategy if issues arise

### Quality Gates Content
- [ ] Phase 0: Setup & verification gates
- [ ] Phase 1: Foundation components gates
- [ ] Phase 2: Interactive components gates
- [ ] Phase 3: Layout patterns gates
- [ ] Phase 4: Platform adaptation gates
- [ ] Phase 5: Advanced features gates
- [ ] Phase 6: Full integration gates

### Accessibility Requirements Content
- [ ] WCAG 2.1 AA compliance checklist
- [ ] VoiceOver testing requirements
- [ ] Keyboard navigation requirements
- [ ] Dynamic Type support requirements
- [ ] Color contrast requirements (4.5:1 for normal text)
- [ ] Reduce Motion support
- [ ] High Contrast mode support

## 🔧 Implementation Notes

### Step 1: Read Current Design System Guide
**Action:** Review `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md` to understand current structure and identify integration points.

**Key sections to review:**
- Existing design principles
- Current component inventory
- Style guidelines
- Accessibility guidance (if present)

### Step 2: Add FoundationUI Integration Checklist
**Location:** New section after existing design principles

**Structure:**
```markdown
## FoundationUI Integration Checklist

Before integrating any FoundationUI component into ISOInspectorApp, ensure:

### 1. Design Token Usage ✅
- [ ] All spacing uses `DS.Spacing` tokens (never magic numbers)
- [ ] All colors use `DS.Colors` semantic tokens
- [ ] All typography uses `DS.Typography` tokens
- [ ] All animations use `DS.Animation.Timing` predefined curves
- [ ] No hardcoded platform-specific values

### 2. Component Wrapper Pattern ✅
- [ ] FoundationUI component wrapped with domain-specific semantics
- [ ] FoundationUI types not exposed in business logic layer
- [ ] Wrapper component documented with DocC
- [ ] Wrapper follows "One File — One Entity" principle

### 3. Testing Requirements ✅
- [ ] Unit tests cover all initialization paths (≥80% coverage target)
- [ ] Snapshot tests cover light/dark modes and all component states
- [ ] Accessibility tests verify VoiceOver labels and keyboard navigation
- [ ] Integration tests cover component composition patterns

### 4. Platform Compatibility ✅
- [ ] Component tested on iOS 17+ (iPhone SE, Pro, Pro Max)
- [ ] Component tested on macOS 14+ (multiple window sizes)
- [ ] Component tested on iPadOS 17+ (all size classes, orientations)
- [ ] Platform-specific adaptations use `@Environment(\.platformAdaptation)`

### 5. Accessibility Compliance ✅
- [ ] WCAG 2.1 AA compliance verified (≥98% score)
- [ ] VoiceOver labels clear and descriptive
- [ ] Keyboard navigation functional (Tab, Return, Escape)
- [ ] Dynamic Type support (all size categories XS-XXXL)
- [ ] Color contrast ≥4.5:1 for normal text, ≥3:1 for large text
- [ ] Reduce Motion setting respected
- [ ] High Contrast mode supported

### 6. Documentation ✅
- [ ] Component wrapper documented with DocC comments
- [ ] Usage examples added to ComponentTestApp showcase
- [ ] Migration notes documented (if replacing legacy component)
- [ ] Cross-references to integration patterns in Technical Spec

### 7. Build Quality Gates ✅
- [ ] SwiftLint: 0 violations
- [ ] Compiler: 0 warnings
- [ ] Tests: All passing
- [ ] Code coverage: ≥80%
- [ ] Accessibility audit: ≥98%
```

### Step 3: Document Migration Path
**Location:** New section "Migrating to FoundationUI"

**Content outline:**
1. **Component Mapping Table:**
   | Old Pattern | FoundationUI Component | Migration Priority |
   |-------------|----------------------|-------------------|
   | Manual badge styling | `DS.Badge` | Phase 1 (P1) |
   | Manual card containers | `DS.Card` | Phase 1 (P1) |
   | Manual key-value rows | `DS.KeyValueRow` | Phase 1 (P1) |
   | Manual copy buttons | `DS.Copyable` | Phase 2 (P2) |
   | Manual hover effects | `DS.InteractiveStyle` | Phase 2 (P2) |
   | Manual sidebar | `DS.SidebarPattern` | Phase 3 (P3) |
   | Manual inspector layout | `DS.InspectorPattern` | Phase 3 (P3) |
   | Manual tree view | `DS.BoxTreePattern` | Phase 3 (P3) |

2. **Migration Workflow:**
   - Step 1: Identify component to migrate
   - Step 2: Review FoundationUI component API
   - Step 3: Create domain-specific wrapper
   - Step 4: Write comprehensive tests
   - Step 5: Update UI to use wrapper
   - Step 6: Verify accessibility
   - Step 7: Archive old implementation

3. **Before/After Code Examples:**
   - Badge component migration
   - Card component migration
   - KeyValueRow migration

4. **Common Pitfalls:**
   - Mixing FoundationUI with legacy UI in same screen
   - Hardcoding spacing instead of using DS.Spacing tokens
   - Skipping accessibility tests
   - Not using platform adaptation contexts

### Step 4: Add Quality Gates Per Phase
**Location:** New section "Integration Phase Quality Gates"

**Content:** Quality criteria for each of the 6 integration phases from FoundationUI_Integration_Strategy.md

**Example gate structure:**
```markdown
### Phase 0: Setup & Verification Gates
**Before proceeding to Phase 1:**
- [ ] FoundationUI dependency builds successfully
- [ ] Integration test suite structure created
- [ ] ComponentTestApp runs without crashes
- [ ] Integration patterns documented
- [ ] Design System Guide updated

**Validation:**
- All Phase 0 tasks (I0.1-I0.5) marked complete
- Tests pass: 123 integration tests
- Code coverage ≥80%
- SwiftLint 0 violations
```

### Step 5: Document Accessibility Requirements
**Location:** Expand existing accessibility section or create new "Accessibility Requirements for FoundationUI Integration"

**Content:**
- WCAG 2.1 AA compliance checklist (detailed breakdown)
- VoiceOver testing guide (per-component)
- Keyboard navigation requirements
- Dynamic Type testing procedure
- Color contrast verification tools
- Reduce Motion implementation patterns
- High Contrast mode testing

### Step 6: Cross-Reference ComponentTestApp and Tests
**Action:** Add references to live examples and test suite throughout the guide

**Example cross-references:**
- "See `Examples/ComponentTestApp/Sources/Screens/BadgeShowcaseScreen.swift` for live examples"
- "Refer to `Tests/ISOInspectorAppTests/FoundationUI/BadgeComponentTests.swift` for test patterns"
- "Review `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md` for integration architecture"

### Step 7: Update next_tasks.md
**Action:** Mark I0.5 as completed and update Phase 1 readiness

## 🧠 Source References

- [`10_DESIGN_SYSTEM_GUIDE.md`](../AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md) — Current design system guide (to be updated)
- [`03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md) — Integration patterns (updated in I0.4)
- [`FoundationUI_Integration_Strategy.md`](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — 9-week phased roadmap
- [`Summary_of_Work.md` (I0.2)](../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/Summary_of_Work.md) — Integration test suite details
- [`Summary_of_Work.md` (I0.4)](../TASK_ARCHIVE/100_I0_4_Document_Integration_Patterns/Summary_of_Work.md) — Integration patterns documentation
- [`Examples/ComponentTestApp/README.md`](../../Examples/ComponentTestApp/README.md) — Component showcase guide
- [`Tests/ISOInspectorAppTests/FoundationUI/`](../../Tests/ISOInspectorAppTests/FoundationUI/) — 123 integration tests
- [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) — Task selection rules
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md) — Master PRD reference

---

**Created:** 2025-11-14
**Status:** In Progress
**Priority:** P0 (Phase 0 blocker for Phase 1 development)
**Effort:** 0.5 days
**Dependencies:** I0.1, I0.2, I0.3, I0.4 (all complete)
