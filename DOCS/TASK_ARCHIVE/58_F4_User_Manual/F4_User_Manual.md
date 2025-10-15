# 2025-10-13-user-manual — micro PRD

## Intent

Deliver end-user documentation for the ISOInspector app
workflows.【F:Documentation/ISOInspector.docc/Manuals/App.md†L1-L78】
Document CLI usage, streaming exports, and validation flows for automation
scenarios.【F:Documentation/ISOInspector.docc/Manuals
/CLI.md†L1-L76】

## Scope

- Kit: Documented research log defaults and MP4RA refresh flow; no code changes required.
- CLI: Described global options plus `inspect`, `validate`, `export`, and `batch` commands with usage guidance.【F:Documentation/

ISOInspector.docc/Manuals/CLI.md†L11-L99】

- App: Captured onboarding, search/filter controls, detail pane, and persistence behaviour for the SwiftUI
  shell.【F:Documentati

on/ISOInspector.docc/Manuals/App.md†L9-L76】

## Integration contract

- Public Kit API added/changed: None — docs reference existing behaviour only.
- Call sites updated: N/A (documentation-only iteration).
- Backward compat: No runtime changes.
- Tests: No new tests; documentation validated with `scripts/fix_markdown.py` and Markdownlint.

## Next puzzles

- [ ] Capture annotated screenshots for macOS and iPadOS layouts once CI artifacts or manual captures are available.
- [ ] Publish troubleshooting recipes for session persistence once diagnostics surfacing lands (blocked by existing
  @todo items).

## Notes

Build & lint: `python3 scripts/fix_markdown.py` then `npx markdownlint-cli2 "DOCS/INPROGRESS/**/*.md" "DOCS/COMMANDS/**/*.md" "D
OCS/RULES/**/*.md"`
