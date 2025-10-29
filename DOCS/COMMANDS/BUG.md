# SYSTEM PROMPT: Process and Resolve a Bug Report

## 🧩 PURPOSE

Transform an incoming bug report into a fully diagnosed, test-driven fix plan that delivers a verified resolution while keeping all workflow artefacts up to date.

## 🎯 GOAL

From the invocation context extract the user-submitted bug report, formalize it, capture it in `DOCS/INPROGRESS`, define the remediation scope (front of work, code touchpoints, and validation strategy), execute the fix via TDD/XP/PDD workflows, and update planning documents when blockers arise.

---

## 🔗 REFERENCE MATERIALS

- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md)
- [`DOCS/RULES/04_PDD.md`](../RULES/04_PDD.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- Existing task records in [`DOCS/INPROGRESS`](../INPROGRESS)
- Blocked work references in [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) and [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED)

---

## ⚙️ EXECUTION STEPS

### Step 1. Capture the Bug Report

- Parse the invocation context to extract the raw user bug report (title, observed behaviour, environment, expected behaviour, reproduction steps).
- Normalize and enrich the report with missing critical details when inferable (logs, repro assumptions, impacted components).
- Store the formalized report in a new Markdown file within [`DOCS/INPROGRESS`](../INPROGRESS) using a numbered, descriptive filename.
- Include sections for **Objective**, **Symptoms**, **Environment**, **Reproduction Steps**, **Expected vs. Actual**, and **Open Questions**.

### Step 2. Define Scope and Hypotheses

- Identify the functional area (“front of work”) affected by the bug (UI, backend service, CLI, docs, etc.).
- Pinpoint likely code locations (modules, files, functions) to investigate.
- Note relevant existing tests or the absence thereof.
- Record initial diagnostic hypotheses in the INPROGRESS document.

### Step 3. Plan Diagnostics and Testing

- Create a **Diagnostics Plan** detailing experiments, logging, or instrumentation needed to isolate root cause.
- Outline a **TDD Testing Plan** specifying new or updated automated tests (unit, integration, UI) required to reproduce and prevent the regression.
- If additional specifications are needed, append references or create stubs in the PRD master documents.

### Step 4. Produce a Focused PRD Update

- Draft a PRD section (embed or link within the INPROGRESS file) summarizing the customer impact, acceptance criteria, and technical approach for the fix.
- Ensure alignment with the master PRD and execution guide; update relevant backlog entries to reflect the bug-fix effort.

### Step 5. Execute the Fix via TDD/XP/PDD

- Follow the TDD cycle: write failing tests based on the plan, implement minimal fixes, refactor, and ensure all tests pass.
- Adhere to XP principles (small iterations, continuous refactoring) and treat each sub-problem as a PDD puzzle.
- Update task notes, TODOs, and work logs as progress is made.

### Step 6. Validate and Document

- Run the full test suite plus targeted diagnostics to confirm the fix.
- Update the INPROGRESS document with results, remaining risks, and links to commits.
- If new documentation, changelog, or user-facing notes are required, author them now.

### Step 7. Handle Blockers or Large Scope

- If the bug cannot be resolved due to upstream blockers or exceeds feasible scope:
  - Update the diagnostics and PRD sections with current findings.
  - Refresh relevant planning artefacts (`todo.md`, workplan, backlog) to capture the blocker.
  - Archive or reclassify the INPROGRESS file according to project rules, ensuring all intermediate documents are saved.

### Step 8. Finalize

- Once resolved, transition the INPROGRESS file to the appropriate archive location per workflow rules and mark linked TODO/workplan items as completed.
- Summarize the resolution, tests executed, and remaining follow-ups.

---

## ✅ EXPECTED OUTPUT

- A richly detailed bug report stored in `DOCS/INPROGRESS` with diagnostics, testing, and PRD sections.
- Updated plans outlining code touchpoints, hypotheses, and TDD steps.
- Implemented bug fix verified by automated tests and documented outcomes.
- Updated planning artefacts when blockers prevent completion.

---

## 🧠 TIPS

- Treat the improved bug report as the anchor document—keep it synchronized with discoveries and decisions.
- Prefer automation for reproduction where possible; manual steps should be a fallback.
- When scope balloons, break work into smaller INPROGRESS entries and keep the workplan synchronized.

---

## END OF SYSTEM PROMPT

Ensure Markdown formatting remains consistent; the legacy `scripts/fix_markdown.py` helper is retired.
