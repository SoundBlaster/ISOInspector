# SYSTEM PROMPT: Fix FoundationUI Bug Implementation

## 🧩 PURPOSE

Implement fixes for documented bugs in FoundationUI components, modifiers, or design tokens, following TDD workflow and ensuring comprehensive regression prevention.

---

## 🎯 GOAL

Execute bug fixes based on specifications created by the BUG command, fully adhering to:

- **TDD (Test-Driven Development)** - Write failing test that reproduces bug first
- **XP (Extreme Programming)** - Minimal fix, continuous refactoring
- **Zero Magic Numbers** - All values must use DS (Design System) tokens
- **Regression Prevention** - Comprehensive tests to prevent bug recurrence
- **Platform Coverage** - Fix and test on all affected platforms (iOS/iPadOS/macOS)
- **Accessibility** - Ensure fix maintains or improves accessibility compliance

---

## 📚 REFERENCE MATERIALS

### Primary Documents

- [Bug Specifications](../SPECS/) — Detailed bug analysis and fix proposals
- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Task tracking
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy

### Development Rules (from main ISOInspector)

- [DOCS/RULES/](../../../DOCS/RULES/) — **Complete rules directory** (TDD, PDD, SwiftUI Testing, etc.)
- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — Outside-in TDD flow
- [04_PDD.md](../../../DOCS/RULES/04_PDD.md) — Puzzle-driven development workflow
- [07_AI_Code_Structure_Principles.md](../../../DOCS/RULES/07_AI_Code_Structure_Principles.md) — One entity per file
- [11_SwiftUI_Testing.md](../../../DOCS/RULES/11_SwiftUI_Testing.md) — **SwiftUI testing guidelines & @MainActor requirements**

### FoundationUI-Specific Rules

- **Design System First**: All spacing, colors, typography, radius, animation must come from `DS` namespace
- **SwiftUI Best Practices**: Use `@ViewBuilder`, environment values, and platform conditionals
- **Accessibility**: VoiceOver labels, contrast ratios ≥4.5:1, keyboard navigation
- **Platform Adaptation**: Conditional compilation for iOS/iPadOS/macOS differences
- **Preview Coverage**: 100% SwiftUI preview coverage for all public components

---

## ⚙️ EXECUTION STEPS

### Step 0. Install and Verify Swift Toolchain

**IMPORTANT**: Swift must be installed and available before writing or running tests.

#### Check if Swift is Installed

```bash
swift --version
```

If Swift is installed, you should see output like:

```bash
Swift version 6.0.x (swift-6.0-RELEASE)
Target: x86_64-unknown-linux-gnu
```

#### Install Swift (Ubuntu/Debian Linux)

If Swift is not installed, follow these steps:

1. **Install Swift dependencies**:

   ```bash
   apt-get update
   apt-get install -y \
     wget binutils git gnupg2 libc6-dev libcurl4-openssl-dev \
     libedit2 libgcc-11-dev libpython3-dev libsqlite3-0 \
     libstdc++-11-dev libxml2-dev libz3-dev pkg-config \
     tzdata unzip zlib1g-dev
   ```

