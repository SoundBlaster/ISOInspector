# ISOInspector Release Readiness Checklist and Go-Live Runbook

## Purpose

Provide release managers and on-call engineers with a single checklist that covers QA gates, documentation deliverables, and distribution packaging so ISOInspector builds can ship confidently across CLI, notarized macOS DMG, and TestFlight targets.

## Reference Links

- `Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json`
- `Project.swift`
- `scripts/notarize_app.sh`
- `Documentation/ISOInspector.docc/Manuals/App.md`
- `Documentation/ISOInspector.docc/Manuals/CLI.md`
- `Documentation/ISOInspector.docc/Guides/CLIReleaseDistributionStrategy.md`
- `DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md`
- `DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/Summary_of_Work.md`
- `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md`

## Pre-Release Checklist

### QA Gates and Validation Evidence

| Area | Owner | Command or Artifact | Evidence Captured |
| --- | --- | --- | --- |
| Build readiness | Release engineer | `swift build -c release` | Attach build log with commit SHA. |
| Core tests | QA | `swift test` | Store XCTest report including `LargeFileBenchmarkTests` baseline values. |
| UI automation | QA (macOS hardware) | `swift test --filter ParseTreeStreamingSelectionAutomationTests` | Upload video/logs; note blockers if macOS UI runner unavailable. |
| Performance | QA (macOS hardware) | `swift test --filter LargeFileBenchmarkTests/testAppEventBridgeDeliversUpdatesWithinLatencyBudget` | Capture latency/CPU/memory metrics and confirm against thresholds; document skips if Combine unavailable. |
| Linting | Development lead | `scripts/swiftlint-format.sh && docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" -w /work ghcr.io/realm/swiftlint:0.53.0 swiftlint lint --strict --no-cache --config .swiftlint.yml` | Archive lint log showing no violations. |
| Documentation | Tech writer | `scripts/generate_documentation.sh` | Publish DocC archives under `Documentation/DocC/` and link in release notes. |

### Documentation and Communication

- [ ] Update release notes with user-facing changes, benchmark deltas, and known issues.
- [ ] Refresh README build badges or version tables if marketing version increments.
- [ ] Ensure manuals highlight new workflows or migration notes before tagging the release.
- [ ] Confirm the CLI distribution checklist in [`CLIReleaseDistributionStrategy`](CLIReleaseDistributionStrategy.md) is complete (notarized ZIP, Homebrew tap update, Linux tarballs, published checksums).
- [ ] Notify stakeholders in the engineering channel with checklist status and expected release window.

### Distribution Metadata and Compliance

- [ ] Bump marketing version and build number in `DistributionMetadata.json` and regenerate the Tuist workspace so all targets inherit the update.
- [ ] Verify bundle identifiers and entitlements match distribution requirements for macOS, iOS, and iPadOS targets.
- [ ] Review outstanding `@todo` entitlements (Apple Events automation) and confirm whether additional capabilities are still unnecessary for the current flow.
- [ ] Confirm notarization credentials in the keychain profile referenced by `scripts/notarize_app.sh` remain valid.

## Packaging and Go-Live Runbook

### 1. Prepare Version Metadata

1. Edit `Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json` to update `marketingVersion`, `buildNumber`, and any target-specific metadata.
1. Run `tuist generate` to regenerate the Xcode workspace, ensuring `Project.swift` consumes the new metadata.
1. Commit the metadata change alongside release notes.

### 2. Build Artifacts

1. Build the CLI release binary: `swift build -c release --product ISOInspectorCLI`. Copy the binary into `Distribution/CLI/<version>/` for release packaging and run `scripts/package_cli.sh --version <version>` to codesign, zip, notarize, and staple the CLI artifacts.
1. Generate DocC archives: `scripts/generate_documentation.sh Documentation/DocC`. Zip each target directory for artifact upload.
1. Archive the SwiftUI app via Xcode or `xcodebuild archive` using the Tuist-generated workspace. Export both a notarization-ready `.zip` and a TestFlight `.ipa`.

### 3. Notarize and Distribute macOS Artifacts

1. On macOS, run `scripts/notarize_app.sh --artifact <path-to-zip> --profile <keychain-profile>` for the GUI build and verify notarization tickets before stapling.
1. Run `scripts/package_cli.sh` (or follow the inline checklist in [`CLIReleaseDistributionStrategy`](CLIReleaseDistributionStrategy.md)) to submit the CLI ZIP for notarization, staple the result, and copy SHA256/SHA512 checksums into the release notes draft.
1. Package the stapled app into a DMG or distribute the notarized `.zip` through GitHub Releases. Upload the CLI ZIP alongside DocC archives and retain checksum manifests under `releases/<version>/QA/`.

### 4. Publish iOS and iPadOS Builds

1. Use Xcode Organizer or `xcodebuild -exportArchive` to produce an `.ipa` signed for TestFlight.
1. Upload via Xcode or `xcrun altool`/`xcrun notarytool` equivalents configured for App Store Connect.
1. Create release notes in App Store Connect referencing QA evidence and any feature flags toggled for the build.

### 5. Final Communications and Artifact Storage

- Store CLI binaries, notarized DMGs/ZIPs, Linux tarballs, and DocC archives under the release tag in GitHub Releases. Use consistent naming: `ISOInspector-<version>-cli-macos.zip`, `ISOInspector-<version>-cli-linux-gnu.tar.gz`, `ISOInspector-<version>-cli-linux-musl.tar.gz`, `ISOInspector-<version>-app.dmg`, `DocC-<target>-<version>.zip`.
- Publish the QA summary (test logs, benchmark metrics) in the `releases/<version>/QA` folder or linked wiki page. Use `Documentation/Performance/2025-10-19-benchmark-summary.md` and the adjacent raw logs as the current baseline when compiling the evidence packet.
- Circulate an internal announcement summarizing the release scope, artifacts, and any deferred items.

## Go / No-Go Review

| Gate | Evidence | Status Owner | Notes |
| --- | --- | --- | --- |
| QA suites | XCTest + UI automation logs | QA lead | Blocked if macOS automation or Combine benchmarks cannot run; escalate before go-live. |
| Performance | Benchmark metrics archive | Performance lead | Must include CLI and UI numbers; document skips with remediation plan. |
| Documentation | Updated README, manuals, DocC zip links | Tech writer | Confirm doc links resolve and version numbers match `DistributionMetadata.json`. |
| Distribution | Notarization receipt, TestFlight processing | Release engineer | Fails if entitlements change without approval or notarization returns errors. |
| Stakeholder sign-off | Product + Engineering approvals | Product owner | Capture approvals in release ticket or retrospective notes. |

## Post-Release Checklist

- [ ] Tag the release in Git and push version bump commits.
- [ ] Update `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`, `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`, and `DOCS/INPROGRESS/next_tasks.md` to mark F5 complete.
- [ ] Close or archive micro-PRD files under `DOCS/TASK_ARCHIVE/59_F5_Finalize_Release_Checklist_and_Go_Live_Runbook/`.
- [ ] File follow-up tasks for any deferred QA runs (e.g., pending macOS Combine benchmark) and keep `todo.md` puzzles in sync.
- [ ] Schedule a post-release retro to capture lessons learned and tooling improvements.
