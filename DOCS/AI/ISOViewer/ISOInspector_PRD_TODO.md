# PRD & TODO: MP4/QuickTime (ISO BMFF) Parser & Inspector for macOS / iPadOS / iOS

> Goal: Build a native Swift parser and inspector for MP4/QuickTime (ISO BMFF) files, inspired by legacy ISOViewer, with modern UX (SwiftUI), streaming parsing, JSON export, and no third‑party deps.

---

## 1) Scope & Intent

### Objective
Create a **Swift** library (`ISOInspectorKit`) and a **multiplatform SwiftUI app** (`ISOInspector`) that:
- Parses the **box/atom hierarchy** of ISO BMFF (MP4/QuickTime/MOV).
- Validates **structural integrity** (sizes, offsets, containment, versioned fields).
- Extracts key **media structures**: sample tables (`stbl`), codec configs (`avcC/hvcC/esds`), fragmented MP4 (`moof/trun`), indexing (`sidx/mfra`), and metadata (`udta/meta/ilst/keys`).
- Presents a **tree UI**, **details pane**, **hex viewer**, and **JSON export**.
- Runs fully **on-device** (macOS/iPadOS/iOS). **No third-party libraries**.

### Deliverables
- SwiftPM package **ISOInspectorKit** (parsing + validation + export).
- SwiftUI app **ISOInspector** (macOS, iPadOS, iOS) with sandbox-friendly file access.
- (Optional) macOS command tool **isoinspect** for CI/parsing in pipelines.

### Success Criteria
- Opens files from kilobytes to **20+ GB** without OOM (streaming IO).
- Parses at least: `ftyp`, `free/skip`, `mdat`, `moov` (and children), `mvex`, `moof/traf/trun`, `sidx`, `mfra/tfra/mfro`.
- Extracts details for: `avcC`, `hvcC`, `esds`, `stsd`, `stts`, `ctts`, `stsc`, `stsz/stz2`, `stco/co64`, `edts/elst`, `hdlr`, `mdhd/tkhd/mvhd`.
- JSON export of tree/subtree with **byte offsets** and **computed fields**.
- UI: interactive tree, hex with highlighted ranges, search, filters, copy actions.

### Constraints & Assumptions
- **Swift 5.9+**, Swift Concurrency.
- Frameworks: **Foundation**, **SwiftUI**, **UniformTypeIdentifiers**, optional POSIX for `mmap` (only via Foundation `Data.mappedIfSafe`).
- **No network**; all parsing local. **No third‑party deps**.
- Sandboxed file access via pickers and security-scoped bookmarks.
- Targets: macOS 13+, iOS/iPadOS 16+.

---

## 2) Functional Requirements

1. **File IO**
   - Open via file picker / drag-and-drop (macOS) / Files app (iOS/iPadOS).
   - Random-access reads by absolute **offset + length**.
   - Prefer **memory-mapped** reads (`Data(..., .mappedIfSafe)`), fallback to buffered `FileHandle` with seek.
   - Determine file length accurately (64-bit).

2. **Box Parsing (Generic)**
   - Parse header: `size (32)`, `type (fourcc)`, optional `largesize (64)` when `size==1`, optional `uuid`.
   - Maintain `currentOffset` and compute `payloadRange` and `endOffset` safely (overflow-checked).
   - Handle `size==0` (box extends to end-of-file or end-of-parent, per spec interpretations).
   - Support **FullBox** (version:1, flags:24) reading.
   - Distinguish **container** vs **leaf** boxes by `type` registry.

3. **Specific Box Families**
   - **Top-level**: `ftyp`, `moov`, `mdat`, `free`, `skip`, fragmented (`sidx`, `mfra`), `uuid`.
   - **Movie tree (`moov`)**: `mvhd`, `trak` → `tkhd`, `edts/elst`, `mdia` → `mdhd/hdlr/minf` → `dinf/dref`, `stbl` → `stsd`, `stts`, `ctts`, `stsc`, `stsz/stz2`, `stco/co64`, `stss`, `sgpd/sbgp`.
   - **Fragmented**: `mvex/trex`, `moof/mfhd`, `traf/tfhd/tfdt/trun` (+ `senc/saiz/saio` placeholders).
   - **Index/RA**: `sidx`, `mfra/tfra/mfro`.
   - **Codec configs**: `avcC`, `hvcC`, `esds` (DecoderSpecific config).
   - **Metadata**: `udta`, `meta` (handler), `keys`, `ilst`, common `©xyz`, `©day`, etc.

