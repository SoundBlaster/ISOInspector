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
   - **Error handling**: surface document load failures with retry/dismiss controls via the app shell banner. *(Completed ✅ — see `DOCS/TASK_ARCHIVE/66_E5_Surface_Document_Load_Failures/Summary_of_Work.md`.)*

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


### 🚧 In Progress
- [x] T3.4 — Placeholder Nodes for Missing Children. _(Completed — synthetic nodes surface expected-but-absent structures with tolerant parsing issues; see `DOCS/TASK_ARCHIVE/190_T3_4_Placeholder_Nodes_for_Missing_Children/Summary_of_Work.md` for the delivery recap.)_
  - Ensure placeholder nodes cooperate with the contextual status labeling pass (T3.5) so severity and remediation copy stay aligned across the outline and Integrity panes.
  - Capture validation-driven heuristics for which children warrant placeholders and document the fallback behaviors in the PRD to unblock parser wiring.
- [x] T3.5 — Contextual Status Labels. _(Completed — outline rows and detail inspector now display synchronized status chips for tolerant parsing metadata; see `DOCS/TASK_ARCHIVE/191_T3_5_Contextual_Status_Labels/Summary_of_Work.md` for scope.)_
- [x] T3.3 — Integrity Detail Pane. _(Completed — see `DOCS/TASK_ARCHIVE/188_T3_3_Integrity_Detail_Pane/Summary_of_Work.md` for implementation recap.)_
- [x] D3 — `traf/tfhd/tfdt/trun` fragment run parsing and validation scaffolding. _(Completed — see `DOCS/TASK_ARCHIVE/137_D3_traf_tfhd_tfdt_trun_Parsing/Summary_of_Work.md` for the latest fragment parsing delivery and follow-up notes.)_
- [x] B5 — Introduce `FullBoxReader` for (version,flags) extraction. **(Completed — helper, tests, and parser refactors documented in `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/B5_FullBoxReader.md` and `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/Summary_of_Work.md`.)**
- [x] C6 — Integrate `ResearchLogMonitor` audit results into SwiftUI previews rendering VR-006 research log entries. _(Completed — see `DOCS/TASK_ARCHIVE/C6_Integrate_ResearchLogMonitor_Previews/Summary_of_Work.md`.)_
- [x] C7 — Connect persisted bookmark diff entities to resolved bookmark records once reconciliation rules are finalized. _(Completed — see `DOCS/TASK_ARCHIVE/77_C7_Connect_Bookmark_Diffs_to_Resolved_Bookmarks/Summary_of_Work.md`.)_


- [x] ♻️ Snapshot & CLI Fixture Maintenance — Keep JSON export baselines and CLI expectations refreshed whenever schema or presentation changes are intentional. _(Completed — see `DOCS/TASK_ARCHIVE/178_Snapshot_and_CLI_Fixture_Maintenance/Summary_of_Work.md`; regenerate via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests` when schemas change.)_

- [x] A1. Define `RandomAccessReader` protocol: `length`, `read(at:count:)`, endian helpers (`readU32BE`, `readU64BE`, `readFourCC`). _(Completed in [Task B1 — Chunked File Reader](../../TASK_ARCHIVE/01_B1_Chunked_File_Reader/B1_Chunked_File_Reader.md))._
- [x] A2. Implement `MappedReader` using `Data(contentsOf:options:.mappedIfSafe)`; provide bounds-checked slices. *(Delivered — see `DOCS/TASK_ARCHIVE/61_A2_Implement_MappedReader/Summary_of_Work.md`.)*
- [x] A3. Implement `FileHandleReader` using `FileHandle` seek+read; ensure thread-safety (serial queue). _(Delivered with the chunked reader implementation in [Task B1](../../TASK_ARCHIVE/01_B1_Chunked_File_Reader/B1_Chunked_File_Reader.md))._
- [x] A4. Add error types: `IOError`, `BoundsError`, `OverflowError`. _(Completed — see `DOCS/TASK_ARCHIVE/62_A4_RandomAccessReader_Error_Types/Summary_of_Work.md`.)_
- [x] A5. Micro-benchmarks: random slice reads on large files, compare mapped vs handle. **(Completed — see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/`).**

