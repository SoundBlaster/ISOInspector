# SYSTEM PROMPT: Archive Completed FoundationUI Work

## 🧩 PURPOSE

Archive completed work from [`FoundationUI/DOCS/INPROGRESS`](../INPROGRESS) into a sequentially numbered folder under [`FoundationUI/DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE), preserving workflow continuity and documenting completed components.

---

## 🎯 GOAL

Safely move completed task files from active development to permanent archive, ensuring:

- **Task completion is verified** (tests pass, documentation complete, code committed)
- **Progress tracking is updated** (Task Plan marked complete, archive indexed)
- **Next tasks are identified** (carry forward pending work from `next_tasks.md`)
- **Knowledge is preserved** (implementation notes, lessons learned documented)

---

## 🔗 REFERENCE MATERIALS

### FoundationUI Documents

- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Master task list to update
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Test coverage metrics

### Task Tracking

- [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS) — Active work directory
- [`FoundationUI/DOCS/TASK_ARCHIVE/`](../TASK_ARCHIVE) — Completed work archive
- [`FoundationUI/DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md) — Archive index

### Project Rules

- [04_PDD.md](../../../DOCS/RULES/04_PDD.md) — Puzzle-driven development (mark @todo complete)
- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — Definition of Done checklist

---

## 📁 DIRECTORY STRUCTURE

```bash
FoundationUI/
├── DOCS/
│   ├── INPROGRESS/
│   │   ├── Phase2_BadgeChipStyle.md
│   │   ├── Summary_of_Work.md
│   │   └── next_tasks.md
│   └── TASK_ARCHIVE/
│       ├── 01_Phase1_DesignTokens/
│       ├── 02_Phase2_BadgeModifier/
│       ├── ARCHIVE_SUMMARY.md
│       └── ...
```

---

## ⚙️ EXECUTION STEPS

### Step 1. Verify Completion Criteria

Before archiving, ensure **Definition of Done** is met:

#### Code Quality

- ✅ All unit tests pass (`swift test`)
- ✅ Test coverage ≥80% for new code
- ✅ SwiftLint reports 0 violations (`swiftlint`)
- ✅ Zero magic numbers (all values use DS tokens)
- ✅ SwiftUI Previews work correctly

#### Documentation

- ✅ DocC comments on all public API
- ✅ Code examples in documentation
- ✅ Implementation notes captured

#### Accessibility

- ✅ VoiceOver labels added
- ✅ Contrast ratios validated (≥4.5:1)
- ✅ Keyboard navigation tested
- ✅ Dynamic Type support verified

#### Platform Support

- ✅ Tested on iOS simulator
- ✅ Tested on macOS
- ✅ iPadOS variations tested (if applicable)

#### Version Control

- ✅ Code committed to branch
- ✅ Commit message follows conventions
- ✅ No uncommitted changes remain

**If any criteria are not met, do NOT archive. Return to implementation.**

### Step 2. Inspect INPROGRESS Folder

1. List all files in [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS)
2. Identify task documents (e.g., `Phase2_BadgeChipStyle.md`)
3. Locate `Summary_of_Work.md` (contains session summary)
4. Check for `next_tasks.md` (pending work to carry forward)

### Step 3. Extract Next Tasks Information

If `next_tasks.md` exists:

