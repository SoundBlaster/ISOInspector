# I0.1 — Add FoundationUI Dependency

## 🎯 Objective

Add FoundationUI as a Swift Package dependency to ISOInspectorApp, verify successful builds with the new target, and establish the foundation for gradual UI component migration. This task enables Phase 1-6 of the FoundationUI integration strategy by ensuring the package is properly configured and accessible to all app targets.

## 🧩 Context

ISOInspectorApp currently uses hand-rolled UI components with manual styling throughout the codebase. The FoundationUI Swift Package provides a comprehensive design system with reusable components (badges, cards, patterns, etc.) that will improve consistency, maintainability, and accessibility.

**Current State:**
- ISOInspectorApp has no external UI dependencies beyond SwiftUI
- Manual styling scattered across view files
- Inconsistent spacing, colors, and component behavior
- No shared design system

**Target State:**
- FoundationUI added as Package.swift dependency
- All targets can import FoundationUI
- Package builds successfully on macOS, iOS, iPadOS
- Platform requirements updated if needed (e.g., minimum iOS version)

**Dependencies:**
- None (P0 blocker for all subsequent integration phases)

**Blocking:**
- I0.2 — Create Integration Test Suite
- I0.3 — Build Component Showcase
- I0.4 — Document Integration Patterns
- I0.5 — Update Design System Guide
- All Phase 1-6 FoundationUI integration tasks

## ✅ Success Criteria

- ✅ FoundationUI added as dependency in `Package.swift` under `ISOInspectorApp` target
- ✅ Package resolves successfully: `swift package resolve` completes without errors
- ✅ Clean build succeeds: `swift build` completes for all platforms
- ✅ Test build succeeds: `swift test` compiles without errors
- ✅ Platform requirements validated:
  - macOS 13+ (current minimum)
  - iOS/iPadOS 16+ (current minimum)
  - No conflicts with existing dependencies
- ✅ FoundationUI imports work in app targets:
  ```swift
  import FoundationUI
  // Basic import verification compiles
  ```
- ✅ CI/CD pipeline passes with new dependency
- ✅ No SwiftLint violations introduced
- ✅ Git status clean (no untracked build artifacts)

## 🔧 Implementation Notes

### Step-by-Step Plan

1. **Locate FoundationUI Package**
   - Verify FoundationUI package location in repository
   - Check if it's a sibling directory or separate repository
   - Confirm package structure and available products

2. **Update Package.swift**
   - Add FoundationUI to `dependencies` array
   - Add FoundationUI to `ISOInspectorApp` target dependencies
   - Verify no version conflicts with existing packages
   - Update platform requirements if FoundationUI requires newer OS versions

3. **Resolve Dependencies**
   - Run `swift package resolve` to fetch and validate
   - Check for any resolution errors or conflicts
   - Verify `Package.resolved` updates correctly

4. **Build Verification**
   - Run `swift build` for all platforms
   - Run `swift test` to verify test targets compile
   - Check for any deprecation warnings or build errors

5. **Import Verification**
   - Create minimal test file that imports FoundationUI
   - Verify basic component access (e.g., `DS.Badge`)
   - Ensure no namespace conflicts

6. **Documentation Updates**
   - Update `README.md` dependencies section if needed
   - Note FoundationUI integration in CHANGELOG (if applicable)
   - Update any developer onboarding docs

### Package.swift Changes

Expected diff structure:
```swift
dependencies: [
    // Existing dependencies...
    .package(path: "../FoundationUI"), // or .package(url:...) if external
],
targets: [
    .target(
        name: "ISOInspectorApp",
        dependencies: [
            // Existing dependencies...
            .product(name: "FoundationUI", package: "FoundationUI"),
        ]
    ),
]
```

### Platform Requirements Check

FoundationUI may require:
- Swift 5.9+ (verify current Swift version)
- macOS 13+ / iOS 16+ (confirm against current minimum)
- SwiftUI compatibility (should align with existing requirements)

### Potential Issues

- **Path Resolution:** If FoundationUI is in a sibling directory, use `.package(path:...)`
- **Version Conflicts:** If FoundationUI requires newer platforms, update app minimums
- **Build Cache:** May need `swift package clean` if resolution fails
- **CI Configuration:** GitHub Actions may need workspace setup for local package

### Verification Commands

```bash
# Clean state
swift package clean
rm -rf .build/

# Resolve dependencies
swift package resolve

# Build all targets
swift build

# Run tests
swift test

# Verify no lint violations
swiftlint lint --strict
```

## 🧠 Source References

- **Integration Strategy:** [`DOCS/INPROGRESS/FoundationUI_Integration_Strategy.md`](FoundationUI_Integration_Strategy.md)
- **Next Tasks:** [`DOCS/INPROGRESS/next_tasks.md`](next_tasks.md)
- **Workplan:** [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- **Main PRD:** [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- **Rules:** [`DOCS/RULES/03_Next_Task_Selection.md`](../RULES/03_Next_Task_Selection.md)

### Related Archives

- **Phase 0 Planning:** [`DOCS/INPROGRESS/FoundationUI_Integration_Planning_Complete.md`](FoundationUI_Integration_Planning_Complete.md)
- **T6.3 Completion:** [`DOCS/TASK_ARCHIVE/211_T6_3_SDK_Tolerant_Parsing_Documentation/`](../TASK_ARCHIVE/211_T6_3_SDK_Tolerant_Parsing_Documentation/)

---

**Status:** 📋 Ready for Implementation
**Priority:** P0 (Critical — Blocks all FoundationUI integration phases)
**Estimated Effort:** 0.5 days
**Assigned:** Current session (T6.3 follow-up)
