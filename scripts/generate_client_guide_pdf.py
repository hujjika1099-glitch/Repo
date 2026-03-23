#!/usr/bin/env python3
"""Generate a simple client-facing PDF from a Markdown guide without external dependencies."""

from __future__ import annotations

import argparse
import math
import re
import textwrap
from pathlib import Path


def normalize_markdown_line(line: str) -> str:
    line = line.rstrip("\n")
    if not line.strip():
        return ""

    # Headings
    if line.lstrip().startswith("#"):
        line = re.sub(r"^\s*#+\s*", "", line)
        return line.strip().upper()

    # Tables -> readable sentence-like text
    if line.strip().startswith("|") and line.strip().endswith("|"):
        cells = [c.strip() for c in line.strip("|").split("|")]
        if all(set(c) <= {"-", ":"} for c in cells):
            return ""
        return " | ".join(cells)

    # Bullets
    if re.match(r"^\s*[-*]\s+", line):
        line = re.sub(r"^\s*[-*]\s+", "- ", line)
        return line.strip()

    # Numbered list
    if re.match(r"^\s*\d+[.)]\s+", line):
        line = re.sub(r"^\s*(\d+)[.)]\s+", r"\1. ", line)
        return line.strip()

    # Code fences
    if line.strip().startswith("```"):
        return ""

    return line.strip()


def markdown_to_wrapped_lines(md_text: str, width: int = 96) -> list[str]:
    out: list[str] = []
    in_code = False

    for raw in md_text.splitlines():
        if raw.strip().startswith("```"):
            in_code = not in_code
            out.append("")
            continue

        if in_code:
            code_line = f"    {raw.rstrip()}"
            out.extend(textwrap.wrap(code_line, width=width, break_long_words=False, break_on_hyphens=False) or [""])
            continue

        line = normalize_markdown_line(raw)
        if line == "":
            out.append("")
            continue

        wrapped = textwrap.wrap(line, width=width, break_long_words=False, break_on_hyphens=False)
        out.extend(wrapped or [""])

    # Remove extra trailing blanks
    while out and out[-1] == "":
        out.pop()
    return out


def escape_pdf_text(s: str) -> str:
    s = s.replace("\\", "\\\\")
    s = s.replace("(", "\\(").replace(")", "\\)")
    return s


def build_page_stream(lines: list[str], title: str) -> bytes:
    stream_lines = [
        "BT",
        "/F1 11 Tf",
        "50 770 Td",
        "14 TL",
        f"({escape_pdf_text(title)}) Tj",
        "T*",
        "T*",
    ]
    for line in lines:
        stream_lines.append(f"({escape_pdf_text(line)}) Tj")
        stream_lines.append("T*")
    stream_lines.append("ET")
    stream = "\n".join(stream_lines).encode("latin-1", errors="replace")
    return stream


def write_simple_pdf(output_pdf: Path, pages_lines: list[list[str]], doc_title: str) -> None:
    # Object index plan:
    # 1: Catalog
    # 2: Pages
    # 3: Font (Helvetica)
    # For each page i:
    #   page_obj = 4 + i*2
    #   contents_obj = 5 + i*2

    objects: list[bytes] = []

    # 1 Catalog
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")

    # 2 Pages (kids filled after page objects known)
    # placeholder for now
    objects.append(b"")

    # 3 Font
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

    page_kids: list[str] = []

    for i, lines in enumerate(pages_lines):
        page_obj_num = 4 + i * 2
        contents_obj_num = 5 + i * 2
        page_kids.append(f"{page_obj_num} 0 R")

        page_dict = (
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            f"/Resources << /Font << /F1 3 0 R >> >> "
            f"/Contents {contents_obj_num} 0 R >>"
        ).encode("ascii")
        objects.append(page_dict)

        stream = build_page_stream(lines, doc_title)
        contents = (
            f"<< /Length {len(stream)} >>\nstream\n".encode("ascii")
            + stream
            + b"\nendstream"
        )
        objects.append(contents)

    kids = "[ " + " ".join(page_kids) + " ]"
    pages_obj = f"<< /Type /Pages /Kids {kids} /Count {len(page_kids)} >>".encode("ascii")
    objects[1] = pages_obj

    output_pdf.parent.mkdir(parents=True, exist_ok=True)

    with output_pdf.open("wb") as f:
        f.write(b"%PDF-1.4\n")

        offsets = [0]
        for idx, obj in enumerate(objects, start=1):
            offsets.append(f.tell())
            f.write(f"{idx} 0 obj\n".encode("ascii"))
            f.write(obj)
            f.write(b"\nendobj\n")

        xref_pos = f.tell()
        f.write(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
        f.write(b"0000000000 65535 f \n")
        for i in range(1, len(objects) + 1):
            f.write(f"{offsets[i]:010d} 00000 n \n".encode("ascii"))

        f.write(b"trailer\n")
        f.write(f"<< /Size {len(objects) + 1} /Root 1 0 R >>\n".encode("ascii"))
        f.write(b"startxref\n")
        f.write(f"{xref_pos}\n".encode("ascii"))
        f.write(b"%%EOF\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate client guide PDF from markdown")
    parser.add_argument("--input", default="reports/client_operational_guide.md", help="Input markdown file")
    parser.add_argument("--output", default="reports/client_operational_guide.pdf", help="Output PDF path")
    parser.add_argument("--title", default="ADXL335 + ESP32 - Guia Operativa", help="Document title")
    parser.add_argument("--width", type=int, default=96, help="Wrap width")
    parser.add_argument("--lines-per-page", type=int, default=45, help="Body lines per page")
    args = parser.parse_args()

    input_md = Path(args.input)
    output_pdf = Path(args.output)

    if not input_md.is_file():
        raise FileNotFoundError(f"Input markdown not found: {input_md}")

    md_text = input_md.read_text(encoding="utf-8")
    lines = markdown_to_wrapped_lines(md_text, width=max(60, args.width))

    if not lines:
        lines = ["Documento vacio"]

    lines_per_page = max(20, args.lines_per_page)
    page_count = math.ceil(len(lines) / lines_per_page)
    pages_lines = []

    for i in range(page_count):
        start = i * lines_per_page
        end = start + lines_per_page
        body = lines[start:end]
        body.append("")
        body.append(f"Pagina {i + 1} de {page_count}")
        pages_lines.append(body)

    write_simple_pdf(output_pdf, pages_lines, args.title)
    print(f"PDF_OK: {output_pdf.as_posix()}")
    print(f"PAGES: {page_count}")
    print(f"LINES: {len(lines)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
