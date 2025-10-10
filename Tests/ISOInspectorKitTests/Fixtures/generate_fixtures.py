#!/usr/bin/env python3
"""Generate text-encoded fixtures for ISOInspectorKit tests.

The fixtures are intentionally small, deterministic, and base64 encoded so they
can be stored in source control without committing binary blobs. Each fixture
encodes a targeted scenario for validation tests including fragmented MP4
layouts, DASH segments, oversized `mdat` payloads, and malformed structures.
"""
from __future__ import annotations

import base64
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parent
MEDIA = ROOT / "Media"
TEXT_EXTENSION = "txt"


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


def write_fixture(name: str, data: bytes) -> None:
    path = MEDIA / f"{name}.{TEXT_EXTENSION}"
    encoded = base64.b64encode(data).decode("ascii")
    path.write_text(encoded)
    print(f"wrote {path.name} ({len(data)} bytes source)")


def main() -> None:
    MEDIA.mkdir(parents=True, exist_ok=True)
    write_fixture("fragmented_stream_init", build_fragmented_init())
    write_fixture("dash_segment_1", build_dash_segment())
    write_fixture("large_mdat_placeholder", build_large_mdat())
    write_fixture("malformed_truncated", build_malformed_truncated())


if __name__ == "__main__":
    main()
