#!/usr/bin/env python3
"""Generate ISOInspector app icon raster assets from the brand palette."""

from __future__ import annotations

import json
from collections import OrderedDict
from pathlib import Path
from typing import Tuple

from PIL import Image, ImageDraw, ImageFilter

# Brand palette derived from ISOInspectorBrandPalette.production.
LIGHT_ACCENT = (15, 98, 254)
DARK_ACCENT = (44, 120, 255)
LIGHT_BACKGROUND = (243, 246, 251)
DARK_BACKGROUND = (13, 20, 31)

ROOT = Path(__file__).resolve().parent.parent
ASSET_CATALOG = ROOT / "Sources" / "ISOInspectorApp" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
MANIFEST_PATH = ASSET_CATALOG / "Contents.json"


def main() -> None:
    manifest = load_manifest(MANIFEST_PATH)
    master = render_master_icon(1024)

    for image_entry in manifest["images"]:
        filename = filename_for(image_entry)
        image_entry["filename"] = filename

        pixel_size = dimension_for(image_entry)
        output = ASSET_CATALOG / filename
        generate_variant(master, pixel_size, output)

    dump_manifest(manifest, MANIFEST_PATH)


def load_manifest(path: Path) -> OrderedDict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle, object_pairs_hook=OrderedDict)


def dump_manifest(manifest: OrderedDict, path: Path) -> None:
    with path.open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")


def filename_for(image_entry: OrderedDict) -> str:
    idiom = image_entry.get("idiom", "universal")
    size = image_entry.get("size", "0x0").replace(" ", "")
    scale = image_entry.get("scale", "1x")
    size_label = size.replace(".", "-")
    return f"AppIcon-{idiom}-{size_label}@{scale}.png"


def dimension_for(image_entry: OrderedDict) -> int:
    raw_size = image_entry.get("size", "0x0")
    width_str, _, _ = raw_size.partition("x")
    try:
        base_size = float(width_str)
    except ValueError as exc:  # pragma: no cover - manifest is trusted
        raise ValueError(f"Invalid size entry: {raw_size!r}") from exc

    scale_str = image_entry.get("scale", "1x")
    if scale_str.endswith("x"):
        scale = float(scale_str[:-1]) if scale_str[:-1] else 1.0
    else:
        scale = float(scale_str)

    pixels = base_size * scale
    return int(round(pixels))


def render_master_icon(size: int) -> Image.Image:
    """Render the base 1024×1024 artwork used for all variants."""
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)

    for y in range(size):
        ratio = y / (size - 1)
        color = interpolate_color(LIGHT_BACKGROUND, DARK_BACKGROUND, ratio)
        draw.line([(0, y), (size, y)], fill=color)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        [size * 0.05, size * 0.05, size * 0.95, size * 0.95],
        fill=(*LIGHT_ACCENT, 35),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=size * 0.18))
    image = Image.alpha_composite(image, glow)

    accent = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent)
    inset = size * 0.18
    accent_draw.ellipse(
        [inset, inset, size - inset, size - inset],
        fill=(*blend_colors(LIGHT_ACCENT, DARK_ACCENT, 0.65), 255),
    )

    inner_inset = size * 0.34
    accent_draw.ellipse(
        [inner_inset, inner_inset, size - inner_inset, size - inner_inset],
        fill=(*LIGHT_BACKGROUND, 255),
    )

    highlight_inset = size * 0.42
    accent_draw.ellipse(
        [highlight_inset, highlight_inset, size - highlight_inset, size - highlight_inset],
        outline=(*LIGHT_ACCENT, 220),
        width=max(2, int(size * 0.01)),
    )

    handle_rect = [size * 0.63, size * 0.63, size * 0.84, size * 0.76]
    accent_draw.rounded_rectangle(
        handle_rect,
        radius=size * 0.06,
        fill=(*DARK_ACCENT, 235),
    )
    accent = accent.rotate(45, resample=Image.Resampling.BICUBIC, center=(size / 2, size / 2))
    image = Image.alpha_composite(image, accent)

    radar = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    radar_draw = ImageDraw.Draw(radar)
    for index, radius in enumerate((0.48, 0.36, 0.24)):
        opacity = 60 - index * 15
        radar_draw.ellipse(
            [size * (0.5 - radius / 2), size * (0.5 - radius / 2), size * (0.5 + radius / 2), size * (0.5 + radius / 2)],
            outline=(*blend_colors(LIGHT_ACCENT, DARK_ACCENT, 0.3), opacity),
            width=max(1, int(size * 0.008)),
        )
    image = Image.alpha_composite(image, radar)

    return image


def generate_variant(master: Image.Image, pixels: int, output: Path) -> None:
    variant = master.resize((pixels, pixels), resample=Image.Resampling.LANCZOS)
    variant_rgb = variant.convert("RGB")
    output.parent.mkdir(parents=True, exist_ok=True)
    variant_rgb.save(output, format="PNG", optimize=True)


def interpolate_color(a: Tuple[int, int, int], b: Tuple[int, int, int], ratio: float) -> Tuple[int, int, int]:
    return tuple(int(round(a_c * (1 - ratio) + b_c * ratio)) for a_c, b_c in zip(a, b))


def blend_colors(a: Tuple[int, int, int], b: Tuple[int, int, int], ratio: float) -> Tuple[int, int, int]:
    return interpolate_color(a, b, ratio)


if __name__ == "__main__":
    main()