- [x] B1. Define `BoxHeader`: `type: FourCC`, `size32`, `largesize64?`, `headerSize`, `payloadRange`, `startOffset`, `endOffset`, `uuid?`. _(Delivered via [02_B2_Box_Header_Decoder](../../TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder.md))._
- [x] B2. Define `BoxNode`: `header`, `children: [BoxNode]`, `payload: Payload?`, `warnings: [Warning]`. _(Completed — see `DOCS/TASK_ARCHIVE/158_B2_Define_BoxNode/Summary_of_Work.md` for the BoxNode aggregate rollout recap and follow-up notes.)_
- [x] B2+. AsyncSequence event stream integration for `ParsePipeline`, wiring the live streaming interface for CLI and SwiftUI consumers. _(Completed — see `DOCS/TASK_ARCHIVE/176_B2_Plus_AsyncSequence_Event_Stream/Summary_of_Work.md` for implementation recap.)_
- [x] B3. Implement `readBoxHeader(at:)` supporting: size==0 (to EOF/parent end), size==1 (largesize), `uuid` type. _(Covered by [02_B2_Box_Header_Decoder](../../TASK_ARCHIVE/02_B2_Box_Header_Decoder/B2_Box_Header_Decoder.md) and validated in downstream streaming integration tasks.)_
- [x] B4. Implement container iteration (`parseContainer(parentRange:)`) with forward-progress guard and max-depth limit. _(Shipped with [05_B3_Puzzle1_ParsePipeline_Live_Integration](../../TASK_ARCHIVE/05_B3_Puzzle1_ParsePipeline_Live_Integration/05_B3_Puzzle1_ParsePipeline_Live_Integration.md))._
- [x] B5. Introduce `FullBoxReader` for (version,flags) extraction. **(Completed — helper, tests, and parser refactors documented in `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/B5_FullBoxReader.md` and `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/Summary_of_Work.md`.)**
- [x] B6. Create `BoxParserRegistry`: map fourcc → parser; default: container? or leaf; unknown: opaque leaf. **(Completed — placeholder payload fallback and snapshot updates documented in `DOCS/TASK_ARCHIVE/132_B6_Box_Parser_Registry/Summary_of_Work.md`.)**

