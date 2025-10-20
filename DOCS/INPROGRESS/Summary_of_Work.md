# Summary of Work — Start Command Run

## Completed Tasks

- **C14a — Finalize `edts/elst` Parser Scope**
  - Documented parser scope, validation checkpoints, and streaming considerations in

    `DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope/C14a_Finalize_Edit_List_Scope.md` to guide upcoming tasks C14b–C14d.

- **C14b — Implement `elst` Edit List Parser**
  - Registered a streaming `elst` decoder in `BoxParserRegistry` that emits normalized edit metadata, playback rates, and

    cumulative presentation offsets for downstream consumers while keeping fields accessible to the CLI exporter.

  - Added new structured payload surfaces and tests covering both 32-bit and 64-bit edit entries. Live parse pipeline
    now

    threads `mvhd`/`mdhd` timescales into the edit list environment so normalized seconds populate without test-only overrides;

    regression covered by `ParsePipelineLiveTests.testLivePipelineNormalizesEditListUsingHeaderTimescales`.

## Notes

- See `DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope/Summary_of_Work.md` for detailed completion notes and follow-up

  puzzles.
