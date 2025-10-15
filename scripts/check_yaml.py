#!/usr/bin/env python3
"""Validate repository YAML files using PyYAML.

The script accepts an optional list of YAML paths to validate. When no
arguments are provided it defaults to the tracked ``*.yml`` and ``*.yaml``
files in the repository to keep the pre-commit hook fast and deterministic.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable

try:
    import yaml
except ImportError as exc:  # pragma: no cover - defensive guard
    message = (
        "PyYAML is required to validate YAML files. Install it with "
        "`python3 -m pip install pyyaml` and re-run the script."
    )
    raise SystemExit(message) from exc


class PermissiveLoader(yaml.SafeLoader):
    """Treat unknown YAML tags as plain strings."""


def _construct_undefined(self, node):
    return self.construct_scalar(node)


PermissiveLoader.add_constructor(None, _construct_undefined)


def _git_ls_files(patterns: Iterable[str]) -> list[Path]:
    """Return tracked files that match the given glob patterns."""

    result = subprocess.run(
        ["git", "ls-files", *patterns],
        check=True,
        capture_output=True,
        text=True,
    )
    paths = []
    seen: set[Path] = set()
    for line in result.stdout.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        path = Path(stripped)
        if path in seen:
            continue
        seen.add(path)
        paths.append(path)
    return paths


def _validate_yaml(path: Path) -> list[str]:
    """Return a list of validation errors for ``path``."""

    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ["File no longer exists"]

    if not text.strip():
        # Empty documents are legal YAML but likely unintended.
        return ["Empty YAML document"]

    try:
        yaml.load(text, Loader=PermissiveLoader)
    except yaml.YAMLError as error:  # pragma: no cover - exercised in CI
        return [str(error)]

    return []


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        help="Optional YAML files to validate. Defaults to tracked .yml/.yaml files.",
    )
    args = parser.parse_args(argv)

    repo_root = Path(__file__).resolve().parents[1]
    os.chdir(repo_root)

    if args.paths:
        paths = [Path(p) for p in args.paths]
    else:
        paths = _git_ls_files(["*.yml", "*.yaml"])

    if not paths:
        print("No YAML files to validate.")
        return 0

    errors = []
    for path in paths:
        path_errors = _validate_yaml(path)
        if path_errors:
            for issue in path_errors:
                errors.append((path, issue))

    if errors:
        for path, issue in errors:
            print(f"{path}: {issue}")
        print(f"YAML validation failed for {len(errors)} file(s).", file=sys.stderr)
        return 1

    print(f"Validated {len(paths)} YAML file(s).")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    sys.exit(main(sys.argv[1:]))
