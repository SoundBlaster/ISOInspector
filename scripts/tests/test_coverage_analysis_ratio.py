import contextlib
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[2] / "coverage_analysis.py"
spec = importlib.util.spec_from_file_location("coverage_analysis", SCRIPT)
analysis = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analysis)


class CoverageAnalysisRatioTests(unittest.TestCase):
    def test_missing_test_layer_does_not_reuse_previous_layer_count(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base = root / "FoundationUI"
            for layer in ("DesignTokens", "Modifiers"):
                source = base / "Sources" / "FoundationUI" / layer
                source.mkdir(parents=True)
                (source / "Example.swift").write_text("let value = 1\n")
            tests = base / "Tests" / "FoundationUITests" / "DesignTokensTests"
            tests.mkdir(parents=True)
            (tests / "ExampleTests.swift").write_text("let test = 1\n")
            output = io.StringIO()
            with patch.object(analysis, "find_repo_root", return_value=root), \
                 patch.object(sys, "argv", ["coverage_analysis.py"]), \
                 contextlib.redirect_stdout(output):
                analysis.main()
            self.assertIn("Total Test LOC:   1", output.getvalue())
            self.assertIn("Overall Test/Code Ratio: 50.0%", output.getvalue())
            self.assertNotIn("Coverage Estimate", output.getvalue())


if __name__ == "__main__":
    unittest.main()
