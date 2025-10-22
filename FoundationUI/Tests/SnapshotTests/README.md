# FoundationUI Snapshot Tests

## Overview

This directory contains visual regression snapshot tests for all FoundationUI components. Snapshot testing ensures that UI components render consistently across changes and prevents unintended visual regressions.

## Framework

We use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) by Point-Free for snapshot testing.

**Version**: 1.15.0+

## Test Coverage

### Components Tested

1. **Badge** (`BadgeSnapshotTests.swift`) - 25+ snapshots
   - All BadgeLevel variants (info, warning, error, success)
   - Light/Dark mode
   - Dynamic Type sizes
   - With/without icons
   - RTL support

2. **Card** (`CardSnapshotTests.swift`) - 35+ snapshots
   - All elevation levels (none, low, medium, high)
   - All corner radius options
   - Material backgrounds (thin, regular, thick, ultraThin, ultraThick)
   - Light/Dark mode
   - Dynamic Type sizes
   - Nested cards
   - RTL support

3. **SectionHeader** (`SectionHeaderSnapshotTests.swift`) - 23+ snapshots
   - With/without divider
   - Light/Dark mode
   - Dynamic Type sizes
   - Various title lengths
   - RTL support

4. **KeyValueRow** (`KeyValueRowSnapshotTests.swift`) - 37+ snapshots
   - Horizontal/vertical layouts
   - Light/Dark mode
   - Dynamic Type sizes
   - Copyable text variants
   - Long text handling
   - RTL support

**Total: 120+ snapshot tests**

## Running Snapshot Tests

### Prerequisites

- Xcode 15.0+ or Swift 5.9+ toolchain
- macOS 14.0+ or iOS 17.0+ simulator

### First Time Setup: Recording Baselines

When running snapshot tests for the first time or after intentional visual changes:

1. **Enable recording mode** in the test file:
   ```swift
   assertSnapshot(
       of: view,
       as: .image(layout: .sizeThatFits),
       record: true  // Set to true to record
   )
   ```

2. **Run the test suite**:
   ```bash
   cd FoundationUI
   swift test
   ```
   or in Xcode: `Cmd+U`

3. **Verify generated snapshots**:
   - Snapshots are saved to `__Snapshots__/{TestFileName}/`
   - Open snapshot images to verify they look correct
   - Check for proper rendering, spacing, colors, etc.

4. **Commit snapshots to repository**:
   ```bash
   git add Tests/SnapshotTests/__Snapshots__
   git commit -m "Add baseline snapshots for components"
   ```

5. **Disable recording mode**:
   - Set `record: false` in all test files
   - Commit this change

### Normal Test Runs: Comparison Mode

With `record: false`, snapshot tests compare rendered views against saved baselines:

```bash
cd FoundationUI
swift test
```

**Expected behavior**:
- ✅ Tests pass if rendered output matches baseline
- ❌ Tests fail if there are visual differences
- Diff images are saved to `__Snapshots__/{TestFileName}/` when failures occur

## Updating Snapshots

When you intentionally change component appearance:

1. **Review the visual change** to confirm it's expected
2. **Temporarily enable recording**:
   - Set `record: true` in affected test(s)
   - Or globally update all tests if many components changed
3. **Run tests** to update baselines
4. **Review diff** before committing:
   ```bash
   git diff Tests/SnapshotTests/__Snapshots__
   ```
5. **Commit updated snapshots**:
   ```bash
   git add Tests/SnapshotTests/__Snapshots__
   git commit -m "Update snapshots for {component} visual changes"
   ```
6. **Disable recording** (`record: false`)

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Run snapshot tests
  run: |
    cd FoundationUI
    swift test --filter SnapshotTests

- name: Upload snapshot failures
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: snapshot-failures
    path: FoundationUI/Tests/SnapshotTests/__Snapshots__/**/*-failed.png
```

### CI Best Practices

- **Fail builds on snapshot mismatches** to catch regressions
- **Upload failure diffs** as artifacts for review
- **Require snapshot updates** in separate commits for audit trail
- **Use consistent test environment** (same OS/Xcode version) to avoid false positives

## Snapshot Directory Structure

```
Tests/SnapshotTests/
├── README.md                          # This file
├── BadgeSnapshotTests.swift           # 25+ Badge tests
├── CardSnapshotTests.swift            # 35+ Card tests
├── SectionHeaderSnapshotTests.swift   # 23+ SectionHeader tests
├── KeyValueRowSnapshotTests.swift     # 37+ KeyValueRow tests
└── __Snapshots__/                     # Generated snapshot images
    ├── BadgeSnapshotTests/
    │   ├── testBadgeInfoLightMode.1.png
    │   ├── testBadgeInfoDarkMode.1.png
    │   └── ...
    ├── CardSnapshotTests/
    │   ├── testCardElevationLow.1.png
    │   └── ...
    ├── SectionHeaderSnapshotTests/
    │   └── ...
    └── KeyValueRowSnapshotTests/
        └── ...
```

## Troubleshooting

### Tests fail with "No such file or directory"

**Problem**: Baseline snapshots not yet recorded.

**Solution**: Enable `record: true` and run tests to create baselines.

### Tests fail with visual differences

**Problem**: Component rendering changed.

**Solutions**:
1. If change is **unintentional**: Fix the code to match baseline
2. If change is **intentional**: Update snapshots (see "Updating Snapshots")

### Different results on different machines

**Problem**: Platform/OS differences.

**Solution**:
- Use consistent test environment (same macOS/iOS version)
- Consider platform-specific snapshot baselines if needed
- Run CI tests in controlled environment

### Snapshots too large in repository

**Problem**: Many high-resolution snapshots increase repo size.

**Solutions**:
- Use `.image(precision: 0.95)` for slightly lossy compression
- Consider Git LFS for snapshot storage
- Use smaller frame sizes where appropriate

## Best Practices

### Writing Snapshot Tests

✅ **DO**:
- Test all visual variants (light/dark, accessibility sizes)
- Use descriptive test names (`testBadgeInfoLightMode`)
- Frame views to minimize snapshot size
- Test RTL layouts for internationalization
- Group related snapshots in single test class

❌ **DON'T**:
- Snapshot entire app screens (too brittle)
- Use random/dynamic data (causes flaky tests)
- Forget to commit `__Snapshots__/` directory
- Leave `record: true` in committed code

### Snapshot Test Hygiene

- **Review diffs carefully** before updating baselines
- **Keep snapshots focused** on component behavior
- **Run snapshot tests locally** before pushing
- **Update snapshots in separate commits** from code changes
- **Document visual changes** in PR descriptions

## Additional Resources

- [swift-snapshot-testing Documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [FoundationUI Test Plan](../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
- [FoundationUI Task Plan](../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)

---

**Last Updated**: 2025-10-22
**Test Count**: 120+ snapshot tests
**Framework Version**: swift-snapshot-testing 1.15.0+
