# T6.3 — SDK Tolerant Parsing Documentation

## 🎯 Objective

Ensure SDK consumers can opt into tolerant parsing via `ISOInspectorKit.ParseOptions`, complete with comprehensive documentation and code examples demonstrating how to integrate corruption-resilient parsing into their applications.

## 🧩 Context

Task **T6.3** from the Corrupted Media Tolerance workplan (`DOCS/AI/Tolerance_Parsing/TODO.md`) requires that the SDK expose tolerant parsing capabilities with proper documentation for third-party developers.

**Current State:**
- ✅ `ParsePipeline.Options` API is **already public** with `.strict` and `.tolerant` presets
- ✅ Public initializers exist: `ParsePipeline.init(options:)` and `ParsePipeline.live(options:)`
- ✅ Public API is fully functional and tested (T1.3 completed)
- ❌ **No SDK documentation** explaining tolerant parsing usage
- ❌ **No code examples** for SDK consumers
- ❌ **No integration guidance** in ISOInspectorKit.docc

**Dependencies:**
- T1.3 — ParsePipeline Options (✅ Completed — see `DOCS/TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/`)
- T6.1 — CLI Tolerant Flag (✅ Completed — see `DOCS/TASK_ARCHIVE/204_T6_1_CLI_Tolerant_Flag/`)
- T6.2 — CLI Corruption Summary (✅ Completed — see `DOCS/TASK_ARCHIVE/208_T6_2_CLI_Corruption_Summary_Output/`)

## ✅ Success Criteria

1. **SDK Documentation Created:** New DocC article `TolerantParsingGuide.md` added to `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/`
2. **Code Examples Provided:** Documentation includes at least 3 working code examples:
   - Basic tolerant parsing setup
   - Accessing corruption metrics from `ParseIssueStore`
   - Comparing strict vs. tolerant behavior
3. **API Reference Updated:** `ParsePipeline.Options`, `.strict`, and `.tolerant` have inline documentation with usage notes
4. **Integration Guide:** Documentation explains when to use tolerant mode and how to interpret `ParseIssue` results
5. **Cross-References:** Article linked from main `ISOInspectorKit.docc/Documentation.md` Topics section
6. **DocC Build Passes:** `swift package generate-documentation` succeeds and renders the new guide

## 🔧 Implementation Notes

### Files to Create/Modify

1. **New Article:** `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/TolerantParsingGuide.md`
   - Sections: Overview, When to Use, Basic Setup, Accessing Issues, Advanced Configuration, Best Practices
   - Code samples using `ParsePipeline.live(options: .tolerant)`
   - Examples showing `ParseIssueStore` queries by severity

2. **Update Main Catalog:** `Sources/ISOInspectorKit/ISOInspectorKit.docc/Documentation.md`
   - Add new "Tolerant Parsing" topic section
   - Link to `<doc:TolerantParsingGuide>`

3. **Inline Documentation:** `Sources/ISOInspectorKit/ISO/ParsePipeline.swift`
   - Add DocC comments to `ParsePipeline.Options` struct
   - Document `.strict` and `.tolerant` presets
   - Explain `abortOnStructuralError`, `maxCorruptionEvents`, `payloadValidationLevel`

4. **Code Examples:** Create `Tests/ISOInspectorKitTests/Examples/TolerantParsingExamples.swift`
   - Executable test examples that verify documentation code samples
   - Use corrupt fixtures from `Fixtures/Corrupt/` for realism

### Content Structure

**TolerantParsingGuide.md outline:**

```markdown
# Tolerant Parsing Guide

## Overview
Brief explanation of tolerant parsing and its use cases.

## When to Use Tolerant Parsing
- QC workflows for damaged media
- Forensic analysis of corrupted files
- Streaming server diagnostics

## Basic Setup

### Creating a Tolerant Pipeline
```swift
import ISOInspectorKit

let pipeline = ParsePipeline.live(options: .tolerant)
```

### Parsing a File
```swift
let reader = try MappedReader(url: fileURL)
var context = ParsePipeline.Context(source: fileURL)

for try await event in pipeline.events(for: reader, context: context) {
    // Handle events...
}
```

## Accessing Corruption Issues

### Querying ParseIssueStore
```swift
let issueStore = ParseIssueStore()
context.issueStore = issueStore

// After parsing...
let metrics = issueStore.metricsSnapshot()
print("Errors: \(metrics.countsBySeverity[.error] ?? 0)")
```

### Filtering by Severity
```swift
let errors = issueStore.issues(severity: .error)
for issue in errors {
    print("\(issue.code): \(issue.message) at offset \(issue.byteRange.lowerBound)")
}
```

## Advanced Configuration

### Custom Options
```swift
var customOptions = ParsePipeline.Options.tolerant
customOptions.maxCorruptionEvents = 1000
customOptions.maxTraversalDepth = 128

let pipeline = ParsePipeline.live(options: customOptions)
```

## Best Practices
- Use `.tolerant` for user-uploaded files
- Use `.strict` for CI/validation pipelines
- Monitor `maxCorruptionEvents` to prevent performance degradation
- Export issues via JSON for forensic records
```

### Testing Strategy

- Create `Tests/ISOInspectorKitTests/Documentation/TolerantParsingDocTests.swift`
- Verify all code examples compile and execute
- Use `Fixtures/Corrupt/truncated-moov.mp4` for realistic demonstrations
- Assert issue counts match expected values

### Cross-References

Link to related documentation:
- `DOCS/AI/Tolerance_Parsing/TODO.md` (feature workplan)
- `DOCS/TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/` (API implementation)
- `DOCS/TASK_ARCHIVE/204_T6_1_CLI_Tolerant_Flag/` (CLI usage)
- `Documentation/ISOInspector.docc/Manuals/CLI.md` (CLI examples for comparison)

## 🧠 Source References

- **Workplan:** [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- **Execution Guide:** [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- **T1.3 Implementation:** [`DOCS/TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/`](../TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/)
- **T6.1 CLI Flag:** [`DOCS/TASK_ARCHIVE/204_T6_1_CLI_Tolerant_Flag/`](../TASK_ARCHIVE/204_T6_1_CLI_Tolerant_Flag/)
- **T6.2 CLI Output:** [`DOCS/TASK_ARCHIVE/208_T6_2_CLI_Corruption_Summary_Output/`](../TASK_ARCHIVE/208_T6_2_CLI_Corruption_Summary_Output/)
- **Feature PRD:** [`DOCS/AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md`](../AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md)

## 📋 Verification Checklist

- [ ] `TolerantParsingGuide.md` created with all sections
- [ ] Main `Documentation.md` updated with link to new guide
- [ ] Inline DocC comments added to `ParsePipeline.Options`
- [ ] Code examples in guide are copy-paste ready
- [ ] Test file `TolerantParsingDocTests.swift` verifies examples
- [ ] `swift package generate-documentation` builds successfully
- [ ] Documentation previews render correctly in Xcode
- [ ] Cross-references to CLI/App guides added
- [ ] Archive task PRD and summary in `DOCS/TASK_ARCHIVE/211_T6_3_SDK_Tolerant_Parsing_Documentation/`

## 🎯 Definition of Done

- All verification checklist items completed
- Documentation builds without warnings
- Code examples tested and verified
- T6.3 marked complete in `DOCS/AI/Tolerance_Parsing/TODO.md`
- Summary committed to task archive
