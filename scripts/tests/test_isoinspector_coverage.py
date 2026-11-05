import importlib.util
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "isoinspector_coverage.py"
spec = importlib.util.spec_from_file_location("isoinspector_coverage", MODULE_PATH)
coverage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(coverage)


class TestBinaryDiscoveryTests(unittest.TestCase):
    def test_finds_all_swift_build_bundles_and_omits_benchmarks(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ("ISOInspectorKitTests", "ISOInspectorAppTests", "ISOInspectorPerformanceTests"):
                binary = root / f"{name}.xctest" / "Contents" / "MacOS" / name
                binary.parent.mkdir(parents=True)
                binary.touch(mode=0o755)
            binaries = coverage.find_test_binaries(root)
            self.assertEqual([path.name for path in binaries], ["ISOInspectorAppTests", "ISOInspectorKitTests"])

    def test_finds_legacy_flat_test_executable(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "ISOInspectorPackageTests.xctest"
            binary.touch(mode=0o755)
            self.assertEqual(coverage.find_test_binaries(root), [binary])

    def test_missing_test_binary_fails(self):
        with TemporaryDirectory() as temporary:
            with self.assertRaises(SystemExit):
                coverage.find_test_binaries(Path(temporary))

    def test_report_includes_every_binary(self):
        binaries = [Path("kit"), Path("app"), Path("cli")]
        with patch.object(coverage.subprocess, "check_output", return_value="report") as run:
            self.assertEqual(coverage.llvm_cov_report(binaries, Path("profile")), "report")
        self.assertEqual(
            run.call_args.args[0],
            ["xcrun", "llvm-cov", "report", "kit", "-instr-profile=profile", "-object", "app", "-object", "cli"],
        )


if __name__ == "__main__":
    unittest.main()
