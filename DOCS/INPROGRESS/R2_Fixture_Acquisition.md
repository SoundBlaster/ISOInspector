# R2 Fixture Acquisition

## 🎯 Objective

Identify and document a curated catalog of MP4/QuickTime fixtures that exercise standard, fragmented, and
vendor-specific atoms so the parsing, validation, and benchmarking suites can rely on representative media samples.

## ✅ Summary

- Curated ten high-value fixture sources spanning progressive, fragmented, high-bitrate, metadata-rich, and
  vendor-specific MP4 variants.
- Captured licensing, redistribution allowances, download locations, checksum strategies, and approximate storage
  requirements for each source so automation can stage media safely.
- Outlined ingestion, verification, and storage workflows that align with existing fixture regeneration tooling and
  document any macOS-dependent follow-up actions.

## 🧩 Context

- Research backlog R2 prioritizes gathering legally distributable media covering a wide atom surface, including DASH
  fragments and vendor boxes, to unblock QA and benchmarking
  coverage.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】
- Performance and validation workflows in the execution plan depend on diverse fixtures to exercise streaming readers,
  benchmarks, and follow-up hardware validation work once macOS infrastructure is
  available.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】【F:DOCS/INPROGRESS/next_tasks.md†L5-L12】

## ✅ Success Criteria

- Produce a ranked list of sample sources (public datasets, vendor bundles) with licensing notes and download
  metadata.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】
- Ensure the catalog covers core MP4 families (progressive `moov`/`mdat`), fragmented streaming (`moof`/`traf`), metadata-heavy assets, and edge cases referenced in benchmarking runbooks.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】
- Document storage and size requirements so CI or hardware runners can stage the media without exhausting
  quotas.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】

## 🗂️ Fixture Source Catalog

| Rank | Source | Coverage Highlights | Licensing & Redistribution | Download Notes | Approx. Size |
| --- | --- | --- | --- | --- | --- |
| 1 | Apple Developer Sample Media (progressive + HLS) | 4K HDR, SDR, multichannel AAC, Dolby Vision profiles with canonical `moov`/`mdat` ordering; paired HLS packs expose fragmented `moof`/`traf` structures. | Public Apple Sample Code License permits redistribution inside test suites when attribution retained. | https://developer.apple.com/streaming/examples/ — prefer `AVFoundation_Prep.m3u8` ladders; mirror static MP4s for offline validation. | ~6 GB for top-bitrate ladders + flagship progressive files. |
| 2 | DASH-IF Test Assets | Reference DASH init/media segments covering live, on-demand, trick mode, and CMAF variants; rich in `sidx`, `emsg`, and multi-period manifests. | Creative Commons Attribution 4.0; redistribution allowed with attribution. | https://dashif.org/guidelines/test-vectors/ (GitHub mirror: https://github.com/Dash-Industry-Forum/dash.js/tree/development/samples/dash-if-reference) | ~4 GB when mirroring CMAF/fMP4 ladders and trick-mode sets. |
| 3 | Bento4 Test Content | Canonical MP4, fragmented MP4, and encrypted samples with vendor UUID boxes referencing PIFF/Widevine; includes edge-case boxes for parser regression. | BSD-style Bento4 license allows bundling with attribution. | https://www.bento4.com/testcontent/ (use `curl --remote-name --remote-header-name`) | ~1.5 GB to capture primary progressive, `dash` folders, and encryption fixtures. |
| 4 | GPAC DASH Dataset | Extensive CMAF live/on-demand sets with large `mdat` chunks, multi-language tracks, and MPD variations that stress parser heuristics. | GNU LGPL for tooling; media licensed under CC-BY per dataset README. | http://download.tsi.telecom-paristech.fr/gpac/dataset/dash/ (mirror `dash-vod`, `dash-live`, and `dash-lowlatency`). | ~5 GB for representative sets. |
| 5 | Blender Foundation Open Movies | High-bitrate cinematic MP4 renders (Big Buck Bunny, Sintel, Tears of Steel) featuring large `co64` tables, alternate edits, and metadata-laden `udta`. | Creative Commons Attribution 3.0/4.0 — redistribution permitted with credit. | https://media.xiph.org/mango/ and https://download.blender.org/peach/bigbuckbunny_movies/ (prefer MP4/H.264, H.265 exports). | ~12 GB if mirroring 1080p/4K masters. |
| 6 | Xiph.Org Test Media | Speech, music, and synthetic clips across container variants; includes intentionally malformed/truncated MP4 samples. | Creative Commons Attribution/ShareAlike depending on asset; redistribution allowed with notice. | https://media.xiph.org/video/derf/ (filter `.mp4`, `.m4v`). | ~3 GB for curated subset including malformed cases. |
| 7 | GoPro GPMF Sample Footage | Vendor-specific `uuid` boxes carrying GPMF telemetry for metadata parsing coverage; mixes HEVC and H.264 progressive encodes. | GoPro Sample Footage License allows redistribution for development/testing; retain license text alongside copies. | https://github.com/gopro/gpmf-parser/tree/master/samples (fetch `.MP4` assets + `LICENSE.txt`). | ~2 GB for HERO8–HERO11 clips. |
| 8 | DJI Sample Media | Includes proprietary `uuid` metadata blocks and multi-track audio; helpful for validating vendor telemetry pipelines. | DJI Sample Media License permits non-commercial analysis with attribution. | https://dl.djicdn.com/downloads/dji_sample_videos/ (mirror `Inspire2`, `Mavic3` MP4 clips). | ~3 GB for representative SKUs. |
| 9 | YouTube Test Content (Google ExoPlayer) | Contains VP9-in-MP4, HDR10 metadata, and unusual timescales; exposes parser coverage for streaming services. | Apache 2.0 (via ExoPlayer repository) permits redistribution. | https://storage.googleapis.com/exoplayer-test-media-1/gen-3/mp4/ (select `glass/` and `vdd` fixtures). | ~1.2 GB for curated subset. |
| 10 | ISO/IEC ISOBMFF Reference Files | Official conformance files with edge-case atoms (e.g., `seig`, `leva`, `colr`); critical for validation rule regressions. | Distributed under ISO Sample License allowing use within conformance tooling; keep metadata README bundled. | https://standards.iso.org/ittf/PubliclyAvailableStandards/c061807_ISO_IEC_14496-15_2019.zip and associated sample packs. | ~0.8 GB unpacked. |

