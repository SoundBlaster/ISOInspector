# SYSTEM PROMPT: Select the Next Task

## 🧩 PURPOSE

Automatically determine and initialize the next task to work on, following the predefined project rules and available task notes from [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md), the execution guide, and the authoritative TODO sources.

---

## 🎯 GOAL

Read and apply the selection rules from [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md), analyze pending tasks listed in [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md), and create a new task document containing its title and a lightweight PRD outline based on the main project documentation (see the [execution workplan](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md), [PRD backlog](../AI/ISOViewer/ISOInspector_PRD_TODO.md), and [master PRD](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)).

---

## 🔗 REFERENCE MATERIALS

- [Root TODO list (`todo.md`)](../../todo.md)
- [Execution workplan (04_TODO_Workplan.md)](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Master PRD (ISOInspector_Master_PRD.md)](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [Detailed backlog (ISOInspector_PRD_TODO.md)](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [Task selection rules (`DOCS/RULES/03_Next_Task_Selection.md`)](../RULES/03_Next_Task_Selection.md)
- [Workflow rules (`DOCS/RULES/02_TDD_XP_Workflow.md`)](../RULES/02_TDD_XP_Workflow.md)

---

## ⚙️ EXECUTION STEPS

### Step 1. Read Task Selection Rules

- Open [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md) for the explicit prioritization and dependency logic.
- Review supporting workflow guidance in [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md) and product framing notes in [`DOCS/RULES/01_PRD.md`](../RULES/01_PRD.md).
- Parse and understand the criteria before evaluating candidates.

### Step 2. Inspect Pending Tasks

- Check if [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) exists.
- If present, read the file and extract the listed upcoming tasks or ideas, noting references such as the carried-over `B2+` streaming interface item.

### Step 3. Apply Selection Rules

- Use the criteria from Step 1 to determine which task should be selected next.
- If multiple tasks qualify, choose the one with the highest priority according to the rules.
- If no tasks are found in `next_tasks.md`, consult the broader backlog sources:
  - [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) for the authoritative workplan.
  - [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md) — especially the "## 5) Detailed TODO (execution-ready, без кода)" section.
  - The root [`todo.md`](../../todo.md) for any repo-level quick wins.

### Step 4. Create a New Task Document

- Use the folder [`DOCS/INPROGRESS`](../INPROGRESS) as the target location.
- Create a new Markdown file with a name matching the chosen task, e.g.:

  ```text
  DOCS/INPROGRESS/03_Implement_New_Feature.md
  ```

- Inside the new file, include a **lightweight PRD (Product Requirements Document)** derived from the main PRD and guides located in other DOCS subfolders.

### Step 5. PRD Content Template

The created file should include the following structure:

```markdown
# {TASK_TITLE}

## 🎯 Objective
Short description of what needs to be achieved.

## 🧩 Context
Reference to relevant guides or PRD sections.

## ✅ Success Criteria
List of measurable completion conditions.

## 🔧 Implementation Notes
Any key hints or dependencies to consider.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Any relevant archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

```

- Keep it short, structured, and clear.

### Step 6. Report Result

- Output the name of the chosen task.
- Confirm that the new Markdown PRD file was successfully created in `DOCS/INPROGRESS`.

---

## ✅ EXPECTED OUTPUT

- A new file created in `DOCS/INPROGRESS` with the next task name and a lightweight PRD.
- The task is chosen according to the defined rules in [`DOCS/RULES`](../RULES) and the notes in [`next_tasks.md`](../INPROGRESS/next_tasks.md), plus the backlog sources linked above.
- A short summary confirming the selected task and the applied rules.

---

## 🧠 EXAMPLE

**Before:**

```text
DOCS/
 ├── RULES/
 │    └── task_selection_rules.md
 ├── INPROGRESS/
 │    └── next_tasks.md
 └── PRD/
      └── main_prd.md

```

**After:**

```text
DOCS/
 ├── RULES/
 │    └── task_selection_rules.md
 ├── INPROGRESS/
 │    ├── next_tasks.md
 │    └── 03_Implement_New_Feature.md
 └── PRD/
      └── main_prd.md

```

---

## 🧾 NOTES

- Always prioritize based on the formal rules in `DOCS/RULES`.
- Use `next_tasks.md` as the primary source of candidates.
- Ensure consistent file naming (prefix numbers if applicable).
- Keep the generated PRD concise and consistent with project standards.

---

## END OF SYSTEM PROMPT
