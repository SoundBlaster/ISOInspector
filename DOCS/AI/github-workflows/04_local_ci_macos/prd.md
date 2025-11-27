# PRD: Local CI Execution on macOS

## 1. Purpose

Enable developers to run the same tests, actions, and jobs locally on macOS that normally execute in GitHub Actions CI, providing fast feedback during development and reducing CI iteration cycles.

## 2. Problem Statement

Currently, developers must push commits to GitHub to validate:
- SwiftLint compliance
- Swift formatting
- Build success across platforms
- Test execution (unit, integration, snapshot)
- Coverage thresholds
- DocC documentation builds
- Python script tests

This creates a slow feedback loop and wastes CI resources on trivial issues that could be caught locally.

## 3. Goals

1. **Primary**: Provide scripts to run all CI jobs locally on macOS
2. **Secondary**: Support Docker-based execution where applicable (SwiftLint, Python tests)
3. **Tertiary**: Create clear documentation for setup and usage

## 4. Non-Goals

- Replace GitHub Actions CI (local execution is supplementary)
- Support Windows or Linux as primary development platforms (focus on macOS)
- Automate CI job discovery (manual script maintenance is acceptable)

## 5. Scope

### 5.1. CI Jobs to Support Locally

From analysis of `.github/workflows/`:

#### Tier 1: Essential (must support)
1. **SwiftLint** (`swiftlint.yml`)
   - Main project linting
   - FoundationUI linting
   - ComponentTestApp linting
   - Execution: Native (brew) or Docker

2. **Swift Format Check** (`ci.yml`)
   - Format validation
   - Execution: Native (swift-format CLI)

3. **Build and Test** (`ci.yml`, `macos.yml`, `foundationui.yml`)
   - Swift Package Manager builds (ISOInspectorKit, CLI)
   - Xcode builds (macOS app, iOS/macOS FoundationUI)
   - Unit tests
   - Snapshot tests
   - Execution: Native (swift build/test, xcodebuild)

4. **Coverage Analysis** (`swift-linux.yml`)
   - Code coverage thresholds
   - Execution: Native (llvm-cov)

#### Tier 2: Important (should support)
5. **Script Tests** (`script-tests.yml`)
   - Python unit tests
   - Syntax validation
   - Execution: Docker (Python containers) or native

6. **DocC Validation** (`foundationui.yml`, `ci.yml`)
   - Documentation builds
   - Execution: Native (xcodebuild docbuild)

7. **JSON Validation** (`ci.yml`)
   - MP4RABoxes.json validation
   - Execution: Native (Python script)

#### Tier 3: Optional (nice to have)
8. **Markdown Validation** (`ci.yml` - currently disabled)
9. **Strict Concurrency** (`ci.yml`)
10. **Accessibility Tests** (`foundationui.yml`)

### 5.2. Execution Modes

1. **Native macOS**: Direct execution on host machine
   - Pros: Fast, no container overhead, matches CI exactly for macOS jobs
   - Cons: Requires tool installation, potential version mismatches
   - Use for: Swift builds, tests, xcodebuild, DocC

2. **Docker**: Containerized execution
   - Pros: Consistent environment, matches Linux CI exactly
   - Cons: Slower, requires Docker Desktop
   - Use for: SwiftLint (ghcr.io/realm/swiftlint), Python tests

## 6. User Stories

### US-1: Quick Validation
As a developer, I want to run all formatting and linting checks locally before committing, so I can avoid CI failures.

**Acceptance Criteria:**
- Single command runs: SwiftLint, swift-format, JSON validation
- Completes in <30 seconds for typical changes
- Reports violations in same format as CI

### US-2: Full Test Suite
As a developer, I want to run the complete test suite locally, so I can verify my changes before pushing.

**Acceptance Criteria:**
- Runs all unit tests (Kit, CLI, FoundationUI)
- Runs snapshot tests where applicable
- Reports coverage metrics
- Matches CI test selection exactly

### US-3: Platform-Specific Builds
As a developer, I want to test macOS and iOS builds locally, so I can catch platform-specific issues early.

**Acceptance Criteria:**
- Supports Tuist project generation
- Builds ISOInspectorApp (macOS)
- Builds FoundationUI (iOS + macOS)
- Builds ComponentTestApp (iOS + macOS)

### US-4: Incremental Execution
As a developer, I want to run individual CI jobs (e.g., just SwiftLint or just tests), so I can iterate quickly on specific issues.

**Acceptance Criteria:**
- Each job has standalone script
- Scripts support --help flag
- Exit codes match CI expectations

## 7. Technical Design

### 7.1. Script Structure

