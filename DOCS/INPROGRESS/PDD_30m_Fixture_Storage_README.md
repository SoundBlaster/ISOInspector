# PDD:30m Fixture Storage README

## 🎯 Objective

Document the storage locations, mount expectations, and quota guidance for large fixture downloads so macOS hardware
runners and Linux CI agents can host the manifest-driven catalog without manual guesswork.

## 🧩 Context

- The execution workplan highlights forthcoming hardware validation runs that rely on staging the full fixture catalog,
  requiring clear storage targets on macOS and Linux
  infrastructure.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】【F:DOCS/INPROGRESS/next_tasks.md†L5-L21】
- The fixture acquisition research summarized acceptable data sources and specified storage footprints plus licensing
  locations that the README must restate in an operator-friendly
  format.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L48-L72】
- Current fixture tooling already mirrors large binaries under `Distribution/Fixtures/` and expects accompanying license texts, so infrastructure guidance should align with those conventions.【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L1-L34】

## ✅ Success Criteria

- Spell out required disk quotas and mount paths for macOS runners (≈40 GB) and Linux CI caches (≈15 GB) with headroom
  recommendations taken from the fixture research
  notes.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L57-L64】
- Provide directory layout diagrams tying together `Documentation/FixtureCatalog/manifest.json`, mirrored licenses, and `Distribution/Fixtures/<category>/` staging folders so operators know where downloads land.【F:Documentation/FixtureCatalog/manifest.json†L1-L120】【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L60-L64】
- Include setup steps for mounting or syncing caches on both platforms, referencing the existing `generate_fixtures.py` invocation patterns to keep tooling consistent.【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L15-L34】

## 🔧 Implementation Notes

- Confirm whether macOS runners expose writable volumes like `/Volumes/Fixtures` or use workspace-relative directories, and describe fallback strategies (e.g., symlinks) if elevated permissions are unavailable.【F:DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md†L57-L64】
- Capture expectations for periodic cache refreshes, including checksum validation via the manifest helper, to avoid
  stale or corrupted assets during release readiness
  rehearsals.【F:DOCS/TASK_ARCHIVE/85_PDD_45m_Wire_Generate_Fixtures_Manifest/Summary_of_Work.md†L1-L18】
- Coordinate with the release readiness runbook so fixture storage guidance dovetails with notarization and benchmark
  preflight checklists tracked for macOS distribution
  sign-off.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L1-L200】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
