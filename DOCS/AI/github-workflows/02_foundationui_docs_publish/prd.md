# PRD: FoundationUI Documentation GitHub Pages Publication

## 1. Purpose
Provide automated publishing of FoundationUI DocC archives to GitHub Pages so the component library has the same documentation access story as ISOInspector. The workflow must match the existing ISOInspector pipeline (`.github/workflows/documentation.yml`) to keep maintenance and hosting consistent across the mono-repo.

## 2. Research Summary
- `.github/workflows/documentation.yml` already publishes the ISOInspectorKit DocC archive with static hosting transforms and an HTML redirect into the generated symbol pages.
- FoundationUI ships its DocC catalog at `FoundationUI/Sources/FoundationUI/Documentation.docc`. `swift package generate-documentation --target FoundationUI` produces the required static archive (`FoundationUI.doccarchive`).
- GitHub Pages requires `.nojekyll` and an index redirect to avoid case sensitivity mismatches (DocC lowercases output folder names such as `documentation/foundationui/`).
- No conflicting PRDs mention FoundationUI Pages deployment; this is a net-new addition and can reuse the ISOInspector approach one-to-one.

## 3. Scope
**Included**
- Dedicated workflow mirroring ISOInspector’s publishing job but targeting the `FoundationUI` Swift Package target.
- Uploading DocC output as a `actions/upload-pages-artifact` artifact and deploying with `actions/deploy-pages` on pushes to `main`.
- Hosting base path `FoundationUI` so the public URL becomes `https://<org>.github.io/FoundationUI/`.
- HTML redirect from `/index.html` to `/documentation/foundationui/` and `.nojekyll` marker in the artifact bundle.

**Excluded**
- Any modifications to the FoundationUI DocC content itself.
- Custom domains, DNS configuration, or analytics.
- Consolidating ISOInspector and FoundationUI docs into a single Pages site (each keeps a dedicated workflow and base path).

## 4. Deliverables
| Artifact | Location | Notes |
| --- | --- | --- |
| GitHub Actions workflow | `.github/workflows/foundationui-documentation.yml` | Triggered on `push`, `pull_request`, and `workflow_dispatch` like the ISOInspector job. |
| Deployment artifact bundle | `gh-pages/` (workflow temp folder) | Contains DocC static files, `.nojekyll`, and redirecting `index.html`. |
| Documentation entry | `DOCS/AI/github-workflows/02_foundationui_docs_publish/` | Captures scope, TODOs, and links to ISOInspector precedent. |

## 5. Success Criteria
- Workflow green on PRs touching FoundationUI documentation or Swift sources (DocC generation completes without warnings/failures).
- Pushes to `main` publish updated content to GitHub Pages at `https://<org>.github.io/FoundationUI/`.
- Generated archive contains the `documentation/foundationui/` tree with symbol pages accessible via the HTML redirect.
- Implementation recorded in repository documentation per `DOCS/COMMANDS/NEW.md` expectations.

## 6. Risks & Mitigations
| Risk | Mitigation |
| --- | --- |
| Concurrent runs of ISOInspector and FoundationUI publishers could stomp each other | Use a unique concurrency group (`foundationui-pages`) so both jobs queue separately. |
| DocC output path mismatched due to case sensitivity | Copy from `.build/plugins/Swift-DocC/outputs/FoundationUI.doccarchive/` and keep redirect pointing to the lowercase folder. |
| macOS runner availability | Align with ISOInspector job using `macos-14` which already works for DocC generation. |