4. **Validation**
   - Header sanity: `size >= headerSize`, `endOffset` within parent, 64-bit overflow checks, progress guarantees.
   - Hierarchy: child range must be **within** parent; no overlapping; iteration is contiguous.
   - avcC/hvcC: `lengthSizeMinusOne ∈ {0,1,2,3}`; SPS/PPS/HVCC arrays consistent.
   - `stbl` basic consistency (counts present and coherent). Advanced cross-table validation is Phase 2.

5. **UI & UX**
   - **Tree**: fourcc, human name, size (human), offset (dec/hex), children count, warnings badge.
   - **Details**: typed fields with inline help.
   - **Hex**: windowed view around selected node; highlight subranges for fields.
   - **Search**: by fourcc/name/offset; **filters** (containers, metadata, fragments, codecs).
   - **Actions**: copy fourcc/offset/size; export JSON of node/subtree/full tree.
   - **Navigation**: jump to referenced boxes (e.g., from `stsd` entry to `avcC`).

6. **Export**
   - JSON export with `fourcc`, `offset`, `size`, `version`, `flags`, and parsed fields; recursive `children`.
   - (Phase 2) CSV export of flat list (offset,size,fourcc,parentPath).

7. **Performance**
   - Streaming parse; `mdat` skipped by seek.
   - Hex viewer reads windowed slices only (e.g., ±64 KiB).

8. **Testing**
   - Fixture set: MP4, MOV, fMP4, DASH segments, large `co64`, metadata-heavy, malformed (truncated, bogus sizes).
   - Snapshot JSON tests for small files.

---

## 3) Non-Functional Requirements
- **Reliability:** Deterministic parsing, explicit error types (I/O vs structural).
- **Security:** Bounds-checked reads; no execution of external code; no network.
- **Performance:** Sub-second parse for small files; scalable to multi-GB within a few seconds.
- **UX:** Smooth tree/hex scrolling; responsive during parse (progress events optional).
- **Accessibility:** Dynamic Type, VoiceOver labels, keyboard navigation (macOS/iPadOS).

---

## 4) Architecture

### 4.1 Packages/Targets
- **ISOInspectorKit** (SwiftPM)
  - `IO`: `RandomAccessReader` protocol; `MappedReader`, `FileHandleReader` implementations.
  - `Core`: `BoxHeader`, `BoxNode`, `BoxParser`, `FullBoxReader`, `Registry`.
  - `Parsers`: specific boxes (structured per family).
  - `Validation`: structural + advisory semantic checks.
  - `Export`: JSON (and CSV in Phase 2).
  - `Hex`: `HexSliceProvider` with safe windowing.

- **ISOInspector** (SwiftUI App)
  - Views: `DocumentPicker`, `TreeView`, `DetailsView`, `HexView`, `SearchBar`, `Toolbar`.
  - ViewModels: `DocumentVM`, `NodeVM`, `HexVM`.
  - Glue: `ParserRunner` to stream parse on background queue, publish tree.

### 4.2 Data Flow
1. User picks file → `RandomAccessReader` created (mapped or handle).
2. `BoxParser.parseRoot()` walks boxes from offset 0..EOF, building `BoxNode` tree.
3. UI binds to tree; selecting a node loads details and hex slice on-demand.
4. Export encodes selected node/tree to JSON.

---

## 5) Detailed TODO (execution-ready, без кода)

> Update (2025-10-07): VR-006 research logging now persists unknown boxes to a shared JSON research log exposed through the CLI `--research-log` option and UI consumers.


