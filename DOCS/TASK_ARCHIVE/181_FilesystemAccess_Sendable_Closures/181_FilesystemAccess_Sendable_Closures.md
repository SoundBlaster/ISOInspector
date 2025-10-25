# FilesystemAccess Sendable Closure Compliance

## 🎯 Objective
Eliminate Swift concurrency warnings triggered when `FilesystemAccess` captured non-Sendable bookmark helpers so the app builds cleanly under strict Sendable checking on both macOS and iOS targets.

## 🧩 Context
- `FilesystemAccess` stores its dialog handlers as `@Sendable` function typealiases. Passing instance methods such as `FoundationBookmarkDataManager.createBookmark(for:)` directly caused the compiler to complain about "Converting non-Sendable function value…" when building with `SWIFT_STRICT_CONCURRENCY`.
- The warnings originated in the shared live factory (`FilesystemAccess+Live.swift`) and every test harness that referenced the same bookmark manager methods, leading to noisy builds and masking real concurrency issues.

## ✅ Fix Summary
1. Wrapped bookmark manager method calls in inline closures that immediately invoke the underlying manager (`{ url in try bookmarkManager.createBookmark(for: url) }` and `{ data in try bookmarkManager.resolveBookmark(data: data) }`). This makes the Sendable contract explicit without changing behavior (`Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess+Live.swift`).
2. Mirrored the same closure pattern across all FilesystemAccess unit tests so their `FilesystemAccess` initializers match production usage (`Tests/ISOInspectorKitTests/FilesystemAccessTests.swift`).
3. Required callers to pass an explicit clock closure (`makeDate`) to `FilesystemAccessLogger` so Sendable loggers never capture implicit defaults; updated the CLI factory and `.disabled` singleton accordingly (`Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccessLogger.swift`, `Sources/ISOInspectorCLI/CLI.swift`).
4. Verified `swift build` completes without the Sendable warnings, keeping CI noise-free.

## 🧠 Source References
- `Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess+Live.swift`
- `Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccessLogger.swift`
- `Sources/ISOInspectorCLI/CLI.swift`
- `Tests/ISOInspectorKitTests/FilesystemAccessTests.swift`
