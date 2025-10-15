## 56 — Tuist Compatibility Fixes (2025-10-15)

- Restored iOS and macOS app builds after lowering deployment targets in the Tuist manifest.
- Wrapped iOS 17-only SwiftUI APIs (`onChange(initial:)`, `ContentUnavailableView`, `focusable`) in helpers that fall back to older equivalents.
- Replaced `.foregroundStyle` usage with `.foregroundColor` so colour styling compiles on iOS 16 and macOS 13.
- Verified `xcodebuild` for `ISOInspectorApp-iOS` (simulator) and `ISOInspectorApp-macOS`, plus `swift build`.
