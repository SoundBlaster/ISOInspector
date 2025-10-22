# C19 — Validation Preset UI Settings Integration

## Overview
- Added validation metadata support across `ParseTree`, JSON exports, and session snapshots so downstream consumers understand the active preset and disabled rules.
- Introduced persistence for validation configuration defaults and workspace overrides, exposing preset/rule operations on `DocumentSessionController`.
- Implemented the macOS `ValidationSettingsView` scene to switch scopes, select presets, toggle individual rules, and reset workspace overrides.

## Verification
- `swift test`

## Follow-ups
- Manual SwiftUI QA for the new settings pane (preset selection, custom badge, reset action).
- Thread validation configuration flags through ISOInspectorCLI (Task D7) to complete end-to-end preset coverage.