### ✅ Completed via Task Archive
- [x] [01_B1_Chunked_File_Reader](../../TASK_ARCHIVE/01_B1_Chunked_File_Reader)
- [x] [02_B2_Box_Header_Decoder](../../TASK_ARCHIVE/02_B2_Box_Header_Decoder)
- [x] [03_B2_Plus_Streaming_Interface_Evaluation](../../TASK_ARCHIVE/03_B2_Plus_Streaming_Interface_Evaluation)
- [x] [04_B3_ParsePipeline_Live_Streaming](../../TASK_ARCHIVE/04_B3_ParsePipeline_Live_Streaming)
- [x] [05_B3_Puzzle1_ParsePipeline_Live_Integration](../../TASK_ARCHIVE/05_B3_Puzzle1_ParsePipeline_Live_Integration)
- [x] [06_B4_MP4RA_Metadata_Integration](../../TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration)
- [x] [07_R1_MP4RA_Catalog_Refresh](../../TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh)
- [x] [08_Metadata_Driven_Validation_and_Reporting](../../TASK_ARCHIVE/08_Metadata_Driven_Validation_and_Reporting)
- [x] [09_B4_Metadata_Follow_Up_Planning](../../TASK_ARCHIVE/09_B4_Metadata_Follow_Up_Planning)
- [x] [10_B5_VR003_Metadata_Comparison_Rule](../../TASK_ARCHIVE/10_B5_VR003_Metadata_Comparison_Rule)
- [x] [11_B5_VR003_Metadata_Validation](../../TASK_ARCHIVE/11_B5_VR003_Metadata_Validation)
- [x] [12_B5_VR001_VR002_Structural_Validation](../../TASK_ARCHIVE/12_B5_VR001_VR002_Structural_Validation)
- [x] [13_B5_VR004_VR005_Ordering_Validation](../../TASK_ARCHIVE/13_B5_VR004_VR005_Ordering_Validation)
- [x] [14_B5_VR006_Research_Logging](../../TASK_ARCHIVE/14_B5_VR006_Research_Logging)
- [x] [15_Monitor_VR006_Research_Log_Adoption](../../TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption)
- [x] [16_Integrate_ResearchLogMonitor_SwiftUI_Previews](../../TASK_ARCHIVE/16_Integrate_ResearchLogMonitor_SwiftUI_Previews)
- [x] [17_Extend_VR006_Telemetry_UI_Smoke_Tests](../../TASK_ARCHIVE/17_Extend_VR006_Telemetry_UI_Smoke_Tests)
- [x] [18_C1_Combine_Bridge_and_State_Stores](../../TASK_ARCHIVE/18_C1_Combine_Bridge_and_State_Stores)
- [x] [19_C2_Tree_View_Virtualization](../../TASK_ARCHIVE/19_C2_Tree_View_Virtualization)
- [x] [20_C2_Tree_View_Virtualization_Follow_Up](../../TASK_ARCHIVE/20_C2_Tree_View_Virtualization_Follow_Up)
- [x] [21_C2_Integrate_Outline_Explorer_With_Streaming](../../TASK_ARCHIVE/21_C2_Integrate_Outline_Explorer_With_Streaming)
- [x] [22_C2_Extend_Outline_Filters](../../TASK_ARCHIVE/22_C2_Extend_Outline_Filters)
- [x] [23_C3_Detail_and_Hex_Inspectors](../../TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors)
- [x] [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges)
- [x] [25_B4_C2_Category_Filtering](../../TASK_ARCHIVE/25_B4_C2_Category_Filtering)
- [x] [26_F1_Fixtures_and_B4_MP4RA](../../TASK_ARCHIVE/26_F1_Fixtures_and_B4_MP4RA)
- [x] [27_F1_Expand_Fixture_Catalog](../../TASK_ARCHIVE/27_F1_Expand_Fixture_Catalog)
- [x] [28_B6_JSON_and_Binary_Export_Modules](../../TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules)
- [x] [29_D3_CLI_Export_Commands](../../TASK_ARCHIVE/29_D3_CLI_Export_Commands)
- [x] [30_Summary_of_Work_2025-10-10](../../TASK_ARCHIVE/30_Summary_of_Work_2025-10-10)
- [x] [31_A3_DocC_Catalog_Setup](../../TASK_ARCHIVE/31_A3_DocC_Catalog_Setup)
- [x] [35_A3_DocC_Tutorial_Expansion](../../TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion)
- [x] [33_C4_CoreData_Annotation_Persistence](../../TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence)
- [x] [34_E3_CoreData_Migration_Planning](../../TASK_ARCHIVE/34_E3_CoreData_Migration_Planning)


