# ISOInspector App Manual (Draft)

The ISOInspector SwiftUI application will provide interactive MP4/QuickTime inspection per the product requirements. This draft ties future work to tasks C1–C5 and E1–E4 of the execution workplan.

## Current State
- SwiftUI entry point renders the parse tree explorer with detail pane, live payload
  annotations, and CoreData-backed notes/bookmark controls.
- Linux-compatible fallback prints the same welcome summary for developers without SwiftUI.
- Annotation and bookmark persistence runs through
  `CoreDataAnnotationBookmarkStore`. The detail pane now exposes bookmarking,
  note creation/editing, and deletion for the selected box; outline rows
  display bookmark toggles that sync instantly with the store.

## Planned Features
1. Document browser and recent files list (E1).
2. Streaming tree and detail panes (C1–C3).
3. Annotation and bookmark persistence (C4) — live in-app editing is now
   available; future work covers synchronization with additional sessions.
4. Accessibility compliance and keyboard navigation (C5).
5. Distribution readiness including entitlements and notarization (E4).

Update this manual with screenshots, workflows, and troubleshooting notes as features land.

## Distribution Configuration (E4)

- **Bundle identifiers** — All platforms share the product name `ISOInspector` with platform-specific bundle identifiers:
  - macOS: `com.isoinspector.app.mac`
  - iOS: `com.isoinspector.app.ios`
  - iPadOS: `com.isoinspector.app.ipados`
- **Versioning** — Marketing version `0.1.0` and build number `1` are declared in `DistributionMetadata.json`. Update this file
  when incrementing releases so automation and documentation stay in sync.【F:Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json†L1-L21】
- **Entitlements** — Platform-specific plist files live under `Distribution/Entitlements/`. macOS enables the App Sandbox with
  security-scoped bookmarks for persisted document access. iOS and iPadOS inherit the default sandbox configuration.【F:Distribution/Entitlements/ISOInspectorApp.macOS.entitlements†L1-L13】【F:Distribution/Entitlements/ISOInspectorApp.iOS.entitlements†L1-L7】【F:Distribution/Entitlements/ISOInspectorApp.iPadOS.entitlements†L1-L7】
- **Notarization workflow** — Use `scripts/notarize_app.sh` with a zipped `.app` bundle. Supply the `--dry-run` flag on Linux
  hosts or configure a keychain profile (`NOTARYTOOL_PROFILE`) on macOS builders.【F:scripts/notarize_app.sh†L1-L75】
- **Xcode project generation** — `Tuist/Project.swift` consumes the shared distribution metadata to stamp bundle identifiers,
  entitlements, and marketing/build versions into generated `.xcodeproj` files.【F:Tuist/Project.swift†L1-L111】
