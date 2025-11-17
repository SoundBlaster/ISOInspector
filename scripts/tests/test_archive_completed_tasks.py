"""
Unit tests for archive_completed_tasks.py

Tests the TaskArchiver class and its core functionality:
- Status extraction from markdown files
- File classification (RESOLVED, IN PROGRESS, BLOCKED, NEW)
- Objective extraction from markdown
- Next folder number calculation
- Archive folder creation and file movement
"""

import importlib.util
import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from tempfile import TemporaryDirectory

MODULE_PATH = Path(__file__).resolve().parents[1] / "archive_completed_tasks.py"
spec = importlib.util.spec_from_file_location("scripts.archive_completed_tasks", MODULE_PATH)
archive_completed_tasks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(archive_completed_tasks)


class StatusExtractionTests(unittest.TestCase):
    """Test Status field extraction from markdown content."""

    def test_resolved_status_with_bold_markers(self) -> None:
        """Test extraction of **Status**: RESOLVED format."""
        content = """# Bug Report 233
**Date Reported**: 2025-11-17
**Status**: RESOLVED
**Severity**: MEDIUM
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "RESOLVED")

    def test_in_progress_status_with_spaces(self) -> None:
        """Test extraction of 'IN PROGRESS' (multi-word) status."""
        content = """# Bug Report 231
**Status**: IN PROGRESS
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "IN PROGRESS")

    def test_blocked_status(self) -> None:
        """Test extraction of BLOCKED status."""
        content = """# Task Report
**Status**: BLOCKED
**Reason**: Missing hardware
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "BLOCKED")

    def test_completed_status_variant(self) -> None:
        """Test extraction of COMPLETED (variant of RESOLVED)."""
        content = """# Feature Task
**Status**: COMPLETED
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "COMPLETED")

    def test_missing_status_returns_unknown(self) -> None:
        """Test that missing Status field returns UNKNOWN."""
        content = """# New Bug Report
**Date Reported**: 2025-11-17
## Symptoms
This is a new bug without status.
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "UNKNOWN")

    def test_status_case_insensitive(self) -> None:
        """Test that status extraction is case-insensitive."""
        content = """# Report
**status**: resolved
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "RESOLVED")

    def test_status_without_bold_markers(self) -> None:
        """Test extraction of Status: format without bold markers."""
        content = """# Report
Status: IN PROGRESS
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        status = archiver.extract_status(content)
        self.assertEqual(status, "IN PROGRESS")


class ObjectiveExtractionTests(unittest.TestCase):
    """Test objective/purpose extraction from markdown."""

    def test_objective_from_h2_heading(self) -> None:
        """Test extraction of objective from ## Objective heading."""
        content = """# Bug Report
## Objective
Fix the critical state sharing issue in multi-window mode.
## Symptoms
Users report that state changes affect all windows.
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        objective = archiver.extract_objective(content)
        self.assertIn("state sharing", objective.lower())

    def test_objective_truncated_if_too_long(self) -> None:
        """Test that objectives are truncated to 100 chars."""
        content = """# Bug Report
