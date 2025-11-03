# Next Tasks for FoundationUI

**Updated**: 2025-11-03
**Current Status**: Accessibility context refinements merged ✅

## 🎯 Immediate Priorities (P0)

### Phase 3.2: Context unit tests (P0) → ⏳ READY TO START

**Status**: ⏳ **READY TO START**
**Priority**: P0 (Critical - Required for quality)
**Estimated Effort**: M (6-8 hours)
**Dependencies**: All Phase 3.2 Contexts ✅
**Task Document**: TBD (to be created)

**Description**: Create comprehensive unit tests for all Context layer components (SurfaceStyleKey, PlatformAdapter, ColorSchemeAdapter, PlatformExtensions).

**Requirements**:

- Unit tests for environment key propagation
- Platform detection tests (compile-time and runtime)
- Color scheme adaptation tests (light/dark mode)
- Platform extension tests (keyboard shortcuts, gestures, hover effects)
- Edge case coverage
- ≥80% test coverage minimum

**Why now**: Critical for ensuring Context layer reliability before moving to next phase. Required for production quality.

---

## ✅ Recently Completed

### Phase 3.2: Accessibility Context Overrides & Contrast Detection ✅ COMPLETE (2025-11-03)

- Introduced `AccessibilityContextOverrides` so tests and previews can opt into contrast, bold text, or dynamic type variants without mutating read-only environment values.
- Swapped the increase-contrast detection to use the system accessibility APIs (`UIAccessibility.isDarkerSystemColorsEnabled` / `NSWorkspace.accessibilityDisplayShouldIncreaseContrast`) for toolchains that do not yet expose `EnvironmentValues.accessibilityContrast`.
- Annotated export callbacks in `IntegritySummaryView` and `ParseTreeOutlineView` with `@MainActor` and wrapped selection handlers to satisfy Strict Concurrency while keeping the menu behaviour unchanged.
- Verified `AccessibilityContextTests` passes in the standalone FoundationUI package via `swift test --filter AccessibilityContextTests`.

### Phase 3.2: Platform Comparison Previews ✅ COMPLETE AND ARCHIVED (2025-10-27)

- **File**: `Sources/FoundationUI/Previews/PlatformComparisonPreviews.swift` (~1000+ lines)
- **8 comprehensive SwiftUI Previews** covering all platform scenarios
  - Platform Detection Preview
  - Spacing Adaptation Side-by-Side Preview
  - macOS Keyboard Shortcuts Preview
  - iOS Gestures Preview
  - iPadOS Pointer Interactions Preview
  - Color Scheme - Light Mode Preview
  - Color Scheme - Dark Mode Preview
  - Component Adaptation Showcase Preview
  - Cross-Platform Integration Preview
