#!/usr/bin/env python3
"""
Per-module line coverage for the ISOInspector SPM package.

Runs (or reuses) `swift test --enable-code-coverage`, merges profraw files,
invokes `llvm-cov report` on the test bundle, and aggregates line coverage
per Sources/<Module>/ tree.

Usage:
    scripts/isoinspector_coverage.py [--run-tests] [--json PATH] [--summary PATH]
                                     [--kit FLOAT] [--app FLOAT] [--cli FLOAT]
                                     [--cli-runner FLOAT]

Exits 1 if any module's line coverage is below its threshold.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

MODULES = ("ISOInspectorKit", "ISOInspectorApp", "ISOInspectorCLI", "ISOInspectorCLIRunner")

# Matches one file row produced by `llvm-cov report`.
# The column order is: Filename | Regions | Missed | Cover% | Functions |
# Missed | Executed% | Lines | Missed | Cover% | Branches | Missed | Cover%.
ROW_RE = re.compile(
    r"^(?P<path>\S.*?)\s+"
    r"(?P<regions>\d+)\s+(?P<regions_missed>\d+)\s+[\d.]+%\s+"
    r"(?P<functions>\d+)\s+(?P<functions_missed>\d+)\s+[\d.]+%\s+"
    r"(?P<lines>\d+)\s+(?P<lines_missed>\d+)\s+[\d.]+%"
)


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    print(f"$ {' '.join(cmd)}", file=sys.stderr)
    return subprocess.run(cmd, check=True, **kwargs)


def swift_test_with_coverage() -> None:
    run(["swift", "test", "--enable-code-coverage"])


def find_bin_path() -> Path:
    out = subprocess.check_output(["swift", "build", "--show-bin-path"], text=True).strip()
    return Path(out)


def merge_profdata(bin_path: Path) -> Path:
    codecov = bin_path / "codecov"
    profraws = sorted(codecov.glob("*.profraw"))
    if not profraws:
        sys.exit(f"error: no .profraw files in {codecov}; run with --run-tests first")
    out = codecov / "default.profdata"
    cmd = ["xcrun", "llvm-profdata", "merge", "-sparse", *map(str, profraws), "-o", str(out)]
    run(cmd)
    return out


def find_test_binary(bin_path: Path) -> Path:
    # macOS bundle layout
    for bundle in bin_path.glob("*PackageTests.xctest"):
        macos = bundle / "Contents" / "MacOS"
        if macos.is_dir():
            for exe in macos.iterdir():
                if exe.is_file() and os.access(exe, os.X_OK):
                    return exe
    # Linux: plain executable
    for exe in bin_path.glob("*PackageTests.xctest"):
        if exe.is_file() and os.access(exe, os.X_OK):
            return exe
    sys.exit(f"error: could not locate PackageTests binary under {bin_path}")


def llvm_cov_report(binary: Path, profdata: Path) -> str:
    cmd = ["xcrun", "llvm-cov", "report", str(binary), f"-instr-profile={profdata}"]
    print(f"$ {' '.join(cmd)}", file=sys.stderr)
    return subprocess.check_output(cmd, text=True)


def aggregate(report: str) -> dict[str, dict[str, int]]:
    agg = {
        m: {"lines": 0, "missed": 0, "regions": 0, "regions_missed": 0, "functions": 0, "functions_missed": 0, "files": 0}
        for m in MODULES
    }
    for line in report.splitlines():
        m = ROW_RE.match(line)
        if not m:
            continue
        path = m.group("path")
        for mod in MODULES:
            prefix = f"Sources/{mod}/"
            # llvm-cov can emit absolute paths; match on substring too.
            if prefix in path:
                bucket = agg[mod]
                bucket["lines"] += int(m.group("lines"))
                bucket["missed"] += int(m.group("lines_missed"))
                bucket["regions"] += int(m.group("regions"))
                bucket["regions_missed"] += int(m.group("regions_missed"))
                bucket["functions"] += int(m.group("functions"))
                bucket["functions_missed"] += int(m.group("functions_missed"))
                bucket["files"] += 1
                break
    return agg


def pct(covered: int, total: int) -> float:
    return 100.0 * covered / total if total else 0.0


def render_markdown(agg: dict[str, dict[str, int]], thresholds: dict[str, float]) -> tuple[str, bool]:
    lines = [
        "## 📊 ISOInspector Coverage (SPM)",
        "",
        "| Module | Files | Lines | Covered | **Line %** | Threshold | Status |",
        "|---|---:|---:|---:|---:|---:|:---:|",
    ]
    passed = True
    for mod in MODULES:
        b = agg[mod]
        thr = thresholds.get(mod)
        if b["lines"] == 0:
            if thr is None:
                # Module not configured and not found — nothing to report.
                continue
            # Module has a threshold but no coverage rows — treat as a failure,
            # since the gate cannot verify the configured threshold.
            passed = False
            lines.append(
                f"| `{mod}` | 0 | 0 | 0 | **n/a** | {thr:.1f}% | ❌ (no coverage data) |"
            )
            continue
        covered = b["lines"] - b["missed"]
        line_pct = pct(covered, b["lines"])
        ok = thr is None or line_pct + 1e-9 >= thr
        passed = passed and ok
        status = "✅" if ok else "❌"
        thr_cell = f"{thr:.1f}%" if thr is not None else "—"
        lines.append(
            f"| `{mod}` | {b['files']} | {b['lines']} | {covered} | **{line_pct:.2f}%** | {thr_cell} | {status} |"
        )
    lines.append("")
    lines.append(f"**Overall status:** {'✅ PASS' if passed else '❌ FAIL'}")
    return "\n".join(lines) + "\n", passed


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--run-tests", action="store_true", help="Execute `swift test --enable-code-coverage` first")
    p.add_argument("--json", type=Path, help="Write aggregated JSON to this path")
    p.add_argument("--summary", type=Path, help="Append Markdown summary to this path (for GITHUB_STEP_SUMMARY)")
    p.add_argument("--kit", type=float, default=None, metavar="PCT", help="Threshold for ISOInspectorKit")
    p.add_argument("--app", type=float, default=None, metavar="PCT", help="Threshold for ISOInspectorApp")
    p.add_argument("--cli", type=float, default=None, metavar="PCT", help="Threshold for ISOInspectorCLI")
    p.add_argument("--cli-runner", type=float, default=None, metavar="PCT", help="Threshold for ISOInspectorCLIRunner")
    args = p.parse_args()

    if not shutil.which("swift"):
        sys.exit("error: swift is not on PATH")

    if args.run_tests:
        swift_test_with_coverage()

    bin_path = find_bin_path()
    profdata = merge_profdata(bin_path)
    binary = find_test_binary(bin_path)
    report = llvm_cov_report(binary, profdata)
    agg = aggregate(report)

    thresholds = {}
    if args.kit is not None:
        thresholds["ISOInspectorKit"] = args.kit
    if args.app is not None:
        thresholds["ISOInspectorApp"] = args.app
    if args.cli is not None:
        thresholds["ISOInspectorCLI"] = args.cli
    if args.cli_runner is not None:
        thresholds["ISOInspectorCLIRunner"] = args.cli_runner

    md, passed = render_markdown(agg, thresholds)
    print(md)

    if args.summary:
        with args.summary.open("a", encoding="utf-8") as f:
            f.write(md)

    if args.json:
        payload = {
            "modules": {
                mod: {
                    **b,
                    "covered_lines": b["lines"] - b["missed"],
                    "line_percent": pct(b["lines"] - b["missed"], b["lines"]),
                    "threshold": thresholds.get(mod),
                    "missing_from_report": b["lines"] == 0,
                }
                for mod, b in agg.items()
                if b["lines"] > 0 or mod in thresholds
            },
            "passed": passed,
        }
        args.json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
