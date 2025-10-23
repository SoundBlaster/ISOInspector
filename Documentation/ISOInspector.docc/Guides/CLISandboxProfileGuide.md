# ISOInspector CLI Sandbox Automation Guide

## Purpose

Explain how to prepare, sign, and distribute sandbox profiles that allow the `isoinspector` CLI to process media without interactive prompts while remaining compliant with the App Sandbox and FilesystemAccessKit bookmark flows.

## Prerequisites

- ISOInspector must be signed with the App Sandbox entitlement bundle that already ships with the macOS target, including `com.apple.security.files.user-selected.read-write` and the bookmark entitlements required by FilesystemAccessKit.【F:Distribution/Entitlements/ISOInspectorApp.macOS.entitlements†L1-L15】
- Automation runners need access to the FilesystemAccessKit bookmark store introduced by Tasks G1 and G2 so that CLI invocations can activate security-scoped URLs without UI prompts.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L6-L69】
- Keep the notarized CLI binary and the sandbox profile within the same distribution so downstream teams can verify the signature chain before enabling headless execution.

## Step 1. Create an allowlist sandbox profile

Start from the default deny profile and opt into the exact directories or files that the automation run should touch. Generate the profile on a development Mac so you can iterate quickly.

```scheme
(version 1)
(deny default)
(allow ipc-posix-shm)
(allow file-read*
    (subpath "/Users/automation/Fixtures")
    (subpath "/tmp/isoinspector")
)
(allow file-write*
    (subpath "/Users/automation/Fixtures")
    (subpath "/tmp/isoinspector")
)
(allow file-issue-extension)
(allow mach-lookup (global-name "com.apple.SecurityServer"))
```

- Retain the default deny stance so the CLI cannot access user home directories or network sockets.
- Mirror every path that operators would have selected through the GUI flow so the security-scoped URLs still map to authorized directories.
- Store the profile as `isoinspector-automation.sb` in source control for repeatable provisioning.

## Step 2. Sign and notarize the profile bundle

1. Package the profile alongside the CLI binary so codesign covers both artifacts:
   ```bash
   codesign --force --sign "Developer ID Application: Example Corp" isoinspector-automation.sb
   ```
2. Staple notarization results to the CLI distribution (DMG or ZIP) that contains the signed profile to avoid quarantine prompts during CI bootstrap.
3. Publish SHA-256 digests for both the binary and the sandbox profile so operators can validate integrity before use.

## Step 3. Capture bookmarks with `--open`

Use a trusted workstation to generate bookmark data that headless runners will later consume.

1. Invoke the CLI with the sandbox profile preloaded and redirect the bookmark payload to disk:
   ```bash
   sandbox-exec -f isoinspector-automation.sb \
     isoinspector --open /Users/automation/Fixtures/Trailer.mp4 > bookmarks/trailer.bookmark
   ```
2. The CLI activates FilesystemAccessKit’s `openFile` helper to request a security-scoped URL, then emits base64-encoded bookmark data to standard output for capture.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L18-L69】
3. Commit the bookmark artifact to a secure secrets store so automation workers can fetch it at runtime.

## Step 4. Authorize headless runs with `--authorize`

When automation executes on a sandboxed runner, preload the bookmark and point the CLI at the whitelisted profile.

```bash
sandbox-exec -f isoinspector-automation.sb \
  isoinspector --authorize bookmarks/trailer.bookmark inspect Trailer.mp4
```

- `--authorize` resolves the bookmark via FilesystemAccessKit, calling `resolveBookmarkData` to reactivate the security scope before the CLI attempts any file IO.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L30-L53】
- Place the target media relative to the bookmarked directory; otherwise the CLI will emit `authorization_denied` diagnostics.
- Monitor stderr for stale bookmark warnings so operators can refresh artifacts proactively.
- Bookmark commands emit hashed `FilesystemAccessAuditTrail` events. Leave telemetry enabled (default) to capture audit output for compliance logs, or pass `--disable-telemetry` to suppress publishing when audits are not required.【F:Sources/ISOInspectorCLI/CLI.swift†L11-L129】【F:Tests/ISOInspectorCLITests/FilesystemAccessTelemetryTests.swift†L6-L104】

## Step 5. Rotate bookmarks safely

- Refresh bookmarks whenever the source directory moves or permissions change. Stale bookmarks trigger the `bookmark.resolve.stale` log entry, after which automation should discard and recreate the credential.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L42-L66】
- Audit events now include a `bookmark_id` field derived from the persisted ledger so you can correlate CLI output with stored bookmark records when rotating credentials.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L60-L109】【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L566-L683】
- Store bookmarks in the same secrets manager as other CI credentials and audit access; they grant filesystem reach beyond the sandbox defaults.
- When revoking access, remove bookmark files and regenerate the sandbox profile to tighten the allowlist.

## Troubleshooting checklist

| Symptom | Mitigation |
| --- | --- |
| `authorization_denied` errors when invoking `--authorize`. | Confirm the sandbox profile includes the directory path and that the bookmark still resolves to a file under that subpath. Recreate the bookmark with `--open` if stale warnings appear in the log.|
| Bookmark resolves but CLI reports missing file. | Validate that automation downloaded the media into the same path structure used during bookmark creation and that the sandbox profile allows read/write access.|
| CLI fails to write exports while sandboxed. | Add the export directory to the profile under `file-write*` and re-sign the profile bundle before distribution.|

## Verification before rollout

1. Run the unit test suite with sandbox disabled to confirm FilesystemAccessKit integrations stay green:
   ```bash
   swift test --disable-sandbox
   ```
2. Execute an end-to-end dry run on a macOS runner using the signed profile, `--authorize` bookmark, and a sample MP4 to ensure parsing succeeds with exit code 0.
3. Capture logs showing FilesystemAccessKit bookmark activation and store them alongside release notes for traceability.

Following this runbook keeps the CLI sandbox-compliant while enabling repeatable, headless automation flows.