- **Platform-specific features**: macOS (⌘ shortcuts), iOS (gestures), iPadOS (hover effects)
- **Color scheme adaptation**: Light/Dark mode support via ColorSchemeAdapter
- **100% DS token usage**: Zero magic numbers (DS.Spacing, DS.Radius, DS.Typography, DS.Animation)
- **100% DocC documentation**: Comprehensive API documentation for all previews
- **Conditional compilation**: Proper platform detection (#if os(macOS), #if os(iOS))
- **Touch target guidelines**: 44pt minimum on iOS displayed
- **Runtime detection**: iPad pointer interactions with UIDevice.current.userInterfaceIdiom

---

## ✅ Recently Archived

### Phase 3.2: Platform Extensions ✅ ARCHIVED (2025-10-27)

- **Archive**: `TASK_ARCHIVE/27_Phase3.2_PlatformExtensions/`
- **Files**:
  - `Sources/FoundationUI/Contexts/PlatformExtensions.swift` (551 lines)
  - `Tests/FoundationUITests/ContextsTests/PlatformExtensionsTests.swift` (24 tests)
- **macOS keyboard shortcuts**: Copy (⌘C), Paste (⌘V), Cut (⌘X), Select All (⌘A)
- **iOS gestures**: Tap, double tap, long press, swipe (all directions)
- **iPadOS pointer interactions**: Hover effects (lift, highlight, automatic) with runtime iPad detection
- **3 enums**: PlatformKeyboardShortcutType, PlatformSwipeDirection, PlatformHoverEffectStyle
- **9 platform-specific view extensions** with conditional compilation
- **4 SwiftUI Previews**: macOS shortcuts, iOS gestures, iPadOS hover, cross-platform
- **100% DocC documentation** (comprehensive API coverage)
- **Zero magic numbers** (uses DS.Spacing, DS.Animation tokens exclusively)
- **24 comprehensive tests** covering all platforms and edge cases

### Phase 3.2: Platform Adaptation Integration Tests ✅ ARCHIVED (2025-10-26)

- **Archive**: `TASK_ARCHIVE/26_Phase3.2_PlatformAdaptationIntegrationTests/`
- **File**: `Tests/FoundationUITests/ContextsTests/PlatformAdaptationIntegrationTests.swift`
- **28 comprehensive integration tests** (1068 lines)
- **macOS-specific tests** (6): spacing, keyboard shortcuts, clipboard, hover effects, sidebar
- **iOS-specific tests** (6): touch targets (44pt), gestures, clipboard, inspector
- **iPad adaptive tests** (6): size classes, split view, pointer interaction, sidebar adaptation
- **Cross-platform consistency tests** (6): DS tokens, dark mode, accessibility, environment
- **Edge case tests** (4): nil size class, unknown variants, complex hierarchies
- **274 DocC comment lines** (100% coverage)
- **Zero magic numbers** (100% DS token usage, only documented constant: 44pt iOS touch target)

### Phase 3.2: ColorSchemeAdapter ✅ ARCHIVED (2025-10-26)

- **Archive**: `TASK_ARCHIVE/24_Phase3.2_ColorSchemeAdapter/`
- ColorSchemeAdapter struct with automatic Dark Mode adaptation
- 7 adaptive color properties for backgrounds, text, borders, dividers
- View modifier `.adaptiveColorScheme()` for convenient usage
- Platform-specific color handling (iOS UIColor / macOS NSColor)
- 29 comprehensive tests (24 unit + 5 integration)
- 6 SwiftUI Previews covering all use cases
- 100% DocC documentation (779 lines)
- Zero magic numbers (uses system colors and DS tokens)

### Phase 3.2: PlatformAdaptation Modifiers ✅ ARCHIVED (2025-10-26)

- **Archive**: `TASK_ARCHIVE/23_Phase3.2_PlatformAdaptation/`
- PlatformAdapter enum with platform detection (`isMacOS`, `isIOS`)
- PlatformAdaptiveModifier for spacing adaptation
- Conditional compilation for macOS (12pt) vs iOS (16pt)
- Size class adaptation for iPad (compact: 12pt, regular: 16pt)
- View extensions: `.platformAdaptive()`, `.platformSpacing()`, `.platformPadding()`
- iOS minimum touch target constant (44pt per Apple HIG)
- 28 comprehensive unit tests
- 6 SwiftUI Previews
- 100% DocC documentation (572 lines)

### Phase 3.2: SurfaceStyleKey Environment Key ✅ ARCHIVED (2025-10-26)

- **Archive**: `TASK_ARCHIVE/22_Phase3.2_SurfaceStyleKey/`
- SwiftUI EnvironmentKey for surface material propagation
- Default value `.regular` for balanced translucency
- EnvironmentValues extension with `surfaceStyle` property
- 12 comprehensive unit tests
- 6 SwiftUI Previews
- 100% DocC documentation (237 lines)

---

## 📊 Current Phase Status

| Phase | Progress | Status |
|-------|----------|--------|
| Phase 1.1: Infrastructure | 2/8 (25%) | In progress |
| Phase 1.2: Design Tokens | 7/7 (100%) | ✅ Complete |
| Phase 2: Core Components | 22/22 (100%) | ✅ Complete |
| Phase 3.1: Patterns | 7/8 (88%) | In progress |
| Phase 3.2: Contexts | 7/8 (87.5%) | 🚧 **IN PROGRESS** |

**Overall Progress**: 49/116 tasks (42.2%)

---

## 🔜 Next Task (Immediate Priority)

### Phase 3.2: Context unit tests (P0) → ⏳ READY TO START

**Status**: ⏳ **READY TO START**
**Priority**: P0 (Critical - Required for quality)
**Estimated Effort**: M (6-8 hours)
**Dependencies**: All Phase 3.2 Contexts ✅
**Task Document**: TBD (to be created)

**Description**: Create comprehensive unit tests for all Context layer components (SurfaceStyleKey, PlatformAdapter, ColorSchemeAdapter, PlatformExtensions).

**Requirements**:

- Unit tests for environment key propagation
- Platform detection tests (compile-time and runtime)
- Color scheme adaptation tests (light/dark mode)
- Platform extension tests (keyboard shortcuts, gestures, hover effects)
- Edge case coverage
- ≥80% test coverage minimum

**Why now**: Critical for ensuring Context layer reliability before moving to next phase. Required for production quality.

---

## 🔭 Upcoming Tasks (Phase 3.2)

### Remaining Phase 3.2 Tasks

Phase 3.2 currently has 7/8 tasks complete (87.5%).

**Pending**:

- [ ] Context unit tests (P0) - Test environment key propagation, platform detection, color scheme adaptation (NEXT TASK)

---

## 🔮 Future Phases

### Phase 3.1: Remaining Tasks

- Complete any remaining pattern tasks (1/8 remaining)

### Phase 4: Agent Support & Polish (0/18 tasks)

- Deferred until foundational work complete

### Phase 4.3: Copyable Architecture Refactoring (P2)

**Goal**: Refactor CopyableText into composable, modifier-based architecture
**Status**: Not Started (0/5 tasks)
**Priority**: P2 (Future Enhancement)
**Estimated Effort**: 16-22 hours
**PRD**: `FoundationUI/DOCS/PRD_CopyableArchitecture.md`

**When to Implement**: After Phase 3 completion, before Phase 5 (Documentation)

---

**Latest Update**: Platform Comparison Previews completed (2025-10-27)
**Next Action**: Create Context unit tests (P0 - Critical priority)
