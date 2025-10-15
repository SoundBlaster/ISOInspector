# 2025-10-13-release-checklist — micro PRD

## Intent

Deliver a consolidated release readiness checklist and go-live runbook so QA, release engineering, and product stakeholders can execute ISOInspector releases consistently across CLI, notarized macOS DMG, and TestFlight builds.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L1-L106】

## Scope

- QA gates: capture required commands, owners, and evidence expectations for build, test, automation, and benchmark coverage.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L12-L49】
- Documentation deliverables: ensure release notes, README, manuals, and DocC archives stay in sync with the version bump.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L51-L60】【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L82-L106】
- Packaging runbook: outline Tuist metadata updates, CLI binary builds, notarization flow, and TestFlight submission steps that reuse shared distribution configuration and tooling.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L62-L101】
- Go/no-go sign-off: document evidence required for release approval and capture deferred QA items such as the macOS Combine benchmark follow-up.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L108-L125】

## Integration Contract

- Source of truth lives under `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`.
- No production code changes required; focuses on documentation and process alignment.
- Test artifacts referenced (SwiftLint, XCTest, DocC generation) already exist; runbook links to commands only.

## Acceptance Criteria

- Checklist enumerates QA gates with owners, commands, and evidence expectations.
- Runbook instructions reuse distribution metadata, notarization tooling, and Tuist manifests from tasks E4 and F2.
- Documentation updates and post-release bookkeeping steps (todo/workplan/prd trackers) appear explicitly.

## Follow-Up Puzzles

- [ ] Schedule macOS hardware runs for `ParseTreeStreamingSelectionAutomationTests` and `LargeFileBenchmarkTests.testAppEventBridgeDeliversUpdatesWithinLatencyBudget` when runners become available; record evidence in the release QA log.
- [ ] Evaluate whether release automation should publish DocC archives to a documentation portal beyond GitHub Releases.
