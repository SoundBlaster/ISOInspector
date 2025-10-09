#!/usr/bin/env python3
"""Minimal validator for MP4RABoxes.json."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import List

DEFAULT_CATALOG_PATH = Path("Sources/ISOInspectorKit/Resources/MP4RABoxes.json")

FOURCC_RE = re.compile(r"^[\x20-\x7E]{4}$")
UUID_DASHED_RE = re.compile(
    r"^[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$"
)
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

    provenance = data.get("provenance")
    if provenance is not None:
        if not isinstance(provenance, dict):
            errors.append("provenance must be an object if present")
        else:
            fetched_at = provenance.get("fetchedAt")
            if fetched_at is not None and (
                not isinstance(fetched_at, str) or not fetched_at.strip()
            ):
                errors.append("provenance.fetchedAt must be a non-empty string when provided")

            sources = provenance.get("sources")
            if sources is not None:
                if not isinstance(sources, list) or not sources or not all(
                    isinstance(item, str) and item.strip() for item in sources
                ):
                    errors.append(
                        "provenance.sources must be a non-empty array of strings when provided"
                    )

    boxes = data.get("boxes")
    if not isinstance(boxes, list):
        errors.append("boxes must be an array of box entries")
        return

    seen_identifiers: set[str] = set()

    for index, entry in enumerate(boxes):
        context = f"[index: {index}]"
        if not isinstance(entry, dict):
            errors.append(f"{context} Box entry must be an object")
            continue

        identifier = entry.get("type")
        if not isinstance(identifier, str) or not identifier:
            errors.append(f"{context} type must be a non-empty string")
            continue

        if identifier in seen_identifiers:
            errors.append(f"Duplicate type identifier detected: {identifier}")
            continue
        seen_identifiers.add(identifier)

        if len(identifier) == 4 and FOURCC_RE.match(identifier):
            pass
        elif identifier == "uuid":
            uuid_value = entry.get("uuid")
            if not isinstance(uuid_value, str) or not UUID_DASHED_RE.match(uuid_value):
                errors.append(
                    f"{context} uuid entries must include a UUID field in dashed hexadecimal form"
                )
        else:
            errors.append(
                f"{context} type must be a FourCC (4 printable ASCII characters) or the literal 'uuid'"
            )

        for field in ("name", "summary", "specification"):
            if field in entry:
                value = entry[field]
                if not isinstance(value, str) or not value.strip():
                    errors.append(f"{context} {field} must be a non-empty string when present")

        if "category" in entry:
            value = entry["category"]
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{context} category must be a non-empty string when present")

        if "flags" in entry and not isinstance(entry["flags"], str):
            errors.append(f"{context} flags must be stored as a string")

        if "version" in entry and not isinstance(entry["version"], int):
            errors.append(f"{context} version must be an integer")



def load_json(text: str, errors: List[str]) -> object | None:
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        errors.append(f"JSON parse error: {exc}")
        return None


def main(argv: List[str]) -> int:
    if len(argv) == 1:
        path = DEFAULT_CATALOG_PATH
    elif len(argv) == 2:
        path = Path(argv[1])
    else:
        print("Usage: validate_mp4ra_minimal.py [path-to-MP4RABoxes.json]", file=sys.stderr)
        return 2

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
