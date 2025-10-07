# PRD: Minimal JSON Validator for MP4RA Catalog

## 1. Purpose
Ensure automatic, lightweight validation of `MP4RABoxes.json` in the repository on every pull request and pushes to `main`.  
No JSON Schema — only correctness and conformance to a minimal set of MP4RA catalog standards.

## 2. Scope
**Included**
- JSON well-formedness (parsable, UTF‑8 without BOM).
- Top-level shape:
  - Required keys: `provenance`, `boxes`.
  - `boxes` is an object whose keys are valid FourCC or UUID identifiers.
- Identifier standards:
  - **FourCC**: exactly 4 printable ASCII characters (`0x20–0x7E`).
  - **UUID**: `uuid:` + 32 hex characters (uppercase/lowercase accepted), no dashes.
- `provenance` minimum fields:
  - `fetchedAt` (string, datetime-like but only presence is checked).
  - `sources` (non-empty array of strings).
- No `null` where strings are expected for basic display fields (e.g., `name` inside a box object).
- Pretty formatting: two spaces indentation, LF line endings (`\n`).

**Excluded (not in MVP)**
- Deep semantic checks (children/parents correctness).
- JSON Schema usage.
- URL availability/HTTP checks.
- Status fields consistency (`deprecated`, `replacement`), etc.

## 3. Deliverables
### 3.1. Script
`scripts/validate_mp4ra_minimal.py`  
Responsibilities:
- Load and parse `MP4RABoxes.json` as UTF‑8.
- Validate rules from §4.
- Print `Validation OK` or a bullet list of errors.
- Exit code: 0 on success; 1 on any failure.

### 3.2. GitHub Workflow (to be added by repo owner)
`.github/workflows/validate-mp4ra-minimal.yml` should:
1. Run on `pull_request` and `push` when `MP4RABoxes.json` changes.
2. Checkout code, set up Python 3.x.
3. Execute: `python scripts/validate_mp4ra_minimal.py MP4RABoxes.json`.

## 4. Validation Rules Summary
| Rule | Description | Example of Violation |
|------|-------------|----------------------|
| JSON valid | File must parse as JSON | Trailing comma / syntax error |
| Top-level keys | `provenance`, `boxes` required | Missing `boxes` |
| `boxes` type | Must be an object | `boxes` is an array |
| FourCC format | 4 printable ASCII | `"ft y"`, non‑printable |
| UUID format | `uuid:` + 32 hex, no dashes | `uuid:BE7A-…` |
| `provenance.fetchedAt` | Present (string) | Absent |
| `provenance.sources` | Non-empty array of strings | `[]` or contains non-string |
| UTF‑8, no BOM | Valid encoding | Wrong encoding / BOM |
| Indentation | 2 spaces | Tabs or 4-space indentation |
| No null strings | e.g., `name` not null | `"name": null` |

## 5. Success Criteria
**Pass (CI green)** if all rules in §4 are satisfied.  
**Fail (CI red)** if any rule fails; script prints a list of violations and exits 1.

## 6. Example Outputs
**Success**
```
Validation OK
```

**Failure**
```
Validation FAILED:
 - Top-level key 'boxes' missing
 - [key: ft y] Invalid FourCC: must be 4 printable ASCII characters
 - provenance.sources must be a non-empty array of strings
```

## 7. Implementation Notes
- Use only Python standard library (`json`, `sys`, `re`, `pathlib`, `codecs`).
- No external dependencies.
- Keep the validator under ~150 lines for maintainability.
- O(n) complexity relative to number of entries in `boxes`.

## 8. Future Extensions (Out of Scope for MVP)
- Children/parent cross-reference integrity checks.
- URL validation and HTTPS-only enforcement.
- `stco` vs `co64` policy checks.
- Snapshot freshness check against live MP4RA sources.
