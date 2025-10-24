# Snapshot & CLI Fixture Maintenance

## 🎯 Objective
Ensure JSON export snapshots and CLI fixtures remain accurate after intentional schema or presentation updates so app, library, and tooling outputs stay in sync.

## 🧩 Context
- JSON export fidelity underpins the product's export requirements and CLI workflows outlined in the PRD backlog and master PRD.
- Snapshot baselines are validated by `JSONExportSnapshotTests`, which guard exported structure, derived metadata, and compatibility aliases across representative fixtures.
- CLI fixtures document expected formatter output for regression coverage when schema fields change or new presentation affordances ship.

## ✅ Success Criteria
- All snapshot fixtures regenerated with `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests` when schema changes require it, followed by clean test runs without regeneration notices.
- CLI fixture expectations audited and updated alongside snapshot refreshes to match intentional schema or formatting adjustments.
- PRD backlog and TODO sources reflect the maintenance status and reference this in-progress document.
- Issue metrics emitted by tolerant parsing export paths appear in JSON snapshots and CLI assertions so downstream clients observe severity counts and depth summaries.

## 🔧 Implementation Notes
- Use the regeneration environment variable before committing schema changes to capture updated baselines emitted by `JSONExportSnapshotTests`.
- After regenerating baselines, rerun the snapshot test target without the environment variable to confirm deterministic output and avoid accidental regressions.
- Validate CLI regressions with existing integration tests and manually inspect fixture diffs for readability and alignment with documented schema fields.
- Coordinate with tolerant parsing consumers to ensure new issue fields or format summaries continue to render as documented across app and CLI surfaces.
- Export updates now include `issue_metrics` counts; refresh CLI coverage when severity totals change.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