## Objective
This is a very long objective description that should be truncated because it exceeds the maximum length allowed for display purposes in the archival report.
"""
        archiver = archive_completed_tasks.TaskArchiver(".")
        objective = archiver.extract_objective(content)
        self.assertLessEqual(len(objective), 110)  # Allow some buffer


class FileClassificationTests(unittest.TestCase):
    """Test file classification by status."""

    def test_classify_resolved_file(self) -> None:
        """Test that RESOLVED files are classified correctly."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create a RESOLVED file
            resolved_file = inprogress_dir / "233_Example.md"
            resolved_file.write_text("# Bug\n**Status**: RESOLVED\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.inprogress_dir = inprogress_dir
            archiver.archive_dir = archive_dir

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                archiver.classify_files()

            self.assertEqual(len(archiver.resolved_files), 1)
            self.assertEqual(len(archiver.active_files), 0)
            output = buffer.getvalue()
            self.assertIn("RESOLVED", output)

    def test_classify_in_progress_file(self) -> None:
        """Test that IN PROGRESS files remain in active list."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create an IN PROGRESS file
            active_file = inprogress_dir / "231_Example.md"
            active_file.write_text("# Bug\n**Status**: IN PROGRESS\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.inprogress_dir = inprogress_dir
            archiver.archive_dir = archive_dir

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                archiver.classify_files()

            self.assertEqual(len(archiver.resolved_files), 0)
            self.assertEqual(len(archiver.active_files), 1)
            output = buffer.getvalue()
            self.assertIn("IN PROGRESS", output)

    def test_classify_new_unclassified_file(self) -> None:
        """Test that files without Status are treated as NEW."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create a file without Status
            new_file = inprogress_dir / "234_New_Bug.md"
            new_file.write_text("# New Bug Report\n## Objective\nDescribe the issue.\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.inprogress_dir = inprogress_dir
            archiver.archive_dir = archive_dir

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                archiver.classify_files()

            self.assertEqual(len(archiver.resolved_files), 0)
            self.assertEqual(len(archiver.active_files), 0)
            self.assertEqual(len(archiver.new_files), 1)
            output = buffer.getvalue()
            self.assertIn("NEW", output)

    def test_mixed_file_classification(self) -> None:
        """Test classification of mixed file types."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create different types of files
            (inprogress_dir / "233_Resolved.md").write_text("# Bug\n**Status**: RESOLVED\n")
            (inprogress_dir / "231_Active.md").write_text("# Bug\n**Status**: IN PROGRESS\n")
            (inprogress_dir / "234_New.md").write_text("# New Bug\n## Objective\nDo something.\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.inprogress_dir = inprogress_dir
            archiver.archive_dir = archive_dir

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                archiver.classify_files()

            self.assertEqual(len(archiver.resolved_files), 1)
            self.assertEqual(len(archiver.active_files), 1)
            self.assertEqual(len(archiver.new_files), 1)


class NextFolderNumberTests(unittest.TestCase):
    """Test archive folder number calculation."""

    def test_next_number_after_230(self) -> None:
        """Test calculation of next folder number."""
        with TemporaryDirectory() as tmpdir:
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            archive_dir.mkdir(parents=True)

            # Create existing folder 230
            (archive_dir / "230_A8_Gate_Test_Coverage").mkdir()

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.archive_dir = archive_dir

            next_num = archiver.get_next_folder_number()
            self.assertEqual(next_num, 231)

    def test_next_number_with_three_digit_folders(self) -> None:
        """Test with three-digit numbered folders."""
        with TemporaryDirectory() as tmpdir:
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            archive_dir.mkdir(parents=True)

            # Create folders with three-digit numbers
            (archive_dir / "099_Some_Task").mkdir()
            (archive_dir / "100_Another_Task").mkdir()
            (archive_dir / "101_Latest_Task").mkdir()

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.archive_dir = archive_dir

            next_num = archiver.get_next_folder_number()
            self.assertEqual(next_num, 102)

    def test_next_number_empty_archive_dir(self) -> None:
        """Test with empty archive directory."""
        with TemporaryDirectory() as tmpdir:
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            archive_dir.mkdir(parents=True)

            archiver = archive_completed_tasks.TaskArchiver(tmpdir)
            archiver.archive_dir = archive_dir

            next_num = archiver.get_next_folder_number()
            self.assertEqual(next_num, 1)


class ArchiveFolderCreationTests(unittest.TestCase):
    """Test archive folder creation and naming."""

    def test_create_archive_folder_single_resolved_file(self) -> None:
        """Test folder creation with single resolved file."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create existing archive folders to establish numbering
            (archive_dir / "230_A8_Gate_Test_Coverage").mkdir()

            # Create a resolved file
            resolved_file = inprogress_dir / "233_SwiftUI_Warning_Fix.md"
            resolved_file.write_text("# Bug\n**Status**: RESOLVED\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir, dry_run=False)
            archiver.inprogress_dir = inprogress_dir
            archiver.archive_dir = archive_dir
            archiver.classify_files()

            folder = archiver.create_archive_folder()

            self.assertTrue(folder.exists())
            self.assertIn("231", folder.name)
            self.assertIn("SwiftUI", folder.name)

    def test_create_archive_folder_with_dry_run(self) -> None:
        """Test that dry-run doesn't actually create folder."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create a resolved file
            resolved_file = inprogress_dir / "233_Example.md"
            resolved_file.write_text("# Bug\n**Status**: RESOLVED\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir, dry_run=True)
            archiver.inprogress_dir = inprogress_dir
            archiver.archive_dir = archive_dir
            archiver.classify_files()

            folder = archiver.create_archive_folder()

            # In dry-run, folder is planned but not created
            self.assertFalse(folder.exists())


class IntegrationTests(unittest.TestCase):
    """Integration tests for the complete archival workflow."""

    def test_full_archival_workflow_dry_run(self) -> None:
        """Test complete dry-run workflow without side effects."""
        with TemporaryDirectory() as tmpdir:
            inprogress_dir = Path(tmpdir) / "DOCS" / "INPROGRESS"
            archive_dir = Path(tmpdir) / "DOCS" / "TASK_ARCHIVE"
            inprogress_dir.mkdir(parents=True)
            archive_dir.mkdir(parents=True)

            # Create test files
            (inprogress_dir / "233_Resolved.md").write_text("# Bug\n**Status**: RESOLVED\n")
            (inprogress_dir / "231_Active.md").write_text("# Bug\n**Status**: IN PROGRESS\n")

            archiver = archive_completed_tasks.TaskArchiver(tmpdir, dry_run=True)

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                archiver.run()

            output = buffer.getvalue()

            # Verify output contains expected information
            self.assertIn("RESOLVED", output)
            self.assertIn("IN PROGRESS", output)
            self.assertIn("dry run", output.lower())

            # Verify no files were moved
            self.assertTrue((inprogress_dir / "233_Resolved.md").exists())
            self.assertTrue((inprogress_dir / "231_Active.md").exists())


if __name__ == "__main__":
    unittest.main()
