#!/usr/bin/env python3
"""Minimal validator for MP4RABoxes.json."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import List

FOURCC_RE = re.compile(r"^[\x20-\x7E]{4}$")
UUID_RE = re.compile(r"^uuid:[0-9a-fA-F]{32}$")
BOM_UTF8 = b"\xef\xbb\xbf"


def validate_utf8(path: Path, errors: List[str]) -> str | None:
    if not path.exists():
        errors.append(f"File not found: {path}")
        return None

    raw = path.read_bytes()
    if raw.startswith(BOM_UTF8):
        errors.append("File must not contain a UTF-8 BOM")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        errors.append(f"File is not valid UTF-8: {exc}")
        return None

    if "\r" in text:
        errors.append("File must use LF (\n) line endings")

    if "\t" in text:
        errors.append("File must not contain tab characters; use two-space indentation")

    for idx, line in enumerate(text.splitlines(), start=1):
        stripped = line.lstrip(" ")
        indent_len = len(line) - len(stripped)
        if indent_len and indent_len % 2 != 0:
            errors.append(
                f"Line {idx}: indentation must be in multiples of two spaces (found {indent_len})"
            )
    return text


def validate_structure(data: object, errors: List[str]) -> None:
    if not isinstance(data, dict):
        errors.append("Top-level JSON structure must be an object")
        return

    for key in ("provenance", "boxes"):
        if key not in data:
            errors.append(f"Top-level key '{key}' is required")

    provenance = data.get("provenance")
    if isinstance(provenance, dict):
        fetched_at = provenance.get("fetchedAt")
        if not isinstance(fetched_at, str) or not fetched_at.strip():
            errors.append("provenance.fetchedAt must be a non-empty string")

        sources = provenance.get("sources")
        if not isinstance(sources, list) or not sources or not all(
            isinstance(item, str) and item.strip() for item in sources
        ):
            errors.append("provenance.sources must be a non-empty array of strings")
    else:
        errors.append("provenance must be an object")

    boxes = data.get("boxes")
    if not isinstance(boxes, dict):
        errors.append("boxes must be an object")
        return

    for identifier, payload in boxes.items():
        if not isinstance(identifier, str):
            errors.append("Box identifiers must be strings")
            continue
        if not (FOURCC_RE.match(identifier) or UUID_RE.match(identifier)):
            errors.append(
                f"[key: {identifier}] Identifier must be a FourCC (4 printable ASCII characters) "
                "or UUID in the form 'uuid:' followed by 32 hex digits"
            )

        if not isinstance(payload, dict):
            errors.append(f"[key: {identifier}] Box entry must be an object")
            continue

        if "name" in payload and (payload["name"] is None or not isinstance(payload["name"], str)):
            errors.append(f"[key: {identifier}] name must be a non-null string")



def load_json(text: str, errors: List[str]) -> object | None:
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        errors.append(f"JSON parse error: {exc}")
        return None


def main(argv: List[str]) -> int:
    if len(argv) != 2:
        print("Usage: validate_mp4ra_minimal.py <path-to-MP4RABoxes.json>", file=sys.stderr)
        return 2

    path = Path(argv[1])
    errors: List[str] = []

    text = validate_utf8(path, errors)
    data = load_json(text, errors) if text is not None else None

    if data is not None:
        validate_structure(data, errors)

    if errors:
        print("Validation FAILED:")
        for err in errors:
            print(f" - {err}")
        return 1

    print("Validation OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
