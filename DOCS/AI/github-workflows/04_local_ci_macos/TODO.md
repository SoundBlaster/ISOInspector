# TODO: Local CI Execution on macOS

## Phase 1: Core Scripts ✅ (Current Focus)

### 1.1. Infrastructure Setup
- [x] Analyze existing CI workflows
- [x] Create PRD document
- [ ] Create script directory structure (`scripts/local-ci/`)
- [ ] Implement common library functions
  - [ ] `lib/common.sh`: Logging, error handling, tool detection
  - [ ] `lib/ci-env.sh`: Environment validation, Xcode/Swift version checks
  - [ ] `lib/docker-helpers.sh`: Docker availability, container management

### 1.2. Linting & Formatting (`run-lint.sh`)
- [ ] SwiftLint execution (native mode)
  - [ ] Main project linting
  - [ ] FoundationUI linting
  - [ ] ComponentTestApp linting
  - [ ] Report aggregation (match CI format)
- [ ] SwiftLint execution (Docker mode)
  - [ ] Container setup with ghcr.io/realm/swiftlint:0.53.0
  - [ ] Volume mounting
  - [ ] User ID mapping
- [ ] Swift format check
  - [ ] Recursive formatting check (Sources/, Tests/)
  - [ ] Exit on violations
- [ ] JSON validation
  - [ ] Run validate_json.py
  - [ ] MP4RABoxes.json checks

### 1.3. Build Matrix (`run-build.sh`)
- [ ] Swift Package Manager builds
  - [ ] ISOInspectorKit
  - [ ] ISOInspectorCLI
  - [ ] ISOInspectorCLIRunner
  - [ ] Build cache support
- [ ] Tuist workspace generation
  - [ ] Auto-detect Tuist version from CI
  - [ ] Download and cache Tuist binary
  - [ ] Run `tuist generate`
- [ ] Xcode builds
  - [ ] ISOInspectorApp (macOS)
  - [ ] FoundationUI (iOS Simulator)
  - [ ] FoundationUI (macOS)
  - [ ] ComponentTestApp (iOS Simulator)
  - [ ] ComponentTestApp (macOS)
- [ ] Build artifacts management

### 1.4. Test Execution (`run-tests.sh`)
- [ ] Swift Package Manager tests
  - [ ] ISOInspectorKitTests
  - [ ] ISOInspectorCLITests
  - [ ] Parallel test execution
- [ ] Xcode test suites
  - [ ] ISOInspectorAppTests-macOS
  - [ ] FoundationUI tests (iOS)
  - [ ] FoundationUI tests (macOS)
  - [ ] Snapshot tests (with SNAPSHOT_UPDATE support)
- [ ] Test result collection
  - [ ] xcresult parsing
  - [ ] Summary generation
  - [ ] Failed test extraction

### 1.5. Documentation (`README.md`)
- [ ] Quick start guide
- [ ] Prerequisites and installation
  - [ ] Xcode installation
  - [ ] Homebrew setup
  - [ ] Optional: Docker Desktop
- [ ] Usage examples
  - [ ] Run all checks: `./scripts/local-ci/run-all.sh`
  - [ ] Run specific job: `./scripts/local-ci/run-lint.sh`
  - [ ] Configuration options
- [ ] Troubleshooting section

## Phase 2: Advanced Features

### 2.1. Coverage Analysis (`run-coverage.sh`)
- [ ] Enable code coverage for tests
- [ ] Generate coverage reports (llvm-cov)
- [ ] Threshold validation (check_coverage_threshold.py)
- [ ] Coverage report formats
  - [ ] Console output
  - [ ] Cobertura XML (for IDE integration)
  - [ ] HTML report (for browsing)

### 2.2. Script Tests (`run-scripts.sh`)
- [ ] Python environment setup
  - [ ] Detect Python 3.10-3.12
  - [ ] Virtual environment creation
  - [ ] Dependency installation (if any)
- [ ] Test discovery and execution
  - [ ] unittest discover in scripts/tests/
  - [ ] Syntax validation (py_compile)
  - [ ] Style checks (pycodestyle)
