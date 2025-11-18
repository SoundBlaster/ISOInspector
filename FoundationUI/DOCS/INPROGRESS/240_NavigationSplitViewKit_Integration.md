# Task 240: Integrate NavigationSplitViewKit Dependency

**Phase**: 3.1 (Patterns & Platform Adaptation)
**Priority**: P0 (Critical for cross-platform navigation)
**Status**: Ready for Implementation
**Created**: 2025-11-18
**Specification**: [`NEW_NavigationSplitViewKit_Proposal.md`](./NEW_NavigationSplitViewKit_Proposal.md)

---

## 🎯 Objective

Add the external `NavigationSplitViewKit` Swift package as a dependency to FoundationUI, ensuring it integrates seamlessly across all build systems (SPM, Tuist) and CI/CD pipelines. This dependency is foundational for the `NavigationSplitScaffold` pattern work that follows in task 241.

---

## 🧩 Context

The FoundationUI project requires a production-ready implementation of SwiftUI's `NavigationSplitView` with synchronized state management and adaptive behaviors across iOS 17+, iPadOS 17+, and macOS 14+. The `NavigationSplitViewKit` package (https://github.com/SoundBlaster/NavigationSplitView) provides this foundation with:

- ✅ Adaptive three-column layout (Sidebar → Content → Inspector)
- ✅ Shared `NavigationModel` state with `@Bindable` support
- ✅ Column visibility orchestration for compact size classes
- ✅ Inspector pinning and resize behaviors on desktop/tablet
- ✅ Comprehensive DocC reference and Tuist demo for onboarding

**Dependency Chain**:
- Task 240 (this task) → Integrate dependency into package manifests and CI
- Task 241 (follow-up) → Create `NavigationSplitScaffold` wrapper pattern
- Task 242 (follow-up) → Update existing patterns to adopt shared navigation model

---

## ✅ Success Criteria

1. **SPM Integration**: `NavigationSplitViewKit` added to `FoundationUI/Package.swift` with:
   - Correct version pinning (`.from("1.0.0")` or higher)
   - Linked to all relevant targets (Examples, Tests, main library)
   - Swift 5.9+ compatibility verified

2. **Tuist Integration**:
   - Dependency mirrored in `FoundationUI/Project.swift`
   - Targets properly declare dependency on NavigationSplitViewKit
   - Project regenerates cleanly (`tuist generate`)

3. **Lockfile Updates**:
   - `FoundationUI/Package.resolved` regenerated after SPM dependency addition
   - Tuist lockfiles updated if applicable
   - Git status shows clean diffs for manifest-only changes

4. **CI/CD Updates**:
   - GitHub Actions workflows cache the new dependency
   - SPM test jobs validate compile against all platforms
   - Build time regression monitored (target: <120s for clean build)
   - Artifact uploads functional for dependency graphs

5. **Verification**:
   - ✅ Local build succeeds: `cd FoundationUI && swift build`
   - ✅ All tests pass: `swift test`
   - ✅ Tuist demo builds: `tuist build ComponentTestApp`
   - ✅ No SwiftLint violations introduced
   - ✅ Documentation updated (see below)

---

## 🔧 Implementation Notes

### Step 1: Update Package.swift

Location: `FoundationUI/Package.swift`

1. Add dependency to `dependencies` array:
```swift
.package(url: "https://github.com/SoundBlaster/NavigationSplitView", from: "1.0.0"),
```

2. Link to all targets requiring it:
   - `FoundationUI` main library target
   - `FoundationUITests` test target (for integration tests)
   - `ComponentTestApp` example target

3. Example target configuration:
```swift
.executableTarget(
    name: "ComponentTestApp",
    dependencies: [
        .target(name: "FoundationUI"),
        .product(name: "NavigationSplitViewKit", package: "NavigationSplitView"),
    ],
    // ... other config
),
```

### Step 2: Update Tuist Project.swift

Location: `FoundationUI/Project.swift` (if using Tuist)

1. Mirror the SPM dependency in Tuist manifest using `ExternalDependency`:
```swift
let navigationSplitViewKit = ExternalDependency.package(
    product: "NavigationSplitViewKit",
    condition: .none
)
```

2. Add to relevant target dependencies in project definition

3. Verify Tuist graph can resolve the dependency

### Step 3: Regenerate Lockfiles

