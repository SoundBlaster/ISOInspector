# Bug #235 — Smoke tests blocked by Sendable violations in WindowSessionController

## Objective
Capture and scope the strict-concurrency build failure that prevents smoke tests from running. The goal is to unblock smoke/regression suites by resolving Sendable and actor-isolation errors emitted from `WindowSessionController` (and related closures) when running `swift test` with strict concurrency enabled.

## Symptoms
- Command `swift test --filter ISOInspectorKitTests.CorruptFixtureCorpusTests/testTolerantPipelineProcessesSmokeFixtures --filter ISOInspectorAppTests.UICorruptionIndicatorsSmokeTests/testTolerantParsingProducesCorruptionIndicatorsForSmokeFixtures` fails during compilation before any tests execute.
- Compiler errors (strict concurrency):
  - `WindowSessionController.DocumentLoadingResources` is non-Sendable but passed across `Task.detached` boundaries and returned to the main actor (`value` access).
  - `readerFactory` and `pipelineFactory` (function properties) are main-actor isolated and non-`@Sendable`, yet captured inside `Task.detached`, triggering “non-Sendable type cannot exit main actor-isolated context”.
  - Multiple “type does not conform to Sendable” and “non-Sendable type of nonisolated property 'value' cannot be sent to main actor-isolated context” errors at `Sources/ISOInspectorApp/State/WindowSessionController.swift:211-220`.
- Warnings (not fatal but related):
  - `DocumentSessionBackgroundQueue.execute` captures a non-Sendable closure in a Dispatch queue.
  - `CoreDataAnnotationBookmarkStore.perform` captures non-Sendable values in `context.performAndWait`.
  - `AppShellView` exports non-Sendable function values into `@Sendable` actions.

## Environment
- Host: macOS (arm64), Swift 6.2.1 (swift-driver 1.127.14.1), target `arm64-apple-macosx26.0`.
- Command: `swift test --filter ISOInspectorKitTests.CorruptFixtureCorpusTests/testTolerantPipelineProcessesSmokeFixtures --filter ISOInspectorAppTests.UICorruptionIndicatorsSmokeTests/testTolerantParsingProducesCorruptionIndicatorsForSmokeFixtures`.
- Branch: local workspace (Task A7 context); no pending code changes beyond documentation and lint thresholds.

## Reproduction Steps
1. From repo root, run
   `swift test --filter ISOInspectorKitTests.CorruptFixtureCorpusTests/testTolerantPipelineProcessesSmokeFixtures --filter ISOInspectorAppTests.UICorruptionIndicatorsSmokeTests/testTolerantParsingProducesCorruptionIndicatorsForSmokeFixtures`
2. Build stops during `WindowSessionController.swift` compilation with the Sendable/actor-isolation errors described above; tests never start.

## Expected vs Actual
- Expected: Smoke test slice compiles and executes; strict concurrency checks pass.
- Actual: Build fails with Sendable/actor-isolation errors in `WindowSessionController` (plus related warnings in background queue and CoreData helper).

## Open Questions
- Should `DocumentLoadingResources` be `Sendable`, `@MainActor`, or avoided entirely by returning primitive values?
- Are `RandomAccessReader` and `ParsePipeline` meant to be used off-main and are they (or should they be) `Sendable`? If not, should background work be wrapped in a dedicated actor or confined to main?
- Should the factories (`readerFactory`, `pipelineFactory`) remain main-actor properties, or be passed in as `@Sendable` values to the detached task?
- Is `Task.detached` the right mechanism here, or should this be rewritten to use `Task { ... }` with `withTaskGroup` or `withCheckedThrowingContinuation` to keep actor boundaries explicit?

## Scope & Hypotheses
- Front of work: UI app layer — document/session loading pipeline in `WindowSessionController` and supporting background queue abstractions.
- Likely fix areas:
  - Rework the detached task to avoid capturing main-actor properties; either copy `@Sendable` factories into locals, mark them `@Sendable`, or perform work inside a dedicated actor/queue wrapper.
  - Make `DocumentLoadingResources` either `@unchecked Sendable` (if underlying types are safe) or refactor to return Sendable-safe primitives (e.g., URLs, config structs) while constructing non-Sendable objects on the consumer actor.
  - Update `DocumentSessionBackgroundQueue.execute` to accept `@Sendable` closures or wrap via `@MainActor` dispatch to silence Sendable warnings legitimately.
  - Add `@Sendable` annotations (or convert to actors) for `CoreDataAnnotationBookmarkStore.perform` captures if they remain on background queues.
- Impacted files: `Sources/ISOInspectorApp/State/WindowSessionController.swift` (primary), plus potential touch points in `DocumentSessionController.swift`, `DocumentSessionBackgroundQueue`, and CoreData helpers if warnings are addressed together.

## Diagnostics Plan
1. Inspect `WindowSessionController` around lines 190-230 to map actor isolation, `Task.detached` usage, and property access patterns.
2. Determine Sendable status of `RandomAccessReader`, `ParsePipeline`, and `ParsePipeline.Context`; decide whether to:
   - Keep construction on the main actor and move heavy work to a dedicated worker actor/queue, or
   - Mark types `@unchecked Sendable` only if they are thread-safe, or
   - Pass immutable configs to a worker and instantiate non-Sendable types back on the main actor.
3. Evaluate whether `DocumentLoadingResources` can be broken into smaller Sendable components to avoid returning non-Sendable types across actor boundaries.
4. Review background queue helpers (`DocumentSessionBackgroundQueue`, `CoreDataAnnotationBookmarkStore.perform`) to ensure `@Sendable` closures where applicable; decide whether warnings are acceptable or need fixes alongside the main error.
5. Re-run the smoke test filters under `swift test --strict-concurrency=complete` after refactors to confirm clean build.

## TDD Testing Plan
- Add/extend concurrency-focused tests in `ISOInspectorAppTests`:
  - A regression test that exercises `WindowSessionController` document loading with stub `readerFactory`/`pipelineFactory`, ensuring it completes without hitting Sendable/actor violations (can be a lightweight async test that drives the load pipeline with a temporary URL or in-memory stub).
  - Keep existing smoke tests (`UICorruptionIndicatorsSmokeTests`, tolerant pipeline smoke) in the filter list for verification.
- Optional: introduce a narrow unit test for `DocumentSessionBackgroundQueue.execute` using an `@Sendable` closure to ensure no Sendable warnings after refactor (if we change its signature).
- Maintain strict concurrency build flags in CI to prevent regression.

## PRD Alignment
- Customer impact: File-open smoke path is blocked by build errors; this blocks release validation and CI signal for core parsing flows.
- Acceptance criteria for the fix:
  - `swift test --strict-concurrency=complete` (or the existing strict-concurrency CI job) completes without Sendable/actor-isolation errors.
  - Smoke suites for tolerant parsing and UI corruption indicators execute and pass.
  - No new data races introduced; background work remains off the main thread where appropriate.

## Implementation Handoff
- Suggested next command for implementation: run `DOCS/COMMANDS/FIX.md` targeting this bug doc.
- Prereqs:
  - Decide the intended actor boundary for `WindowSessionController` document loading (background worker vs. main actor construction).
  - Confirm `RandomAccessReader`/`ParsePipeline` thread-safety if marking `@Sendable`/`@unchecked Sendable`.
- Deliverables for the FIX phase:
  - Refactored concurrency-safe document loading path with resolved Sendable errors.
  - Updated tests per the TDD plan.
  - Documentation updates (if any) noting concurrency invariants for document loading.
