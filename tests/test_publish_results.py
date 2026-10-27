"""Exercise publication with real local Git repositories; no network or MUSAN."""

from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".github/scripts/publish-preliminary-results.sh"


class PublishResultsTest(unittest.TestCase):
    def git(self, directory, *args):
        return subprocess.run(
            ["git", *args], cwd=directory, check=True, capture_output=True, text=True
        ).stdout.strip()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.origin = root / "origin.git"
        self.seed = root / "seed"
        self.worker = root / "worker"
        self.editor = root / "editor"
        self.seed.mkdir()
        self.git(root, "init", "--bare", "--initial-branch=main", str(self.origin))
        self.git(self.seed, "init", "--initial-branch=main")
        self.configure(self.seed)
        for name, value in {
            "README.md": "Initial documentation\n",
            "src/model.m": "% Original experiment\n",
            "data/splits/source_split.csv": "type,partition,path\n",
            "results/metrics.csv": "F1\n0.5\n",
            "results/preliminary_figures/chart.png": b"PNG\x00original",
        }.items():
            self.write(self.seed, name, value)
        self.git(self.seed, "add", ".")
        self.git(self.seed, "commit", "-m", "Initial experiment")
        self.git(self.seed, "remote", "add", "origin", str(self.origin))
        self.git(self.seed, "push", "origin", "main")
        for clone in (self.worker, self.editor):
            self.git(root, "clone", str(self.origin), str(clone))
            self.configure(clone)

    def configure(self, directory):
        self.git(directory, "config", "user.name", "Regression test")
        self.git(directory, "config", "user.email", "test@example.invalid")
        self.git(directory, "config", "commit.gpgsign", "false")

    @staticmethod
    def write(directory, name, value):
        path = directory / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(value if isinstance(value, bytes) else value.encode())

    def remote_change(self, name, value):
        self.write(self.editor, name, value)
        self.git(self.editor, "add", name)
        self.git(self.editor, "commit", "-m", "Concurrent repository update")
        self.git(self.editor, "push", "origin", "main")
        return self.git(self.editor, "rev-parse", "HEAD")

    def publish(self):
        return subprocess.run(
            ["bash", str(SCRIPT), "main"], cwd=self.worker,
            check=True, capture_output=True, text=True
        ).stdout

    def test_preserves_updates_made_while_experiment_runs(self):
        self.write(self.worker, "results/metrics.csv", "F1\n0.9\n")
        update = self.remote_change("README.md", "Documentation updated during run\n")
        self.assertIn("Published preliminary results", self.publish())
        self.assertEqual(self.git(self.origin, "show", "main:README.md"),
                         "Documentation updated during run")
        self.assertEqual(self.git(self.origin, "show", "main:results/metrics.csv"), "F1\n0.9")
        self.git(self.origin, "merge-base", "--is-ancestor", update, "main")

    def test_does_not_publish_results_for_outdated_experiment_code(self):
        self.write(self.worker, "results/metrics.csv", "F1\n0.9\n")
        update = self.remote_change("src/model.m", "% Experiment changed\n")
        self.assertIn("Experiment code changed", self.publish())
        self.assertEqual(self.git(self.origin, "rev-parse", "main"), update)
        self.assertEqual(self.git(self.origin, "show", "main:results/metrics.csv"), "F1\n0.5")

    def test_keeps_newer_remote_results_on_binary_conflict(self):
        self.write(self.worker, "results/preliminary_figures/chart.png", b"PNG\x00local result")
        update = self.remote_change("results/preliminary_figures/chart.png", b"PNG\x00remote result")
        self.assertIn("Results changed concurrently", self.publish())
        self.assertEqual(self.git(self.origin, "rev-parse", "main"), update)
        self.assertFalse((self.worker / ".git/rebase-merge").exists())

    def test_unchanged_results_do_not_create_empty_commit(self):
        before = self.git(self.origin, "rev-parse", "main")
        self.assertIn("already up to date", self.publish())
        self.assertEqual(self.git(self.origin, "rev-parse", "main"), before)
        self.assertEqual(self.git(self.worker, "rev-parse", "HEAD"), before)


if __name__ == "__main__":
    unittest.main()
