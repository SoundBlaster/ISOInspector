# Fixture Storage Guide

## Purpose

Provide operators with repeatable storage targets for manifest-driven fixture downloads so macOS hardware runners and Linux CI agents can host the catalog without exhausting quotas or breaking the default tooling paths.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L56-L68】【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L19-L37】

## Storage Targets

| Platform | Mount or Cache Root | Recommended Quota | Notes |
| --- | --- | --- | --- |
| macOS hardware runner | `/Volumes/ISOInspectorFixtures` (APFS sparse disk) → symlinked to `Distribution/Fixtures/` | 40 GB (≈37 GB footprint + 20 % headroom) | Mount a writable sparse bundle before the download step. Fallback to `$WORKSPACE/Derived/Fixtures` if `/Volumes` is restricted.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L64-L68】 |
| Linux CI agent | `$HOME/.cache/isoinspector/fixtures` → symlinked to `Distribution/Fixtures/` | 15 GB (subset catalog + 20 % headroom) | Persist the cache between workflow runs (for example, GitHub Actions cache or dedicated volume) to avoid re-downloading large media.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L64-L68】 |

> ℹ️ Both environments should mirror license texts into `Documentation/FixtureCatalog/licenses/` alongside the manifest entries. The helper script handles this automatically when pointed at the manifest.【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L25-L37】

## Directory Layout

```text
Documentation/
  FixtureCatalog/
    manifest.json
    corrupt-fixtures.json
    licenses/
Distribution/
  Fixtures/
    <category>/
      <fixture files>
Tests/ISOInspectorKitTests/Fixtures/
  generate_fixtures.py
```

- `manifest.json` describes fixture metadata, destination categories, and license references for automated downloads.【F:Documentation/FixtureCatalog/manifest.json†L1-L23】
- `corrupt-fixtures.json` enumerates the deterministic corrupt corpus used by tolerant parsing smoke tests.【F:Documentation/FixtureCatalog/corrupt-fixtures.json†L1-L121】
- `Distribution/Fixtures/<category>/` stores the downloaded binaries referenced by the manifest, ensuring the CLI, Kit, and app share the same staging path.【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L25-L33】
- `Documentation/FixtureCatalog/licenses/` contains mirrored attribution files required for redistribution compliance.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L64-L68】

## macOS Runner Setup

1. Create and mount the sparse bundle volume before invoking fixture sync:

    ```bash
    hdiutil create -size 40g -type SPARSEBUNDLE -fs APFS -volname ISOInspectorFixtures \
      "$HOME/Library/Caches/ISOInspectorFixtures.sparsebundle"
    hdiutil attach "$HOME/Library/Caches/ISOInspectorFixtures.sparsebundle"
    ln -sfn /Volumes/ISOInspectorFixtures "$(pwd)/Distribution/Fixtures"
    ```

1. If `/Volumes` mounting is unavailable, create a workspace-local cache and link it instead:

    ```bash
    mkdir -p "$WORKSPACE/Derived/Fixtures"
    ln -sfn "$WORKSPACE/Derived/Fixtures" "$(pwd)/Distribution/Fixtures"
    ```

1. Run the manifest sync to download or refresh fixtures:

    ```bash
    python3 Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py \
      --skip-text-fixtures \
      --manifest Documentation/FixtureCatalog/manifest.json
    ```

1. Use `--dry-run` during CI rehearsals to validate manifest entries without downloading large assets:

    ```bash
    python3 Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py \
      --skip-text-fixtures \
      --manifest Documentation/FixtureCatalog/manifest.json \
      --dry-run
    ```

The downloaded fixtures remain available to the release readiness runbook, which expects the catalog to reside under `Distribution/Fixtures/` during notarization and benchmark rehearsals.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L9-L35】

## Linux CI Cache Setup

1. Provision a persistent cache directory and link it to the repository path:

    ```bash
    mkdir -p "$HOME/.cache/isoinspector/fixtures"
    ln -sfn "$HOME/.cache/isoinspector/fixtures" "$(pwd)/Distribution/Fixtures"
    ```

1. Optionally seed the cache with existing artifacts (for example, from an object store) before triggering downloads.

1. Execute the manifest workflow:

    ```bash
    python3 Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py \
      --skip-text-fixtures \
      --manifest Documentation/FixtureCatalog/manifest.json
    ```

1. After downloads complete, archive the cache directory using the platform’s cache mechanism (e.g., GitHub Actions cache) so subsequent jobs reuse the fixtures without hitting external bandwidth caps.

## Corrupt Fixture Corpus

- Generate the deterministic corrupt fixtures in-repo for tolerant parsing smoke coverage:

    ```bash
    python3 Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py \
      --skip-text-fixtures
    ```

- The helper writes binary assets to `Fixtures/Corrupt/` and updates `Documentation/FixtureCatalog/corrupt-fixtures.json`, which enumerates corruption patterns, expected `ParseIssue` codes, and smoke-test hints consumed by the test suite.【F:Documentation/FixtureCatalog/corrupt-fixtures.json†L1-L121】
- Each binary is mirrored as `<name>.mp4.base64` so the catalog remains text-friendly for source control. The test suite automatically materializes `.mp4` siblings from these base64 sources when needed, and `.gitignore` prevents accidental commits of the regenerated binaries.【F:Tests/ISOInspectorKitTests/CorruptFixtureCorpusTests.swift†L9-L120】【F:Fixtures/Corrupt/.gitignore†L1-L1】
- Automated sanity checks in `CorruptFixtureCorpusTests` parse the fixtures in tolerant mode and assert the documented issues occur without crashes.【F:Tests/ISOInspectorKitTests/CorruptFixtureCorpusTests.swift†L1-L78】

## Maintenance

- Re-run the manifest sync monthly or whenever fixture metadata changes to refresh checksums and ensure the cache contains the latest assets.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L60-L68】
- Validate cache health with `--dry-run`; the helper verifies existing files against the manifest checksum and redownloads corrupted assets automatically.【F:Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py†L64-L112】
- Keep license texts in sync with the manifest and include them in distribution packages per the release readiness runbook requirements.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L9-L31】【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L27-L33】

## Synthetic Fragment Profiles

### `fragmented-multi-trun`

Synthetic fragment with two `trun` boxes. The first run carries explicit sample
durations, sizes, and version 0 composition offsets while the second relies on
defaulted values. Regenerate via `generate_fixtures.py` to stress multi-run
aggregation across validator, CLI, and JSON export tests.

### `fragmented-negative-offset`

Fragmented sample that encodes a negative `data_offset`, forcing the parser to
drop absolute byte ranges while keeping logical totals. Useful for rehearsing
edge cases before promoting assets into the golden catalog.

### `fragmented-no-tfdt`

Fragment without a `tfdt` box so decode times default to contextual state. The
fixture keeps durations and sizes explicit to confirm totals remain available
when timing cursors are nil; metadata documents the expected warning.

