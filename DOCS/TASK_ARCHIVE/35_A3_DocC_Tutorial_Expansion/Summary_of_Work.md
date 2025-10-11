# Summary of Work — DocC Tutorial Expansion

## Completed Tasks

- Expanded ISOInspectorCLI DocC catalog with the **Capture Research Logs for Annotation Reviews** tutorial, including
  cross-links to app workflows and new CLI screenshot assets.
- Expanded ISOInspectorApp DocC catalog with the **Annotate and Bookmark MP4 Investigations** tutorial, covering
  annotation and bookmark persistence steps with supporting screenshots.
- Updated `DOCS/INPROGRESS/next_tasks.md` to reflect completion of the DocC expansion task.

## Documentation & Assets

- Added tutorial files under both DocC catalogs along with generated PNG resources.
- Updated catalog landing pages to surface the new tutorials within the overview and topics sections.

## Tests & Validation

- `swift test`
- `python3 scripts/fix_markdown.py`

## Follow-up Notes

- Once additional UI polish lands (e.g., rich text annotations or shared bookmark collections), extend the tutorials
  with new sections and fresh screenshots.
- Coordinate with CI owners to publish DocC archives that include the new tutorial content.
