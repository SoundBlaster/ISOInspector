import importlib.util
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[2] / ".github" / "scripts" / "pr_quality_gate.py"
spec = importlib.util.spec_from_file_location("pr_quality_gate", SCRIPT)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class QualityGateTests(unittest.TestCase):
    def snapshot(self, applicable=()):
        needs = {"changes": {"result": "success", "outputs": {}}}
        for name in gate.CHECKS:
            needed = name in applicable
            needs["changes"]["outputs"][name] = str(needed).lower()
            needs[name] = {"result": "success" if needed else "skipped"}
        return needs

    def test_irrelevant_jobs_may_be_skipped(self):
        self.assertEqual(gate.failures(self.snapshot()), [])

    def test_applicable_jobs_must_succeed(self):
        for result in ("failure", "cancelled", "skipped", "", None):
            with self.subTest(result=result):
                needs = self.snapshot(["macos"])
                needs["macos"]["result"] = result
                self.assertTrue(gate.failures(needs))

    def test_failed_scope_and_missing_scope_fail_closed(self):
        for result in ("failure", "cancelled", "skipped"):
            needs = self.snapshot()
            needs["changes"]["result"] = result
            self.assertTrue(gate.failures(needs))
        needs = self.snapshot()
        del needs["changes"]["outputs"]["linux"]
        self.assertTrue(gate.failures(needs))

    def test_unexpected_failure_is_never_ignored(self):
        needs = self.snapshot()
        needs["foundationui"]["result"] = "failure"
        self.assertTrue(gate.failures(needs))

    def test_all_applicable_checks_pass(self):
        self.assertEqual(gate.failures(self.snapshot(gate.CHECKS)), [])


if __name__ == "__main__":
    unittest.main()
