# Accessibility Guidelines for Tree, Detail, and Hex Views

## Purpose and Scope
- Reinforce non-functional requirement **NFR-USAB-001** by capturing VoiceOver, Dynamic Type, and keyboard navigation guardrails for ISOInspector’s primary SwiftUI surfaces.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L21-L28】
- Applies to the parse tree explorer, detail inspector, and hex viewer that share state via `InspectorFocusTarget` and NestedA11yIDs identifiers.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L32-L136】【F:Sources/ISOInspectorApp/Accessibility/InspectorFocusTarget.swift†L1-L6】

## Shared Accessibility Checklist

### VoiceOver and Identifiers
- Maintain NestedA11yIDs coverage for every interactive element so automation remains aligned with previews and XCTest suites.【F:Documentation/ISOInspector.docc/Guides/NestedA11yIDsIntegration.md†L4-L47】【F:Tests/ISOInspectorAppTests/ParseTreeAccessibilityIdentifierTests.swift†L8-L157】
- Keep accessibility descriptors in sync with metadata helpers (`AccessibilityDescriptor`, `HexByteAccessibilityFormatter`) so VoiceOver reads semantic labels instead of raw codes.【F:Sources/ISOInspectorApp/Accessibility/AccessibilitySupport.swift†L6-L78】【F:Sources/ISOInspectorApp/Accessibility/HexByteAccessibilityFormatter.swift†L4-L13】
- When adding new controls, mirror the identifier path conventions (`ParseTreeAccessibilityID`, `ResearchLogAccessibilityID`) and extend identifier tests accordingly.【F:Tests/ISOInspectorAppTests/ParseTreeAccessibilityIdentifierTests.swift†L41-L138】

### Keyboard and Focus Synchronization
- Preserve the cross-pane focus commands (`⌘⌥1`–`⌘⌥4`) and `InspectorFocusTarget` routing so macOS VoiceOver and hardware keyboards can switch panes without pointer input.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L32-L137】
- Keep `InspectorFocusShortcutCatalog` as the source of truth for command ordering, titles, and key mappings so menus, discoverability HUDs, and hidden shortcuts stay synchronized across macOS and iPadOS.【F:Sources/ISOInspectorApp/Accessibility/InspectorFocusShortcuts.swift†L1-L31】【F:Sources/ISOInspectorApp/ISOInspectorApp.swift†L20-L48】
- Share focus bindings with the scene using `focusedSceneValue` so the dedicated **Focus** command menu can hand control back to the outline, detail, notes, or hex panes while updating `.focused` modifiers within the explorer view.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L72-L104】【F:Sources/ISOInspectorApp/Accessibility/FocusedValues+InspectorFocusTarget.swift†L1-L13】
- Add focus cases for new panes and ensure `.focused` bindings and `.compatibilityFocusable()` wrappers are applied when introducing custom container views.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L43-L47】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L221-L238】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L343-L376】

### Dynamic Type and Layout Scaling
- Respect dynamic type ranges from `.medium ... .accessibility5` in scrollable regions, and verify new typography choices do not clip at the largest accessibility sizes.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L42-L56】
- Prefer SwiftUI’s semantic fonts (`.title3`, `.body`, `.caption`) to inherit size categories automatically across the outline, detail, and annotation components.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L421-L446】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L86-L213】

## Parse Tree Explorer Guidelines

### VoiceOver
- Leverage `ParseTreeOutlineRow.accessibilityDescriptor` to announce names, box types, validation severity, descendants, and bookmark state; update the formatter whenever new row badges or states are introduced.【F:Sources/ISOInspectorApp/Accessibility/AccessibilitySupport.swift†L12-L50】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L412-L512】
- Keep bookmark toggles exposing “Add/Remove bookmark” labels and respect annotation session availability when disabling the control.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L482-L492】

### Dynamic Type
- Confirm filter chips and outline rows remain legible at accessibility text sizes; rely on intrinsic padding and avoid hard-coded heights so text can wrap naturally.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L199-L239】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L421-L447】
- Validate empty states and status labels in ContentUnavailableView for iOS 17+/macOS 14+ as well as the fallback VStack path for older platforms.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L311-L334】

### Keyboard Navigation
- Maintain `.onMoveCommand` handling so arrow keys map to outline navigation, including collapse/expand behavior for left/right and selection persistence when no new node is available.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L296-L407】
- Ensure row tap gestures set `focusTarget = .outline` to keep keyboard navigation anchored after pointer interaction.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L254-L305】

