#!/usr/bin/env python3
"""
Check code coverage threshold from Cobertura XML report.
Usage: python3 check_coverage_threshold.py <coverage.xml> <threshold> [--platform NAME]
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def parse_coverage(xml_path: Path) -> float:
    """Parse Cobertura XML and return line coverage percentage."""
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()

        # Get line-rate from root coverage element (0.0 - 1.0)
        line_rate = float(root.attrib.get('line-rate', 0.0))

        # Convert to percentage
        return line_rate * 100.0
    except Exception as e:
        print(f"Error parsing coverage XML: {e}", file=sys.stderr)
        return 0.0


def main():
    if len(sys.argv) < 3:
        print("Usage: check_coverage_threshold.py <coverage.xml> <threshold> [--platform NAME]")
        sys.exit(1)

    xml_path = Path(sys.argv[1])
    threshold = float(sys.argv[2])
    platform = sys.argv[4] if len(sys.argv) > 4 and sys.argv[3] == '--platform' else 'Unknown'

    if not xml_path.exists():
        print(f"❌ Coverage file not found: {xml_path}", file=sys.stderr)
        sys.exit(1)

    coverage = parse_coverage(xml_path)

    print(f"📊 Coverage Report - {platform}")
    print(f"   Coverage: {coverage:.2f}%")
    print(f"   Threshold: {threshold:.2f}%")

    if coverage >= threshold:
        print(f"   ✅ PASS: Coverage meets threshold")
        # Write to step output for GitHub Actions
        with open('/tmp/coverage_result.txt', 'a') as f:
            f.write(f"{platform}={coverage:.2f}\n")
        sys.exit(0)
    else:
        deficit = threshold - coverage
        print(f"   ❌ FAIL: Coverage below threshold by {deficit:.2f}%")
        # Write to step output for GitHub Actions
        with open('/tmp/coverage_result.txt', 'a') as f:
            f.write(f"{platform}={coverage:.2f}\n")
        sys.exit(1)


if __name__ == '__main__':
    main()
