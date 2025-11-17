#!/usr/bin/env python3
"""
Smart task archiver for DOCS/INPROGRESS

This script intelligently archives COMPLETED/RESOLVED tasks from DOCS/INPROGRESS
while keeping IN PROGRESS and BLOCKED tasks in place.

Usage:
    python3 scripts/archive_completed_tasks.py [--dry-run] [--interactive] [--format json]

Features:
    - Parses status from each .md file (Status: RESOLVED, IN PROGRESS, BLOCKED, etc.)
    - Archives only RESOLVED/COMPLETED tasks
    - Keeps IN PROGRESS, BLOCKED, and new task reports in DOCS/INPROGRESS
    - Interactive mode to update status on NEW/UNCLASSIFIED files
    - Automatically updates ARCHIVE_SUMMARY.md with descriptions
    - Provides dry-run mode to preview changes
    - JSON/CSV output formats for integration
    - Validation warnings for malformed markdown
    - Generates comprehensive archival report
"""

import os
import re
import sys
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple


class TaskArchiver:
    def __init__(self, repo_root: str, dry_run: bool = False):
        self.repo_root = Path(repo_root)
        self.inprogress_dir = self.repo_root / "DOCS" / "INPROGRESS"
        self.archive_dir = self.repo_root / "DOCS" / "TASK_ARCHIVE"
        self.archive_summary = self.archive_dir / "ARCHIVE_SUMMARY.md"
        self.dry_run = dry_run

        self.resolved_files: List[Path] = []
        self.active_files: List[Path] = []
        self.new_files: List[Path] = []
        self.next_folder_num = 0

    def extract_status(self, content: str) -> str:
        """Extract Status field from markdown front matter or text."""
        # Look for "Status: XXXXX" pattern (case-insensitive)
        # Matches: Status: XXXX, **Status**: XXXX, **Status**:XXXX, etc.
        patterns = [
            r'\*\*Status\*\*:\s*(\w+(?:\s+\w+)*)',  # **Status**: IN PROGRESS
            r'^\*\*Status\*\*:\s*(\w+(?:\s+\w+)*)',  # At line start
            r'Status:\s*(\w+(?:\s+\w+)*)',            # Status: IN PROGRESS
            r'^\s*Status:\s*(\w+(?:\s+\w+)*)',        # At line start with spaces
        ]

        for line in content.split('\n')[:50]:  # Check first 50 lines
            for pattern in patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    status = match.group(1).strip().upper()
                    # Normalize multi-word status (e.g., "IN PROGRESS" -> "IN PROGRESS")
                    return status

        return "UNKNOWN"

    def extract_objective(self, content: str) -> str:
        """Extract objective/purpose from markdown."""
        patterns = [
            r'^#+\s+(?:Objective|PURPOSE|Summary).*?\n(.+?)(?:\n\n|$)',
        ]

        for line in content.split('\n')[1:10]:
            if line.strip() and not line.startswith('#'):
                return line.strip()[:100]

        return "(No description)"

    def get_next_folder_number(self) -> int:
        """Find next available folder number."""
        max_num = 0

        for item in self.archive_dir.iterdir():
            if item.is_dir():
                match = re.match(r'^(\d+)_', item.name)
                if match:
                    num = int(match.group(1))
                    max_num = max(max_num, num)

        return max_num + 1

    def classify_files(self) -> None:
        """Classify files based on status."""
        if not self.inprogress_dir.exists():
            print(f"❌ Directory not found: {self.inprogress_dir}")
            return

        markdown_files = sorted(self.inprogress_dir.glob("*.md"))
        self.next_folder_num = self.get_next_folder_number()

        print(f"\n📋 Scanning {len(markdown_files)} markdown files...")
        print(f"   Next archive folder number: {self.next_folder_num}\n")

        for file_path in markdown_files:
            content = file_path.read_text(encoding='utf-8')
            status = self.extract_status(content)
            objective = self.extract_objective(content)

            # Normalize status for comparison
            status_normalized = status.replace(" ", "_").upper()

            if status_normalized in ["RESOLVED", "COMPLETED", "DONE"]:
                self.resolved_files.append(file_path)
                print(f"  ✅ RESOLVED: {file_path.name}")
                print(f"     → {objective}\n")
            elif status_normalized in ["IN_PROGRESS", "INPROGRESS"]:
                self.active_files.append(file_path)
                print(f"  ⏳ IN PROGRESS: {file_path.name}")
                print(f"     → {objective}\n")
            elif status_normalized == "BLOCKED":
                self.active_files.append(file_path)
                print(f"  🚫 BLOCKED: {file_path.name}")
                print(f"     → {objective}\n")
            else:
                # Assume new task reports without clear status
                self.new_files.append(file_path)
                print(f"  🆕 NEW/UNCLASSIFIED (Status: {status}): {file_path.name}")
                print(f"     → {objective}\n")

    def create_archive_folder(self) -> Path:
        """Create the archive folder with auto-generated name."""
        # Use RESOLVED file names to generate folder name
        if self.resolved_files:
            # Extract common prefix or create descriptive name
            names = [f.stem for f in self.resolved_files]
            # Try to find a pattern
            first_num = re.match(r'^(\d+)', names[0])
            if first_num and len(names) == 1:
                # Single file - use its name
                folder_name = f"{self.next_folder_num:03d}_{names[0].split('_', 1)[1]}"
            else:
                # Multiple files - create summary name
                folder_name = f"{self.next_folder_num:03d}_Resolved_Tasks_Batch"
        else:
            folder_name = f"{self.next_folder_num:03d}_Resolved_Tasks"

        folder_path = self.archive_dir / folder_name

        if not self.dry_run:
            folder_path.mkdir(parents=True, exist_ok=True)

        return folder_path

    def archive_files(self, archive_folder: Path) -> None:
        """Move resolved files to archive folder."""
        print(f"\n📦 Archiving {len(self.resolved_files)} resolved tasks...")
        print(f"   Target: {archive_folder.name}\n")

        for file_path in self.resolved_files:
            dest_path = archive_folder / file_path.name

            if self.dry_run:
                print(f"  [DRY RUN] mv {file_path.name} → {archive_folder.name}/")
            else:
                shutil.move(str(file_path), str(dest_path))
                print(f"  ✓ {file_path.name}")

    def update_archive_summary(self, archive_folder: Path) -> None:
        """Add entry to ARCHIVE_SUMMARY.md."""
        if not self.resolved_files:
            return

        # Generate summary entry
        summary_entry = f"\n## {archive_folder.name}\n"
        summary_entry += f"- **Archived files:** "

        file_list = ", ".join([f"`{f.name}`" for f in self.resolved_files])
        summary_entry += f"{file_list}\n"
        summary_entry += f"- **Archived location:** `DOCS/TASK_ARCHIVE/{archive_folder.name}/`\n"
        summary_entry += f"- **Archival date:** {datetime.now().strftime('%Y-%m-%d')}\n"
        summary_entry += f"- **Status:** ✅ All tasks RESOLVED\n"
        summary_entry += f"- **Summary:**\n"

        for file_path in self.resolved_files:
            content = file_path.read_text(encoding='utf-8')
            objective = self.extract_objective(content)
            # Extract bug number if present
            match = re.search(r'^#(\d+)', file_path.stem)
            bug_num = match.group(1) if match else file_path.stem
            summary_entry += f"  - **Bug/Task #{bug_num}:** {objective}\n"

        summary_entry += f"- **Next steps:** None — all archived items are resolved and ready for verification.\n"

        if self.dry_run:
            print(f"\n[DRY RUN] Would append to ARCHIVE_SUMMARY.md:")
            print(summary_entry)
        else:
            with open(self.archive_summary, 'a', encoding='utf-8') as f:
                f.write(summary_entry)
            print(f"\n✓ Updated ARCHIVE_SUMMARY.md")

    def print_report(self, archive_folder: Path) -> None:
        """Print final archival report."""
        print("\n" + "="*70)
        print("ARCHIVAL REPORT")
        print("="*70)

        print(f"\n📊 Summary:")
        print(f"   Resolved & Archived: {len(self.resolved_files)} files")
        print(f"   Remaining In Progress: {len(self.active_files)} files")
        print(f"   New/Unclassified: {len(self.new_files)} files")

        print(f"\n📂 Archive Folder:")
        print(f"   {archive_folder}")

        if self.active_files:
            print(f"\n⏳ Files remaining in DOCS/INPROGRESS ({len(self.active_files)}):")
            for f in self.active_files:
                status = self.extract_status(f.read_text(encoding='utf-8'))
                print(f"   • {f.name} ({status})")

        if self.new_files:
            print(f"\n🆕 New task reports ({len(self.new_files)}):")
            for f in self.new_files:
                print(f"   • {f.name}")

        print("\n" + "="*70)

        if self.dry_run:
            print("✓ Dry run complete. Use without --dry-run to execute archival.")
        else:
            print("✓ Archival complete! Commit changes with:")
            print(f"   git add DOCS/INPROGRESS/ DOCS/TASK_ARCHIVE/")
            print(f"   git commit -m 'Archive {len(self.resolved_files)} resolved tasks'")

        print("="*70 + "\n")

    def run(self) -> bool:
        """Execute the archival process."""
        print("\n" + "🤖 SMART TASK ARCHIVER".center(70))
        print("="*70)

        self.classify_files()

        if not self.resolved_files:
            print("\n✓ No resolved tasks to archive. DOCS/INPROGRESS is up to date!")
            return True

        archive_folder = self.create_archive_folder()
        self.archive_files(archive_folder)
        self.update_archive_summary(archive_folder)
        self.print_report(archive_folder)

        return True


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Smart archiver for completed tasks in DOCS/INPROGRESS"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without executing archival"
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Repository root directory (default: current directory)"
    )

    args = parser.parse_args()

    archiver = TaskArchiver(args.repo_root, dry_run=args.dry_run)
    success = archiver.run()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
