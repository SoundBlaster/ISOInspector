import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[2] / ".github/scripts/macos_artifact_gate.py"


class MacOSArtifactGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        self.commit({"Tests/old.swift": "old", "Sources/app.swift": "old"})
        self.base = self.git("rev-parse", "HEAD").strip()
        self.output = self.root / "output"
        self.event = self.root / "event.json"

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.root, text=True)

    def commit(self, files, deleted=()):
        for name, content in files.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        for name in deleted:
            (self.root / name).unlink()
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)
        subprocess.run(["git", "-c", "user.name=Test", "-c", "user.email=test@example.com",
                        "-c", "commit.gpgsign=false", "commit", "-qm", "test"], cwd=self.root, check=True)

    def gate(self, event_name, event):
        self.event.write_text(json.dumps(event))
        self.output.write_text("")
        env = {**os.environ, "GITHUB_EVENT_NAME": event_name,
               "GITHUB_EVENT_PATH": str(self.event), "GITHUB_OUTPUT": str(self.output)}
        result = subprocess.run([sys.executable, str(SCRIPT)], cwd=self.root, env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.output.read_text().strip()

    def test_test_only_change_skips_archive_for_pull_request_and_push(self):
        self.commit({"Tests/new file.swift": "new"}, deleted=("Tests/old.swift",))
        head = self.git("rev-parse", "HEAD").strip()
        self.assertEqual(self.gate("pull_request", {"pull_request": {"base": {"sha": self.base},
                                                                      "head": {"sha": head}}}), "archive=false")
        self.assertEqual(self.gate("push", {"before": self.base, "after": head}), "archive=false")

    def test_mixed_change_runs_archive(self):
        self.commit({"Tests/new.swift": "new", "Sources/app.swift": "new"})
        head = self.git("rev-parse", "HEAD").strip()
        self.assertEqual(self.gate("push", {"before": self.base, "after": head}), "archive=true")

    def test_nested_package_and_script_tests_skip_archive(self):
        self.commit({"FoundationUI/Tests/Example.swift": "test", "scripts/tests/test_example.py": "test"})
        head = self.git("rev-parse", "HEAD").strip()
        self.assertEqual(self.gate("push", {"before": self.base, "after": head}), "archive=false")

    def test_renaming_production_file_into_tests_still_runs_archive(self):
        self.commit({"Tests/moved.swift": "old"}, deleted=("Sources/app.swift",))
        head = self.git("rev-parse", "HEAD").strip()
        self.assertEqual(self.gate("push", {"before": self.base, "after": head}), "archive=true")

    def test_pull_request_uses_merge_base_when_base_branch_advances(self):
        self.commit({"Tests/new.swift": "new"})
        head = self.git("rev-parse", "HEAD").strip()
        subprocess.run(["git", "checkout", "-q", "--detach", self.base], cwd=self.root, check=True)
        self.commit({"Sources/app.swift": "advanced base"})
        advanced_base = self.git("rev-parse", "HEAD").strip()
        event = {"pull_request": {"base": {"sha": advanced_base}, "head": {"sha": head}}}
        self.assertEqual(self.gate("pull_request", event), "archive=false")

    def test_unknown_base_and_manual_run_are_conservative(self):
        self.assertEqual(self.gate("push", {"before": "0" * 40, "after": self.base}), "archive=true")
        self.assertEqual(self.gate("push", {"before": "f" * 40, "after": self.base}), "archive=true")
        self.assertEqual(self.gate("pull_request", {"pull_request": None}), "archive=true")
        self.assertEqual(self.gate("workflow_dispatch", {}), "archive=true")


if __name__ == "__main__":
    unittest.main()