- [x] A1. Define `RandomAccessReader` protocol: `length`, `read(at:count:)`, endian helpers (`readU32BE`, `readU64BE`, `readFourCC`). _(Completed in [Task B1 — Chunked File Reader](../../TASK_ARCHIVE/01_B1_Chunked_File_Reader/B1_Chunked_File_Reader.md))._
- [ ] A2. Implement `MappedReader` using `Data(contentsOf:options:.mappedIfSafe)`; provide bounds-checked slices.
- [x] A3. Implement `FileHandleReader` using `FileHandle` seek+read; ensure thread-safety (serial queue). _(Delivered with the chunked reader implementation in [Task B1](../../TASK_ARCHIVE/01_B1_Chunked_File_Reader/B1_Chunked_File_Reader.md))._
- [ ] A4. Add error types: `IOError`, `BoundsError`, `OverflowError`.
- [ ] A5. Micro-benchmarks: random slice reads on large files, compare mapped vs handle.

- [x] B1. Define `BoxHeader`: `type: FourCC`, `size32`, `largesize64?`, `headerSize`, `payloadRange`, `startOffset`, `endOffset`, `uuid?`. _(Delivered via [02_B2_Box_Header_Decoder](../../TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder.md))._
- [ ] B2. Define `BoxNode`: `header`, `children: [BoxNode]`, `payload: Payload?`, `warnings: [Warning]`.
- [x] B3. Implement `readBoxHeader(at:)` supporting: size==0 (to EOF/parent end), size==1 (largesize), `uuid` type. _(Covered by [02_B2_Box_Header_Decoder](../../TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder.md) and validated in downstream streaming integration tasks.)_
- [x] B4. Implement container iteration (`parseContainer(parentRange:)`) with forward-progress guard and max-depth limit. _(Shipped with [05_B3_Puzzle1_ParsePipeline_Live_Integration](../../TASK_ARCHIVE/05_B3_Puzzle1_ParsePipeline_Live_Integration/05_B3_Puzzle1_ParsePipeline_Live_Integration.md))._
- [ ] B5. Introduce `FullBoxReader` for (version,flags) extraction.
- [ ] B6. Create `BoxParserRegistry`: map fourcc → parser; default: container? or leaf; unknown: opaque leaf.

### Phase C — Specific Parsers (Baseline)
- [ ] C1. `ftyp`: major_brand, minor_version, compatible_brands[].
- [ ] C2. `mvhd`: timescale, duration(32/64), rate, volume, matrix.
- [ ] C3. `tkhd`: flags-driven size; track_id; duration; width/height.
- [ ] C4. `mdhd`: creation/modification times, timescale, duration, language.
- [ ] C5. `hdlr`: handler_type, name.
- [ ] C6. `stsd`: entry_count; generic sample_entry header; detect visual/audio entry.
- [ ] C7. `stts`, `ctts`: entry arrays.
- [ ] C8. `stsc`: sample-to-chunk entries.
- [ ] C9. `stsz/stz2`: sample sizes.
- [ ] C10. `stco/co64`: chunk offsets (32/64).
- [ ] C11. `stss`: sync sample numbers.
- [ ] C12. `dinf/dref`: data reference entries.
- [ ] C13. `smhd/vmhd`: media headers.
- [ ] C14. `edts/elst`: edit list entries.
- [ ] C15. Metadata: `udta`, `meta` (handler), `keys`, `ilst` (basic types).
- [ ] C16. Codec configs:
  - [ ] C16.1 `avcC`: version/profile/level, `lengthSizeMinusOne`, SPS/PPS counts + lengths.
  - [ ] C16.2 `hvcC`: profile/compat/level, arrays (vps/sps/pps), `lengthSizeMinusOne`.
  - [ ] C16.3 `esds`: ES_Descriptor → DecoderSpecific (AudioSpecificConfig fields mapped).

