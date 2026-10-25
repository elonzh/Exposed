"""Offline regression tests for the documentation sync workflow.

Run with: python3 -m unittest discover -s documentation-website-zh/scripts/tests -v
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
EN_DIR = Path("documentation-website/Writerside/topics")
ZH_DIR = Path("documentation-website-zh/Writerside/topics")


class SyncWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory(
            prefix="exposed-sync-test-", dir=os.environ.get("TMPDIR")
        )
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.scripts = self.root / "documentation-website-zh/scripts"
        self.scripts.mkdir(parents=True)
        for filename in ("sync.sh", "detect-changes.sh"):
            shutil.copy2(SCRIPTS_DIR / filename, self.scripts / filename)
        # Keep the real sync and detector; only isolate the network/merge step.
        (self.scripts / "fetch-upstream.sh").write_text("#!/bin/bash\nexit 0\n")
        for directory in (EN_DIR, ZH_DIR):
            (self.root / directory).mkdir(parents=True)
            (self.root / directory / "example.topic").write_text("Original topic\n")
        self.git("init", "--quiet")
        self.git("config", "user.name", "Sync Test")
        self.git("config", "user.email", "sync-test@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "tag.gpgsign", "false")
        self.git("config", "core.hooksPath", "/dev/null")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "Initial docs")
        self.git("tag", "docs-zh-sync-test")

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.root, capture_output=True, text=True, check=True
        )

    def run_sync(self, *args):
        return subprocess.run(
            ["bash", str(self.scripts / "sync.sh"), *args],
            cwd=self.root,
            capture_output=True,
            text=True,
            timeout=10,
        )

    def test_no_changes_ignores_detector_diagnostic_output(self):
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No changes detected. Nothing to do.", result.stdout)
        self.assertNotIn("Modified:", result.stdout)
        self.assertNotIn("Next steps:", result.stdout)
        self.assertIn("Last sync tag:", result.stderr)
        self.assertNotIn("Last sync tag:", result.stdout)

    def test_real_change_counts_only_the_document(self):
        (self.root / EN_DIR / "example.topic").write_text("Updated topic\n")
        os.utime(self.root / ZH_DIR / "example.topic", (1000000000, 1000000000))
        self.git("add", str(EN_DIR))
        self.git("commit", "--quiet", "-m", "Update English docs")
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Modified: 1 files", result.stdout)
        self.assertIn("  - example.topic", result.stdout)
        self.assertNotIn("Last sync tag:", result.stdout)
        self.assertIn("Last sync tag:", result.stderr)

    def test_up_to_date_diagnostic_does_not_create_a_change(self):
        (self.root / EN_DIR / "example.topic").write_text("Updated topic\n")
        self.git("add", str(EN_DIR))
        self.git("commit", "--quiet", "-m", "Update English docs")
        os.utime(self.root / EN_DIR / "example.topic", (1000000000, 1000000000))
        os.utime(self.root / ZH_DIR / "example.topic", (1000000001, 1000000001))
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No changes detected. Nothing to do.", result.stdout)
        self.assertNotIn("Modified:", result.stdout)
        self.assertIn("SKIP (up-to-date): example.topic", result.stderr)
        self.assertNotIn("SKIP", result.stdout)

    def test_all_flag_is_forwarded_to_detector(self):
        result = self.run_sync("--all")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Mode: ALL", result.stdout)
        self.assertIn("Modified: 1 files", result.stdout)
        self.assertIn("  - example.topic", result.stdout)

    def test_first_sync_lists_documents(self):
        self.git("tag", "-d", "docs-zh-sync-test")
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Mode: FIRST_SYNC", result.stdout)
        self.assertIn("Modified: 1 files", result.stdout)
        self.assertIn("  - example.topic", result.stdout)

    def test_detector_failure_stops_workflow_and_keeps_diagnostics(self):
        # Inject a dependency failure to check the sync process boundary.
        (self.scripts / "detect-changes.sh").write_text(
            "#!/bin/bash\nprintf 'Detector failed\\n' >&2\nexit 42\n"
        )
        result = self.run_sync()
        self.assertEqual(result.returncode, 42)
        self.assertIn("Detector failed", result.stderr)
        self.assertNotIn("Detector failed", result.stdout)
        self.assertNotIn("Next steps:", result.stdout)
        self.assertNotIn("No changes detected.", result.stdout)


if __name__ == "__main__":
    unittest.main()