```
scripts/local-ci/
├── README.md                    # Usage guide
├── run-all.sh                   # Run complete CI suite
├── run-lint.sh                  # SwiftLint + swift-format
├── run-build.sh                 # All build variants
├── run-tests.sh                 # All test suites
├── run-coverage.sh              # Coverage analysis
├── run-scripts.sh               # Python script tests
├── run-docc.sh                  # DocC builds
└── lib/
    ├── common.sh                # Shared functions
    ├── docker-helpers.sh        # Docker utilities
    └── ci-env.sh                # Environment setup
```

### 7.2. Dependencies

#### Required (Tier 1)
- macOS 13+ (Ventura or later)
- Xcode 16.0+ (matches CI)
- Homebrew (for tool installation)
- Swift 6.0+ (bundled with Xcode)

#### Optional (for full parity)
- Docker Desktop (for containerized SwiftLint/Python)
- Tuist (for workspace generation, installed by script)
- Python 3.10-3.12 (for script tests)

### 7.3. Key Implementation Details

#### SwiftLint Execution
```bash
# Option 1: Native (requires brew install swiftlint)
swiftlint lint --strict --config .swiftlint.yml

# Option 2: Docker (exact CI parity)
docker run --rm -u "$(id -u):$(id -g)" \
  -v "$PWD:/work" -w /work \
  ghcr.io/realm/swiftlint:0.53.0 \
  swiftlint lint --strict --config .swiftlint.yml
```

#### Xcode Build Matrix
```bash
# FoundationUI iOS
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# FoundationUI macOS
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=macOS'
```

#### Coverage Threshold
```bash
# Run tests with coverage
swift test --enable-code-coverage

# Check threshold (reuse existing script)
python scripts/check_coverage_threshold.py --threshold 0.67
```

### 7.4. Configuration

Create `.local-ci-config` in repo root:
```bash
# Tool paths (auto-detected if not specified)
XCODE_PATH="/Applications/Xcode.app"
TUIST_VERSION=""  # Auto-fetch from GitHub API if empty
SWIFTLINT_MODE="native"  # or "docker"

# Test configuration
SKIP_SNAPSHOT_TESTS=false
SKIP_IOS_TESTS=false
COVERAGE_THRESHOLD=0.67

# Parallel execution
PARALLEL_BUILDS=true
MAX_JOBS=4
```

## 8. Deliverables

### Phase 1: Core Scripts (Week 1)
- [x] Analyze CI workflows
- [ ] Create script structure
- [ ] Implement run-lint.sh (SwiftLint + swift-format)
- [ ] Implement run-build.sh (SPM + xcodebuild)
- [ ] Implement run-tests.sh (unit + snapshot)
- [ ] Basic README with setup instructions

### Phase 2: Advanced Features (Week 2)
- [ ] Implement run-coverage.sh
- [ ] Implement run-scripts.sh (Python tests)
- [ ] Implement run-docc.sh
- [ ] Docker support for SwiftLint/Python
- [ ] Tuist auto-installation
- [ ] Configuration file support

### Phase 3: Integration (Week 3)
- [ ] run-all.sh orchestration script
- [ ] CI parity validation tests
- [ ] Performance benchmarking
- [ ] Developer onboarding guide
- [ ] Update CONTRIBUTING.md

## 9. Success Metrics

1. **Coverage**: Scripts cover ≥80% of CI job types
2. **Parity**: Local results match CI outcomes in ≥95% of cases
3. **Performance**: Full suite completes in <10 minutes on M1 MacBook Pro
4. **Adoption**: ≥50% of team uses local CI within 1 month

## 10. Open Questions

1. **Q**: Should we support pre-commit hooks integration?
   **A**: Deferred to Phase 4; focus on manual execution first

2. **Q**: How to handle CI secrets (e.g., GITHUB_TOKEN for Tuist fetch)?
   **A**: Scripts use public API calls; authentication is optional

3. **Q**: Support for Apple Silicon vs Intel?
   **A**: Both supported; Rosetta compatibility for Intel-only tools

## 11. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| CI environment drift | High | Pin tool versions in scripts, auto-fetch from CI YAML |
| Docker Desktop license costs | Medium | Provide native alternatives for all jobs |
| Tuist version mismatches | Medium | Auto-detect from CI, cache binaries |
| Xcode version incompatibility | High | Validate Xcode version before execution |

## 12. Future Enhancements

- **Act integration**: Use [nektos/act](https://github.com/nektos/act) to run GitHub Actions locally
- **Pre-commit hooks**: Auto-run linting/formatting on git commit
- **VS Code tasks**: Integrate scripts as IDE tasks
- **CI/CD dashboard**: Local web UI for test results
- **Remote execution**: Trigger jobs on remote macOS machines

## 13. References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [nektos/act - Run GitHub Actions locally](https://github.com/nektos/act)
- [Tuist Documentation](https://docs.tuist.io)
- [SwiftLint Docker Images](https://github.com/realm/SwiftLint/pkgs/container/swiftlint)
- ISOInspector CI workflows: `.github/workflows/`

## 14. Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-27 | 1.0 | Initial PRD draft |
