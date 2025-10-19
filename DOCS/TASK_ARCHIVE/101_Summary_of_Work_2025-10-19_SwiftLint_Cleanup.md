# SwiftLint Pipeline and Configuration Updates (2025-10-19)

## Overview
- disabled the `function_parameter_count` rule in `.swiftlint.yml` to remove repeated in-source suppressions.
- removed the stale `optional_data_string_conversion` entry that triggered warnings every lint run.

## CI/CD Pipeline Improvements
- replaced the Linux workflow SwiftLint steps with a UID/GID aware docker invocation that clears `.swiftlint.cache`, runs `swiftlint --fix --no-cache --config .swiftlint.yml`, and fails with a concise file list when formatting is required.
- added a strict verification pass that reuses the repository configuration without cache to ensure lint parity with local runs.

## Local Tooling Alignment
- updated `scripts/swiftlint-format.sh` to mirror the CI container command, purge the cache, and run `swiftlint --fix --no-cache --config .swiftlint.yml` for consistent developer workflows.

## Codebase Adjustments
- introduced a `DescriptorHeader` helper struct in `Sources/ISOInspectorKit/ISO/BoxParserRegistry.swift` so `readDescriptorHeader` no longer returns a three-member tuple, satisfying the `large_tuple` rule that became visible after the stricter lint execution.

## Verification
- `./scripts/swiftlint-format.sh`
- `docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" -w /work ghcr.io/realm/swiftlint:0.53.0 swiftlint lint --strict --no-cache --config .swiftlint.yml`

Both commands report success (docker still warns about the default `line_length` configuration being disabled, matching prior behavior).
