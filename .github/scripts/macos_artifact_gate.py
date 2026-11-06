#!/usr/bin/env python3
"""Skip artifact builds only when all changes are under Tests/."""

import json
import os
from pathlib import Path
import re
import subprocess


def should_archive(event_name, event):
    if event_name == "pull_request":
        pull_request = event.get("pull_request", {})
        base = pull_request.get("base", {}).get("sha", "")
        head = pull_request.get("head", {}).get("sha", "")
    elif event_name == "push":
        base, head = event.get("before", ""), event.get("after", "")
    else:
        return True

    if not all(isinstance(sha, str) and re.fullmatch(r"[0-9a-f]{40,64}", sha) and int(sha, 16)
               for sha in (base, head)):
        return True

    revisions = [f"{base}...{head}"] if event_name == "pull_request" else [base, head]
    result = subprocess.run(
        ["git", "diff", "--no-ext-diff", "--no-renames", "--name-only", "-z", *revisions, "--"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if result.returncode:
        return True
    paths = [path for path in result.stdout.split(b"\0") if path]
    return not paths or any(not path.startswith(b"Tests/") for path in paths)


def main():
    try:
        event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
        archive = should_archive(os.environ.get("GITHUB_EVENT_NAME", ""), event)
    except (AttributeError, KeyError, OSError, ValueError, TypeError):
        archive = True
    print(f"archive={'true' if archive else 'false'}")
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"archive={'true' if archive else 'false'}\n")


if __name__ == "__main__":
    main()