- [ ] C17. `mdat`: record offset/size (skip payload).
- [ ] C18. `free/skip`: opaque pass-through.

- [ ] D1. `mvex/trex`: defaults.
- [ ] D2. `moof/mfhd`: sequence number.
- [ ] D3. `traf/tfhd/tfdt/trun`: parse via flags; sample_count; optional data_offset; sizes.
- [x] D4. `sidx`: refs (sizes/durations), earliest_presentation_time, timescale. _(Completed — see `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/51_D4_CLI_Batch_Mode.md`.)_
- [ ] D5. `mfra/tfra/mfro`: random access table.
- [ ] D6. Recognize `senc/saio/saiz` (CENC placeholders), capture sizes/offsets only.

### Phase E — Validation
- [ ] E1. Enforce parent containment and non-overlap.
- [ ] E2. Detect zero/negative progress loops; cap nesting depth. _(In Progress — alignment with app shell wiring to surface live parser progress.)_
- [ ] E3. Warn on unusual top-level ordering (advisory).
- [ ] E4. Verify `avcC/hvcC` invariants; flag inconsistencies.
- [ ] E5. Basic `stbl` coherence checks (counts nonzero, arrays parse).
- [x] E6. Add streaming structural validation rules VR-001 (header sizing) and VR-002 (container closure).