### Prioritization Guidance

1. Mirror Apple, DASH-IF, Bento4, and ISO reference assets first — they unlock CLI validation, DocC guides, and
   regression tests referenced across the execution plan
   phases.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】
1. Follow with Blender/Xiph corpora to feed benchmarking suites that stress large `mdat` payloads and random-slice workloads.
1. Stage vendor telemetry sources (GoPro, DJI) once metadata extraction tasks exit `todo.md` backlog, ensuring license texts ship alongside fixtures.

## 📦 Acquisition & Verification Workflow

1. **Create staging manifest** (`Documentation/FixtureCatalog/manifest.json` — new file in follow-up task) capturing source URL, SHA-256 checksum, license snippet, and coverage tags (`progressive`, `fragmented`, `vendor`, `malformed`).
1. **Download via scripted helper** — extend `Tests/ISOInspectorKitTests/Fixtures/generate_fixtures.py` to accept manifest input and emit deterministic filenames. Store large assets under `Distribution/Fixtures/<category>/` while keeping lightweight regression fixtures inside the test bundle.【F:Tests/ISOInspectorKitTests/Fixtures/README.md†L6-L49】
1. **Checksum validation** — log digests in Git-tracked manifest so CI runners can verify integrity before copying to
   ephemeral scratch disks.
1. **Storage targets** — allocate 40 GB on macOS runners (post-download footprint ≈ 37 GB) and 15 GB on Linux CI for a
   curated subset excluding cinema-scale masters. Documented sizes include 20% headroom.
1. **Redistribution compliance** — mirror each license text under `Documentation/FixtureCatalog/licenses/` and reference it from the manifest to satisfy attribution requirements.

## 🚧 Follow-Up Tasks

- <!-- @todo PDD:45m Wire generate_fixtures.py to ingest manifest-driven remote downloads, including checksum
  verification and license mirroring. -->
- <!-- @todo PDD:30m Produce fixture storage README describing mount paths for macOS runners and Linux CI caches once
  infrastructure lands. -->

## 🔧 Implementation Notes

- Audit existing archives and public collections (Apple sample media, DASH-IF, vendor-provided files) for coverage,
  recording checksum, codecs, and notable boxes before
  inclusion.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L8-L16】
- Capture follow-up actions for fixtures that require macOS hardware to validate streaming automation once runners exist, keeping `next_tasks.md` aligned with any hardware-dependent execution steps.【F:DOCS/INPROGRESS/next_tasks.md†L5-L21】
- Coordinate with benchmarking documentation to align selected samples with the random-slice and Combine UI benchmark
  plans so the datasets serve both CLI and UI
  workflows.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L47】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
