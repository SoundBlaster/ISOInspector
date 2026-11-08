#!/usr/bin/env python3
"""Fail closed when an applicable PR workflow did not succeed."""

import json
import os
import sys


CHECKS = (
    "general", "linux", "macos", "coverage", "foundationui", "foundation_coverage",
    "lint", "duplication", "scripts", "workflows", "mp4ra",
)


def failures(needs):
    problems = []
    changes = needs.get("changes", {})
    if changes.get("result") != "success":
        return ["change detection did not succeed"]
    outputs = changes.get("outputs", {})
    for name in CHECKS:
        required = outputs.get(name)
        result = needs.get(name, {}).get("result")
        if required not in ("true", "false"):
            problems.append(f"{name}: missing or invalid scope decision")
        elif required == "true" and result != "success":
            problems.append(f"{name}: applicable workflow returned {result!r}")
        elif required == "false" and result != "skipped":
            problems.append(f"{name}: unexpected result for inapplicable workflow: {result!r}")
    return problems


def main():
    try:
        needs = json.loads(os.environ["NEEDS_JSON"])
        problems = failures(needs)
    except (KeyError, TypeError, ValueError) as error:
        problems = [f"invalid workflow results: {error}"]
    for problem in problems:
        print(f"::error::{problem}")
    if problems:
        return 1
    print("All applicable PR quality checks succeeded.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
