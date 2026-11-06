#!/usr/bin/env python3
"""Create synthetic tkhd boxes for comparison against independent parsers."""

import base64
import json
from pathlib import Path
import struct


def make_box(version):
    creation, modification, track_id, duration = (
        (1, 2, 3, 540) if version == 0 else (4294967297, 4294967298, 12, 4294968196)
    )
    body = bytes([version, 0, 0, 1 if version == 0 else 7])
    body += struct.pack(">IIIII" if version == 0 else ">QQIIQ", creation, modification, track_id, 0, duration)
    body += struct.pack(">IIhhHH", 0, 0, -2, 3, 256, 0)
    body += struct.pack(">9i", 65536, -65536, 536870912, 32768, 65536, -536870912, 0, 65536, 1073741824)
    width, height = (1280, 720) if version == 0 else (1920, 1080)
    body += struct.pack(">II", width << 16, height << 16)
    return struct.pack(">I4s", len(body) + 8, b"tkhd") + body


def main():
    boxes = {f"v{version}": make_box(version) for version in (0, 1)}
    cases = dict(boxes)
    for name, data in boxes.items():
        incomplete = data[:-1]
        cases[f"{name}_incomplete"] = incomplete
        cases[f"{name}_short_box"] = struct.pack(">I", len(incomplete)) + incomplete[4:]
    unknown = bytearray(boxes["v0"])
    unknown[8] = 2
    cases["unknown_version"] = bytes(unknown)
    output = {name: base64.b64encode(data).decode("ascii") for name, data in cases.items()}
    Path(__file__).with_name("tkhd_differential_inputs.json").write_text(
        json.dumps(output, sort_keys=True, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
