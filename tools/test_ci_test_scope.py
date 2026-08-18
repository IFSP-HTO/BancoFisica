#!/usr/bin/env python3
"""Fast regression checks for tools/ci_test_scope.py."""

from __future__ import annotations

import tempfile
from pathlib import Path

from ci_test_scope import choose_scope


def write(path: Path, text: str = "x") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        write(
            root / "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
            'include_supplement("img1.jpeg")\n\\includegraphics{img1.jpeg}',
        )
        write(root / "BancoDeQuestoes/cinematica/MCU/Q2.Rnw", "sem figura")
        write(
            root / "BancoDeQuestoes/dinamica/Q3.Rnw",
            "\\includegraphics{../figuras/shared.png}",
        )
        write(root / "BancoDeQuestoes/cinematica/MCU/img1.jpeg")
        write(root / "BancoDeQuestoes/cinematica/MCU/unmapped.dat")
        write(root / "BancoDeQuestoes/figuras/shared.png")

        cases = [
            (
                ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
                "incremental",
                ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            ),
            (
                ["BancoDeQuestoes/cinematica/MCU/img1.jpeg"],
                "incremental",
                ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            ),
            (
                ["BancoDeQuestoes/figuras/shared.png"],
                "incremental",
                ["BancoDeQuestoes/dinamica/Q3.Rnw"],
            ),
            (
                ["BancoDeQuestoes/cinematica/MCU/unmapped.dat"],
                "incremental",
                [
                    "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
                    "BancoDeQuestoes/cinematica/MCU/Q2.Rnw",
                ],
            ),
            (["README.md"], "none", []),
        ]

        for changed, expected_mode, expected_questions in cases:
            mode, questions, _ = choose_scope(root, changed)
            assert mode == expected_mode, (changed, mode, expected_mode)
            assert questions == expected_questions, (changed, questions, expected_questions)

        mode, questions, _ = choose_scope(root, ["tests/tests.R"])
        assert mode == "full"
        assert len(questions) == 3

        # A removed/renamed asset that no longer has references must not widen scope.
        write(
            root / "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
            'include_supplement("replacement.jpeg")',
        )
        mode, questions, _ = choose_scope(
            root,
            [
                "BancoDeQuestoes/cinematica/MCU/old.jpeg",
                "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
            ],
        )
        assert mode == "incremental"
        assert questions == ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"]

        # An existing shared asset that cannot be mapped remains fully conservative.
        write(root / "BancoDeQuestoes/figuras/unknown.png")
        mode, questions, _ = choose_scope(
            root, ["BancoDeQuestoes/figuras/unknown.png"]
        )
        assert mode == "full"
        assert len(questions) == 3

    print("ci_test_scope regression checks: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
