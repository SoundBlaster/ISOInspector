"""Exercise the checked-in workflow shell with isolated Git snapshots."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/specificationmetrics.yml"


def step(name):
    text = WORKFLOW.read_text().split(f"      - name: {name}\n", 1)[1]
    block = text.split("\n      - name:", 1)[0].split("        run: |\n", 1)[1]
    return "\n".join(line[10:] for line in block.splitlines()) + "\n"


class SpecificationMetricsWorkflowTests(unittest.TestCase):
    def test_success_and_interrupted_collection_have_distinct_evidence(self):
        for fail_head in (False, True):
            with self.subTest(fail_head=fail_head), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                repo, runner = root / "repo", root / "runner"
                repo.mkdir()
                runner.mkdir()
                subprocess.run(["git", "init", "-q", str(repo)], check=True)
                (repo / "source.swift").write_text("if ready {}\n")
                subprocess.run(["git", "-C", str(repo), "add", "source.swift"], check=True)
                subprocess.run(
                    ["git", "-C", str(repo), "-c", "user.name=test", "-c", "user.email=test@example.org",
                     "-c", "commit.gpgsign=false", "commit", "-qm", "snapshot"],
                    check=True,
                )
                sha = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
                (repo / ".specificationmetrics.toml").write_bytes((ROOT / ".specificationmetrics.toml").read_bytes())
                (repo / "scopes").mkdir()
                (repo / "scopes/specificationmetrics.toml").write_bytes((ROOT / "scopes/specificationmetrics.toml").read_bytes())
                cli = runner / "specificationmetrics-cli/bin/specification-metrics"
                cli.parent.mkdir(parents=True)
                cli.write_text(
                    "#!/usr/bin/env python3\n"
                    "import json, os, pathlib, sys\n"
                    "output = pathlib.Path(sys.argv[sys.argv.index('--output')+1])\n"
                    f"if {fail_head!r} and output.name == 'after.json': sys.exit(23)\n"
                    "if sys.argv[1] == 'collect':\n"
                    " assert '--candidate-locations' in sys.argv\n"
                    " data={'status':'provisional','primary':{'source_revision':os.environ['HEAD_SHA'],"
                    "'specification_definitions':1,'remaining_opportunities':2,'ratio':0.5,"
                    "'parse_issues':[{}],'scope_issues':[],'unknown_specifications':0}}\n"
                    " output.write_text(json.dumps(data))\n"
                    "elif '--github-markdown' in sys.argv: output.write_text('### Remaining opportunities (U)\\n')\n"
                    "else: output.write_text('{}')\n"
                )
                cli.chmod(0o755)
                report = runner / "specificationmetrics"
                env = os.environ | {
                    "RUNNER_TEMP": str(runner), "REPORT_DIR": str(report), "BASE_SHA": sha,
                    "HEAD_SHA": sha, "ANALYZER_SHA": "a" * 40, "PROJECT_NAME": "owner/repo",
                    "GITHUB_RUN_ID": "123", "GITHUB_RUN_ATTEMPT": "2",
                    "GITHUB_STEP_SUMMARY": str(runner / "summary.md"),
                }
                result = subprocess.run(["bash", "--noprofile", "--norc", "-euo", "pipefail", "-c",
                                         step("Capture and compare source snapshots")], cwd=repo, env=env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 23 if fail_head else 0, result.stderr)
                provenance = json.loads((report / "provenance.json").read_text())
                self.assertEqual(provenance["base_sha"], sha)
                self.assertEqual(provenance["run_attempt"], "2")
                self.assertEqual(provenance["collection_execution"], "started" if fail_head else "completed")
                self.assertTrue((report / "before.json").is_file())
                self.assertEqual((report / "diff.json").exists(), not fail_head)
                self.assertEqual((report / "locations.md").exists(), not fail_head)
                if not fail_head:
                    subprocess.run(["bash", "--noprofile", "--norc", "-euo", "pipefail", "-c",
                                    step("Summarize diagnostic observations")], cwd=repo, env=env, check=True)
                    summary = (runner / "summary.md").read_text()
                    self.assertIn("**provisional**", summary)
                    self.assertIn("parse issues 1", summary)
                    self.assertIn("Swift CC/Cog are not measured", summary)


if __name__ == "__main__":
    unittest.main()
