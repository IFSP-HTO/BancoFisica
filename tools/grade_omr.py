#!/usr/bin/env python3
"""Read BancoFisica IFSP-OMR answer sheets from PDF/images.

The grader is deliberately conservative: blank, multiple, ambiguous, unreadable QR
or missing page markers are flagged for manual review rather than guessed.
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

try:
    import cv2
    import numpy as np
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Install provas/requirements.txt before using grade_omr.py") from exc

LETTERS = "ABCDE"
ROOT = Path(__file__).resolve().parents[1]

def assert_private_student_path(path: Path) -> None:
    """Reject student-level files in versioned repository paths."""
    try:
        rel = path.resolve().relative_to(ROOT)
    except ValueError:
        return
    if len(rel.parts) < 2 or rel.parts[:2] != ("build", "private"):
        raise SystemExit("Privacy guard: scans/names/grades inside the repository must live under build/private/ (gitignored).")



def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_pages(path: Path, dpi: int) -> tuple[list[np.ndarray], tempfile.TemporaryDirectory | None]:
    ext = path.suffix.lower()
    if ext == ".pdf":
        if shutil.which("pdftoppm") is None:
            raise SystemExit("pdftoppm is required to grade PDF scans")
        td = tempfile.TemporaryDirectory(prefix="bf-omr-")
        prefix = Path(td.name) / "page"
        subprocess.run(["pdftoppm", "-r", str(dpi), "-png", str(path), str(prefix)], check=True)
        files = sorted(Path(td.name).glob("page-*.png"))
        return [cv2.imread(str(f), cv2.IMREAD_GRAYSCALE) for f in files], td
    img = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise SystemExit(f"Could not read image: {path}")
    return [img], None


def _square_candidates(gray: np.ndarray) -> list[tuple[float, float, float]]:
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, bw = cv2.threshold(blur, 70, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(bw, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    h, w = gray.shape
    out = []
    for c in contours:
        x, y, cw, ch = cv2.boundingRect(c)
        area = cv2.contourArea(c)
        if area < 0.00015 * w * h or area > 0.01 * w * h:
            continue
        ratio = cw / max(ch, 1)
        if not 0.65 <= ratio <= 1.35:
            continue
        fill = area / max(cw * ch, 1)
        if fill < 0.55:
            continue
        out.append((x + cw / 2, y + ch / 2, area))
    return out


def find_page_markers(gray: np.ndarray) -> np.ndarray:
    h, w = gray.shape
    cand = _square_candidates(gray)
    targets = [(0.07*w, 0.05*h), (0.93*w, 0.05*h), (0.07*w, 0.95*h), (0.93*w, 0.95*h)]
    chosen = []
    used: set[int] = set()
    for tx, ty in targets:
        ranked = sorted(
            enumerate(cand),
            key=lambda z: (z[1][0]-tx)**2 + (z[1][1]-ty)**2,
        )
        pick = next((i for i, c in ranked if i not in used), None)
        if pick is None:
            raise ValueError("could not locate four page markers")
        used.add(pick)
        chosen.append(cand[pick][:2])
    return np.array(chosen, dtype=np.float32)


def canonicalize(gray: np.ndarray, profile: dict[str, Any], dpi: int) -> np.ndarray:
    omr = profile["omr"]
    page_w = float(omr["page_width_cm"])
    page_h = float(omr["page_height_cm"])
    px_cm = dpi / 2.54
    out_w, out_h = round(page_w * px_cm), round(page_h * px_cm)
    markers = omr["page_markers_cm"]
    dst = np.array([
        markers["top_left"], markers["top_right"], markers["bottom_left"], markers["bottom_right"]
    ], dtype=np.float32) * px_cm
    src = find_page_markers(gray)
    H = cv2.getPerspectiveTransform(src, dst)
    return cv2.warpPerspective(gray, H, (out_w, out_h), flags=cv2.INTER_LINEAR, borderValue=255)


def decode_qr(gray: np.ndarray) -> str:
    det = cv2.QRCodeDetector()
    value, _, _ = det.detectAndDecode(gray)
    return value.strip()


def bubble_dark_fraction(gray: np.ndarray, x_cm: float, y_cm: float, r_cm: float, dpi: int) -> float:
    px_cm = dpi / 2.54
    cx, cy = int(round(x_cm * px_cm)), int(round(y_cm * px_cm))
    # Use the inner disk so the printed outline contributes little to the score.
    r = max(2, int(round(r_cm * px_cm * 0.66)))
    y0, y1 = max(0, cy-r), min(gray.shape[0], cy+r+1)
    x0, x1 = max(0, cx-r), min(gray.shape[1], cx+r+1)
    crop = gray[y0:y1, x0:x1]
    yy, xx = np.ogrid[:crop.shape[0], :crop.shape[1]]
    mask = (xx-(cx-x0))**2 + (yy-(cy-y0))**2 <= r*r
    if not mask.any():
        return 0.0
    return float(np.mean(crop[mask] < 150))


def read_responses(gray: np.ndarray, profile: dict[str, Any], dpi: int) -> tuple[str, list[str], list[list[float]]]:
    omr = profile["omr"]
    xs_l = [float(x) for x in omr["bubbles_cm"]["left_x"]]
    xs_r = [float(x) for x in omr["bubbles_cm"]["right_x"]]
    ys = [float(y) for y in omr["bubbles_cm"]["y"]]
    r = float(omr["bubble_radius_cm"])
    threshold = float(omr.get("fill_threshold", 0.28))
    margin = float(omr.get("ambiguity_margin", 0.08))
    answers: list[str] = []
    flags: list[str] = []
    scores_all: list[list[float]] = []
    for q in range(10):
        xs = xs_l if q < 5 else xs_r
        y = ys[q if q < 5 else q-5]
        scores = [bubble_dark_fraction(gray, x, y, r, dpi) for x in xs]
        scores_all.append(scores)
        order = sorted(range(5), key=lambda i: scores[i], reverse=True)
        top, second = scores[order[0]], scores[order[1]]
        marked = [i for i, s in enumerate(scores) if s >= threshold]
        if not marked:
            answers.append("-")
            flags.append(f"Q{q+1}:blank")
        elif len(marked) > 1:
            answers.append("?")
            flags.append(f"Q{q+1}:multiple")
        elif top - second < margin:
            answers.append("?")
            flags.append(f"Q{q+1}:ambiguous")
        else:
            answers.append(LETTERS[order[0]])
    return "".join(answers), flags, scores_all


def names_map(path: Path | None) -> dict[int, str]:
    if path is None:
        return {}
    out: dict[int, str] = {}
    with path.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            out[int(row["page"])] = row.get("name", "")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("scan", type=Path)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--profile", type=Path, default=Path("provas/profiles/ifsp-omr.yaml"))
    ap.add_argument("--names-csv", type=Path, help="Optional CSV with columns page,name")
    ap.add_argument("--output", type=Path, default=Path("build/private/grades.csv"))
    ap.add_argument("--dpi", type=int, default=200)
    ap.add_argument("--debug-dir", type=Path)
    args = ap.parse_args()

    assert_private_student_path(args.scan)
    assert_private_student_path(args.output)
    if args.names_csv is not None:
        assert_private_student_path(args.names_csv)
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    profile = load_yaml(args.profile)
    names = names_map(args.names_csv)
    pages, td = load_pages(args.scan, args.dpi)
    if args.debug_dir:
        args.debug_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    for page_no, page in enumerate(pages, 1):
        flags: list[str] = []
        try:
            canon = canonicalize(page, profile, args.dpi)
        except Exception as exc:
            rows.append([page_no, names.get(page_no, ""), "", "", "", "", "manual_review", f"markers:{exc}"])
            continue
        qr = decode_qr(canon)
        code = qr.split("|")[-1] if qr else ""
        version = manifest.get("versions", {}).get(code)
        if not version:
            flags.append("qr_unreadable_or_unknown")
        responses, omr_flags, raw = read_responses(canon, profile, args.dpi)
        flags.extend(omr_flags)
        key = "" if version is None else "".join(version["answers"])
        score = ""
        status = "manual_review" if flags else "ok"
        if version is not None and "?" not in responses:
            score = sum(a == b for a, b in zip(responses, key))
        rows.append([page_no, names.get(page_no, ""), code, responses, key, score, status, ";".join(flags)])
        if args.debug_dir:
            cv2.imwrite(str(args.debug_dir / f"page-{page_no:03d}.png"), canon)
            (args.debug_dir / f"page-{page_no:03d}.json").write_text(
                json.dumps({"qr": qr, "code": code, "responses": responses, "flags": flags, "fill": raw}, indent=2),
                encoding="utf-8",
            )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["page", "name", "control_code", "responses", "key", "score", "status", "flags"])
        w.writerows(rows)
    if td is not None:
        td.cleanup()
    print(f"Wrote {len(rows)} row(s) to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
