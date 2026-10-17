#!/usr/bin/env python3
import argparse
import datetime as dt
import html
from pathlib import Path
import textwrap
import unicodedata


PAGE_WIDTH = 792
PAGE_HEIGHT = 612
MARGIN_LEFT = 38
MARGIN_RIGHT = 34
MARGIN_TOP = 46
MARGIN_BOTTOM = 42
HEADER_Y = PAGE_HEIGHT - 27
FOOTER_Y = 20
FILE_TITLE_SIZE = 18
FILE_PATH_SIZE = 8
CODE_SIZE = 7.4
LINE_HEIGHT = 9.4
CODE_FONT_WIDTH = CODE_SIZE * 0.6
LINE_NUMBER_WIDTH = 34
CODE_X = MARGIN_LEFT + LINE_NUMBER_WIDTH + 10

SOURCE_ROOTS = [
    "AetherGain",
    "AetherGainTests",
    "AetherGainUITests",
    "MLTraining",
]

EXCLUDED_PARTS = {
    ".git",
    ".build",
    "Products",
    "DerivedData",
    "abseil",
    "GoogleDataTransport",
    "gRPC",
    "SwiftProtobuf",
    "Promises",
    "AppCheck",
    "InteropForGoogle",
    "GTMSessionFetcher",
    "nanopb",
    "leveldb",
    "GoogleAdsOnDeviceConversion",
    "Firebase",
    "GoogleUtilities",
    "GoogleAppMeasurement",
}

CODE_EXTENSIONS = {
    ".swift",
    ".py",
}

EXTRA_FILES = [
    "../analysis/generate_report.py",
]


def plain_text(value):
    normalized = unicodedata.normalize("NFKD", value)
    return normalized.encode("cp1252", errors="replace").decode("cp1252")


def pdf_string(value):
    value = plain_text(value)
    value = value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
    value = value.replace("\n", " ")
    return f"({value})"


