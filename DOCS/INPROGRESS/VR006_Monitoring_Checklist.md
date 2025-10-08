# VR-006 Research Log Monitoring Checklist

## 🔍 Integration Touchpoints

- **CLI Schema Banner** — `isoinspect inspect` now emits the VR-006 schema version

  and field list so analysts can verify that downstream tooling expects the same
  structure.

- **Schema Audit Helper** — `ResearchLogMonitor.audit(logURL:)` validates that

  persisted logs contain only the supported fields and surfaces mismatches for
  future automation.

## ✅ Pre-UI Milestone Checklist

- [x] Capture schema metadata in CLI output for quick regression detection.
- [x] Provide a programmatic audit that UI prototypes can run to confirm log

      compatibility before binding to streaming events.

- [ ] Integrate the audit helper into SwiftUI previews once the UI layer begins

      consuming `ParseEvent.validationIssues`.

- [ ] Extend telemetry dashboards to watch for missing VR-006 entries during UI

      smoke tests.

## 📓 Notes for Analysts

- Schema version `v1.0` enumerates the `boxType`, `filePath`, `startOffset`, and

  `endOffset` columns — any additions require a coordinated schema bump.

- The audit helper throws a descriptive error when unexpected keys appear, which

  should be surfaced in developer tooling and CI to prevent silent divergence.
