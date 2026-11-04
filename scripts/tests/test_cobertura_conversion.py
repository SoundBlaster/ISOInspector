import json
import os
import shutil
import subprocess
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from tempfile import TemporaryDirectory

SCRIPT = Path(__file__).resolve().parents[1] / "convert_coverage_to_cobertura.sh"


@unittest.skipUnless(shutil.which("jq"), "jq is required by the converter")
class CoberturaTargetFilterTests(unittest.TestCase):
    def test_requested_targets_exclude_dependency_from_total(self):
        result, root = self.convert([
            "-target", "FoundationUI.framework", "-target", "FoundationUITests.xctest"
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(root.attrib["lines-covered"], "13")
        self.assertEqual(root.attrib["lines-valid"], "20")
        self.assertEqual(root.attrib["line-rate"], "0.6500")
        self.assertEqual(
            [package.attrib["name"] for package in root.findall("./packages/package")],
            ["FoundationUI.framework", "FoundationUITests.xctest"],
        )

    def test_missing_target_fails_instead_of_reporting_partial_coverage(self):
        result, _ = self.convert(["-target", "FoundationUI.framework", "-target", "missing"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requested coverage target is missing", result.stderr)

    def test_default_keeps_all_targets(self):
        result, root = self.convert([])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(root.attrib["lines-covered"], "13")
        self.assertEqual(root.attrib["lines-valid"], "120")

    def convert(self, arguments):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundle = root / "result.xcresult"
            bundle.mkdir()
            target = lambda name, covered, total: {
                "name": name, "coveredLines": covered, "executableLines": total,
                "lineCoverage": covered / total, "files": [],
            }
            report = {
                "coveredLines": 13, "executableLines": 120, "lineCoverage": 13 / 120,
                "targets": [
                    target("FoundationUI.framework", 4, 10),
                    target("FoundationUITests.xctest", 9, 10),
                    target("Dependency", 0, 100),
                ],
            }
            (root / "report.json").write_text(json.dumps(report))
            xcrun = root / "xcrun"
            xcrun.write_text('#!/bin/sh\ncat "$FAKE_COVERAGE_REPORT"\n')
            xcrun.chmod(0o755)
            output = root / "coverage.xml"
            environment = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                               FAKE_COVERAGE_REPORT=str(root / "report.json"))
            result = subprocess.run(
                ["bash", str(SCRIPT), "-xcresult", str(bundle), "-output", str(output), *arguments],
                env=environment, text=True, capture_output=True,
            )
            xml_root = ET.parse(output).getroot() if output.exists() else None
            return result, xml_root


if __name__ == "__main__":
    unittest.main()
