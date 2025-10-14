# Distribution scaffolding — micro PRD

## Intent

Ship initial distribution metadata, entitlements, and notarization tooling so the ISOInspector app bundle is ready for
signed
macOS/iOS builds.

## Scope

- Kit: `DistributionMetadataLoader`, `DistributionMetadata` resource (bundle IDs, versioning, team identifier)
- CLI: No changes required; tooling consumes kit metadata indirectly.
- App: Distribution entitlements stored in `Distribution/Entitlements/` for platform builds.

## Integration contract

- Public Kit API added/changed: `DistributionMetadataLoader.defaultMetadata()` decodes versioned configuration.
- Call sites updated: New XCTest `DistributionMetadataTests` ensures metadata loads under SwiftPM.
- Backward compat: Additive resource and loader; no existing APIs modified.
- Tests: `Tests/ISOInspectorKitTests/DistributionMetadataTests.swift` validates metadata decoding.

## Next puzzles

- [ ] Evaluate Apple Events entitlements once CLI-to-App notarized workflows are defined (mirrors @todo PDD:30m).

## Notes

Build: `swift build && swift test`
