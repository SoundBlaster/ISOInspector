# C6 Codec Payload Additions Follow-Up

## 🎯 Objective

Document the plan for extending `BoxParserRegistry` with future codec-specific payload parsers so new fixtures (e.g., Dolby Vision descriptors or novel audio profiles) surface rich metadata without regressions.

## 🧩 Context

- `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/Summary_of_Work.md` highlights the need to monitor upcoming codec payload additions after landing AVC/HEVC/AAC coverage.
- `DOCS/INPROGRESS/next_tasks.md` tracks this follow-up under "Upcoming Parser Enhancements" to keep streaming and export paths aligned with new payload types.
- `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` maintains codec configuration milestones under Phase C, ensuring UI and CLI consumers display codec metadata consistently.

## ✅ Success Criteria

- Inventory target codec payloads (e.g., Dolby Vision `dvvC`, enhanced audio descriptors) with fixture sources and decoding references.
- Define parser requirements, emitted fields, and validation hooks per payload while preserving existing snapshot/export

  regressions.

- Outline test coverage updates (unit + JSON snapshot) required for each new payload and identify fixture gaps.
- Enumerate documentation updates needed across PRD, user guides, and archived follow-up notes once implementations

  land.

## 🎬 Target Payload Inventory

1. **Dolby Vision configuration (`dvvC`)**
   - Sample entries: `dvh1`, `dvhe`, `dvav`, and `dvvc` require the Dolby Vision configuration box defined in ETSI TS 103 433-1.
   - Key fields: `dv_version_major/minor`, profile, level, `rpu_present_flag`, `el_present_flag`, `bl_present_flag`, and compatibility identifiers.
   - Fixture plan: ingest Dolby Vision demo streams from the Dolby developer sample pack and supplement with MP4RA-hosted `dvvC` layout examples. Capture both single-layer (`dvhe.05`) and dual-layer (`dvhe.07`) bitstreams so encryption combinations are represented.

1. **AV1 codec configuration (`av1C`)**
   - Sample entries: `av01` carries the AV1 Codec Configuration Box per ISOBMFF Amendment 4.
   - Key fields: sequence profile, level, tier, bit depth, monochrome flag, chroma subsampling, and initial operating point flags. Record `configOBUs` lengths for validation.
   - Fixture plan: reuse AOM reference MP4s (e.g., `Netflix_Aerials_8bit`) and generate encrypted samples with `mp4muxer` if coverage for `encv` wrapping is missing.

1. **VP9 codec configuration (`vpcC`)**
   - Sample entries: `vp09` (and deprecated `vp08`) embed the VP Codec Configuration box as described in ISO/IEC 14496-15.
   - Key fields: profile, level, bit depth, chroma subsampling, colour primaries, transfer characteristics, and matrix

     coefficients.

   - Fixture plan: pull the WebM Project conformance set and create sidecar metadata to verify HDR (`vp09.02`) payloads.

1. **Dolby AC-4 descriptors (`dac4`)**
   - Sample entries: `ac-4` sample descriptions reference the Dolby AC-4 specific box defined in ETSI TS 103 190-3.
   - Key fields: bitstream version, presentation version, `mdcompat`, frame rate code, and short program identifier lists.
   - Fixture plan: request Dolby AC-4 transport samples with `dac4` boxes via manifest-driven fixture acquisition; ensure at least one sample includes channel-based presentations and another includes objects.

1. **MPEG-H 3D Audio configuration (`mhaC`)**
   - Sample entries: `mha1`/`mhm1` require the MPEG-H configuration record specified in ISO/IEC 23008-3.
   - Key fields: profile level indication, reference channel layout, `compatibleSetIndication`, and `generalProfileCompatibilitySet` bits for playback guidance.
   - Fixture plan: leverage Fraunhofer's public MPEG-H demos and add encrypted variants when we extend Common Encryption

     coverage.

## 🧱 Parser and Model Extensions

- Introduce a `CodecPayload.DolbyVisionConfiguration` struct exposing versioning, layer presence flags, and compatibility identifiers. Extend the registry to fall back to opaque payloads when unrecognized profile combinations appear while logging VR-006 research entries.
- Add `CodecPayload.AV1Configuration` capturing profile, level, tier, bit depth, chroma layout, and operating point descriptors. Reuse existing bit reader utilities to parse the packed fields and store `configOBUs` payload lengths for validation.
- Add `CodecPayload.VP9Configuration` reflecting chroma and colour metadata, ensuring parsed colour tags remain aligned with ISOInspectorKit's existing colour mapping enums.
- Model `CodecPayload.DolbyAC4` with presentation and bitstream identifiers so CLI exports can surface presentation counts. Validate program ID arrays against descriptor length limits.
- Model `CodecPayload.MPEGHConfiguration` exposing compatibility flags and reference layout data, enabling downstream validation rules to enforce speaker layout coverage.
- Update `BoxParserRegistry` to register each codec-specific parser behind feature flags that gate release until fixtures land. Maintain existing encrypted sample entry handling so `sinf/schi/tenc` metadata is preserved.

## 🧪 Test and Fixture Strategy

- **Unit tests:** Extend `StsdSampleDescriptionParserTests` with one case per payload using fixture-backed payload data. Add negative tests that feed truncated payloads to confirm validation hooks raise descriptive errors without panics.
- **Snapshot coverage:** Update the JSON export baseline (`CodecMetadataBaseline.json`) with new codec-specific fields. Gate snapshot updates behind fixture availability to avoid incomplete metadata surfaces.
- **Fixture acquisition:**
  - Add manifest entries in `scripts/generate_fixtures.py` for each new sample, including checksum, license text, and encryption metadata.
  - Record fixture provenance in `Documentation/FixtureCatalog/README.md` once downloads are automated.
- **Automation hooks:** Wire new payload models into validation rule VR-006 logging paths to capture unsupported

  configurations for telemetry review.

## 📝 Documentation and Tracking Updates

- Update `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` Phase C milestones once each codec payload ships, marking the associated checklist items as complete.
- Refresh `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/next_tasks.md` with links to the new payload trackers when implementation PRs are filed.
- Document CLI export examples showcasing the new metadata fields in `Documentation/Guides/CodecMetadata.md` and mirror the narrative in the SwiftUI detail pane guide.
- Capture release notes for each codec payload in `Documentation/ReleaseNotes/` so downstream consumers can track metadata expansion per release.

## 🔭 Open Questions

- Confirm whether Dolby Vision dual-layer samples require additional parser hooks to associate enhancement layer NAL

  units with base layer entries.

- Determine whether MPEG-H configuration parsing should defer until Combine-backed streaming playback arrives or if

  static metadata is sufficient.

- Evaluate if Common Encryption `schi`/`tenc` fallbacks need to special-case Dolby AC-4 object metadata when encryption flags mask descriptor payloads.

## ✅ Next Steps

1. Acquire Dolby Vision and AV1 fixtures through the manifest-driven pipeline and verify licensing terms.
1. Land parser structs and registry wiring under development flags, accompanied by failing tests to drive

   implementation.

1. Update JSON snapshots and CLI/UI bindings once fixtures validate new payload models, then promote feature flags to

   production.
