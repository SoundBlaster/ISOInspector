# Next Tasks for FoundationUI

**Last Updated**: 2025-10-21
**Current Phase**: Phase 2.2 - Layer 2: Essential Components (Molecules)

---

## Immediate Priority (Phase 2.2)

### 1. Badge Component
- **Status**: Ready to start
- **Priority**: P0 (Critical)
- **Dependencies**: BadgeChipStyle modifier ✅ COMPLETE
- **Estimated Effort**: S (2-4 hours)
- **File**: `Sources/FoundationUI/Components/Badge.swift`

**Why now**: BadgeChipStyle modifier is complete and tested. Badge component is the simplest molecule to implement and will validate our component architecture.

**Requirements**:
- Public initializer: `Badge(text: String, level: BadgeLevel)`
- Use BadgeChipStyle modifier internally
- Full VoiceOver support
- 4+ SwiftUI Previews (all levels, light/dark mode)
- Unit tests for all badge levels
- DocC documentation with usage examples

---

### 2. Card Component
- **Status**: Ready to start
- **Priority**: P0 (Critical)
- **Dependencies**: CardStyle modifier ✅ COMPLETE
- **Estimated Effort**: M (4-6 hours)
- **File**: `Sources/FoundationUI/Components/Card.swift`

**Why now**: CardStyle modifier is complete. Card component is needed for many higher-level patterns and will be heavily reused.

**Requirements**:
- Generic content with `@ViewBuilder`
- Configurable elevation (none, low, medium, high)
- Configurable corner radius via DS.Radius tokens
- Material background support (optional)
- Comprehensive previews showing various content types
- Unit tests for all elevation levels
- Integration tests with nested components
- DocC documentation

---

### 3. KeyValueRow Component
- **Status**: Ready to start
- **Priority**: P0 (Critical)
- **Dependencies**: DS.Typography ✅, DS.Spacing ✅
- **Estimated Effort**: M (4-6 hours)
- **File**: `Sources/FoundationUI/Components/KeyValueRow.swift`

**Why now**: Essential for inspector patterns and metadata display. No blocking dependencies.

**Requirements**:
- Display key-value pairs with semantic styling
- Optional copyable text integration (phase 4.2 utility)
- Monospaced font for values (hex, timestamps, etc.)
- Keyboard shortcut hints display
- Accessibility labels for screen readers
- Multiple layout variants (horizontal, vertical)
- Unit tests
- Previews with various content types

**Note**: CopyableText integration can be deferred to Phase 4.2, implement basic version first.

---

### 4. SectionHeader Component
- **Status**: Ready to start
- **Priority**: P0 (Critical)
- **Dependencies**: DS.Typography ✅, DS.Spacing ✅
- **Estimated Effort**: S (2-4 hours)
- **File**: `Sources/FoundationUI/Components/SectionHeader.swift`

**Why now**: Simple component needed for organizing inspector views and list sections.

**Requirements**:
- Uppercase title styling (`.textCase(.uppercase)`)
- Optional divider support
- Consistent spacing via DS.Spacing tokens
- Accessibility heading level (`.accessibilityAddTraits(.isHeader)`)
- Unit tests
- Previews with and without dividers
- DocC documentation

---

## Testing Tasks (Phase 2.2)

### 5. Component Unit Tests
- **Status**: Pending (implement alongside components)
- **Priority**: P0 (Critical)
- **Estimated Effort**: M (4-6 hours total)

**Requirements**:
- Test Badge with all levels
- Test Card composition and nesting
- Test KeyValueRow layout variants
- Test SectionHeader with/without divider
- Verify 100% public API coverage
- Target: ≥85% code coverage for components

---

### 6. Component Snapshot Tests
- **Status**: Pending
- **Priority**: P0 (Critical)
- **Estimated Effort**: L (1-2 days)

**Requirements**:
- Set up SnapshotTesting framework
- Test Light/Dark mode rendering for all components
- Test Dynamic Type sizes (XS, M, XXL)
- Test platform-specific layouts
- Test locale variations (RTL support)

