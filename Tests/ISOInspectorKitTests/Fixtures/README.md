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

### `fragmented-multi-trun`

Fragmented segment containing two `trun` runs: the first sets explicit durations,
sizes, and version 0 composition offsets while the second relies on defaults.
Used by `FragmentFixtureCoverageTests` to confirm run aggregation and by JSON
snapshot tests to verify composition offsets surface in exported trees.

### `fragmented-negative-offset`

Single-run fragment with a negative `data_offset`, ensuring parser summaries and
CLI formatting tolerate unresolved byte ranges. The entry also carries a signed
composition offset to cover version 1 payload handling.

### `fragmented-no-tfdt`

Fragment without a `tfdt` box so decode times default to contextual state.
Durations remain explicit, allowing totals to be asserted even when per-sample
timestamps are nil. Catalog metadata advertises the expected warning about the
missing decode time box.

### `large-mdat`

MP4 stub with an 8 KiB payload written via a large-size `mdat` box. Used to
exercise streaming and validation paths that need to handle oversized payloads
without consuming excessive disk space.

### `malformed-truncated`

Intentional negative fixture where the declared `moov` size exceeds the payload.
Validation is expected to surface a "Truncated box payload" error along with a
warning documenting the truncated hierarchy.

### `codec-invalid-configs`

Synthetic `moov` hierarchy containing `avc1` and `hvc1` sample descriptions whose
codec configuration boxes declare zero-length parameter sets. Validation emits
VR-018 errors for both the H.264 sequence parameter set and HEVC SPS array so CLI,
JSON, and ParsePipeline integrations surface codec diagnostics end to end.

### `sample-encryption-placeholder`

Fragmented sample containing a `moof` with `senc`, `saio`, and `saiz` placeholders
so regression tests can assert encryption metadata flows through the kit, CLI, and
app. The `saio` table uses version 1 to exercise 64-bit auxiliary offsets while
`senc` encodes two samples with override defaults and subsample encryption ranges.
