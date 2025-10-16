# FilesystemAccessKit PRD — Secure Sandbox File Access

## 1. Purpose & Background
- Deliver a unified FilesystemAccessKit that mediates sandbox-compliant file access for ISOInspector targets across macOS, iOS, and iPadOS.
- Extend prior distribution work (**Task E4**) that established App Sandbox entitlements and notarization tooling by defining the runtime APIs and persistence model for security-scoped access.【../TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/54_E4_Prepare_App_Distribution_Configuration.md】
- Address non-functional requirement NFR-SEC-001, which mandates sandboxed operation with no implicit filesystem privileges.【02_Product_Requirements.md†L24-L29】

## 2. Objectives
| ID | Objective | Success Criteria |
|----|-----------|------------------|
| FS-OBJ-01 | Provide async APIs for opening, saving, and persisting access to user-selected files. | `FilesystemAccess.openFile`, `saveFile`, `createBookmark`, and `resolveBookmarkData` deliver security-scoped URLs validated by unit tests. |
| FS-OBJ-02 | Support platform-specific pickers while exposing a single shared interface. | macOS uses `NSOpenPanel`/`NSSavePanel`; iOS/iPadOS uses `UIDocumentPickerViewController`; CLI headless flows accept pre-authorized paths via sandbox profile allowances. |
| FS-OBJ-03 | Persist user consent using security-scoped bookmarks that survive app relaunch. | Bookmarks stored in App Support, restored on launch, and revoked when underlying files disappear. |
| FS-OBJ-04 | Maintain zero-trust logging with minimal exposure of absolute paths. | Logs redact user paths, tagging access events with hashed identifiers. |

## 3. Scope
- **In Scope**
  - Async Swift API surface matching the proposed interface from the feature brief.
  - Bookmark persistence, refresh, and error recovery flows.
  - UI integration hooks for SwiftUI document open/save actions and CLI argument parsing.
  - Sandbox configuration notes for entitlement management across app and CLI targets.
- **Out of Scope**
  - iCloud Drive/document provider synchronization (deferred roadmap item).
  - Cross-platform Linux implementation beyond mocked adapters.
  - User-facing bookmark management UI beyond existing recents/session views.

## 4. Dependencies & Research
| Dependency | Impact | Notes |
|------------|--------|-------|
| App Sandbox entitlements (`com.apple.security.files.user-selected.read-write`, `com.apple.security.files.bookmarks.app-scope`). | Required for persistent security-scoped bookmarks. | Already provisioned via Task E4 distribution deliverables; verify profiles remain current.【../TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/54_E4_Prepare_App_Distribution_Configuration.md】 |
| Security-Scoped Bookmark restoration behavior. | Necessary for bookmark expiry handling. | Document testing guidance; capture Apple docs references (Security Scoped Bookmarks, UIDocumentPicker). |
| CLI sandbox profile updates. | Required so headless tools can access authorized paths. | Align with packaging tasks tracked in `DOCS/INPROGRESS/next_tasks.md`. |

## 5. Implementation Plan
| Phase | Deliverable | Description |
|-------|-------------|-------------|
| P1 | FilesystemAccess core module | Implement `FilesystemAccess` singleton, platform adapters, and bookmark helpers with unit tests. |
| P2 | Persistence store & migration | Store bookmark metadata under Application Support; migrate existing recents/session data to reference bookmark IDs. |
| P3 | App integrations | Wire SwiftUI document commands, recents restoration, and error messaging to the new API. |
| P4 | CLI headless mode | Introduce CLI flags for using pre-scoped paths or requesting interactive authorization when available (macOS only). |
| P5 | Audit & logging | Ensure diagnostics redact paths, and update logging policies to align with zero-trust requirements. |

## 6. Compliance Checklist
- ✅ Use platform picker UI for all new access requests.
- ✅ Call `startAccessingSecurityScopedResource()`/`stopAccessing...` around file operations.
- ✅ Persist bookmark data with access timestamp for audit trail.
- ✅ Purge temporary files via `FileManager.default.temporaryDirectory`.
- ✅ Document sandbox profile updates for CLI automation. Guidance lives in `Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md` and mirrors the shipped entitlements.

## 7. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Bookmark stale or file removed. | Detect bookmark resolution failures, prompt user to re-authorize, and clean up stale entries. |
| CLI automation lacking UI context. | Support pre-authorized command-line arguments and note requirement for signed sandbox profiles. Documentation now captures the end-to-end flow, including bookmark rotation and verification. |
| Logging sensitive file paths. | Implement hashing + limited metadata logging, and update diagnostics tests. |

## 8. Open Questions
1. How should the app expose bookmark revocation to users (automatic cleanup vs. manual list)?
2. Do we require additional entitlements for external volumes (e.g., network shares) beyond user-selected read/write?
3. What audit retention period is necessary for access logs under zero-trust compliance policies?

## 9. Deliverables & Documentation Updates
- Add FilesystemAccessKit module spec to `03_Technical_Spec.md`.
- Extend workplan (`04_TODO_Workplan.md`) with a dedicated phase.
- Update backlog trackers (`ISOInspector_PRD_TODO.md`, `DOCS/INPROGRESS/next_tasks.md`).
- Record follow-up summary in `DOCS/INPROGRESS/Summary_of_Work.md` with outstanding questions.
- Reference Apple sandbox documentation in `06_Task_Source_Crosswalk.md` for traceability.
