# Smart Task Archiver Script Guide

## Overview

The `scripts/archive_completed_tasks.py` script provides intelligent, automated archival of completed work items from `DOCS/INPROGRESS` to `DOCS/TASK_ARCHIVE` based on task status parsing.

**Purpose:** Prevent accidental archival of active tasks by automatically classifying files based on explicit `Status:` fields in markdown.

## Quick Start

```bash
# Preview changes before executing (ALWAYS do this first!)
python3 scripts/archive_completed_tasks.py --dry-run

# Update Status for NEW/UNCLASSIFIED files interactively
python3 scripts/archive_completed_tasks.py --interactive --dry-run

# Get JSON output for automation/monitoring
python3 scripts/archive_completed_tasks.py --dry-run --format json

# Execute archival if dry-run output looks correct
python3 scripts/archive_completed_tasks.py

# Commit the changes
git add DOCS/INPROGRESS/ DOCS/TASK_ARCHIVE/
git commit -m "Archive completed tasks"
```

## Command-Line Options

### `--dry-run` (Recommended)

Preview all changes without moving any files or modifying the archive.

```bash
python3 scripts/archive_completed_tasks.py --dry-run
```

**Output includes:**
- Classification of all files (RESOLVED, IN PROGRESS, BLOCKED, NEW)
- **Validation warnings** for missing Status fields, malformed markdown, etc.
- Preview of archive folder that would be created
- Count of files in each category
- Which files would be archived vs. remaining

**Always run with `--dry-run` first** to verify intended behavior.

### `--interactive` / `-i` (New Feature)

Interactively update Status field for NEW/UNCLASSIFIED files.

```bash
python3 scripts/archive_completed_tasks.py --interactive --dry-run
```

**How it works:**
1. Script identifies all files missing Status field
2. For each file, displays objective/description and prompts:
   - `1) IN PROGRESS` - Mark as actively being worked on
   - `2) BLOCKED` - Mark as blocked/waiting
   - `3) RESOLVED` - Mark as completed
   - `s) Skip` - Leave this file unchanged
   - `q) Quit` - Exit interactive mode
3. Automatically updates the markdown file with chosen Status
4. Continues with archival workflow

**Use when:**
- Multiple new bug reports created without Status fields
- Validation warnings show many "Missing Status field" issues
- Want to bulk-update task statuses quickly

### `--format` / `-f` (New Feature)

Output format for reports: `text` (default), `json`, or `csv`.

```bash
# JSON format for automation/monitoring
python3 scripts/archive_completed_tasks.py --dry-run --format json

# CSV format for spreadsheet analysis
python3 scripts/archive_completed_tasks.py --dry-run --format csv > report.csv
```

**Text format** (default):
- Human-readable with emoji indicators
- Validation warnings section
- Interactive tips and suggestions
- Git commit command

**JSON format**:
- Machine-readable structured data
- Includes: timestamp, archive_folder, summary stats, file lists, warnings
- Perfect for CI/monitoring/automation pipelines
- Can be parsed with `jq` or other JSON tools

**CSV format**:
- Spreadsheet-compatible output
- Columns: File, Status, Category, Objective
- Import into Excel, Google Sheets, etc.
- Good for reporting and analysis

### `--repo-root PATH` (Optional)

Specify the repository root directory. Default: current directory.

```bash
python3 scripts/archive_completed_tasks.py --repo-root /path/to/repo
```

## How It Works

### 1. Status Field Parsing

The script searches each `.md` file in `DOCS/INPROGRESS` for a `Status:` field:

```markdown
# Bug Report 233
**Date Reported**: 2025-11-17
**Status**: RESOLVED  ← This field is parsed
**Severity**: MEDIUM
```

**Supported formats:**
- `**Status**: RESOLVED` (bold with markdown)
- `Status: RESOLVED` (plain text)
- `Status: IN PROGRESS` (multi-word status)
- Case-insensitive: `status:`, `STATUS:`, `**status**:` all work

### 2. File Classification

Files are categorized into four groups:

