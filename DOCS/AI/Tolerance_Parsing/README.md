# Corrupted Media Tolerance — Feature Documentation

**Status:** Planning Phase Complete — Ready for Sprint 1 Entry
**Owner:** Core Parsing Team
**Priority:** High (P0 for forensic workflow adoption)

---

## Overview

This directory contains planning, analysis, and integration documentation for the **Corrupted Media Tolerance** feature — a transformative capability that enables ISOInspector to parse corrupted or partially downloaded media files while explicitly signaling structural issues.

**Paradigm Shift:** From "detect errors and halt" to "detect, record, and continue."

**Target Users:** QC operators, streaming SREs, video engineers investigating damaged media.

---

## Documentation Index

### Core Documents

1. **[CorruptedMediaTolerancePRD.md](./CorruptedMediaTolerancePRD.md)** — Product Requirements Document
   - Problem statement, goals, user scenarios
   - Functional & non-functional requirements
   - Technical architecture, rollout plan
   - **Read this first** for feature context.

2. **[TODO.md](./TODO.md)** — Execution Workplan
   - 7 phases (T1-T7): Parsing Resiliency → UI → Export → Testing → CLI → Rollout
   - 37 atomic tasks with effort estimates, dependencies, acceptance criteria
   - Sprint timeline and exit criteria
   - **Use this** for implementation planning.

3. **[FeatureAnalysis.md](./FeatureAnalysis.md)** — Novelty & Impact Assessment
   - Relationship to existing work (E1, E2, VR-*, B7)
   - Competitive positioning vs. ffprobe/Bento4
   - User impact analysis, technical architecture changes
   - Risk matrix and success metrics
   - **Consult this** for decision rationale and risk mitigation.

4. **[IntegrationSummary.md](./IntegrationSummary.md)** — Component Integration Guide
   - Component-by-component integration plan (BoxParser, UI, export, CLI)
   - Code change specifications with before/after examples
   - Testing strategy (unit, integration, UI, performance, fuzzing)
   - Migration & rollout plan (Sprint 1-6 + Post-Launch)
   - **Use this** during implementation for detailed integration contracts.

5. **[ResearchSummary.md](./ResearchSummary.md)** — Research Findings & Next Actions
   - Summary of documentation integration process (per `DOCS/COMMANDS/NEW.md`)
   - Key decisions, open questions, success metrics tracking
   - Immediate/short-term/long-term next actions
   - **Review this** for project status and handoff.

---

## Quick Start

