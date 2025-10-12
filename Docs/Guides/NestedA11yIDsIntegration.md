# NestedA11yIDs Integration Guide

## Overview
NestedA11yIDs standardizes hierarchical accessibility identifiers for SwiftUI views.
This guide summarizes the ISOInspector App integration and codifies conventions for
future development and UI test automation.

## Dependency setup
1. `Package.swift` includes `NestedA11yIDs` from `1.0.0`.
2. The `ISOInspectorApp` target conditionally links the product on iOS and macOS.
3. Build verification: `swift build --target ISOInspectorApp` or `swift test` (preferred).

## Usage checklist
- Import `NestedA11yIDs` in SwiftUI files compiled for the App target.
- Wrap top-level screens with `.a11yRoot("<screen>")`.
- Apply `.nestedAccessibilityIdentifier("component")` to subsections and control groups.
- Prefer centralized constants (see `ParseTreeAccessibilityID`).
- Compose identifiers by defining dot-free segments that the library joins into dotted paths (e.g., root `parseTree`, child `outline`, leaf `filters`, etc.).
- Avoid localized strings or dynamic data in identifiers.

## Naming conventions
| Scope | Example constant | Resulting ID |
| --- | --- | --- |
| Screen root | `ParseTreeAccessibilityID.root` | `parseTree` |
| Outline filters | `ParseTreeAccessibilityID.Outline.Filters.searchField` | `parseTree.outline.filters.searchField` |
| Outline row bookmark | `ParseTreeAccessibilityID.Outline.List.rowBookmark(42)` | `parseTree.outline.list.row.42.bookmark` |
| Detail sections | `ParseTreeAccessibilityID.Detail.metadata` | `parseTree.detail.metadata` |
| Research log diagnostics | `ResearchLogAccessibilityID.Diagnostics.row(0)` | `researchLogPreview.diagnostics.row.0` |

Guidelines:
- Use lowercase English slugs for each segment (no literal dots inside the segment values).
- Prefer semantic names (`filters` + `searchField`) over visual positions.
- Keep identifiers stable when views re-order.

## Testing identifiers
1. Unit tests (`ParseTreeAccessibilityIdentifierTests`) host the SwiftUI hierarchy and assert the composed identifiers exist.
2. UI automation should reference the dotted IDs via `XCUIApplication().descendants(matching: .any)["<id>"]`.
3. For additional probes, embed temporary readers that inspect `Environment(\.accessibilityPrefix)` during previews.

## Migration roadmap
- Parse tree explorer and detail panes now emit rooted identifiers.
- Research log preview flows (`ResearchLogAuditPreview.swift`) expose the `researchLogPreview` hierarchy for headers, metadata,
  and diagnostics.
- Remaining candidates:
  - Annotation editors beyond bookmark controls.
  - Future inspectors (e.g., timeline, payload analyzers).
- Track follow-ups as `@todo` entries in code and `todo.md`.

## CI expectations
- `swift test` exercises identifier coverage and dependency resolution.
- Future UI test harnesses should reuse the constants to avoid drift.
- Document new identifiers in release notes when screens ship.
