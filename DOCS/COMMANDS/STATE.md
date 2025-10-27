# SYSTEM PROMPT: Report Project State

## 🧩 PURPOSE

Provide a concise but comprehensive status report for the project so stakeholders understand what is in progress, what comes next, and how overall execution is tracking against the defined plans.

---

## 🎯 GOAL

Collect and summarize the current implementation status, including active and upcoming tasks, workstream coverage, and completion percentages across all authoritative planning sources (workplan, task plan, and TODO lists).

---

## 🔗 REFERENCE MATERIALS

- [`DOCS/INPROGRESS`](../INPROGRESS) — especially [`next_tasks.md`](../INPROGRESS/next_tasks.md) and any active task documents.
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md).
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md).
- Root [`todo.md`](../../todo.md) and any other up-to-date TODO or task-tracking lists referenced by [`SELECT_NEXT`](SELECT_NEXT.md).
- Relevant history in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE) when clarifying what has already been completed.

---

## ⚙️ EXECUTION STEPS

### Step 1. Load Current Context

- Read [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) to identify selected upcoming tasks and any prioritization notes.
- Enumerate all Markdown files in [`DOCS/INPROGRESS`](../INPROGRESS) (excluding utility files like summaries or archives) to capture work that is actively being executed.

### Step 2. Review Planning Sources

- Inspect the authoritative workplan: [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md).
- Inspect the detailed task plan / backlog: [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md) — focus on execution-ready sections highlighted by [`SELECT_NEXT`](SELECT_NEXT.md).
- Inspect the repo-wide TODO file [`todo.md`](../../todo.md) plus any linked task lists noted in [`SELECT_NEXT`](SELECT_NEXT.md).

### Step 3. Measure Progress

For each planning source consulted in Step 2:

- Count total tasks or checklist items versus those explicitly marked as completed/done.
- Compute completion percentage (completed ÷ total × 100). Record assumptions if the format is ambiguous.
- Note any discrepancies between sources (e.g., tasks marked done in one list but not another).

### Step 4. Summarize State

Produce a structured report containing:

1. **Current Active Tasks** — list active task files with short status summaries (in progress, blocked, pending review, etc.).
2. **Next Selected Tasks** — restate the candidates or queued work from [`next_tasks.md`](../INPROGRESS/next_tasks.md) with priority ordering.
3. **Progress Metrics** — table or bullet list of completion percentages for:
   - Execution workplan tasks.
   - Task plan / backlog entries.
   - Repository TODO lists (and any other authoritative TODO lists referenced above).
4. **Notable Risks or Dependencies** — highlight blockers, required decisions, or mismatches between planning documents.
5. **Recommended Updates** — specify which documents should be updated (if any) to keep records consistent.

### Step 5. Deliver Output

- Return the report in Markdown with clear section headers mirroring Step 4.
- Include a short changelog summary noting any files inspected or metrics computed.
- If information is missing or ambiguous, explicitly call it out and suggest how to resolve the gap (e.g., “workplan lacks completion markers for sections 3.2–3.4”).

---

## ✅ EXPECTED OUTPUT

- A Markdown-formatted status report covering active tasks, next tasks, and completion metrics across all referenced planning sources.
- Transparent handling of unknowns or inconsistencies.
- Ready-to-share summary that can be pasted into project updates without additional editing.

---

## 🧾 NOTES

- Do **not** modify any source documents while gathering the report; this command is read-only.
- Keep calculations reproducible — show item counts or simple formulas where practical.
- If numerical tracking is impossible because of missing markers, estimate conservatively and annotate the assumption.
- Prefer referencing documents by relative path to keep context portable.

---

## END OF SYSTEM PROMPT

At the end of working ensure Markdown formatting is consistent. The legacy helper script `scripts/fix_markdown.py` has been retired.
