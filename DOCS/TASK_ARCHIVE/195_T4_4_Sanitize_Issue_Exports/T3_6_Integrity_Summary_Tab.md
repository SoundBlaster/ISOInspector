# T3.6 — Integrity Summary Tab (2025-10-27 Refresh)

> Historical discovery notes were archived in `DOCS/TASK_ARCHIVE/194_T4_2_Plaintext_Issue_Export_Closeout/T3_6_Integrity_Summary_Tab.md` on 2025-10-27.

## 🎯 Objective
Deliver a dedicated Integrity tab that consolidates all recorded `ParseIssue` entries into a sortable, filterable table and exposes exports so operators can triage corruption without scanning the outline manually.

## 📌 Immediate Focus
- Finish the SwiftUI tab layout, ensuring severity sort/filter controls stay synchronized with ribbon and detail pane counts.
- Bind row selection to the outline/detail focus APIs introduced during T3.3–T3.5 so navigation remains contextual.
- Wire the Share menu to the refreshed plaintext and JSON exporters now shipping in T4.2.

## 🔗 References
- [`DOCS/TASK_ARCHIVE/174_T2_1_ParseIssueStore_Aggregation/`](../TASK_ARCHIVE/174_T2_1_ParseIssueStore_Aggregation/)
- [`DOCS/TASK_ARCHIVE/191_T3_5_Contextual_Status_Labels/`](../TASK_ARCHIVE/191_T3_5_Contextual_Status_Labels/)
- [`DOCS/TASK_ARCHIVE/194_T4_2_Plaintext_Issue_Export_Closeout/T4_2_Text_Issue_Summary_Export.md`](../TASK_ARCHIVE/194_T4_2_Plaintext_Issue_Export_Closeout/T4_2_Text_Issue_Summary_Export.md)