2. **Download Swift 6.0 (or latest stable) for Ubuntu**:

   ```bash
   # For Ubuntu 22.04 / 24.04 x86_64
   cd /tmp
   wget https://download.swift.org/swift-6.0.3-release/ubuntu2204/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu22.04.tar.gz
   ```

   Alternative: Check [swift.org/download](https://swift.org/download/) for the latest release.

3. **Extract and install Swift**:

   ```bash
   tar xzf swift-6.0.3-RELEASE-ubuntu22.04.tar.gz
   mv swift-6.0.3-RELEASE-ubuntu22.04 /usr/share/swift
   ```

4. **Add Swift to PATH**:

   ```bash
   export PATH=/usr/share/swift/usr/bin:$PATH
   echo 'export PATH=/usr/share/swift/usr/bin:$PATH' >> ~/.bashrc
   ```

5. **Verify installation**:

   ```bash
   swift --version
   swift test --help
   ```

#### Platform-Specific Notes

- **Linux**: Swift on Linux does **not** include SwiftUI frameworks (UIKit/AppKit)
  - Tests will compile but SwiftUI views cannot be instantiated
  - Use `#if canImport(SwiftUI)` guards in tests
  - Run full UI tests on macOS/Xcode when possible

- **macOS**: Swift comes bundled with Xcode
  - Install Xcode 15.0+ from Mac App Store
  - Verify: `xcode-select --install`

- **CI/CD**: Use official Swift Docker images
  - `docker pull swift:6.0`
  - GitHub Actions: `swiftlang/swift-action@v1`

#### Troubleshooting

If `swift test` fails with import errors:

1. Verify Package.swift platforms match your Swift version
2. Check that all dependencies are resolved: `swift package resolve`
3. Clean build artifacts: `swift package clean`
4. Rebuild: `swift build`

---

### Step 1. Select Bug Specification

1. List all documented bugs in `FoundationUI/DOCS/SPECS/`:

   ```bash
   ls -la FoundationUI/DOCS/SPECS/BUG_*.md
   ```

2. Select a bug specification to fix (typically P0 or P1 priority)
3. Read the full specification to understand:
   - **Root cause**: Why the bug occurs
   - **Affected files**: What needs to be changed
   - **Proposed fix**: Recommended approach
   - **Testing requirements**: What tests to add
   - **Success criteria**: Definition of done

4. Check Task Plan to ensure bug fix task exists and is not blocked by prerequisites

### Step 2. Review Bug Analysis

Before starting implementation, thoroughly review the bug specification:

- **Understand the symptom**: What users observe
- **Understand the root cause**: Why it happens (code location, logic error, wrong token)
- **Identify affected platforms**: iOS, iPadOS, macOS, or all
- **Check design system violations**: Are magic numbers involved? Wrong tokens?
- **Review accessibility impact**: Does this affect VoiceOver, contrast, keyboard nav?
- **Understand user impact**: How severe is this bug?

**Ask questions if anything is unclear before proceeding.**

### Step 3. Apply TDD Cycle for Bug Fixing

Bug fixing follows a modified TDD workflow:

#### 3.1. Write a Failing Test (Reproduce the Bug)

Before fixing, prove the bug exists with a failing test.

1. **Create or update test file**: `Tests/FoundationUITests/{Layer}Tests/{ComponentName}Tests.swift`

2. **Write test that reproduces the bug**:

   ```swift
   func testBugReproduction_{BugName}() {
       // Arrange: Set up the buggy scenario
       // Act: Execute the code that triggers the bug
       // Assert: Verify the bug exists (test should FAIL before fix)
   }
   ```

   **Example** (from Badge warning color bug):

   ```swift
   func testWarningBadgeUsesCorrectBackgroundColor() {
       // This test will FAIL because .warning returns wrong color
       let backgroundColor = BadgeLevel.warning.backgroundColor
       XCTAssertEqual(backgroundColor, DS.Colors.warnBG)  // FAILS: returns infoBG
   }
   ```

3. **Run tests to confirm failure**:

   ```bash
   cd FoundationUI
   swift test --filter {TestName}
   ```

   **Expected**: Test should fail, proving bug exists.

4. **Document reproduction in bug spec** if not already documented:
   - Add test code to "Reproduction Steps" section
   - Note exact failure message

#### 3.2. Implement Minimal Fix

Now implement the smallest change that fixes the bug.

1. **Locate the buggy code** (identified in bug specification)

2. **Apply the minimal fix**:
   - Use DS tokens exclusively (never hardcode values)
   - Follow platform-specific conventions
   - Respect Composable Clarity layer boundaries
   - Keep changes focused (don't refactor unrelated code yet)

   **Example** (from Badge warning color bug):

   ```swift
   // Before (buggy code)
   case .warning: return DS.Colors.infoBG

   // After (minimal fix)
   case .warning: return DS.Colors.warnBG
   ```

3. **Run tests to confirm fix**:

   ```bash
   swift test --filter {TestName}
   ```

   **Expected**: Previously failing test now passes.

4. **Run full test suite** to check for regressions:

   ```bash
   swift test
   ```

   **Expected**: All tests pass.

#### 3.3. Add Regression Prevention Tests

Add comprehensive tests to prevent bug recurrence.

1. **Unit tests**: Cover all edge cases and variants
   - Test correct behavior for all inputs
   - Test boundary conditions
   - Test platform-specific behavior

2. **Snapshot tests** (for visual bugs):
   - Capture before/after snapshots
   - Test Light/Dark mode
   - Test Dynamic Type sizes (XS, M, XXL)
   - Test all component variants

3. **Accessibility tests** (if applicable):
   - VoiceOver label correctness
   - Contrast ratio validation (≥4.5:1)
   - Keyboard navigation support

**Example** (regression tests for color bug):

```swift
// Unit tests
func testAllBadgeLevelsUseCorrectColors() {
    XCTAssertEqual(BadgeLevel.info.backgroundColor, DS.Colors.infoBG)
    XCTAssertEqual(BadgeLevel.warning.backgroundColor, DS.Colors.warnBG)
    XCTAssertEqual(BadgeLevel.error.backgroundColor, DS.Colors.errorBG)
    XCTAssertEqual(BadgeLevel.success.backgroundColor, DS.Colors.successBG)
}

// Snapshot tests
func testBadgeSnapshotAllLevels() {
    assertSnapshot(matching: Badge(text: "Info", level: .info), as: .image)
    assertSnapshot(matching: Badge(text: "Warning", level: .warning), as: .image)
    assertSnapshot(matching: Badge(text: "Error", level: .error), as: .image)
    assertSnapshot(matching: Badge(text: "Success", level: .success), as: .image)
}
```

#### 3.4. Refactor While Keeping Tests Green

Now that the bug is fixed and tests pass, refactor if needed:

- Improve code clarity
- Remove duplication
- Extract reusable logic
- Update documentation comments

**Important**: Run tests after each refactoring step to ensure no regressions.

#### 3.5. Update SwiftUI Previews

Update or create SwiftUI Preview to demonstrate the fix:

```swift
#Preview("Badge Fix - All Levels") {
    VStack(spacing: DS.Spacing.m) {
        Badge(text: "Info", level: .info)
        Badge(text: "Warning", level: .warning)  // Shows correct yellow now
        Badge(text: "Error", level: .error)
        Badge(text: "Success", level: .success)
    }
    .padding()
}
```

### Step 4. Test on All Affected Platforms

If the bug is platform-specific, test the fix on all affected platforms:

#### iOS Testing

```bash
# Build for iOS
swift build -c release --arch arm64-apple-ios

# Run iOS simulator tests (requires macOS)
xcodebuild test -scheme FoundationUI -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### macOS Testing

```bash
# Build for macOS
swift build -c release --arch arm64-apple-macosx

# Run macOS tests
swift test
```

#### Platform-Specific Verification

For platform-specific bugs (e.g., macOS-only), verify:

1. **Conditional compilation works correctly**:

   ```swift
   #if canImport(UIKit)
   // iOS/iPadOS code
   #elseif canImport(AppKit)
   // macOS code
   #else
   // Fallback
   #endif
   ```

2. **Platform-specific behavior is correct**:
   - Colors match platform conventions
   - Spacing follows platform guidelines
   - Interactions work as expected

3. **Accessibility works on all platforms**:
   - Test with VoiceOver (iOS) or VoiceOver (macOS)
   - Test with Accessibility Inspector
   - Test with Increase Contrast enabled

### Step 5. Quality Assurance Checklist

Before marking the bug fix complete, verify:

- ✅ **Bug is not reproducible**: Original reproduction steps no longer trigger the bug
- ✅ **Tests pass**: `swift test` shows 100% pass rate
- ✅ **Regression tests added**: Bug cannot recur without test failure
- ✅ **Zero magic numbers**: All values use DS tokens
- ✅ **SwiftLint clean**: `swiftlint` reports 0 violations
- ✅ **Preview works**: SwiftUI preview demonstrates the fix
- ✅ **Accessibility maintained**: VoiceOver labels, contrast ratios validated
- ✅ **Documentation updated**: DocC comments reflect changes if needed
- ✅ **Platform support verified**: Tested on all affected platforms (iOS/iPadOS/macOS)
- ✅ **Design system integrity**: Fix respects Composable Clarity layers

### Step 6. Update Documentation

After successful fix, update all planning documents:

#### 6.1. Update Task Plan

1. Open [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
2. Mark bug fix task as complete: `[ ]` → `[x]`
3. Update phase progress percentages
4. Add any new tasks discovered during fix (if needed)

**Example**:

```markdown
### Phase 1.X Bug Fixes

- [x] **P0** Fix DS.Colors.tertiary macOS contrast bug
  - Files: `Colors.swift`, `ColorsTests.swift`
  - Root cause: Used label color instead of background color
  - Impact: High — restored macOS accessibility compliance
  - Fixed: 2025-11-07
```

#### 6.2. Update PRD

1. Open [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
2. Update bug fix section with completion status:

```markdown
#### Bug Fix: {BugTitle} ✅ FIXED

**Layer**: {Layer number and name}
**Severity**: {Critical/High/Medium/Low}
**Affected Component**: {ComponentName}
**Fixed**: {Date}

{Description of the bug and how it was resolved}

**Fix Implemented**:
- {Change 1}
- {Change 2}

**Regression Prevention**:
- {Test 1}
- {Test 2}
```

#### 6.3. Update Test Plan

1. Open [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
2. Document regression tests added:

```markdown
### Bug Fix Regression Tests: {BugTitle}

**Status**: ✅ Implemented
**Date**: {Date}

#### Regression Prevention Tests Added
- `test{FeatureName}()` — Verifies correct behavior
- `test{FeatureName}_EdgeCases()` — Covers boundary conditions
- `test{FeatureName}_AllPlatforms()` — Platform-specific validation

**Coverage**: 100% of bug fix code paths
```

### Step 7. Archive Bug Specification

Move the bug specification to archive after successful fix:

1. **Add "FIXED" status to specification**:

   Update the bug spec header:

   ```markdown
   **Date**: 2025-11-07
   **Status**: ✅ FIXED — 2025-11-07
   **Severity**: High
   ```

   Add "Fix Implementation" section at the end:

   ```markdown
   ---

   ## Fix Implementation (2025-11-07)

   ### Changes Made
   - File: `{File}.swift` (line {X})
   - Change: {Description}

   ### Tests Added
   - `{TestName}()` — {Purpose}

   ### Verification
   - ✅ Bug no longer reproducible
   - ✅ All tests pass
   - ✅ Platform verification complete (iOS/macOS)
   - ✅ Accessibility compliance restored

   ### Commit
   - Commit: `{commit hash}`
   - Branch: `{branch name}`
   ```

2. **Move to archive** (optional, or keep in DOCS/SPECS for reference):

   ```bash
   mkdir -p FoundationUI/DOCS/SPECS/FIXED
   mv FoundationUI/DOCS/SPECS/BUG_{Name}.md FoundationUI/DOCS/SPECS/FIXED/
   ```

3. **Create work summary** in `DOCS/INPROGRESS/`:

   ```markdown
   # Bug Fix Summary: {BugTitle}

   **Date**: {Date}
   **Bug Spec**: [BUG_{Name}.md](../SPECS/BUG_{Name}.md)

   ## Bug Description
   {Brief description}

   ## Fix Implemented
   {What was changed}

   ## Tests Added
   - {Test 1}
   - {Test 2}

   ## Impact
   {User-facing improvements}

   ## Lessons Learned
   {Any insights for preventing similar bugs}
   ```

### Step 8. Commit and Document

Follow git best practices:

- **Atomic commits**: One bug fix = one commit (unless fix requires multiple logical steps)
- **Descriptive messages**: Reference bug spec and what was fixed

  ```plaintext
  Fix DS.Colors.tertiary low contrast on macOS (#BUG_Colors_Tertiary)

  - Changed macOS implementation from .tertiaryLabelColor to .controlBackgroundColor
  - Restores proper contrast for all components using tertiary color
  - Adds regression tests for color token platform parity
  - Verified on macOS Light/Dark mode with Accessibility Inspector
  - Fixes WCAG AA contrast compliance issue

  Severity: High (P0)
  Layer: 0 (Design Tokens)
  Affected platforms: macOS only
  ```

- **Run tests before committing**:

  ```bash
  swift test
  swiftlint
  ```

- **Commit the fix**:

  ```bash
  git add .
  git commit -m "Fix {bug title} (#{bug spec name})"
  ```

---

## 🎨 BUG-FIXING-SPECIFIC CONVENTIONS

### Root Cause Analysis

Before implementing fix, always:

1. **Verify the root cause** described in bug spec is correct
2. **Check for related bugs** that might share the same root cause
3. **Consider cascade effects** — will this fix break anything else?
4. **Review design system impact** — does this expose token gaps?

### Minimal Change Principle

Bug fixes should be **minimal and focused**:

- ✅ Fix only the bug at hand
- ✅ Use existing design tokens when possible
- ❌ Don't refactor unrelated code
- ❌ Don't add new features
- ❌ Don't change unrelated behavior

**Exception**: If the bug reveals a larger design system issue, document it as a new task rather than expanding the fix scope.

### Regression Prevention First

Every bug fix **must** include regression tests:

- Unit tests that would fail if bug returns
- Snapshot tests for visual regressions
- Platform-specific tests if bug was platform-specific
- Accessibility tests if bug affected a11y

**Goal**: Make it **impossible** for the bug to recur without test failure.

### Platform Parity

For platform-specific bugs:

1. **Understand platform conventions**:
   - iOS: Uses `UIColor.systemBackground`, `.secondarySystemBackground`, etc.
   - macOS: Uses `NSColor.windowBackgroundColor`, `.controlBackgroundColor`, etc.

2. **Maintain semantic equivalence**:
   - Ensure macOS implementation matches iOS intent
   - Don't just copy values — match the semantic purpose

3. **Test on actual platforms**:
   - Don't assume simulator == device
   - Test Light and Dark mode separately
   - Test with accessibility settings enabled

### Documentation Debt

If a bug reveals documentation gaps:

1. **Update DocC comments** to clarify correct usage
2. **Add code examples** showing correct patterns
3. **Document platform differences** explicitly
4. **Update README** if bug affects public API

---

## ✅ EXPECTED OUTPUT

At the end of a bug-fixing session:

- Bug is fixed with minimal, focused change
- Failing test was written first (reproduced bug)
- All tests pass with ≥80% coverage
- Regression tests prevent bug recurrence
- SwiftLint reports 0 violations
- SwiftUI Preview demonstrates the fix
- Bug specification is updated with "FIXED" status
- Task Plan, PRD, and Test Plan are updated
- Code is committed to the designated branch
- Work summary is created in `DOCS/INPROGRESS/`

---

## 🧠 EXAMPLE WORKFLOW

### Fixing Bug: Badge Warning Color

#### Bug Spec

File: `FoundationUI/DOCS/SPECS/BUG_Badge_Warning_Color.md`

```markdown
## Root Cause
Copy-paste error in `BadgeChipStyle.swift` line 15:
case .warning: return DS.Colors.infoBG  // Should be warnBG
```

#### Step 1: Select Bug

```bash
ls -la FoundationUI/DOCS/SPECS/BUG_*.md
# Select BUG_Badge_Warning_Color.md
```

#### Step 2: Review Analysis

- **Layer**: 1 (Modifier) affecting Layer 2 (Component)
- **Severity**: Medium
- **Root cause**: Copy-paste error
- **Affected files**: `BadgeChipStyle.swift`, `BadgeTests.swift`
- **Platforms**: All (iOS, iPadOS, macOS)

#### Step 3: Apply TDD

**3.1. Write Failing Test**:

```swift
// Tests/FoundationUITests/ModifiersTests/BadgeChipStyleTests.swift

func testWarningBadgeUsesCorrectBackgroundColor() {
    // This test will FAIL before fix
    let backgroundColor = BadgeLevel.warning.backgroundColor
    XCTAssertEqual(backgroundColor, DS.Colors.warnBG)
}
```

Run test:

```bash
swift test --filter testWarningBadgeUsesCorrectBackgroundColor
# ❌ Test fails: expected warnBG, got infoBG
```

**3.2. Implement Minimal Fix**:

```swift
// Sources/FoundationUI/Modifiers/BadgeChipStyle.swift:15

// Before
case .warning: return DS.Colors.infoBG

// After
case .warning: return DS.Colors.warnBG
```

Run test:

```bash
swift test --filter testWarningBadgeUsesCorrectBackgroundColor
# ✅ Test passes
```

**3.3. Add Regression Tests**:

```swift
func testAllBadgeLevelsUseCorrectColors() {
    XCTAssertEqual(BadgeLevel.info.backgroundColor, DS.Colors.infoBG)
    XCTAssertEqual(BadgeLevel.warning.backgroundColor, DS.Colors.warnBG)
    XCTAssertEqual(BadgeLevel.error.backgroundColor, DS.Colors.errorBG)
    XCTAssertEqual(BadgeLevel.success.backgroundColor, DS.Colors.successBG)
}
```

Run full test suite:

```bash
swift test
# ✅ All tests pass
```

**3.4. Refactor**: Not needed (fix is already minimal)

**3.5. Update Preview**:

```swift
#Preview("Badge Fix - All Levels") {
    VStack(spacing: DS.Spacing.m) {
        Badge(text: "Info", level: .info)
        Badge(text: "Warning", level: .warning)  // Now shows yellow
        Badge(text: "Error", level: .error)
        Badge(text: "Success", level: .success)
    }
    .padding()
}
```

#### Step 4: Test Platforms

```bash
# iOS
xcodebuild test -scheme FoundationUI -destination 'platform=iOS Simulator,name=iPhone 15'

# macOS
swift test
```

#### Step 5: QA Checklist

- ✅ Bug not reproducible (warning badge shows yellow)
- ✅ Tests pass (all 45 tests passing)
- ✅ Regression tests added (testAllBadgeLevelsUseCorrectColors)
- ✅ Zero magic numbers (uses DS.Colors.warnBG)
- ✅ SwiftLint clean (0 violations)
- ✅ Preview works (shows all badge levels correctly)
- ✅ Accessibility maintained (contrast ratios unchanged)
- ✅ Platforms verified (iOS and macOS both work)

#### Step 6: Update Documentation

Task Plan:

```markdown
- [x] **P1** Fix Badge warning level color bug (Fixed: 2025-11-07)
```

PRD:

```markdown
#### Bug Fix: Badge Warning Color ✅ FIXED
**Fixed**: 2025-11-07
Changed `.warning` case to return correct `DS.Colors.warnBG` token.
```

Test Plan:

```markdown
### Bug Fix Regression Tests: Badge Warning Color
- `testWarningBadgeUsesCorrectBackgroundColor()` — Verifies correct color
- `testAllBadgeLevelsUseCorrectColors()` — Prevents all color bugs
```

#### Step 7: Archive Bug Spec

Updated `BUG_Badge_Warning_Color.md`:

```markdown
**Status**: ✅ FIXED — 2025-11-07

## Fix Implementation (2025-11-07)
- Changed line 15 in BadgeChipStyle.swift
- Added 2 regression tests
- Verified on iOS and macOS
```

#### Step 8: Commit

```bash
git add .
git commit -m "$(cat <<'EOF'
Fix Badge warning level shows wrong background color (#BUG_Badge_Warning_Color)

- Changed BadgeChipStyle.swift line 15 from DS.Colors.infoBG to DS.Colors.warnBG
- Added unit tests to prevent regression
- Verified on iOS and macOS Light/Dark mode
- SwiftLint clean, all tests passing

Severity: Medium (P1)
Layer: 1 (Modifier) affecting Layer 2 (Component)
EOF
)"
```

---

## 🧾 NOTES

### Role of FIX Command

This is an **implementation/execution command** that:

- ✅ Implements bug fixes based on specifications
- ✅ Follows TDD workflow (reproduce → fix → test)
- ✅ Adds comprehensive regression tests
- ✅ Verifies fix on all platforms
- ✅ Updates all documentation after fix
- ❌ Does NOT create bug specifications (use BUG command first)

### Relationship to Other Commands

- **BUG command**: Creates specifications → **FIX command**: Implements fixes
- **START command**: Implements new features → **FIX command**: Fixes existing bugs
- **ARCHIVE command**: Documents completed phases → Used after bug fixes complete

### When to Use FIX Command

Use FIX when:

- A bug specification exists in `DOCS/SPECS/BUG_*.md`
- Bug has been analyzed and root cause identified
- Fix approach has been proposed and reviewed
- Bug fix task is not blocked by prerequisites

Do NOT use FIX when:

- Bug has not been documented yet (use BUG command first)
- Root cause is unknown (investigate first)
- Fix requires new features (use NEW command to add feature, then fix)

### Best Practices

- **Always reproduce first**: Write failing test before implementing fix
- **Keep fix minimal**: Don't refactor unrelated code
- **Think regression**: Add tests that prevent bug recurrence
- **Test all platforms**: Especially for platform-specific bugs
- **Update documentation**: Keep Task Plan, PRD, Test Plan in sync
- **Commit atomically**: One bug = one commit (usually)

---

## END OF SYSTEM PROMPT

When work is complete, ensure Markdown formatting is consistent across all documentation.