| Category | Statuses | Action |
|----------|----------|--------|
| **RESOLVED** | `RESOLVED`, `COMPLETED`, `DONE` | Will be archived |
| **ACTIVE** | `IN PROGRESS`, `IN_PROGRESS`, `INPROGRESS` | Stays in INPROGRESS |
| **BLOCKED** | `BLOCKED` | Stays in INPROGRESS |
| **NEW** | No Status field, or unrecognized status | Stays in INPROGRESS |

### 3. Validation Warnings (New Feature)

Script validates each markdown file and reports issues:

**Detected issues:**
- Missing Status field
- Empty or very short files (<50 characters)
- Missing objective/description
- Missing markdown heading

**Example warning output:**
```
⚠️  Validation Warnings (8):
   ⚠️  234_Remove_Recent_File_From_Sidebar.md: Missing Status field
   ⚠️  235_System_Notification_For_Export.md: Missing Status field
```

Use `--interactive` mode to quickly fix "Missing Status field" warnings.

### 4. Archive Folder Creation

Script automatically:
- Calculates next sequential folder number (e.g., 231, 232, 233)
- Creates descriptive folder name based on resolved files
- Generates summary entry in `ARCHIVE_SUMMARY.md`

**Naming convention:**
- Single resolved file: Use its number and name: `231_SwiftUI_Publishing_Changes_Warning_Fix`
- Multiple resolved files: Use generic name: `232_Resolved_Tasks_Batch`

## Status Field Convention

### For New Task Files

When creating a new task/bug report, include a `Status:` field:

```markdown
# Bug Report 234: Example Issue

**Date Reported**: 2025-11-17
**Severity**: HIGH
**Status**: IN PROGRESS

## Objective
Describe what needs to be fixed or implemented.

## Symptoms
Describe the current behavior.

## Expected Behavior
Describe the desired outcome.
```

### Status Values Reference

| Status | Meaning | Archival |
|--------|---------|----------|
| `RESOLVED` | Task completed and verified | ✅ Will be archived |
| `COMPLETED` | Synonym for RESOLVED | ✅ Will be archived |
| `DONE` | Synonym for RESOLVED | ✅ Will be archived |
| `IN PROGRESS` | Actively being worked on | ❌ Stays in INPROGRESS |
| `IN_PROGRESS` | Alternative format | ❌ Stays in INPROGRESS |
| `INPROGRESS` | Alternative format | ❌ Stays in INPROGRESS |
| `BLOCKED` | Cannot proceed without external work | ❌ Stays in INPROGRESS |
| (no Status) | New task without status assigned | ❌ Stays as NEW |

### Updating Status When Resolving Tasks

When a task is complete:

1. Open the task file in `DOCS/INPROGRESS`
2. Update the `Status:` field:
   ```markdown
   **Status**: RESOLVED  ← Change this
   ```
3. Save the file
4. Run archival script with `--dry-run` to verify
5. Execute archival

## Understanding the Output

### Dry-Run Output Example

```
🤖 SMART TASK ARCHIVER
======================================================================

📋 Scanning 10 markdown files...
   Next archive folder number: 232

  ✅ RESOLVED: 233_SwiftUI_Publishing_Changes_Warning_Fix.md
     → Fixed SwiftUI runtime warning in IntegritySummaryViewModel

  ⏳ IN PROGRESS: 231_MacOS_iPadOS_MultiWindow_SharedState_Bug.md
     → Fix multi-window state sharing where changes affect all windows

  ⏳ IN PROGRESS: 232_UI_Content_Not_Displayed_After_File_Selection.md
     → Fix regression where UI content not displayed after file select

  🆕 NEW/UNCLASSIFIED (Status: UNKNOWN): 234_Remove_Recent_File_From_Sidebar.md
     → Document missing affordance for deleting recent file entries

...

✓ Dry run complete. Use without --dry-run to execute archival.
```

### Understanding the Symbols

- `✅ RESOLVED` - File will be moved to archive folder
- `⏳ IN PROGRESS` - File will remain in DOCS/INPROGRESS
- `🚫 BLOCKED` - File will remain in DOCS/INPROGRESS
- `🆕 NEW/UNCLASSIFIED` - File will remain in DOCS/INPROGRESS (mark Status if you know it)

## Workflow Examples