---

### 7. Component Previews
- **Status**: Implement alongside components
- **Priority**: P0 (Critical)
- **Estimated Effort**: S (included in component tasks)

**Requirements**:
- Create comprehensive preview catalog
- Show all component variations
- Include usage examples in DocC
- Platform-specific preview conditionals

---

### 8. Component Accessibility Tests
- **Status**: Pending
- **Priority**: P1 (Important)
- **Estimated Effort**: M (4-6 hours)

**Requirements**:
- VoiceOver navigation testing
- Contrast ratio validation (≥4.5:1)
- Keyboard navigation testing
- Focus management verification

---

### 9. Component Performance Tests
- **Status**: Pending
- **Priority**: P1 (Important)
- **Estimated Effort**: M (4-6 hours)

**Requirements**:
- Measure render time for complex hierarchies
- Test memory footprint (target: <5MB per screen)
- Verify 60 FPS on all platforms
- Profile with Instruments

---

### 10. Component Integration Tests
- **Status**: Pending
- **Priority**: P1 (Important)
- **Estimated Effort**: M (4-6 hours)

**Requirements**:
- Test component nesting scenarios
- Verify Environment value propagation
- Test state management
- Test preview compilation

---

### 11. Code Quality Verification
- **Status**: Continuous
- **Priority**: P1 (Important)
- **Estimated Effort**: S (1-2 hours)

**Requirements**:
- Run SwiftLint (target: 0 violations)
- Verify zero magic numbers
- Check documentation coverage (100%)
- Review API naming consistency

---

### 12. Demo Application
- **Status**: Pending (Phase 2.3)
- **Priority**: P0 (Critical)
- **Estimated Effort**: L (1-2 days)

**Why later**: Build after components are complete to showcase all functionality

---

## Phase 2.2 Completion Criteria

Before archiving Phase 2.2:
- ✅ All 4 components implemented (Badge, Card, KeyValueRow, SectionHeader)
- ✅ All unit tests written and passing
- ✅ All snapshot tests created
- ✅ All components have comprehensive previews
- ✅ 100% DocC coverage
- ✅ SwiftLint 0 violations
- ✅ Zero magic numbers
- ✅ Accessibility compliance verified
- ✅ All code committed to git

---

## Upcoming (Phase 2.3 & Beyond)

### Phase 2.3: Demo Application
- **Status**: Blocked until Phase 2.2 complete
- **Priority**: P0 (Critical)
- **Estimated Effort**: L (1-2 days)

**Tasks**:
- Create minimal demo app for component testing
- Implement component showcase screens
- Add interactive component inspector
- Demo app documentation

### Phase 3.1: UI Patterns (Organisms)
- **Status**: Blocked until Phase 2.2 complete
- **Priority**: P0-P1
- **Estimated Effort**: XL (3-5 days)

**Tasks**:
- Implement InspectorPattern
- Implement SidebarPattern
- Implement ToolbarPattern
- Implement BoxTreePattern

**Dependencies**: Need Badge, Card, SectionHeader, KeyValueRow components

---

## Notes

- **Focus on Phase 2.2**: Complete all 4 essential components before moving to patterns
- **TDD First**: Write tests before implementation for each component
- **Preview Everything**: Every component needs comprehensive SwiftUI previews
- **Document Continuously**: Add DocC comments as you implement
- **Zero Magic Numbers**: All values must use DS tokens
- **Accessibility First**: Build VoiceOver support from the start

---

## Recommended Implementation Order

1. **Badge** (simplest, validates component architecture)
2. **SectionHeader** (simple, needed for demo app)
3. **Card** (more complex, heavily reused)
4. **KeyValueRow** (moderate complexity, inspector essential)
5. **Component Tests** (comprehensive test coverage)
6. **Snapshot Tests** (visual regression prevention)
7. **Demo App** (integration validation)

---

**Next Action**: Use `/start` command with Badge component task to begin Phase 2.2 implementation.
