# SYSTEM PROMPT: Select Next FoundationUI Task

## 🧩 PURPOSE

Automatically determine and initialize the next task from the [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md), respecting the Composable Clarity layered architecture and task dependencies.

---

## 🎯 GOAL

Apply intelligent task selection rules to choose the next FoundationUI component or feature to implement, ensuring:

- **Layer dependencies are respected** (Tokens → Modifiers → Components → Patterns → Contexts)
- **Prerequisites are met** (e.g., Design Tokens exist before creating Modifiers)
- **High-priority tasks are addressed first** (P0 before P1 before P2)
- **Test coverage requirements are maintained** (tests written before implementation)

---

## 🔗 REFERENCE MATERIALS

### FoundationUI Documents
- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Master task list with phases and priorities
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements and scope
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy

### Project Rules
- [03_Next_Task_Selection.md](../../../DOCS/RULES/03_Next_Task_Selection.md) — General task selection criteria
- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — TDD workflow requirements

### Task Tracking
- [`FoundationUI/DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) — Manually noted upcoming tasks
- [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS) — Currently active tasks

---

## 📐 FOUNDATIONUI TASK SELECTION RULES

### Rule 1: Respect Layer Dependencies

The Composable Clarity architecture has strict layer ordering:

```
Layer 0: Design Tokens (DS)
   ↓ (Modifiers depend on Tokens)
Layer 1: View Modifiers
   ↓ (Components depend on Modifiers)
Layer 2: Components
   ↓ (Patterns depend on Components)
Layer 3: Patterns
   ↓ (Contexts enhance all layers)
Layer 4: Contexts
```

**Never select a task from a higher layer if lower layer dependencies are incomplete.**

Example:
- ❌ Cannot implement `Badge` component (Layer 2) without `BadgeChipStyle` modifier (Layer 1)
- ❌ Cannot implement `InspectorPattern` (Layer 3) without `Card` component (Layer 2)
- ✅ Can implement `CardStyle` modifier (Layer 1) if `DS.Radius` and `DS.Spacing` exist (Layer 0)

### Rule 2: Priority Levels (P0 > P1 > P2)

Tasks are marked with priority:
- **P0** = Critical for MVP, must be completed
- **P1** = Important for quality, should be completed
- **P2** = Nice to have, can be deferred

**Always select P0 tasks before P1, and P1 before P2**, within the same layer.

### Rule 3: Phase Progression

Phases must be completed in order:

1. **Phase 1: Foundation** (Layer 0 - Design Tokens)
2. **Phase 2: Core Components** (Layers 1-2 - Modifiers & Components)
3. **Phase 3: Patterns & Platform Adaptation** (Layers 3-4)
4. **Phase 4: Agent Support & Polish**
5. **Phase 5: Documentation & QA**
6. **Phase 6: Integration & Validation**

**Do not start Phase 3 until Phase 2 is complete.**

### Rule 4: Test-First Requirement

For every implementation task, a corresponding test task must be selected or created first.

Example sequence:
1. Select "Write BadgeChipStyle unit tests"
2. Write failing tests
3. Select "Implement BadgeChipStyle modifier"
4. Implement code to pass tests

### Rule 5: Platform Coverage

Tasks marked with platform-specific requirements (iOS/macOS/iPadOS) must be completed for **all supported platforms** before marking as done.

---

## ⚙️ EXECUTION STEPS

### Step 1. Scan Current Progress

1. Open [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
2. Locate the **Overall Progress Tracker** table
3. Identify the current active phase (first phase with incomplete tasks)
4. Note any tasks marked with `[x]` (completed) vs `[ ]` (pending)

### Step 2. Check INPROGRESS Folder

1. List files in [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS)
2. If tasks are actively being worked on, do not select new tasks
3. If `next_tasks.md` exists, read it for manually prioritized items

### Step 3. Apply Selection Algorithm

```
FOR each phase in [1, 2, 3, 4, 5, 6]:
    IF phase is not 100% complete:
        FOR each priority in [P0, P1, P2]:
            FOR each layer in [0, 1, 2, 3, 4]:
                SELECT first incomplete task WHERE:
                    - priority == current priority
                    - layer == current layer
                    - all lower layer dependencies are satisfied
                    - no blocking tasks in INPROGRESS
                IF task found:
                    RETURN task
```

### Step 4. Verify Prerequisites

Before finalizing task selection, check:

- **Code dependencies exist**: Required DS tokens, modifiers, or components are implemented
- **Test infrastructure is ready**: `Tests/` directory, XCTest framework configured
- **Build system is functional**: `swift build` succeeds
- **SwiftLint is configured**: `.swiftlint.yml` exists

If prerequisites are missing, select the prerequisite task instead.

### Step 5. Create Task Document

Once a task is selected, create a detailed task file:

**File location**: `FoundationUI/DOCS/INPROGRESS/{Phase}_{TaskName}.md`

**Example**: `FoundationUI/DOCS/INPROGRESS/Phase2_BadgeChipStyle.md`

**Content template**:

```markdown
# {TASK_NAME}

## 🎯 Objective
{Short description of what needs to be achieved}

## 🧩 Context
- **Phase**: {Phase number and name}
- **Layer**: {Layer number and name}
- **Priority**: {P0/P1/P2}
- **Dependencies**: {List of prerequisite tasks}

## ✅ Success Criteria
- [ ] Unit tests written and passing
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Preview included
- [ ] DocC documentation complete
- [ ] Accessibility labels added
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Notes
{Key hints from the Task Plan or PRD}

### Files to Create/Modify
- `Sources/FoundationUI/{Layer}/{ComponentName}.swift`
- `Tests/FoundationUITests/{Layer}Tests/{ComponentName}Tests.swift`

### Design Token Usage
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}`
- Radius: `DS.Radius.{card|chip|small}`
- Animation: `DS.Animation.{quick|medium}`

## 🧠 Source References
- [FoundationUI Task Plan § {Phase}.{Section}](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § {Section}](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

## 📋 Checklist
- [ ] Read task requirements from Task Plan
- [ ] Create test file and write failing tests
- [ ] Run `swift test` to confirm failure
- [ ] Implement minimal code using DS tokens
- [ ] Run `swift test` to confirm pass
- [ ] Add SwiftUI Preview
- [ ] Add DocC comments
- [ ] Run `swiftlint` (0 violations)
- [ ] Test on iOS simulator
- [ ] Test on macOS
- [ ] Update Task Plan with [x] completion mark
- [ ] Commit with descriptive message
```

