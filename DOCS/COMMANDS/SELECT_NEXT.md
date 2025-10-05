# SYSTEM PROMPT: Select the Next Task

## 🧩 PURPOSE
Automatically determine and initialize the next task to work on, following the predefined project rules and available task notes.

---

## 🎯 GOAL
Read and apply the selection rules from `DOCS/RULES`, analyze pending tasks listed in `DOCS/INPROGRESS/next_tasks.md`, and create a new task document containing its title and a lightweight PRD outline based on the main project documentation.

---

## ⚙️ EXECUTION STEPS

### Step 1. Read Task Selection Rules
- Open the folder `DOCS/RULES/`.
- Find the Markdown document that defines how to choose the next task (e.g., prioritization, dependencies, urgency).
- Parse and understand its logic or priority criteria.

### Step 2. Inspect Pending Tasks
- Check if `DOCS/INPROGRESS/next_tasks.md` exists.
- If present, read the file and extract the listed upcoming tasks or ideas.

### Step 3. Apply Selection Rules
- Use the criteria from Step 1 to determine which task should be selected next.
- If multiple tasks qualify, choose the one with the highest priority according to the rules.
- If no tasks are found in `next_tasks.md`, the system may refer to other `todo` or `tasks` files in the project for fallback options from the file `/DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` `⁨⁩DOCS⁩/AI/ISOViewer⁩` folder from its section "## 5) Detailed TODO (execution-ready, без кода)" on the line 122.

### Step 4. Create a New Task Document
- Use the folder `DOCS/INPROGRESS/` as the target location.
- Create a new Markdown file with a name matching the chosen task, e.g.:
  ```
  DOCS/INPROGRESS/03_Implement_New_Feature.md
  ```
- Inside the new file, include a **lightweight PRD (Product Requirements Document)** derived from the main PRD and guides located in other DOCS subfolders.

### Step 5. PRD Content Template
The created file should include the following structure:
```
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
- DOCS/PRD/main_prd.md
- DOCS/GUIDES/*
- DOCS/RULES/*
```
- Keep it short, structured, and clear.

### Step 6. Report Result
- Output the name of the chosen task.
- Confirm that the new Markdown PRD file was successfully created in `DOCS/INPROGRESS`.

---

## ✅ EXPECTED OUTPUT
- A new file created in `DOCS/INPROGRESS` with the next task name and a lightweight PRD.
- The task is chosen according to the defined rules in `DOCS/RULES` and the notes in `next_tasks.md` and the todo in `/DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`.
- A short summary confirming the selected task and the applied rules.

---

## 🧠 EXAMPLE

**Before:**
```
DOCS/
 ├── RULES/
 │    └── task_selection_rules.md
 ├── INPROGRESS/
 │    └── next_tasks.md
 └── PRD/
      └── main_prd.md
```

**After:**
```
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

# END OF SYSTEM PROMPT
