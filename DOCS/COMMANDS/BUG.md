# SYSTEM PROMPT: Document and Diagnose a Bug Report

## 🧩 PURPOSE

Convert an incoming bug report into a fully documented, scope-ready artifact that captures reproduction details, diagnostic hypotheses, testing plans, and PRD context without beginning any implementation work.

## 🎯 GOAL

Extract the user-submitted bug report from the invocation context, formalize it, store it inside `DOCS/INPROGRESS`, outline remediation hypotheses plus testing/diagnostics plans, and prepare a handoff package that the `FIX` command (and its nested `START` workflow) can use to implement the resolution.

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

### Step 5. Prepare the Implementation Handoff

- Summarize the diagnostics, scope, and testing plan at the end of the INPROGRESS document under **Implementation Handoff**.
- Explicitly list prerequisites or blockers that the implementation workflow must respect.
- Provide instructions for invoking the [`FIX`](FIX.md) command so the implementer can follow the bug-specific wrapper around [`START`](START.md).

### Step 6. Archive and Sync Planning Artefacts

- Update `todo.md`, workplan entries, and any backlog files to reflect the new bug record and its status.
- If the bug is blocked, document the blocker in [`DOCS/INPROGRESS/blocked.md`](../INPROGRESS/blocked.md) and cross-link from the INPROGRESS file.
- Ensure all related documentation (PRD snippets, diagnostics plans) is saved and cross-referenced.

---

## ✅ EXPECTED OUTPUT

- A richly detailed bug report stored in `DOCS/INPROGRESS` capturing diagnostics, testing strategy, and PRD context.
- Updated plans outlining code touchpoints, hypotheses, and TDD steps, all clearly marked as pre-implementation guidance.
- Planning artefacts (`todo.md`, backlog files) synchronized with the new bug record and its status.
- A clearly documented **Implementation Handoff** that directs implementers to use the `FIX` command (which wraps `START`).

---

## 🧠 TIPS

- Treat the improved bug report as the anchor document—keep it synchronized with discoveries and decisions.
- Prefer automation for reproduction where possible; manual steps should be a fallback.
- When scope balloons, break work into smaller INPROGRESS entries and keep the workplan synchronized.
- Do **not** begin implementation here; that is delegated to the `FIX` wrapper command.

---

## END OF SYSTEM PROMPT

Ensure Markdown formatting remains consistent; the legacy `scripts/fix_markdown.py` helper is retired.
