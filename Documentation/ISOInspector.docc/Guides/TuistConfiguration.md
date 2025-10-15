# Tuist Configuration Guide

This guide explains how ISOInspector encodes its multi-platform targets, shared distribution metadata, and developer workflows in Tuist manifests.

## Manifest overview
- `Project.swift` is the canonical Tuist manifest. It loads distribution metadata, defines helper functions for locating the repository, and exposes shared constants used by every target.【F:Project.swift†L4-L69】
- The manifest models each supported platform through the `DistributionPlatform` enum and helper methods that resolve destinations and deployment targets for macOS, iOS, and iPadOS builds.【F:Project.swift†L29-L89】
- `tuist generate` should be run from the repository root to materialize an Xcode project backed by these manifests and metadata.【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L121-L130】

## Distribution metadata inputs
- Marketing version, build number, team identifier, and bundle identifiers live in `Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json`. Keep these values authoritative so the manifest, documentation, and CI builds stay synchronized.【F:Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json†L1-L21】
- The manifest resolves the repository directory dynamically to ensure the JSON file is discoverable even when Tuist compiles manifests in its cache, preventing path issues during automation.【F:Project.swift†L35-L60】

## Target definitions
- Shared base build settings (marketing version and build number) are applied to every target via the `baseSettings` dictionary.【F:Project.swift†L64-L69】
- The universal framework target (`ISOInspectorKit`) shares source and resource globs across macOS, iPhone, and iPad destinations, exposing a single bundle identifier for every platform.【F:Project.swift†L91-L104】
- Application targets wrap the framework, attach platform-specific entitlements, and depend on the `NestedA11yIDs` package for accessibility tooling.【F:Project.swift†L106-L135】
- CLI targets (`ISOInspectorCLI` and `ISOInspectorCLIRunner`) expose command-line functionality and pull in `swift-argument-parser` alongside the macOS framework.【F:Project.swift†L139-L169】
- Remote Swift Package dependencies for accessibility IDs and ArgumentParser are declared at the project level so Tuist resolves them consistently during generation.【F:Project.swift†L172-L191】

## Entitlements and security
- Entitlement files referenced in the manifest live under `Distribution/Entitlements/`. Update them in concert with metadata changes so Tuist continues to inject the correct sandbox capabilities.【F:Distribution/Entitlements/ISOInspectorApp.macOS.entitlements†L1-L15】【F:Project.swift†L117-L135】

## Maintenance checklist
- When shipping a new release, bump marketing version or build number in the JSON metadata and regenerate the project; Tuist will propagate the values to all targets automatically.【F:Project.swift†L64-L69】【F:Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json†L1-L21】
- Adding a new Apple platform requires updating the JSON metadata, extending `DistributionPlatform`, and adding corresponding target builders that follow the existing pattern for destinations, entitlements, and dependencies.【F:Project.swift†L29-L137】
- Keep dependency versions aligned with supported tooling by adjusting the Tuist package declarations before running `tuist fetch` or `tuist generate` in CI.【F:Project.swift†L172-L191】