### For Product Managers
- **Read:** PRD ([CorruptedMediaTolerancePRD.md](./CorruptedMediaTolerancePRD.md))
- **Review:** Success metrics in [ResearchSummary.md](./ResearchSummary.md#success-metrics-tracking-plan)
- **Track:** Rollout plan in [TODO.md](./TODO.md#phase-t7--rollout--iteration-per-prd-rollout-plan)

### For Engineers (Sprint 1 Entry)
- **Start with:** Task T1.1 in [TODO.md](./TODO.md#phase-t1--core-parsing-resiliency)
- **Understand integration:** [IntegrationSummary.md](./IntegrationSummary.md#1-boxheaderdecoder)
- **Review risks:** [FeatureAnalysis.md](./FeatureAnalysis.md#risk-matrix)

### For Release Managers
- **Rollout plan:** [TODO.md](./TODO.md#phase-t7--rollout--iteration-per-prd-rollout-plan)
- **Testing strategy:** [IntegrationSummary.md](./IntegrationSummary.md#testing-strategy)
- **Migration checklist:** [IntegrationSummary.md](./IntegrationSummary.md#risk-mitigation-checklist)

### For QA/Test Engineers
- **Fixture corpus:** Task T5.1 in [TODO.md](./TODO.md#phase-t5--testing--fixtures)
- **Acceptance criteria:** Each task in [TODO.md](./TODO.md) includes verification steps
- **Performance benchmarks:** Task T5.4 in [TODO.md](./TODO.md#phase-t5--testing--fixtures)

---

## Feature Summary

### Problem
ISOInspector currently halts parsing on the first structural error, preventing users from inspecting corrupted media. Stakeholders (QC operators, SREs) require forensic-grade tools that extract maximum information from damaged files.

### Solution
Introduce **lenient parsing mode** that:
1. Continues parsing after encountering recoverable errors
2. Records corruption events as structured `ParseIssue` objects
3. Renders partial trees with corruption badges, placeholders, diagnostic details
4. Exports actionable diagnostics (JSON/text) with byte offsets and suggested actions

### Architecture Highlights
- **`ParseIssue` model**: Severity, code, message, byte range
- **`ParsePipeline.Options`**: Toggles for `abortOnStructuralError`, `maxCorruptionEvents`
- **`ParseTreeNode` extensions**: `issues: [ParseIssue]`, `status: NodeStatus`
- **Dual-mode validation**: Rules check pipeline options; emit issues (lenient) or throw (strict)
- **UI corruption views**: Badges, placeholders, "Integrity" summary tab, export actions

### Rollout Plan
- **Sprint 1-2:** Prototype (core parsing resiliency, issue recording)
- **Sprint 3:** Alpha (UI corruption views, internal QC feedback)
- **Sprint 4-5:** Beta (CLI parity, external beta testing)
- **Sprint 6:** GA (default lenient mode, feature flag removed)
- **Post-Launch:** Telemetry, heuristic refinement

---

## Cross-References

### Related ISOInspector Components
- **Main PRD:** [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../ISOViewer/ISOInspector_PRD_TODO.md)
- **Execution Guide:** [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- **Current Tasks:** [`DOCS/INPROGRESS/next_tasks.md`](../../INPROGRESS/next_tasks.md)

### Related Archived Tasks
- **E1: Parent Containment Validation** — [`DOCS/TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/`](../../TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/)
- **E2: Progress Loop Guards** — [`DOCS/TASK_ARCHIVE/163_E2_Detect_Progress_Loops/`](../../TASK_ARCHIVE/163_E2_Detect_Progress_Loops/)
- **B7: Validation Configuration** — [`DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`](../../TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/)
- **G7: UI State Management** — [`DOCS/TASK_ARCHIVE/154_G7_State_Management_ViewModels/`](../../TASK_ARCHIVE/154_G7_State_Management_ViewModels/)
- **B6: JSON Export** — [`DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/`](../../TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/)

---

## Success Metrics

| Metric | Target | Status |
|--------|--------|--------|
| **Coverage** | ≥95% corrupt fixtures parse to completion | Pending (Sprint 2) |
| **User Satisfaction** | ≥4/5 on "inspect damaged files" | Pending (Post-GA) |
| **Crash-Free Sessions** | 99.9% across corrupt fixture suite | Pending (Sprint 5) |
| **Performance** | Lenient mode ≤1.2× strict mode | Pending (Sprint 5) |

---

## Open Questions

1. **Batching large corruption clusters** — How to summarize thousands of broken samples without hiding detail?
   - *Status:* Open — defer to Sprint 3 QC feedback

2. **Placeholder creation heuristics** — When to auto-create placeholder nodes vs. grouping missing siblings?
   - *Status:* Open — prototype in Sprint 2

3. **Localization validation** — Are issue labels clear for Russian- and English-speaking operators?
   - *Status:* Open — beta feedback in Sprint 4-5

4. **Telemetry safeguards** — Do offset ranges leak sensitive metadata?
   - *Status:* **Resolved** — no payload bytes exported; privacy audit confirms compliance

---

## Contact & Approval

**Feature Owner:** Core Parsing Team
**Stakeholders:** QC Operations, SRE Team, Video Engineering
**Review Status:** Documentation complete; awaiting Sprint 1 entry approval

**Next Reviewer:** Core team lead (verify T1.4 refactor feasibility)
**Approval Required From:** Product owner (confirm Sprint 1 timing)

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-10-23 | Initial documentation structure created per `DOCS/COMMANDS/NEW.md` workflow | AI Integration Assistant |
| 2025-10-23 | Added to `DOCS/INPROGRESS/next_tasks.md` (Task T1.1 queued) | AI Integration Assistant |

---

## Navigation

**Up:** [`DOCS/AI/`](../)
**Main PRD:** [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../ISOViewer/ISOInspector_PRD_TODO.md)
**Current Tasks:** [`DOCS/INPROGRESS/next_tasks.md`](../../INPROGRESS/next_tasks.md)
**Archived Tasks:** [`DOCS/TASK_ARCHIVE/`](../../TASK_ARCHIVE/)
