"""Batch LibreOffice conversions without disturbing the GUI or existing files."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

# https://help.libreoffice.org/latest/en-US/text/shared/guide/convertfilters.html
FORMATS = {
    "pdf": "pdf",
    "slides-text": "fodp:OpenDocument Presentation Flat XML",
    "pptx": "pptx:Impress MS PowerPoint 2007 XML",
    "txt": "txt:Text (encoded):UTF8",
    "docx": "docx:Office Open XML Text",
    "csv": "csv:Text - txt - csv (StarCalc):44,34,76,1",
    "xlsx": "xlsx:Calc MS Excel 2007 XML",
}
NS = {
    "office": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
    "draw": "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
    "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
    "presentation": "urn:oasis:names:tc:opendocument:xmlns:presentation:1.0",
}


def slide_text(path):
    root = ET.parse(path).getroot()
    pages = root.findall("./office:body/office:presentation/draw:page", NS)
    if not pages:
        raise ValueError("LibreOffice produced no slides")
    for element in root.iter():
        if element.tag == f"{{{NS['text']}}}s":
            element.text = " " * int(element.get(f"{{{NS['text']}}}c", "1"))
        elif element.tag == f"{{{NS['text']}}}tab":
            element.text = "\t"
        elif element.tag == f"{{{NS['text']}}}line-break":
            element.text = "\n"
    slides = []
    for number, page in enumerate(pages, 1):
        lines = [f"Slide {number}"]
        for shape in page:
            if shape.tag == f"{{{NS['presentation']}}}notes":
                continue
            lines.extend("".join(p.itertext()) for p in shape.findall(".//text:p", NS))
        slides.append("\n".join(lines))
    return "\n\n".join(slides) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("format", choices=FORMATS)
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("-o", "--outdir", type=Path, default=Path.cwd(),
                        help="output directory (default: current directory)")
    args = parser.parse_args()
    executable = shutil.which("libreoffice") or shutil.which("soffice")
    if not executable:
        parser.exit(1, "LibreOffice is missing. On Debian install libreoffice through apt.\n")
    try:
        args.outdir = args.outdir.expanduser()
        args.outdir.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        parser.exit(1, f"{args.outdir}: {error}\n")
    extension = "txt" if args.format == "slides-text" else args.format
    failed = False
    for source in args.files:
        try:
            source = source.expanduser().resolve(strict=True)
            if not source.is_file():
                raise ValueError(f"not a file: {source}")
            destination = args.outdir / f"{source.stem}.{extension}"
            if destination.exists() or destination.is_symlink():
                raise FileExistsError(f"refusing to overwrite {destination}")
            with tempfile.TemporaryDirectory(prefix="office-convert-") as temp:
                work = Path(temp)
                subprocess.run(
                    [
                        executable,
                        f"-env:UserInstallation={(work / 'profile').as_uri()}",
                        "--headless", "--convert-to", FORMATS[args.format],
                        "--outdir", str(work), str(source),
                    ],
                    check=True,
                    timeout=180,
                    env={**os.environ, "SAL_USE_VCLPLUGIN": "svp"},
                )
                suffix = "fodp" if args.format == "slides-text" else extension
                converted = work / f"{source.stem}.{suffix}"
                if not converted.is_file() or not converted.stat().st_size:
                    raise ValueError(f"LibreOffice did not produce {converted.name}")
                if args.format == "slides-text":
                    converted.write_text(slide_text(converted), encoding="utf-8")
                # Exclusive creation also protects duplicate basenames in a batch.
                with converted.open("rb") as content, destination.open("xb") as output:
                    shutil.copyfileobj(content, output)
            print(destination)
        except (OSError, ValueError, ET.ParseError, subprocess.SubprocessError) as error:
            print(f"{source}: {error}", file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
