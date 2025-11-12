# Tolerant Parsing Guide

Learn how to parse corrupted or damaged ISO Base Media files using ISOInspectorKit's tolerant parsing mode.

## Overview

ISOInspectorKit's tolerant parsing mode enables your application to analyze damaged, truncated, or malformed ISO Base Media (MP4/QuickTime) files without aborting on structural errors. This mode is designed for quality control workflows, forensic analysis, and diagnostic tools that need to extract as much information as possible from corrupted media.

In strict mode (the default), the parser aborts immediately when it encounters structural errors like invalid box sizes or corrupted headers. Tolerant mode continues parsing, records all issues, and attempts to recover gracefully, providing you with both the successfully parsed content and a detailed log of problems encountered.

## When to Use Tolerant Parsing

Tolerant parsing is ideal for:

- **Quality Control Workflows**: Analyze user-uploaded files that may be damaged or incomplete during transfer
- **Forensic Analysis**: Extract maximum information from corrupted evidence files
- **Streaming Server Diagnostics**: Diagnose fragmented MP4 files with missing or damaged fragments
- **File Recovery Tools**: Attempt to salvage content from partially corrupted media
- **Validation Tools**: Generate comprehensive corruption reports for damaged files

**When NOT to use tolerant parsing:**

- Production encoding/decoding pipelines where corruption should fail fast
- CI/CD validation where only valid files should pass
- Security-sensitive contexts where malformed files should be rejected immediately

## Basic Setup

### Creating a Tolerant Pipeline

The simplest way to enable tolerant parsing is to use the `.tolerant` preset:

```swift
import ISOInspectorKit

let pipeline = ParsePipeline.live(options: .tolerant)
```

This configures the parser with sensible defaults for corruption tolerance:
- Structural errors don't abort parsing
- Up to 500 corruption events are recorded
- Payload validation focuses on structure rather than exhaustive semantic checks

### Parsing a File

To parse a file with tolerant mode:

```swift
import ISOInspectorKit

// Create a memory-mapped reader for efficient access
let reader = try MappedReader(url: fileURL)

// Create a parse context
var context = ParsePipeline.Context(source: fileURL)

// Create an issue store to collect corruption reports
let issueStore = ParseIssueStore()
context.issueStore = issueStore

// Create the pipeline with tolerant options
let pipeline = ParsePipeline.live(options: .tolerant)

// Parse the file
for try await event in pipeline.events(for: reader, context: context) {
    switch event.kind {
    case .willStartBox(let header, let depth):
        print("Starting box: \(header.identifierString) at depth \(depth)")

    case .didFinishBox(let header, let depth):
        print("Finished box: \(header.identifierString)")

        // Check for issues encountered in this box
        if !event.issues.isEmpty {
            print("  Issues: \(event.issues.count)")
        }
    }
}

// After parsing, examine the collected issues
let metrics = issueStore.metricsSnapshot()
print("Total errors: \(metrics.errorCount)")
print("Total warnings: \(metrics.warningCount)")
```

## Accessing Corruption Issues

### Understanding ParseIssue

Each ``ParseIssue`` represents a problem encountered during parsing:

- `severity`: `.error`, `.warning`, or `.info`
- `code`: A unique identifier for the issue type (e.g., "SR-001", "VR-003")
- `message`: Human-readable description
- `byteRange`: Location in the file where the issue occurred
- `affectedNodeIDs`: Box offsets affected by this issue

### Querying ParseIssueStore

The ``ParseIssueStore`` collects all issues during parsing and provides various query methods:

```swift
let issueStore = ParseIssueStore()
context.issueStore = issueStore

// Parse file...

// Get metrics snapshot
let metrics = issueStore.metricsSnapshot()
print("Errors: \(metrics.errorCount)")
print("Warnings: \(metrics.warningCount)")
print("Info: \(metrics.infoCount)")
print("Deepest corruption depth: \(metrics.deepestAffectedDepth)")

// Get total issue count
let summary = issueStore.makeIssueSummary()
print("Total issues: \(summary.totalCount)")
```

### Filtering Issues by Severity

Retrieve all issues and filter by severity:

```swift
let allIssues = issueStore.issuesSnapshot()

// Filter by severity
let errors = allIssues.filter { $0.severity == .error }
let warnings = allIssues.filter { $0.severity == .warning }

// Print error details
for issue in errors {
    if let range = issue.byteRange {
        print("\(issue.code): \(issue.message) at offset \(range.lowerBound)")
    } else {
        print("\(issue.code): \(issue.message)")
    }
}
```

### Querying Issues by Location

Find issues affecting a specific byte range:

```swift
// Find all issues in a specific range
let startOffset: Int64 = 1000
let endOffset: Int64 = 2000
let issuesInRange = issueStore.issues(in: startOffset..<endOffset)

print("Found \(issuesInRange.count) issues in range \(startOffset)-\(endOffset)")
```

## Advanced Configuration

### Custom Options

