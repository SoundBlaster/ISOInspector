# Phase 2.2 - Implement CopyableText Utility Component

**Status**: 🚧 In Progress (initiated 2025-10-25)
**Phase / Layer**: Phase 2.2 – Essential Components (Layer 2)
**Priority**: P0 (Critical)

---

## 🎯 Objective

Implement a reusable `CopyableText` utility component that provides platform-specific clipboard integration with visual feedback. This component will be used within `KeyValueRow` and other components where users need to copy technical data (hex values, IDs, offsets).

## 🧩 Context

The `KeyValueRow` component currently includes inline copyable text functionality. To improve code reuse and consistency, we need to extract this into a dedicated utility component that can be used across the entire FoundationUI framework.

### Key Requirements (from FoundationUI PRD)
- **Platform-specific clipboard**: Use `NSPasteboard` on macOS, `UIPasteboard` on iOS
- **Visual feedback**: Animation or toast notification on copy
- **Keyboard shortcut**: Support ⌘C (macOS) / Ctrl+C (iOS) when focused
- **Accessibility**: VoiceOver announcement on successful copy
- **Design System compliance**: Use DS tokens exclusively (zero magic numbers)

### Integration Points
- Used by: `KeyValueRow`, future inspector components
- Depends on: `DS.Animation`, `DS.Spacing`, `DS.Typography`
- Layer: Utilities (shared across components)

## ✅ Success Criteria

### Implementation
- [ ] Create `Sources/FoundationUI/Utilities/CopyableText.swift`
- [ ] Public API: `CopyableText(text: String, label: String?)`
- [ ] Platform-specific clipboard handling (`#if os(macOS)` / `#else`)
- [ ] Visual feedback animation (fade-in "Copied!" indicator)
- [ ] Keyboard shortcut support (platform-specific)
- [ ] Zero magic numbers (100% DS token usage)
- [ ] 100% DocC documentation with usage examples

### Testing
- [ ] Create `Tests/FoundationUITests/UtilitiesTests/CopyableTextTests.swift`
- [ ] Unit tests for clipboard operations (mocked)
- [ ] Unit tests for visual feedback state
- [ ] Unit tests for keyboard shortcut handling
- [ ] Accessibility tests (VoiceOver labels)
- [ ] Platform-specific tests (macOS vs iOS behavior)
- [ ] ≥80% code coverage

### Quality Assurance
- [ ] SwiftLint: 0 violations
- [ ] SwiftUI Preview with interactive demo
- [ ] Integration test with `KeyValueRow`
- [ ] Accessibility audit (VoiceOver, Dynamic Type)

## 🔧 Implementation Notes

### API Design
```swift
/// A utility component for displaying copyable text with visual feedback
public struct CopyableText: View {
    public init(text: String, label: String? = nil)

    public var body: some View
}
```

### Platform-Specific Clipboard
```swift
#if os(macOS)
import AppKit
// Use NSPasteboard
#else
import UIKit
// Use UIPasteboard
#endif
```

### Visual Feedback States
- Default: Show copy icon/button
- Copying: Animate feedback
- Copied: Show "Copied!" indicator briefly
- Return to default

### Design System Usage
- Spacing: `DS.Spacing.s`, `DS.Spacing.m`
- Animation: `DS.Animation.quick` for feedback
- Typography: `DS.Typography.caption` for "Copied!" label
- Colors: `DS.Color.accent` for copy indicator

### Accessibility
- Button label: "Copy {value}"
- VoiceOver announcement: "{value} copied to clipboard"
- Keyboard shortcut hint in accessibility label

## 🧠 Source References

- [FoundationUI Task Plan](../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#22-layer-2-essential-components-molecules)
- [FoundationUI PRD](../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) - Layer 2 components
- [KeyValueRow Implementation](../../../Sources/FoundationUI/Components/KeyValueRow.swift) - Current copyable text integration
- [TDD Workflow Rules](../../../DOCS/RULES/02_TDD_XP_Workflow.md) - Test-first development
- [Code Structure Principles](../../../DOCS/RULES/07_AI_Code_Structure_Principles.md) - One entity per file

## 📁 File Locations

### Source Files
- `Sources/FoundationUI/Utilities/CopyableText.swift` (new)
- Update `Sources/FoundationUI/Components/KeyValueRow.swift` (integration)

### Test Files
- `Tests/FoundationUITests/UtilitiesTests/CopyableTextTests.swift` (new)

### Documentation
- DocC comments in source file
- SwiftUI Preview in source file

## 🔄 Dependencies

### Prerequisites (All Satisfied)
- ✅ DS.Animation tokens (Phase 1.2)
- ✅ DS.Spacing tokens (Phase 1.2)
- ✅ DS.Typography tokens (Phase 1.2)
- ✅ DS.Color tokens (Phase 1.2)
- ✅ SwiftUI framework
- ✅ Platform APIs (NSPasteboard / UIPasteboard)

### Blocks
- None (all dependencies satisfied)

## 🚀 Next Steps

1. **Write failing tests first** (TDD workflow)
   - Create `CopyableTextTests.swift`
   - Define expected API and behavior
   - Run `swift test` to confirm failures

2. **Implement minimal working version**
   - Create `CopyableText.swift`
   - Implement basic clipboard copy
   - Add visual feedback state

3. **Refactor and polish**
   - Add keyboard shortcuts
   - Enhance visual feedback animation
   - Complete DocC documentation

4. **Integration**
   - Update `KeyValueRow` to use `CopyableText`
   - Remove duplicate clipboard logic
   - Verify all tests pass

5. **Archive**
   - Create summary in `TASK_ARCHIVE/20_Phase2.2_CopyableText/`
   - Update Task Plan progress
   - Mark task complete in `next_tasks.md`

---

**Created**: 2025-10-25
**Assigned**: Claude
**Estimated Time**: 2-3 hours (S-M task size)
