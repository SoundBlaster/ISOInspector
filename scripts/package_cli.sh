#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<USAGE
Usage: $(basename "$0") --version <version> [--profile <keychain-profile>] [--bundle-id <bundle-id>] [--skip-notarize] [--skip-build]

Packages the isoinspect CLI for release:
  1. Builds the release binary.
  2. Codesigns the executable when the codesign tool is available.
  3. Assembles a distributable ZIP under Distribution/CLI/<version>/.
  4. Computes SHA256/SHA512 checksums.
  5. Optionally submits the ZIP for notarization and staples the ticket.

Run from any repository directory. macOS hosts gain signing and notarization steps; Linux hosts can dry-run packaging prior to notarization.
USAGE
}

version=""
profile=""
bundle_id="com.isoinspector.cli"
skip_notarize=false
skip_build=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            version="${2:-}"
            shift 2
            ;;
        --profile)
            profile="${2:-}"
            shift 2
            ;;
        --bundle-id)
            bundle_id="${2:-}"
            shift 2
            ;;
        --skip-notarize)
            skip_notarize=true
            shift 1
            ;;
        --skip-build)
            skip_build=true
            shift 1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$version" ]]; then
    echo "Error: --version is required." >&2
    usage
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cli_product="isoinspect"
release_build_dir="$repo_root/.build/release"
release_binary="$release_build_dir/$cli_product"
artifact_root="$repo_root/Distribution/CLI/$version"
mkdir -p "$artifact_root"

echo "==> Packaging isoinspect $version"

if [[ "$skip_build" == false ]]; then
    echo "==> Building release binary"
    swift build -c release --product "$cli_product"
else
    echo "==> Skipping build (requested)"
fi

if [[ ! -f "$release_binary" ]]; then
    echo "Error: expected binary $release_binary not found. Ensure swift build succeeded." >&2
    exit 1
fi

payload_dir="$artifact_root/payload"
rm -rf "$payload_dir"

mkdir -p "$payload_dir"

cp "$release_binary" "$payload_dir/$cli_product"
chmod 755 "$payload_dir/$cli_product"

readme_path="$payload_dir/README-cli.txt"
cat <<README > "$readme_path"
ISOInspector CLI $version
=========================

This archive ships the notarized isoinspect command-line tool. To install:

1. Extract the archive:
   unzip ISOInspector-$version-cli-macos.zip
2. Move the binary into a directory on your PATH (for example, /usr/local/bin):
   install -m 755 isoinspect /usr/local/bin/isoinspect
3. Review the CLI manual for sandbox automation tips and telemetry flags.

For more usage examples see Documentation/ISOInspector.docc/Manuals/CLI.md in the repository.
README

if command -v codesign >/dev/null 2>&1; then
    echo "==> Codesigning binary"
    codesign --force --sign "Developer ID Application" --options=runtime --timestamp "$payload_dir/$cli_product"
else
    echo "==> Skipping codesign (codesign tool not available)."
fi

zip_name="ISOInspector-$version-cli-macos.zip"
zip_path="$artifact_root/$zip_name"
rm -f "$zip_path"

if command -v ditto >/dev/null 2>&1; then
    echo "==> Creating ZIP with ditto"
    (cd "$payload_dir" && ditto -c -k --sequesterRsrc --keepParent . "$zip_path")
else
    echo "==> Creating ZIP with zip"
    (cd "$payload_dir" && zip -qry "$zip_path" .)
fi

echo "==> Calculating checksums"
if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$zip_path" > "$artifact_root/ISOInspector-$version-cli-macos.sha256"
    shasum -a 512 "$zip_path" > "$artifact_root/ISOInspector-$version-cli-macos.sha512"
else
    echo "Warning: shasum not available; skipping checksum files." >&2
fi

if [[ "$skip_notarize" == false ]]; then
    if [[ -n "$profile" ]]; then
        echo "==> Submitting ZIP for notarization"
        "$repo_root/scripts/notarize_app.sh" --artifact "$zip_path" --profile "$profile" --primary-bundle-id "$bundle_id"
        if command -v xcrun >/dev/null 2>&1; then
            echo "==> Stapling notarization ticket"
            xcrun stapler staple "$zip_path"
        else
            echo "==> Skipping stapler (xcrun unavailable)."
        fi
    else
        echo "Warning: --profile not provided; skipping notarization. Use --skip-notarize to silence this warning." >&2
    fi
else
    echo "==> Notarization skipped by request."
fi

echo "==> CLI package ready: $zip_path"
echo "    Checksum files:"
ls "$artifact_root" | grep 'cli-macos.sha' || true

rm -rf "$payload_dir"
