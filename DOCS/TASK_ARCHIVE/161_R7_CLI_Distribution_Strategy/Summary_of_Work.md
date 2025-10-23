# R7 — CLI Distribution Strategy — Summary of Work

## Completed Outputs
- Authored `Documentation/ISOInspector.docc/Guides/CLIReleaseDistributionStrategy.md`, documenting notarized macOS distribution, Homebrew tap workflow, Linux packaging, automation hooks, and risk mitigations for the `isoinspect` CLI.
- Updated the release readiness runbook to fold CLI packaging checks into pre-release validation, reuse the new script helper, and enumerate artifact naming for macOS and Linux deliverables.
- Added `scripts/package_cli.sh` to orchestrate building, signing, zipping, checksum generation, and notarization submission for CLI releases.

## Evidence
- Decision record and risk register: [`Documentation/ISOInspector.docc/Guides/CLIReleaseDistributionStrategy.md`](../../Documentation/ISOInspector.docc/Guides/CLIReleaseDistributionStrategy.md)
- Release checklist updates: [`Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`](../../Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md)
- Automation helper: [`scripts/package_cli.sh`](../../scripts/package_cli.sh)

## Follow-Ups
- Extend CI to invoke `scripts/package_cli.sh --skip-notarize` on tagged builds and publish artifacts as GitHub Release assets.
- Publish and maintain the private `isoinspector/homebrew-tap` repository referenced by the strategy.
- Document checksum verification workflow for QA in `releases/<version>/QA/cli/README.md` when the first release executes the plan.
