
# ISOInspectorDocs PRD — Developer and User Documentation

## 1. Scope & Intent
**Objective:** Deliver complete documentation for ISOInspector ecosystem — API, usage, architecture, and contribution guides — in Markdown and DocC formats.

### Deliverables
| Document | Type | Description |
|-----------|------|-------------|
| API Reference | DocC | Generated from Core/UI symbols |
| Developer Guide | Markdown | Architecture, data flow, async model |
| User Guide | Markdown | App & CLI usage, troubleshooting |
| Contribution Guide | Markdown | For open-source contributors |
| Changelog | Markdown | Semantic versioning, release notes |
| README | Markdown | Project overview |
| Diagram Assets | Mermaid/SVG | Data flow & module relationships |

### Success Criteria
- DocC browsable via Xcode & GitHub Pages.
- Markdown rendered correctly on GitHub.
- API coverage ≥95% public symbols.

### Constraints
- Use only DocC, no external site builders.
- All docs bilingual (EN/RU optional).
- Live links and anchors validated.

---

## 2. Structured TODO Breakdown

| Phase | Task | Priority | Effort | Output |
|-------|------|-----------|--------|--------|
| A | Setup DocC catalogs | High | 1d | /Docs/ISOInspectorCore.docc etc. |
| B | Auto-generate API Reference | High | 2d | Core & UI API pages |
| C | Write Developer Guide | High | 3d | Markdown `/Docs/developer_guide.md` |
| D | Write User Guide | Medium | 2d | `/Docs/user_guide.md` |
| E | Contribution & Changelog templates | Medium | 1d | `/CONTRIBUTING.md`, `/CHANGELOG.md` |
| F | Add architecture diagrams (Mermaid) | Medium | 2d | `/Docs/diagrams/` |
| G | Validate links and anchors | Medium | 1d | No broken anchors |
| H | Automate deployment to GitHub Pages | Medium | 1d | CI pipeline |

---

## 3. Non-Functional Requirements
- Readable on both light/dark themes.
- Buildable offline via `xcodebuild docbuild`.
- ≤1s navigation latency in hosted pages.
- Markdown style consistent with GitHub Flavored Markdown spec.

---

## 4. Acceptance Criteria
- DocC builds successfully with `--analyze`.
- GitHub Pages site online and updated each release.
- No broken references or missing DocC topics.
