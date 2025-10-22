# KeyValueRow Component Implementation

## 🎯 Objective
Implement the KeyValueRow component for displaying metadata key-value pairs with semantic styling, monospaced value fonts, and optional copyable text integration.

## 🧩 Context
- **Phase**: Phase 2.2 - Core Components
- **Layer**: Layer 2 - Essential Components (Molecules)
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ DS.Typography tokens (including `.code` for monospaced values)
  - ✅ DS.Spacing tokens
  - ✅ DS.Colors tokens
  - ⏸️ CopyableText utility (Phase 4.2 - can be deferred, implement basic version first)

## ✅ Success Criteria
- [ ] Unit tests written and passing (≥85% component coverage)
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Preview included (≥4 variations)
- [ ] DocC documentation complete (100% public API)
- [ ] Accessibility labels added (VoiceOver support)
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS 17+/macOS 14+/iPadOS 17+)
- [ ] Monospaced font used for values (DS.Typography.code)
- [ ] Multiple layout variants supported (horizontal, vertical)
- [ ] Copyable text integration (basic version without Phase 4.2 dependency)

## 🔧 Implementation Notes

### Component API Design
Based on PRD examples:
```swift
// Basic usage
KeyValueRow(key: "Type", value: "ftyp")

// With copyable text
KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)

// Proposed full API
KeyValueRow(
    key: String,
    value: String,
    layout: KeyValueLayout = .horizontal,
    copyable: Bool = false
)

enum KeyValueLayout {
    case horizontal  // Key and value side-by-side
    case vertical    // Key above value (for long values)
}
```

### Files to Create/Modify
- **Component**: `Sources/FoundationUI/Components/KeyValueRow.swift`
- **Tests**: `Tests/FoundationUITests/ComponentsTests/KeyValueRowTests.swift`

### Design Token Usage
- **Spacing**:
  - `DS.Spacing.s` - Tight spacing between key and value (horizontal)
  - `DS.Spacing.xs` (if available) or `DS.Spacing.s/2` - Vertical spacing in vertical layout
  - `DS.Spacing.m` - Padding around component
- **Typography**:
  - `DS.Typography.body` or `DS.Typography.caption` - For keys
  - `DS.Typography.code` - For values (monospaced for hex, bytes, technical data)
- **Colors**:
  - System default foreground colors
  - Optional: Secondary color for keys to differentiate from values

### Key Features
1. **Semantic Styling**: Clear visual distinction between key and value
2. **Monospaced Values**: Use `DS.Typography.code` for technical content alignment
3. **Layout Variants**: Support both horizontal (compact) and vertical (long values) layouts
4. **Copyable Text**: Basic clipboard integration for `copyable: true` parameter
5. **Accessibility**: Proper VoiceOver labels ("Key: value" format)
6. **Keyboard Hints**: Display keyboard shortcut indicators if copyable

### Accessibility Requirements
- VoiceOver should read: "Type, value: ftyp" (or similar semantic structure)
- Copyable values should announce "Double-tap to copy" hint
- Support Dynamic Type sizing
- Maintain proper touch target size (≥44×44 pt) for interactive elements

### Testing Strategy
**Unit Tests** (≥12 test cases):
- Test basic key-value rendering
- Test horizontal vs vertical layout
- Test copyable text integration
- Test accessibility labels
- Test Dynamic Type scaling
- Test platform-specific rendering
- Test long key/value text wrapping
- Test empty/nil value handling (if supported)

**Preview Variations** (≥4):
1. Basic horizontal layout
2. Vertical layout with long value
3. Copyable text variant
4. Dark Mode comparison
5. Multiple KeyValueRows in VStack (catalog view)

## 🧠 Source References
- [FoundationUI Task Plan § Phase 2.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § 5.2 Component API Examples](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Badge Component Implementation](../../Sources/FoundationUI/Components/Badge.swift) - Reference for component structure
- [SectionHeader Component Implementation](../../Sources/FoundationUI/Components/SectionHeader.swift) - Reference for typography usage

## 📋 Checklist
- [ ] Read task requirements from Task Plan and PRD
- [ ] Create test file `KeyValueRowTests.swift`
- [ ] Write failing unit tests for basic functionality
- [ ] Run `swift test` to confirm failure
- [ ] Implement KeyValueRow component using DS tokens
- [ ] Implement horizontal layout variant
- [ ] Implement vertical layout variant
- [ ] Implement basic copyable text (without Phase 4.2 CopyableText utility)
- [ ] Run `swift test` to confirm tests pass
- [ ] Add comprehensive SwiftUI Previews (≥4 variations)
- [ ] Add DocC documentation comments (100% public API)
- [ ] Run `swiftlint` and fix violations (target: 0)
- [ ] Test on iOS simulator (verify Dynamic Type)
- [ ] Test on macOS (verify platform adaptation)
- [ ] Update Task Plan with [x] completion mark
- [ ] Update `next_tasks.md` progress tracker
- [ ] Commit with descriptive message following TDD workflow

## 🚀 Implementation Approach

### Phase 1: TDD - Write Tests First
1. Create `KeyValueRowTests.swift`
2. Write failing tests for:
   - Basic rendering (key + value)
   - Horizontal layout
   - Vertical layout
   - Accessibility labels
   - Copyable text behavior
3. Run tests → Expect failures ❌

### Phase 2: Minimal Implementation
1. Create `KeyValueRow.swift`
2. Implement minimal struct to pass tests
3. Use `@ViewBuilder` for layout flexibility
4. Apply DS tokens (zero magic numbers)
5. Run tests → Expect success ✅

### Phase 3: Polish & Documentation
1. Add SwiftUI Previews (Light/Dark, layouts, copyable)
2. Add DocC comments
3. Run SwiftLint
4. Manual testing on simulators
5. Final verification

## 📝 Notes
- **CopyableText Integration**: Implement basic clipboard functionality inline for now. Phase 4.2 will introduce a reusable CopyableText utility component that can be refactored later.
- **Layout Flexibility**: Consider if layout should be automatic based on value length, or always manual via parameter.
- **Platform Adaptation**: macOS may benefit from smaller default spacing (use `DS.Spacing.platformDefault`).
- **Keyboard Shortcuts**: For copyable variant, consider showing "⌘C" hint on macOS (defer to Phase 4.2 if complex).

---

**Status**: 🔄 IN PROGRESS
**Started**: 2025-10-22
**Target Completion**: 2025-10-22 (M - 4-6 hours)
