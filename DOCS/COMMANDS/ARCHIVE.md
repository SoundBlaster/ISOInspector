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

### **RECOMMENDED: Use Smart Archiver Script (Step 1-5 automated)**

**The Python script automates all steps and prevents archiving IN PROGRESS tasks.**

```bash
# Dry-run mode (preview without changes)
python3 scripts/archive_completed_tasks.py --dry-run

# Execute archival
python3 scripts/archive_completed_tasks.py

# Then commit
git add DOCS/INPROGRESS/ DOCS/TASK_ARCHIVE/ && git commit -m "Archive completed tasks"
```

**The script automatically:**
- ✅ Parses `Status:` field from each .md file in DOCS/INPROGRESS
- ✅ Archives ONLY files marked `Status: RESOLVED` or `Status: COMPLETED`
- ✅ Keeps `IN PROGRESS`, `BLOCKED`, and `NEW` tasks in place
- ✅ Creates next sequential folder number (e.g., 231_Resolved_Tasks_Batch)
- ✅ Updates ARCHIVE_SUMMARY.md with descriptions
- ✅ Generates comprehensive archival report

**Dry-run output example:**
```
📋 Scanning 10 markdown files...
   Next archive folder number: 231

  ✅ RESOLVED: 233_SwiftUI_Publishing_Changes_Warning_Fix.md
  ⏳ IN PROGRESS: 231_MacOS_iPadOS_MultiWindow_SharedState_Bug.md
  ⏳ IN PROGRESS: 232_UI_Content_Not_Displayed_After_File_Selection.md
  🆕 NEW/UNCLASSIFIED: 234_Remove_Recent_File_From_Sidebar.md
  ...
```

---

### Manual Steps (if script unavailable)

### Step 1. Review and Classify Current In-Progress Files

- Run `ls DOCS/INPROGRESS/*.md` and list every file
- **For each file**, open it and find the `Status:` field (usually near top):
  - `Status: RESOLVED` or `Status: COMPLETED` → Archive it
  - `Status: IN PROGRESS` or `Status: IN_PROGRESS` → Keep in INPROGRESS
  - `Status: BLOCKED` → Keep in INPROGRESS (or move to BLOCKED/ if permanently stuck)
  - No Status field → Check dates and todo.md to determine if it's new/active

**Key distinction:** Only archive tasks explicitly marked RESOLVED/COMPLETED.

### Step 2. Classify Blocked Items

- Inspect [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) if it exists.
- For each entry decide:
  - **Recoverable blockers:** keep them in `blocked.md` and update wording if context changed.
  - **Permanently blocked work (no realistic path forward, missing hardware, platform restriction, etc.):**
    1. Create a new Markdown file under [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) summarizing the blocker, prerequisites to resume, and links to historical context.
    2. Remove the entry from `blocked.md` so the day-to-day list only contains recoverable items.
- Update [`DOCS/TASK_ARCHIVE/BLOCKED/README.md`](../TASK_ARCHIVE/BLOCKED/README.md) if guidance needs refinement.

### Step 3. Determine the Next Archive Folder Name

- Target base path: [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE).
- Folder naming pattern: `{NNN}_{Task_Name}` with three-digit zero padding.
- Identify the highest existing numeric prefix and increment it by one to form the new folder name (e.g., `231_Resolved_Tasks_Batch`).
- Create the folder if it does not exist.

### Step 4. Move Resolved Files Into the Archive

- Move ONLY files marked `Status: RESOLVED`/`COMPLETED` from [`DOCS/INPROGRESS`](../INPROGRESS) to the new archive folder.
- Preserve filenames exactly as-is.
- Update [`DOCS/TASK_ARCHIVE/ARCHIVE_SUMMARY.md`](../TASK_ARCHIVE/ARCHIVE_SUMMARY.md) with a new section describing the archived work and linking to the new folder.

### Step 5. Verify and Report Results

- Confirm `DOCS/INPROGRESS` still contains IN PROGRESS and new tasks (not empty).
- Record the path of the new archive folder and the count of archived files.
- Create a commit with clear message summarizing what was archived.

---

## ✅ EXPECTED OUTPUT

- A new sequential archive folder containing **only RESOLVED/COMPLETED tasks**.
- `DOCS/INPROGRESS` **still contains** all IN PROGRESS, BLOCKED, and NEW tasks (not empty).
- Archive summary automatically updated with descriptions and links.
- Comprehensive archival report showing:
  - Number of archived tasks (resolved)
  - Number of remaining in-progress tasks
  - Number of new unclassified tasks
  - Path to new archive folder
- Clear git commit ready for push.

**Example:**
```
================================================================================
ARCHIVAL REPORT
================================================================================

📊 Summary:
   Resolved & Archived: 1 files
   Remaining In Progress: 2 files
   New/Unclassified: 8 files

📂 Archive Folder:
   /home/user/ISOInspector/DOCS/TASK_ARCHIVE/231_SwiftUI_Publishing_Changes_Warning_Fix

⏳ Files remaining in DOCS/INPROGRESS (2):
   • 231_MacOS_iPadOS_MultiWindow_SharedState_Bug.md (IN PROGRESS)
   • 232_UI_Content_Not_Displayed_After_File_Selection.md (IN PROGRESS)

🆕 New task reports (8):
   • 234_Remove_Recent_File_From_Sidebar.md
   • 235_System_Notification_For_Export.md
   • 236_Box_Details_Default_Card_Selection.md
   • 237_Integrity_Report_Banner_Action.md
   • 238_VIR_Issue_Box_Tree_Scroll.md
   • 239_Missing_Box_Hex_Preview.md
   • 240_TKHD_Flags_Mismatch.md
   • 241_Box_Details_Mono_Font.md

================================================================================
✓ Archival complete! Commit changes with:
   git add DOCS/INPROGRESS/ DOCS/TASK_ARCHIVE/
   git commit -m 'Archive 1 resolved tasks'
================================================================================
```