### Verification Steps
- Run `ParseTreeAccessibilityIdentifierTests` whenever new outline controls are added to confirm identifier propagation stays stable.【F:Tests/ISOInspectorAppTests/ParseTreeAccessibilityIdentifierTests.swift†L8-L157】
- Use Accessibility Inspector rotor for “Headings” and “Links” to confirm VoiceOver surfaces row metadata and bookmark actions; capture findings in the task archive if adjustments are needed.

## Detail Inspector Guidelines

### VoiceOver
- Keep `ParseTreeNodeDetail.accessibilitySummary` authoritative for the metadata section; update when adding new metadata fields so the summary remains comprehensive.【F:Sources/ISOInspectorApp/Accessibility/AccessibilitySupport.swift†L52-L78】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L86-L125】
- Ensure annotation lists expose combined labels (range, value, optional summary) and add `accessibilityAddTraits(.isSelected)` when highlight state changes.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L250-L289】
- Route validation issue rows through `.accessibilityLabel` that includes rule identifiers and severity descriptions so screen readers convey urgency.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L317-L341】

### Dynamic Type
- Validate annotation composer, metadata grid, and validation rows under the accessibility size range to prevent clipping; rely on semantic fonts and `.textSelection(.enabled)` to aid low-vision copy workflows.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L126-L213】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L220-L238】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L317-L335】

### Keyboard Navigation
- Keep bookmark buttons, annotation editors, and copy actions reachable via hardware keyboard by ensuring they inherit button styles and focus states within the `.detail` focus scope.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L138-L214】
- When introducing new subsections, assign NestedA11yIDs identifiers and bind `.focused` or `.focusSection()` modifiers as needed so `⌘⌥2` continues to land inside the detail column.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L47-L55】

### Verification Steps
- Extend `ParseTreeAccessibilityFormatterTests` when augmenting metadata or validation descriptors to guarantee VoiceOver text remains stable.【F:Tests/ISOInspectorAppTests/ParseTreeAccessibilityFormatterTests.swift†L6-L93】
- Audit with Accessibility Inspector’s “Traits” pane to confirm the metadata card is announced as a combined element and annotation rows expose selection traits.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L98-L214】

## Hex Viewer Guidelines

### VoiceOver
- Continue delegating per-byte announcements to `HexByteAccessibilityFormatter` so offsets and highlight state are verbalized; update formatter copy when adding grouping or ASCII annotations.【F:Sources/ISOInspectorApp/Accessibility/HexByteAccessibilityFormatter.swift†L4-L13】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L343-L420】
- Hide redundant ASCII cells from accessibility (`.accessibilityHidden(true)`) to prevent duplicate announcements while still offering textual cues visually.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L464-L489】

### Dynamic Type
- Verify hex grids maintain readability by allowing horizontal scrolling and refraining from fixed-width clipping; adjust `bytesPerRow` if larger accessibility sizes require fewer columns.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L397-L420】
- Ensure offset labels remain monospaced and secondary colored for contrast without reducing accessibility compliance.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L446-L476】

### Keyboard Navigation
- Preserve AppKit move command handling so arrow keys adjust the highlighted byte and keep scroll position synchronized.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L439-L496】
- When adding new selection behaviors (e.g., range expansion), update `select(offset:)` to continue forcing focus to `.hex` and refresh the highlighted range before issuing scroll commands.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L471-L505】

### Verification Steps
- Keep `ParseTreeAccessibilityFormatterTests.testHexByteFormatterAnnouncesSelectionAndOffset` passing after modifying formatter strings or selection logic.【F:Tests/ISOInspectorAppTests/ParseTreeAccessibilityFormatterTests.swift†L88-L93】
- During manual QA, enable the Accessibility Inspector’s “Hearing” > “Play” feature to confirm per-byte VoiceOver narration while resizing the window and toggling highlighted ranges.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L397-L476】

## Follow-Up Tracking
- Document any new gaps (e.g., rotor categories for validation issues, phonetic spellings for hex bytes) as `@todo` comments paired with `todo.md` entries and archive notes so research follow-ups remain traceable.【F:DOCS/RULES/04_PDD.md†L9-L78】
- Update `DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md` whenever guidelines evolve to capture rationale, verification runs, and outstanding accessibility research items.
