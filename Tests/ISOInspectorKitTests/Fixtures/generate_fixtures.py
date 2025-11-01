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
REPO_ROOT = ROOT.parents[2]
DEFAULT_DISTRIBUTION_ROOT = REPO_ROOT / "Distribution" / "Fixtures"
DEFAULT_LICENSE_ROOT = REPO_ROOT / "Documentation" / "FixtureCatalog" / "licenses"
DEFAULT_CORRUPT_ROOT = REPO_ROOT / "Fixtures" / "Corrupt"
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


def full_box(box_type: str, version: int, flags: int, payload: bytes) -> bytes:
    if version < 0 or version > 255:
        raise ValueError("Version must fit in a single byte")
    if flags < 0 or flags > 0xFFFFFF:
        raise ValueError("Flags must fit in 24 bits")
    header = bytes([version]) + flags.to_bytes(3, "big")
    return box(box_type, header + payload)


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


def build_movie_fragment_header(sequence_number: int) -> bytes:
    payload = bytes([0, 0, 0, 0]) + sequence_number.to_bytes(4, "big")
    return full_box("mfhd", 0, 0, payload)


def build_track_fragment_header(
    track_id: int,
    flags: int,
    *,
    base_data_offset: Optional[int] = None,
    sample_description_index: Optional[int] = None,
    default_sample_duration: Optional[int] = None,
    default_sample_size: Optional[int] = None,
    default_sample_flags: Optional[int] = None,
) -> bytes:
    payload = bytearray()
    payload.extend(track_id.to_bytes(4, "big"))
    if flags & 0x000001:
        if base_data_offset is None:
            raise ValueError("base_data_offset required when flag set")
        payload.extend(base_data_offset.to_bytes(8, "big", signed=False))
    if flags & 0x000002:
        if sample_description_index is None:
            raise ValueError("sample_description_index required when flag set")
        payload.extend(sample_description_index.to_bytes(4, "big"))
    if flags & 0x000008:
        if default_sample_duration is None:
            raise ValueError("default_sample_duration required when flag set")
        payload.extend(default_sample_duration.to_bytes(4, "big"))
    if flags & 0x000010:
        if default_sample_size is None:
            raise ValueError("default_sample_size required when flag set")
        payload.extend(default_sample_size.to_bytes(4, "big"))
    if flags & 0x000020:
        if default_sample_flags is None:
            raise ValueError("default_sample_flags required when flag set")
        payload.extend(default_sample_flags.to_bytes(4, "big"))
    return full_box("tfhd", 0, flags, bytes(payload))


def build_track_fragment_decode_time(base_decode_time: int, *, version: int = 1) -> bytes:
    if version == 0:
        if base_decode_time < 0 or base_decode_time > 0xFFFFFFFF:
            raise ValueError("base_decode_time must fit in 32 bits for version 0")
        payload = base_decode_time.to_bytes(4, "big")
    elif version == 1:
        if base_decode_time < 0 or base_decode_time > 0xFFFFFFFFFFFFFFFF:
            raise ValueError("base_decode_time must fit in 64 bits for version 1")
        payload = base_decode_time.to_bytes(8, "big")
    else:
        raise ValueError("Unsupported tfdt version")
    return full_box("tfdt", version, 0, payload)


