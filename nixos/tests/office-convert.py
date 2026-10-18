"""Conversion contract checks with a fake LibreOffice (no GUI or host changes)."""

import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "pkgs/office-convert.py"
SPEC = importlib.util.spec_from_file_location("office_convert", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
FODP = f'''<office:document xmlns:office="{MODULE.NS['office']}"
 xmlns:draw="{MODULE.NS['draw']}" xmlns:text="{MODULE.NS['text']}"
 xmlns:presentation="{MODULE.NS['presentation']}">
 <office:master-styles><text:p>Master</text:p></office:master-styles>
 <office:body><office:presentation><draw:page>
 <draw:frame><draw:text-box><text:p>Hello<text:s text:c="2"/>世界<text:tab/>test<text:line-break/>next</text:p></draw:text-box></draw:frame>
 <presentation:notes><text:p>Secret notes</text:p></presentation:notes>
 </draw:page><draw:page><draw:frame><draw:text-box><text:p>Second slide</text:p></draw:text-box></draw:frame>
 </draw:page></office:presentation></office:body></office:document>'''


class ConversionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = {**os.environ, "PATH": str(self.bin)}
        mock = self.bin / "libreoffice"
        mock.write_text(f'''#!{sys.executable}
from pathlib import Path
import os
import sys
assert os.environ["SAL_USE_VCLPLUGIN"] == "svp"
args = sys.argv[1:]
assert args[0].startswith('-env:UserInstallation=file://')
source = Path(args[-1])
if source.stem == "failure":
    sys.exit(3)
if source.stem == "missing-output":
    sys.exit(0)
format = args[args.index('--convert-to') + 1].split(':')[0]
output = Path(args[args.index('--outdir') + 1]) / (source.stem + '.' + format)
output.write_text({FODP!r} if format == 'fodp' else 'converted ' + source.name)
''')
        mock.chmod(0o755)
        self.output = self.root / "output directory"

    def source(self, name):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("input")
        return path

    def run_converter(self, format, *files):
        return subprocess.run(
            [sys.executable, str(SCRIPT), format, *map(str, files), "-o", str(self.output)],
            env=self.env, text=True, capture_output=True, check=False,
        )

    def test_all_formats_and_space_in_filename(self):
        for format in MODULE.FORMATS:
            with self.subTest(format=format):
                source = self.source(f"{format} with spaces.pptx")
                result = self.run_converter(format, source)
                self.assertEqual(result.returncode, 0, result.stderr)
                suffix = "txt" if format == "slides-text" else format
                self.assertTrue((self.output / f"{source.stem}.{suffix}").is_file())

    def test_slide_text_order_and_whitespace_without_notes_or_master(self):
        source = self.source("lecture.pptx")
        result = self.run_converter("slides-text", source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.output / "lecture.txt").read_text(),
                         "Slide 1\nHello  世界\ttest\nnext\n\nSlide 2\nSecond slide\n")

    def test_existing_output_unchanged_and_batch_continues(self):
        first, second = self.source("one.ppt"), self.source("two.ppt")
        self.output.mkdir()
        target = self.output / "one.pdf"
        target.write_text("keep me")
        result = self.run_converter("pdf", first, second)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(target.read_text(), "keep me")
        self.assertTrue((self.output / "two.pdf").exists())

    def test_duplicate_basename_refused(self):
        result = self.run_converter("pdf", self.source("a/same.ppt"), self.source("b/same.pptx"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("refusing to overwrite", result.stderr)

    def test_failed_conversion_and_silent_failure(self):
        for stem in ["failure", "missing-output"]:
            with self.subTest(stem=stem):
                result = self.run_converter("pdf", self.source(stem + ".pptx"))
                self.assertEqual(result.returncode, 1)
                self.assertFalse((self.output / (stem + ".pdf")).exists())

    def test_missing_input(self):
        result = self.run_converter("pdf", self.root / "absent.pptx")
        self.assertEqual(result.returncode, 1)

    def test_native_soffice_fallback(self):
        (self.bin / "libreoffice").rename(self.bin / "soffice")
        self.assertEqual(self.run_converter("pdf", self.source("deck.ppt")).returncode, 0)

    def test_missing_libreoffice(self):
        (self.bin / "libreoffice").unlink()
        result = self.run_converter("pdf", self.source("deck.ppt"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("LibreOffice is missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
