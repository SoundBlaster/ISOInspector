# SYSTEM PROMPT: Integrate New Feature Tasks into Documentation

## 🧩 PURPOSE

Incorporate an incoming feature request into the existing documentation ecosystem under [`DOCS/`](..), ensuring alignment with historical tasks, current plans, and product requirement documents in [`DOCS/AI`](../AI).

---

## 🎯 GOAL

Transform an incoming feature description (from a sentence to a detailed plan) into a fully contextualized set of
documentation updates:

- Structured analysis of the feature request.
- Cross-referenced insights from prior tasks.
- Updated work plans and TODO entries.
- New or revised PRD sections to capture the feature scope.

---

## ⚙️ EXECUTION STEPS

### Step 1. Understand the Incoming Feature

1. Parse the provided request, regardless of size.
1. Break it down into stages, milestones, and atomic subtasks.
1. Capture open questions, dependencies, and assumptions.

### Step 2. Research Existing Knowledge

1. Search throughout [`DOCS/`](..) — including [`DOCS/AI`](../AI), [`DOCS/TASKS_ARCHIVE`](../TASKS_ARCHIVE), and [`DOCS/INPROGRESS`](../INPROGRESS) — for related or similar tasks, experiments, or decisions.
1. Summarize relevant findings, noting:
   - Which documents contain overlapping scope.
   - Decisions or lessons learned that affect the new feature.
   - Any contradictions or outdated items that must be reconciled.

### Step 3. Evaluate Novelty and Relevance

1. Compare the new feature analysis with prior work.
1. Identify potential duplicates, obsolete directions, or conflicts.
1. Decide whether to merge, supersede, or deprecate earlier tasks.
1. Document rationale for each decision.

### Step 4. Update Documentation Ecosystem

1. Determine where the new tasks belong:
   - Work plans (e.g., [`DOCS/AI/**/TODO`](../AI)).
   - Active pipelines (e.g., [`DOCS/INPROGRESS`](../INPROGRESS)).
   - Roadmaps or backlog lists.
1. Insert or update TODO/Workplan entries with the new subtasks.
1. Mark linked historical tasks as referenced, merged, or closed, when appropriate.

### Step 5. Maintain PRD Coverage

1. Locate the relevant PRD file(s) inside [`DOCS/AI`](../AI).
1. Create or extend sections describing the feature motivation, scope, user impact, and success metrics.
1. Ensure PRD updates align with the decisions captured in Steps 2–4.
1. If no suitable PRD exists, create a new one under the appropriate product directory.

### Step 6. Consolidate Deliverables

1. Produce a summary of findings, updates applied, and next actions.
1. Highlight any unresolved questions or approvals needed.
1. Verify that all modified Markdown files comply with repository formatting standards (see [`scripts/fix_markdown.py`](../../scripts/fix_markdown.py)).

---

## ✅ EXPECTED OUTPUT

- A decomposed task list reflecting the new feature’s workflow.
- References to historical documents and clarity on how they influence the new plan.
- Updated TODO/workplan entries that include the new subtasks.
- Updated or newly created PRD sections addressing the feature.
- A summary documenting decisions, changes, and follow-ups.

---

## 🧾 NOTES

- Always respect the methodologies in [`DOCS/RULES`](../RULES), especially when modifying workflows or task boards.
- Prefer atomic commits that correspond to major documentation updates.
- When creating new documents, mirror the structure and tone of existing files in the same directory.

---

## END OF SYSTEM PROMPT
