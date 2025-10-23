# UI Testing Guide for ComponentTestApp

**Status:** Future Enhancement
**Created:** 2025-10-23
**Priority:** P2 (Nice to have)

---

## Overview

This guide provides instructions for adding UI tests to ComponentTestApp when ready for implementation. UI tests will validate the visual and interactive behavior of FoundationUI components.

---

## When to Add UI Tests

UI tests should be added when:
- ComponentTestApp is stable and feature-complete
- All components have comprehensive unit and snapshot tests
- Development focus shifts to end-to-end validation
- Visual regression testing is required for CI

**Current Status:** Phase 2.3 complete, UI tests deferred to Phase 5-6

---

## Implementation Steps

### 1. Create UI Test Target in Tuist

Update `Examples/ComponentTestApp/Project.swift`:

```swift
func componentTestAppUITestsIOS() -> Target {
    Target.target(
        name: "ComponentTestApp-iOS-UITests",
        destinations: [.iPhone, .iPad],
        product: .uiTests,
        bundleId: "ru.egormerkushev.componenttestapp.ios.uitests",
        deploymentTargets: .iOS("17.0"),
        infoPlist: .default,
        sources: ["UITests/**"],
        dependencies: [
            .target(name: "ComponentTestApp-iOS")
        ],
        settings: .settings(base: baseSettings)
    )
}

func componentTestAppUITestsMacOS() -> Target {
    Target.target(
        name: "ComponentTestApp-macOS-UITests",
        destinations: [.mac],
        product: .uiTests,
        bundleId: "ru.egormerkushev.componenttestapp.macos.uitests",
        deploymentTargets: .macOS("14.0"),
        infoPlist: .default,
        sources: ["UITests/**"],
        dependencies: [
            .target(name: "ComponentTestApp-macOS")
        ],
        settings: .settings(base: baseSettings)
    )
}

// Add to targets array:
targets: [
    componentTestAppIOS(),
    componentTestAppMacOS(),
    componentTestAppUITestsIOS(),    // NEW
    componentTestAppUITestsMacOS()   // NEW
]
```

### 2. Create UI Test Directory Structure

```bash
mkdir -p Examples/ComponentTestApp/UITests
cd Examples/ComponentTestApp/UITests
```

Create test files:
```
UITests/
├── ComponentTestAppUITests.swift       # Base test class
├── DesignTokensScreenTests.swift      # Design tokens UI tests
├── ModifiersScreenTests.swift         # View modifiers UI tests
├── BadgeScreenTests.swift             # Badge component UI tests
├── CardScreenTests.swift              # Card component UI tests
├── KeyValueRowScreenTests.swift       # KeyValueRow UI tests
└── SectionHeaderScreenTests.swift     # SectionHeader UI tests
```

### 3. Example UI Test Structure

**ComponentTestAppUITests.swift:**
```swift
import XCTest

class ComponentTestAppUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
}
```

**BadgeScreenTests.swift:**
```swift
import XCTest

final class BadgeScreenTests: ComponentTestAppUITests {
    func testBadgeScreenNavigation() throws {
        // Navigate to Badge screen
        let badgeLink = app.buttons["Badge"]
        XCTAssertTrue(badgeLink.waitForExistence(timeout: 5))
        badgeLink.tap()

        // Verify screen title
        let title = app.navigationBars["Badge Component"]
        XCTAssertTrue(title.exists)
    }

    func testBadgeLevelPicker() throws {
        // Navigate to Badge screen
        app.buttons["Badge"].tap()

        // Find badge level picker
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.exists)

        // Test switching levels
        picker.buttons["Warning"].tap()
        XCTAssertTrue(app.staticTexts["Warning"].exists)

        picker.buttons["Error"].tap()
        XCTAssertTrue(app.staticTexts["Error"].exists)
    }

    func testShowIconToggle() throws {
        // Navigate to Badge screen
        app.buttons["Badge"].tap()

        // Find and toggle "Show Icons" switch
        let iconToggle = app.switches["Show Icons"]
        XCTAssertTrue(iconToggle.exists)

        // Test toggle behavior
        iconToggle.tap()
        // Verify icons are hidden/shown
    }

    func testAllBadgeLevelsDisplay() throws {
        app.buttons["Badge"].tap()

        // Verify all badge levels are visible
        XCTAssertTrue(app.staticTexts["Info"].exists)
        XCTAssertTrue(app.staticTexts["Warning"].exists)
        XCTAssertTrue(app.staticTexts["Error"].exists)
        XCTAssertTrue(app.staticTexts["Success"].exists)
    }
}
```

**CardScreenTests.swift:**
```swift
import XCTest

final class CardScreenTests: ComponentTestAppUITests {
    func testCardElevationPicker() throws {
        app.buttons["Card"].tap()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.exists)

        // Test elevation switching
        picker.buttons["Low"].tap()
        picker.buttons["Medium"].tap()
        picker.buttons["High"].tap()
    }

    func testCardMaterialPicker() throws {
        app.buttons["Card"].tap()

        // Find material picker (second segmented control)
        let materialPicker = app.segmentedControls.element(boundBy: 1)
        XCTAssertTrue(materialPicker.exists)

        materialPicker.buttons["Thin"].tap()
        materialPicker.buttons["Regular"].tap()
        materialPicker.buttons["Thick"].tap()
    }

    func testComplexCardComposition() throws {
        app.buttons["Card"].tap()

        // Scroll to complex nested content section
        app.swipeUp()

        // Verify nested components exist
        XCTAssertTrue(app.staticTexts["ISO Box Details"].exists)
        XCTAssertTrue(app.staticTexts["Type"].exists)
        XCTAssertTrue(app.staticTexts["ftyp"].exists)
    }
}
```

