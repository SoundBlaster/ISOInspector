# SYSTEM PROMPT: Start a New Task

## 🧩 PURPOSE
Begin active implementation of tasks defined in the `DOCS/INPROGRESS` folder, following all established development rules, methodologies, and documentation dependencies.

---

## 🎯 GOAL
Execute one or more tasks currently stored in `DOCS/INPROGRESS`, fully adhering to the engineering standards and methodologies defined in `DOCS/RULES` — particularly the **TDD (Test-Driven Development)** and **XP (Extreme Programming)** principles.  
Additionally, follow the PDD (Puzzle-Driven Development) process defined in the `04_PDD` document.

---

## ⚙️ EXECUTION STEPS

### Step 1. Identify Active Tasks
- Scan all Markdown files inside `DOCS/INPROGRESS/`.  
- Each file corresponds to a pending task.  
- Choose one (or process sequentially) based on project context or task priority.

### Step 2. Load Methodology Rules
- Open the folder `DOCS/RULES/`.
- Pay special attention to:
  - **02_TDD_XP_Workflow.md** — test-first principles and verification steps, pair programming, refactoring, and incremental delivery.  
  - **04_PDD.md** — workflow for Puzzle-Driven Development.  
- Keep these rules in mind during all implementation actions.

### Step 3. Gather Additional References
- If needed, consult files in other subfolders under `DOCS/`:
  - `DOCS/AI/ISOViewer/` – main product requirements.  
  - `DOCS/AI/ISOInspector_Execution_Guide` – style guides or architecture notes.  
  - `DOCS/MP4_Specs/` – interface or API specifications.  
- Use them to clarify edge cases or functional expectations.

### Step 4. Implement According to TDD + XP + PDD
- Follow **TDD cycle**:
  1. Write a failing test.
  2. Implement the minimal code to make it pass.
  3. Refactor and repeat.
- Apply **XP principles**:
  - Keep iterations small.
  - Refactor continuously.
  - Maintain test coverage.
- Respect **PDD**, try to:
  - Treat each file in `DOCS/INPROGRESS` as a “puzzle.”
  - Commit after each solved puzzle (atomic unit of work).

### Step 5. Track Progress
- During execution, update relevant TODO or task-tracking files.  
- When a puzzle or task is completed, **mark it as done** in the corresponding todo list in `DOCS/AI/ISOViewer/` and in any other status list.

### Step 6. Write Summary
- After all current tasks are implemented:
  - Create a new summary document inside `DOCS/INPROGRESS/`:
    ```
    DOCS/INPROGRESS/Summary_of_Work.md
    ```
  - Include:
    - Completed task names.  
    - Short description of implementation results.  
    - References to commits, tests, or updated specs.  
    - Any pending follow-up actions (if applicable).

### Step 7. Finalize
- Ensure all unit tests pass.  
- Ensure the documentation and task markers are consistent.  
- Return or print a confirmation message summarizing:
  - The tasks completed.  
  - The location of the summary file.

---

## ✅ EXPECTED OUTPUT

- All designated tasks from `DOCS/INPROGRESS` have been implemented.  
- Corresponding entries in `todo` files marked as completed.  
- A new file `Summary_of_Work.md` created in `DOCS/INPROGRESS/` with concise details of what was done.  
- No untracked changes remain.

---

## 🧠 EXAMPLE

**Before:**
```
DOCS/
 ├── INPROGRESS/
 │    ├── 03_Add_Logging.md
 │    ├── 04_Fix_Cache.md
 │    └── next_tasks.md
 ├── RULES/
 │    ├── TDD.md
 │    ├── XP.md
 │    └── 04_PDD.md
 ├── PRD/
 │    └── main_prd.md
```

**After:**
```
DOCS/
 ├── INPROGRESS/
 │    ├── Summary_of_Work.md
 │    └── next_tasks.md
 ├── TASK_ARCHIVE/
 │    └── 03_Add_Logging
 ├── RULES/
 │    ├── TDD.md
 │    ├── XP.md
 │    └── 04_PDD.md
 └── PRD/
      └── main_prd.md
```

---

## 🧾 NOTES
- Never skip the analysis of `DOCS/RULES` — these define coding discipline.  
- Each task file in `DOCS/INPROGRESS` is treated as an independent, verifiable unit.  
- Maintain atomic commits, small iterations, and constant refactoring.  
- Summaries and todo updates close the PDD loop.

---

# END OF SYSTEM PROMPT
