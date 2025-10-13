# E4 — Prepare App Distribution Configuration

## 🎯 Objective

Establish the ISOInspector app's distribution scaffolding by defining bundle identifiers, configuring required
entitlements, and validating notarization tooling so macOS builds are ready for signing and release workflows.

## 🧩 Context

- Phase E of the execution workplan shifts from session persistence into packaging activities; Task E4 depends on the
  integrated app shell delivered by E2 so that distribution settings apply to the functioning UI
  target.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L39-L45】
- The technical spec requires release artifacts to include a notarized app bundle, meaning distribution configuration
  must cover signing identities and automation hooks for CI
  delivery.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L89-L104】
- Packaging and sandboxing updates in Task E4 directly unblock downstream release documentation and entitlement
  hardening tracked in the packaging backlog.【F:DOCS/AI/ISOInspector_PRD_TODO.md†L246-L251】

## ✅ Success Criteria

- Bundle identifiers and versioning metadata recorded for macOS, iPadOS, and iOS targets and referenced by CI build
  scripts.
- App sandbox entitlements finalized for file access, bookmark persistence, and optional automation hooks, with
  validation via signing tools.
- Notarization pipeline exercised end-to-end (locally or via CI) to confirm the packaged app is accepted by Apple
  notarization services.
- Documentation updates summarizing distribution settings and prerequisites for future automation tasks.

## 🔧 Implementation Notes

- Inventory existing Xcode project settings (targets, provisioning profiles) and align them with SwiftPM package
  structure to avoid duplicated identifier definitions.
- Define entitlement files (.entitlements) per platform variant covering sandbox, security-scoped bookmarks, and
  automation/test allowances, and add regression checks in CI to flag unexpected diffs.
- Script notarization flows using `notarytool` with placeholder credentials, ensuring secrets are injected through CI secure storage and providing dry-run guidance for local validation.
- Coordinate with documentation tasks (F4, F5) so user manuals and release checklists inherit accurate bundle IDs,
  signing identities, and notarization verification steps once E4 stabilizes the configuration.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md)
