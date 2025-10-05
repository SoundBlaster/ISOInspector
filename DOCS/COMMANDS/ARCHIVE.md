# SYSTEM PROMPT: Archive Current Work-in-Progress

## 🧩 PURPOSE
Archive the current contents of `DOCS/INPROGRESS` into a sequentially numbered folder under `DOCS/TASK_ARCHIVE`, while preserving workflow continuity by detecting and carrying forward “next task” references.

---

## 🎯 GOAL
Safely move all active task files from `DOCS/INPROGRESS` into a new, properly numbered archive folder and automatically prepare a new `next_tasks.md` file if the current summary references upcoming tasks.

---

## 📁 DIRECTORY STRUCTURE

```
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
- Look inside `DOCS/INPROGRESS`.
- Detect any file whose name **contains “Summary”** or is exactly **“next_task.md”**.
- If found, open and read the content.

### Step 2. Extract Mentions of Upcoming Tasks
- Search the text for mentions of **pending**, **next**, or **upcoming** tasks.
- If found, temporarily store this information to recreate it later.

### Step 3. Determine the Next Archive Folder Name
- Target base path: `DOCS/TASK_ARCHIVE/`.
- Folder naming pattern:
  ```
  {NN}_{TASK_NAME}
  ```
  Example: `02_Setup_Swift_SPM`
- Find the highest existing prefix `{NN}`, increment it by one to define the new folder name, e.g. `03_New_Task_Name`.

### Step 4. Create Archive Folder (if missing)
- If `DOCS/TASK_ARCHIVE` does not exist, create it.
- Then create the new subfolder for the current task using the name from Step 3.

### Step 5. Move Files to Archive
- Move **all files and subfolders** from `DOCS/INPROGRESS` to the new archive folder.
- Preserve structure and file integrity.

### Step 6. Recreate `next_tasks.md` (if applicable)
- If Step 2 found mentions of next tasks:
  - Create a new file:  
    ```
    DOCS/INPROGRESS/next_tasks.md
    ```
  - Write the extracted list or short summary of those next tasks into it.

### Step 7. Report Result
- Output the **path of the new archive folder**.
- Indicate whether a **new `next_tasks.md`** file was created.

---

## ✅ EXPECTED OUTPUT

- A new archive folder created under `DOCS/TASK_ARCHIVE/` with the next sequential number.
- All contents of `DOCS/INPROGRESS` successfully moved there.
- A new file `DOCS/INPROGRESS/next_tasks.md` created if applicable.
- A short text report summarizing actions performed.

---

## 🧠 EXAMPLE

**Before:**
```
DOCS/
 ├── INPROGRESS/
 │    ├── README.md
 │    └── Summary_of_Work.md
 └── TASK_ARCHIVE/
      ├── 01_Initial_Setup
      └── 02_Setup_Swift_SPM
```

**After:**
```
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

# END OF SYSTEM PROMPT
