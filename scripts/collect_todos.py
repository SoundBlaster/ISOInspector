#!/usr/bin/env python3
"""
Collect @todo puzzles from the codebase and generate a Markdown report.

This script implements PDD (Puzzle-Driven Development) task tracking by:
1. Scanning all source files for @todo comments
2. Extracting task numbers and descriptions
3. Grouping tasks by number
4. Generating a Markdown report with tasks sorted by number

Usage:
    python3 scripts/collect_todos.py [--output OUTPUT_FILE]

Example:
    python3 scripts/collect_todos.py --output DOCS/TODO_REPORT.md
"""

import argparse
import os
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional


@dataclass
class TodoItem:
    """Represents a single @todo puzzle."""
    file_path: str
    line_number: int
    task_id: Optional[str]
    description: str
    full_comment: List[str]

    @property
    def location(self) -> str:
        """Returns the location string for the todo item."""
        return f"{self.file_path}:{self.line_number}"


class TodoCollector:
    """Collects @todo puzzles from source files."""

    # Directories to exclude from scanning
    EXCLUDED_DIRS = {
        '.build', '.git', 'build', 'DerivedData',
        'Derived', '.swiftpm', 'Pods', 'node_modules'
    }

    # File extensions to scan
    INCLUDE_EXTENSIONS = {
        '.swift', '.py', '.sh', '.yml', '.yaml', '.md',
        '.txt', '.h', '.m', '.mm', '.cpp', '.c'
    }

    # Regex pattern for @todo comments
    # Matches: @todo #123 description or @todo description
    TODO_PATTERN = re.compile(
        r'@todo\s+(?:#(\S+)\s+)?(.+)',
        re.IGNORECASE
    )

    def __init__(self, root_dir: str = '.'):
        self.root_dir = Path(root_dir).resolve()
        self.todos: List[TodoItem] = []

    def should_scan_file(self, file_path: Path) -> bool:
        """Determines if a file should be scanned for @todo comments."""
        # Check if any parent directory is excluded
        for parent in file_path.parents:
            if parent.name in self.EXCLUDED_DIRS:
                return False

        # Check file extension
        return file_path.suffix in self.INCLUDE_EXTENSIONS

    def extract_todos_from_file(self, file_path: Path) -> List[TodoItem]:
        """Extracts all @todo items from a single file."""
        todos = []

        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"Warning: Could not read {file_path}: {e}")
            return todos

        i = 0
        while i < len(lines):
            line = lines[i]
            match = self.TODO_PATTERN.search(line)

            if match:
                task_id = match.group(1)  # May be None
                description = match.group(2).strip()

                # Collect continuation lines (indented lines after @todo)
                full_comment = [description]
                j = i + 1

                # Determine base indentation from the @todo line
                base_indent = len(line) - len(line.lstrip())

                while j < len(lines):
                    next_line = lines[j].rstrip()

                    # Skip empty lines
                    if not next_line.strip():
                        j += 1
                        continue

                    # Check if line is a continuation (indented more than base)
                    next_indent = len(next_line) - len(next_line.lstrip())

                    # For comment lines, look for comment markers
                    stripped = next_line.strip()
                    if stripped.startswith(('///', '//', '#', '--')):
                        # Remove comment markers
                        content = re.sub(r'^[\s]*(?:///?|#|--)\s?', '', stripped)

                        # Check if it's still part of the todo (indented or continuation)
                        if content and not self.TODO_PATTERN.search(content):
                            full_comment.append(content)
                            j += 1
                            continue

                    # Stop if we hit another @todo or unindented line
                    break

                rel_path = file_path.relative_to(self.root_dir)

                todos.append(TodoItem(
                    file_path=str(rel_path),
                    line_number=i + 1,
                    task_id=task_id,
                    description=description,
                    full_comment=full_comment
                ))

                i = j
            else:
                i += 1

        return todos

    def collect_all_todos(self) -> List[TodoItem]:
        """Scans the entire project and collects all @todo items."""
        print(f"Scanning {self.root_dir} for @todo comments...")

        for file_path in self.root_dir.rglob('*'):
            if file_path.is_file() and self.should_scan_file(file_path):
                file_todos = self.extract_todos_from_file(file_path)
                self.todos.extend(file_todos)

        print(f"Found {len(self.todos)} @todo items")
        return self.todos


