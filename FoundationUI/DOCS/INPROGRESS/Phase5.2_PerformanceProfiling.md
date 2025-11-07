# Phase 5.2: Performance Profiling with Instruments

## 🎯 Objective

Profile all FoundationUI components and patterns using Xcode Instruments to establish performance baselines, identify bottlenecks, and ensure release-ready performance standards (<100ms render time, <5MB memory usage, 60 FPS target).

## 🧩 Context

- **Phase**: 5.2 Testing & Quality Assurance
- **Layer**: All (Tokens → Modifiers → Components → Patterns)
- **Priority**: P0 (Critical for release readiness)
- **Task Status**: IN PROGRESS
- **Dependencies**:
  - ✅ Enhanced Demo App (Phase 5.4) - Complete with PerformanceMonitoringScreen
  - ✅ Unit test infrastructure - 84.5% coverage achieved
  - ✅ Accessibility audit - 98% score achieved
  - ✅ ComponentTestApp with benchmarking capabilities

## ✅ Success Criteria

- [ ] Time Profiler: Profile all components (render time <100ms)
- [ ] Allocations: Memory profiling shows <5MB peak memory per component
- [ ] Core Animation: Frame rate analysis (target: 60 FPS)
- [ ] Testing on oldest supported devices (iOS 17, macOS 14)
- [ ] Identify and document 3-5 major performance bottlenecks
- [ ] Performance report generated with findings and recommendations
- [ ] Performance baselines documented in `PERFORMANCE.md`
- [ ] SwiftLint violations: 0 across entire codebase
- [ ] CI/CD performance gates configured
- [ ] All platforms verified (iOS 17+, macOS 14+, iPadOS 17+)

## 🔧 Implementation Notes

### Performance Profiling Strategy

**1. Time Profiler Analysis (Primary bottlenecks)**
- Profile ComponentTestApp with PerformanceMonitoringScreen
- Test scenarios:
  - BoxTreePattern with 100 nodes (typical)
  - BoxTreePattern with 1000 nodes (stress test)
  - Full ISOInspectorDemoScreen render
  - All modifier stacking combinations
- Record baseline: target <100ms render time per frame

**2. Memory Profiling (Allocations instrument)**
- Measure memory per component type
- Stress test with large data sets
- Check for memory leaks in patterns
- Document peak memory usage (<5MB)

**3. Core Animation Profiling**
- Measure FPS during interactions
- Test on iOS 17 device (oldest supported)
- Target: 60 FPS consistent
- Profile animation performance

**4. Testing Devices**
- iOS: iPhone SE (oldest form factor), iPhone 15 Pro (current)
- macOS: MacBook Air M1 (baseline)
- iPadOS: iPad Air (mid-range)

### Files to Create/Modify

- `PERFORMANCE.md` - Performance baseline report
- `Tests/FoundationUITests/PerformanceTests/PerformanceBaselineTests.swift` - XCTest performance tests
- `.github/workflows/performance-regression.yml` - CI workflow for performance monitoring
- `.swiftlint.yml` - Enhanced SwiftLint configuration
- `.pre-commit-hooks.yaml` - Pre-commit hook configuration

### Design Token Usage

All components use DS tokens exclusively:
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG|...}`
- Radius: `DS.Radius.{card|chip|small}`
- Animation: `DS.Animation.{quick|medium|slow|spring}`

### SwiftLint Configuration Requirements

- Zero magic numbers enforcement
- Code style consistency
- Naming conventions validation
- Complexity checks
- CI integration with --strict mode

## 🧠 Source References

- [FoundationUI Task Plan § Phase 5.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § Testing & Quality Assurance](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [FoundationUI Test Plan § Performance](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
- [Next Tasks § Phase 5.2 Performance & Quality](../INPROGRESS/next_tasks.md)
- [Apple Xcode Instruments Guide](https://developer.apple.com/forums/tags/instruments/)
- [Swift Performance Best Practices](https://developer.apple.com/videos/play/wwdc2023/10181/)

## 📋 Checklist

### Task Preparation
- [x] Read task requirements from Task Plan
- [x] Review next_tasks.md for prioritized items
- [x] Verify dependencies (Enhanced Demo App, ComponentTestApp)
- [x] Create task document (this file)

### Performance Profiling Phase 1: Time Profiling
- [ ] Launch Xcode Instruments with Time Profiler
- [ ] Profile ComponentTestApp main screen
- [ ] Profile PerformanceMonitoringScreen with 100-node BoxTree
- [ ] Profile PerformanceMonitoringScreen with 1000-node BoxTree
- [ ] Profile ISOInspectorDemoScreen full render
- [ ] Document render times for each component

### Performance Profiling Phase 2: Memory Profiling
- [ ] Use Allocations instrument to measure memory
- [ ] Test each component type in isolation
- [ ] Test pattern composition (BoxTree + sidebar + toolbar)
- [ ] Verify no memory leaks detected
- [ ] Document peak memory usage

### Performance Profiling Phase 3: Frame Rate Analysis
- [ ] Use Core Animation tool to measure FPS
- [ ] Test on iOS 17 device (actual hardware if possible)
- [ ] Test on macOS 14 device
- [ ] Verify 60 FPS during interactions
- [ ] Document any dropped frames

### SwiftLint Compliance (P0)
- [ ] Review current SwiftLint configuration
- [ ] Run swiftlint on entire codebase
- [ ] Document all violations found
- [ ] Fix zero magic numbers violations
- [ ] Fix code style violations
- [ ] Verify 0 violations remaining
- [ ] Set up CI enforcement

### CI/CD Enhancement
- [ ] Create performance regression detection job
- [ ] Add accessibility test job to CI
- [ ] Add SwiftLint enforcement job
- [ ] Configure pre-commit hooks
- [ ] Configure pre-push hooks

### Documentation & Reporting
- [ ] Create PERFORMANCE.md with baselines
- [ ] Write performance best practices guide
- [ ] Create performance regression testing framework
- [ ] Document optimization recommendations
- [ ] Update Phase 5.2 section in Task Plan with [x]

### Final Verification
- [ ] All platforms tested (iOS 17+, macOS 14+, iPadOS 17+)
- [ ] Performance baselines documented
- [ ] SwiftLint: 0 violations
- [ ] Build succeeds: `swift build`
- [ ] Tests pass: `swift test`
- [ ] CI workflow passes
- [ ] Update Task Plan status to [x] COMPLETE
- [ ] Commit with descriptive message
- [ ] Push to `claude/implement-select-next-011CUuKPBVtQf3QjZjS4WvPB`

## 🎯 Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Component render time | <100ms | TBD (profiling) |
| Memory per component | <5MB | TBD (profiling) |
| Frame rate | 60 FPS | TBD (testing) |
| SwiftLint violations | 0 | TBD (audit) |
| Test coverage | ≥80% | ✅ 84.5% (achieved) |
| Accessibility score | ≥95% | ✅ 98% (achieved) |

## 📊 Session Log

- **2025-11-07**: Task document created, IN PROGRESS status assigned
- Next: Begin Time Profiler analysis with ComponentTestApp

---

**Last Updated**: 2025-11-07
**Task Owner**: Claude Code (AI assistant)
**Session ID**: 011CUuKPBVtQf3QjZjS4WvPB