- [ ] Docker mode
  - [ ] Use python:3.12-slim image
  - [ ] Mount scripts/ directory
  - [ ] Run tests in container

### 2.3. DocC Generation (`run-docc.sh`)
- [ ] ISOInspector DocC
  - [ ] Generate archives via generate_documentation.sh
  - [ ] Validate no warnings
  - [ ] Package archives
- [ ] FoundationUI DocC
  - [ ] xcodebuild docbuild
  - [ ] Tuist project generation
  - [ ] Archive export

### 2.4. Configuration System
- [ ] Create `.local-ci-config.example`
- [ ] Implement config file loading
- [ ] Support environment variable overrides
- [ ] Validation of config values

### 2.5. Orchestration (`run-all.sh`)
- [ ] Sequential execution of all jobs
- [ ] Parallel execution support (with --parallel flag)
- [ ] Early exit on failure (--fail-fast)
- [ ] Job selection (--jobs lint,build,test)
- [ ] Timing and performance metrics
- [ ] Final summary report

## Phase 3: Integration & Documentation

### 3.1. CI Parity Validation
- [ ] Create test matrix comparing local vs CI results
- [ ] Validate exit codes match
- [ ] Compare output formats
- [ ] Document known differences

### 3.2. Performance Optimization
- [ ] Benchmark full suite execution time
- [ ] Identify bottlenecks
- [ ] Implement caching strategies
  - [ ] Swift build cache
  - [ ] Tuist binary cache
  - [ ] Docker image cache
- [ ] Parallelize independent jobs

### 3.3. Developer Onboarding
- [ ] Update CONTRIBUTING.md with local CI workflow
- [ ] Add to Developer Onboarding Guide (F3)
- [ ] Create video walkthrough (optional)
- [ ] Add to project README

### 3.4. Pre-commit Integration (Optional)
- [ ] Create .pre-commit-config.yaml hooks
- [ ] Lint + format checks on commit
- [ ] Test execution on push
- [ ] Documentation

## Dependencies

### Blocks
- None (greenfield implementation)

### Blocked By
- None

### Related Tasks
- **A2**: Configure CI pipeline (completed) - CI workflows we're mirroring
- **A6**: SwiftFormat enforcement (completed) - swift-format checks
- **A7**: SwiftLint thresholds (in progress) - SwiftLint configuration
- **F3**: Developer Onboarding Guide (completed) - integration target

## Notes

1. **Tool Version Parity**: Scripts should auto-detect versions from CI YAML where possible
   - Xcode: Currently 16.0 (some workflows use 26.0 - typo?)
   - Swift: 6.0
   - SwiftLint: 0.53.0 (Docker image)
   - Tuist: Fetch from GitHub API (latest CLI release)

2. **Platform Support**: Focus on macOS only; Linux scripts would require separate implementation

3. **Docker Strategy**: Prefer native execution for speed; use Docker only where it provides significant value (SwiftLint environment parity, Python version isolation)

4. **Error Handling**: All scripts should:
   - Exit with proper codes (0 = success, 1 = failure)
   - Print clear error messages
   - Support --verbose flag for debugging
   - Support --help flag

5. **CI Workflow Mapping**:
   ```
   ci.yml                → run-lint.sh + run-build.sh + run-tests.sh
   macos.yml             → run-build.sh (Tuist + xcodebuild)
   swift-linux.yml       → run-lint.sh (Docker) + run-coverage.sh
   script-tests.yml      → run-scripts.sh
   swiftlint.yml         → run-lint.sh
   foundationui.yml      → run-build.sh + run-tests.sh + run-docc.sh
   ```

## Completion Criteria

- [ ] All Phase 1 tasks completed
- [ ] Scripts execute on clean macOS installation with only Xcode installed
- [ ] README provides complete setup instructions
- [ ] At least one team member successfully runs local CI
- [ ] CI parity ≥90% for Tier 1 jobs

## Archive Criteria

When ready to archive:
1. Move to `DOCS/TASK_ARCHIVE/XXX_Local_CI_macOS_Setup/`
2. Create Summary_of_Work.md with:
   - Implementation notes
   - Performance metrics
   - Known limitations
   - Usage examples
3. Update references in `04_TODO_Workplan.md`
