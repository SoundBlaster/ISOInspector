# R3 – Accessibility Guidelines

## 🎯 Objective

Document VoiceOver, Dynamic Type, and keyboard navigation guidelines tailored to ISOInspector’s SwiftUI tree, detail,
and hex views so follow-on UI features stay aligned with the completed accessibility work.

## 🧩 Context

- Research gap **R3** calls for codifying accessibility practices that reinforce the UI accessibility commitments
  delivered in Task C5 while guiding future
  enhancements.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L6-L11】【F:DOCS/TASK_ARCHIVE/37_C5_Accessibility_Features/37_C5_Accessibility_Features.md†L1-L27】
- Non-functional requirement **NFR-USAB-001** mandates VoiceOver and Dynamic Type support, and the product requirements
  emphasize keyboard navigation for all interactive
  components.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L20-L57】
- Existing NestedA11yIDs integration provides consistent identifiers, offering a baseline the guidelines should
  reference for automation and documentation
  touchpoints.【F:Documentation/ISOInspector.docc/Guides/NestedA11yIDsIntegration.md†L1-L52】

## ✅ Success Criteria

- Capture a written checklist covering VoiceOver labels, rotor navigation expectations, Dynamic Type behavior, and
  keyboard focus patterns for tree, detail, and hex surfaces.
- Provide linkage to existing implementation touchpoints (e.g., accessibility identifiers, tests, and preview audits)
  plus gaps requiring follow-up bugs or research tasks.
- Outline verification steps (Accessibility Inspector passes, XCTest coverage, manual QA scenarios) that future
  contributors must satisfy before shipping UI changes.

## 🔧 Implementation Notes

- Review Apple’s Accessibility Programming Guide and relevant WWDC sessions, distilling actionable recommendations for
  complex SwiftUI hierarchies used in ISOInspector.
- Audit current UI components against the checklist, noting any deviations or tooling needs so they can be triaged
  without blocking publication of the guidelines.
- Highlight how NestedA11yIDs constants, research log previews, and existing test suites should be leveraged when
  executing accessibility QA.
- Capture any platform-specific nuances (macOS vs. iPadOS/iOS) affecting keyboard shortcuts, focus scopes, or dynamic
  type breakpoints.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