### 4. Accessibility-Focused UI Tests

**AccessibilityUITests.swift:**
```swift
import XCTest

final class AccessibilityUITests: ComponentTestAppUITests {
    func testVoiceOverLabels() throws {
        // Verify all interactive elements have accessibility labels
        app.buttons["Badge"].tap()

        let badgeLevelPicker = app.segmentedControls.firstMatch
        XCTAssertNotNil(badgeLevelPicker.label)

        let iconToggle = app.switches["Show Icons"]
        XCTAssertNotNil(iconToggle.label)
    }

    func testKeyboardNavigation() throws {
        // Test keyboard navigation (macOS)
        #if os(macOS)
        // Tab through interactive elements
        // Verify focus order is logical
        #endif
    }

    func testDynamicType() throws {
        // Test with different Dynamic Type sizes
        // This requires setting accessibility settings before launch
    }
}
```

### 5. Visual Snapshot Tests

**SnapshotUITests.swift:**
```swift
import XCTest

final class SnapshotUITests: ComponentTestAppUITests {
    func testBadgeScreenSnapshot() throws {
        app.buttons["Badge"].tap()

        // Take screenshot
        let screenshot = app.screenshot()

        // Attach to test results
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLightDarkModeComparison() throws {
        // Test Light mode
        app.buttons["Badge"].tap()
        let lightScreenshot = app.screenshot()
        let lightAttachment = XCTAttachment(screenshot: lightScreenshot)
        lightAttachment.name = "Badge-Light"
        add(lightAttachment)

        // Toggle Dark mode
        // (requires adding Dark mode toggle to main navigation)
        // Take Dark mode screenshot
    }
}
```

### 6. Update CI Workflow

Uncomment the UI tests section in `.github/workflows/foundationui.yml`:

```yaml
- name: Run ComponentTestApp UI tests (iOS)
  run: |
    set -eo pipefail
    echo "Running ComponentTestApp UI tests on iOS..."
    xcodebuild test \
      -workspace ISOInspector.xcworkspace \
      -scheme ComponentTestApp-iOS \
      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
      -configuration Debug \
      -only-testing:ComponentTestApp-iOS-UITests \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_ALLOWED=NO \
      CODE_SIGNING_REQUIRED=NO

- name: Run ComponentTestApp UI tests (macOS)
  run: |
    set -eo pipefail
    echo "Running ComponentTestApp UI tests on macOS..."
    xcodebuild test \
      -workspace ISOInspector.xcworkspace \
      -scheme ComponentTestApp-macOS \
      -destination 'platform=macOS' \
      -configuration Debug \
      -only-testing:ComponentTestApp-macOS-UITests \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_ALLOWED=NO \
      CODE_SIGNING_REQUIRED=NO

- name: Upload UI test screenshots
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: ui-test-screenshots
    path: |
      ~/Library/Developer/Xcode/DerivedData/*/Logs/Test/Attachments/*.png
      ~/Library/Developer/Xcode/DerivedData/*/Logs/Test/Attachments/*.jpeg
    if-no-files-found: ignore
```

---

## Testing Strategy

### Unit Tests (Current - Phase 2)
✅ **Purpose:** Test component logic, state, API contracts
✅ **Coverage:** 80%+ across all layers
✅ **Speed:** Fast (<1s per test)
✅ **CI:** Runs on every PR

### Snapshot Tests (Current - Phase 2)
✅ **Purpose:** Visual regression testing
✅ **Coverage:** Light/Dark mode, Dynamic Type, platform variations
✅ **Speed:** Medium (2-5s per test)
✅ **CI:** Runs on every PR

### UI Tests (Future - Phase 5-6)
⚠️ **Purpose:** End-to-end user flows, accessibility validation
⚠️ **Coverage:** Critical user paths, interactive behavior
⚠️ **Speed:** Slow (10-30s per test)
⚠️ **CI:** Optional on PR, required before release

---

## Best Practices

### DO:
✅ Test critical user flows (navigation, interaction)
✅ Verify accessibility labels and traits
✅ Test on both iOS and macOS
✅ Keep tests independent and idempotent
✅ Use meaningful test names
✅ Add screenshots to test results

### DON'T:
❌ Test implementation details
❌ Rely on exact pixel positions
❌ Create flaky tests with timing issues
❌ Test every minor UI variation (use snapshot tests)
❌ Duplicate unit test coverage

---

## Recommended Timeline

| Phase | Task | Priority |
|-------|------|----------|
| Phase 2.3 | ✅ Demo app created | P0 (Complete) |
| Phase 3-4 | Focus on Patterns & Agent Support | P0-P1 |
| Phase 5 | Add basic UI test infrastructure | P1 |
| Phase 5 | Create critical path UI tests | P1 |
| Phase 6 | Full UI test coverage | P2 |
| Phase 6 | Visual regression in CI | P2 |

---

## Resources

- [Apple XCUITest Documentation](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [SwiftUI Testing Best Practices](https://developer.apple.com/wwdc21/10192)
- [Accessibility Testing Guide](https://developer.apple.com/documentation/accessibility/testing-your-app-for-accessibility)

---

**Next Steps:**
1. Complete Phase 3-4 (Patterns & Agent Support)
2. Revisit UI testing in Phase 5
3. Create UI test targets when ready
4. Implement critical path tests first

---

**Last Updated:** 2025-10-23
