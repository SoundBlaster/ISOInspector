import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HOOK = Path(__file__).resolve().parents[2] / ".githooks" / "pre-push"


class PrePushBuildPathsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "marker").write_text("test\n")
        subprocess.run(["git", "add", "marker"], cwd=self.root, check=True)
        subprocess.run(
            ["git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "initial"],
            cwd=self.root, check=True,
        )
        (self.root / "FoundationUI").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / "scripts" / "run_swift_duplication_check.sh").write_text("#!/bin/sh\nexit 0\n")
        (self.root / "scripts" / "run_swift_duplication_check.sh").chmod(0o755)
        (self.root / "coverage_analysis.py").write_text("print('coverage OK')\n")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.calls = self.root / "swift-calls"
        self.executable("swift", '#!/bin/sh\nprintf "<%s>" "$@" >> "$SWIFT_CALLS"\nprintf "\\n" >> "$SWIFT_CALLS"\n')
        self.executable("uname", "#!/bin/sh\necho Darwin\n")
        for name in ("swiftlint", "node", "npx"):
            self.executable(name, "#!/bin/sh\nexit 0\n")
        self.env = os.environ.copy()
        for name in ("ISOINSPECTOR_SWIFTPM_SCRATCH_PATH", "ISOINSPECTOR_FOUNDATIONUI_SCRATCH_PATH",
                     "ISOINSPECTOR_SWIFTPM_CACHE_PATH", "ISOINSPECTOR_BUILD_PREFLIGHT"):
            self.env.pop(name, None)
        self.env.update(PATH=f"{self.bin}:{self.env['PATH']}", SWIFT_CALLS=str(self.calls))

    def executable(self, name, content):
        path = self.bin / name
        path.write_text(content)
        path.chmod(0o755)
        return path

    def run_hook(self):
        return subprocess.run(["bash", str(HOOK)], cwd=self.root, env=self.env, capture_output=True, text=True)

    def test_configured_paths_reach_all_three_swift_commands(self):
        paths = [self.root / name for name in ("root scratch", "foundation scratch", "swift cache")]
        for path in paths:
            path.mkdir()
        preflight_log = self.root / "preflight-calls"
        preflight = self.executable("preflight", '#!/bin/sh\nprintf "%s\\n" "$1" >> "$PREFLIGHT_CALLS"\n')
        self.env["PREFLIGHT_CALLS"] = str(preflight_log)
        config = self.root / ".git" / "isoinspector-build.conf"
        for key, value in zip(("build.rootScratch", "build.foundationScratch", "build.cache", "build.preflight"),
                              (*paths, preflight)):
            subprocess.run(["git", "config", "--file", str(config), key, str(value)], check=True)

        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls.read_text().splitlines()
        self.assertEqual(len(calls), 3)
        self.assertIn(f"<--scratch-path><{paths[0]}><--cache-path><{paths[2]}>", calls[0])
        self.assertIn(f"<--scratch-path><{paths[0]}><--cache-path><{paths[2]}>", calls[1])
        self.assertIn(f"<--scratch-path><{paths[1]}><--cache-path><{paths[2]}>", calls[2])
        self.assertEqual(preflight_log.read_text().splitlines(), [str(self.root), str(self.root / "FoundationUI")])

    def test_failed_preflight_stops_before_swift_runs(self):
        paths = [self.root / name for name in ("root", "foundation", "cache")]
        for path in paths:
            path.mkdir()
        preflight = self.executable("preflight", "#!/bin/sh\nexit 1\n")
        self.env.update(ISOINSPECTOR_SWIFTPM_SCRATCH_PATH=str(paths[0]),
                        ISOINSPECTOR_FOUNDATIONUI_SCRATCH_PATH=str(paths[1]),
                        ISOINSPECTOR_SWIFTPM_CACHE_PATH=str(paths[2]),
                        ISOINSPECTOR_BUILD_PREFLIGHT=str(preflight))

        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("preflight failed", result.stdout)
        self.assertFalse(self.calls.exists())

    def test_unconfigured_hook_preserves_swiftpm_defaults(self):
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls.read_text().splitlines()
        self.assertEqual(len(calls), 3)
        self.assertTrue(all("<--scratch-path>" not in call and "<--cache-path>" not in call for call in calls))

    def test_git_push_environment_does_not_leak_to_swiftpm(self):
        self.env["GIT_DIR"] = str(self.root / ".git")
        self.executable("swift", '#!/bin/sh\n[ -z "${GIT_DIR+x}" ] || { echo "GIT_DIR leaked" >&2; exit 1; }\n')
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_incomplete_configuration_stops_before_swift_runs(self):
        self.env["ISOINSPECTOR_SWIFTPM_SCRATCH_PATH"] = str(self.root / "scratch")
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Configure root scratch", result.stdout)
        self.assertFalse(self.calls.exists())


if __name__ == "__main__":
    unittest.main()
