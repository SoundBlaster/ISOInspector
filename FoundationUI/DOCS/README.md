# FoundationUI Documentation

**Project**: FoundationUI - Design System for ISOInspector
**Last Updated**: 2025-11-06

---

## 🚨 Quality Gates

### Code Coverage (Active)

> **Current Threshold: 67%** (baseline from 2025-11-06)
> **Target Threshold: 80%** (planned improvement)

| Platform | Current Coverage | Threshold | Status |
|----------|-----------------|-----------|--------|
| **iOS** | 67.24% | ≥67% | ✅ Pass |
| **macOS** | 69.61% | ≥67% | ✅ Pass |

**Why 67%?**
- Based on actual CI measurements (not estimated)
- Prevents regression while planning improvement
- Realistic baseline for incremental progress
- Industry target: 80% (to be achieved separately)

📖 **Full Documentation**: [CI_COVERAGE_SETUP.md](CI_COVERAGE_SETUP.md)

---

## 📚 Key Documents

### Active Development
- **[next_tasks.md](INPROGRESS/next_tasks.md)** - Current tasks and priorities
- **[CoverageReport_2025-11-06.md](INPROGRESS/CoverageReport_2025-11-06.md)** - Latest coverage analysis
- **[Phase5.2_ComprehensiveUnitTestCoverage.md](INPROGRESS/Phase5.2_ComprehensiveUnitTestCoverage.md)** - Coverage improvement plan

### CI/CD & Quality
- **[CI_COVERAGE_SETUP.md](CI_COVERAGE_SETUP.md)** - Coverage quality gate configuration
- **[02_SwiftUI_Testing_Guidelines.md](RULES/02_SwiftUI_Testing_Guidelines.md)** - Testing standards
- **[01_SwiftUI_Previews_Guidelines.md](RULES/01_SwiftUI_Previews_Guidelines.md)** - Preview standards

### Commands
- **[SELECT_NEXT.md](COMMANDS/SELECT_NEXT.md)** - Task selection workflow
- **[STATE.md](COMMANDS/STATE.md)** - Project state reporting
- **[START.md](COMMANDS/START.md)** - Task initialization
- **[ARCHIVE.md](COMMANDS/ARCHIVE.md)** - Task archival
- **[NEW.md](COMMANDS/NEW.md)** - New task creation

---

## 🎯 Current Focus: Phase 5.2 Comprehensive Testing

**Goal**: Improve test coverage and quality standards

### Completed ✅
- ✅ Unit test infrastructure
- ✅ Coverage analysis tooling
- ✅ CI coverage workflow (67% baseline)
- ✅ Comprehensive pattern tests (97 new tests added)

### In Progress 🔄
- 🔄 Coverage improvement to 80% target (separate task on macOS)

### Planned 📋
- 📋 Accessibility audit (≥95% score)
- 📋 Performance profiling with Instruments
- 📋 SwiftLint compliance (0 violations)
- 📋 Pre-commit hooks

---

## 📊 Project Statistics

**Lines of Code**: ~6,000+ (production)
**Test Lines**: ~2,500+ (test code)
**Test Coverage**: 67-69% (varies by platform)
**Test Count**: 200+ tests
**Components**: 5 (Badge, Card, KeyValueRow, SectionHeader, Copyable)
**Patterns**: 4 (Inspector, Sidebar, Toolbar, BoxTree)
**Utilities**: 4 (AccessibilityHelpers, CopyableText, KeyboardShortcuts, DynamicTypeSize+Ext)

---

## 🛠️ Quick Links

### For Developers
- 🧪 Run tests: `swift test --parallel` (SPM) or `xcodebuild test` (Xcode)
- 📊 Check coverage: See [CI_COVERAGE_SETUP.md](CI_COVERAGE_SETUP.md)
- 📝 Write tests: Follow [02_SwiftUI_Testing_Guidelines.md](RULES/02_SwiftUI_Testing_Guidelines.md)
- 🔍 Review code: Use [SwiftLint](.swiftlint.yml) configuration

### For Maintainers
- 📈 View progress: Check [FoundationUI_TaskPlan.md](../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- 🗂️ Archive tasks: Use [ARCHIVE.md](COMMANDS/ARCHIVE.md) workflow
- 🆕 Create tasks: Use [NEW.md](COMMANDS/NEW.md) workflow
- 📊 Generate reports: Use [STATE.md](COMMANDS/STATE.md) workflow

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────┐
│  Layer 4: Patterns (macOS/iOS-specific) │  ← 59% coverage
│  InspectorPattern, SidebarPattern, etc.  │
└─────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────┐
│  Layer 3: Contexts (Platform Adaptation)│  ← 78% coverage
│  ColorSchemeAdapter, PlatformAdaptation │
└─────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────┐
│  Layer 2: Components (Reusable Views)   │  ← 75% coverage
│  Badge, Card, KeyValueRow, etc.         │
└─────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────┐
│  Layer 1: Modifiers (View Extensions)   │  ← 72% coverage
│  SurfaceStyle, InteractiveStyle, etc.   │
└─────────────────────────────────────────┘
                  │
┌─────────────────────────────────────────┐
│  Layer 0: Design Tokens (Constants)     │  ← 100% coverage
│  Colors, Spacing, Typography, etc.      │
└─────────────────────────────────────────┘
```

---

## 📖 Additional Resources

- **[BUILD.md](../BUILD.md)** - Build instructions and requirements
- **[README.md](../README.md)** - Package overview and usage
- **[Package.swift](../Package.swift)** - SPM configuration
- **[Project.swift](../Project.swift)** - Tuist configuration

---

**Note**: This is a living document. Update as project evolves.
