# FoundationUI Documentation

**Project**: FoundationUI - Design System for ISOInspector
**Last Updated**: 2025-11-08
**Status**: Active Development (Phase 5.2)

---

## 📑 Table of Contents

1. [Quick Navigation](#-quick-navigation)
2. [Directory Structure](#-directory-structure)
3. [Current Status](#-current-status)
4. [Development Guidelines](#-development-guidelines)
5. [Workflow Commands](#-workflow-commands)
6. [Active Work](#-active-work)
7. [Quality Metrics & Reports](#-quality-metrics--reports)
8. [Architecture Overview](#-architecture-overview)
9. [Project Statistics](#-project-statistics)
10. [Additional Resources](#-additional-resources)

---

## 🚀 Quick Navigation

### For Everyone
- **🎯 What's next?** → [next_tasks.md](INPROGRESS/next_tasks.md)
- **📈 Current progress?** → [Phase 5.2 Performance Profiling](INPROGRESS/Phase5.2_PerformanceProfiling.md)
- **✅ Quality gates?** → [Quality Metrics](#-quality-metrics--reports)

### For Developers
- **🧪 How do I test?** → [SwiftUI Testing Guidelines](RULES/02_SwiftUI_Testing_Guidelines.md)
- **👁️ How do I preview?** → [SwiftUI Previews Guidelines](RULES/01_SwiftUI_Previews_Guidelines.md)
- **🔒 Accessibility API safety?** → [Accessibility API Thread Safety](RULES/12_AccessibilityAPI_ThreadSafety.md)
- **🛠️ How do I build?** → [BUILD.md](../BUILD.md)

### For Maintainers
- **🆕 Starting new task?** → [COMMANDS/START.md](COMMANDS/START.md)
- **🎯 Selecting next task?** → [COMMANDS/SELECT_NEXT.md](COMMANDS/SELECT_NEXT.md)
- **📦 Archiving task?** → [COMMANDS/ARCHIVE.md](COMMANDS/ARCHIVE.md)
- **🆕 Creating new task?** → [COMMANDS/NEW.md](COMMANDS/NEW.md)
- **📊 Reporting status?** → [COMMANDS/STATE.md](COMMANDS/STATE.md)
- **🐛 Fixing bugs?** → [COMMANDS/FIX.md](COMMANDS/FIX.md)

---

## 📂 Directory Structure

```plaintext
FoundationUI/DOCS/
├── README.md                           ← You are here
│
├── COMMANDS/                            ← AI Workflow Prompts
│   ├── START.md                         System prompt for task initialization
│   ├── SELECT_NEXT.md                   System prompt for task selection
│   ├── NEW.md                           System prompt for creating new tasks
│   ├── ARCHIVE.md                       System prompt for archiving tasks
│   ├── STATE.md                         System prompt for status reporting
│   ├── FIX.md                          System prompt for bug fixes
│   └── BUG.md                          System prompt for bug analysis
│
├── RULES/                               ← Development Guidelines & Best Practices
│   ├── 01_SwiftUI_Previews_Guidelines.md      Preview standards and best practices
│   ├── 02_SwiftUI_Testing_Guidelines.md       Unit testing standards and patterns
│   └── 12_AccessibilityAPI_ThreadSafety.md    Thread safety for accessibility APIs
│
├── INPROGRESS/                          ← Current Work & Planning
│   ├── next_tasks.md                    Recommended next tasks (updated daily)
│   └── Phase5.2_PerformanceProfiling.md Automated performance monitoring setup
│
├── REPORTS/                             ← Quality & Audit Reports
│   └── AccessibilityAuditReport.md      WCAG 2.1 Level AA compliance (98% score)
│
├── TASK_ARCHIVE/                        ← Historical Task Records
│   └── [43 archived tasks from all phases]
│
├── CI_COVERAGE_SETUP.md                 Coverage quality gate configuration
├── ARCHIVE_REPORT_2025-10-26.md         Historical archive summary
├── PRD_CopyableArchitecture.md          Product requirements for Copyable
└── PRD_UtilityIntegrationTests.md       Product requirements for utilities
```

---

## 🎯 Current Status

### Phase 5.2: Testing & Quality Assurance
**Progress**: 11/18 tasks (61.1%)
- ✅ **Automated**: 8/8 complete
  - SwiftLint configuration & CI enforcement
  - Performance regression detection workflow
  - Accessibility test job in CI
  - Pre-commit and pre-push hooks

- ⏳ **Manual**: 3/10 deferred (lower priority)
  - Time Profiler analysis
  - Memory profiling with Allocations
  - Core Animation profiling
  - Device testing (see blocked.md)

### Quality Gates (Active)

| Gate | Status | Target |
|------|--------|--------|
| **SwiftLint violations** | ✅ Enforced | 0 violations |
| **Test coverage** | ✅ Monitored | ≥80% (achieved 84.5%) |
| **Accessibility** | ✅ Tested | ≥95% (achieved 98%) |
| **Build time** | ✅ Monitored | <120s |
| **Binary size** | ✅ Monitored | <15MB |
| **PR comments** | ✅ Active | Auto-report results |

### Completed Phases ✅

| Phase | Progress | Status |
|-------|----------|--------|
| Phase 1: Foundation | 10/10 (100%) | ✅ Complete |
| Phase 2: Core Components | 22/22 (100%) | ✅ Complete |
| Phase 3: Patterns & Platform Adaptation | 16/16 (100%) | ✅ Complete |
| Phase 4: Agent Support & Polish | 11/18 (61%) | 🚧 In Progress |
| **Phase 5: Documentation & QA** | **11/28 (39%)** | 🚧 In Progress |
| Phase 6: Integration & Validation | 0/17 (0%) | 📋 Planned |

---

## 🛠️ Development Guidelines

### Code Quality

Read these **before writing code**:

1. **[01_SwiftUI_Previews_Guidelines.md](RULES/01_SwiftUI_Previews_Guidelines.md)** (17.5 KB)
   - Preview coverage requirements (100%)
   - Device/Dark Mode coverage
   - Accessibility preview testing
   - Performance considerations

2. **[02_SwiftUI_Testing_Guidelines.md](RULES/02_SwiftUI_Testing_Guidelines.md)** (23.5 KB)
   - Unit test patterns (outside-in TDD)
   - Snapshot testing for visual regression
   - Accessibility test requirements
   - @MainActor test patterns
   - Test coverage targets (≥80%)

3. **[12_AccessibilityAPI_ThreadSafety.md](RULES/12_AccessibilityAPI_ThreadSafety.md)** (11.4 KB) 🆕
   - Thread safety with accessibility APIs
   - MainActor deadlock prevention
   - iOS vs macOS differences
   - Debugging strategies
   - Code review checklist

### Design System Usage

All code must use **DS (DesignSystem) tokens**:
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG|...}`
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Typography: `DS.Typography.{body|caption|headline}`
- Radius: `DS.Radius.{card|chip|small}`
- Animation: `DS.Animation.{quick|medium|slow|spring}`

See [DesignSystem.swift](../Sources/FoundationUI/DesignTokens/DesignSystem.swift) for complete token reference.

---

## 🤖 Workflow Commands

### Structured AI Workflows

Each command corresponds to a **system prompt** that guides AI assistants through complex tasks:

#### 1. **START.md** - Begin Implementation
**When**: Starting a new task from the task plan
**What it does**: Initialize TDD workflow, verify dependencies, run first test
**Estimated effort**: 5-15 minutes setup
**Output**: Failing test + implementation plan

#### 2. **SELECT_NEXT.md** - Choose Next Task
**When**: Finished current task, need prioritization
**What it does**: Analyze task plan, identify blockers, recommend next task
**Output**: Prioritized task list with effort estimates

#### 3. **NEW.md** - Create New Task
**When**: Need to add task not in original plan
**What it does**: Create task definition, archive structure, initial requirements
**Output**: Task.md document ready for implementation

#### 4. **ARCHIVE.md** - Complete & Archive Task
**When**: Task implementation finished and tests passing
**What it does**: Create archive directory, document work, update task plan
**Output**: Archived task folder with full history

#### 5. **STATE.md** - Status Report
**When**: Need progress summary for team/stakeholders
**What it does**: Generate metrics, list blockers, predict completion
**Output**: Markdown report with charts and metrics

#### 6. **FIX.md** - Bug Fix Workflow
**When**: Bug reported, need structured fix process
**What it does**: Isolate bug, write failing test, implement fix, verify
**Output**: Fixed code with test coverage

#### 7. **BUG.md** - Bug Analysis
**When**: Need to analyze complex bug behavior
**What it does**: Reproduce bug, identify root cause, document patterns
**Output**: Bug analysis report + fix recommendations

---

## 📋 Active Work

### Current Focus: Phase 5.2 Performance & Quality

**Next Task Options** (in priority order):

1. **Phase 4.1: Agent-Driven UI Generation** (P1, 14-20h)
   - Enable AI agents to generate FoundationUI components
   - Define AgentDescribable protocol
   - YAML schema support

2. **Phase 6.1: Platform-Specific Demo Apps** (P1, 16-24h)
   - iOS-specific example application
   - macOS-specific example application
   - iPad-specific example application

3. **Phase 5.2 Manual Profiling** (Lower priority, 8-12h)
   - See [Phase5.2_PerformanceProfiling.md](INPROGRESS/Phase5.2_PerformanceProfiling.md)
   - Deferred to [blocked.md](INPROGRESS/blocked.md)

### How to Get Started

1. **Read**: [next_tasks.md](INPROGRESS/next_tasks.md) for current recommendations
2. **Plan**: Review task requirements in [Task Plan](../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
3. **Start**: Use [COMMANDS/START.md](COMMANDS/START.md) workflow
4. **Code**: Follow [RULES/02_SwiftUI_Testing_Guidelines.md](RULES/02_SwiftUI_Testing_Guidelines.md)
5. **Archive**: Use [COMMANDS/ARCHIVE.md](COMMANDS/ARCHIVE.md) when complete

---

## 📊 Quality Metrics & Reports

### Accessibility Audit (Completed 2025-11-06)

**Location**: [REPORTS/AccessibilityAuditReport.md](REPORTS/AccessibilityAuditReport.md)

| Category | Score | Target | Status |
|----------|-------|--------|--------|
| **Overall** | 98% | ≥95% | ✅ **EXCEEDS** |
| Contrast Ratio (WCAG AA) | 100% | ≥95% | ✅ Pass |
| Touch Targets | 95.5% | ≥95% | ✅ Pass |
| VoiceOver Support | 100% | ≥95% | ✅ Pass |
| Dynamic Type | 100% | ≥95% | ✅ Pass |
| Integration Tests | 96.7% | ≥95% | ✅ Pass |

**Test Coverage**: 99 automated accessibility tests

### Code Coverage (Baseline 2025-11-06)

| Platform | Coverage | Threshold | Status |
|----------|----------|-----------|--------|
| **iOS** | 67.24% | ≥67% | ✅ Pass |
| **macOS** | 69.61% | ≥67% | ✅ Pass |
| **Current** | 84.5% | ≥80% | ✅ **EXCEEDS** |

**Tracked by**: [.github/workflows/foundationui-coverage.yml](../../.github/workflows/foundationui-coverage.yml)

### CI/CD Quality Gates

**SwiftLint Status**: ✅ Configured & Active
- **Configuration**: [FoundationUI/.swiftlint.yml](../.swiftlint.yml)
- **Workflow**: [.github/workflows/swiftlint.yml](../../.github/workflows/swiftlint.yml)
- **Target**: 0 violations (strict enforcement)

**Performance Monitoring**: ✅ Configured & Active
- **Workflow**: [.github/workflows/performance-regression.yml](../../.github/workflows/performance-regression.yml)
- **Metrics**: Build time, binary size, test execution
- **Targets**: <120s build, <15MB binary, <30s tests

---

## 🏗️ Architecture Overview

FoundationUI follows a **5-layer composable architecture**:

```plaintext
┌────────────────────────────────────────────┐
│  Layer 4: Contexts (Platform Adaptation)   │  Environment keys
│  AccessibilityContext, ColorSchemeAdapter  │  State propagation
└────────────────────────────────────────────┘
              ↑
┌────────────────────────────────────────────┐
│  Layer 3: Patterns (Complex Compositions)  │  Real-world layouts
│  InspectorPattern, BoxTreePattern, etc.    │  Navigation, state mgmt
└────────────────────────────────────────────┘
              ↑
┌────────────────────────────────────────────┐
│  Layer 2: Components (Reusable Views)      │  Badge, Card, etc.
│  Badge, Card, KeyValueRow, SectionHeader   │  Self-contained
└────────────────────────────────────────────┘
              ↑
┌────────────────────────────────────────────┐
│  Layer 1: Modifiers (View Extensions)      │  .badgeChipStyle
│  badgeChipStyle, cardStyle, etc.           │  Composable styles
└────────────────────────────────────────────┘
              ↑
┌────────────────────────────────────────────┐
│  Layer 0: Design Tokens (Constants)        │  100% coverage
│  Colors, Spacing, Typography, Radius       │  Zero magic numbers
└────────────────────────────────────────────┘
```

**Key principles**:
- ✅ Zero magic numbers (all values use DS tokens)
- ✅ 100% preview coverage for Layer 0-3
- ✅ ≥80% test coverage per layer
- ✅ WCAG 2.1 Level AA accessibility
- ✅ Platform adaptation (iOS/macOS/iPadOS)
- ✅ Strict concurrency (@MainActor, Sendable)

---

## 📊 Project Statistics

### Code Metrics

| Metric | Value |
|--------|-------|
| **Production Lines** | ~6,000+ |
| **Test Lines** | ~2,500+ |
| **Test Count** | 200+ |
| **Test Coverage** | 84.5% (current) |
| **Accessibility Score** | 98% |

### Component Inventory

| Category | Count |
|----------|-------|
| **Design Tokens** | 50+ |
| **View Modifiers** | 8+ |
| **Components** | 5 |
| **Patterns** | 4 |
| **Utilities** | 4 |
| **Contexts** | 3 |

### Supported Platforms

- iOS 17+
- iPadOS 17+
- macOS 14+
- tvOS 17+ (partial)

---

## 📖 Additional Resources

### Project Documentation

| Document | Purpose |
|----------|---------|
| [BUILD.md](../BUILD.md) | Build instructions & requirements |
| [README.md](../README.md) | Package overview and usage |
| [Package.swift](../Package.swift) | SPM manifest |
| [Project.swift](../Project.swift) | Tuist project definition |

### External References

| Resource | Link |
|----------|------|
| **Task Plan** | [FoundationUI_TaskPlan.md](../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) |
| **PRD** | [FoundationUI_PRD.md](../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) |
| **Test Plan** | [FoundationUI_TestPlan.md](../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) |
| **Main DOCS** | [Main DOCS/RULES](../../DOCS/RULES/) |

### Development Tools

```bash
# Run tests
swift test --parallel

# Check coverage
swift build --enable-code-coverage
swift test --enable-code-coverage

# Lint code
swiftlint --config FoundationUI/.swiftlint.yml

# Build framework
swift build

# Generate DocC
xcodebuild docbuild -scheme FoundationUI
```

---

## 🗓️ Version History

| Date | Change | Version |
|------|--------|---------|
| 2025-11-08 | Add comprehensive TOC and structure documentation | 1.1 |
| 2025-11-06 | Add Phase 5.2 quality gates | 1.0 |
| 2025-10-26 | Initial documentation | 0.9 |

---

## 📝 Contributing

1. **Before coding**: Read [RULES/](RULES/)
2. **During development**: Follow TDD from [COMMANDS/START.md](COMMANDS/START.md)
3. **After completion**: Archive with [COMMANDS/ARCHIVE.md](COMMANDS/ARCHIVE.md)
4. **For guidance**: Check [next_tasks.md](INPROGRESS/next_tasks.md)

---

## ✨ Quick Checklist for New Contributors

- [ ] Read [RULES/02_SwiftUI_Testing_Guidelines.md](RULES/02_SwiftUI_Testing_Guidelines.md)
- [ ] Review [RULES/01_SwiftUI_Previews_Guidelines.md](RULES/01_SwiftUI_Previews_Guidelines.md)
- [ ] Check [RULES/12_AccessibilityAPI_ThreadSafety.md](RULES/12_AccessibilityAPI_ThreadSafety.md) if working with accessibility APIs
- [ ] Use [COMMANDS/START.md](COMMANDS/START.md) for new tasks
- [ ] Run `swift test` locally before pushing
- [ ] Verify SwiftLint with `swiftlint --config FoundationUI/.swiftlint.yml`

---

**Last Updated**: 2025-11-08
**Maintainer**: FoundationUI Team
**Status**: Living Document - Updated as project evolves
