# ISOInspector MVP Checklist (Phases A–F)

> Scope: Minimal streaming parser + validators + JSON export (no UI yet), aligned to PRD.

## ✅ Archived Delivery Log
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

## Phase A — IO Foundations
- [ ] A1. Define `RandomAccessReader` protocol (`length`, `read(at:count:)`, BE helpers stubs)
- [x] A2. Implement `MappedReader` (Data.mappedIfSafe) — placeholder file with TODOs
- [ ] A3. Implement `FileHandleReader` (seek + read) — placeholder file with TODOs
- [ ] A4. Define error model: `IOError`, `ParseError`, `ValidationError` (cases only, no logic)
- [ ] A5. Draft micro-benchmark plan (README section)

## Phase B — Core Box Model & Parser
- [ ] B1. Declare `BoxHeader` fields (no logic): size32, largesize64, type, uuid?, headerSize, payloadRange, startOffset, endOffset
- [ ] B2. Declare `BoxNode` (header, children[], payload?, warnings[])
- [ ] B3. Stub `readBoxHeader(at:)` signature (no body)
- [ ] B4. Stub `parseContainer(parentRange:)` signature (no body); add max-depth constant
- [ ] B5. Create `BoxParserRegistry` skeleton (register/match fourcc)
- [ ] B6. Add `FullBoxReader` type with `version`, `flags` placeholders

## Phase C — Specific Parsers (Baseline)
> **Priority Update (2025-10-20):** Phase C parser work is now a **P0 blocker** for the upcoming milestone. Treat every unchecked item below as urgent and schedule accordingly.
- [x] C1. Stubs: `ftyp`, `mvhd`, `tkhd`, `mdhd`, `hdlr` (input/output types only) **(Completed — see `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md` for the `hdlr` parser implementation; `mdhd` parser landed per `DOCS/TASK_ARCHIVE/95_C4_mdhd_Media_Header_Parser/Summary_of_Work.md`.)**
- [ ] C2. Stubs: `stsd`, `stts`, `ctts`, `stsc`, `stsz/stz2`, `stco/co64`, `stss`
- [ ] C3. Stubs: `dinf/dref`, `smhd/vmhd`, `edts/elst`, `udta/meta/keys/ilst`
- [ ] C4. Stubs: codec configs `avcC`, `hvcC`, `esds` (field names only)
- [ ] C5. Stubs: `mdat`, `free/skip` (opaque markers)

## Phase D — Fragmentation & Indexes
- [ ] D1. Stubs: `mvex/trex`
- [ ] D2. Stubs: `moof/mfhd`
- [ ] D3. Stubs: `traf/tfhd/tfdt/trun` (flags map only)
- [x] D4. Stubs: `sidx`. _(Completed — see `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/51_D4_CLI_Batch_Mode.md`.)_
- [ ] D5. Stubs: `mfra/tfra/mfro`
- [ ] D6. Stubs: `senc/saio/saiz` placeholders

## Phase E — Validation
- [ ] E1. Rules list: containment, non-overlap, overflow (documented in README)
- [ ] E2. Add progress guard + max nesting depth constants
- [ ] E3. Advisory order warnings (ftyp/moov/mdat)
- [ ] E4. avcC/hvcC invariants list
- [ ] E5. Basic `stbl` coherence checks list

## Phase F — Export & Hex
- [ ] F1. JSON export: encoder structure (types only)
- [ ] F2. Hex provider skeleton: windowed reads API (no impl)
- [ ] F3. Field→hex mapping protocol (no impl)
