#!/usr/bin/env python3
"""Generate ISOInspector fixture assets.

The script supports two workflows:

* Regenerating the deterministic, base64-encoded text fixtures that ship with
  the unit tests. These synthetic fixtures remain lightweight and live under
  ``Tests/ISOInspectorKitTests/Fixtures/Media``.
* Mirroring external media fixtures described by a manifest. Each manifest
  entry is downloaded, verified with SHA-256, and catalogued with an
  accompanying license text so larger regression assets can be staged outside
  of the test bundle.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import logging
import shutil
import sys
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable, Iterator, Optional

ROOT = Path(__file__).resolve().parent
MEDIA = ROOT / "Media"
TEXT_EXTENSION = "txt"
REPO_ROOT = ROOT.parents[3]
DEFAULT_DISTRIBUTION_ROOT = REPO_ROOT / "Distribution" / "Fixtures"
DEFAULT_LICENSE_ROOT = REPO_ROOT / "Documentation" / "FixtureCatalog" / "licenses"
BUFFER_SIZE = 1024 * 64

logger = logging.getLogger(__name__)


class ManifestValidationError(RuntimeError):
    """Raised when the manifest is missing required metadata."""


class ChecksumMismatchError(RuntimeError):
    """Raised when downloaded content fails checksum validation."""


@dataclass
class FixtureResult:
    """Report describing the outcome for a single manifest entry."""

    fixture_id: str
    destination: Path
    checksum: str
    downloaded: bool
    license_path: Optional[Path]


def normalize_sha256(value: str) -> str:
    """Return the lowercase SHA-256 digest without prefixes."""

    digest = value.strip()
    prefix = "sha256:"
    if digest.lower().startswith(prefix):
        digest = digest[len(prefix) :]
    if len(digest) != 64:
        raise ManifestValidationError(
            f"Expected 64-character SHA-256 digest, received '{value}'"
        )
    return digest.lower()


def load_manifest(path: Path) -> dict:
    if not path.exists():
        raise ManifestValidationError(f"Manifest not found at {path}")
    with path.open("r", encoding="utf-8") as handle:
        try:
            return json.load(handle)
        except json.JSONDecodeError as exc:
            raise ManifestValidationError(f"Invalid manifest JSON: {exc}") from exc


def _stream_from_url(url: str) -> Iterator[bytes]:
    with urllib.request.urlopen(url) as response:  # noqa: S310 - trusted manifest input
        while True:
            chunk = response.read(BUFFER_SIZE)
            if not chunk:
                break
            yield chunk


def _compute_sha256_for_path(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(BUFFER_SIZE), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def _download_entry(
    url: str,
    destination: Path,
    checksum: str,
    downloader: Optional[Callable[[str], Iterator[bytes]]] = None,
) -> tuple[str, bool]:
    if destination.exists():
        existing_digest = _compute_sha256_for_path(destination)
        if existing_digest.lower() == checksum:
            logger.info("Reusing existing fixture \"%s\"", destination)
            return existing_digest, False
        logger.warning(
            "Existing file %s failed checksum validation; redownloading", destination
        )
        destination.unlink()

    destination.parent.mkdir(parents=True, exist_ok=True)
    hasher = hashlib.sha256()
    generator = downloader(url) if downloader else _stream_from_url(url)
    with tempfile.NamedTemporaryFile(delete=False, dir=destination.parent) as handle:
        temp_path = Path(handle.name)
        try:
            for chunk in generator:
                if not chunk:
                    continue
                handle.write(chunk)
                hasher.update(chunk)
        except Exception:
            temp_path.unlink(missing_ok=True)
            raise

    digest = hasher.hexdigest()
    if digest.lower() != checksum:
        Path(temp_path).unlink(missing_ok=True)
        raise ChecksumMismatchError(
            f"Checksum mismatch for {destination.name}: expected {checksum}, got {digest}"
        )

    Path(temp_path).replace(destination)
    logger.info("Downloaded %s (%s)", destination.name, digest)
    return digest, True


def _ensure_license(
    entry: dict,
    license_root: Path,
    dry_run: bool,
    downloader: Optional[Callable[[str], Iterator[bytes]]],
    manifest_dir: Path,
) -> Optional[Path]:
    metadata = entry.get("license")
    if not metadata:
        return None

    filename = metadata.get("filename") or f"{entry['id']}.txt"
    license_path = license_root / filename
    text = metadata.get("text")
    source_path = metadata.get("path")
    url = metadata.get("url")
    checksum_value = metadata.get("sha256")

    if not any([text, source_path, url]):
        raise ManifestValidationError(
            f"License metadata for {entry['id']} must define text, path, or url"
        )

    if dry_run:
        if source_path and not (manifest_dir / source_path).expanduser().resolve().exists():
            raise ManifestValidationError(
                f"License source path {source_path} missing for {entry['id']}"
            )
        return license_path

    license_path.parent.mkdir(parents=True, exist_ok=True)
    if text:
        license_path.write_text(text, encoding="utf-8")
    elif source_path:
        resolved_path = (manifest_dir / source_path).expanduser().resolve()
        if not resolved_path.exists():
            raise ManifestValidationError(
                f"License source path {source_path} missing for {entry['id']}"
            )
        shutil.copyfile(resolved_path, license_path)
    elif url:
        checksum = normalize_sha256(checksum_value) if checksum_value else None
        license_path = _download_license(url, license_path, checksum, downloader)

    return license_path


def _download_license(
    url: str,
    destination: Path,
    checksum: Optional[str],
    downloader: Optional[Callable[[str], Iterator[bytes]]],
) -> Path:
    generator = downloader(url) if downloader else _stream_from_url(url)
    hasher = hashlib.sha256() if checksum else None
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=False, dir=destination.parent) as handle:
        temp_path = Path(handle.name)
        try:
            for chunk in generator:
                if not chunk:
                    continue
                handle.write(chunk)
                if hasher:
                    hasher.update(chunk)
        except Exception:
            temp_path.unlink(missing_ok=True)
            raise

    if hasher:
        digest = hasher.hexdigest()
        if digest.lower() != checksum:
            temp_path.unlink(missing_ok=True)
            raise ChecksumMismatchError(
                f"License checksum mismatch for {destination.name}:"
                f" expected {checksum}, got {digest}"
            )

    Path(temp_path).replace(destination)
    return destination


def process_manifest(
    manifest_path: Path,
    *,
    distribution_root: Optional[Path] = None,
    license_root: Optional[Path] = None,
    downloader: Optional[Callable[[str], Iterator[bytes]]] = None,
    dry_run: bool = False,
) -> list[FixtureResult]:
    manifest = load_manifest(manifest_path)
    fixtures = manifest.get("fixtures")
    if fixtures is None:
        raise ManifestValidationError("Manifest missing 'fixtures' key")

    resolved_distribution = distribution_root or DEFAULT_DISTRIBUTION_ROOT
    resolved_license = license_root or DEFAULT_LICENSE_ROOT
    manifest_dir = manifest_path.expanduser().resolve().parent
    results: list[FixtureResult] = []

    for entry in fixtures:
        fixture_id = entry.get("id")
        if not fixture_id:
            raise ManifestValidationError("Fixture entry missing 'id'")
        url = entry.get("url")
        if not url:
            raise ManifestValidationError(f"Fixture {fixture_id} missing url")
        raw_checksum = entry.get("sha256")
        if not raw_checksum:
            raise ManifestValidationError(
                f"Fixture {fixture_id} missing sha256 digest"
            )
        checksum = normalize_sha256(raw_checksum)

        destination_meta = entry.get("destination") or {}
        category = destination_meta.get("category")
        filename = destination_meta.get("filename")
        if not category or not filename:
            raise ManifestValidationError(
                f"Fixture {fixture_id} destination requires category and filename"
            )
        destination = resolved_distribution / category / filename

        license_path = _ensure_license(
            entry,
            resolved_license,
            dry_run,
            downloader,
            manifest_dir,
        )

        downloaded = False
        digest = checksum
        if dry_run:
            logger.info("[dry-run] Would download %s to %s", fixture_id, destination)
        else:
            digest, downloaded = _download_entry(url, destination, checksum, downloader)

        results.append(
            FixtureResult(
                fixture_id=fixture_id,
                destination=destination,
                checksum=digest,
                downloaded=downloaded,
                license_path=license_path,
            )
        )

    return results


def box(box_type: str, payload: bytes) -> bytes:
    if len(box_type) != 4:
        raise ValueError("Box type must be exactly four characters")
    size = 8 + len(payload)
    return size.to_bytes(4, "big") + box_type.encode("ascii") + payload


def large_box(box_type: str, payload: bytes) -> bytes:
    if len(box_type) != 4:
        raise ValueError("Box type must be exactly four characters")
    total_size = 16 + len(payload)
    return (
        (1).to_bytes(4, "big")
        + box_type.encode("ascii")
        + total_size.to_bytes(8, "big")
        + payload
    )


def brand_payload(major: str, minor_version: int, compatibles: Iterable[str]) -> bytes:
    payload = major.encode("ascii")
    payload += minor_version.to_bytes(4, "big")
    for brand in compatibles:
        payload += brand.encode("ascii")
    return payload


def build_fragmented_init() -> bytes:
    ftyp = box(
        "ftyp",
        brand_payload("iso5", 0x200, ["iso5", "dash"]),
    )
    mvhd_payload = bytes([0, 0, 0, 0]) + bytes(96)
    mvhd = box("mvhd", mvhd_payload)
    moov = box("moov", mvhd)
    return ftyp + moov


def build_dash_segment() -> bytes:
    styp = box(
        "styp",
        brand_payload("iso6", 0x1, ["msdh", "dash"]),
    )
    sidx_payload = bytes([0, 0, 0, 0]) + bytes(28)
    sidx = box("sidx", sidx_payload)
    mfhd_payload = bytes([0, 0, 0, 0]) + (1).to_bytes(4, "big")
    mfhd = box("mfhd", mfhd_payload)
    tfhd_payload = bytes([0, 0, 0, 0]) + (1).to_bytes(4, "big")
    tfhd = box("tfhd", tfhd_payload)
    tfdt_payload = bytes([1, 0, 0, 0]) + bytes(12)
    tfdt = box("tfdt", tfdt_payload)
    trun_payload = bytes([0, 0, 3, 1]) + (1).to_bytes(4, "big") + bytes(12)
    trun = box("trun", trun_payload)
    traf = box("traf", tfhd + tfdt + trun)
    moof = box("moof", mfhd + traf)
    mdat_payload = bytes([0xAA]) * 512
    mdat = box("mdat", mdat_payload)
    return styp + sidx + moof + mdat


def build_large_mdat() -> bytes:
    ftyp = box(
        "ftyp",
        brand_payload("isom", 0, ["isom", "iso2"]),
    )
    mvhd_payload = bytes([0, 0, 0, 0]) + bytes(96)
    mvhd = box("mvhd", mvhd_payload)
    moov = box("moov", mvhd)
    mdat_payload = bytes([0x55]) * 8192
    mdat = large_box("mdat", mdat_payload)
    return ftyp + moov + mdat


def build_malformed_truncated() -> bytes:
    ftyp = box(
        "ftyp",
        brand_payload("isom", 0, ["isom"]),
    )
    declared_size = 80
    actual_payload = bytes(8)
    moov_header = declared_size.to_bytes(4, "big") + b"moov"
    return ftyp + moov_header + actual_payload


def write_fixture(name: str, data: bytes, media_root: Path = MEDIA) -> Path:
    path = media_root / f"{name}.{TEXT_EXTENSION}"
    encoded = base64.b64encode(data).decode("ascii")
    media_root.mkdir(parents=True, exist_ok=True)
    path.write_text(encoded, encoding="utf-8")
    logger.info("Wrote %s (%d bytes source)", path.name, len(data))
    return path


def generate_text_fixtures(media_root: Path = MEDIA) -> list[Path]:
    return [
        write_fixture("fragmented_stream_init", build_fragmented_init(), media_root),
        write_fixture("dash_segment_1", build_dash_segment(), media_root),
        write_fixture("large_mdat_placeholder", build_large_mdat(), media_root),
        write_fixture("malformed_truncated", build_malformed_truncated(), media_root),
    ]


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate deterministic fixtures and optionally download external "
            "assets described by a manifest."
        )
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=None,
        help="Path to manifest describing remote fixtures to download.",
    )
    parser.add_argument(
        "--distribution-root",
        type=Path,
        default=DEFAULT_DISTRIBUTION_ROOT,
        help="Directory root for mirrored fixture binaries.",
    )
    parser.add_argument(
        "--license-root",
        type=Path,
        default=DEFAULT_LICENSE_ROOT,
        help="Directory for mirrored license texts.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate manifest metadata without downloading fixtures.",
    )
    parser.add_argument(
        "--skip-text-fixtures",
        action="store_true",
        help="Skip regeneration of base64 text fixtures.",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        help="Logging level (DEBUG, INFO, WARNING, ...).",
    )
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)

    logging.basicConfig(level=getattr(logging, args.log_level.upper(), logging.INFO))

    if not args.skip_text_fixtures:
        generate_text_fixtures()

    if args.manifest:
        try:
            results = process_manifest(
                args.manifest,
                distribution_root=args.distribution_root,
                license_root=args.license_root,
                dry_run=args.dry_run,
            )
        except (ManifestValidationError, ChecksumMismatchError) as exc:
            logger.error("Manifest processing failed: %s", exc)
            return 1
        logger.info(
            "Processed %d manifest entr%s",
            len(results),
            "y" if len(results) == 1 else "ies",
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
