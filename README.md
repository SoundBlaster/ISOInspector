# ISOInspector

Monorepo for the ISOInspector suite: a Swift-based ISO Base Media File Format (MP4/QuickTime) parser, CLI, and multiplatform SwiftUI application. The repository follows the execution guidance documented in `DOCS/AI` and the XP-inspired TDD workflow defined in `DOCS/RULES/02_TDD_XP_Workflow.md`.

## Feature Matrix

| Surface | Highlights | Automation hooks |
| --- | --- | --- |
| **ISOInspectorKit** | Streaming `ParsePipeline.live()` surfaces MP4 boxes with metadata, validation, and research logging for callers in any platform target.【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L60-L76】【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L90-L132】 | Exporters emit JSON trees, plaintext issue summaries, and binary captures while `ResearchLogWriter` records VR-006 diagnostics for downstream tooling.【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L60-L76】【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L1-L52】【F:Sources/ISOInspectorKit/Export/PlaintextIssueSummaryExporter.swift†L1-L191】【F:Sources/ISOInspectorKit/Validation/ResearchLogWriter.swift†L19-L60】 |
| **ISOInspectorApp** | SwiftUI workspace combines streaming tree, detail inspector, notes, and hex panes with bookmark syncing across launches. UI built with **FoundationUI design system** for consistent, accessible, cross-platform components.【F:Documentation/ISOInspector.docc/Manuals/App.md†L1-L114】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L137-L396】 | Restores sessions, bookmarks, and notes through Core Data while resolving security-scoped bookmarks for sandboxed distribution builds. Integration patterns documented in Technical Spec with 123 comprehensive tests.【F:Documentation/ISOInspector.docc/Manuals/App.md†L69-L110】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L389-L1074】【F:Tests/ISOInspectorAppTests/FoundationUI/】 |
| **`isoinspect` CLI** | Shared parsers stream validation summaries and box events with commands for inspect, validate, export, and batch workflows.【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L83】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L96-L165】 | Global flags toggle verbose output, telemetry, and sandbox-friendly bookmark automation so jobs can run unattended with captured research logs and MP4RA refresh tooling.【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L11-L63】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L66-L141】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L182-L229】 |

## Supported Platforms & Box Families

- **Platforms:** macOS 14 and iOS/iPadOS 16 or newer targets are available through SwiftPM products for the app and kit.【F:Documentation/ISOInspector.docc/Manuals/App.md†L7-L18】【F:Package.swift†L6-L44】
- **File types:** MP4 (`.mp4`) and QuickTime (`.mov`) containers stream through the document picker and CLI readers.【F:Documentation/ISOInspector.docc/Manuals/App.md†L9-L34】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L52】
- **Container boxes:** `FourCharContainerCode` centralises movie, track, metadata, and streaming container identifiers for traversal utilities.【F:Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift†L1-L46】
- **Media/index boxes:** `MediaAndIndexBoxCode` captures frequently referenced payload and streaming indicator boxes for validation heuristics.【F:Sources/ISOInspectorKit/ISO/MediaAndIndexBoxCode.swift†L1-L43】

## Interface Preview

![ISOInspector app workspace showing tree, detail, and hex panes](Documentation/Assets/isoinspector-app-overview.svg)

The overview illustrates the tri-pane layout documented in the app manual so readers can map README highlights to the live SwiftUI workflow.【F:Documentation/ISOInspector.docc/Manuals/App.md†L33-L114】

## Package Layout
- `Sources/ISOInspectorKit` — Core parsing and validation library (currently scaffolded).
- `Sources/ISOInspectorCLI` — Command-line interface with a custom bootstrap runner.
- `Sources/ISOInspectorApp` — SwiftUI application shell for macOS/iPadOS/iOS.
- `Examples/ComponentTestApp` — Interactive FoundationUI component showcase and testing app.
- `Tests/*` — XCTest suites for the library, CLI surface, and app composition.
- `Tests/ISOInspectorAppTests/FoundationUI/` — Integration test suite for FoundationUI components (123 tests).
- `Docs` — Living documentation (architecture notes, guides, manuals).
- `Sources/*/*.docc` — DocC catalogs for the kit, CLI, and SwiftUI app.