def build_track_run(
    *,
    sample_count: int,
    version: int = 0,
    flags: int,
    data_offset: Optional[int] = None,
    first_sample_flags: Optional[int] = None,
    sample_durations: Optional[list[int]] = None,
    sample_sizes: Optional[list[int]] = None,
    sample_flags: Optional[list[int]] = None,
    composition_offsets: Optional[list[int]] = None,
) -> bytes:
    payload = bytearray()
    payload.extend(sample_count.to_bytes(4, "big"))

    if flags & 0x000001:
        if data_offset is None:
            raise ValueError("data_offset required when flag set")
        payload.extend(int(data_offset).to_bytes(4, "big", signed=True))
    if flags & 0x000004:
        if first_sample_flags is None:
            raise ValueError("first_sample_flags required when flag set")
        payload.extend(first_sample_flags.to_bytes(4, "big"))

    durations = sample_durations or [None] * sample_count
    sizes = sample_sizes or [None] * sample_count
    flags_list = sample_flags or [None] * sample_count
    offsets = composition_offsets or [None] * sample_count

    for index in range(sample_count):
        if flags & 0x000100:
            value = durations[index]
            if value is None:
                raise ValueError("sample_durations missing entry")
            payload.extend(int(value).to_bytes(4, "big"))
        if flags & 0x000200:
            value = sizes[index]
            if value is None:
                raise ValueError("sample_sizes missing entry")
            payload.extend(int(value).to_bytes(4, "big"))
        if flags & 0x000400:
            value = flags_list[index]
            if value is None:
                raise ValueError("sample_flags missing entry")
            payload.extend(int(value).to_bytes(4, "big"))
        if flags & 0x000800:
            value = offsets[index]
            if value is None:
                raise ValueError("composition_offsets missing entry")
            if version == 0:
                payload.extend(int(value).to_bytes(4, "big"))
            elif version == 1:
                payload.extend(int(value).to_bytes(4, "big", signed=True))
            else:
                raise ValueError("Unsupported trun version")

    return full_box("trun", version, flags, bytes(payload))


def build_fragmented_multi_trun() -> bytes:
    styp = box("styp", brand_payload("iso6", 0x1, ["msdh", "dash"]))
    mfhd = build_movie_fragment_header(2)
    tfhd_flags = 0x000002 | 0x000008 | 0x000010 | 0x000020 | 0x000200
    tfhd = build_track_fragment_header(
        track_id=1,
        flags=tfhd_flags,
        sample_description_index=1,
        default_sample_duration=100,
        default_sample_size=400,
        default_sample_flags=0x0010_0000,
    )
    tfdt = build_track_fragment_decode_time(1_000, version=1)
    trun_primary_flags = 0x000001 | 0x000100 | 0x000200 | 0x000800
    trun_primary = build_track_run(
        sample_count=2,
        version=0,
        flags=trun_primary_flags,
        data_offset=128,
        sample_durations=[90, 90],
        sample_sizes=[300, 320],
        composition_offsets=[5, 15],
    )
    trun_tail_flags = 0x000200
    trun_tail = build_track_run(
        sample_count=1,
        version=0,
        flags=trun_tail_flags,
        sample_sizes=[380],
    )
    traf = box("traf", tfhd + tfdt + trun_primary + trun_tail)
    moof = box("moof", mfhd + traf)
    mdat = box("mdat", bytes([0x11]) * 1200)
    return styp + moof + mdat


def build_fragmented_negative_offset() -> bytes:
    styp = box("styp", brand_payload("iso6", 0x1, ["msdh", "dash"]))
    mfhd = build_movie_fragment_header(3)
    tfhd_flags = 0x000001 | 0x000008 | 0x000010
    tfhd = build_track_fragment_header(
        track_id=2,
        flags=tfhd_flags,
        base_data_offset=32,
        default_sample_duration=200,
        default_sample_size=450,
    )
    tfdt = build_track_fragment_decode_time(2_000, version=1)
    trun_flags = 0x000001 | 0x000100 | 0x000200 | 0x000800
    trun = build_track_run(
        sample_count=1,
        version=1,
        flags=trun_flags,
        data_offset=-64,
        sample_durations=[200],
        sample_sizes=[450],
        composition_offsets=[-20],
    )
    traf = box("traf", tfhd + tfdt + trun)
    moof = box("moof", mfhd + traf)
    mdat = box("mdat", bytes([0x22]) * 512)
    return styp + moof + mdat


