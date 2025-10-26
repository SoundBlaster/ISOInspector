#!/usr/bin/env python3
"""Validate that YAML files in the repository are syntactically correct."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable

import yaml


ROOT = Path(__file__).resolve().parents[1]


class LenientSafeLoader(yaml.SafeLoader):
    """SafeLoader variant that tolerates unknown YAML tags."""


def _construct_undefined(loader: LenientSafeLoader, node: yaml.Node):  # type: ignore[override]
    if isinstance(node, yaml.ScalarNode):
        return loader.construct_scalar(node)
    if isinstance(node, yaml.SequenceNode):
        return [loader.construct_object(child) for child in node.value]
    if isinstance(node, yaml.MappingNode):
        return {
            loader.construct_object(key): loader.construct_object(value)
            for key, value in node.value
        }
    raise yaml.constructor.ConstructorError(  # pragma: no cover - defensive branch
        None,
        None,
        f"cannot construct object for node type {type(node).__name__}",
        node.start_mark,
    )


LenientSafeLoader.add_constructor(None, _construct_undefined)


def iter_yaml_files(paths: Iterable[Path]) -> Iterable[Path]:
    for path in paths:
        if path.is_file() and path.suffix in {".yaml", ".yml"}:
            yield path
        elif path.is_dir():
            for candidate in path.rglob("*.yml"):
                if candidate.is_file():
                    yield candidate
            for candidate in path.rglob("*.yaml"):
                if candidate.is_file():
                    yield candidate


def validate_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    try:
        list(yaml.load_all(text, Loader=LenientSafeLoader))
    except yaml.YAMLError as exc:
        print(f"{path}: YAML parsing failed: {exc}")
        return False
    return True


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate YAML files.")
    parser.add_argument(
        "paths",
        nargs="*",
        default=[ROOT],
        type=Path,
        help="Directories or files to validate (default: repository root).",
    )
    args = parser.parse_args(argv)

    success = True
    for candidate in iter_yaml_files(args.paths):
        success &= validate_file(candidate)

    return 0 if success else 1


if __name__ == "__main__":  # pragma: no cover - script entry point
    raise SystemExit(main(sys.argv[1:]))
