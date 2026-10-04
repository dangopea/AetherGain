#!/usr/bin/env python3
"""
export_code_appendix.py
=======================

Walk the AetherGain project, collect all first-party source files, and
produce a single self-contained HTML file formatted as a code appendix
for an IB Computer Science IA.

- One file per section, each with a heading, its relative path, and the
  code beneath in a monospaced block.
- Each file starts on a new page (page-break-before: always).
- Table of contents at the top with line counts.
- Skips the noise: Xcode project internals, build outputs, tests,
  binary assets, Firebase transitive dependencies, secret plists.

Usage
-----
    python3 scripts/export_code_appendix.py

or from anywhere:
    python3 "/Users/glsarada/.../AetherGain/scripts/export_code_appendix.py"

Optional flags:
    --root PATH      Override project root (default = the folder above scripts/)
    --output PATH    Override output file (default = ~/Desktop/AetherGain_Code_Appendix.html)
    --font-size N    Code block font size in px (default = 9)
    --no-open        Do not auto-open the HTML in the default browser.

Then in Safari: File > Export as PDF   (or  Cmd+P > Save as PDF)
"""

from __future__ import annotations

import argparse
import html
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


# ---------------------------------------------------------------------------
# Configuration — tweak these if you want different scope.
# ---------------------------------------------------------------------------

# Directory names to skip anywhere in the tree.
SKIP_DIR_NAMES: set[str] = {
    # VCS / editor
    ".git", ".build", ".vscode", ".idea", "DerivedData",
    # Xcode auto-scaffold + build outputs
    "AetherGainTests",
    "AetherGainUITests",
    "Products",
    # Firebase transitive dependencies pulled in by SPM
    "SwiftProtobuf", "Promises", "abseil", "leveldb", "gRPC",
    "nanopb", "GoogleAppMeasurement", "GoogleUtilities",
    "GoogleDataTransport", "GTMSessionFetcher", "Firebase",
    "AppCheck", "InteropForGoogle", "GoogleAdsOnDeviceConversion",
    # Old phantom folders from earlier refactor (usually empty)
    # left in in case they still contain stubs
}

# Directory suffixes to always skip.
SKIP_DIR_SUFFIXES: tuple[str, ...] = (
    ".xcodeproj",       # Xcode project internals
    ".xcworkspace",     # workspace
    ".xcassets",        # binary asset catalog
    ".playground",
    ".swiftpm",
)

# Filenames to skip (bases only, not paths).
SKIP_FILE_NAMES: set[str] = {
    "GoogleService-Info.plist",   # Firebase secret config — DO NOT include
    "Package.resolved",
    ".DS_Store",
    ".gitignore",
    "info.plist",
    "Info.plist",
}

# File extensions to INCLUDE.
# Swift-only by default — the code appendix is for the iOS app source.
# Add ".py" or ".md" if you ever want the Python analysis / docs bundled too.
INCLUDE_EXTS: set[str] = {
    ".swift",
}


# ---------------------------------------------------------------------------
# File collection
# ---------------------------------------------------------------------------

def should_skip_dir(name: str) -> bool:
    if name in SKIP_DIR_NAMES:
        return True
    if name.startswith("."):
        return True
    if name.endswith(SKIP_DIR_SUFFIXES):
        return True
    return False


def collect_source_files(root: Path) -> list[Path]:
    collected: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        # Prune skip directories in-place so os.walk stops recursing.
        dirnames[:] = [d for d in dirnames if not should_skip_dir(d)]

        for f in filenames:
            if f in SKIP_FILE_NAMES:
                continue
            ext = Path(f).suffix.lower()
            if ext in INCLUDE_EXTS:
                collected.append(Path(dirpath) / f)

    # Sort so the appendix has a stable, logical order.
    collected.sort(key=lambda p: (p.parent.as_posix(), p.name))
    return collected


def relative_display_path(f: Path, root: Path) -> str:
    try:
        return str(f.relative_to(root))
    except ValueError:
        return str(f)


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