## Getting Started
1. Install Swift 6.0 or newer (Swift 6.2+ recommended).
2. Build all targets:
   ```sh
   swift build
   ```
3. Run the test suite:
   ```sh
   swift test
   ```

## Git Hooks

Enable the repository-managed hooks to automatically format Markdown documentation and validate YAML files before each commit:

```sh
git config core.hooksPath .githooks
```

The pre-commit hook requires Docker (recommended), or a local `swiftlint` binary, plus `npx`, `python3`, and [`PyYAML`](https://pyyaml.org/). It runs:

```sh
scripts/swiftlint-format.sh   # falls back to local `swiftlint --fix` if Docker is missing
npx markdownlint-cli2 --fix 'DOCS/INPROGRESS/**/*.md' 'DOCS/COMMANDS/**/*.md' 'DOCS/RULES/**/*.md'
scripts/check_yaml.py         # requires PyYAML (`python3 -m pip install pyyaml`)
```

Re-run the command if your local configuration resets `core.hooksPath`.

Validate YAML files ad-hoc with:

```sh
scripts/check_yaml.py path/to/workflow.yml another/config.yaml
```

## Code Formatting

The repository enforces consistent Swift code style using **swift-format** (Apple's official Swift formatter). All Swift files are automatically formatted before commits via pre-commit hooks, and formatting compliance is validated in CI.

### Local Formatting

Format all Swift files before committing:

```sh
swift format --in-place --recursive Sources Tests
```

Check formatting without modifying files (mirrors CI check):

```sh
swift format lint --recursive Sources Tests
```

### Pre-commit Hook

The `.pre-commit-config.yaml` includes a `swift-format-all` hook that automatically formats staged Swift files before each commit. Install pre-commit hooks:

```sh
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type pre-push
```

Run all hooks manually:

```sh
pre-commit run --all-files
```

### Configuration

Swift formatting is configured via `.swift-format.json` at the repository root. The configuration sets `respectsExistingLineBreaks: false` to ensure consistent brace positioning across the codebase.

### CI Enforcement

The GitHub Actions workflow includes a `swift-format-check` job that runs `swift format lint` on all Swift files. If unformatted code is detected, the workflow fails with instructions to run the formatter locally.

### SwiftLint Compatibility

The repository uses both **SwiftFormat** (for automatic code formatting) and **SwiftLint** (for linting and style enforcement). To avoid conflicts, the following SwiftLint rules are disabled in `.swiftlint.yml`:

- `opening_brace` — SwiftFormat handles brace positioning
- `closure_parameter_position` — SwiftFormat controls closure parameter layout
- `trailing_comma` — SwiftFormat manages trailing commas in multiline collections

This configuration allows both tools to work together harmoniously without creating conflicting formatting requirements.

## Code Quality Gates

The repository enforces complexity thresholds using **SwiftLint** to prevent code quality regressions:

- **Cyclomatic Complexity:** Warning at 30, error at 55
- **Function Body Length:** Warning at 250 lines, error at 350 lines
- **Type Body Length:** Warning at 1200 lines, error at 1500 lines
- **Nesting Depth:** Warning at 5 type levels, error at 7 levels

These thresholds are tuned to allow 95%+ of existing code to pass while blocking future complexity growth. Pre-push hooks and CI workflows run `swiftlint lint --strict` to enforce these limits.

### Running SwiftLint Locally

Check for complexity violations:

```sh
swiftlint lint --strict
```

Install SwiftLint (macOS):

```sh
brew install swiftlint
```

### Exceeding Thresholds

If you need to exceed complexity thresholds for legitimate reasons:

1. Extract helper functions or break large types into smaller units
2. If refactoring is not feasible, document the exception with a `swiftlint:disable:next` comment:

```swift
// Rationale: Complex parser handling all ISO box flags per specification.
// TODO: Consider extracting flag interpretation into helper methods.
// swiftlint:disable:next cyclomatic_complexity
func parseComplexBox(...) {
  // ...
}
```

See existing disable pragmas in the codebase for examples of documented exceptions.

## Test Coverage Gating

The repository enforces a **minimum test coverage threshold of 67%** using a Python-based analysis tool that compares test code lines to source code lines. Coverage is validated at two points:

### Pre-Push Hook

Before you push code, the git pre-push hook automatically checks coverage if FoundationUI sources or tests have changed:

```sh
python3 coverage_analysis.py --threshold 0.67
```

If coverage drops below the threshold, the push is blocked:

```
❌ Test coverage below threshold
Run: python3 coverage_analysis.py --verbose
For more details on how to improve test coverage, see:
Documentation/ISOInspector.docc/Guides/TestingAndCoverage.md
```

To fix and retry:

```sh
# Review coverage breakdown
python3 coverage_analysis.py --verbose

# Add tests for new/modified code
# Then commit and push again
git add .
git commit -m "Add tests to meet coverage threshold"
git push
```

### GitHub Actions Workflow

The `coverage-gate.yml` workflow runs on pull requests and pushes to `main`, automatically:

1. Running unit tests with code coverage enabled
2. Executing the coverage analysis script
3. Uploading coverage reports as artifacts
4. Commenting on PRs with coverage results
5. Failing the workflow if threshold is not met

### Analyzing Coverage

Run the coverage analysis tool locally to understand your coverage:

```sh
# Basic report
python3 coverage_analysis.py

# Check if coverage meets threshold (exits with 0 if OK, 1 if below)
python3 coverage_analysis.py --threshold 0.67

# Save report to file
python3 coverage_analysis.py --report coverage-report.txt

# Verbose mode with repository detection details
python3 coverage_analysis.py -v
```

The report shows:

- **Per-layer analysis** — Coverage breakdown for each FoundationUI layer (DesignTokens, Modifiers, Components, etc.)
- **Overall ratio** — Total test/code ratio across all layers
- **Construct count** — Number of functions, structs, classes, enums, etc. per layer

### Updating the Threshold

If project requirements change, update the threshold in three places:

1. **Pre-push hook** — `.githooks/pre-push`:
   ```bash
   COVERAGE_THRESHOLD=${ISOINSPECTOR_MIN_TEST_COVERAGE:-0.67}  # Change 0.67
   ```

2. **GitHub Actions** — `.github/workflows/coverage-gate.yml`:
   ```yaml
   python3 coverage_analysis.py --threshold 0.67  # Change 0.67
   ```

3. **Environment variable** (optional):
   ```sh
   export ISOINSPECTOR_MIN_TEST_COVERAGE=0.75
   git push
   ```

For comprehensive guidance on testing and coverage, see [Testing and Code Coverage Guide](Documentation/ISOInspector.docc/Guides/TestingAndCoverage.md).

## Documentation

Browse the online documentation at: https://soundblaster.github.io/ISOInspector/documentation/isoinspectorkit/

Generate browsable DocC archives for every target with:

```sh
scripts/generate_documentation.sh
```

The script produces static-hostable archives under `Documentation/DocC/<Target>` and can be
shared via GitHub Pages or other artifact storage.

## Continuous Integration

The repository ships with two GitHub Actions workflows that cover the primary
targets:

- **Swift (Linux)** runs SwiftLint, builds all products, executes the test
  suite with coverage enabled, and prints a summary report.
- **macOS Build** selects the latest stable Xcode toolchain, archives the
  unsigned `ISOInspectorApp`, and publishes a release `isoinspect` CLI binary.

Reproduce the automated checks locally with:

```sh
# Apply SwiftLint fixes via the same container image used in CI
scripts/swiftlint-format.sh

# Verify lint (requires Docker; mirrors the CI verify step)
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" -w /work ghcr.io/realm/swiftlint:0.53.0 \
  swiftlint lint --strict --no-cache --config .swiftlint.yml

# Build and test with coverage
swift test --enable-code-coverage
```

## Container Code Enumeration

ISOInspectorKit now exposes a `FourCharContainerCode` enum that centralises the set of four-character container box identifiers
(`moov`, `trak`, `mdia`, and others). Use the enum when checking for child-bearing boxes instead of hard-coded string literals; it
provides helpers such as `isContainer(_:)` for `FourCharCode`, `String`, and `BoxHeader` values and powers traversal logic in
`StreamingBoxWalker`. Adding new containers only requires extending the enum in `Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift`.

## Media & Index Box Enumeration

Companion enum `MediaAndIndexBoxCode` tracks frequently referenced structural boxes such as `mdat`, `sidx`, and `styp`. The type
offers the same conversion helpers as the container enum, plus convenience sets for streaming indicators and media payloads.
Ordering rules and streaming heuristics rely on these helpers to avoid scattered string literals; extend
`Sources/ISOInspectorKit/ISO/MediaAndIndexBoxCode.swift` when additional structural boxes gain first-class support.

## Fixture Catalog & Deterministic Samples

Regression coverage now includes a deterministic fixture catalog stored in
`Tests/ISOInspectorKitTests/Fixtures`. Synthetic streaming, malformed, and
large-payload MP4 assets are generated locally via
`Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py` and committed as
base64-encoded `.txt` files to keep provenance auditable while avoiding binary
artifacts in git history. Tests in
`Tests/ISOInspectorKitTests/FixtureCatalogExpandedCoverageTests.swift` validate
expected box layouts and documented warnings so future fixture refreshes stay in
sync with the catalog metadata.

## MP4RA Catalog Maintenance
The repository maintains a pinned snapshot of the MP4 Registration Authority box catalog in `Sources/ISOInspectorKit/Resources/MP4RABoxes.json`.
To update the snapshot and keep CI green:

1. Download the latest catalog JSON from the MP4RA source and overwrite `Sources/ISOInspectorKit/Resources/MP4RABoxes.json`.
2. Run the minimal validator locally before committing:
   ```sh
   python scripts/validate_mp4ra_minimal.py Sources/ISOInspectorKit/Resources/MP4RABoxes.json
   ```
   The script also defaults to this path when invoked without arguments.
   A `Validation OK` message indicates the file matches the required structure and formatting (two-space indentation, LF
   newlines, valid identifiers, etc.).
3. Commit the refreshed snapshot together with any fixes required by the validator. The GitHub Actions workflow
   (`validate-mp4ra-minimal.yml`) executes the same script on pull requests and pushes to `main` to enforce consistency.

## FoundationUI Integration

ISOInspectorApp integrates the **FoundationUI design system** for consistent, accessible, cross-platform UI components. The integration follows a structured 6-phase gradual migration plan with comprehensive testing at each stage.

### Quick Links

- **Integration Architecture:** [`DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md`](DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md#foundationui-integration-architecture) — Design patterns, code examples, Do's and Don'ts
- **Design System Guide:** [`DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`](DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md) — Core principles and semantic composition rules
- **Component Showcase:** [`Examples/ComponentTestApp/`](Examples/ComponentTestApp/) — Interactive demo app for all FoundationUI components
- **Integration Tests:** [`Tests/ISOInspectorAppTests/FoundationUI/`](Tests/ISOInspectorAppTests/FoundationUI/) — 123 comprehensive tests across Badge, Card, KeyValueRow components
- **Integration Strategy:** [`DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`](DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — Detailed 9-week phased integration roadmap

### Key Features

- **Design Tokens:** Zero magic numbers — all spacing, colors, typography, and animations use `DS.*` tokens
- **Component Wrappers:** Domain-specific wrappers (e.g., `BoxStatusBadge`) map ISO semantics to FoundationUI
- **Accessibility:** WCAG 2.1 AA compliance with VoiceOver, Dynamic Type, and high contrast support
- **Testing:** 80%+ code coverage with unit tests, snapshot tests, and accessibility tests
- **Platform Adaptation:** Automatic macOS/iOS/iPadOS layout adjustments via environment contexts

### Running ComponentTestApp

Explore live FoundationUI components interactively:

```sh
cd Examples/ComponentTestApp
tuist generate
open ComponentTestApp.xcworkspace
# Select ComponentTestApp-iOS or ComponentTestApp-macOS scheme and run
```

See [`Examples/ComponentTestApp/README.md`](Examples/ComponentTestApp/README.md) for detailed usage.

---

## Next Steps
Consult `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` for feature-level deliverables and `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` for task sequencing. Begin by enhancing the IO foundations described in Phase A.