**SPM**:
```bash
cd FoundationUI
swift package update
# Should update Package.resolved with NavigationSplitViewKit entries
```

**Tuist** (if applicable):
```bash
tuist install
# Regenerates Tuist lockfiles
```

### Step 4: Update CI Workflows

Files to check/update:
- `.github/workflows/foundationui.yml` — Add SPM dependency caching
- `.github/workflows/performance-regression.yml` — Monitor build time impact
- CI job for validation must cache Swift package dependencies for faster runs

Example cache configuration:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-
```

### Step 5: Documentation Updates

1. **README.md** (FoundationUI root):
   - Add NavigationSplitViewKit to the dependencies section
   - Note version requirement and link to upstream repo

2. **BUILD.md** (FoundationUI/DOCS/ or FoundationUI/Documentation/):
   - Document the new dependency
   - Explain why NavigationSplitViewKit is needed
   - Link to the specification and follow-up pattern work

3. **DEPENDENCIES.md** (if exists, or create):
   - Track all external dependencies
   - List version constraints and compatibility notes
   - Document any license considerations

---

## 🧪 Verification Steps

### Local Build Verification
```bash
# From FoundationUI directory
swift build 2>&1 | tee build.log
# Should complete without errors
```

### Test Verification
```bash
swift test
# All tests should pass, including new integration hooks for NavigationSplitViewKit
```

### Tuist Verification (if using Tuist)
```bash
tuist generate
tuist build ComponentTestApp --scheme ComponentTestApp
# ComponentTestApp should build and link successfully
```

### Dependency Graph Check
```bash
swift package describe --type json > /tmp/deps.json
# Verify NavigationSplitViewKit appears in transitive dependencies
```

### SwiftLint Check
```bash
swiftlint lint --strict
# No violations should be introduced by dependency additions
```

---

## 🔍 Known Constraints & Edge Cases

1. **Minimum Platform Versions**: Ensure NavigationSplitViewKit supports iOS 17+, iPadOS 17+, macOS 14+. If not, we may need to gate the dependency behind version checks.

2. **Swift Version Compatibility**: NavigationSplitViewKit must compile with Swift 5.9+. Verify during initial build.

3. **Breaking Changes in Upstream**: Monitor `NavigationSplitViewKit` releases for breaking changes. Once integrated, document version pinning strategy in `DEPENDENCIES.md`.

4. **CI Cache Invalidation**: If NavigationSplitViewKit updates frequently, ensure CI cache keys are based on `Package.resolved` to pick up new versions.

---

## 📋 Related Tasks

- **Predecessor**: None (this is Phase 3.1 kickoff for navigation)
- **Successor**: Task 241 — Create `NavigationSplitScaffold` pattern (depends on this)
- **Successor**: Task 242 — Update existing patterns (depends on tasks 240 + 241)
- **Related**: FoundationUI Task Plan Phase 3.1 (Patterns & Platform Adaptation)

---

## 🔗 References

- **Specification**: [`FoundationUI/DOCS/INPROGRESS/NEW_NavigationSplitViewKit_Proposal.md`](./NEW_NavigationSplitViewKit_Proposal.md)
- **Task Plan**: [`FoundationUI/DOCS/TASK_ARCHIVE/FoundationUI_TaskPlan.md`](../TASK_ARCHIVE/FoundationUI_TaskPlan.md) — Phase 3.1, lines 438–463
- **PRD**: [`FoundationUI/DOCS/AI/ISOViewer/FoundationUI_PRD.md`](../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Section 4.3 (NavigationSplitViewKit Integration)
- **Package Repository**: https://github.com/SoundBlaster/NavigationSplitView
- **Upstream Documentation**: Check repo for API docs and example usage

---

## ⚡ Effort Estimate

- **Discovery & Validation**: 0.5 days (verify compatibility, audit API)
- **Integration (SPM + Tuist)**: 1 day (add deps, regenerate, test locally)
- **CI/CD Updates**: 0.5 days (update workflows, cache config, monitor)
- **Documentation**: 0.5 days (update README, BUILD.md, DEPENDENCIES.md)
- **Buffer & Cleanup**: 0.5 days

**Total**: ~3 days (feasible as a single sprint task)

---

**Last Updated**: 2025-11-18
**Assigned To**: Claude Agent
**Status**: In Progress
