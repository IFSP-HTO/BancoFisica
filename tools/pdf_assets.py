#!/usr/bin/env python3
"""Extract source images from PDFs without base64 transport or AI redrawing.

Two fidelity-preserving modes are supported:

* ``extract`` copies an embedded raster image from the PDF without re-encoding.
* ``crop`` renders only a selected PDF region at a requested DPI.

``batch`` processes a CSV manifest and keeps each source PDF open while all of
its assets are generated.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import defaultdict
from pathlib import Path
import sys
from typing import Iterable

try:
    import fitz  # PyMuPDF
except ImportError as exc:  # pragma: no cover - friendly CLI failure
    raise SystemExit(
        "PyMuPDF is required. Install it with: python -m pip install pymupdf"
    ) from exc


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_page(doc: fitz.Document, page_number: int) -> fitz.Page:
    if page_number < 1 or page_number > doc.page_count:
        raise ValueError(
            f"page must be between 1 and {doc.page_count}; got {page_number}"
        )
    return doc.load_page(page_number - 1)


def ensure_output(path: Path, *, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"output already exists: {path} (use --force to replace)")
    path.parent.mkdir(parents=True, exist_ok=True)


def parse_box(values: Iterable[float], page_rect: fitz.Rect, *, percent: bool) -> fitz.Rect:
    values = list(values)
    if len(values) != 4:
        raise ValueError("bounding box must have four numbers: x0 y0 x1 y1")

    x0, y0, x1, y1 = values
    if percent:
        if not all(0.0 <= value <= 100.0 for value in values):
            raise ValueError("percentage coordinates must be in [0, 100]")
        x0 = page_rect.x0 + page_rect.width * x0 / 100.0
        x1 = page_rect.x0 + page_rect.width * x1 / 100.0
        y0 = page_rect.y0 + page_rect.height * y0 / 100.0
        y1 = page_rect.y0 + page_rect.height * y1 / 100.0

    clip = fitz.Rect(x0, y0, x1, y1) & page_rect
    if clip.is_empty or clip.width <= 0 or clip.height <= 0:
        raise ValueError(f"empty crop after clipping to page: {clip}")
    return clip


def write_provenance(output: Path, payload: dict, *, enabled: bool, force: bool) -> None:
    if not enabled:
        return
    sidecar = output.with_suffix(output.suffix + ".source.json")
    ensure_output(sidecar, force=force)
    sidecar.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def render_page_from_doc(
    doc: fitz.Document, page_number: int, output: Path, *, dpi: int, force: bool
) -> None:
    page = ensure_page(doc, page_number)
    ensure_output(output, force=force)
    page.get_pixmap(dpi=dpi, alpha=False).save(output)


def crop_from_doc(
    doc: fitz.Document,
    source_pdf: Path,
    page_number: int,
    output: Path,
    bbox: Iterable[float],
    *,
    percent: bool,
    dpi: int,
    provenance: bool,
    source_hash: str,
    force: bool,
) -> None:
    page = ensure_page(doc, page_number)
    clip = parse_box(bbox, page.rect, percent=percent)
    ensure_output(output, force=force)
    page.get_pixmap(clip=clip, dpi=dpi, alpha=False).save(output)
    write_provenance(
        output,
        {
            "source_pdf": source_pdf.name,
            "source_sha256": source_hash,
            "mode": "crop",
            "page": page_number,
            "bbox_pdf_points": [
                round(clip.x0, 3),
                round(clip.y0, 3),
                round(clip.x1, 3),
                round(clip.y1, 3),
            ],
            "dpi": dpi,
            "output": output.as_posix(),
        },
        enabled=provenance,
        force=force,
    )


def list_images_from_doc(doc: fitz.Document, page_number: int) -> None:
    page = ensure_page(doc, page_number)
    images = page.get_images(full=True)
    if not images:
        print("No embedded raster images found on this page.")
        return

    print("index\txref\twidth\theight\tbpc\tcolorspace\tname")
    for index, info in enumerate(images):
        xref, _smask, width, height, bpc, colorspace, _alt, name = info[:8]
        print(f"{index}\t{xref}\t{width}\t{height}\t{bpc}\t{colorspace}\t{name}")


def extract_xref_from_doc(
    doc: fitz.Document,
    source_pdf: Path,
    xref: int,
    output: Path | None,
    *,
    provenance: bool,
    source_hash: str,
    force: bool,
) -> Path:
    data = doc.extract_image(xref)
    if not data:
        raise ValueError(f"xref {xref} is not an extractable image")

    extension = data.get("ext", "bin")
    if output is None:
        output = Path(f"xref-{xref}.{extension}")
    elif output.suffix == "":
        output = output.with_suffix(f".{extension}")

    ensure_output(output, force=force)
    output.write_bytes(data["image"])
    write_provenance(
        output,
        {
            "source_pdf": source_pdf.name,
            "source_sha256": source_hash,
            "mode": "embedded",
            "xref": xref,
            "original_extension": extension,
            "output": output.as_posix(),
        },
        enabled=provenance,
        force=force,
    )
    return output


def resolve_from_root(root: Path, value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else root / path


def process_batch(manifest: Path, root: Path, *, provenance: bool, force: bool) -> None:
    with manifest.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    if not rows:
        raise ValueError("manifest has no rows")

    required = {"pdf", "mode", "output"}
    missing = required - set(rows[0])
    if missing:
        raise ValueError(f"manifest missing columns: {', '.join(sorted(missing))}")

    grouped: dict[Path, list[tuple[int, dict[str, str]]]] = defaultdict(list)
    for row_number, row in enumerate(rows, start=2):
        pdf = resolve_from_root(root, row["pdf"]).resolve()
        grouped[pdf].append((row_number, row))

    for pdf, pdf_rows in grouped.items():
        if not pdf.exists():
            raise FileNotFoundError(f"source PDF not found: {pdf}")

        source_hash = sha256_file(pdf)
        with fitz.open(pdf) as doc:
            for row_number, row in pdf_rows:
                output = resolve_from_root(root, row["output"])
                mode = row["mode"].strip().lower()
                try:
                    if mode == "crop":
                        page = int(row["page"])
                        dpi = int(row.get("dpi") or 300)
                        bbox = [float(row[key]) for key in ("x0", "y0", "x1", "y1")]
                        unit = (row.get("unit") or "percent").strip().lower()
                        if unit not in {"percent", "points"}:
                            raise ValueError("unit must be percent or points")
                        crop_from_doc(
                            doc,
                            pdf,
                            page,
                            output,
                            bbox,
                            percent=(unit == "percent"),
                            dpi=dpi,
                            provenance=provenance,
                            source_hash=source_hash,
                            force=force,
                        )
                    elif mode == "embedded":
                        xref = int(row["xref"])
                        output = extract_xref_from_doc(
                            doc,
                            pdf,
                            xref,
                            output,
                            provenance=provenance,
                            source_hash=source_hash,
                            force=force,
                        )
                    else:
                        raise ValueError(f"unsupported mode {mode!r}")
                except Exception as exc:
                    raise ValueError(f"manifest row {row_number}: {exc}") from exc
                print(output)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    page = sub.add_parser("page", help="render a full page for visual inspection")
    page.add_argument("pdf", type=Path)
    page.add_argument("--page", type=int, required=True, help="1-based page number")
    page.add_argument("--output", type=Path, required=True)
    page.add_argument("--dpi", type=int, default=150)
    page.add_argument("--force", action="store_true")

    crop = sub.add_parser("crop", help="render only a rectangular PDF region")
    crop.add_argument("pdf", type=Path)
    crop.add_argument("--page", type=int, required=True, help="1-based page number")
    group = crop.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--bbox",
        nargs=4,
        type=float,
        metavar=("X0", "Y0", "X1", "Y1"),
        help="crop in PDF points",
    )
    group.add_argument(
        "--bbox-percent",
        nargs=4,
        type=float,
        metavar=("X0", "Y0", "X1", "Y1"),
        help="crop in percentages of page width/height",
    )
    crop.add_argument("--output", type=Path, required=True)
    crop.add_argument("--dpi", type=int, default=300)
    crop.add_argument("--provenance", action="store_true")
    crop.add_argument("--force", action="store_true")

    images = sub.add_parser("images", help="list embedded raster images on one page")
    images.add_argument("pdf", type=Path)
    images.add_argument("--page", type=int, required=True, help="1-based page number")

    extract = sub.add_parser(
        "extract", help="copy one embedded raster image by xref without re-encoding"
    )
    extract.add_argument("pdf", type=Path)
    extract.add_argument("--xref", type=int, required=True)
    extract.add_argument("--output", type=Path)
    extract.add_argument("--provenance", action="store_true")
    extract.add_argument("--force", action="store_true")

    batch = sub.add_parser("batch", help="process all rows of a CSV manifest")
    batch.add_argument("manifest", type=Path)
    batch.add_argument(
        "--root", type=Path, default=Path.cwd(), help="base path for relative manifest paths"
    )
    batch.add_argument("--provenance", action="store_true")
    batch.add_argument("--force", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "page":
            with fitz.open(args.pdf) as doc:
                render_page_from_doc(doc, args.page, args.output, dpi=args.dpi, force=args.force)
        elif args.command == "crop":
            source_hash = sha256_file(args.pdf)
            bbox = args.bbox if args.bbox is not None else args.bbox_percent
            with fitz.open(args.pdf) as doc:
                crop_from_doc(
                    doc,
                    args.pdf,
                    args.page,
                    args.output,
                    bbox,
                    percent=args.bbox_percent is not None,
                    dpi=args.dpi,
                    provenance=args.provenance,
                    source_hash=source_hash,
                    force=args.force,
                )
        elif args.command == "images":
            with fitz.open(args.pdf) as doc:
                list_images_from_doc(doc, args.page)
        elif args.command == "extract":
            source_hash = sha256_file(args.pdf)
            with fitz.open(args.pdf) as doc:
                output = extract_xref_from_doc(
                    doc,
                    args.pdf,
                    args.xref,
                    args.output,
                    provenance=args.provenance,
                    source_hash=source_hash,
                    force=args.force,
                )
            print(output)
        elif args.command == "batch":
            process_batch(
                args.manifest,
                args.root,
                provenance=args.provenance,
                force=args.force,
            )
        return 0
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
