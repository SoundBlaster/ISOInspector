# PDD:45m Manifest-Driven Fixture Acquisition

## 🎯 Objective

Implement manifest-driven remote fixture acquisition so `generate_fixtures.py` can download, verify, and catalog large media assets required for benchmarking and validation.

## 🧩 Context

- The fixture acquisition research catalog defines prioritized sources, licensing requirements, checksum expectations,

  and storage targets that the automation must honor when mirroring
  assets.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L34-L72】

- The existing fixture generation script currently rebuilds synthetic fixtures but does not ingest external media or

  manage license mirroring, leaving benchmark and QA workflows
  manual.【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L6-L49】

- Execution planning emphasizes completing fixture automation to unblock pending benchmark and release readiness work
  once macOS hardware is available, so we should prepare the manifest tooling ahead of runner availability.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L164-L171】

## ✅ Success Criteria

- `Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py` accepts a manifest describing remote assets, downloads each entry, verifies SHA-256 checksums, and writes deterministic filenames under the documented storage structure.
- The script copies or references license texts for each source into `Documentation/FixtureCatalog/licenses/` so redistribution requirements are met.
- A tracked manifest (e.g., `Documentation/FixtureCatalog/manifest.json`) records URLs, checksums, coverage tags, and license references for CI/hardware runners.
- Script output logs clearly indicate download status, verification results, and storage paths to aid future automation and troubleshooting.

## 🔧 Implementation Notes

- Extend the Python script with a manifest loader, streaming download helpers (with resume-friendly temp files), and
  checksum validation; reuse existing fixture catalog patterns for deterministic naming.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L57-L65】

- Mirror each source license into a dedicated directory and link it from the manifest entry to satisfy attribution
  requirements before bundling fixtures with runners.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L61-L72】

- Stage large assets outside the test bundle under `Distribution/Fixtures/` while keeping lightweight regression assets in-repo; document mount paths in the follow-up README task to align with storage guidance.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L57-L72】
- Consider adding a dry-run mode that validates checksums and license availability without downloading to support CI

  gating.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
