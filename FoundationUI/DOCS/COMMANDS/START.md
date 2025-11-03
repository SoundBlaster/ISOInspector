# SYSTEM PROMPT: Start FoundationUI Task Implementation

## 🧩 PURPOSE

Begin active implementation of tasks defined in the FoundationUI Task Plan, following TDD, XP, and Composable Clarity Design System principles.

---

## 🎯 GOAL

Execute one or more tasks from the [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md), fully adhering to:

- **TDD (Test-Driven Development)** - Write tests first, then implementation
- **XP (Extreme Programming)** - Small iterations, continuous refactoring
- **PDD (Puzzle-Driven Development)** - Leave @todo markers for incomplete work
- **Zero Magic Numbers** - All values must use DS (Design System) tokens
- **Composable Clarity** - Layered architecture (Tokens → Modifiers → Components → Patterns → Contexts)

---

## 📚 REFERENCE MATERIALS

### Primary Documents

- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Authoritative task list with phases
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements and success criteria
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy and requirements

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

```
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

### Step 1. Identify Active Phase and Tasks

1. Open the [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
2. Check the **Overall Progress Tracker** to see current phase status
3. Scan tasks in [`FoundationUI/DOCS/INPROGRESS/`](../INPROGRESS) for active work
4. If no active tasks exist, select the next uncompleted task from the current phase

### Step 2. Verify Prerequisites

Before starting implementation, ensure:

- **Design Tokens exist** (Layer 0 must be complete before modifiers)
- **Tests directory is set up** (`Tests/FoundationUITests/`)
- **SwiftLint is configured** (zero violations policy)
- **Package.swift is current** (Swift 5.9+, platforms iOS 17+/macOS 14+)
- **Linux Swift toolchain is known** — The container runs Swift 6.1 on x86_64 Linux, where SwiftUI frameworks are unavailable; use `swift test` and cross-platform compilation checks for validation.

### Step 3. Apply TDD Cycle (Outside-In)

For each task, follow strict TDD workflow:

1. **Write a failing test first**
   - Create test file: `Tests/FoundationUITests/{ComponentName}Tests.swift`
   - Define expected behavior with XCTest assertions
   - Run tests to confirm failure: `swift test`

2. **Implement minimal code to pass**
   - Create source file: `Sources/FoundationUI/{Layer}/{ComponentName}.swift`
   - Use DS tokens exclusively (e.g., `DS.Spacing.m`, `DS.Colors.infoBG`)
   - Add SwiftUI Preview at bottom of file
   - Run tests to confirm pass: `swift test`

3. **Refactor while keeping tests green**
   - Remove duplication
   - Improve naming and clarity
   - Extract reusable components
   - Verify tests still pass

4. **Add DocC documentation**
   - Triple-slash comments (`///`) for public API
   - Code examples in documentation
   - Platform-specific notes

### Step 4. Follow Composable Clarity Layers

Implement components in strict layer order:

```
Layer 0: Design Tokens (DS namespace)
   ↓
Layer 1: View Modifiers (.badgeChipStyle, .cardStyle, etc.)
   ↓
Layer 2: Components (Badge, Card, KeyValueRow, etc.)
   ↓
Layer 3: Patterns (InspectorPattern, SidebarPattern, etc.)
   ↓
Layer 4: Contexts (Environment keys, platform adaptation)
```

**Never skip layers.** Lower layers must be complete before building higher layers.

### Step 5. Quality Assurance Checklist

Before marking a task complete, verify:

- ✅ **Tests pass**: `swift test` shows 100% pass rate
- ✅ **Zero magic numbers**: All values use DS tokens
- ✅ **SwiftLint clean**: `swiftlint` reports 0 violations
- ✅ **Preview works**: SwiftUI preview renders correctly
- ✅ **Accessibility**: VoiceOver labels, contrast ratios validated
- ✅ **Documentation**: DocC comments on all public symbols
- ✅ **Platform support**: Tested on iOS/macOS (iPadOS where applicable)

### Step 6. Track Progress