### Phase F — Export & Hex
- [x] F1. JSON export: encode tree with offsets/sizes/parsed fields. _(Implemented by [28_B6_JSON_and_Binary_Export_Modules](../../TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/28_B6_JSON_and_Binary_Export_Modules.md))._
- [x] F2. Configure performance benchmarks for large files. **CLI validation and app bridge benchmarks enforce scaled latency budgets with XCTest metrics harnesses.** _(macOS Combine benchmark capture remains **Blocked** pending macOS hardware — see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md` and `DOCS/INPROGRESS/next_tasks.md`.)_
- [x] F3. Hex slice provider: bounded reads for selected node; window sizing and caching. _(Delivered via [23_C3_Detail_and_Hex_Inspectors](../../TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/23_C3_Detail_and_Hex_Inspectors.md) and refined in [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/Summary_of_Work.md))._
- [x] F4. Field-to-hex mapping metadata for details highlighting. _(See [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/Summary_of_Work.md))._

### Phase F — Documentation & Onboarding
- [x] F3. Author developer onboarding guide and API reference. *(Completed — see `Docs/Guides/DeveloperOnboarding.md` and `DOCS/TASK_ARCHIVE/53_F3_Developer_Onboarding_Guide/`.)*
- [x] F4. Produce user manual covering CLI and app workflows. _(Completed — manuals live in `Documentation/ISOInspector.docc/Manuals/App.md` and `Documentation/ISOInspector.docc/Manuals/CLI.md`.)_

- [x] G1. File open: `.fileImporter` (iOS/iPadOS), `NSOpenPanel` (macOS); UTTypes: movie/mp4/quicktime. _(Completed via [E1_Build_SwiftUI_App_Shell](../../TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/E1_Build_SwiftUI_App_Shell.md))._
- [x] G2. Tree view (Outline) with badges for warnings/errors. _(Implemented in [19_C2_Tree_View_Virtualization](../../TASK_ARCHIVE/19_C2_Tree_View_Virtualization/19_C2_Tree_View_Virtualization.md) and its follow-ups.)_
- [x] G3. Details view: sectioned fields; copy actions (fourcc/offset/size). _(Delivered in [23_C3_Detail_and_Hex_Inspectors](../../TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/23_C3_Detail_and_Hex_Inspectors.md))._
- [x] G4. Hex view: offset gutter, ASCII column, selection; fetch via `HexSliceProvider`. _(Refined through [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/Summary_of_Work.md))._
- [x] G5. Search & filters; quick toggles (containers/codec/meta/frag). _(Expanded in [22_C2_Extend_Outline_Filters](../../TASK_ARCHIVE/22_C2_Extend_Outline_Filters/C2_Extend_Outline_Filters.md))._
- [ ] G6. Export actions (JSON subtree/full).
- [ ] G7. State management: `DocumentVM` holds root; `NodeVM` for selection; `HexVM` for slice & highlight.
- [ ] G8. Accessibility & keyboard shortcuts (macOS/iPadOS).
- [x] Task E3. Implement session persistence so the app restores open files, annotations, and window layouts on relaunch. **(Completed — see `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/`.)**

### Phase H — Fixtures & Tests
- [x] H1. Fixture corpus: MP4 (non-frag), MOV, fMP4 segment, DASH init+media, huge `mdat`, malformed cases.
- [ ] H2. Unit tests: headers, container boundaries, specific box field extraction.
- [ ] H3. Snapshot tests: JSON exports of small fixtures.
- [ ] H4. Performance tests: parse time & memory cap (<100 MB for 20 GB file).
- [x] H5. macOS SwiftUI automation covering streaming default selection and synchronized detail updates. Implemented via
  `ParseTreeStreamingSelectionAutomationTests`, which hosts the app view hierarchy on macOS and asserts outline/detail state
  during a streaming parse. See `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md` for the execution
  note.
  - Hardware validation run remains **Blocked** pending macOS runner — tracked in `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md` and `DOCS/INPROGRESS/next_tasks.md`.

### Phase I — Packaging & Release
- [x] I1. SwiftPM product definitions (library + app).
- [x] I2. App entitlements for file access; sandbox. *(Completed by E4 distribution scaffolding — see `Distribution/Entitlements/` and `scripts/notarize_app.sh` for notarization tooling.)*
- [x] I2.a Evaluate whether Apple Events automation is required for notarized builds and extend entitlements safely. *(Archived — see `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/56_Distribution_Apple_Events_Notarization_Assessment.md`.)*
- [ ] I3. App theming (icon, light/dark).
- [ ] I4. README with feature matrix, supported boxes, screenshots.
- [ ] I5. v0.1.0 Release notes; distribution (TestFlight/DMG notarization).

---

## 6) JSON Export Schema (baseline)

```json
{
  "type": "ISOInspector.Tree",
  "version": 1,
  "file": {
    "name": "example.mp4",
    "length": 123456789
  },
  "root": {
    "fourcc": "root",
    "offset": 0,
    "size": 123456789,
    "children": [
      {
        "fourcc": "ftyp",
        "offset": 0,
        "size": 24,
        "fields": {
          "major_brand": "isom",
          "minor_version": 512,
          "compatible_brands": ["isom","iso2","avc1","mp41"]
        }
      }
    ]
  }
}
```

---

## 7) Acceptance & SLA
- Parses ≥95% of fixtures successfully; malformed inputs produce deterministic errors, not crashes.
- Memory footprint **<100 MB** on 20 GB file (due to streaming).
- JSON export for full tree ≤2 s for a 1–2 GB file on Apple Silicon.
- UI responsive; hex and tree scroll smoothly.

---

## 8) Risks & Mitigations
- **Huge `mdat`** → never load; skip by seek.
- **Malformed size loops** → enforce progress & max depth.
- **Overflow bugs** → centralize 64-bit math and bounds checks; tests for edges.
- **Sandbox access** → use security-scoped bookmarks (recents).

---

## 9) Roadmap (Post‑MVP)
- CENC/CBCS awareness (`schm/schi/tenc`).
- Keyframe timeline and time-to-byte visualizer.
- Side-by-side file diff.
- Optional write/edit capabilities (hex patching) with safety rails.
