# Fixture Catalog Overview

This directory stores deterministic media samples consumed by `ISOInspectorKit`
unit tests. Media payloads are base64 encoded into plain-text `.txt` files so
they can live in source control without violating the "no binary" policy. All
synthetic assets can be regenerated locally via `generate_fixtures.py` to keep
provenance explicit and repository size small.

## Generation

Run the helper script whenever synthetic fixtures need to be recreated:

```bash
python3 Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py
```

The command overwrites existing text artifacts in the `Media/` subdirectory
with freshly generated base64 payloads.

## Manifest-Driven Downloads

The same helper also understands a manifest that describes larger external
fixtures. Pass the tracked manifest to mirror remote assets into the
distribution cache while preserving license texts:

```bash
python3 Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py \
  --skip-text-fixtures \
  --manifest Documentation/FixtureCatalog/manifest.json
```

- Downloaded binaries are stored under `Distribution/Fixtures/<category>/`.
- License texts are mirrored into `Documentation/FixtureCatalog/licenses/`.
- Use `--dry-run` to validate the manifest without performing network I/O.

## Fixture Inventory

### `baseline-sample`

Apple-provided reference MP4 pulled from the official sample set. Serves as the
control asset for smoke tests and basic validation coverage. No warnings or
errors are expected when parsing the file. The catalog stores the payload as a
base64 `.txt` blob; regenerate it manually if the upstream sample changes.

### `fragmented-stream-init`

Synthetic initialization segment containing `ftyp` and `moov` boxes. Tagged as
`fragmented` and `init`, and accompanied by the expectation that streaming
markers (brands and flags) are present without errors.

### `dash-segment-1`

Synthetic DASH media segment (extension `.m4s`) with `styp`, `sidx`, `moof`, and
`mdat` boxes to exercise streaming validations. Tests assert that the warnings
include the "Contains streaming media segment" marker.

### `large-mdat`

MP4 stub with an 8 KiB payload written via a large-size `mdat` box. Used to
exercise streaming and validation paths that need to handle oversized payloads
without consuming excessive disk space.

### `malformed-truncated`

Intentional negative fixture where the declared `moov` size exceeds the payload.
Validation is expected to surface a "Truncated box payload" error along with a
warning documenting the truncated hierarchy.
