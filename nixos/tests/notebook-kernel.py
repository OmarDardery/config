"""Exercise project registration and execute a real kernel from its virtualenv."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'pkgs/notebook-kernel.py'


class KernelTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / 'course with spaces'
        self.project.mkdir()
        self.data = self.root / 'jupyter'
        self.env = {**os.environ, 'JUPYTER_DATA_DIR': str(self.data)}

    def venv(self, project=None, shared=True):
        project = project or self.project
        args = [sys.executable, '-m', 'venv', '--without-pip']
        if shared:
            args.append('--system-site-packages')
        subprocess.run([*args, str(project / '.venv')], check=True)
        if shared:
            # Reuse test-runner dependencies without downloading into every fixture.
            python = str(project / '.venv/bin/python')
            site = Path(subprocess.check_output(
                [python, '-c', 'import sysconfig; print(sysconfig.get_path("purelib"))'], text=True,
            ).strip())
            (site / 'test-dependencies.pth').write_text('\n'.join(p for p in sys.path if p and Path(p).is_dir()) + '\n')
            (site / 'project_probe.py').write_text('VALUE = 42\n')

    def register(self, project=None):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(project or self.project)],
            env=self.env, capture_output=True, text=True, timeout=30,
        )

    def test_real_kernel_uses_project_interpreter_and_dependencies(self):
        self.venv()
        result = self.register()
        self.assertEqual(result.returncode, 0, result.stderr)
        name = result.stdout.strip()
        spec = json.loads((self.data / 'kernels' / name / 'kernel.json').read_text())
        self.assertEqual(spec['argv'][0], str(self.project / '.venv/bin/python'))
        self.assertEqual(spec['display_name'], 'Python (course with spaces .venv)')
        from jupyter_client.kernelspec import KernelSpecManager
        manager = KernelSpecManager(kernel_dirs=[str(self.data / 'kernels')])
        self.assertEqual(manager.get_kernel_spec(name).argv[0], spec['argv'][0])
        # This runner forbids sockets. Execute an actual IPython cell in-process
        # with the registered interpreter instead of replacing it with a mock.
        code = (
            "from ipykernel.inprocess.manager import InProcessKernelManager; "
            "m = InProcessKernelManager(); m.start_kernel(); "
            "r = m.kernel.shell.run_cell("
            "'import sys, project_probe; assert project_probe.VALUE == 42; print(sys.prefix)'); "
            "assert r.success; m.shutdown_kernel()"
        )
        result = subprocess.run([spec['argv'][0], '-c', code], capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.project / '.venv'), result.stdout)

    def test_nested_directory_and_repeat_registration_are_stable(self):
        self.venv()
        nested = self.project / 'src/notebooks'
        nested.mkdir(parents=True)
        first = self.register()
        second = self.register(nested)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(first.stdout, second.stdout)
        self.assertEqual(len(list((self.data / 'kernels').iterdir())), 1)

    def test_same_named_projects_have_distinct_kernels(self):
        self.venv()
        other = self.root / 'another/course with spaces'
        other.mkdir(parents=True)
        self.venv(other)
        first, second = self.register(), self.register(other)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertNotEqual(first.stdout, second.stdout)

    def test_missing_kernel_dependency_does_not_install_anything(self):
        self.venv(shared=False)
        result = self.register()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('uv add --dev ipykernel', result.stderr)
        self.assertFalse(self.data.exists())

    def test_missing_environment_reports_actionable_error(self):
        result = self.register()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No project .venv', result.stderr)

    def test_nested_project_does_not_use_parent_environment(self):
        self.venv()
        nested = self.project / 'child'
        nested.mkdir()
        (nested / 'pyproject.toml').write_text('[project]\nname = "child"\n')
        self.assertNotEqual(self.register(nested).returncode, 0)


if __name__ == '__main__':
    unittest.main()
