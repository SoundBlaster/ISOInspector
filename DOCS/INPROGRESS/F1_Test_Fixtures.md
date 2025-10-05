# F1 — Automated Test Fixture Suite

## 🎯 Objective

Produce a curated collection of MP4/MOV sample files and supporting metadata that exercises nominal and malformed
structures so the parser, validators, and exporters can be regression-tested automatically.

## 🧩 Context

- Execution Workplan task F1 prioritizes fixture development after B2 so the streaming pipeline (B3) and downstream
  modules have reliable coverage of positive and negative cases.

- The Research Gaps log highlights R2 (Fixture Acquisition) as a prerequisite investigation, pointing to open datasets
  and licensing checks required before implementation.

- Phase B components already in place (chunked reader and box header decoder) depend on realistic payloads to validate
  boundary conditions noted in the technical specification.

## ✅ Success Criteria

- Fixture corpus includes at least: standard MP4, fragmented MP4, MOV variant, DASH init/media segments, large `mdat`, and intentionally malformed headers.

- Each fixture ships with machine-readable metadata (box inventory, expected warnings/errors, licensing notes) stored
  alongside the files for automated validation.

- `swift test` suites load fixtures without exceeding memory/time budgets and assert expected parse/validation outcomes for both success and failure cases.

- Documentation explains sourcing/licensing for every file and the process to refresh or regenerate fixtures.

## 🔧 Implementation Notes

- Collaborate with research outcomes from R2 to obtain legally distributable samples; prefer small but representative
  files when licensing permits.

- Where real samples are unavailable, generate synthetic MP4 structures using Bento4 or FFmpeg tooling scripted in
  Python as outlined in the AI Source Guide toolchain.

- Store fixtures under `Tests/ISOInspectorKitTests/Fixtures/` with checksum tracking so CI can verify integrity and detect drift.

- Define helper utilities (e.g., `FixtureCatalog`) that expose fixture metadata to tests and future benchmarks (F2) without hard-coding paths.

- Anticipate reuse by CLI/UI teams by documenting fixture semantics in DocC or Guides for cross-team visibility.

## 🧠 Source References

- DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md
- DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md
- DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md
- DOCS/AI/02_ISOInspector_AI_Source_Guide.md
- DOCS/PRD/main_prd.md
- DOCS/GUIDES/*
- DOCS/RULES/*
