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

### ✅ Completed via Task Archive
- [x] [01_B1_Chunked_File_Reader](../../../../../TASK_ARCHIVE/01_B1_Chunked_File_Reader)
- [x] [02_B2_Box_Header_Decoder](../../../../../TASK_ARCHIVE/02_B2_Box_Header_Decoder)
- [x] [03_B2_Plus_Streaming_Interface_Evaluation](../../../../../TASK_ARCHIVE/03_B2_Plus_Streaming_Interface_Evaluation)
- [x] [04_B3_ParsePipeline_Live_Streaming](../../../../../TASK_ARCHIVE/04_B3_ParsePipeline_Live_Streaming)
- [x] [05_B3_Puzzle1_ParsePipeline_Live_Integration](../../../../../TASK_ARCHIVE/05_B3_Puzzle1_ParsePipeline_Live_Integration)
- [x] [06_B4_MP4RA_Metadata_Integration](../../../../../TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration)
- [x] [07_R1_MP4RA_Catalog_Refresh](../../../../../TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh)
- [x] [08_Metadata_Driven_Validation_and_Reporting](../../../../../TASK_ARCHIVE/08_Metadata_Driven_Validation_and_Reporting)
- [x] [09_B4_Metadata_Follow_Up_Planning](../../../../../TASK_ARCHIVE/09_B4_Metadata_Follow_Up_Planning)
- [x] [10_B5_VR003_Metadata_Comparison_Rule](../../../../../TASK_ARCHIVE/10_B5_VR003_Metadata_Comparison_Rule)
- [x] [11_B5_VR003_Metadata_Validation](../../../../../TASK_ARCHIVE/11_B5_VR003_Metadata_Validation)
- [x] [12_B5_VR001_VR002_Structural_Validation](../../../../../TASK_ARCHIVE/12_B5_VR001_VR002_Structural_Validation)
- [x] [13_B5_VR004_VR005_Ordering_Validation](../../../../../TASK_ARCHIVE/13_B5_VR004_VR005_Ordering_Validation)
- [x] [14_B5_VR006_Research_Logging](../../../../../TASK_ARCHIVE/14_B5_VR006_Research_Logging)
- [x] [15_Monitor_VR006_Research_Log_Adoption](../../../../../TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption)
- [x] [16_Integrate_ResearchLogMonitor_SwiftUI_Previews](../../../../../TASK_ARCHIVE/16_Integrate_ResearchLogMonitor_SwiftUI_Previews)
- [x] [17_Extend_VR006_Telemetry_UI_Smoke_Tests](../../../../../TASK_ARCHIVE/17_Extend_VR006_Telemetry_UI_Smoke_Tests)
- [x] [18_C1_Combine_Bridge_and_State_Stores](../../../../../TASK_ARCHIVE/18_C1_Combine_Bridge_and_State_Stores)
- [x] [19_C2_Tree_View_Virtualization](../../../../../TASK_ARCHIVE/19_C2_Tree_View_Virtualization)
- [x] [20_C2_Tree_View_Virtualization_Follow_Up](../../../../../TASK_ARCHIVE/20_C2_Tree_View_Virtualization_Follow_Up)
- [x] [21_C2_Integrate_Outline_Explorer_With_Streaming](../../../../../TASK_ARCHIVE/21_C2_Integrate_Outline_Explorer_With_Streaming)
- [x] [22_C2_Extend_Outline_Filters](../../../../../TASK_ARCHIVE/22_C2_Extend_Outline_Filters)
- [x] [23_C3_Detail_and_Hex_Inspectors](../../../../../TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors)
- [x] [24_C3_Highlight_Field_Subranges](../../../../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges)
- [x] [25_B4_C2_Category_Filtering](../../../../../TASK_ARCHIVE/25_B4_C2_Category_Filtering)

### Phase A — IO Foundations
- [ ] A1. Define `RandomAccessReader` protocol: `length`, `read(at:count:)`, endian helpers (`readU32BE`, `readU64BE`, `readFourCC`).
- [x] A2. Implement `MappedReader` using `Data(contentsOf:options:.mappedIfSafe)`; provide bounds-checked slices.
- [ ] A3. Implement `FileHandleReader` using `FileHandle` seek+read; ensure thread-safety (serial queue).
- [ ] A4. Add error types: `IOError`, `BoundsError`, `OverflowError`.
- [ ] A5. Micro-benchmarks: random slice reads on large files, compare mapped vs handle.