1. Update task status in [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
   - Change `[ ]` to `[x]` for completed tasks
   - Update phase progress percentages
2. If work is incomplete, leave `@todo` puzzles in code:

   ```swift
   // @todo #42 Add Dark Mode color variants for warning badge
   ```

3. Create summary in `DOCS/INPROGRESS/Summary_of_Work.md` when session ends

### Step 7. Commit and Document

Follow git best practices:

- **Atomic commits**: One task = one commit
- **Descriptive messages**: Reference task number and what was achieved

  ```
  Add BadgeChipStyle modifier with all variants (#2.1)

  - Implements info, warning, error, success levels
  - Uses DS.Colors and DS.Radius tokens exclusively
  - Includes unit tests and SwiftUI previews
  - VoiceOver labels for all badge types
  ```

- **Run tests in CI**: Ensure pipeline passes before merging

---

## 🎨 FOUNDATIONUI-SPECIFIC CONVENTIONS

### File Organization

```
Sources/FoundationUI/
├── DesignTokens/
│   ├── DesignSystem.swift       # DS namespace enum
│   ├── Spacing.swift            # DS.Spacing.s/m/l/xl
│   ├── Colors.swift             # DS.Colors.infoBG/etc
│   └── ...
├── Modifiers/
│   ├── BadgeChipStyle.swift     # .badgeChipStyle(level:)
│   └── ...
├── Components/
│   ├── Badge.swift              # Badge(text:level:)
│   └── ...
├── Patterns/
│   └── InspectorPattern.swift   # InspectorPattern(title:content:)
└── Contexts/
    └── SurfaceStyleKey.swift    # @Environment(\.surfaceStyle)

Tests/FoundationUITests/
├── DesignTokensTests/
├── ModifiersTests/
├── ComponentsTests/
└── ...
```

### Naming Conventions

- **Design Tokens**: `DS.{Category}.{name}` (e.g., `DS.Spacing.m`, `DS.Colors.infoBG`)
- **Modifiers**: Lowercase with descriptive name (e.g., `.badgeChipStyle(level: .warning)`)
- **Components**: PascalCase struct name (e.g., `Badge`, `KeyValueRow`)
- **Enums**: Use semantic names (e.g., `BadgeLevel.info`, not `.blue`)

### Testing Requirements

Every component must have:

1. **Unit tests** (logic, state, API contracts)
2. **Snapshot tests** (visual regression, Light/Dark mode)
3. **Accessibility tests** (VoiceOver, contrast, Dynamic Type)
4. **SwiftUI Previews** (embedded in source file)

Minimum test coverage: **≥80%**

---

## ✅ EXPECTED OUTPUT

At the end of a work session:

- All selected tasks from `DOCS/INPROGRESS` are implemented
- Tests pass with ≥80% coverage
- SwiftLint reports 0 violations
- Task Plan is updated with completed checkmarks
- Summary document created in `DOCS/INPROGRESS/Summary_of_Work.md`
- Code is committed to the designated branch

---

## 🧠 EXAMPLE WORKFLOW

**Starting Phase 2.1: BadgeChipStyle Modifier**

1. Read task from [Task Plan Phase 2.1](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#21-layer-1-view-modifiers-atoms)
2. Create `Tests/FoundationUITests/ModifiersTests/BadgeChipStyleTests.swift`:

   ```swift
   func testBadgeChipStyleAppliesCorrectBackgroundColor() {
       let view = Text("Test")
           .badgeChipStyle(level: .info)
       // Assert background color matches DS.Colors.infoBG
   }
   ```

3. Run `swift test` → fails (modifier doesn't exist yet)
4. Create `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift`:

   ```swift
   import SwiftUI

   public extension View {
       func badgeChipStyle(level: BadgeLevel) -> some View {
           self
               .padding(.horizontal, DS.Spacing.m)
               .background(level.backgroundColor)
               .cornerRadius(DS.Radius.chip)
       }
   }

   public enum BadgeLevel {
       case info, warning, error, success

       var backgroundColor: Color {
           switch self {
           case .info: return DS.Colors.infoBG
           case .warning: return DS.Colors.warnBG
           case .error: return DS.Colors.errorBG
           case .success: return DS.Colors.successBG
           }
       }
   }

   #Preview {
       VStack {
           Text("Info").badgeChipStyle(level: .info)
           Text("Warning").badgeChipStyle(level: .warning)
       }
   }
   ```

5. Run `swift test` → passes ✅
6. Add DocC comments, accessibility labels
7. Update Task Plan: `[x] Implement BadgeChipStyle modifier`
8. Commit: `git commit -m "Add BadgeChipStyle modifier (#2.1)"`

---

## 🧾 NOTES

- **Design System Tokens First**: Never hardcode values like `12` or `Color.blue`. Always use `DS` namespace.
- **Test Before Code**: Outside-in TDD is non-negotiable. Write failing test, then implement.
- **Platform Differences**: Use `#if os(macOS)` conditionals for platform-specific behavior.
- **Previews Are Documentation**: SwiftUI previews serve as live examples in Xcode.
- **Accessibility Is Core**: Not an afterthought. Build it in from the start.

---

## END OF SYSTEM PROMPT

When work is complete, ensure Markdown formatting is consistent across all documentation.