### Phase C — Specific Parsers (Baseline)
> **Priority Update (2025-10-20):** Phase C parser work is now a **P0 blocker** for the upcoming milestone. Treat every unchecked item below as urgent and schedule accordingly.
> **Priority Escalation (2025-10-23):** Outstanding items called out by program management — **C2, C3, C8–C15** — are now classified as **Critical P0+** and must be prioritized above all other work until completed.
- [x] C1. `ftyp`: major_brand, minor_version, compatible_brands[]. **(Completed — see `DOCS/TASK_ARCHIVE/99_C1_ftyp_Box_Parser/Summary_of_Work.md`.)**
- [x] 🔴 **P0+** C2. `mvhd`: timescale, duration(32/64), rate, volume, matrix. **(Completed — parser, matrix decoding, and snapshot updates documented in `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/C2_mvhd_Movie_Header_Parser.md`.)**
- [x] 🔴 **P0+** C3. `tkhd`: flags-driven size; track_id; duration; width/height. _(Completed — parser detail, fixtures, and snapshots documented in `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/Summary_of_Work.md`.)_
- [x] C4. `mdhd`: creation/modification times, timescale, duration, language. **(Completed — `BoxParserRegistry` now registers the parser; see `DOCS/TASK_ARCHIVE/95_C4_mdhd_Media_Header_Parser/Summary_of_Work.md`.)**
- [x] C5. `hdlr`: handler_type, name. **(Completed — see `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md`.)**
- [x] C6. `stsd`: entry_count; generic sample_entry header; detect visual/audio entry. *(Completed — see `DOCS/TASK_ARCHIVE/97_C6_stsd_Sample_Description_Parser/`.)*
- [x] C7. Connect persisted bookmark diff entities to resolved bookmark records once reconciliation rules are finalized. _(Completed — see `DOCS/TASK_ARCHIVE/77_C7_Connect_Bookmark_Diffs_to_Resolved_Bookmarks/Summary_of_Work.md`.)_
- [x] 🔴 **P0+** C8. `stsc`: sample-to-chunk entries. _(Completed — see `DOCS/TASK_ARCHIVE/109_C8_stsc_Sample_To_Chunk_Parser/Summary_of_Work.md`.)_
- [x] 🔴 **P0+** C9. `stsz/stz2`: sample sizes. **(Completed — see `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/Summary_of_Work.md` for parser delivery notes.)**
- [x] 🟢 **P0+** C10. `stco/co64`: chunk offsets (32/64). **(Completed — see `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/C10_stco_co64_Chunk_Offset_Parser.md` and `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/Summary_of_Work.md`.)**
- [x] 🔴 **P0+** C11. `stss`: sync sample numbers. _(Completed — see `DOCS/TASK_ARCHIVE/115_C11_stss_Sync_Sample_Table/Summary_of_Work.md`.)_
- [x] 🔴 **P0+** C12. `dinf/dref`: data reference entries. _(Completed — parsers, tests, and exports documented in `DOCS/TASK_ARCHIVE/117_C12_dinf_dref_Data_Reference_Parser/Summary_of_Work.md` with implementation notes recorded in `DOCS/TASK_ARCHIVE/117_C12_dinf_dref_Data_Reference_Parser/C12_dinf_dref_Data_Reference_Parser.md`.)_
- [x] 🟢 **P0+** C13. `smhd/vmhd`: media headers. **(Completed — balance, graphics mode, and opcolor metadata now flow through `BoxParserRegistry`; see `DOCS/TASK_ARCHIVE/118_C13_Surface_smhd_vmhd_Media_Header_Fields/Summary_of_Work.md`.)**
- [x] 🔴 **P0+** C14. `edts/elst`: edit list entries. _(Scope documented in `DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope/C14a_Finalize_Edit_List_Scope.md`; parser implementation archived in `DOCS/TASK_ARCHIVE/121_C14b_Implement_elst_Parser/C14b_Implement_elst_Parser.md`, with validation and fixture work archived in `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/`.)_ **(Completed — VR-014 fixtures, exports, and snapshots refreshed in `DOCS/TASK_ARCHIVE/123_C14d_Refresh_Edit_List_Fixtures/Summary_of_Work.md` with rollout notes mirrored in `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/Summary_of_Work.md`.)**
- [x] 🔴 **P0+** C15. Metadata: `udta`, `meta` (handler), `keys`, `ilst` (basic types). **(Completed — see `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/C15_Metadata_Box_Coverage.md` and `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/Summary_of_Work.md`.)**
  > **Completed 2025-10-20:** Expanded metadata value decoding coverage for additional `ilst` data types so CLI exports render booleans, floating-point values, and common binary payloads. See `DOCS/TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/C15_Metadata_Value_Decoding_Expansion.md` and `DOCS/TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/Summary_of_Work.md` for implementation notes.
  > **Follow-up:** Surface remaining MP4RA metadata value types (e.g., GIF/TIFF/image variants, signed fixed-point) when fixtures land — tracked via `@todo` in `BoxParserRegistry+Metadata.swift`, `todo.md`, and `DOCS/INPROGRESS/next_tasks.md`. _(Completed — see `DOCS/TASK_ARCHIVE/129_C15_Metadata_Value_Type_Expansion/C15_Metadata_Value_Type_Expansion.md`.)_
  > **Completed:** Validation Rule #15 now correlates `stsc` chunk runs, `stsz/stz2` sample sizes, and the `stco/co64` offsets. See `DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Summary_of_Work.md` for validation outcomes and `DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Validation_Rule_15_Sample_Table_Correlation.md` for the archived planning notes linked with `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/`.
- [x] C16. Codec configs:
  - [x] C16.1 `avcC`: version/profile/level, `lengthSizeMinusOne`, SPS/PPS counts + lengths. **(Completed — codec metadata now parsed with regression coverage; see `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/C6_Extend_stsd_Codec_Metadata.md` and `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/Summary_of_Work.md`.)**
  - [x] C16.2 `hvcC`: profile/compat/level, arrays (vps/sps/pps), `lengthSizeMinusOne`. **(Completed — see `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/C6_Extend_stsd_Codec_Metadata.md`.)**
  - [x] C16.3 `esds`: ES_Descriptor → DecoderSpecific (AudioSpecificConfig fields mapped). **(Completed — see `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/C6_Extend_stsd_Codec_Metadata.md`.)**