def build_fragmented_no_tfdt() -> bytes:
    styp = box("styp", brand_payload("iso6", 0x1, ["msdh", "dash"]))
    mfhd = build_movie_fragment_header(4)
    tfhd_flags = 0x000002 | 0x000010 | 0x000200
    tfhd = build_track_fragment_header(
        track_id=3,
        flags=tfhd_flags,
        sample_description_index=1,
        default_sample_size=256,
    )
    trun_flags = 0x000001 | 0x000100 | 0x000200
    trun = build_track_run(
        sample_count=2,
        version=0,
        flags=trun_flags,
        data_offset=96,
        sample_durations=[120, 120],
        sample_sizes=[200, 220],
    )
    traf = box("traf", tfhd + trun)
    moof = box("moof", mfhd + traf)
    mdat = box("mdat", bytes([0x33]) * 512)
    return styp + moof + mdat


def build_movie_header(timescale: int, duration: int, next_track_id: int) -> bytes:
    payload = bytearray()
    payload.extend((0).to_bytes(1, "big"))  # version
    payload.extend((0).to_bytes(3, "big"))  # flags
    payload.extend((0).to_bytes(4, "big"))  # creation time
    payload.extend((0).to_bytes(4, "big"))  # modification time
    payload.extend(timescale.to_bytes(4, "big"))
    payload.extend(duration.to_bytes(4, "big"))
    payload.extend((0x0001_0000).to_bytes(4, "big"))  # rate 1.0
    payload.extend((0x0100).to_bytes(2, "big"))  # volume 1.0
    payload.extend(bytes(10))  # reserved
    matrix = [
        0x0001_0000,
        0,
        0,
        0,
        0x0001_0000,
        0,
        0,
        0,
        0x4000_0000,
    ]
    for value in matrix:
        payload.extend(int(value).to_bytes(4, "big", signed=True))
    payload.extend(bytes(24))  # pre-defined
    payload.extend(next_track_id.to_bytes(4, "big"))
    return box("mvhd", bytes(payload))


def build_track_header(track_id: int, duration: int, width: int = 0, height: int = 0) -> bytes:
    payload = bytearray()
    payload.extend((0).to_bytes(1, "big"))  # version
    payload.extend((0x0000_0007).to_bytes(3, "big"))  # flags: enabled + in movie + in preview
    payload.extend((0).to_bytes(4, "big"))  # creation time
    payload.extend((0).to_bytes(4, "big"))  # modification time
    payload.extend(track_id.to_bytes(4, "big"))
    payload.extend((0).to_bytes(4, "big"))  # reserved
    payload.extend(duration.to_bytes(4, "big"))
    payload.extend((0).to_bytes(4, "big"))  # reserved
    payload.extend((0).to_bytes(4, "big"))  # reserved
    payload.extend((0).to_bytes(2, "big", signed=True))  # layer
    payload.extend((0).to_bytes(2, "big", signed=True))  # alternate group
    payload.extend((0).to_bytes(2, "big"))  # volume (0 for video)
    payload.extend((0).to_bytes(2, "big"))  # reserved
    matrix = [
        0x0001_0000,
        0,
        0,
        0,
        0x0001_0000,
        0,
        0,
        0,
        0x4000_0000,
    ]
    for value in matrix:
        payload.extend(int(value).to_bytes(4, "big", signed=True))
    payload.extend((width << 16).to_bytes(4, "big"))
    payload.extend((height << 16).to_bytes(4, "big"))
    return box("tkhd", bytes(payload))


def pack_language(code: str) -> bytes:
    if len(code) != 3:
        raise ValueError("ISO-639-2 language code must be 3 characters")
    scalars = [ord(char) - 0x60 for char in code.lower()]
    value = ((scalars[0] & 0x1F) << 10) | ((scalars[1] & 0x1F) << 5) | (scalars[2] & 0x1F)
    return value.to_bytes(2, "big")


def build_media_header(timescale: int, duration: int, language: str = "eng") -> bytes:
    payload = bytearray()
    payload.extend((0).to_bytes(1, "big"))  # version
    payload.extend((0).to_bytes(3, "big"))  # flags
    payload.extend((0).to_bytes(4, "big"))  # creation time
    payload.extend((0).to_bytes(4, "big"))  # modification time
    payload.extend(timescale.to_bytes(4, "big"))
    payload.extend(duration.to_bytes(4, "big"))
    payload.extend(pack_language(language))
    payload.extend((0).to_bytes(2, "big"))  # pre-defined
    return box("mdhd", bytes(payload))


