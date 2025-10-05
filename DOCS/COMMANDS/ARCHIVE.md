# SYSTEM PROMPT: Archive Current Work-in-Progress

## 🧩 PURPOSE

Archive the current contents of [`DOCS/INPROGRESS`](../INPROGRESS) into a sequentially numbered folder under [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE). Preserve workflow continuity by detecting and carrying forward “next task” references documented in [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md).

---

## 🎯 GOAL

Safely move all active task files from [`DOCS/INPROGRESS`](../INPROGRESS) into a new, properly numbered archive folder. Automatically prepare a new [`next_tasks.md`](../INPROGRESS/next_tasks.md) file if the current summary references upcoming tasks.

---

## 🔗 REFERENCE MATERIALS

- [Root TODO list (`todo.md`)](../../todo.md)
- [Execution workplan (04_TODO_Workplan.md)](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [Task selection rules (03_Next_Task_Selection.md)](../RULES/03_Next_Task_Selection.md)
- [Backlog detail (ISOInspector_PRD_TODO.md)](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [Archive index (`DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`)](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md)

---

## 📁 DIRECTORY STRUCTURE

```text
DOCS/
 ├── INPROGRESS/
 │    ├── ...
 │    └── Summary_of_Work.md (optional)
 └── TASK_ARCHIVE/
      ├── 01_Initial_Setup
      ├── 02_Setup_Swift_SPM
      └── ...

```

---

## ⚙️ EXECUTION STEPS

### Step 1. Inspect Current Work Folder

- Look inside [`DOCS/INPROGRESS`](../INPROGRESS) (e.g., the current task docs `B3_Streaming_Parse_Pipeline.md` and `F1_Test_Fixtures.md`).
- Detect any file whose name **contains “Summary”** (such as a `Summary_of_Work.md`) or is exactly **`next_tasks.md`**.
- If found, open and read the content to capture context that must persist after archiving.

### Step 2. Extract Mentions of Upcoming Tasks

- Search the text for mentions of **pending**, **next**, or **upcoming** tasks. Prioritize any checklists in [`DOCS/INPROGRESS/next_tasks.md`](../INPROGRESS/next_tasks.md) and cross-check against the broader backlog in [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) and [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md).
- If found, temporarily store this information to recreate it later.

### Step 3. Determine the Next Archive Folder Name

- Target base path: [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE).
- Folder naming pattern:

  ```text
  {NN}_{TASK_NAME}
  ```

  Example: `02_Setup_Swift_SPM`

- Find the highest existing prefix `{NN}`, increment it by one to define the new folder name, e.g. `03_New_Task_Name`.

- If [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE) does not exist, create it.
- Then create the new subfolder for the current task using the name from Step 3.

### Step 5. Move Files to Archive

- Move **all files and subfolders** from [`DOCS/INPROGRESS`](../INPROGRESS) to the new archive folder.
- Preserve structure and file integrity.
- Update [`DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md) if a new entry is needed.

### Step 6. Recreate `next_tasks.md` (if applicable)

- If Step 2 found mentions of next tasks:

  - Create a new file:

    ```text
    DOCS/INPROGRESS/next_tasks.md
    ```

  - Write the extracted list or short summary of those next tasks into it, ensuring they align with the backlog items tracked in [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) and [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md).

### Step 7. Report Result

- Output the **path of the new archive folder**.
- Indicate whether a **new `next_tasks.md`** file was created.
- Reference any updates made to [`ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md) or outstanding todos in [`todo.md`](../../todo.md).

---

## ✅ EXPECTED OUTPUT

- A new archive folder created under `DOCS/TASK_ARCHIVE/` with the next sequential number.
- All contents of `DOCS/INPROGRESS` successfully moved there.
- A new file `DOCS/INPROGRESS/next_tasks.md` created if applicable.
- A short text report summarizing actions performed.

---

## 🧠 EXAMPLE

**Before:**

```text
DOCS/
 ├── INPROGRESS/
 │    ├── README.md
 │    └── Summary_of_Work.md
 └── TASK_ARCHIVE/
      ├── 01_Initial_Setup
      └── 02_Setup_Swift_SPM

```

**After:**

```text
DOCS/
 ├── INPROGRESS/
 │    └── next_tasks.md
 └── TASK_ARCHIVE/
      ├── 01_Initial_Setup
      ├── 02_Setup_Swift_SPM
      └── 03_Current_Work

```

---

## 🧾 NOTES

- Always analyze the content before moving files.
- Maintain numeric order continuity.
- Never overwrite existing archive folders.
- Preserve relative paths and file metadata during move.

---

## END OF SYSTEM PROMPT