- [x] C16.4 Future codec payload descriptors (e.g., Dolby Vision, enhanced audio) ensure registry coverage stays current. **(Completed — see `DOCS/TASK_ARCHIVE/131_C16_4_Future_Codec_Payload_Descriptors/Summary_of_Work.md` for implementation notes and `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/C6_Codec_Payload_Additions.md` for historical research.)**

- [x] C17. `mdat`: record offset/size (skip payload). **(Completed — streaming parser now records byte ranges without loading payload data; see `DOCS/TASK_ARCHIVE/126_C17_mdat_Box_Parser/Summary_of_Work.md`.)**
- [x] C18. `free/skip`: opaque pass-through. **(Completed — see `DOCS/TASK_ARCHIVE/127_C18_free_skip_Pass_Through/Summary_of_Work.md` for implementation notes and `DOCS/TASK_ARCHIVE/127_C18_free_skip_Pass_Through/C18_free_skip_Pass_Through.md` for original puzzle scope.)**

- [x] C19. Validation preset UI settings integration. **(Completed — macOS settings scene now surfaces presets, per-rule toggles, workspace overrides, and reset affordance with persistence captured in `DOCS/TASK_ARCHIVE/147_Summary_of_Work_2025-10-22_Validation_Preset_UI_Settings_Integration/Summary_of_Work.md`.)**

- [x] D1. `mvex/trex`: defaults. _(Completed — see `DOCS/TASK_ARCHIVE/D1_mvex_trex_Defaults/Summary_of_Work.md`.)_
- [x] [D2. `moof/mfhd`: sequence number](../../TASK_ARCHIVE/134_D2_moof_mfhd_Sequence_Number/D2_moof_mfhd_Sequence_Number.md). _(Completed — fragment headers now surface sequence numbers across Kit, CLI, and exports.)_
- [x] D3. `traf/tfhd/tfdt/trun`: parse via flags; sample_count; optional data_offset; sizes. _(Completed — see `DOCS/TASK_ARCHIVE/137_D3_traf_tfhd_tfdt_trun_Parsing/Summary_of_Work.md` for implementation recap and follow-up notes.)_
- [x] Fragment fixture coverage — *(Completed — see `DOCS/TASK_ARCHIVE/138_Fragment_Fixture_Coverage/Fragment_Fixture_Coverage.md` and `DOCS/TASK_ARCHIVE/138_Fragment_Fixture_Coverage/Summary_of_Work.md` for fixture details. Validator/CLI polish documentation now lives in `DOCS/TASK_ARCHIVE/139_Validator_and_CLI_Polish/Summary_of_Work.md`, while real-world asset licensing follow-ups remain queued in `DOCS/INPROGRESS/next_tasks.md`.)*
- [x] D4. `sidx`: refs (sizes/durations), earliest_presentation_time, timescale. _(Completed — see `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/51_D4_CLI_Batch_Mode.md`.)_
- [x] D5. `mfra/tfra/mfro`: random access table. _(Completed — see `DOCS/TASK_ARCHIVE/140_D5_mfra_tfra_mfro_Random_Access/Summary_of_Work.md` for implementation recap and remaining notes.)_
- [x] D6. Recognize `senc/saio/saiz` (CENC placeholders), capture sizes/offsets only. _(Completed — implementation recap lives in `DOCS/TASK_ARCHIVE/150_Summary_of_Work_2025-10-22_Sample_Encryption_Metadata/Summary_of_Work.md`, with detailed PRDs retained under `DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/`.)_

> **Completed Research:** Task R7 — CLI distribution strategy now lives in `DOCS/TASK_ARCHIVE/161_R7_CLI_Distribution_Strategy/`. Release engineers can follow `Documentation/ISOInspector.docc/Guides/CLIReleaseDistributionStrategy.md` for notarization, Homebrew tap, and Linux packaging workflows.