def build_edit_list_box(entries: list[dict], version: int = 0) -> bytes:
    payload = bytearray()
    payload.append(version & 0xFF)
    payload.extend((0).to_bytes(3, "big"))  # flags
    payload.extend(len(entries).to_bytes(4, "big"))
    for entry in entries:
        segment_duration = int(entry["segment_duration"])
        media_time = int(entry["media_time"])
        media_rate_integer = int(entry.get("media_rate_integer", 1))
        media_rate_fraction = int(entry.get("media_rate_fraction", 0))
        if version == 1:
            payload.extend(segment_duration.to_bytes(8, "big"))
            payload.extend(media_time.to_bytes(8, "big", signed=True))
        else:
            payload.extend(segment_duration.to_bytes(4, "big"))
            payload.extend(media_time.to_bytes(4, "big", signed=True))
        payload.extend(media_rate_integer.to_bytes(2, "big", signed=True))
        payload.extend(media_rate_fraction.to_bytes(2, "big"))
    return box("elst", bytes(payload))


def build_edit_list_fixture(
    *,
    entries: list[dict],
    movie_timescale: int = 600,
    movie_duration: int,
    track_id: int,
    track_duration: int,
    media_timescale: int = 48_000,
    media_duration: int,
    version: int = 0,
) -> bytes:
    ftyp = box("ftyp", brand_payload("isom", 0, ["isom", "iso2"]))
    mvhd = build_movie_header(movie_timescale, movie_duration, next_track_id=track_id + 1)
    tkhd = build_track_header(track_id, track_duration)
    mdhd = build_media_header(media_timescale, media_duration)
    elst = build_edit_list_box(entries, version=version)
    edts = box("edts", elst)
    mdia = box("mdia", mdhd)
    trak = box("trak", tkhd + edts + mdia)
    moov = box("moov", mvhd + trak)
    return ftyp + moov


def build_edit_list_empty() -> bytes:
    return build_edit_list_fixture(
        entries=[],
        movie_duration=1_200,
        track_id=1,
        track_duration=900,
        media_duration=96_000,
    )


def build_edit_list_single_offset() -> bytes:
    entries = [
        {
            "segment_duration": 120,
            "media_time": -1,
            "media_rate_integer": 1,
            "media_rate_fraction": 0,
        },
        {
            "segment_duration": 780,
            "media_time": 240,
            "media_rate_integer": 1,
            "media_rate_fraction": 0,
        },
    ]
    return build_edit_list_fixture(
        entries=entries,
        movie_duration=900,
        track_id=2,
        track_duration=900,
        media_duration=64_000,
    )


def build_edit_list_multi_segment() -> bytes:
    entries = [
        {"segment_duration": 400, "media_time": 0},
        {"segment_duration": 400, "media_time": 400},
        {"segment_duration": 400, "media_time": 800},
    ]
    return build_edit_list_fixture(
        entries=entries,
        movie_duration=1_000,
        track_id=3,
        track_duration=950,
        media_duration=96_000,
    )


def build_edit_list_rate_adjusted() -> bytes:
    entries = [
        {
            "segment_duration": 300,
            "media_time": 0,
            "media_rate_integer": -1,
            "media_rate_fraction": 0,
        },
        {
            "segment_duration": 300,
            "media_time": 300,
            "media_rate_integer": 2,
            "media_rate_fraction": 0,
        },
        {
            "segment_duration": 0,
            "media_time": 600,
            "media_rate_integer": 1,
            "media_rate_fraction": 1,
        },
    ]
    return build_edit_list_fixture(
        entries=entries,
        movie_duration=600,
        track_id=4,
        track_duration=600,
        media_duration=48_000,
    )


