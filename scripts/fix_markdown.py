"""Deprecated placeholder for the former Markdown auto-fix script.

This module intentionally performs no work. Historical automation relied on
`fix_markdown.py` to normalize Markdown documents, but the workflow has been
retired. The script is left in place so that existing documentation and tools
that reference its path continue to function without errors.
"""

from __future__ import annotations

import sys


def main() -> None:
    """Inform callers that the script is disabled and exit successfully."""

    message = (
        "scripts/fix_markdown.py is disabled. Markdown auto-fix automation has "
        "been retired, so the script no longer modifies files."
    )
    print(message)


if __name__ == "__main__":
    sys.exit(main())
