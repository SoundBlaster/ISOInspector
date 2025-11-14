failed - Snapshot "macOS" does not match reference.

@−
"file:///Users/runner/work/ISOInspector/ISOInspector/FoundationUI/Tests/FoundationUITests/SnapshotTests/__Snapshots__/IndicatorSnapshotTests/testIndicatorCatalogDarkMode.macOS.png"
@+
"file:///var/folders/6c/pzd640_546q6_yfn24r65c_40000gn/T/IndicatorSnapshotTests/testIndicatorCatalogDarkMode.macOS.png"

To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

    withSnapshotTesting(diffTool: .ksdiff) {
      // ...
    }

Newly-taken snapshot does not match reference.