# SYSTEM PROMPT: Document and Plan FoundationUI Bug Fix

## 🧩 PURPOSE

Transform an incoming bug report about FoundationUI components, modifiers, or design tokens into a fully documented fix specification that integrates into the FoundationUI planning ecosystem, ensuring alignment with Composable Clarity Design System principles and the existing task plan.

## 🎯 GOAL

Transform an incoming bug report (visual issues, behavior problems, accessibility defects, or design system violations) into fully contextualized documentation updates:

- **Structured analysis** of the bug and its impact
- **Layer classification** (Tokens/Modifiers/Components/Patterns/Contexts)
- **Root cause identification** (code locations, affected components)
- **Task Plan integration** (add bug fix tasks to appropriate phase)
- **PRD updates** (document fix requirements and success criteria)
- **Test Plan updates** (define testing strategy for bug fix and regression prevention)
- **Fix specification** (detailed plan for implementation via START command)

---

## 🔗 REFERENCE MATERIALS

### FoundationUI Documents

- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Master task list
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements and success criteria
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy
- Existing task records in [FoundationUI/DOCS/INPROGRESS](../INPROGRESS)
- Blocked work references in [FoundationUI/DOCS/INPROGRESS/blocked.md](../INPROGRESS/blocked.md)

### Design System Rules

