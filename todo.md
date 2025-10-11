# TODO

- [x] #1 Implement ParsePipeline.live() to iterate through MP4 boxes and emit streaming parse events.
- [x] #2 Automate refreshing MP4RABoxes.json from the upstream registry and document the update workflow.
- [ ] #3 Implement remaining validation rules (VR-001, VR-002, VR-004, VR-005) using streaming context and metadata stack.
    - [x] VR-001 Box size must be ≥ header length and fit within file range.
    - [x] VR-002 Container boxes must close exactly at their declared payload size.
    - [x] VR-004 `ftyp` must appear before any media box.
    - [x] VR-005 `moov` must precede `mdat` unless flagged streaming.
    - [x] VR-006 Research log persists unknown boxes for follow-up analysis.
- [x] #4 Integrate ResearchLogMonitor with SwiftUI previews once VR-006 UI surfaces consume research entries.
- [x] #5 Emit telemetry during UI smoke tests to flag missing VR-006 research log events.
- [x] #6 Add box category and streaming metadata filters once corresponding models are available.
- [x] #7 Highlight field subranges and support selection syncing once payload annotations are available.
- [x] #8 Expand fixture catalog with fragmented, DASH, and malformed samples plus expected validation notes.
- [x] #9 Add CLI export commands for JSON and binary captures using the new ISOInspectorKit exporters.
- [x] #10 Replace JSON persistence with the selected CoreData schema once R6 finalizes annotation storage requirements.
- [ ] #11 Implement session persistence (Task E3) following the archived CoreData migration plan.
- [ ] #12 Add DocC publishing to CI once storage and hosting requirements are validated.