HTML_HEAD = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>AetherGain — Code Appendix</title>
<style>
  @page {{
    margin: 15mm 12mm;
  }}
  @media print {{
    body {{ margin: 0; }}
    section.file {{
      page-break-before: always;
      break-before: page;
    }}
    section.file:first-of-type {{ page-break-before: auto; }}
  }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue",
                 Helvetica, Arial, sans-serif;
    color: #111;
    max-width: 900px;
    margin: 0 auto;
    padding: 30px 25px;
    background: #fff;
    line-height: 1.4;
  }}
  h1 {{
    font-size: 26px;
    border-bottom: 2px solid #333;
    padding-bottom: 8px;
    margin-bottom: 18px;
  }}
  .meta {{ color: #555; font-size: 11px; margin-bottom: 20px; }}
  .toc {{
    background: #f9f9f9;
    border: 1px solid #ddd;
    padding: 16px 20px;
    margin-bottom: 30px;
    font-size: 11px;
    line-height: 1.5;
  }}
  .toc strong {{ font-size: 13px; }}
  .toc ul {{ padding-left: 18px; margin: 6px 0 0 0; }}
  .toc li {{ margin: 1px 0; }}
  .toc code {{ font-size: 10px; }}
  section.file {{ margin-bottom: 0; }}
  h2.filepath {{
    font-family: "SF Mono", Menlo, Consolas, "Courier New", monospace;
    font-size: 13px;
    background: #f0f0f0;
    padding: 8px 12px;
    border-left: 4px solid #ff8a2e;
    margin-top: 0;
    margin-bottom: 10px;
    word-break: break-all;
    color: #111;
  }}
  pre.code {{
    font-family: "SF Mono", Menlo, Consolas, "Courier New", monospace;
    font-size: {font_size}px;
    line-height: 1.35;
    background: #fafafa;
    border: 1px solid #ddd;
    padding: 10px 12px;
    overflow-x: auto;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
    tab-size: 4;
    -moz-tab-size: 4;
    color: #111;
    margin: 0;
  }}
  .file-meta {{
    color: #888;
    font-size: 10px;
    margin: 0 0 4px 2px;
    font-family: "SF Mono", Menlo, monospace;
  }}
</style>
</head>
<body>
"""


def build_html(files: list[Path], root: Path, font_size: int) -> str:
    total_lines = 0
    toc_items: list[str] = []
    sections: list[str] = []

    for i, f in enumerate(files, start=1):
        try:
            content = f.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            content = f"<< Could not read file: {e} >>"
        line_count = content.count("\n") + (0 if content.endswith("\n") else 1)
        if not content:
            line_count = 0
        total_lines += line_count

        rel = relative_display_path(f, root)
        anchor = f"file-{i}"
        toc_items.append(
            f'<li><a href="#{anchor}"><code>{html.escape(rel)}</code></a>'
            f' &mdash; {line_count} lines</li>'
        )
        sections.append(
            f'<section class="file" id="{anchor}">\n'
            f'  <h2 class="filepath">{html.escape(rel)}</h2>\n'
            f'  <div class="file-meta">{line_count} lines</div>\n'
            f'  <pre class="code">{html.escape(content)}</pre>\n'
            f'</section>\n'
        )

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")

    header = HTML_HEAD.format(font_size=font_size)
    title_block = (
        '<h1>AetherGain &mdash; Code Appendix</h1>\n'
        f'<div class="meta">'
        f'Generated {timestamp} &nbsp;·&nbsp; '
        f'Project root: <code>{html.escape(str(root))}</code><br/>'
        f'{len(files)} source files, {total_lines} total lines.'
        f'</div>\n'
    )
    toc = (
        '<div class="toc">'
        '<strong>Contents</strong>'
        f'<ul>{"".join(toc_items)}</ul>'
        '</div>\n'
    )
    body = "\n".join(sections)
    return header + title_block + toc + body + "\n</body>\n</html>\n"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def default_root() -> Path:
    """
    Default = the folder that contains scripts/ (i.e. the project root that
    holds AetherGain/, analysis/, IA_DOCUMENTATION.md).
    """
    return Path(__file__).resolve().parent.parent


def default_output() -> Path:
    return Path.home() / "Desktop" / "AetherGain_Code_Appendix.html"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate an HTML/PDF code appendix.")
    parser.add_argument("--root", type=Path, default=default_root(),
                        help="Project root to scan (default: parent of scripts/)")
    parser.add_argument("--output", type=Path, default=default_output(),
                        help=f"Output HTML path (default: {default_output()})")
    parser.add_argument("--font-size", type=int, default=9,
                        help="Code block font size in px (default 9)")
    parser.add_argument("--no-open", action="store_true",
                        help="Do not auto-open the generated HTML.")
    args = parser.parse_args(argv)

    root: Path = args.root.resolve()
    output: Path = args.output.resolve()

    if not root.exists():
        print(f"Error: project root does not exist: {root}", file=sys.stderr)
        return 1

    files = collect_source_files(root)
    if not files:
        print(f"No source files found under {root}.", file=sys.stderr)
        return 1

    print(f"Scanned  {root}")
    print(f"Collected {len(files)} source files.")
    for f in files:
        print(f"  {relative_display_path(f, root)}")

    html_content = build_html(files, root, args.font_size)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(html_content, encoding="utf-8")

    print()
    print(f"Wrote HTML: {output}")
    print("Next step: open in Safari and 'File > Export as PDF' "
          "(or Cmd+P > Save as PDF).")

    if not args.no_open and sys.platform == "darwin":
        try:
            subprocess.run(["open", str(output)], check=False)
        except Exception:
            pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
