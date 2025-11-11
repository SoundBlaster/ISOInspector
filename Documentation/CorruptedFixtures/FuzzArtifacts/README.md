# Fuzzing Reproduction Artifacts

This directory contains reproduction artifacts captured during fuzzing test failures.

## Purpose

When the `TolerantParsingFuzzTests` suite detects a crash or unexpected failure during fuzzing, it automatically saves reproduction artifacts here to aid in debugging and regression analysis.

## Artifact Structure

Each failed fuzzing case generates two files:

1. **`fuzz_repro_seed{N}.json`** — Metadata describing the failure:
   - `seed`: The random seed used for this mutation
   - `mutation`: Description of the corruption applied
   - `errorDescription`: The error message that occurred

2. **`fuzz_repro_seed{N}.mp4`** — Binary payload that triggered the failure

## Usage

To reproduce a specific failure:

```bash
# Run parser with the saved payload
iso-inspector-cli analyze --tolerant fuzz_repro_seed42.mp4

# Or load the artifact metadata to understand the mutation
cat fuzz_repro_seed42.json
```

## Cleanup

These artifacts are excluded from version control via `.gitignore` and should be cleaned up after investigation:

```bash
rm -f fuzz_repro_*
```

## Integration with Test Suite

The `TolerantParsingFuzzTests` suite automatically:
- Captures artifacts when `successRate < 0.999`
- Includes artifact paths in test failure messages
- Limits artifacts to failed cases only (successful completions are not saved)

## See Also

- `Tests/ISOInspectorKitTests/TolerantParsingFuzzTests.swift` — Main fuzzing harness
- `DOCS/TASK_ARCHIVE/209_T5_5_Tolerant_Parsing_Fuzzing_Harness/209_T5_5_Fuzzing_Harness.md` — Task specification
- `DOCS/AI/Tolerance_Parsing/TODO.md` — Tolerance parsing workplan
