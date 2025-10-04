# ISOInspector MVP Checklist (Phases A–F)

> Scope: Minimal streaming parser + validators + JSON export (no UI yet), aligned to PRD.

## Phase A — IO Foundations
- [ ] A1. Define `RandomAccessReader` protocol (`length`, `read(at:count:)`, BE helpers stubs)
- [ ] A2. Implement `MappedReader` (Data.mappedIfSafe) — placeholder file with TODOs
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
- [ ] C1. Stubs: `ftyp`, `mvhd`, `tkhd`, `mdhd`, `hdlr` (input/output types only)
- [ ] C2. Stubs: `stsd`, `stts`, `ctts`, `stsc`, `stsz/stz2`, `stco/co64`, `stss`
- [ ] C3. Stubs: `dinf/dref`, `smhd/vmhd`, `edts/elst`, `udta/meta/keys/ilst`
- [ ] C4. Stubs: codec configs `avcC`, `hvcC`, `esds` (field names only)
- [ ] C5. Stubs: `mdat`, `free/skip` (opaque markers)

## Phase D — Fragmentation & Indexes
- [ ] D1. Stubs: `mvex/trex`
- [ ] D2. Stubs: `moof/mfhd`
- [ ] D3. Stubs: `traf/tfhd/tfdt/trun` (flags map only)
- [ ] D4. Stubs: `sidx`
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
