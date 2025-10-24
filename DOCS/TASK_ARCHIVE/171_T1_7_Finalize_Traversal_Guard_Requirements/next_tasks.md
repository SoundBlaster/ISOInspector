# Next Tasks

- Implement traversal guard enforcement inside `StreamingBoxWalker`, honoring the
  budgets defined in `Traversal_Guard_Requirements.md` and ensuring strict mode
  behaviour is unchanged.
- Add corrupt fixtures (`zero-size-loop.mp4`, nested `uuid` stack, overlapping
  children) to the fixture catalog and wire them into unit, integration, and fuzz
  harnesses.
- Update CLI/UI issue presenters to localize new `guard.*` codes and surface guard
  counts in integrity summaries.
- Capture guard activation metrics in tolerant parsing dashboards so QA can track
  hit rates across fuzz campaigns.
