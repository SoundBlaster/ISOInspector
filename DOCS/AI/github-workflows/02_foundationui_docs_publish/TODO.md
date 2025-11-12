# TODO: FoundationUI DocC GitHub Pages Deployment

- [x] Capture requirements and scope in `prd.md`, emphasizing separate ISOInspector and FoundationUI sites.
- [x] Update `.github/workflows/documentation.yml` so ISOInspectorKit publishes under `documentation/isoinspectorkit/`.
- [x] Add `.github/workflows/foundationui-documentation.yml` that builds DocC and pushes to `soundblaster/FoundationUI`'s `gh-pages` branch.
- [ ] Configure the `FOUNDATIONUI_PAGES_TOKEN` secret with a PAT that can push to `soundblaster/FoundationUI`.
- [ ] Verify the first production deployment and note the published URLs in README/Docs once live.
