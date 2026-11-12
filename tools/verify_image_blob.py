#!/usr/bin/env python3
"""Preflight and verify image bytes for a GitHub create_blob(base64) transfer.

This does not upload to GitHub; the caller must invoke the connected GitHub API.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path
import struct
import sys

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def inspect_image(data: bytes) -> dict[str, object]:
    if data.startswith(PNG_SIGNATURE):
        if len(data) < 33 or data[12:16] != b"IHDR":
            raise ValueError("PNG sem cabecalho IHDR valido")
        width, height = struct.unpack(">II", data[16:24])
        if width < 1 or height < 1:
            raise ValueError("PNG com dimensoes invalidas")
        if b"IEND" not in data[-16:]:
            raise ValueError("PNG aparentemente truncado (IEND ausente)")
        return {"format": "PNG", "width": width, "height": height}
    if data.startswith(b"\xff\xd8\xff"):
        if not data.endswith(b"\xff\xd9"):
            raise ValueError("JPEG aparentemente truncado (EOI ausente)")
        return {"format": "JPEG", "width": None, "height": None}
    raise ValueError("Formato nao suportado: usar PNG ou JPEG")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=Path, help="Arquivo PNG/JPEG final aprovado")
    parser.add_argument("--remote-sha", help="SHA retornado por create_blob ou pelo tree Git remoto")
    parser.add_argument("--base64-out", type=Path, help="Opcional: gravar Base64 FORA do repositorio")
    args = parser.parse_args()

    if not args.image.is_file():
        parser.error("Arquivo nao encontrado; use o caminho real do anexo salvo")
    data = args.image.read_bytes()
    if not data:
        parser.error("Arquivo vazio")

    try:
        metadata = inspect_image(data)
    except ValueError as exc:
        parser.error(str(exc))

    git_sha = hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()
    sha256 = hashlib.sha256(data).hexdigest()
    result = {
        "filename": args.image.name,
        "bytes": len(data),
        **metadata,
        "git_blob_sha1": git_sha,
        "sha256": sha256,
        "remote_sha_matches": None,
    }
    if args.remote_sha:
        result["remote_sha_matches"] = git_sha.lower() == args.remote_sha.strip().lower()
    if args.base64_out:
        args.base64_out.parent.mkdir(parents=True, exist_ok=True)
        args.base64_out.write_text(base64.b64encode(data).decode("ascii"), encoding="ascii")
        result["base64_out"] = str(args.base64_out)

    print(json.dumps(result, ensure_ascii=False, indent=2))
    if result["remote_sha_matches"] is False:
        print("ERRO: SHA Git divergente; nao criar commit", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