---

## 🧠 TIPS & BEST PRACTICES

### Smart Archiver Script

- **Always use the script first** with `--dry-run` flag to preview changes before executing.
- The script automatically parses the `Status:` field, preventing accidental archival of active tasks.
- If a file lacks a `Status:` field, it's treated as NEW/UNCLASSIFIED and kept in INPROGRESS.
- Dry-run output clearly shows which tasks will be archived vs. kept.

### Status Field Convention

**Every task file should include a Status field near the top:**

```markdown
# Bug Report 234: Example Issue

**Date Reported**: 2025-11-17
**Severity**: HIGH
**Status**: IN PROGRESS  ← This line is parsed by the archiver
```

**Valid status values:**
- `Status: RESOLVED` or `Status: COMPLETED` → Will be archived
- `Status: IN PROGRESS` or `Status: IN_PROGRESS` → Will stay in INPROGRESS
- `Status: BLOCKED` → Will stay in INPROGRESS (or move to BLOCKED/ if permanent)
- No Status field → Treated as NEW, stays in INPROGRESS

### When to Archive

**Archive when:**
- [ ] Task is explicitly marked `Status: RESOLVED` or `Status: COMPLETED`
- [ ] All work is merged and verified in main branch
- [ ] No follow-up tasks remain in INPROGRESS
- [ ] Archive summary entry is auto-generated and verified

**Never archive:**
- ❌ Tasks with `Status: IN PROGRESS`
- ❌ Tasks with `Status: BLOCKED` (unless moving to permanent BLOCKED/ archive)
- ❌ New bug reports or feature requests (unless explicitly resolved)
- ❌ Files without a clear Status field (mark them first)

### Numbering & Naming

- Keep folder numbers contiguous; never reuse or skip numbers.
- Use sequential three-digit format: `001`, `002`, ..., `231`, `232`, etc.
- Folder name should reflect the content: `231_Resolved_Tasks_Batch`, `232_Bug_Fixes_November`, etc.
- Single resolved file: Use the task number/name: `231_SwiftUI_Publishing_Changes_Warning_Fix`

### Manual Review (If Script Unavailable)

If the Python script is unavailable:
1. Manually read the `Status:` field from each file
2. Create a list of files to archive (RESOLVED/COMPLETED only)
3. Create a list of files to keep (IN PROGRESS, BLOCKED, NEW)
4. Follow manual steps 3-5 in "EXECUTION STEPS" above
5. Update ARCHIVE_SUMMARY.md with descriptions

### Preventing Future Confusion

The new script-driven approach prevents the previous confusion by:
- ✅ Automatically parsing status instead of relying on manual judgment
- ✅ Providing dry-run preview before any changes
- ✅ Clearly reporting which files stay vs. archive
- ✅ Handling edge cases (missing Status field → treated as NEW)
- ✅ Generating consistent archive entries and numbering

---

## END OF SYSTEM PROMPT

At the end of working ensure Markdown formatting is consistent. The legacy helper script `scripts/fix_markdown.py` has been retired.

## 📜 SCRIPT REFERENCE

**Location:** `scripts/archive_completed_tasks.py`

**Full documentation:** See [`ARCHIVE_SCRIPT_GUIDE.md`](./ARCHIVE_SCRIPT_GUIDE.md)

**Usage:**
```bash
python3 scripts/archive_completed_tasks.py [--dry-run] [--repo-root .]
```

**Options:**
- `--dry-run`: Preview changes without executing (recommended first step)
- `--repo-root`: Specify repository root (default: current directory)

**Output:**
- Classification of all .md files in DOCS/INPROGRESS by status
- Archival report with counts and file paths
- Automatic ARCHIVE_SUMMARY.md updates
- Ready-to-use git commit command

## 🧪 TESTING

The script is tested automatically in CI and has comprehensive unit tests:

**Test coverage:**
- ✅ Status field extraction (all formats and edge cases)
- ✅ File classification (RESOLVED, IN PROGRESS, BLOCKED, NEW)
- ✅ Archive folder numbering and naming
- ✅ Dry-run mode (no side effects)
- ✅ Integration tests (complete workflow)

**Run tests locally:**
```bash
python -m unittest discover -s scripts/tests -p "test_archive*.py" -v
```

**CI configuration:** `.github/workflows/script-tests.yml`
- Runs on Python 3.10, 3.11, 3.12
- Tests on push to main/develop/claude/* branches
- Validates syntax and style
- Runs dry-run on actual repository

## 📚 RELATED DOCUMENTATION

- [`ARCHIVE_SCRIPT_GUIDE.md`](./ARCHIVE_SCRIPT_GUIDE.md) - Detailed script guide with examples
- `.github/workflows/script-tests.yml` - CI testing configuration
- `scripts/tests/test_archive_completed_tasks.py` - Unit test suite (19 tests)
