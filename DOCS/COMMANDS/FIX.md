# SYSTEM PROMPT: Execute a Bug Fix (Wrapper Around START)

## 🧩 PURPOSE

Provide a bug-fix-specific command that wraps the [`START`](START.md) workflow, ensuring implementation work follows the diagnostics, hypotheses, and testing plans documented by the `BUG` command while respecting all ISOInspector delivery rules.

## 🎯 GOAL

Take a prepared bug record in `DOCS/INPROGRESS`, confirm its readiness, run the `START` command’s implementation sequence with bug-aware safeguards, and deliver a verified fix plus updated documentation and planning artefacts.

---

## ⚙️ EXECUTION STEPS

### Step 1. Load the Bug Documentation

- Identify the target Markdown file within [`DOCS/INPROGRESS`](../INPROGRESS) that contains the bug report produced by `BUG`.
- Review the **Implementation Handoff**, diagnostics plan, hypotheses, and TDD testing plan.
- Confirm prerequisites (logs, fixtures, environments) are available; if not, document blockers and stop.

### Step 2. Align Scope and Success Criteria

- Validate that the recorded scope matches the current request; adjust the INPROGRESS file if new findings emerge before coding starts.
- Translate the diagnostics/testing plans into concrete tasks or TODO items.
- Ensure regression criteria, acceptance tests, and customer impact statements are understood.

### Step 3. Invoke the START Workflow with Bug-Specific Guidance

- Execute every step in [`START.md`](START.md) as the core implementation loop.
- When following START:
  - Use the diagnostics plan to prioritize investigation order.
  - Implement tests outlined in the TDD plan before writing fixes.
  - Keep the INPROGRESS document updated with discoveries, referencing puzzle/commit IDs per PDD guidance.

### Step 4. Execute the Fix via TDD/XP/PDD

- Follow the TDD cycle: write failing tests, implement minimal fixes, refactor, repeat.
- Apply XP principles (small iterations, continuous refactoring) and PDD (treat each hypothesis as a puzzle, commit per puzzle).
- Capture logs, screenshots, or recordings if required to demonstrate repro and resolution.

### Step 5. Validate and Document

- Run the full test suite plus targeted diagnostics to confirm the fix.
- Update the INPROGRESS file with results, remaining risks, and links to commits.
- If new documentation, changelog, or user-facing notes are required, author them now.

### Step 6. Handle Blockers or Large Scope

- If the bug cannot be resolved due to upstream blockers or exceeds feasible scope:
  - Update the diagnostics and PRD sections with current findings.
  - Refresh relevant planning artefacts (`todo.md`, workplan, backlog) to capture the blocker.
  - Archive or reclassify the INPROGRESS file according to project rules, ensuring all intermediate documents are saved.

### Step 7. Finalize

- Once resolved, transition the INPROGRESS file to the appropriate archive location per workflow rules and mark linked TODO/workplan items as completed.
- Summarize the resolution, tests executed, and remaining follow-ups in the INPROGRESS document and any PR messages.
- Verify that the `START` workflow’s summary requirements (e.g., `Summary_of_Work.md`) remain satisfied.

---

## ✅ EXPECTED OUTPUT

- Implemented bug fix verified by automated tests and diagnostics.
- Updated INPROGRESS document capturing execution notes, validation evidence, and resolution summary.
- Planning artefacts (`todo.md`, backlog files, PRD snippets) synchronized with the fix outcome or blocker status.
- Archival actions (moving INPROGRESS files, updating `Summary_of_Work.md`) completed per `START` requirements.

---

## 🧠 TIPS

- Treat the BUG-produced document as the single source of truth; keep it updated every time a hypothesis is confirmed or rejected.
- When regressions touch multiple subsystems, spin up separate puzzles/commits while still running under this wrapper.
- Prefer adding regression tests that would have caught the bug.
- If new scope is discovered mid-fix, pause, update the BUG documentation, and only then continue via this FIX wrapper.

---

## END OF SYSTEM PROMPT

Ensure Markdown formatting remains consistent; the legacy `scripts/fix_markdown.py` helper is retired.
