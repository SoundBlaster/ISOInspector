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
import json
import csv
import io
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional


class TaskArchiver:
    def __init__(self, repo_root: str, dry_run: bool = False, interactive: bool = False,
                 output_format: str = "text"):
        self.repo_root = Path(repo_root)
        self.inprogress_dir = self.repo_root / "DOCS" / "INPROGRESS"
        self.archive_dir = self.repo_root / "DOCS" / "TASK_ARCHIVE"
        self.archive_summary = self.archive_dir / "ARCHIVE_SUMMARY.md"
        self.dry_run = dry_run
        self.interactive = interactive
        self.output_format = output_format

        self.resolved_files: List[Path] = []
        self.active_files: List[Path] = []
        self.new_files: List[Path] = []
        self.next_folder_num = 0
        self.warnings: List[str] = []

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

    def validate_markdown(self, file_path: Path, content: str) -> List[str]:
        """Validate markdown file and return list of warnings."""
        warnings = []

        # Check for missing Status field
        status = self.extract_status(content)
        if status == "UNKNOWN":
            warnings.append(f"⚠️  {file_path.name}: Missing Status field")

        # Check for empty or very short files
        if len(content.strip()) < 50:
            warnings.append(f"⚠️  {file_path.name}: File content is suspiciously short (<50 chars)")

        # Check for missing objective/description
        objective = self.extract_objective(content)
        if objective == "(No description)":
            warnings.append(f"⚠️  {file_path.name}: No clear objective/description found")

        # Check for common markdown issues
        if not content.startswith('#'):
            warnings.append(f"⚠️  {file_path.name}: Missing markdown heading")

        return warnings

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

    def update_file_status(self, file_path: Path, new_status: str) -> bool:
        """Update Status field in markdown file."""
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')

            # Find and update existing Status line
            updated = False
            for i, line in enumerate(lines):
                if re.search(r'\*\*Status\*\*:', line, re.IGNORECASE):
                    lines[i] = f"**Status**: {new_status}"
                    updated = True
                    break
                elif re.search(r'^Status:', line, re.IGNORECASE):
                    lines[i] = f"**Status**: {new_status}"
                    updated = True
                    break

            # If no Status line found, add it after the first heading
            if not updated:
                for i, line in enumerate(lines):
                    if line.startswith('#'):
                        # Insert after heading
                        lines.insert(i + 1, f"\n**Status**: {new_status}")
                        updated = True
                        break

            if updated and not self.dry_run:
                file_path.write_text('\n'.join(lines), encoding='utf-8')
                return True
            return updated
        except Exception as e:
            print(f"❌ Error updating {file_path.name}: {e}")
            return False

    def interactive_update_status(self) -> None:
        """Interactively update status for NEW/UNCLASSIFIED files."""
        if not self.new_files:
            print("\n✓ No NEW/UNCLASSIFIED files to update!")
            return

        print(f"\n🔄 Interactive Mode: Updating {len(self.new_files)} NEW/UNCLASSIFIED files\n")
        print("Available statuses:")
        print("  1) IN PROGRESS")
        print("  2) BLOCKED")
        print("  3) RESOLVED")
        print("  s) Skip this file")
        print("  q) Quit interactive mode\n")

        updated_count = 0
        for file_path in self.new_files[:]:  # Copy list to allow removal
            content = file_path.read_text(encoding='utf-8')
            objective = self.extract_objective(content)

            print(f"\n📄 {file_path.name}")
            print(f"   {objective}")

            while True:
                choice = input("\n   Select status (1/2/3/s/q): ").strip().lower()

                if choice == 'q':
                    print("\n⏸️  Exiting interactive mode")
                    return
                elif choice == 's':
                    print("   ⏭️  Skipped")
                    break
                elif choice == '1':
                    if self.update_file_status(file_path, "IN PROGRESS"):
                        print("   ✓ Updated to IN PROGRESS")
                        self.new_files.remove(file_path)
                        self.active_files.append(file_path)
                        updated_count += 1
                    break
                elif choice == '2':
                    if self.update_file_status(file_path, "BLOCKED"):
                        print("   ✓ Updated to BLOCKED")
                        self.new_files.remove(file_path)
                        self.active_files.append(file_path)
                        updated_count += 1
                    break
                elif choice == '3':
                    if self.update_file_status(file_path, "RESOLVED"):
                        print("   ✓ Updated to RESOLVED")
                        self.new_files.remove(file_path)
                        self.resolved_files.append(file_path)
                        updated_count += 1
                    break
                else:
                    print("   Invalid choice. Please enter 1, 2, 3, s, or q")

        print(f"\n✅ Updated {updated_count} file(s)")

    def classify_files(self) -> None:
        """Classify files based on status."""
        if not self.inprogress_dir.exists():
            if self.output_format == "text":
                print(f"❌ Directory not found: {self.inprogress_dir}")
            return

        markdown_files = sorted(self.inprogress_dir.glob("*.md"))
        self.next_folder_num = self.get_next_folder_number()

        if self.output_format == "text":
            print(f"\n📋 Scanning {len(markdown_files)} markdown files...")
            print(f"   Next archive folder number: {self.next_folder_num}\n")

        for file_path in markdown_files:
            content = file_path.read_text(encoding='utf-8')
            status = self.extract_status(content)
            objective = self.extract_objective(content)

            # Validate markdown and collect warnings
            file_warnings = self.validate_markdown(file_path, content)
            self.warnings.extend(file_warnings)

            # Normalize status for comparison
            status_normalized = status.replace(" ", "_").upper()

            if status_normalized in ["RESOLVED", "COMPLETED", "DONE"]:
                self.resolved_files.append(file_path)
                if self.output_format == "text":
                    print(f"  ✅ RESOLVED: {file_path.name}")
                    print(f"     → {objective}\n")
            elif status_normalized in ["IN_PROGRESS", "INPROGRESS"]:
                self.active_files.append(file_path)
                if self.output_format == "text":
                    print(f"  ⏳ IN PROGRESS: {file_path.name}")
                    print(f"     → {objective}\n")
            elif status_normalized == "BLOCKED":
                self.active_files.append(file_path)
                if self.output_format == "text":
                    print(f"  🚫 BLOCKED: {file_path.name}")
                    print(f"     → {objective}\n")
            else:
                # Assume new task reports without clear status
                self.new_files.append(file_path)
                if self.output_format == "text":
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

        for idx, file_path in enumerate(self.resolved_files):
            dest_path = archive_folder / file_path.name

            if self.dry_run:
                print(f"  [DRY RUN] mv {file_path.name} → {archive_folder.name}/")
            else:
                shutil.move(str(file_path), str(dest_path))
                # Update the stored path so later steps (like summary generation)
                # read from the new archive location instead of the now-missing
                # source file path.
                self.resolved_files[idx] = dest_path
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

    def generate_json_report(self, archive_folder: Path) -> str:
        """Generate JSON format report."""
        report = {
            "timestamp": datetime.now().isoformat(),
            "archive_folder": str(archive_folder),
            "summary": {
                "resolved_archived": len(self.resolved_files),
                "in_progress": len(self.active_files),
                "new_unclassified": len(self.new_files)
            },
            "resolved_files": [f.name for f in self.resolved_files],
            "active_files": [
                {"name": f.name, "status": self.extract_status(f.read_text(encoding='utf-8'))}
                for f in self.active_files
            ],
            "new_files": [f.name for f in self.new_files],
            "warnings": self.warnings,
            "dry_run": self.dry_run
        }
        return json.dumps(report, indent=2)

    def generate_csv_report(self, archive_folder: Path) -> str:
        """Generate CSV format report."""
        output = io.StringIO()
        writer = csv.writer(output)

        writer.writerow(["File", "Status", "Category", "Objective"])

        for f in self.resolved_files:
            content = f.read_text(encoding='utf-8')
            writer.writerow([f.name, "RESOLVED", "Archived", self.extract_objective(content)])

        for f in self.active_files:
            content = f.read_text(encoding='utf-8')
            status = self.extract_status(content)
            writer.writerow([f.name, status, "Active", self.extract_objective(content)])

        for f in self.new_files:
            content = f.read_text(encoding='utf-8')
            writer.writerow([f.name, "UNKNOWN", "New", self.extract_objective(content)])

        return output.getvalue()

    def print_report(self, archive_folder: Path) -> None:
        """Print final archival report."""
        if self.output_format == "json":
            print(self.generate_json_report(archive_folder))
            return
        elif self.output_format == "csv":
            print(self.generate_csv_report(archive_folder))
            return

        # Text format (default)
        print("\n" + "="*70)
        print("ARCHIVAL REPORT")
        print("="*70)

        print(f"\n📊 Summary:")
        print(f"   Resolved & Archived: {len(self.resolved_files)} files")
        print(f"   Remaining In Progress: {len(self.active_files)} files")
        print(f"   New/Unclassified: {len(self.new_files)} files")

        print(f"\n📂 Archive Folder:")
        print(f"   {archive_folder}")

        if self.warnings:
            print(f"\n⚠️  Validation Warnings ({len(self.warnings)}):")
            for warning in self.warnings[:10]:  # Show first 10
                print(f"   {warning}")
            if len(self.warnings) > 10:
                print(f"   ... and {len(self.warnings) - 10} more warnings")

        if self.active_files:
            print(f"\n⏳ Files remaining in DOCS/INPROGRESS ({len(self.active_files)}):")
            for f in self.active_files:
                status = self.extract_status(f.read_text(encoding='utf-8'))
                print(f"   • {f.name} ({status})")

        if self.new_files:
            print(f"\n🆕 New task reports ({len(self.new_files)}):")
            for f in self.new_files:
                print(f"   • {f.name}")
            if self.interactive:
                print("\n💡 Tip: Some files are missing Status field.")
                print("   The --interactive mode can help you update them!")

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
        if self.output_format == "text":
            print("\n" + "🤖 SMART TASK ARCHIVER".center(70))
            print("="*70)

        self.classify_files()

        # Run interactive mode if requested and there are NEW files
        if self.interactive and self.new_files:
            self.interactive_update_status()

        if not self.resolved_files:
            if self.output_format == "text":
                print("\n✓ No resolved tasks to archive. DOCS/INPROGRESS is up to date!")

            # Still generate report even if nothing to archive (for CI and monitoring)
            if self.output_format in ["json", "csv"]:
                # Create a dummy path for reporting
                dummy_folder = self.archive_dir / f"{self.next_folder_num:03d}_No_Tasks_To_Archive"
                self.print_report(dummy_folder)

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
        "--interactive", "-i",
        action="store_true",
        help="Interactively update status for NEW/UNCLASSIFIED files"
    )
    parser.add_argument(
        "--format", "-f",
        choices=["text", "json", "csv"],
        default="text",
        help="Output format for reports (default: text)"
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Repository root directory (default: current directory)"
    )

    args = parser.parse_args()

    archiver = TaskArchiver(
        args.repo_root,
        dry_run=args.dry_run,
        interactive=args.interactive,
        output_format=args.format
    )
    success = archiver.run()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
