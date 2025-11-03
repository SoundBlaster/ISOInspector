# SYSTEM PROMPT: Report FoundationUI Project State

## 🧩 PURPOSE

Provide a concise but comprehensive status report for the FoundationUI project so stakeholders understand what is in progress, what comes next, and how overall execution is tracking against the defined plans and Composable Clarity architecture.

---

## 🎯 GOAL

Collect and summarize the current implementation status, including:

- **Active and upcoming tasks** with layer and phase context
- **Layer-by-layer completion status** (Tokens → Modifiers → Components → Patterns → Contexts)
- **Phase progression metrics** across all six implementation phases
- **Platform coverage status** (iOS, macOS, iPadOS)
- **Overall completion percentages** from authoritative planning sources

---

## 🔗 REFERENCE MATERIALS

### FoundationUI Planning Documents

- [`DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md`](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Master task list with phases, layers, and priorities
- [`DOCS/AI/ISOViewer/FoundationUI_PRD.md`](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements and architecture specification
- [`DOCS/AI/ISOViewer/FoundationUI_TestPlan.md`](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy and coverage requirements

### Task Tracking

- [`FoundationUI/DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) — Queued and prioritized upcoming tasks
- [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS) — Currently active task documents
- [`FoundationUI/DOCS/TASK_ARCHIVE/`](../TASK_ARCHIVE) — Completed task history

### Project Rules

- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — Test-driven development workflow
- [`DOCS/RULES/03_Next_Task_Selection.md`](../../../DOCS/RULES/03_Next_Task_Selection.md) — Task prioritization rules

### Related Commands

- [`SELECT_NEXT.md`](SELECT_NEXT.md) — Task selection algorithm
- [`START.md`](START.md) — Task initialization workflow
- [`ARCHIVE.md`](ARCHIVE.md) — Task completion workflow

---

## ⚙️ EXECUTION STEPS

### Step 1. Load Current Context

1. **Scan active work**: List all Markdown files in [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS) (excluding `next_tasks.md` and summaries)
2. **Identify queued tasks**: Read [`FoundationUI/DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) to see what's been prioritized next
3. **Check recent completions**: List the most recent 5 files in [`FoundationUI/DOCS/TASK_ARCHIVE/`](../TASK_ARCHIVE) to understand velocity

### Step 2. Analyze Phase and Layer Progress

Open [`FoundationUI_TaskPlan.md`](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) and extract:

1. **Overall Progress Tracker** table (Phase 1–6 completion percentages)
2. **Phase-by-phase task counts**: Total vs completed for each phase
3. **Layer-by-layer status**:
   - Layer 0: Design Tokens (DS)
   - Layer 1: View Modifiers
   - Layer 2: Components
   - Layer 3: Patterns
   - Layer 4: Contexts
4. **Priority breakdown**: Count P0, P1, P2 tasks remaining vs completed
5. **Platform coverage notes**: Any platform-specific tasks (iOS/macOS/iPadOS) that need attention

### Step 3. Measure Completion Metrics

For each planning source, compute and record:

| **Source** | **Total Items** | **Completed** | **Completion %** | **Notes** |
|------------|-----------------|---------------|------------------|-----------|
| TaskPlan Phase 1 | {count} | {count} | {percent}% | Foundation complete |
| TaskPlan Phase 2 | {count} | {count} | {percent}% | Core components |
| TaskPlan Phase 3 | {count} | {count} | {percent}% | Patterns & adaptation |
| TaskPlan Phase 4 | {count} | {count} | {percent}% | Agent support |
| TaskPlan Phase 5 | {count} | {count} | {percent}% | Documentation |
| TaskPlan Phase 6 | {count} | {count} | {percent}% | Integration |
| **Overall TaskPlan** | **{total}** | **{completed}** | **{percent}%** | **All phases** |

### Step 4. Identify Blockers and Dependencies

Check for:

- **Layer dependency violations**: Are any tasks blocked waiting for lower-layer completions?
- **Test coverage gaps**: Are implementation tasks outpacing test tasks (violates TDD)?
- **Platform inconsistencies**: Do any components lack macOS or iPadOS support?
- **Build failures**: Has the project been building successfully?
- **Documentation debt**: Are completed components missing DocC comments or previews?

### Step 5. Assess Architecture Compliance

Verify adherence to Composable Clarity principles:

- ✅ **Zero magic numbers**: All components use DS tokens
- ✅ **Accessibility**: Labels and dynamic type support
- ✅ **Platform adaptation**: Conditional compilation for platform differences
- ✅ **Test coverage**: Unit tests for all modifiers and components
- ✅ **SwiftLint compliance**: Zero violations policy

### Step 6. Summarize State

Produce a structured Markdown report with the following sections:

---

## 📊 REPORT TEMPLATE

```markdown
# FoundationUI Project Status Report

**Generated**: {YYYY-MM-DD HH:MM}
**Current Phase**: Phase {X}: {Phase Name}
**Overall Completion**: {XX.X}% ({completed}/{total} tasks)

---

## 🚀 ACTIVE TASKS

{List each file in INPROGRESS/ with a 1-2 sentence summary of status}

**Example**:
- **Phase3_PlatformExtensions.md** — Implementing conditional compilation for iPadOS-specific UI elements. Status: In progress, 3/5 success criteria met.

---

## 📋 NEXT QUEUED TASKS

{Restate contents of next_tasks.md with priority order}

**Example**:
1. **(P0)** Implement CardStyle modifier — Layer 1, Phase 2
2. **(P1)** Write Badge component tests — Layer 2, Phase 2

---

## 📈 PROGRESS METRICS

### Phase Completion

| Phase | Name | Tasks | Completed | % Done | Status |
|-------|------|-------|-----------|--------|--------|
| 1 | Foundation | 8 | 8 | 100% | ✅ Complete |
| 2 | Core Components | 22 | 14 | 63.6% | 🔄 Active |
| 3 | Patterns & Adaptation | 18 | 2 | 11.1% | ⏳ Waiting |
| 4 | Agent Support | 12 | 0 | 0% | ⏳ Waiting |
| 5 | Documentation | 8 | 0 | 0% | ⏳ Waiting |
| 6 | Integration | 6 | 0 | 0% | ⏳ Waiting |
| **Total** | **All Phases** | **74** | **24** | **32.4%** | **🔄 Active** |

### Layer Completion (Composable Clarity Architecture)

| Layer | Name | Tasks | Completed | % Done | Blockers |
|-------|------|-------|-----------|--------|----------|
| 0 | Design Tokens (DS) | 8 | 8 | 100% | None |
| 1 | View Modifiers | 6 | 4 | 66.7% | None |
| 2 | Components | 14 | 6 | 42.9% | Awaiting Layer 1 completion |
| 3 | Patterns | 8 | 1 | 12.5% | Awaiting Layer 2 completion |
| 4 | Contexts | 4 | 0 | 0% | Awaiting Layer 3 completion |

### Priority Distribution

| Priority | Total | Completed | Remaining | % Complete |
|----------|-------|-----------|-----------|------------|
| P0 (Critical) | 32 | 18 | 14 | 56.3% |
| P1 (Important) | 28 | 6 | 22 | 21.4% |
| P2 (Nice-to-have) | 14 | 0 | 14 | 0% |

---

## 🎯 ARCHITECTURE COMPLIANCE

**Design Token Usage**: ✅ 100% compliance (zero magic numbers detected)
**Test Coverage**: ⚠️  82% (8 components missing tests)
**SwiftLint Compliance**: ✅ Zero violations
**Platform Support**: 🔄 Partial (iOS ✅, macOS ✅, iPadOS 🔄 in progress)
**Accessibility**: ⚠️  65% (12 components need labels)
**Documentation**: 🔄 78% (DocC comments present, previews incomplete)

---

## ⚠️  BLOCKERS & RISKS

{List any issues preventing forward progress}

**Example**:
- ⚠️  **Layer dependency**: Cannot implement `InspectorPattern` (Layer 3) until `Card` and `Badge` components (Layer 2) are complete
- ⚠️  **Test coverage gap**: 3 modifiers implemented without corresponding unit tests (violates TDD workflow)
- ⚠️  **Platform inconsistency**: `PlatformExtensions.swift` not yet tested on iPadOS simulator

---

## 🔧 RECOMMENDED UPDATES

{Suggest actions to keep documentation and implementation aligned}

**Example**:
1. Update `FoundationUI_TaskPlan.md` to mark `BadgeChipStyle` as `[x]` completed
2. Create test tasks in `next_tasks.md` for 3 modifiers missing tests
3. Add iPadOS platform testing to success criteria for active tasks
4. Archive completed `Phase2_BadgeChipStyle.md` task to TASK_ARCHIVE

---

## 🧠 RECENT COMPLETIONS

{List last 5 archived tasks with completion dates}

**Example**:
- **2025-10-26**: Phase2_BadgeChipStyle.md — BadgeChipStyle modifier with tests
- **2025-10-25**: Phase2_CardStyle.md — CardStyle modifier with platform variants
- **2025-10-24**: Phase1_DesignTokens_Radius.md — DS.Radius token suite

---

## 📊 VELOCITY METRICS

**Avg tasks/week**: {calculate from archive dates}
**Estimated completion** (current velocity): {weeks remaining} weeks
**Critical path tasks remaining**: {count P0 tasks}

---

## 🎯 NEXT RECOMMENDED ACTION

Based on layer dependencies and priority, the next task should be:

**{Task Name}** — {Phase}, {Layer}, Priority: {P0/P1/P2}

Dependencies satisfied: ✅ / Blockers: {list or "None"}

Use `/select_next` to formally select and initialize this task.

---

## 📝 CHANGELOG

**Files Inspected**:
- FoundationUI/DOCS/INPROGRESS/ ({X} active tasks)
- FoundationUI/DOCS/INPROGRESS/next_tasks.md
- DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md
- FoundationUI/DOCS/TASK_ARCHIVE/ ({Y} archived tasks)

**Metrics Computed**:
- Phase completion percentages (6 phases)
- Layer completion percentages (5 layers)
- Priority distribution (P0/P1/P2)
- Architecture compliance checks (6 criteria)

**Assumptions**:
{List any assumptions made when data was ambiguous}

---
```

---

## ✅ EXPECTED OUTPUT

- **Structured Markdown report** covering all sections in the template above
- **Quantitative metrics** with reproducible calculations (show denominators)
- **Architecture-aware analysis** respecting Composable Clarity layer dependencies
- **Actionable recommendations** for maintaining consistency across planning docs
- **Transparent handling** of missing data or ambiguities
- **Ready-to-share format** requiring no additional editing for stakeholder consumption

---

## 🧾 NOTES

### Read-Only Operation

- This command **does not modify** any source documents
- All metrics are computed from existing files
- If updates are recommended, they must be applied manually or via other commands

### Reproducible Calculations

- Always show numerator/denominator (e.g., "14/22 = 63.6%")
- If task markers are ambiguous, estimate conservatively and annotate the assumption
- Prefer exact counts over approximations

### Platform Portability

- Use relative paths for all document references
- Assume the working directory is `FoundationUI/DOCS/COMMANDS/`
- Links should work from any branch or clone of the repository

### Integration with Workflow

- Use this command before sprint planning or stakeholder updates
- Run after completing major milestones to update velocity metrics
- Compare reports over time to track acceleration or deceleration

### Handling Inconsistencies

If planning documents conflict (e.g., task marked done in TaskPlan but not archived):

1. **Note the discrepancy** explicitly in the Recommended Updates section
2. **Use TaskPlan as source of truth** for completion status
3. **Suggest reconciliation** (e.g., "Archive Phase2_BadgeChipStyle.md to match TaskPlan")

---

## 🔄 RELATED COMMANDS

- **[SELECT_NEXT](SELECT_NEXT.md)** — Use after reviewing state to choose next task
- **[START](START.md)** — Initialize work on selected task
- **[ARCHIVE](ARCHIVE.md)** — Complete task and update metrics

---

## END OF SYSTEM PROMPT

Ensure all Markdown formatting is consistent across documentation files.