### Phase B — Core Box Model & Parser
- [ ] B1. Define `BoxHeader`: `type: FourCC`, `size32`, `largesize64?`, `headerSize`, `payloadRange`, `startOffset`, `endOffset`, `uuid?`.
- [ ] B2. Define `BoxNode`: `header`, `children: [BoxNode]`, `payload: Payload?`, `warnings: [Warning]`.
- [ ] B3. Implement `readBoxHeader(at:)` supporting: size==0 (to EOF/parent end), size==1 (largesize), `uuid` type.
- [ ] B4. Implement container iteration (`parseContainer(parentRange:)`) with forward-progress guard and max-depth limit.
- [ ] B5. Introduce `FullBoxReader` for (version,flags) extraction.
- [ ] B6. Create `BoxParserRegistry`: map fourcc → parser; default: container? or leaf; unknown: opaque leaf.

### Phase C — Specific Parsers (Baseline)
> **Priority Update (2025-10-20):** Phase C parser work is now a **P0 blocker** for the upcoming milestone. Treat every unchecked item below as urgent and schedule accordingly.
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

### Phase D — Fragmentation & Indexes
- [ ] D1. `mvex/trex`: defaults.
- [ ] D2. `moof/mfhd`: sequence number.
- [ ] D3. `traf/tfhd/tfdt/trun`: parse via flags; sample_count; optional data_offset; sizes.
- [x] D4. `sidx`: refs (sizes/durations), earliest_presentation_time, timescale. _(Completed — see `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/51_D4_CLI_Batch_Mode.md`.)_
- [ ] D5. `mfra/tfra/mfro`: random access table.
- [ ] D6. Recognize `senc/saio/saiz` (CENC placeholders), capture sizes/offsets only.

### Phase E — Validation
- [ ] E1. Enforce parent containment and non-overlap.
- [ ] E2. Detect zero/negative progress loops; cap nesting depth.
- [ ] E3. Warn on unusual top-level ordering (advisory).
- [ ] E4. Verify `avcC/hvcC` invariants; flag inconsistencies.
- [ ] E5. Basic `stbl` coherence checks (counts nonzero, arrays parse).

### Phase F — Export & Hex
- [ ] F1. JSON export: encode tree with offsets/sizes/parsed fields.
- [x] F2. Configure performance benchmarks for large files. **CLI validation and app bridge benchmarks enforce scaled latency budgets with XCTest metrics harnesses.**
- [ ] F3. Hex slice provider: bounded reads for selected node; window sizing and caching.
- [ ] F4. Field-to-hex mapping metadata for details highlighting.

### Phase G — SwiftUI App
- [ ] G1. File open: `.fileImporter` (iOS/iPadOS), `NSOpenPanel` (macOS); UTTypes: movie/mp4/quicktime.
- [ ] G2. Tree view (Outline) with badges for warnings/errors.
- [ ] G3. Details view: sectioned fields; copy actions (fourcc/offset/size).
- [ ] G4. Hex view: offset gutter, ASCII column, selection; fetch via `HexSliceProvider`.
- [ ] G5. Search & filters; quick toggles (containers/codec/meta/frag).
- [ ] G6. Export actions (JSON subtree/full).
- [ ] G7. State management: `DocumentVM` holds root; `NodeVM` for selection; `HexVM` for slice & highlight.
- [ ] G8. Accessibility & keyboard shortcuts (macOS/iPadOS).

### Phase H — Fixtures & Tests
- [ ] H1. Fixture corpus: MP4 (non-frag), MOV, fMP4 segment, DASH init+media, huge `mdat`, malformed cases.
- [ ] H2. Unit tests: headers, container boundaries, specific box field extraction. **(In Progress — see `DOCS/INPROGRESS/H2_Unit_Tests.md`.)**
- [ ] H3. Snapshot tests: JSON exports of small fixtures.
- [ ] H4. Performance tests: parse time & memory cap (<100 MB for 20 GB file).

### Phase I — Packaging & Release
- [ ] I1. SwiftPM product definitions (library + app).
- [ ] I2. App entitlements for file access; sandbox.
- [ ] I3. App theming (icon, light/dark).
- [ ] I4. README with feature matrix, supported boxes, screenshots.
- [ ] I5. v0.1.0 Release notes; distribution (TestFlight/DMG notarization). _(In Progress — see `DOCS/INPROGRESS/I5_v0_1_0_Release_Notes.md`.)_

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
