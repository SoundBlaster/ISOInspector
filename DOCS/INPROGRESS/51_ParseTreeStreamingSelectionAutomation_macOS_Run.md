# ParseTreeStreamingSelectionAutomationTests macOS Run

## 🎯 Objective

Execute the `ParseTreeStreamingSelectionAutomationTests` suite on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI streaming selection flow and capture evidence that automation remains stable outside the Linux container environment.

## 🧩 Context

- The execution workplan calls for macOS SwiftUI automation coverage following the streaming UI integrations delivered in Phase E2. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L35-L44】
- The detailed PRD backlog tracks Task H5 as the macOS automation scenario ensuring the outline/detail panes stay synchronized during streaming parses. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L236-L259】
- Master PRD goals emphasize low-latency streaming event propagation into the UI, which this automation validates on real macOS infrastructure. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L14-L22】

## ✅ Success Criteria

- `ParseTreeStreamingSelectionAutomationTests` executes on macOS hardware with UI automation enabled and reports success.
- Resulting logs/screenshots are archived for future regression comparison and attached to the task record.
- Any macOS-specific issues discovered are filed with actionable follow-up items or patches.
- Documentation (`next_tasks.md`, backlog, and automation notes) updated to reflect completion status.

## 🔧 Implementation Notes

- Use a macOS runner (physical or CI-hosted) with XCTest UI entitlement; the test is skipped on Linux because Combine and SwiftUI automation are unavailable.
- Preferred invocation: `xcodebuild test -scheme ISOInspectorApp -destination "platform=macOS" -only-testing:ParseTreeStreamingSelectionAutomationTests` from the repository root.
- Ensure SwiftUI accessibility permissions are granted to the test runner; pre-authorize in System Settings → Privacy & Security → Accessibility.
- Capture and store the `DerivedData` `xcresult` bundle for evidence; upload alongside a short execution summary in `DOCS/TASK_ARCHIVE` when complete.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection`](../TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/)
