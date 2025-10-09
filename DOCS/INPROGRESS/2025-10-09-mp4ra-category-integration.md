# MP4RA category integration — micro PRD

## Intent

Expose MP4RA category strings through the catalog so streaming parse events can surface human-readable metadata
groupings.

## Scope

- Kit: `BoxDescriptor`, `BoxCatalog`, `MP4RACatalogRefresher`, `scripts/validate_mp4ra_minimal.py`
- CLI: No changes required; existing formatting already displays catalog summaries.
- App: No changes required; view models consume the enriched descriptors automatically.

## Integration contract

- Public Kit API added/changed: `BoxDescriptor` now includes optional `category` metadata.
- Call sites updated: Catalog loader and refresher pipelines populate the new property.
- Backward compat: Addition is additive and defaults to `nil` when absent.
- Tests: `BoxCatalogTests`, `MP4RACatalogRefresherTests`, and workspace-wide suites updated.

## Next puzzles

- No follow-up puzzles identified; consumers already read the enriched descriptors.

## Notes

Build: `swift test`