### Phase E — Validation
- [x] E1. Enforce parent containment and non-overlap. _(Completed — see `DOCS/TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/Summary_of_Work.md` for validation details; historical context remains in `DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md`.)_
- [x] E2. Detect zero/negative progress loops; cap nesting depth. _(Completed — see `DOCS/TASK_ARCHIVE/163_E2_Detect_Progress_Loops/E2_Detect_Progress_Loops.md` for the archived PRD and implementation notes.)_
- [x] E3. Warn on unusual top-level ordering (advisory). _(Completed — summary in `DOCS/TASK_ARCHIVE/142_E3_Warn_on_Unusual_Top_Level_Ordering/Summary_of_Work.md`.)_
- [x] E4. Verify `avcC/hvcC` invariants; flag inconsistencies. _(Completed — validation summary recorded in `DOCS/TASK_ARCHIVE/143_E4_Verify_avcC_hvcC_Invariants/Summary_of_Work.md`.)_
- [x] E5. Basic `stbl` coherence checks (counts nonzero, arrays parse). **(Completed — see `DOCS/TASK_ARCHIVE/144_E5_Basic_stbl_Coherence_Checks/Summary_of_Work.md` for validation rollout notes.)**
- [x] Codec validation coverage expansion for `avcC`/`hvcC` diagnostics across ParsePipeline and CLI/JSON snapshots. _(Completed — see `DOCS/TASK_ARCHIVE/149_Codec_Validation_Coverage_Expansion/Summary_of_Work.md` for regression coverage and fixture notes.)_
- [x] E7. Validation rule presets and per-rule toggles spanning core, CLI, and UI. _(Completed — configuration layer archived in `DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/B7_Validation_Rule_Preset_Configuration.md`, CLI wiring summarized in `DOCS/TASK_ARCHIVE/148_D7_Validation_Preset_CLI_Wiring/Summary_of_Work.md` (with planning retained in `DOCS/TASK_ARCHIVE/148_D7_Validation_Preset_CLI_Wiring/D7_Validation_Preset_CLI_Wiring.md`), and UI settings integration captured in `DOCS/TASK_ARCHIVE/147_Summary_of_Work_2025-10-22_Validation_Preset_UI_Settings_Integration/Summary_of_Work.md`. Bundled JSON manifests seed default presets, Application Support stores user-authored sets, exports mark disabled rules as `skipped`, and CLI aliases (for example, `--structural-only`) complement the `--preset` flag.)_
- [x] E6. Add streaming structural validation rules VR-001 (header sizing) and VR-002 (container closure).

### Phase T — Tolerance Parsing (Corrupted Media Resilience)

**Status:** Planning Phase Complete — Ready for Sprint 1 Entry
**Documentation:** [`DOCS/AI/Tolerance_Parsing/`](../Tolerance_Parsing/README.md)

This phase introduces **lenient parsing mode** that continues parsing corrupted media files while recording structural issues as `ParseIssue` events. Complements existing strict-mode validation (E1, E2, VR-*) to enable forensic workflows for QC operators, streaming SREs, and video engineers.

**Key Deliverables:**
- **T1:** Core parsing resiliency (Result-based decoder, issue recording, progress guards)
- **T2:** Corruption aggregation (`ParseIssueStore`, event streaming, metrics)
- [x] T2.1. `ParseIssueStore` aggregate and query APIs. _(Completed — see `DOCS/TASK_ARCHIVE/175_Summary_of_Work_2025-10-26_ParseIssueStore_Aggregation/Summary_of_Work.md` for aggregation recap.)_
- [x] T2.2. Emit parse events with severity metadata for tolerant parsing. _(Completed — see `DOCS/TASK_ARCHIVE/180_T2_2_Emit_Parse_Events/Summary_of_Work.md` for implementation details.)_
- [x] T2.3. Aggregate parse issue metrics for UI and CLI ribbons. _(Completed — archived in `DOCS/TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/`; ribbon design follow-ups remain in `DOCS/INPROGRESS/next_tasks.md`.)_
- [x] 🛠️ T2.4. Validation rules emit `ParseIssue` diagnostics in lenient mode. _(Completed — tolerant mode now records VR-001…VR-015 issues via `ParseIssueStore`; see `DOCS/TASK_ARCHIVE/183_T2_4_Validation_Rule_Dual_Mode_Support/Summary_of_Work.md` for details.)_
- **T3:** UI corruption views (badges, placeholders, "Integrity" tab, export actions)
- **T4:** Diagnostics export (JSON/text with byte ranges, file metadata)
  - [x] **T4.1 Extend JSON export schema for issues.** _(Completed — see `DOCS/TASK_ARCHIVE/192_T4_1_Extend_JSON_Export_Schema_for_Issues/` for implementation notes, schema documentation updates, and verification summary.)_