### Example 1: Archive a Resolved Bug

```bash
# 1. Check current status
python3 scripts/archive_completed_tasks.py --dry-run

# Output shows:
# ✅ RESOLVED: 233_SwiftUI_Publishing_Changes_Warning_Fix.md

# 2. Execute if satisfied with preview
python3 scripts/archive_completed_tasks.py

# 3. Commit the changes
git add DOCS/INPROGRESS/ DOCS/TASK_ARCHIVE/
git commit -m "Archive resolved bug #233"
git push
```

### Example 2: Mixed Scenario

You have:
- 2 RESOLVED tasks (should archive)
- 3 IN PROGRESS tasks (keep)
- 5 NEW bug reports (keep for planning)

```bash
# Preview
python3 scripts/archive_completed_tasks.py --dry-run

# Output shows count and which files
# Resolved & Archived: 2 files
# Remaining In Progress: 3 files
# New/Unclassified: 5 files

# Execute if correct
python3 scripts/archive_completed_tasks.py
```

## Troubleshooting

### "No resolved tasks to archive"

This means no files have `Status: RESOLVED` or `Status: COMPLETED`.

**Solution:** Either:
1. Mark completed tasks with the correct Status field
2. Or this is expected if all active work is still in progress

### Script found wrong status for a file

**Cause:** Status field not found or misformatted.

**Solution:**
1. Check that Status field exists in the file
2. Verify format: `**Status**: XXXXX` or `Status: XXXXX`
3. Ensure it's within first 50 lines of the file
4. Ensure it's on its own line (not buried in a paragraph)

### Files in INPROGRESS that should have been archived

**Cause:** Status field not set to RESOLVED/COMPLETED.

**Solution:**
1. Open the file
2. Add/update Status field to `RESOLVED`
3. Rerun the script

## Integration with CI/CD

The script is automatically tested in CI via `.github/workflows/script-tests.yml`:

- **Syntax validation:** Python compilation check
- **Unit tests:** 30+ unit tests covering all classification logic
- **Integration test:** Dry-run on actual repo to verify no errors
- **Multi-version testing:** Tests on Python 3.10, 3.11, 3.12

To run tests locally:

```bash
# Run all unit tests
python -m unittest discover -s scripts/tests -p "test_*.py" -v

# Run specific test class
python -m unittest scripts.tests.test_archive_completed_tasks.StatusExtractionTests
```

## Best Practices

### ✅ DO

- Run with `--dry-run` **every time** before executing
- Mark completed tasks with clear Status field
- Review dry-run output to verify what will be archived
- Commit archival changes with descriptive message
- Check that DOCS/INPROGRESS still contains active tasks after archival

### ❌ DON'T

- Skip the `--dry-run` step
- Archive tasks with `Status: IN PROGRESS`
- Forget to update Status field before archival
- Archive files without explicit Status (mark them first)
- Archive new bug reports (keep them in INPROGRESS for planning)

## Technical Implementation

### Architecture

```
TaskArchiver
├── extract_status(content) → str
│   └── Parse **Status**: field from markdown
├── extract_objective(content) → str
│   └── Extract task description for summary
├── classify_files() → None
│   └── Categorize all files by status
├── get_next_folder_number() → int
│   └── Calculate next sequential archive folder
├── create_archive_folder() → Path
│   └── Create new archive folder with auto-generated name
├── archive_files(folder) → None
│   └── Move resolved files to archive
├── update_archive_summary(folder) → None
│   └── Append entry to ARCHIVE_SUMMARY.md
└── run() → bool
    └── Execute complete workflow
```

### Status Normalization

Status values are normalized for comparison:
- Spaces replaced with underscores
- Converted to uppercase
- Aliases handled: IN PROGRESS → IN_PROGRESS

This allows flexible input formats while maintaining strict validation.

## See Also

- [ARCHIVE.md](./ARCHIVE.md) - Main archival command documentation
- [.github/workflows/script-tests.yml](../../.github/workflows/script-tests.yml) - CI testing configuration
- [scripts/tests/test_archive_completed_tasks.py](../../scripts/tests/test_archive_completed_tasks.py) - Unit test suite
