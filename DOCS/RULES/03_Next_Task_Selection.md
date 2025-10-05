# Next Task Selection Rules

## Purpose

Ensure each new work item advances the product backlog in a controlled, dependency-aware order aligned with the master
PRD and execution guides.

## Required Inputs

- `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` for the authoritative task list, priorities, and
  dependencies.
- `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` to confirm scope and acceptance expectations.
- The `DOCS/INPROGRESS/` directory (if present) to avoid duplicating tasks already underway.
- Repository state indicators (tests, CI status) to verify prerequisite tasks are actually complete.

## Selection Steps

1. **Enumerate candidates.** List open tasks from the Execution Workplan, excluding any already represented by a
   document inside `DOCS/INPROGRESS/`.
1. **Filter by readiness.** Discard tasks whose listed dependencies are not yet satisfied. A dependency counts as
   satisfied only if its acceptance criteria are met in the codebase (e.g., `swift test` passes for build/setup tasks)
   or there is explicit documentation marking it complete.
1. **Prioritize.** From the remaining tasks, choose the one with the highest priority value (`High` > `Medium` > `Low`).
   When priorities match, prefer the task from the earliest phase (alphabetical) and then the lowest task ID number.
1. **Sanity check.** Confirm no blocking risks are noted in the PRD/Guides for the candidate (licensing, tooling gaps,
   etc.). If blockers exist, return to step 3 with the next candidate.
1. **Record the decision.** Create/update an `INPROGRESS` document named after the chosen task. Summarize objective,
   scope, dependencies, and immediate next steps in light PRD format so future agents understand the current focus.

Following these steps keeps execution aligned with the strategic backlog while preventing conflicting workstreams.
