# A2 — Configure Continuous Integration Pipeline

## Summary
Establish an automated GitHub Actions workflow that builds and tests the ISOInspector Swift package on every pull request so regressions are blocked before merge. This aligns with Phase A goals in the master PRD to solidify IO foundations before deeper parser work.

## Source Requirements
- Execution priority and acceptance criteria pulled from `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` (Task A2 — High priority, depends on A1, CI must run on pull requests and gate merges on failures).
- Product expectations validated against `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` Phase A scope (IO infrastructure and tooling readiness).
- Tooling references available via `DOCS/AI/02_ISOInspector_AI_Source_Guide.md` (Swift, swiftlint recommendations, external tool awareness).

## Objectives
1. Provide deterministic `swift build`/`swift test` execution for all package targets on Linux (container) and macOS (matrix optional, phased).
2. Ensure workflow artifacts/logs capture failures clearly for follow-up agents.
3. Lay groundwork for linting/static analysis steps once configuration files exist.

## Dependencies
- **A1 — SwiftPM workspace initialization.** Verified via successful local `swift test` run (2025-10-04) and existing multi-target Package.swift manifest.

## In-Scope
- Creating `.github/workflows/ci.yml` (or equivalent) with checkout, Swift toolchain setup, dependency caching, build + test steps.
- Configuring required status checks instructions (documented in repo README or contributing guide as needed).
- Optional stub steps for linting with clear TODO comments if configuration not yet present.

## Out of Scope
- Publishing DocC artifacts (task A3).
- Release automation, notarization, or distribution-specific signing.
- Generating new lint configuration files (can be separate task when specs available).

## Acceptance Criteria
- Workflow triggers on pull requests to the default branch.
- Jobs execute `swift test` (and `swift build` if separated) against all targets without manual intervention.
- Workflow fails the PR when tests fail.
- Basic caching or toolchain version pinning prevents unnecessary redownloads (optional but recommended for stability).

## Implementation Notes
- Prefer `swift-actions/setup-swift` for toolchain installation to match Linux container environment.
- Use separate jobs or steps if macOS runners are added later; start with Ubuntu to keep runtime low.
- Surface build logs via `--enable-test-discovery` default behavior; attach artifacts only if job logs become unwieldy.

## Immediate Next Steps
1. Scaffold the workflow file with name, triggers (`pull_request`, optional `push` to main).
2. Add steps: checkout, setup Swift (5.9+), cache `.build` directory, run `swift build` and `swift test`.
3. Commit workflow and update documentation (e.g., README CI badge) if necessary once pipeline verified.