- **T5:** Testing & fixtures (corrupt corpus, regression, performance, fuzzing)
- **T6:** CLI & ecosystem parity (--tolerant flag, SDK API)
- **T7:** Rollout (Prototype → Alpha → Beta → GA → Telemetry)

**Active Work:**
- [x] **T3.1 — Non-modal warning ribbon for tolerant parsing metrics.** _(Completed — archived in `DOCS/TASK_ARCHIVE/185_T3_1_Tolerant_Parsing_Warning_Ribbon/`; ribbon now presents `ParseIssueStore` metrics with dismissal persistence and accessibility hooks.)_

**Full Workplan:** [`TODO.md`](../Tolerance_Parsing/TODO.md) (37 tasks across 7 phases)
**Integration Guide:** [`IntegrationSummary.md`](../Tolerance_Parsing/IntegrationSummary.md)
**Feature Analysis:** [`FeatureAnalysis.md`](../Tolerance_Parsing/FeatureAnalysis.md)

**Current Status:**
- [x] T1.1. Define `ParseIssue` model (severity, code, message, byte range). _(Completed — see `DOCS/TASK_ARCHIVE/164_Summary_of_Work_ParseIssue_Model/Summary_of_Work.md`)_
- [x] T1.2. Extend `ParseTreeNode` with `issues` and `status` fields. _(Completed — see `DOCS/TASK_ARCHIVE/165_T1_2_Extend_ParseTreeNode_Status_and_Issues/Summary_of_Work.md` for the latest status.)_
- [x] T1.3. Create `ParsePipeline.Options` for tolerance configuration. _(Completed — see `DOCS/TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/Summary_of_Work.md` for strict vs. tolerant defaults and wiring notes.)_
- [x] T1.4. Refactor `BoxHeaderDecoder` to Result-based API. _(Completed — see `DOCS/TASK_ARCHIVE/167_T1_4_BoxHeaderDecoder_Result_API/Summary_of_Work.md`.)_
- [x] T1.5. Update container iteration to handle errors gracefully. **(Completed — see `DOCS/TASK_ARCHIVE/169_T1_5_Propagate_Decoder_Failures_Through_Tolerant_Parsing/` for implementation details.)**
- [x] T1.6. Implement binary reader guards (clamp to parent boundaries). _(Completed — see `DOCS/TASK_ARCHIVE/170_T1_6_Implement_Binary_Reader_Guards/Summary_of_Work.md` for truncation guard coverage.)_
- [x] T1.7. Add progress/depth guards in lenient mode. _(Completed — see `DOCS/TASK_ARCHIVE/171_T1_7_Finalize_Traversal_Guard_Requirements/Summary_of_Work.md` and `DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md` for the guard specification.)_
- [x] T1.8. Enforce traversal guard budgets in the streaming pipeline and emit scoped tolerant parsing issues. _(Completed — see `DOCS/TASK_ARCHIVE/173_T1_8_Traversal_Guard_Implementation/Summary_of_Work.md` for the implementation recap and verification history.)_

**Success Metrics (from PRD):**
- Coverage: ≥95% corrupt fixtures parse to completion
- User Satisfaction: ≥4/5 on "inspect damaged files"
- Crash-Free: 99.9% across corrupt suite
- Performance: Lenient mode ≤1.2× strict mode

**Related Tasks:**
- Builds on: E1 (containment), E2 (progress guards), B7 (validation config)
- Extends: G7 (UI state), B6 (JSON export), VR-001 to VR-015 (validation rules)

