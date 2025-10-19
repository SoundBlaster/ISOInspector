#!/usr/bin/env python3
"""Validate JSON files formatting for the project.

This script ensures that JSON resources in the source and test folders are
valid and adhere to the formatting conventions currently used in the
repository. Instead of reformatting the files, the script checks that:

* Each file can be parsed as JSON.
* Indentation is done with two-space multiples (no tabs).
* Spacing around object key colons is consistent within the file.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]


def iter_json_files(paths: Iterable[Path]) -> Iterable[Path]:
    for path in paths:
        if path.is_file() and path.suffix in {".json", ".jsonc"}:
            yield path
        elif path.is_dir():
            for candidate in path.rglob("*.json"):
                yield candidate
            for candidate in path.rglob("*.jsonc"):
                yield candidate


def validate_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    try:
        json.loads(text)
    except json.JSONDecodeError as exc:  # pragma: no cover - executed in CI
        print(f"{path}: JSON parsing failed: {exc}")
        return False

    indentation_ok = _validate_indentation(path, text)
    colon_style_ok = _validate_colon_spacing(path, text)
    return indentation_ok and colon_style_ok


def _validate_indentation(path: Path, text: str) -> bool:
    success = True
    for line_no, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip(" 	")
        leading = line[: len(line) - len(stripped)]

        if not stripped:
            continue  # ignore empty lines

        if "\t" in leading:
            print(f"{path}:{line_no}: indentation uses tabs instead of spaces")
            success = False
            continue

        if len(leading) % 2 != 0:
            print(f"{path}:{line_no}: indentation is not a multiple of two spaces")
            success = False

    return success


COLON_PATTERN = re.compile(r'"(?:\\.|[^"\\])*"(\s*):(\s*)')


def _validate_colon_spacing(path: Path, text: str) -> bool:
    before_style: str | None = None
    after_style: str | None = None
    success = True

    for match in COLON_PATTERN.finditer(text):
        before, after = match.groups()
        if "\n" in before or "\n" in after:
            continue  # Ignore multi-line constructs (should not occur in style)

        if before_style is None:
            before_style = before
        elif before != before_style:
            print(
                f"{path}: inconsistent spacing before ':' (found {before!r} vs {before_style!r})"
            )
            success = False
            break

        if after_style is None:
            after_style = after
        elif after != after_style:
            print(
                f"{path}: inconsistent spacing after ':' (found {after!r} vs {after_style!r})"
            )
            success = False
            break

    if success and after_style not in {None, " "}:
        print(f"{path}: expected a single space after ':' but found {after_style!r}")
        success = False

    if success and before_style not in {None, "", " "}:
        print(f"{path}: unexpected spacing before ':' ({before_style!r})")
        success = False

    return success


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Validate JSON formatting.")
    parser.add_argument(
        "paths",
        nargs="*",
        default=[ROOT / "Sources", ROOT / "Tests"],
        type=Path,
        help="Directories or files to validate (default: Sources and Tests).",
    )
    args = parser.parse_args(argv)

    success = True
    for path in iter_json_files(args.paths):
        success &= validate_file(path)

    return 0 if success else 1


if __name__ == "__main__":  # pragma: no cover - script entry point
    raise SystemExit(main(sys.argv[1:]))
