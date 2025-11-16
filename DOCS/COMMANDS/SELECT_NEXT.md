# SYSTEM PROMPT: Select the Next Task

## 🧩 PURPOSE

Identify the next actionable task based on project rules, the carried-forward notes in [`DOCS/INPROGRESS`](../INPROGRESS), and the prioritized backlog so new work starts with an up-to-date PRD stub.

## 🎯 GOAL

Apply the decision framework in [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) to choose a task, verify it is not permanently blocked, and create an `INPROGRESS` Markdown document that records its objective, context, and success criteria.

---

## 🔗 REFERENCE MATERIALS

- [Task selection rules (`03_Next_Task_Selection.md`)](../RULES/03_Next_Task_Selection.md)
- [Workflow rules (`02_TDD_XP_Workflow.md`)](../RULES/02_TDD_XP_Workflow.md)
- [PDD methodology (`04_PDD.md`)](../RULES/04_PDD.md)
- [Master PRD (`ISOInspector_Master_PRD.md`)](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [Execution workplan (`04_TODO_Workplan.md`)](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Detailed backlog (`ISOInspector_PRD_TODO.md`)](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [Root TODO list (`todo.md`)](../../todo.md)
- [Current blocked list (`DOCS/INPROGRESS/blocked.md`)](../INPROGRESS/blocked.md)
- [Permanent blockers (`DOCS/TASK_ARCHIVE/BLOCKED`)](../TASK_ARCHIVE/BLOCKED)

### 🔧 PDD Task Discovery Tool

The `scripts/collect_todos.py` script scans the codebase for `@todo` puzzles and generates a comprehensive report following PDD (Puzzle-Driven Development) methodology:

```bash
# Generate PDD puzzle report
python3 scripts/collect_todos.py --output DOCS/TODO_REPORT.md

# View the report
cat DOCS/TODO_REPORT.md
```

**Purpose:** Extract all `@todo #TaskID description` comments from code, group by task ID, and generate a sorted Markdown report. Use this to discover code-level tasks that may not be in planning documents.

**Documentation:** See `scripts/README.md` for full usage details.

---

## ⚙️ EXECUTION STEPS

### Step 1. Review the Selection Framework

- Read [`03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) to refresh prioritization and dependency rules.
- Cross-check supporting context in [`02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md) and [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md).

### Step 2. Inspect Blocked Work

- Scan [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) to understand which items are currently blocked but recoverable.
- Review [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) to ensure permanently blocked efforts are not accidentally reconsidered.
- If a candidate task appears in either list, confirm the blocker has been resolved before selecting it; otherwise choose a different item or document the work required to unblock it.

### Step 3. Gather Candidate Tasks

- Read [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) if present and extract proposed follow-ups.
- If the file is missing or empty, consult the broader backlog sources:
  - [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
  - [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
  - [`todo.md`](../../todo.md)
- **Optional:** Run `python3 scripts/collect_todos.py` to generate a PDD puzzle report from `@todo` comments in the codebase. This reveals code-level tasks that may not appear in planning documents.
  - The report groups tasks by ID (e.g., `#A7`, `#220`) and shows exact file locations
  - Particularly useful for finding refactoring tasks, technical debt, and blocked work
  - Tasks without IDs appear in a separate "Unnumbered Tasks" section
- Note dependencies, prerequisites, and any context captured in archived summaries under [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE).

### Step 4. Apply Selection Rules

- Filter the candidate list using the criteria from Step 1 (priority, dependencies, customer value, and readiness).
- Confirm the chosen task has the resources and unblockers required to proceed.
- Update the source documents (`next_tasks.md`, workplan, backlog) to reflect the decision—mark the selected task as **In Progress** or remove it from the candidate list as appropriate.

### Step 5. Create the New Task Document

- Place the file in [`DOCS/INPROGRESS`](../INPROGRESS) with a descriptive, numbered filename (e.g., `194_CLI_Export_Smoke_Tests.md`).
- Populate it using the template below:

```markdown
# {TASK_TITLE}

## 🎯 Objective
Brief summary of the user or system outcome we need to deliver.

## 🧩 Context
Relevant background, dependencies, or links to prior archives.

## ✅ Success Criteria
Bullet list describing when the task is complete.

## 🔧 Implementation Notes
Important considerations, experiments, or sub-steps.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
```

### Step 6. Report Outcome

- Summarize which task was chosen, why it met the prioritization rules, and where its PRD lives.
- Mention any updates made to `next_tasks.md`, backlog documents, or blocked lists.

---

## ✅ EXPECTED OUTPUT

- A clearly justified task selection aligned with project rules.
- A new Markdown file in `DOCS/INPROGRESS` that captures objectives, context, and references.
- Updated planning artifacts reflecting the new in-progress work and the current state of blocked tasks.

---

## 🧠 TIPS

- Always cross-reference the blocked directories before picking a task; resurrecting permanently blocked efforts wastes time.
- Keep filenames consistent with archive numbering so the next archival step is seamless.
- If no candidate meets the rules, document the gap and propose unblocker actions instead of forcing a low-quality selection.

---

## END OF SYSTEM PROMPT

At the end of working ensure Markdown formatting is consistent. The legacy helper script `scripts/fix_markdown.py` has been retired.
