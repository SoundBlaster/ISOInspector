import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


def load_generate_fixtures_module():
    script_path = (
        Path(__file__).resolve().parent
        / "ISOInspectorKitTests"
        / "Fixtures"
        / "generate_fixtures.py"
    )
    spec = importlib.util.spec_from_file_location("generate_fixtures", script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ManifestProcessingTests(unittest.TestCase):
    def setUp(self):
        self.module = load_generate_fixtures_module()

    def create_manifest(self, temp_dir: Path, **overrides):
        data = overrides or {}
        manifest_path = temp_dir / "manifest.json"
        with manifest_path.open("w", encoding="utf-8") as handle:
            json.dump(data, handle)
        return manifest_path

    def test_process_manifest_downloads_and_validates(self):
        gf = self.module
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source_payload = b"fixture-bytes"
            source = tmp_path / "source.bin"
            source.write_bytes(source_payload)
            checksum = hashlib.sha256(source_payload).hexdigest()
            manifest = {
                "fixtures": [
                    {
                        "id": "demo-fixture",
                        "url": source.as_uri(),
                        "sha256": checksum,
                        "destination": {
                            "category": "demo",
                            "filename": "demo.bin",
                        },
                        "license": {
                            "filename": "demo-license.txt",
                            "text": "Demo license text",
                        },
                        "tags": ["demo"],
                    }
                ]
            }
            manifest_path = self.create_manifest(tmp_path, **manifest)
            distribution_root = tmp_path / "Distribution" / "Fixtures"
            license_root = tmp_path / "Documentation" / "FixtureCatalog" / "licenses"

            results = gf.process_manifest(
                manifest_path,
                distribution_root=distribution_root,
                license_root=license_root,
            )

            self.assertEqual(len(results), 1)
            result = results[0]
            self.assertTrue(result.destination.exists())
            self.assertEqual(result.destination.read_bytes(), source_payload)
            self.assertEqual(result.checksum, checksum)
            self.assertTrue(result.downloaded)
            self.assertIsNotNone(result.license_path)
            self.assertEqual(result.license_path.read_text(encoding="utf-8"), "Demo license text")

    def test_process_manifest_checksum_mismatch_raises(self):
        gf = self.module
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "source.bin"
            source.write_bytes(b"content")
            manifest = {
                "fixtures": [
                    {
                        "id": "invalid-checksum",
                        "url": source.as_uri(),
                        "sha256": "0" * 64,
                        "destination": {
                            "category": "demo",
                            "filename": "demo.bin",
                        },
                        "license": {
                            "filename": "demo-license.txt",
                            "text": "License",
                        },
                        "tags": [],
                    }
                ]
            }
            manifest_path = self.create_manifest(tmp_path, **manifest)

            with self.assertRaises(gf.ChecksumMismatchError):
                gf.process_manifest(
                    manifest_path,
                    distribution_root=tmp_path / "dist",
                    license_root=tmp_path / "licenses",
                )

    def test_process_manifest_dry_run(self):
        gf = self.module
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source_payload = b"fixture"
            source = tmp_path / "source.bin"
            source.write_bytes(source_payload)
            checksum = hashlib.sha256(source_payload).hexdigest()
            manifest = {
                "fixtures": [
                    {
                        "id": "dry-run",
                        "url": source.as_uri(),
                        "sha256": checksum,
                        "destination": {
                            "category": "demo",
                            "filename": "demo.bin",
                        },
                        "license": {
                            "filename": "demo-license.txt",
                            "text": "Dry run license",
                        },
                        "tags": ["demo"],
                    }
                ]
            }
            manifest_path = self.create_manifest(tmp_path, **manifest)
            distribution_root = tmp_path / "Distribution" / "Fixtures"
            license_root = tmp_path / "Documentation" / "FixtureCatalog" / "licenses"

            results = gf.process_manifest(
                manifest_path,
                distribution_root=distribution_root,
                license_root=license_root,
                dry_run=True,
            )

            self.assertEqual(len(results), 1)
            result = results[0]
            self.assertFalse(result.downloaded)
            self.assertFalse(result.destination.exists())
            if result.license_path:
                self.assertFalse(result.license_path.exists())


if __name__ == "__main__":
    unittest.main()
