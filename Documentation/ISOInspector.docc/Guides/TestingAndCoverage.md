# Testing and Code Coverage

ISOInspector measures executed-line coverage separately for its Swift package
modules and FoundationUI. Coverage is evidence about executed code, not proof
that every behavior is tested.

## Running tests

Run the root package with `swift test` and FoundationUI with
`swift test --package-path FoundationUI`. Add `--enable-code-coverage` when
collecting SwiftPM coverage. Use checkout-specific external scratch and cache
paths when required by your local development environment.

## CI coverage

- `isoinspector-coverage.yml` runs the root package tests and enforces the
  thresholds declared in that workflow for Kit, App, and CLI. Its
  `isoinspector-coverage` artifact contains the measured results.
- `foundationui-coverage.yml` runs Xcode tests and enforces separate macOS and
  iOS thresholds. The workflow files are the source of truth for current
  thresholds.
- `PR Quality Gate` checks that the workflows applicable to the changed files
  have succeeded. A workflow skipped because it is not applicable is not a
  coverage measurement.

Change thresholds in the corresponding workflow only after measuring a
representative run and reviewing the change.

## Local pre-push checks

The pre-push hook runs the root package build and tests and, on macOS, the
FoundationUI tests. Configure separate scratch paths for the root and
FoundationUI packages as described in the README.

The hook also generates an informational FoundationUI test/source LOC ratio
using `coverage_analysis.py`. This report counts lines of source and test code;
**it does not measure executed-line or branch coverage** and does not gate
pushes. A larger ratio does not establish that a behavior is tested.

```sh
python3 coverage_analysis.py --report Documentation/Quality/loc-ratio.txt -v
```

## Interpreting failures

When a test or coverage check fails, inspect the individual workflow job and
its artifacts. A failing test, a failed instrumentation step, and a measured
coverage threshold failure have different causes. For CI failures involving
macOS or iOS, reproduce with the relevant Xcode scheme and platform; Linux
coverage excludes platform-specific code.
