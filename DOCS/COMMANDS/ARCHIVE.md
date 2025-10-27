# SYSTEM PROMPT: Archive Current Work-in-Progress

## 🧩 PURPOSE
Archive the current contents of [`DOCS/INPROGRESS`](../INPROGRESS) into a new, sequentially numbered folder in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE) while keeping "next task" breadcrumbs and blocked work logs accurate.

## 🎯 GOAL
Safely move every active task note into the archive, regenerate any `next_tasks.md` content that still applies, and ensure blocked work is either tracked for recovery or retired into [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) when it cannot proceed.

---

## 🔗 REFERENCE MATERIALS
- [Root TODO list (`todo.md`)](../../todo.md)
- [Execution workplan (`04_TODO_Workplan.md`)](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Task selection rules (`03_Next_Task_Selection.md`)](../RULES/03_Next_Task_Selection.md)
- [Backlog detail (`ISOInspector_PRD_TODO.md`)](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [Archive index (`ARCHIVE_SUMMARY.md`)](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md)
- [Permanent blocker log (`DOCS/TASK_ARCHIVE/BLOCKED`)](../TASK_ARCHIVE/BLOCKED)

---

## 📁 KEY DIRECTORIES
```text
DOCS/
 ├── INPROGRESS/
 │    ├── current task notes, summaries, next_tasks.md, blocked.md
 │    └── ...
 └── TASK_ARCHIVE/
      ├── <NN>_<Task_Name>/
      ├── ARCHIVE_SUMMARY.md
      └── BLOCKED/
```

---

## ⚙️ EXECUTION STEPS

### Step 1. Review Current In-Progress Files
- Open [`DOCS/INPROGRESS`](../INPROGRESS) and list every Markdown document.
- Capture key context from any summaries, notes, or checklists so it is not lost during the move.

### Step 2. Collect Future Work Notes
- Read [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) if it exists and extract any actionable follow-ups.
- Compare those notes with the backlog sources in the reference materials to confirm they are still relevant.

### Step 3. Classify Blocked Items
- Inspect [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md).
- For each entry decide:
  - **Recoverable blockers:** keep them in `blocked.md` and update wording if context changed.
  - **Permanently blocked work (no realistic path forward, missing hardware, platform restriction, etc.):**
    1. Create a new Markdown file under [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) summarizing the blocker, prerequisites to resume, and links to historical context.
    2. Remove the entry from `blocked.md` so the day-to-day list only contains recoverable items.
- Update [`DOCS/TASK_ARCHIVE/BLOCKED/README.md`](../TASK_ARCHIVE/BLOCKED/README.md) if guidance needs refinement.

### Step 4. Determine the Next Archive Folder Name
- Target base path: [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE).
- Folder naming pattern: `{NN}_{Task_Name}` with two-digit zero padding.
- Identify the highest existing numeric prefix and increment it by one to form the new folder name (e.g., `194_New_Work_Item`).
- Create the folder if it does not exist.

### Step 5. Move Current Work Into the Archive
- Move every file and subfolder from [`DOCS/INPROGRESS`](../INPROGRESS) into the new archive folder.
- Preserve relative structure and filenames.
- Update [`DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md) with a new entry describing the archived work and linking to the new folder.

### Step 6. Rebuild `DOCS/INPROGRESS`
- Recreate [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) using the actionable items gathered in Step 2 (omit the file if there are no follow-ups).
- Recreate [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) with the remaining recoverable blockers from Step 3.
- Add any other scaffolding files (e.g., new task PRD shells) required for upcoming work.

### Step 7. Update Planning Artifacts
- Reflect the archived state in `todo.md`, `04_TODO_Workplan.md`, and `ISOInspector_PRD_TODO.md` where applicable.
- Ensure any tasks moved to the permanent blocked list are marked accordingly in these documents.

### Step 8. Report Results
- Record the path of the new archive folder and whether fresh `next_tasks.md` or `blocked.md` files were generated.
- Note updates to the archive index, backlog documents, and the permanent blocker directory.

---

## ✅ EXPECTED OUTPUT
- A new sequential archive folder containing all previously in-progress files.
- Updated `DOCS/INPROGRESS` scaffolding reflecting only actionable next tasks and recoverable blockers.
- Permanent blockers, if any, captured under `DOCS/TASK_ARCHIVE/BLOCKED` with clear prerequisites for resuming work.
- A short summary highlighting the changes.

---

## 🧠 TIPS
- Keep numbering contiguous; never reuse an existing archive prefix.
- Always double-check `next_tasks.md` against the authoritative backlog to avoid duplicating outdated plans.
- Use the permanent blocker directory sparingly—only when recovery truly depends on unavailable capabilities.

---

## END OF SYSTEM PROMPT

At the end of working ensure Markdown formatting is consistent. The legacy helper script `scripts/fix_markdown.py` has been retired.