### Step 6. Update Task Plan Status

Mark the selected task as **In Progress** in the Task Plan:

```markdown
- [ ] **P0** Implement BadgeChipStyle modifier → IN PROGRESS
```

### Step 7. Report Selection

Output a summary:

```
✅ Selected Next Task:
  Phase: 2.1 Layer 1: View Modifiers
  Task: Implement BadgeChipStyle modifier
  Priority: P0
  File: FoundationUI/DOCS/INPROGRESS/Phase2_BadgeChipStyle.md

Dependencies satisfied:
  ✅ DS.Colors tokens exist
  ✅ DS.Spacing tokens exist
  ✅ DS.Radius tokens exist
  ✅ Test infrastructure ready

Next steps:
  1. Create Tests/FoundationUITests/ModifiersTests/BadgeChipStyleTests.swift
  2. Write failing unit tests
  3. Implement Sources/FoundationUI/Modifiers/BadgeChipStyle.swift
  4. Run tests and iterate until green
```

---

## ✅ EXPECTED OUTPUT

- **One task selected** based on priority, layer dependencies, and phase progression
- **Task document created** in `DOCS/INPROGRESS/{Phase}_{TaskName}.md`
- **Task Plan updated** to show "IN PROGRESS" status
- **Prerequisites verified** before selection finalized
- **Summary report** with next steps

---

## 🧠 EXAMPLE: Phase 2 Selection

**Scenario**: Phase 1 (Design Tokens) is 100% complete. Selecting first Phase 2 task.

**Algorithm execution**:

1. Phase 2 is active (0/22 tasks completed)
2. Check P0 tasks in Layer 1 (View Modifiers):
   - `[ ] Implement BadgeChipStyle modifier` — SELECTED ✅
   - Dependencies: Requires `DS.Colors`, `DS.Spacing`, `DS.Radius` (all exist in Phase 1)
3. Create `FoundationUI/DOCS/INPROGRESS/Phase2_BadgeChipStyle.md`
4. Update Task Plan:
   ```markdown
   ### 2.1 Layer 1: View Modifiers (Atoms)
   **Progress: 0/6 tasks → IN PROGRESS**

   - [ ] **P0** Implement BadgeChipStyle modifier → **IN PROGRESS**
   ```

---

## 🧾 NOTES

- **Layer dependencies are strict**: Never skip layers or implement out of order.
- **Priority is secondary to layers**: A P1 task in Layer 1 comes before a P0 task in Layer 2.
- **Test-first is non-negotiable**: Always select test tasks before implementation tasks.
- **Platform coverage is required**: Don't mark tasks complete until all platforms are verified.
- **Manual overrides allowed**: If `next_tasks.md` exists, prioritize those items first.

---

## 🔄 INTEGRATION WITH WORKFLOW

After selecting a task, use the [START command](./START.md) to begin implementation following the TDD workflow.

When the task is complete, use the [ARCHIVE command](./ARCHIVE.md) to move it to the task archive.

---

## END OF SYSTEM PROMPT

Ensure all Markdown formatting is consistent across documentation files.
