# SYSTEM PROMPT: Add New FoundationUI Component or Feature

## 🧩 PURPOSE

Integrate a new component, modifier, pattern, or feature request into the FoundationUI documentation ecosystem, ensuring alignment with Composable Clarity Design System principles and the existing task plan.

---

## 🎯 GOAL

Transform an incoming feature request (from a simple idea to a detailed specification) into fully contextualized documentation updates:

- **Structured analysis** of the component/feature requirements
- **Layer assignment** (Tokens/Modifiers/Components/Patterns/Contexts)
- **Dependency identification** (which existing components it needs)
- **Task Plan integration** (add to appropriate phase and priority)
- **PRD updates** (document scope and success criteria)
- **Test Plan updates** (define testing strategy)

---

## 🔗 REFERENCE MATERIALS

### FoundationUI Documents
- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Master task list
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy

### Design System Rules
- [Composable Clarity PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#composable-clarity-design-system) — Layered architecture
- [Zero Magic Numbers Rule](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md#design-system-tokens) — All values must use DS tokens

### Project Rules
- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — Test-first workflow
- [07_AI_Code_Structure_Principles.md](../../../DOCS/RULES/07_AI_Code_Structure_Principles.md) — One entity per file

---

## ⚙️ EXECUTION STEPS

### Step 1. Analyze the Feature Request

Parse the incoming request and extract:

1. **Feature name** (e.g., "Tooltip component", "Hover effect modifier")
2. **Description** (what it does, why it's needed)
3. **Layer classification**:
   - **Layer 0**: New design token (spacing, color, font, etc.)
   - **Layer 1**: View modifier (styling, behavior enhancement)
   - **Layer 2**: Reusable component (UI building block)
   - **Layer 3**: UI pattern (composition of multiple components)
   - **Layer 4**: Context/environment (platform adaptation, theming)
4. **Dependencies**:
   - Which DS tokens does it need? (e.g., `DS.Colors.tooltipBG`)
   - Which modifiers does it use? (e.g., `.cardStyle()`)
   - Which components does it compose? (e.g., `Text`, `Image`)
5. **Platforms**: iOS, iPadOS, macOS, or all?
6. **Priority**: P0 (MVP critical), P1 (important), P2 (nice to have)

### Step 2. Research Existing Components

Search FoundationUI codebase to avoid duplication:

1. Check `Sources/FoundationUI/{Layer}/` directories
2. Search Task Plan for similar or overlapping tasks
3. Check `DOCS/TASK_ARCHIVE/` for previously completed work
4. Identify opportunities to:
   - **Reuse** existing components
   - **Extend** existing components with new variants
   - **Refactor** existing code to extract shared behavior

**Output**: Summary of existing components and how the new feature relates to them.

### Step 3. Define Component Specification

Create a detailed specification:

```markdown
# {FEATURE_NAME} Specification

## Overview
{1-2 sentence description}

## Layer Classification
- **Layer**: {0/1/2/3/4}
- **Type**: {Token/Modifier/Component/Pattern/Context}

## API Design

### Swift API
```swift
// Example usage
{code snippet showing how developers will use this feature}
```

### Design Tokens Used
- `DS.{Category}.{token}` — {description}
- ...

### Dependencies
- {List of required components/modifiers}

## Behavior Specification

### Variants
- {List of supported variants, e.g., "info, warning, error, success"}

### Platform Differences
- **iOS**: {iOS-specific behavior}
- **macOS**: {macOS-specific behavior}
- **iPadOS**: {iPad-specific behavior}

### Accessibility Requirements
- VoiceOver labels: {what should be announced}
- Contrast ratio: {≥4.5:1 for text, ≥3:1 for UI elements}
- Keyboard navigation: {how users navigate with keyboard}
- Dynamic Type: {must support text scaling}

## Testing Strategy

### Unit Tests
- {List of test cases for logic}

### Snapshot Tests
- Light/Dark mode rendering
- All variants
- Dynamic Type sizes (XS, M, XXL)

### Accessibility Tests
- Contrast ratio validation
- VoiceOver label verification

## Success Criteria
- [ ] Implementation uses DS tokens exclusively (zero magic numbers)
- [ ] All variants implemented and tested
- [ ] SwiftUI Preview included
- [ ] DocC documentation complete
- [ ] Accessibility requirements met
- [ ] Test coverage ≥80%
```

### Step 4. Identify Prerequisite Tasks

If the new feature depends on missing components:

1. List all missing dependencies (e.g., "requires `DS.Colors.tooltipBG` token")
2. Create prerequisite tasks for each dependency
3. Order tasks by layer (lower layers first)

**Example**: To add `Tooltip` component (Layer 2):
- Prerequisite 1: Add `DS.Colors.tooltipBG` token (Layer 0)
- Prerequisite 2: Add `DS.Animation.fadeIn` token (Layer 0)
- Prerequisite 3: Add `.tooltipStyle()` modifier (Layer 1)
- Main task: Implement `Tooltip` component (Layer 2)

### Step 5. Update Task Plan

Insert new tasks into [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md):

1. **Locate the correct phase**:
   - Phase 1 for Design Tokens
   - Phase 2 for Modifiers/Components
   - Phase 3 for Patterns/Contexts
   - Phase 4 for advanced features

2. **Add tasks in layer order**:
   ```markdown
   ### {Phase}.{Section} {Layer Name}
   **Progress: {current}/{total+new} tasks**

   - [ ] **{Priority}** {Task description}
     - File: `Sources/FoundationUI/{Layer}/{FileName}.swift`
     - {Additional details}
   ```

3. **Update progress counters**:
   - Increment total task count for the phase
   - Update percentage in Overall Progress Tracker

### Step 6. Update PRD

Add feature specification to [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md):

1. **Locate relevant section**:
   - Design Tokens → "Design System Tokens (DS)"
   - Modifiers → "View Modifiers (Layer 1)"
   - Components → "Reusable Components (Layer 2)"
   - Patterns → "UI Patterns (Layer 3)"

2. **Add entry**:
   ```markdown
   #### {ComponentName}
   **Layer**: {Layer number and name}
   **Priority**: {P0/P1/P2}

   {Description of component purpose and behavior}

   **API Example**:
   ```swift
   {Code example}
   ```

   **Success Criteria**:
   - {List of measurable requirements}
   ```

### Step 7. Update Test Plan

Add testing strategy to [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md):

```markdown
### {ComponentName} Testing

**Test Coverage Target**: ≥{80/85/90}%

#### Unit Tests
- {Test case 1}
- {Test case 2}

#### Snapshot Tests
- Light/Dark mode variants
- All {variant types}
- Dynamic Type sizes

#### Accessibility Tests
- VoiceOver navigation
- Contrast ratio ≥4.5:1
- Keyboard shortcuts
```

### Step 8. Create Next Tasks Entry

If the new feature is high priority, add to `next_tasks.md`:

```markdown
# Next Tasks

## High Priority

### {Feature Name} ({Layer Name})
- **Status**: Pending
- **Dependencies**: {List prerequisites}
- **Estimated effort**: {S/M/L/XL}
- **Why now**: {Rationale for prioritization}

**Subtasks**:
1. [ ] {Prerequisite task 1}
2. [ ] {Prerequisite task 2}
3. [ ] {Main implementation task}
```

### Step 9. Validate Integration

Before finalizing, verify:

- ✅ **Layer assignment is correct** (follows Composable Clarity hierarchy)
- ✅ **Dependencies are complete** (all required tokens/modifiers exist or are planned)
- ✅ **No duplication** (feature doesn't overlap with existing components)
- ✅ **Priority is justified** (P0 for MVP-critical, P1 for important, P2 for nice-to-have)
- ✅ **Testing strategy is defined** (unit/snapshot/accessibility tests planned)
- ✅ **Accessibility is considered** (VoiceOver, contrast, keyboard navigation)

### Step 10. Generate Summary Report

Create a summary document:

**File**: `FoundationUI/DOCS/INPROGRESS/NEW_{FeatureName}_Proposal.md`

```markdown
# New Feature Proposal: {Feature Name}

## Summary
{Brief description of the feature and why it's being added}

## Analysis Results

### Layer Classification
- **Layer**: {Layer number and name}
- **Priority**: {P0/P1/P2}

### Dependencies
{List of prerequisites}

### Existing Components Review
{Summary of related existing components}

## Documentation Updates

### Task Plan
- Added {N} tasks to Phase {X}
- Updated progress counters

### PRD
- Added specification to {PRD section}

### Test Plan
- Added testing strategy for {component name}

## Next Steps
1. {First action to take}
2. {Second action}
3. ...

## Open Questions
- {Any unresolved decisions or clarifications needed}

---
**Proposal Date**: {Current date}
**Status**: Ready for Implementation / Needs Review
```

---

## ✅ EXPECTED OUTPUT

- **Feature specification** with layer assignment, dependencies, and API design
- **Task Plan updated** with new tasks in correct phase and layer order
- **PRD updated** with component description and success criteria
- **Test Plan updated** with testing strategy
- **Proposal document** created in `DOCS/INPROGRESS/`
- **Summary report** with next steps and open questions

---

## 🧠 EXAMPLE: Adding a Tooltip Component

### Input
User request: "Add a tooltip component that appears on hover (macOS) or long press (iOS)"

### Step 1: Analyze Request
- **Feature name**: Tooltip
- **Layer**: 2 (Component)
- **Dependencies**: Needs `DS.Colors.tooltipBG`, `DS.Animation.fadeIn`, `.tooltipStyle()` modifier
- **Platforms**: iOS (long press), macOS (hover)
- **Priority**: P1 (important for UX, but not MVP-critical)

### Step 2: Research Existing
- Search results: No existing tooltip component
- Similar components: None
- Reuse opportunities: Can use existing `Text` and `Card` components

### Step 3: Define Specification
```swift
// API Design
Text("Username")
    .tooltip("Enter your username")

// Implementation will use:
// - DS.Colors.tooltipBG for background
// - DS.Spacing.s for padding
// - DS.Animation.fadeIn for appearance
```

### Step 4: Identify Prerequisites
1. Add `DS.Colors.tooltipBG` to `Colors.swift` (Layer 0)
2. Add `DS.Animation.fadeIn` to `Animation.swift` (Layer 0)
3. Add `.tooltipStyle()` modifier (Layer 1)
4. Implement `Tooltip` component (Layer 2)

### Step 5-7: Update Documentation
- **Task Plan**: Add 4 tasks to Phase 2
- **PRD**: Add Tooltip section to Components chapter
- **Test Plan**: Add tooltip testing strategy

### Step 8: Create Proposal
File: `FoundationUI/DOCS/INPROGRESS/NEW_Tooltip_Proposal.md`

### Step 9: Validate
- ✅ Layer 2 assignment correct
- ✅ All dependencies identified
- ✅ No duplication
- ✅ P1 priority justified
- ✅ Testing strategy defined
- ✅ Accessibility considered (keyboard trigger for macOS)

---

## 🧾 NOTES

- **Always classify by layer first** — this determines where tasks go in the plan
- **Check for duplication** — search existing code and archived tasks
- **Define prerequisites** — ensure lower layers are complete before higher layers
- **Justify priority** — P0 is for MVP-critical features only
- **Plan for testing** — every component needs unit, snapshot, and accessibility tests
- **Consider platforms** — iOS, iPadOS, and macOS may have different behaviors

---

## 🔄 INTEGRATION WITH WORKFLOW

After adding a new feature to the Task Plan, use:
- [SELECT_NEXT command](./SELECT_NEXT.md) to choose when to implement it
- [START command](./START.md) to begin implementation
- [ARCHIVE command](./ARCHIVE.md) to document completion

---

## END OF SYSTEM PROMPT

Ensure all Markdown formatting is consistent across documentation files.
