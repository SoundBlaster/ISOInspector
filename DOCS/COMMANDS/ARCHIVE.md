# SYSTEM PROMPT: Archive Current Work-in-Progress

## 🧩 PURPOSE

Archive the current contents of [`DOCS/INPROGRESS`](../INPROGRESS) into a new, sequentially numbered folder in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE) while keeping blocked work logs accurate.

## 🎯 GOAL

Safely move every active task note into the archive and ensure blocked work is either tracked for recovery or retired into [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) when it cannot proceed.

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

### Step 2. Classify Blocked Items

- Inspect [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md).
- For each entry decide:
  - **Recoverable blockers:** keep them in `blocked.md` and update wording if context changed.
  - **Permanently blocked work (no realistic path forward, missing hardware, platform restriction, etc.):**
    1. Create a new Markdown file under [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) summarizing the blocker, prerequisites to resume, and links to historical context.
    2. Remove the entry from `blocked.md` so the day-to-day list only contains recoverable items.
- Update [`DOCS/TASK_ARCHIVE/BLOCKED/README.md`](../TASK_ARCHIVE/BLOCKED/README.md) if guidance needs refinement.

### Step 3. Determine the Next Archive Folder Name

- Target base path: [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE).
- Folder naming pattern: `{NN}_{Task_Name}` with two-digit zero padding.
- Identify the highest existing numeric prefix and increment it by one to form the new folder name (e.g., `194_New_Work_Item`).
- Create the folder if it does not exist.

### Step 4. Move Current Work Into the Archive

- Move every file and subfolder from [`DOCS/INPROGRESS`](../INPROGRESS) into the new archive folder.
- Preserve relative structure and filenames.
- Update [`DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md) with a new entry describing the archived work and linking to the new folder.

### Step 5. Report Results

- Record the path of the new archive folder and summarize any changes to the archive index or permanent blocker directory.

---

## ✅ EXPECTED OUTPUT

- A new sequential archive folder containing all previously in-progress files.
- `DOCS/INPROGRESS` left empty (or containing only the files moved during the archive step, if you need to keep stubs for record keeping).
- Permanent blockers, if any, captured under `DOCS/TASK_ARCHIVE/BLOCKED` with clear prerequisites for resuming work.
- A short summary highlighting the changes.

---

## 🧠 TIPS

- Keep numbering contiguous; never reuse an existing archive prefix.
- Use the permanent blocker directory sparingly—only when recovery truly depends on unavailable capabilities.

---

## END OF SYSTEM PROMPT

At the end of working ensure Markdown formatting is consistent. The legacy helper script `scripts/fix_markdown.py` has been retired.