You can customize tolerant parsing behavior by modifying the preset:

```swift
var customOptions = ParsePipeline.Options.tolerant

// Allow more corruption events before stopping
customOptions.maxCorruptionEvents = 1000

// Increase maximum traversal depth for deeply nested structures
customOptions.maxTraversalDepth = 128

// Create pipeline with custom options
let pipeline = ParsePipeline.live(options: customOptions)
```

### Understanding Option Parameters

``ParsePipeline/Options`` provides fine-grained control:

- **`abortOnStructuralError`**: When `true`, parsing stops immediately on structural errors (default: `false` for `.tolerant`)
- **`maxCorruptionEvents`**: Maximum number of corruption issues to record before stopping (default: `500` for `.tolerant`)
- **`payloadValidationLevel`**:
  - `.full`: Performs exhaustive semantic validation
  - `.structureOnly`: Validates only structural integrity (default for `.tolerant`)
- **`maxTraversalDepth`**: Maximum box nesting depth (default: `64`)
- **`maxStalledIterationsPerFrame`**: Maximum stalled iterations before aborting (default: `3`)
- **`maxZeroLengthBoxesPerParent`**: Maximum zero-length boxes per parent (default: `2`)
- **`maxIssuesPerFrame`**: Maximum issues to record per iteration (default: `256`)

### Comparing Strict vs. Tolerant Behavior

```swift
let fileURL = URL(fileURLWithPath: "corrupted.mp4")
let reader = try MappedReader(url: fileURL)

// Try strict mode first
let strictPipeline = ParsePipeline.live(options: .strict)
var strictContext = ParsePipeline.Context(source: fileURL)

do {
    var boxCount = 0
    for try await event in strictPipeline.events(for: reader, context: strictContext) {
        if case .willStartBox = event.kind {
            boxCount += 1
        }
    }
    print("Strict mode: Successfully parsed \(boxCount) boxes")
} catch {
    print("Strict mode failed: \(error)")
}

// Now try tolerant mode
let tolerantPipeline = ParsePipeline.live(options: .tolerant)
var tolerantContext = ParsePipeline.Context(source: fileURL)
let issueStore = ParseIssueStore()
tolerantContext.issueStore = issueStore

var tolerantBoxCount = 0
for try await event in tolerantPipeline.events(for: reader, context: tolerantContext) {
    if case .willStartBox = event.kind {
        tolerantBoxCount += 1
    }
}

let metrics = issueStore.metricsSnapshot()
print("Tolerant mode: Parsed \(tolerantBoxCount) boxes")
print("  Errors: \(metrics.errorCount)")
print("  Warnings: \(metrics.warningCount)")
```

## Best Practices

### Choose the Right Mode for Your Use Case

- **Use `.strict` for:** Production pipelines, CI/CD validation, security-sensitive contexts
- **Use `.tolerant` for:** User-uploaded files, diagnostics, forensic analysis, QC workflows

### Monitor maxCorruptionEvents

If you're consistently hitting the `maxCorruptionEvents` limit, consider:
- Increasing the limit for severely damaged files
- Implementing progress callbacks to abort early if too many issues are found
- Using `.strict` mode if the file is too corrupted to be useful

### Handle Incomplete Data Gracefully

In tolerant mode, some boxes may have incomplete or missing payload data:

```swift
for try await event in pipeline.events(for: reader, context: context) {
    guard case .didFinishBox = event.kind else { continue }

    if let payload = event.payload {
        // Successfully parsed payload
        processPayload(payload)
    } else {
        // Payload parsing failed or was skipped
        print("Warning: No payload for box \(event.metadata?.name ?? "unknown")")
    }

    // Check for validation issues
    if !event.validationIssues.isEmpty {
        print("Validation issues: \(event.validationIssues.count)")
    }
}
```

### Export Issues for Forensic Records

For forensic or QC workflows, export the issue log alongside your analysis:

```swift
let issues = issueStore.issuesSnapshot()
let metrics = issueStore.metricsSnapshot()

struct CorruptionReport: Codable {
    let fileName: String
    let totalIssues: Int
    let errorCount: Int
    let warningCount: Int
    let issues: [IssueDetail]

    struct IssueDetail: Codable {
        let severity: String
        let code: String
        let message: String
        let offset: Int64?
    }
}

let report = CorruptionReport(
    fileName: fileURL.lastPathComponent,
    totalIssues: issues.count,
    errorCount: metrics.errorCount,
    warningCount: metrics.warningCount,
    issues: issues.map { issue in
        CorruptionReport.IssueDetail(
            severity: "\(issue.severity)",
            code: issue.code,
            message: issue.message,
            offset: issue.byteRange?.lowerBound
        )
    }
)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let jsonData = try encoder.encode(report)
try jsonData.write(to: reportURL)
```

## See Also

- ``ParsePipeline``
- ``ParsePipeline/Options-swift.struct``
- ``ParseIssueStore``
- ``ParseIssue``
- <doc:KitArchitecture>