### Phase F — Export & Hex
- [x] F1. JSON export: encode tree with offsets/sizes/parsed fields. _(Implemented by [28_B6_JSON_and_Binary_Export_Modules](../../TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/28_B6_JSON_and_Binary_Export_Modules.md))._
- [x] F2. Configure performance benchmarks for large files. **CLI validation and app bridge benchmarks enforce scaled latency budgets with XCTest metrics harnesses.** _(macOS Combine benchmark capture remains **Blocked** pending macOS hardware — see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md` and `DOCS/INPROGRESS/next_tasks.md`.)_
- [x] F3. Hex slice provider: bounded reads for selected node; window sizing and caching. _(Delivered via [23_C3_Detail_and_Hex_Inspectors](../../TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/23_C3_Detail_and_Hex_Inspectors.md) and refined in [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/Summary_of_Work.md))._
- [x] F4. Field-to-hex mapping metadata for details highlighting. _(See [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/Summary_of_Work.md))._
- [x] F6. Export schema verification harness covering compatibility aliases and format summary output before production schema updates. _(Completed — see `DOCS/TASK_ARCHIVE/152_F6_Export_Schema_Verification_Harness/Summary_of_Work.md` for tests and CLI coverage.)_

### Phase F — Documentation & Onboarding
- [x] F3. Author developer onboarding guide and API reference. *(Completed — see `Docs/Guides/DeveloperOnboarding.md` and `DOCS/TASK_ARCHIVE/53_F3_Developer_Onboarding_Guide/`.)*
- [x] F4. Produce user manual covering CLI and app workflows. _(Completed — manuals live in `Documentation/ISOInspector.docc/Manuals/App.md` and `Documentation/ISOInspector.docc/Manuals/CLI.md`.)_
- [x] F5. Finalize release checklist and go-live runbook covering QA sign-off, documentation updates, and packaging logistics. _(Completed — see `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md` and archive notes in `DOCS/TASK_ARCHIVE/59_F5_Finalize_Release_Checklist_and_Go_Live_Runbook/`.)_

- [x] G1. File open: `.fileImporter` (iOS/iPadOS), `NSOpenPanel` (macOS); UTTypes: movie/mp4/quicktime. _(Completed via [E1_Build_SwiftUI_App_Shell](../../TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/E1_Build_SwiftUI_App_Shell.md))._
- [x] G2. Tree view (Outline) with badges for warnings/errors. _(Implemented in [19_C2_Tree_View_Virtualization](../../TASK_ARCHIVE/19_C2_Tree_View_Virtualization/19_C2_Tree_View_Virtualization.md) and its follow-ups.)_
- [x] G3. Details view: sectioned fields; copy actions (fourcc/offset/size). _(Delivered in [23_C3_Detail_and_Hex_Inspectors](../../TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/23_C3_Detail_and_Hex_Inspectors.md))._
- [x] G4. Hex view: offset gutter, ASCII column, selection; fetch via `HexSliceProvider`. _(Refined through [24_C3_Highlight_Field_Subranges](../../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/Summary_of_Work.md))._
- [x] G5. Search & filters; quick toggles (containers/codec/meta/frag). _(Expanded in [22_C2_Extend_Outline_Filters](../../TASK_ARCHIVE/22_C2_Extend_Outline_Filters/C2_Extend_Outline_Filters.md))._
- [x] G6. Export actions (JSON subtree/full). **(Completed — see `DOCS/TASK_ARCHIVE/179_Summary_of_Work_2025-10-27_G6_Export_JSON_Actions/G6_Export_JSON_Actions.md` for the archived PRD and `Summary_of_Work.md` for verification notes.)**
- [x] G7. State management: `DocumentVM` holds root; `NodeVM` for selection; `HexVM` for slice & highlight. _(Completed — see `DOCS/TASK_ARCHIVE/154_G7_State_Management_ViewModels/Summary_of_Work.md` for orchestration details.)_
- [x] G8. Accessibility & keyboard shortcuts (macOS/iPadOS). _(Completed — see [Summary_of_Work](../../TASK_ARCHIVE/155_G8_Accessibility_and_Keyboard_Shortcuts/Summary_of_Work.md))._
- [x] Task E3. Implement session persistence so the app restores open files, annotations, and window layouts on relaunch. **(Completed — see `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/`.)**
- [x] Task E6. Emit diagnostics for recents and session persistence failures once logging pipeline hooks land. **(Completed — see `DOCS/TASK_ARCHIVE/68_E6_Emit_Persistence_Diagnostics/Summary_of_Work.md`.)**

### Phase H — Fixtures & Tests
- [x] H1. Fixture corpus: MP4 (non-frag), MOV, fMP4 segment, DASH init+media, huge `mdat`, malformed cases.
- [x] H2. Unit tests: headers, container boundaries, specific box field extraction. **(Completed — see `DOCS/TASK_ARCHIVE/94_H2_Unit_Tests/Summary_of_Work.md`.)**
- [x] H3. Snapshot tests: JSON exports of small fixtures. *(Completed — see `Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift` and `DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/Summary_of_Work.md` for baselines and update workflow.)*
- [x] H4. Performance tests: parse time & memory cap (<100 MB for 20 GB file). _(Completed — see `DOCS/TASK_ARCHIVE/107_H4_Performance_Benchmark_Validation/Summary_of_Work.md`.)_
- [x] H5. macOS SwiftUI automation covering streaming default selection and synchronized detail updates. Implemented via
  `ParseTreeStreamingSelectionAutomationTests`, which hosts the app view hierarchy on macOS and asserts outline/detail state
  during a streaming parse. See `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md` for the execution
  note.
  - Hardware validation run remains **Blocked** pending macOS runner — tracked in `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md` and `DOCS/INPROGRESS/next_tasks.md`.

### Phase I — Packaging & Release
- [x] I1. SwiftPM product definitions (library + app).
- [x] I2. App entitlements for file access; sandbox. *(Completed by E4 distribution scaffolding — see `Distribution/Entitlements/` and `scripts/notarize_app.sh` for notarization tooling.)*
- [x] I2.a Evaluate whether Apple Events automation is required for notarized builds and extend entitlements safely. *(Completed — see `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/57_Distribution_Apple_Events_Notarization_Assessment.md` and the summary in `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/79_Distribution_Apple_Events_Follow_Up.md`.)*
- [x] I3. App theming (icon, light/dark). **(Completed — manual `AppIcon.icon` asset is committed, the generator/tests were sunset per [`DOCS/AI/ISOInspector_Execution_Guide/12_AppIcon_Asset_Update_Summary.md`](../ISOInspector_Execution_Guide/12_AppIcon_Asset_Update_Summary.md), and CI now targets Xcode 16.0+ to build the asset; palette reference remains in [`DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/`](../../TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/).)**
- [x] I4. README with feature matrix, supported boxes, screenshots. **(Completed — README updated with matrix, platform coverage, and concept capture; see `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/Summary_of_Work.md`.)**
- [x] I5. v0.1.0 Release notes; distribution (TestFlight/DMG notarization). **(Completed — see `Distribution/ReleaseNotes/v0.1.0.md` and `DOCS/TASK_ARCHIVE/82_I5_v0_1_0_Release_Notes/`.)**

### Phase J — Secure Filesystem Access
- [x] J1. Ship FilesystemAccessKit core API with async open/save/bookmark helpers shared by all targets. *(Completed — archived in `DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/`; ongoing bookmark persistence and sandbox profile planning remain in `DOCS/INPROGRESS/next_tasks.md` and the Phase G workplan.)*
- [x] J2. Persist security-scoped bookmarks and integrate with recents/session restoration flows. *(Completed — see `DOCS/TASK_ARCHIVE/157_J2_Persist_Security_Scoped_Bookmarks/Summary_of_Work.md` for audit logging and ledger reconciliation notes.)*
- [x] J3. Document CLI sandbox usage, including `--open` automation hook and sample sandbox profile snippets. _(Completed — see `Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md` and the archive at `DOCS/TASK_ARCHIVE/72_G3_Expose_CLI_Sandbox_Profile_Guidance/`.)_
- [x] J4. Add zero-trust logging policies ensuring file paths are hashed or redacted in diagnostics outputs. **(Completed — see `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/Summary_of_Work.md` and updated logging notes in `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/G4_Zero_Trust_Logging.md`.)**

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