def normalize_code(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text.expandtabs(4).rstrip() + "\n"


def relative_sort_key(path):
    root_order = {root: index for index, root in enumerate(SOURCE_ROOTS)}
    return (root_order.get(path.parts[0], 99), str(path).lower())


def collect_files(project_root):
    files = []

    for source_root in SOURCE_ROOTS:
        root = project_root / source_root
        if not root.exists():
            continue

        for path in root.rglob("*"):
            relative_path = path.relative_to(project_root)
            if not path.is_file():
                continue
            if any(part in EXCLUDED_PARTS for part in relative_path.parts):
                continue
            if path.suffix in CODE_EXTENSIONS:
                files.append(relative_path)

    for extra in EXTRA_FILES:
        if (project_root / extra).is_file():
            files.append(Path(extra))

    return sorted(files, key=relative_sort_key)


class PDFAppendix:
    def __init__(self, title):
        self.title = title
        self.pages = []
        self.current = []
        self.y = PAGE_HEIGHT - MARGIN_TOP
        self.current_file = ""
        self.file_page = 0

    def command(self, value):
        self.current.append(value)

    def text(self, x, y, value, font="F1", size=10, color=(0, 0, 0)):
        r, g, b = color
        self.command(
            f"{r:.3f} {g:.3f} {b:.3f} rg BT /{font} {size:.2f} Tf {x:.2f} {y:.2f} Td {pdf_string(value)} Tj ET"
        )

    def line(self, x1, y1, x2, y2, color=(0.82, 0.82, 0.82), width=0.5):
        r, g, b = color
        self.command(f"{r:.3f} {g:.3f} {b:.3f} RG {width:.2f} w {x1:.2f} {y1:.2f} m {x2:.2f} {y2:.2f} l S")

    def rect(self, x, y, width, height, color):
        r, g, b = color
        self.command(f"{r:.3f} {g:.3f} {b:.3f} rg {x:.2f} {y:.2f} {width:.2f} {height:.2f} re f")

    def start_page(self, file_path=None, continued=False):
        if self.current:
            self.pages.append(self.current)

        self.current = []
        self.y = PAGE_HEIGHT - MARGIN_TOP

        if file_path is not None:
            self.current_file = str(file_path)
            self.file_page = 1
        elif self.current_file:
            self.file_page += 1

        self.text(MARGIN_LEFT, HEADER_Y, self.title, "F2", 9, (0.24, 0.24, 0.24))
        if self.current_file:
            header = self.current_file
            if continued:
                header += " continued"
            self.text(MARGIN_LEFT + 185, HEADER_Y, header, "F1", 8, (0.38, 0.38, 0.38))
        self.line(MARGIN_LEFT, HEADER_Y - 8, PAGE_WIDTH - MARGIN_RIGHT, HEADER_Y - 8, (0.84, 0.84, 0.84))

    def ensure_code_space(self):
        if self.y - LINE_HEIGHT < MARGIN_BOTTOM:
            self.start_page(continued=True)

    def add_title_page(self, files):
        self.current_file = ""
        self.file_page = 0
        self.start_page()
        self.text(MARGIN_LEFT, PAGE_HEIGHT - 115, "AetherGain", "F2", 30, (0.06, 0.06, 0.06))
        self.text(MARGIN_LEFT, PAGE_HEIGHT - 145, "Code Appendix", "F2", 19, (0.22, 0.22, 0.22))
        self.text(MARGIN_LEFT, PAGE_HEIGHT - 178, f"Generated {dt.date.today().isoformat()}", "F1", 10, (0.38, 0.38, 0.38))
        self.text(MARGIN_LEFT, PAGE_HEIGHT - 198, f"{len(files)} source files included", "F1", 10, (0.38, 0.38, 0.38))
        self.line(MARGIN_LEFT, PAGE_HEIGHT - 220, PAGE_WIDTH - MARGIN_RIGHT, PAGE_HEIGHT - 220, (0.78, 0.78, 0.78), 0.8)

        y = PAGE_HEIGHT - 250
        self.text(MARGIN_LEFT, y, "Contents", "F2", 13, (0.08, 0.08, 0.08))
        y -= 22
        for relative_path in files:
            if y < MARGIN_BOTTOM + 12:
                self.start_page()
                y = PAGE_HEIGHT - MARGIN_TOP
            self.text(MARGIN_LEFT, y, str(relative_path), "F3", 8.2, (0.10, 0.10, 0.10))
            y -= 11
        self.y = y

    def add_file_heading(self, relative_path):
        self.start_page(file_path=relative_path)
        self.text(MARGIN_LEFT, self.y, relative_path.name, "F2", FILE_TITLE_SIZE, (0.04, 0.04, 0.04))
        self.y -= 17
        self.text(MARGIN_LEFT, self.y, str(relative_path), "F1", FILE_PATH_SIZE, (0.35, 0.35, 0.35))
        self.y -= 15
        self.line(MARGIN_LEFT, self.y, PAGE_WIDTH - MARGIN_RIGHT, self.y, (0.76, 0.76, 0.76), 0.7)
        self.y -= 15

    def add_code_line(self, line_number, visual_line, continuation=False):
        self.ensure_code_space()
        band_y = self.y - 2
        self.rect(MARGIN_LEFT, band_y, PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT, LINE_HEIGHT, (0.985, 0.985, 0.985))

        number = "" if continuation else str(line_number)
        self.text(MARGIN_LEFT, self.y, number.rjust(4), "F3", CODE_SIZE, (0.55, 0.55, 0.55))
        self.text(CODE_X, self.y, visual_line, "F3", CODE_SIZE, (0.05, 0.05, 0.05))
        self.y -= LINE_HEIGHT

    def add_file(self, project_root, relative_path):
        self.add_file_heading(relative_path)
        code = normalize_code((project_root / relative_path).read_text(encoding="utf-8", errors="replace"))
        max_chars = int((PAGE_WIDTH - MARGIN_RIGHT - CODE_X) / CODE_FONT_WIDTH)
        wrapper = textwrap.TextWrapper(
            width=max_chars,
            replace_whitespace=False,
            drop_whitespace=False,
            break_long_words=True,
            break_on_hyphens=False,
            subsequent_indent="    ",
        )

        for line_number, line in enumerate(code.splitlines(), start=1):
            chunks = wrapper.wrap(line) or [""]
            for index, chunk in enumerate(chunks):
                self.add_code_line(line_number, chunk, continuation=index > 0)

    def finish(self):
        if self.current:
            self.pages.append(self.current)
            self.current = []

        total_pages = len(self.pages)
        for index, page in enumerate(self.pages, start=1):
            page.append(f"0.830 0.830 0.830 RG 0.50 w {MARGIN_LEFT:.2f} 32.00 m {PAGE_WIDTH - MARGIN_RIGHT:.2f} 32.00 l S")
            page.append(f"0.420 0.420 0.420 rg BT /F1 8.00 Tf {MARGIN_LEFT:.2f} {FOOTER_Y:.2f} Td {pdf_string('AetherGain Code Appendix')} Tj ET")
            page.append(f"0.420 0.420 0.420 rg BT /F1 8.00 Tf {PAGE_WIDTH - MARGIN_RIGHT - 76:.2f} {FOOTER_Y:.2f} Td {pdf_string(f'Page {index} of {total_pages}')} Tj ET")


def write_pdf(document, output_path):
    document.finish()
    objects = []

    def add_object(body):
        objects.append(body)
        return len(objects)

    catalog_id = add_object("<< /Type /Catalog /Pages 2 0 R >>")
    pages_id = add_object("")
    helvetica_id = add_object("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
    helvetica_bold_id = add_object("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>")
    courier_id = add_object("<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>")

    page_ids = []
    for page_commands in document.pages:
        stream = "\n".join(page_commands).encode("latin-1", errors="replace")
        content_id = add_object(
            f"<< /Length {len(stream)} >>\nstream\n{stream.decode('latin-1')}\nendstream"
        )
        page_id = add_object(
            "<< /Type /Page "
            f"/Parent {pages_id} 0 R "
            f"/MediaBox [0 0 {PAGE_WIDTH} {PAGE_HEIGHT}] "
            f"/Resources << /Font << /F1 {helvetica_id} 0 R /F2 {helvetica_bold_id} 0 R /F3 {courier_id} 0 R >> >> "
            f"/Contents {content_id} 0 R >>"
        )
        page_ids.append(page_id)

    kids = " ".join(f"{page_id} 0 R" for page_id in page_ids)
    objects[pages_id - 1] = f"<< /Type /Pages /Kids [{kids}] /Count {len(page_ids)} >>"

    output = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for object_id, body in enumerate(objects, start=1):
        offsets.append(len(output))
        output.extend(f"{object_id} 0 obj\n{body}\nendobj\n".encode("latin-1", errors="replace"))

    xref_start = len(output)
    output.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    output.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        output.extend(f"{offset:010d} 00000 n \n".encode("ascii"))

    output.extend(
        (
            "trailer\n"
            f"<< /Size {len(objects) + 1} /Root {catalog_id} 0 R >>\n"
            "startxref\n"
            f"{xref_start}\n"
            "%%EOF\n"
        ).encode("ascii")
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(output)


def write_html(project_root, files, output_path):
    rows = []
    for relative_path in files:
        code = normalize_code((project_root / relative_path).read_text(encoding="utf-8", errors="replace"))
        numbered_lines = []
        for line_number, line in enumerate(code.splitlines(), start=1):
            numbered_lines.append(
                f'<span class="line"><span class="number">{line_number}</span><span class="code">{html.escape(line)}</span></span>'
            )
        rows.append(
            "\n".join(
                [
                    '<section class="file">',
                    f"<h1>{html.escape(relative_path.name)}</h1>",
                    f'<p class="path">{html.escape(str(relative_path))}</p>',
                    '<pre class="code-block"><code>',
                    "\n".join(numbered_lines),
                    "</code></pre>",
                    "</section>",
                ]
            )
        )

    document = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>AetherGain Code Appendix</title>
<style>
@page {{
    size: landscape;
    margin: 14mm 12mm;
}}
body {{
    color: #111;
    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
    line-height: 1.35;
}}
.cover {{
    break-after: page;
    padding-top: 72px;
}}
.cover h1 {{
    font-size: 34px;
    margin: 0 0 8px;
}}
.cover p {{
    color: #555;
    margin: 0 0 18px;
}}
.contents {{
    columns: 2;
    font: 10px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
}}
.contents div {{
    break-inside: avoid;
    margin-bottom: 5px;
}}
.file {{
    break-before: page;
}}
h1 {{
    font-size: 22px;
    margin: 0 0 3px;
}}
.path {{
    color: #666;
    font-size: 10px;
    margin: 0 0 10px;
    border-bottom: 1px solid #ccc;
    padding-bottom: 7px;
}}
.code-block {{
    background: #fbfbfb;
    border: 1px solid #ddd;
    font: 8.5px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    line-height: 1.28;
    margin: 0;
    overflow: visible;
    padding: 8px 0;
    white-space: pre-wrap;
}}
.line {{
    display: block;
    min-height: 1.28em;
}}
.number {{
    color: #888;
    display: inline-block;
    padding-right: 10px;
    text-align: right;
    user-select: none;
    width: 34px;
}}
.code {{
    white-space: pre-wrap;
}}
</style>
</head>
<body>
<section class="cover">
<h1>AetherGain Code Appendix</h1>
<p>Generated {dt.date.today().isoformat()} · {len(files)} source files</p>
<div class="contents">
{''.join(f'<div>{html.escape(str(path))}</div>' for path in files)}
</div>
</section>
{''.join(rows)}
</body>
</html>
"""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(document, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Generate a clean code appendix for the AetherGain CS IA.")
    parser.add_argument(
        "-o",
        "--output",
        default="Appendix/CodeAppendix.pdf",
        help="PDF output path. Default: Appendix/CodeAppendix.pdf",
    )
    parser.add_argument(
        "--html-output",
        default="Appendix/CodeAppendix.html",
        help="HTML preview output path. Default: Appendix/CodeAppendix.html",
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Project root to scan. Default: current directory",
    )
    args = parser.parse_args()

    project_root = Path(args.root).resolve()
    output_path = Path(args.output)
    html_output_path = Path(args.html_output)

    if not output_path.is_absolute():
        output_path = project_root / output_path
    if not html_output_path.is_absolute():
        html_output_path = project_root / html_output_path

    files = collect_files(project_root)
    if not files:
        raise SystemExit("No source files found.")

    write_html(project_root, files, html_output_path)

    document = PDFAppendix("AetherGain Code Appendix")
    document.add_title_page(files)
    for relative_path in files:
        document.add_file(project_root, relative_path)

    write_pdf(document, output_path)
    print(f"Wrote {output_path}")
    print(f"Wrote {html_output_path}")
    print(f"Included {len(files)} files.")


if __name__ == "__main__":
    main()