class MarkdownReportGenerator:
    """Generates a Markdown report from collected @todo items."""

    def __init__(self, todos: List[TodoItem]):
        self.todos = todos

    def group_by_task_id(self) -> tuple[dict[str, List[TodoItem]], List[TodoItem]]:
        """Groups todos by task ID. Returns (numbered_tasks, unnumbered_tasks)."""
        numbered = defaultdict(list)
        unnumbered = []

        for todo in self.todos:
            if todo.task_id:
                numbered[todo.task_id].append(todo)
            else:
                unnumbered.append(todo)

        return numbered, unnumbered

    def generate_markdown(self) -> str:
        """Generates the complete Markdown report."""
        numbered, unnumbered = self.group_by_task_id()

        lines = [
            "# TODO Puzzles Report",
            "",
            f"**Generated:** {self._get_timestamp()}  ",
            f"**Total puzzles:** {len(self.todos)}  ",
            f"**Numbered tasks:** {len(numbered)}  ",
            f"**Unnumbered tasks:** {len(unnumbered)}",
            "",
            "This report is automatically generated from `@todo` comments in the codebase.",
            "Following the Puzzle-Driven Development (PDD) methodology.",
            "",
        ]

        # Numbered tasks section
        if numbered:
            lines.extend([
                "## Numbered Tasks",
                "",
                "Tasks with explicit task IDs (e.g., `@todo #A7 description`).",
                "",
            ])

            # Sort by task ID
            for task_id in sorted(numbered.keys()):
                items = numbered[task_id]
                lines.append(f"### Task #{task_id}")
                lines.append("")
                lines.append(f"**Count:** {len(items)} puzzle(s)")
                lines.append("")

                for item in items:
                    lines.append(f"#### {item.location}")
                    lines.append("")

                    # Description
                    for comment_line in item.full_comment:
                        lines.append(f"> {comment_line}")
                    lines.append("")

                lines.append("---")
                lines.append("")

        # Unnumbered tasks section
        if unnumbered:
            lines.extend([
                "## Unnumbered Tasks",
                "",
                "Tasks without explicit task IDs. Consider adding task IDs for better tracking.",
                "",
            ])

            # Group by file for better organization
            by_file = defaultdict(list)
            for item in unnumbered:
                by_file[item.file_path].append(item)

            for file_path in sorted(by_file.keys()):
                items = by_file[file_path]
                lines.append(f"### {file_path}")
                lines.append("")

                for item in items:
                    lines.append(f"**Line {item.line_number}:**")
                    lines.append("")
                    for comment_line in item.full_comment:
                        lines.append(f"> {comment_line}")
                    lines.append("")

                lines.append("---")
                lines.append("")

        # Summary section
        lines.extend([
            "## Summary",
            "",
            f"- Total @todo puzzles: **{len(self.todos)}**",
            f"- Numbered tasks: **{len(numbered)}**",
            f"- Unnumbered tasks: **{len(unnumbered)}**",
            "",
        ])

        if numbered:
            lines.append("### Numbered Tasks Breakdown")
            lines.append("")
            lines.append("| Task ID | Puzzle Count |")
            lines.append("|---------|--------------|")
            for task_id in sorted(numbered.keys()):
                count = len(numbered[task_id])
                lines.append(f"| #{task_id} | {count} |")
            lines.append("")

        lines.extend([
            "---",
            "",
            "*Generated by `scripts/collect_todos.py`*",
        ])

        return '\n'.join(lines)

    @staticmethod
    def _get_timestamp() -> str:
        """Returns current timestamp in ISO format."""
        from datetime import datetime
        return datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Collect @todo puzzles and generate a Markdown report'
    )
    parser.add_argument(
        '--output', '-o',
        default='DOCS/TODO_REPORT.md',
        help='Output file path (default: DOCS/TODO_REPORT.md)'
    )
    parser.add_argument(
        '--root', '-r',
        default='.',
        help='Root directory to scan (default: current directory)'
    )

    args = parser.parse_args()

    # Collect todos
    collector = TodoCollector(root_dir=args.root)
    todos = collector.collect_all_todos()

    # Generate report
    generator = MarkdownReportGenerator(todos)
    markdown = generator.generate_markdown()

    # Write output
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(markdown)

    print(f"\n✅ Report generated: {output_path}")
    print(f"   Total puzzles: {len(todos)}")


if __name__ == '__main__':
    main()