def build_sample_encryption_box() -> bytes:
    payload = bytearray()
    payload.extend((0x010203).to_bytes(3, "big"))
    payload.append(8)
    payload.extend(bytes(range(0x20, 0x30)))
    payload.extend((2).to_bytes(4, "big"))
    payload.extend(bytes(range(0x01, 0x09)))
    payload.extend((1).to_bytes(2, "big"))
    payload.extend((0x0010).to_bytes(2, "big"))
    payload.extend((0x0000_0020).to_bytes(4, "big"))
    payload.extend(bytes(range(0x11, 0x19)))
    payload.extend((2).to_bytes(2, "big"))
    payload.extend((0x0004).to_bytes(2, "big"))
    payload.extend((0x0000_0008).to_bytes(4, "big"))
    payload.extend((0x0006).to_bytes(2, "big"))
    payload.extend((0x0000_000C).to_bytes(4, "big"))
    return full_box("senc", 0, 0x000003, bytes(payload))


def build_sample_aux_info_offsets_box() -> bytes:
    payload = bytearray()
    payload.extend(b"cenc")
    payload.extend((1).to_bytes(4, "big"))
    payload.extend((2).to_bytes(4, "big"))
    payload.extend((0x0000_0000_0000_0200).to_bytes(8, "big"))
    payload.extend((0x0000_0000_0000_0380).to_bytes(8, "big"))
    return full_box("saio", 1, 0x000001, bytes(payload))


def build_sample_aux_info_sizes_box() -> bytes:
    payload = bytearray()
    payload.extend(b"cenc")
    payload.extend((1).to_bytes(4, "big"))
    payload.append(0)
    payload.extend((2).to_bytes(4, "big"))
    payload.extend(bytes([0x10, 0x18]))
    return full_box("saiz", 0, 0x000001, bytes(payload))


def build_sample_encryption_fragment() -> bytes:
    ftyp = box("ftyp", brand_payload("iso6", 0, ["iso6", "dash"]))
    mvhd = build_movie_header(600, 600, next_track_id=2)
    tkhd = build_track_header(1, 600)
    mdhd = build_media_header(48_000, 48_000)
    mdia = box("mdia", mdhd)
    trak = box("trak", tkhd + mdia)
    moov = box("moov", mvhd + trak)

    mfhd = build_movie_fragment_header(1)
    tfhd_flags = 0x000001 | 0x000002 | 0x000008 | 0x000010
    tfhd = build_track_fragment_header(
        track_id=1,
        flags=tfhd_flags,
        base_data_offset=0x0000_0000_0000_0200,
        sample_description_index=1,
        default_sample_duration=120,
        default_sample_size=256,
    )
    tfdt = build_track_fragment_decode_time(1_000, version=1)
    trun_flags = 0x000001 | 0x000100 | 0x000200
    trun = build_track_run(
        sample_count=2,
        version=0,
        flags=trun_flags,
        data_offset=128,
        sample_durations=[120, 120],
        sample_sizes=[256, 256],
    )
    senc = build_sample_encryption_box()
    saio = build_sample_aux_info_offsets_box()
    saiz = build_sample_aux_info_sizes_box()
    traf = box("traf", tfhd + tfdt + trun + senc + saio + saiz)
    moof = box("moof", mfhd + traf)
    mdat = box("mdat", bytes([0x55]) * 256)
    return ftyp + moov + moof + mdat


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
        write_fixture("fragmented_multi_trun", build_fragmented_multi_trun(), media_root),
        write_fixture("fragmented_negative_offset", build_fragmented_negative_offset(), media_root),
        write_fixture("fragmented_no_tfdt", build_fragmented_no_tfdt(), media_root),
        write_fixture("large_mdat_placeholder", build_large_mdat(), media_root),
        write_fixture("malformed_truncated", build_malformed_truncated(), media_root),
        write_fixture("edit_list_empty", build_edit_list_empty(), media_root),
        write_fixture("edit_list_single_offset", build_edit_list_single_offset(), media_root),
        write_fixture("edit_list_multi_segment", build_edit_list_multi_segment(), media_root),
        write_fixture("edit_list_rate_adjusted", build_edit_list_rate_adjusted(), media_root),
        write_fixture("sample_encryption_metadata", build_sample_encryption_fragment(), media_root),
    ]