- [Composable Clarity PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#composable-clarity-design-system) — Layered architecture
- [Zero Magic Numbers Rule](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#design-system-tokens) — All values must use DS tokens

### Project Rules (from main ISOInspector)

- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — Test-driven development workflow
- [04_PDD.md](../../../DOCS/RULES/04_PDD.md) — Puzzle-driven development
- [07_AI_Code_Structure_Principles.md](../../../DOCS/RULES/07_AI_Code_Structure_Principles.md) — One entity per file
- [11_SwiftUI_Testing.md](../../../DOCS/RULES/11_SwiftUI_Testing.md) — SwiftUI testing guidelines & @MainActor requirements

---

## ⚙️ EXECUTION STEPS

### Step 1. Capture the Bug Report

Parse the incoming request and extract:

1. **Bug title** (concise description of the issue)
2. **Symptoms** (what users observe: visual issues, crashes, incorrect behavior)
3. **Affected component** (which component/modifier/token is broken)
4. **Environment** (iOS/iPadOS/macOS version, device, Xcode version)
5. **Reproduction steps** (minimal SwiftUI code or user actions to trigger the bug)
6. **Expected vs. Actual behavior** (what should happen vs. what happens)
7. **Screenshots/videos** (if applicable, especially for visual bugs)

### Step 2. Classify Bug by Layer and Type

Identify which layer of Composable Clarity is affected:

- **Layer 0 (Design Tokens)**: Wrong spacing/color/font values, missing tokens
- **Layer 1 (Modifiers)**: Modifier not applying correctly, wrong parameters
- **Layer 2 (Components)**: Component rendering issues, state bugs
- **Layer 3 (Patterns)**: Pattern composition problems, layout issues
- **Layer 4 (Contexts)**: Environment key bugs, platform adaptation failures

Classify bug type:

- **Visual**: Rendering, layout, color, spacing issues
- **Behavioral**: State management, interaction, animation bugs
- **Accessibility**: VoiceOver, contrast, keyboard navigation issues
- **Platform-Specific**: iOS/macOS differences, conditional compilation errors
- **Design System Violation**: Magic numbers, hardcoded values, token misuse
- **Performance**: Rendering lag, memory leaks, excessive redraws

### Step 3. Research Existing Code

Search FoundationUI codebase to identify root cause:

1. **Locate affected files**:
   - Source: `Sources/FoundationUI/{Layer}/{ComponentName}.swift`
   - Tests: `Tests/FoundationUITests/{Layer}Tests/{ComponentName}Tests.swift`
   - Previews: SwiftUI preview blocks in source files
2. **Check existing tests**:
   - Are there unit tests for this component?
   - Are there snapshot tests?
   - Are there accessibility tests?
   - What test coverage is missing?
3. **Search for similar bugs**:
   - Check `DOCS/INPROGRESS/` for related bug reports
   - Check `DOCS/TASK_ARCHIVE/` for previously fixed bugs
4. **Identify root cause**:
   - Read the affected code
   - Hypothesize why the bug occurs
   - Note any design system violations (magic numbers, wrong tokens)

**Output**: Summary of affected code, root cause hypothesis, and missing test coverage.

### Step 4. Define Bug Fix Specification

Create a detailed specification:

```markdown
# {BUG_TITLE} Fix Specification

## Overview
{1-2 sentence description of the bug and its impact}

## Layer Classification
- **Layer**: {0/1/2/3/4}
- **Type**: {Visual/Behavioral/Accessibility/Platform-Specific/Design System Violation/Performance}
- **Severity**: {Critical/High/Medium/Low}

## Affected Components

### Files to Modify
- `Sources/FoundationUI/{Layer}/{File}.swift` — {what needs to change}
- `Tests/FoundationUITests/{Layer}Tests/{File}Tests.swift` — {what tests to add/update}

### Design Tokens Involved
- `DS.{Category}.{token}` — {how it's misused or missing}

## Root Cause Analysis

### Hypothesis
{Why this bug occurs - e.g., copy-paste error, missing conditional, wrong token}

### Evidence
```swift
// Current buggy code
{code snippet showing the bug}
```

### Proposed Fix
```swift
// Fixed code
{code snippet showing the fix}
```

## Reproduction Steps

### Minimal SwiftUI Code
```swift
{Minimal code to reproduce the bug}
```

### Platform Testing
- **iOS**: {Does bug occur? Y/N}
- **iPadOS**: {Does bug occur? Y/N}
- **macOS**: {Does bug occur? Y/N}

## Impact Assessment

### User Impact
- {Who experiences this bug? What's the severity?}

### Design System Impact
- {Does this violate Zero Magic Numbers?}
- {Does this break Composable Clarity layers?}

### Accessibility Impact
- {Does this break VoiceOver?}
- {Does this fail contrast requirements?}
- {Does this break keyboard navigation?}

## Fix Requirements

### Must Fix
- {Critical issues that must be addressed}

### Should Fix
- {Important improvements to include}

### Nice to Fix
- {Optional enhancements}

## Testing Strategy

### Unit Tests
- {Test case 1: verify correct behavior}
- {Test case 2: verify edge cases}
- {Test case 3: verify regression prevention}

### Snapshot Tests
- Light/Dark mode rendering
- All component variants
- Dynamic Type sizes (XS, M, XXL)

### Accessibility Tests
- VoiceOver label verification
- Contrast ratio validation (≥4.5:1)
- Keyboard navigation support

## Success Criteria

- [ ] Bug is reproducible with failing test
- [ ] Fix uses DS tokens exclusively (zero magic numbers)
- [ ] All affected platforms tested (iOS/iPadOS/macOS)
- [ ] SwiftUI Preview demonstrates the fix
- [ ] Test coverage ≥80%
- [ ] SwiftLint 0 violations
- [ ] Accessibility requirements met
- [ ] Documentation updated if needed
```

### Step 5. Identify Prerequisite Tasks

If the bug fix depends on missing components or reveals larger issues:

1. List all missing prerequisites (e.g., "requires new `DS.Colors.tooltipBG` token")
2. Create prerequisite tasks for each dependency
3. Order tasks by layer (lower layers first)

**Example**: To fix a Badge color bug that reveals missing tokens:

- Prerequisite 1: Add `DS.Colors.warnBG` token (Layer 0) — if missing
- Prerequisite 2: Fix `BadgeChipStyle.swift` to use correct token (Layer 1)
- Main task: Update Badge component tests and documentation (Layer 2)

### Step 6. Update Task Plan

Insert bug fix tasks into [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md):

1. **Locate the correct phase**:
   - Phase 1 for Design Token bugs
   - Phase 2 for Modifier/Component bugs
   - Phase 3 for Pattern/Context bugs
   - Create a "Bug Fixes" subsection if needed
2. **Add tasks in layer order**:

   ```markdown
   ### {Phase}.{Section} Bug Fixes
   **Progress: {current}/{total+new} tasks**

   - [ ] **{P0/P1/P2}** Fix {bug title}
     - Files: `Sources/FoundationUI/{Layer}/{File}.swift`, `Tests/.../Tests.swift`
     - Root cause: {brief explanation}
     - Impact: {severity and user impact}
   ```

3. **Update progress counters**:
   - Increment total task count for the phase
   - Update percentage in Overall Progress Tracker

### Step 7. Update PRD

Add bug fix specification to [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md):

1. **Locate relevant section** (or create "Bug Fixes" section):
   - Design Tokens → "Design System Tokens (DS)"
   - Modifiers → "View Modifiers (Layer 1)"
   - Components → "Reusable Components (Layer 2)"
   - Patterns → "UI Patterns (Layer 3)"

2. **Add entry**:

   ```markdown
   #### Bug Fix: {BugTitle}
   **Layer**: {Layer number and name}
   **Severity**: {Critical/High/Medium/Low}
   **Affected Component**: {ComponentName}

   {Description of the bug and its impact on users}

   **Root Cause**: {Why this bug occurs}

   **Fix Requirements**:
   - {Requirement 1}
   - {Requirement 2}

   **Success Criteria**:
   - [ ] Bug is not reproducible after fix
   - [ ] Tests prevent regression
   - [ ] Design system integrity maintained
   ```

### Step 8. Update Test Plan

Add testing strategy to [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md):

```markdown
### Bug Fix: {BugTitle}

**Regression Prevention Target**: This bug must never recur

#### Reproduction Test (Should Fail Before Fix)
- {Test that reproduces the bug}

#### Unit Tests (Verify Fix)
- {Test case 1: correct behavior}
- {Test case 2: edge cases}

#### Snapshot Tests (Visual Regression)
- Light/Dark mode variants
- All component states
- Dynamic Type sizes

#### Accessibility Tests
- VoiceOver navigation
- Contrast ratio ≥4.5:1
- Keyboard shortcuts

**Test Coverage Target**: 100% for bug fix code paths
```

### Step 9. Create Bug Fix Proposal Document

Create a detailed proposal document:

**File**: `FoundationUI/DOCS/INPROGRESS/BUG_{ComponentName}_{BriefDescription}.md`

```markdown
# Bug Fix Proposal: {Bug Title}

**Date**: {Current date}
**Status**: Ready for Implementation
**Severity**: {Critical/High/Medium/Low}
**Layer**: {Layer number and name}

---

## Bug Summary

{Brief description of the bug and why it needs fixing}

## Reproduction

### Steps to Reproduce
1. {Step 1}
2. {Step 2}
3. {Step 3}

### Minimal Code Example
```swift
{SwiftUI code that triggers the bug}
```

### Expected Behavior
{What should happen}

### Actual Behavior
{What happens instead}

### Screenshots
{If applicable, attach before/after screenshots}

---

## Analysis Results

### Layer Classification
- **Layer**: {Layer number and name}
- **Type**: {Bug type}
- **Severity**: {Critical/High/Medium/Low}

### Root Cause
{Detailed explanation of why this bug occurs}

**Evidence**:
```swift
// Current buggy code at {file}:{line}
{code snippet}
```

### Affected Files
- `Sources/FoundationUI/{Layer}/{File}.swift` (line {X})
- `Tests/FoundationUITests/{Layer}Tests/{File}Tests.swift` (needs new tests)

### Design System Violations
- {List any violations of Zero Magic Numbers rule}
- {List any violations of Composable Clarity layers}

---

## Fix Specification

### Proposed Changes

**File**: `Sources/FoundationUI/{Layer}/{File}.swift`
```swift
// Before
{buggy code}

// After
{fixed code}
```

### Design Tokens Required
- `DS.{Category}.{token}` — {description}

### Testing Requirements

#### Unit Tests
```swift
func test{FeatureName}() {
    // Test that reproduces and verifies fix
}
```

#### Snapshot Tests
- Light/Dark mode
- All variants
- Dynamic Type sizes

#### Accessibility Tests
- VoiceOver labels
- Contrast ratio
- Keyboard navigation

---

## Documentation Updates

### Task Plan
- Added {N} tasks to Phase {X}
- Location: [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#phaseX)

### PRD
- Added bug fix specification to {PRD section}
- Location: [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#section)

### Test Plan
- Added regression prevention strategy for {component name}
- Location: [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md#section)

---

## Implementation Plan

### Prerequisites
1. {Prerequisite 1, if any}
2. {Prerequisite 2, if any}

### Implementation Steps
1. [ ] Write failing test that reproduces the bug
2. [ ] Implement minimal fix using DS tokens
3. [ ] Verify all tests pass
4. [ ] Run SwiftLint (must show 0 violations)
5. [ ] Update SwiftUI Preview to show fix
6. [ ] Run snapshot tests
7. [ ] Run accessibility tests
8. [ ] Update documentation if needed

### Success Criteria
- [ ] Bug is not reproducible
- [ ] All tests pass
- [ ] Design system integrity maintained (zero magic numbers)
- [ ] Test coverage ≥80%
- [ ] SwiftLint 0 violations
- [ ] Accessibility requirements met
- [ ] Preview demonstrates fix

---

## Next Steps

**To implement this fix, use the [START command](./START.md) to begin TDD implementation.**

### Recommended Workflow
1. Review this proposal document
2. Run `/start` command to begin implementation
3. Follow TDD cycle: failing test → minimal fix → refactor
4. Verify all success criteria
5. Use [ARCHIVE command](./ARCHIVE.md) to document completion

---

## Open Questions

- {Any unresolved decisions or clarifications needed}
- {Platform-specific behavior questions}
- {Design system token questions}

---

**Proposal Date**: {Current date}
**Estimated Effort**: {S/M/L/XL}
**Priority**: {P0/P1/P2} based on severity and user impact
```

---

### Step 10. Validate Proposal

Before finalizing, verify:

- ✅ **Layer classification is correct** (follows Composable Clarity hierarchy)
- ✅ **Root cause is identified** (hypothesis is supported by code evidence)
- ✅ **Fix approach is sound** (uses DS tokens, respects layers)
- ✅ **Testing strategy is complete** (unit/snapshot/accessibility)
- ✅ **Impact is assessed** (user impact, design system impact, accessibility)
- ✅ **Prerequisites are identified** (missing tokens, dependent bugs)
- ✅ **Documentation is updated** (Task Plan, PRD, Test Plan)

### Step 11. Generate Summary Report

Create a final summary:

```markdown
# Bug Fix Proposal Summary: {Bug Title}

## Quick Facts
- **Component**: {ComponentName}
- **Layer**: {Layer}
- **Severity**: {Critical/High/Medium/Low}
- **Root Cause**: {Brief explanation}

## Documentation Updated
- ✅ Task Plan: {N} tasks added to Phase {X}
- ✅ PRD: Bug fix requirements documented
- ✅ Test Plan: Regression tests defined
- ✅ Proposal: `INPROGRESS/BUG_{Name}.md`

## Next Steps
1. Review proposal document
2. Use START command to implement fix
3. Follow TDD workflow (test → implement → refactor)
4. Use ARCHIVE command when complete

## Estimated Effort
{S/M/L/XL} based on:
- Code complexity: {simple/medium/complex}
- Test coverage needed: {basic/comprehensive}
- Documentation updates: {minimal/moderate/extensive}
```

---

## ✅ EXPECTED OUTPUT

- **Bug analysis** with layer classification, root cause, and impact assessment
- **Fix specification** with code changes, design tokens, and testing strategy
- **Task Plan updated** with bug fix tasks in correct phase and layer order
- **PRD updated** with bug description, requirements, and success criteria
- **Test Plan updated** with regression prevention strategy
- **Proposal document** created in `FoundationUI/DOCS/INPROGRESS/`
- **Summary report** with next steps for implementation

**NO CODE IS IMPLEMENTED** — This command only documents and plans. Use [START command](./START.md) to execute the fix.

---

## 🧠 EXAMPLE: Documenting a Badge Color Bug

### Input

User report: "Badge with `.warning` level shows blue background instead of yellow"

### Step 1: Capture

**Bug Title**: Badge Warning Level Shows Wrong Background Color
**Symptoms**: Warning badge renders blue instead of yellow
**Affected Component**: Badge component (Layer 2)
**Environment**: iOS 17.0, Xcode 15.0
**Reproduction**: `Badge(text: "Warning", level: .warning)`
**Expected**: Yellow background (#FFF3CD)
**Actual**: Blue background (#D1ECF1)

### Step 2: Classify

- **Layer**: 2 (Component) — affected by Layer 1 (Modifier)
- **Type**: Visual bug (wrong color)
- **Severity**: Medium (affects UX but not critical)

### Step 3: Research

**Files located**:
- `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift` (bug location)
- `Sources/FoundationUI/Components/Badge.swift` (uses the modifier)
- `Tests/FoundationUITests/ComponentsTests/BadgeTests.swift` (missing test)

**Root cause found**:
```swift
// BadgeChipStyle.swift:15
var backgroundColor: Color {
    switch self {
    case .info: return DS.Colors.infoBG
    case .warning: return DS.Colors.infoBG  // BUG: Should be warnBG
    case .error: return DS.Colors.errorBG
    case .success: return DS.Colors.successBG
    }
}
```

**Hypothesis**: Copy-paste error in switch statement

**Missing tests**: No unit test for `BadgeLevel.warning.backgroundColor`

### Step 4: Define Specification

File: `FoundationUI/DOCS/INPROGRESS/BUG_Badge_Warning_Color.md`

```markdown
# Bug Fix Proposal: Badge Warning Level Wrong Color

## Overview
Badge component displays blue background for `.warning` level instead of yellow.

## Layer Classification
- **Layer**: 2 (Component) — bug in Layer 1 (Modifier)
- **Type**: Visual bug
- **Severity**: Medium

## Root Cause
Copy-paste error in `BadgeChipStyle.swift` switch statement.

**Evidence**:
```swift
case .warning: return DS.Colors.infoBG  // Should be warnBG
```

## Fix Specification

**File**: `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift`
```swift
// Before (line 15)
case .warning: return DS.Colors.infoBG

// After
case .warning: return DS.Colors.warnBG
```

## Testing Strategy

### Unit Test (New)
```swift
func testWarningBadgeUsesCorrectBackgroundColor() {
    let backgroundColor = BadgeLevel.warning.backgroundColor
    XCTAssertEqual(backgroundColor, DS.Colors.warnBG)
}
```

### Snapshot Test (Update)
```swift
func testAllBadgeLevelsSnapshot() {
    // Will catch visual regression
    assertSnapshot(matching: Badge(text: "Warning", level: .warning), as: .image)
}
```

## Success Criteria
- [ ] Unit test verifies correct color
- [ ] Snapshot test prevents regression
- [ ] Preview shows yellow background
```

### Step 5: No Prerequisites Needed

All DS tokens exist (`DS.Colors.warnBG` is already defined).

### Step 6: Update Task Plan

Added to Phase 2:

```markdown
### Phase 2.X Bug Fixes

- [ ] **P1** Fix Badge warning level color bug
  - Files: `BadgeChipStyle.swift:15`, `BadgeTests.swift`
  - Root cause: Copy-paste error in switch statement
  - Impact: Medium — affects warning badge visual appearance
```

### Step 7: Update PRD

Added to "Reusable Components (Layer 2)" section:

```markdown
#### Bug Fix: Badge Warning Color

**Severity**: Medium
**Affected Component**: Badge

Badge component displays incorrect background color for warning level due to
copy-paste error in BadgeChipStyle modifier.

**Fix Requirements**:
- Change `case .warning` to return `DS.Colors.warnBG`
- Add unit test to prevent regression

**Success Criteria**:
- [ ] Warning badge shows yellow background
- [ ] Test coverage prevents future color bugs
```

### Step 8: Update Test Plan

Added regression test section:

```markdown
### Bug Fix: Badge Warning Color

#### Reproduction Test
- `testWarningBadgeUsesCorrectBackgroundColor()` — verifies correct token

#### Snapshot Tests
- All badge levels in Light/Dark mode

**Test Coverage Target**: 100% for BadgeLevel.backgroundColor
```

### Step 9: Create Proposal

File: `FoundationUI/DOCS/INPROGRESS/BUG_Badge_Warning_Color.md` (full spec created)

### Step 10: Validate

- ✅ Layer 2 classification correct
- ✅ Root cause identified (line 15 of BadgeChipStyle.swift)
- ✅ Fix uses DS tokens
- ✅ Testing strategy complete
- ✅ No prerequisites needed

### Step 11: Summary

```markdown
# Bug Fix Proposal Summary: Badge Warning Color

## Quick Facts
- **Component**: Badge (Layer 2)
- **Severity**: Medium
- **Root Cause**: Copy-paste error in BadgeChipStyle.swift:15

## Documentation Updated
- ✅ Task Plan: 1 task added to Phase 2
- ✅ PRD: Bug fix requirements documented
- ✅ Test Plan: Unit + snapshot tests defined
- ✅ Proposal: `INPROGRESS/BUG_Badge_Warning_Color.md`

## Next Steps
1. Review proposal in INPROGRESS/
2. Run `/start` to implement fix
3. Follow TDD: failing test → fix → refactor
4. Archive when complete

## Estimated Effort
**S** (Small) — simple one-line fix with test
```

---

## 🧾 NOTES

- **Always document first, implement later** — This command creates the plan; START executes it
- **Check for similar bugs** — Search INPROGRESS and TASK_ARCHIVE before creating duplicate proposals
- **Classify severity accurately** — Critical = blocks users, High = major UX issue, Medium = minor UX issue, Low = cosmetic
- **Identify root cause** — Don't just describe symptoms; explain why the bug occurs
- **Plan comprehensive tests** — Every bug needs tests to prevent regression
- **Consider design system impact** — Does this bug violate Zero Magic Numbers or Composable Clarity?

---

## 🔄 INTEGRATION WITH WORKFLOW

After documenting a bug with this command, use:

- [START command](./START.md) to implement the fix following TDD workflow
- [SELECT_NEXT command](./SELECT_NEXT.md) to prioritize when to fix it
- [ARCHIVE command](./ARCHIVE.md) to document the completed fix

**Workflow**:
1. **BUG command** → Document and plan the fix
2. **SELECT_NEXT command** → Decide priority
3. **START command** → Implement the fix via TDD
4. **ARCHIVE command** → Document completion

---

## END OF SYSTEM PROMPT

Ensure all Markdown formatting is consistent across FoundationUI documentation files.