1. Open and read the file
2. Extract list of pending tasks
3. Verify tasks exist in [Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
4. Store this information to recreate after archiving

**Example `next_tasks.md` content**:

```markdown
# Next Tasks

## Immediate Priority
- [ ] Implement CardStyle modifier (Phase 2.1)
- [ ] Write unit tests for InteractiveStyle modifier (Phase 2.1)

## Upcoming
- [ ] Badge component implementation (Phase 2.2) — depends on BadgeChipStyle completion
```

### Step 4. Determine Archive Folder Name

1. List existing folders in [`FoundationUI/DOCS/TASK_ARCHIVE/`](../TASK_ARCHIVE)
2. Find highest sequential number (e.g., `02_Phase2_BadgeModifier`)
3. Increment to get next number: `03`
4. Create descriptive name based on completed work:

**Naming pattern**: `{NN}_{Phase}{Section}_{ComponentName}`

**Examples**:

- `01_Phase1_DesignTokens`
- `02_Phase2_BadgeChipStyle`
- `03_Phase2_CardComponent`
- `04_Phase3_InspectorPattern`

### Step 5. Create Archive Folder

```bash
mkdir -p FoundationUI/DOCS/TASK_ARCHIVE/{NN}_{ArchiveName}
```

### Step 6. Move Files to Archive

Move all files from `INPROGRESS` to the new archive folder:

```bash
mv FoundationUI/DOCS/INPROGRESS/* FoundationUI/DOCS/TASK_ARCHIVE/{NN}_{ArchiveName}/
```

**Preserve**:

- All task documents
- Summary of work
- Implementation notes
- Any diagrams or supplementary files

### Step 7. Update Task Plan

Mark completed tasks in [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md):

**Before**:

```markdown
### 2.1 Layer 1: View Modifiers (Atoms)
**Progress: 0/6 tasks**

- [ ] **P0** Implement BadgeChipStyle modifier
  - File: `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift`
  - Support BadgeLevel enum (info, warning, error, success)
  - Use DS tokens exclusively (zero magic numbers)
```

**After**:

```markdown
### 2.1 Layer 1: View Modifiers (Atoms)
**Progress: 1/6 tasks (17%)**

- [x] **P0** Implement BadgeChipStyle modifier ✅ Completed 2025-10-21
  - File: `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift`
  - Support BadgeLevel enum (info, warning, error, success)
  - Use DS tokens exclusively (zero magic numbers)
  - Archive: `DOCS/TASK_ARCHIVE/02_Phase2_BadgeChipStyle/`
```

**Also update**:

- Phase progress counters
- Overall progress tracker percentage
- Phase status (if all tasks in phase are complete)

### Step 8. Update Archive Summary

Add entry to [`FoundationUI/DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md):

```markdown
# FoundationUI Task Archive Summary

## Archive Index

### 02_Phase2_BadgeChipStyle
**Completed**: 2025-10-21
**Phase**: 2.1 Layer 1: View Modifiers
**Component**: BadgeChipStyle modifier

**Implemented**:
- BadgeLevel enum with .info, .warning, .error, .success variants
- View extension `.badgeChipStyle(level:)` using DS tokens
- Unit tests with 100% coverage
- SwiftUI Previews for all variants
- DocC documentation

**Files Created**:
- `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift`
- `Tests/FoundationUITests/ModifiersTests/BadgeChipStyleTests.swift`

**Test Coverage**: 100%
**SwiftLint Violations**: 0
**Accessibility Score**: 100%

**Lessons Learned**:
- Using enum for semantic levels prevents magic string usage
- SF Symbols work well for badge icons
- VoiceOver announces badge level correctly with `.accessibilityLabel()`

**Next Steps**:
- Implement CardStyle modifier (Phase 2.1)
- Create Badge component using BadgeChipStyle (Phase 2.2)

---
```

### Step 9. Remove @todo Puzzles from Code

If PDD @todo markers were used during implementation:

1. Search codebase for resolved puzzles:

   ```bash
   grep -r "@todo" FoundationUI/Sources/
   ```

2. For completed puzzles, remove the comment or mark resolved:

   ```swift
   // Before:
   // @todo #42 Add Dark Mode color variants

   // After (if implemented):
   // (comment removed, code now handles Dark Mode)
   ```

### Step 10. Recreate next_tasks.md

If Step 3 extracted pending tasks:

1. Create new file: `FoundationUI/DOCS/INPROGRESS/next_tasks.md`
2. Write the extracted task list
3. Optionally add new tasks discovered during implementation

**Example recreated file**:

```markdown
# Next Tasks for FoundationUI

## Immediate Priority (Phase 2.1)

### CardStyle Modifier
- **Status**: Pending
- **Priority**: P0
- **Dependencies**: DS.Radius, DS.Spacing (✅ complete)
- **Estimated Effort**: M (4-6 hours)

**Why now**: Required for Card component (Phase 2.2)

### InteractiveStyle Modifier
- **Status**: Pending
- **Priority**: P0
- **Dependencies**: Platform conditionals (#if os(macOS))
- **Estimated Effort**: L (1-2 days)

**Why now**: Needed for hover effects on macOS

## Upcoming (Phase 2.2)

### Badge Component
- **Status**: Blocked
- **Blocker**: Waiting for BadgeChipStyle completion ✅ UNBLOCKED
- **Dependencies**: BadgeChipStyle modifier ✅
- **Estimated Effort**: S (2-4 hours)

**Why later**: Can start immediately now that BadgeChipStyle is done
```

### Step 11. Generate Archive Report

Create a summary of the archival operation:

```markdown
# Archive Report: {Archive Name}

## Summary
Archived completed work from FoundationUI Phase {X}.{Y} on {date}.

## What Was Archived
- {N} task documents
- {M} implementation files
- {K} test files
- Summary of work document

## Archive Location
`FoundationUI/DOCS/TASK_ARCHIVE/{NN}_{ArchiveName}/`

## Task Plan Updates
- Marked {N} tasks as complete
- Updated Phase {X} progress: {old}% → {new}%
- Updated Overall Progress: {old}% → {new}%

## Test Coverage
- Unit tests: {N} tests, {coverage}% coverage
- Snapshot tests: {M} snapshots
- Accessibility tests: {K} assertions

## Quality Metrics
- SwiftLint violations: 0
- Magic numbers: 0
- DocC coverage: 100%

## Next Tasks Identified
{List of pending tasks from next_tasks.md}

## Lessons Learned
{Key insights from implementation}

## Open Questions
{Any unresolved issues or future considerations}

---
**Archive Date**: {current date}
**Archived By**: Claude (FoundationUI Agent)
```

---

## ✅ EXPECTED OUTPUT

- **Archive folder created**: `FoundationUI/DOCS/TASK_ARCHIVE/{NN}_{ArchiveName}/`
- **All INPROGRESS files moved** to archive folder
- **Task Plan updated** with completion markers and archive references
- **Archive Summary updated** with new entry
- **next_tasks.md recreated** (if pending tasks exist)
- **Archive report generated** with metrics and lessons learned

---

## 🧠 EXAMPLE: Archiving BadgeChipStyle

### Before Archival

```bash
FoundationUI/DOCS/INPROGRESS/
├── Phase2_BadgeChipStyle.md
├── Summary_of_Work.md
└── next_tasks.md
```

### Step 1: Verify Completion

- ✅ Tests pass: `swift test` → 4 tests, 100% coverage
- ✅ SwiftLint: 0 violations
- ✅ Preview works in Xcode
- ✅ Committed: `git log` shows commit "Add BadgeChipStyle modifier (#2.1)"

### Step 2-3: Inspect and Extract

- Found `next_tasks.md` with "CardStyle modifier" and "Badge component"
- Extracted for recreation after archiving

### Step 4-5: Create Archive

- Existing archives: `01_Phase1_DesignTokens`
- New archive: `02_Phase2_BadgeChipStyle`
- Created folder

### Step 6: Move Files

```bash
mv FoundationUI/DOCS/INPROGRESS/* \
   FoundationUI/DOCS/TASK_ARCHIVE/02_Phase2_BadgeChipStyle/
```

### Step 7: Update Task Plan

```markdown
- [x] **P0** Implement BadgeChipStyle modifier ✅ Completed 2025-10-21
```

Progress: 0/6 → 1/6 (17%)

### Step 8: Update Archive Summary

Added entry to `ARCHIVE_SUMMARY.md`

### Step 9: Check @todo

No unresolved @todo markers found

### Step 10: Recreate next_tasks.md

Created new file with CardStyle and Badge tasks

### Step 11: Generate Report

Created archive report with metrics

### After Archival

```bash
FoundationUI/DOCS/
├── INPROGRESS/
│   └── next_tasks.md (recreated)
└── TASK_ARCHIVE/
    ├── 01_Phase1_DesignTokens/
    ├── 02_Phase2_BadgeChipStyle/
    │   ├── Phase2_BadgeChipStyle.md
    │   ├── Summary_of_Work.md
    │   └── next_tasks.md (original)
    └── ARCHIVE_SUMMARY.md (updated)
```

---

## 🧾 NOTES

- **Never archive incomplete work** — all completion criteria must be met
- **Preserve implementation history** — keep all notes and summaries
- **Maintain sequential numbering** — never skip numbers in archive folders
- **Document lessons learned** — capture insights for future work
- **Carry forward next tasks** — don't lose pending work information
- **Update all tracking documents** — Task Plan, Archive Summary, etc.

---

## 🔄 INTEGRATION WITH WORKFLOW

After archiving:

- Use [SELECT_NEXT command](./SELECT_NEXT.md) to choose the next task from `next_tasks.md`
- Use [START command](./START.md) to begin implementation of the selected task
- Repeat the development cycle

---

## 🎯 QUALITY GATES

Before archiving, run final quality checks:

```bash
# Run all tests
swift test

# Check test coverage
swift test --enable-code-coverage

# Run SwiftLint
swiftlint

# Verify no uncommitted changes
git status

# Verify build succeeds
swift build
```

All checks must pass before archival is permitted.

---

## END OF SYSTEM PROMPT

Ensure all Markdown formatting is consistent across documentation files.
