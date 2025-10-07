#!/usr/bin/env python3
# Minimal MP4RA catalog validator (no JSON Schema).
# Usage: python scripts/validate_mp4ra_minimal.py MP4RABoxes.json
import sys, json, re, codecs
from pathlib import Path

FOURCC_RE = re.compile(r'^[\x20-\x7E]{4}$')  # 4 printable ASCII
UUID_RE = re.compile(r'^uuid:[0-9A-Fa-f]{32}$')  # uuid: + 32 hex, no dashes

def load_utf8_no_bom(path: Path):
    data = path.read_bytes()
    # Detect UTF-8 BOM
    if data.startswith(codecs.BOM_UTF8):
        raise ValueError("File must be UTF-8 without BOM")
    try:
        return data.decode('utf-8')
    except UnicodeDecodeError as e:
        raise ValueError(f"File is not valid UTF-8: {e}") from e

def validate_top_level(obj, errors):
    if not isinstance(obj, dict):
        errors.append("Top-level must be a JSON object")
        return

    for key in ("provenance", "boxes"):
        if key not in obj:
            errors.append(f"Top-level key '{key}' missing")

    boxes = obj.get("boxes")
    if boxes is not None and not isinstance(boxes, dict):
        errors.append("`boxes` must be an object")

    prov = obj.get("provenance", {})
    if prov is not None and not isinstance(prov, dict):
        errors.append("`provenance` must be an object")
        return

    # provenance minimums
    if isinstance(prov, dict):
        if "fetchedAt" not in prov or not isinstance(prov.get("fetchedAt"), str):
            errors.append("provenance.fetchedAt is required (string)")
        sources = prov.get("sources")
        if not isinstance(sources, list) or len(sources) == 0 or not all(isinstance(s, str) for s in sources):
            errors.append("provenance.sources must be a non-empty array of strings")

def is_valid_key(k: str) -> bool:
    return bool(FOURCC_RE.match(k)) or bool(UUID_RE.match(k))

def validate_boxes(obj, errors):
    boxes = obj.get("boxes", {})
    if not isinstance(boxes, dict):
        return

    for k, v in boxes.items():
        if not isinstance(k, str):
            errors.append(f"[key:{k!r}] Key must be string")
            continue
        if not is_valid_key(k):
            if len(k) == 4 and not FOURCC_RE.match(k):
                errors.append(f"[key:{k}] Invalid FourCC: must be 4 printable ASCII characters")
            elif k.startswith("uuid:"):
                errors.append(f"[key:{k}] Invalid UUID key: expected 'uuid:' + 32 hex (no dashes)")
            else:
                errors.append(f"[key:{k}] Invalid key: FourCC (4 ASCII) or 'uuid:<32hex>'")

        # Minimal object shape
        if not isinstance(v, dict):
            errors.append(f"[{k}] Value must be an object")
            continue

        # Optional presentational strings should not be null
        for field in ("name", "definedBy", "specURL", "status", "replacement", "notes", "kind"):
            if field in v and v[field] is None:
                errors.append(f"[{k}] Field '{field}' must not be null (omit field or use string)")

        # isContainer if present must be boolean
        if "isContainer" in v and not isinstance(v["isContainer"], bool):
            errors.append(f"[{k}] 'isContainer' must be boolean if present")

        # children if present must be array of strings
        if "children" in v:
            ch = v["children"]
            if ch is not None and not (isinstance(ch, list) and all(isinstance(x, str) and x for x in ch)):
                errors.append(f"[{k}] 'children' must be an array of non-empty strings or omitted")

def check_indentation(original_text: str, errors):
    # Very lightweight check: enforce two-space indentation (no tabs)
    if "\t" in original_text:
        errors.append("Indentation must not use tabs (use two spaces)")
    # Check some lines start with multiples of two spaces (heuristic)
    for i, line in enumerate(original_text.splitlines(), 1):
        if not line:
            continue
        # ignore lines that don't start with spaces
        if line and line[0] == ' ':
            # count leading spaces
            n = len(line) - len(line.lstrip(' '))
            if n % 2 != 0:
                errors.append(f"Line {i}: indentation should be multiples of two spaces")
                break  # one example is enough

def main(path_str: str) -> int:
    p = Path(path_str)
    errors = []

    try:
        text = load_utf8_no_bom(p)
    except ValueError as e:
        errors.append(str(e))
        print("Validation FAILED:")
        for e in errors:
            print(" -", e)
        return 1

    # Normalize line endings check: if CRLF present, flag
    if "\r\n" in text:
        errors.append("Line endings must be LF (\\n), not CRLF (\\r\\n)")

    # Parse JSON
    try:
        obj = json.loads(text)
    except json.JSONDecodeError as e:
        errors.append(f"JSON parse error: {e}")
        print("Validation FAILED:")
        for e in errors:
            print(" -", e)
        return 1

    # Structural checks
    validate_top_level(obj, errors)
    validate_boxes(obj, errors)

    # Formatting checks
    check_indentation(text, errors)

    if errors:
        print("Validation FAILED:")
        for e in errors:
            print(" -", e)
        return 1

    print("Validation OK")
    return 0

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "MP4RABoxes.json"
    sys.exit(main(path))
