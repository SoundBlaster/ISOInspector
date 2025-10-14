# MP4RA Catalog Refresh Guide

This guide documents the repeatable workflow for updating `Sources/ISOInspectorKit/Resources/MP4RABoxes.json` from the official MP4RA registry.

## Prerequisites

- Active internet access (the registry is fetched from `https://mp4ra.org/api/boxes`).
- Swift toolchain available locally (the project already uses Swift Package Manager).
- Run commands from the repository root unless otherwise noted.

## Refresh Workflow

1. **Fetch the latest registry JSON and regenerate the bundled catalog.**

   ```bash
   swift run isoinspect mp4ra refresh
   ```

   - The command downloads the registry, normalizes MP4 box identifiers (including `$20`-encoded spaces), and writes the refreshed catalog to `Sources/ISOInspectorKit/Resources/MP4RABoxes.json`.
   - By default the CLI targets the bundled file path. Use `--output <path>` to write to a scratch location for inspection, and `--source <url>` to test alternative registry endpoints.

2. **Inspect metadata and diff.**
   - Ensure the JSON now contains an updated `metadata` block with `source`, `fetchedAt` (UTC ISO8601 timestamp), and `recordCount` fields.
   - Review the `git diff` to confirm the number of entries and any notable changes before committing.

3. **Validate compatibility.**
   - Run the full test suite to confirm `BoxCatalog` still decodes the refreshed file and downstream behaviour is unchanged.

   ```bash
   swift test
   ```

4. **Document the refresh.**
   - Update any relevant task logs or research notes if the refresh resolves an open follow-up.
   - Commit the regenerated JSON together with supporting documentation updates.

## Troubleshooting

- **Network failures:** rerun the command once connectivity is restored. The CLI prints the failing URL for quick diagnostics.
- **Schema mismatches:** if MP4RA introduces new fields, extend `MP4RACatalogRefresher` and add regression tests before regenerating.
- **Selective updates:** when validating locally without overwriting the bundled catalog, supply an alternate `--output` path and copy the file into place once reviewed.

Keep this guide alongside future refreshes so contributors can execute the maintenance task without reverse-engineering prior changes.
