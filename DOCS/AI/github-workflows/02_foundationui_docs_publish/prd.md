# PRD: FoundationUI Documentation GitHub Pages Publication

## 1. Purpose

Automate publishing of the FoundationUI DocC archive to the dedicated `soundblaster/FoundationUI` GitHub Pages site so its API reference is reachable at `https://soundblaster.github.io/FoundationUI/documentation/foundationui/` without overwriting the existing ISOInspector documentation site.

## 2. Research Summary

- GitHub Pages supports only one site per repository. ISOInspector docs already occupy the `soundblaster/ISOInspector` site, so FoundationUI must ship to its own repository (`soundblaster/FoundationUI`).
- The existing ISOInspector workflow (`.github/workflows/documentation.yml`) already builds DocC successfully; it only needs a hosting base path update so the generated links match `documentation/isoinspectorkit/`.
- `swift package generate-documentation --target FoundationUI` produces `FoundationUI.doccarchive` with the required `documentation/foundationui/` folder when the hosting base path is set appropriately.
- Publishing to another repository requires a personal access token; a new workflow can fetch the `gh-pages` branch, copy the archive, and push updates.

## 3. Scope

### Included

- Retain the ISOInspector workflow for ISOInspectorKit only, adjusting its hosting base path to `documentation/isoinspectorkit`.
- Add a dedicated workflow (`.github/workflows/foundationui-documentation.yml`) that builds the FoundationUI DocC archive on macOS runners.
- Copy the generated archive into the `soundblaster/FoundationUI` repository’s `gh-pages` branch, add `.nojekyll`, and create an `index.html` redirect to `documentation/foundationui/`.
- Require a `FOUNDATIONUI_PAGES_TOKEN` secret with write access to the target repository and fail fast if it is missing.

### Excluded

- Altering DocC content for either framework.
- Adding shared landing pages or cross-linking between the two sites.
- Managing DNS, custom domains, or SSL configuration (GitHub Pages defaults apply).

## 4. Deliverables

| Artifact | Location | Notes |
| --- | --- | --- |
| Updated ISOInspector workflow | `.github/workflows/documentation.yml` | Builds ISOInspectorKit DocC with correct `documentation/isoinspectorkit/` links. |
| New FoundationUI workflow | `.github/workflows/foundationui-documentation.yml` | Builds/publishes FoundationUI DocC to `soundblaster/FoundationUI` via PAT. |
| Publishing documentation | `DOCS/AI/github-workflows/02_foundationui_docs_publish/` | Captures requirements, risks, and TODO tracking. |

## 5. Success Criteria

- Pushes to `main` regenerate ISOInspector docs at `https://soundblaster.github.io/ISOInspector/documentation/isoinspectorkit/`.
- Pushes to `main` regenerate FoundationUI docs at `https://soundblaster.github.io/FoundationUI/documentation/foundationui/` once the PAT is configured.
- The FoundationUI workflow exits early with an actionable error when the deployment token is absent.
- Documentation for the new workflow conforms to `DOCS/COMMANDS/NEW.md` expectations.

## 6. Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| Missing or insufficient PAT for the FoundationUI repository | Add an explicit token check and document the `FOUNDATIONUI_PAGES_TOKEN` requirement. |
| `gh-pages` branch absent in the FoundationUI repository | `actions/checkout` with PAT can create the branch on first run; document the expectation and verify push succeeds. |
| DocC generation failures on macOS runners | Mirror the ISOInspector job configuration that already works (macos-14 + latest Xcode). |