def build_empty_file() -> bytes:
    return b""


def build_truncated_size_field() -> bytes:
    return b"\x00\x00\x00"


def build_invalid_fourcc() -> bytes:
    return (8).to_bytes(4, "big") + bytes([0x01, 0x02, 0x03, 0x04])


def build_zero_size_top_level() -> bytes:
    return (0).to_bytes(4, "big") + b"moov"


def build_oversized_large_size() -> bytes:
    large_size = 1 << 63
    return (1).to_bytes(4, "big") + b"ftyp" + large_size.to_bytes(8, "big")


def build_uuid_invalid_size() -> bytes:
    return (8).to_bytes(4, "big") + b"uuid" + bytes(16)


def build_truncated_moov_reader() -> bytes:
    ftyp = box("ftyp", brand_payload("isom", 0, ["isom"]))
    moov_header = (32).to_bytes(4, "big") + b"moov"
    return ftyp + moov_header


def build_parent_truncated_child() -> bytes:
    child_header = (24).to_bytes(4, "big") + b"trak"
    child_payload = child_header + bytes(8)
    moov = (24).to_bytes(4, "big") + b"moov" + child_payload
    ftyp = box("ftyp", brand_payload("isom", 0, ["isom"]))
    return ftyp + moov


def build_zero_length_loop() -> bytes:
    zero_trak = box("trak", b"")
    moov_payload = zero_trak + zero_trak + zero_trak + zero_trak
    moov = box("moov", moov_payload)
    ftyp = box("ftyp", brand_payload("isom", 0, ["isom"]))
    return ftyp + moov


def build_deep_recursion_chain(depth: int = 70) -> bytes:
    containers = [
        "moov",
        "trak",
    ]
    sequence: list[str] = []
    while len(sequence) < depth:
        sequence.extend(containers)
    sequence = sequence[:depth]
    payload = box("free", bytes(4))
    for container_type in reversed(sequence):
        payload = box(container_type, payload)
    ftyp = box("ftyp", brand_payload("isom", 0, ["isom"]))
    return ftyp + payload


def write_binary_fixture(name: str, data: bytes, root: Path = DEFAULT_CORRUPT_ROOT) -> Path:
    root.mkdir(parents=True, exist_ok=True)
    path = root / name
    base64_path = path.with_suffix(path.suffix + ".base64")

    path.write_bytes(data)
    encoded = base64.encodebytes(data).decode("ascii")
    base64_path.write_text(encoded, encoding="ascii")

    logger.info(
        "Wrote %s (%d bytes) and %s",
        path.name,
        len(data),
        base64_path.name,
    )
    return path


def generate_corrupt_fixtures(root: Path = DEFAULT_CORRUPT_ROOT) -> list[Path]:
    fixtures: list[tuple[str, bytes]] = [
        ("empty-file.mp4", build_empty_file()),
        ("truncated-size-field.mp4", build_truncated_size_field()),
        ("invalid-fourcc.mp4", build_invalid_fourcc()),
        ("zero-size-top-level.mp4", build_zero_size_top_level()),
        ("oversized-large-size.mp4", build_oversized_large_size()),
        ("uuid-invalid-size.mp4", build_uuid_invalid_size()),
        ("truncated-moov.mp4", build_truncated_moov_reader()),
        ("parent-truncated-child.mp4", build_parent_truncated_child()),
        ("zero-length-loop.mp4", build_zero_length_loop()),
        ("deep-recursion.mp4", build_deep_recursion_chain()),
    ]
    return [write_binary_fixture(name, data, root) for name, data in fixtures]


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
        "--corrupt-root",
        type=Path,
        default=DEFAULT_CORRUPT_ROOT,
        help="Directory for generated corrupt fixture binaries.",
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
        "--skip-corrupt-fixtures",
        action="store_true",
        help="Skip regeneration of corrupt binary fixtures.",
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

    if not args.skip_corrupt_fixtures:
        generate_corrupt_fixtures(args.corrupt_root)

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
