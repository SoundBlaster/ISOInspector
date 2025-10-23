# ISOInspector CLI Distribution Strategy

## Purpose
Establish a repeatable release plan for the notarized `isoinspect` CLI so binaries, tap formulas, and Linux artifacts ship in lockstep with the macOS app. This decision record captures release engineering expectations, automation hooks, and risk mitigations for every distribution channel.

## Release Cadence Alignment
- Publish CLI artifacts whenever the macOS app tags a release. Reuse the same marketing version and build number stored in `DistributionMetadata.json` so the CLI, app, and documentation report identical identifiers.
- Keep notarization, checksum publication, and release notes in the same GitHub Release draft. Bundle CLI zips alongside the DMG, IPA, and DocC archives already listed in the runbook.
- Track ownership hand-offs in the go/no-go review. QA owns binary verification and checksum capture, while release engineering owns packaging, uploads, and tap automation.

## macOS Distribution (Signed ZIP + Optional DMG)
1. **Build** the CLI with `swift build -c release --product isoinspect` on macOS so the binary inherits the signing identity from the developer certificate profile. Copy the binary into `Distribution/CLI/<version>/isoinspect` before packaging.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L51-L63】
2. **Package** the binary into a `.zip` that includes the executable, LICENSE, and README snippet describing usage. Apply `codesign --sign "Developer ID Application" --options=runtime --timestamp` before zipping to embed hardened runtime requirements.
3. **Notarize** the archive with `scripts/notarize_app.sh --artifact Distribution/CLI/<version>/isoinspect.zip --profile <keychain-profile>`. Use `--primary-bundle-id com.isoinspector.cli` so App Store Connect tracks CLI submissions separately from the GUI app.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L64-L77】
4. **Staple** notarization tickets with `xcrun stapler staple Distribution/CLI/<version>/isoinspect.zip`. If customers prefer a DMG, reuse the same signed binary inside a simple drag-to-install disk image and staple the DMG before upload.
5. **Verify** the stapled archive via `spctl --assess --type open --verbose Distribution/CLI/<version>/isoinspect.zip` and publish SHA256/SHA512 checksums next to the download link. Store logs and checksums in `releases/<version>/QA/cli/` for audit trails.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L78-L109】

## Homebrew Tap Publication
1. **Tap Location** — host a private `isoinspector/homebrew-tap` repository containing `isoinspect.rb`. The tap repository tracks the notarized macOS ZIP and Linux tarballs uploaded to GitHub Releases.
2. **Formula Template** — define a cask-style formula that downloads the notarized ZIP, verifies its SHA256 checksum, runs `chmod +x`, and links the binary to `/usr/local/bin/isoinspect`. Include caveats about sandbox profiles and telemetry flags summarized in the CLI manual.【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L63】
3. **Automation Hook** — extend the release workflow with a job that:
   - Downloads the notarized ZIP and computes the checksum.
   - Updates `isoinspect.rb` with the new version, URL, and checksum.
   - Opens a PR against the tap repository or pushes directly if automation credentials are scoped appropriately.
   - Runs `brew audit --strict isoinspect` and `brew install --build-from-source isoinspect` to confirm formula health.
4. **Update Cadence** — when hotfixing CLI-only bugs, ship both the tap update and notarized ZIP in the same release tag even if the GUI app remains unchanged. Document the delta in release notes and keep marketing version parity to avoid confusion.

## Linux Artifact Delivery
1. **Target Platforms** — provide glibc-compatible x86_64 and musl-compatible static binaries. Use Swift cross-compilation Docker images to build `isoinspect` with `swift build -c release --triple x86_64-unknown-linux-gnu` and `swift build -c release --triple x86_64-unknown-linux-musl`.
2. **Packaging** — publish `.tar.gz` archives with the binary, LICENSE, and README snippet. Include a `bin/isoinspect` path so tarball extraction mirrors Homebrew layouts.
3. **Checksums & Signatures** — sign each tarball with minisign or GPG (project preference: minisign for lightweight verification). Publish public keys in the README and store signatures under `releases/<version>/checksums/` with SHA256 manifests.
4. **Distribution** — reference tarball URLs in release notes and tap formula `on_linux` blocks. Avoid distro-specific packages until community demand and maintainer capacity justify the maintenance burden.
5. **CI Validation** — extend GitHub Actions to smoke-test Linux tarballs by running `isoinspect --help` inside Ubuntu (glibc) and Alpine (musl) containers after extraction. Record logs in release assets.

## Automation Additions
- Update the release pipeline to upload CLI ZIPs and Linux tarballs using the same job that publishes DocC archives. Store artifact names as `ISOInspector-<version>-cli-macos.zip`, `ISOInspector-<version>-cli-linux-gnu.tar.gz`, and `ISOInspector-<version>-cli-linux-musl.tar.gz` for consistency with the runbook.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L102-L118】
- Add a `scripts/package_cli.sh` helper that orchestrates building, signing, zipping, notarizing, stapling, and checksum generation. The script emits `@todo` placeholders for future automation (e.g., S3 mirroring) so tasks stay traceable through PDD.
- Integrate checksum verification into the go/no-go checklist: QA confirms the published checksums match local builds by running `shasum -a 256 <artifact>` before signing off.

## Risk Assessment & Mitigations
| Channel | Risk | Impact | Mitigation |
| --- | --- | --- | --- |
| macOS notarized ZIP | Notarization rejects binaries lacking hardened runtime entitlements. | Blocks distribution; release delayed. | Enforce `codesign --options=runtime` in `scripts/package_cli.sh` and validate locally with `spctl` before notarization submission. |
| macOS DMG | Disk image fails Gatekeeper due to missing staple. | Users receive security prompts. | Staple DMGs post-notarization and include `spctl` verification in release checklist. |
| Homebrew tap | Formula checksum drift or tap repository PR delays release. | Users cannot install via `brew`. | Automate checksum updates, run `brew audit` in CI, and maintain a fallback script in release notes for manual installation. |
| Linux tarballs | Glibc/musl incompatibilities or missing ICU dependencies. | CLI crashes on launch; support burden increases. | Use static linking builds, smoke-test in Ubuntu and Alpine containers, and document runtime requirements in README. |
| Signing keys | Expired Developer ID or minisign keys. | Notarization fails; signatures invalid. | Track certificate expiry in `DistributionMetadata.json` comments and schedule renewal alerts one month prior; rotate minisign keys with release engineer ownership log. |

## Follow-Up Actions
- Document `scripts/package_cli.sh` usage and automation hooks in the release engineering wiki once implemented.
- Evaluate publishing a checksum feed for downstream automation once initial release cadence stabilizes.
