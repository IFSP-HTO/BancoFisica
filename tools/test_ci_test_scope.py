#!/usr/bin/env python3
"""Fast regression checks for tools/ci_test_scope.py."""

from __future__ import annotations

import tempfile
from pathlib import Path

from ci_test_scope import choose_scope, choose_test_profile


def write(path: Path, text: str = "x") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def assert_case(root: Path, changed, expected_mode, expected_questions, expected_profile):
    mode, questions, _ = choose_scope(root, changed)
    profile = choose_test_profile(root, changed, mode)
    assert mode == expected_mode, (changed, mode, expected_mode)
    assert questions == expected_questions, (changed, questions, expected_questions)
    assert profile == expected_profile, (changed, profile, expected_profile)


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
            'include_supplement("../figuras/shared.png")\n'
            "\\includegraphics{../figuras/shared.png}",
        )
        write(
            root / "BancoDeQuestoes/dinamica/Q4.Rnw",
            'asset <- "dynamic.png"\ninclude_supplement(asset)\n'
            "\\includegraphics{dynamic.png}",
        )
        write(root / "BancoDeQuestoes/cinematica/MCU/img1.jpeg")
        write(root / "BancoDeQuestoes/cinematica/MCU/unmapped.dat")
        write(root / "BancoDeQuestoes/figuras/shared.png")
        write(root / "BancoDeQuestoes/dinamica/dynamic.png")

        assert_case(
            root,
            ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            "incremental",
            ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            "full",
        )
        assert_case(
            root,
            ["BancoDeQuestoes/cinematica/MCU/img1.jpeg"],
            "incremental",
            ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            "asset",
        )
        assert_case(
            root,
            ["BancoDeQuestoes/figuras/shared.png"],
            "incremental",
            ["BancoDeQuestoes/dinamica/Q3.Rnw"],
            "asset",
        )
        # The dependency is discoverable, but dynamic supplement registration is
        # not strong enough evidence to reduce random-seed coverage.
        assert_case(
            root,
            ["BancoDeQuestoes/dinamica/dynamic.png"],
            "incremental",
            ["BancoDeQuestoes/dinamica/Q4.Rnw"],
            "full",
        )
        assert_case(
            root,
            ["BancoDeQuestoes/cinematica/MCU/unmapped.dat"],
            "incremental",
            [
                "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
                "BancoDeQuestoes/cinematica/MCU/Q2.Rnw",
            ],
            "full",
        )
        assert_case(root, ["README.md"], "none", [], "none")

        mode, questions, _ = choose_scope(root, ["tests/tests.R"])
        assert mode == "full"
        assert len(questions) == 4
        assert choose_test_profile(root, ["tests/tests.R"], mode) == "full"

        # Asset + question source in the same change must keep the complete seed profile.
        assert_case(
            root,
            [
                "BancoDeQuestoes/cinematica/MCU/img1.jpeg",
                "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
            ],
            "incremental",
            ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            "full",
        )

        # A removed/renamed asset that no longer has references must not widen scope.
        write(
            root / "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
            'include_supplement("replacement.jpeg")',
        )
        assert_case(
            root,
            [
                "BancoDeQuestoes/cinematica/MCU/old.jpeg",
                "BancoDeQuestoes/cinematica/MCU/Q1.Rnw",
            ],
            "incremental",
            ["BancoDeQuestoes/cinematica/MCU/Q1.Rnw"],
            "full",
        )

        # An existing shared asset that cannot be mapped remains fully conservative.
        write(root / "BancoDeQuestoes/figuras/unknown.png")
        mode, questions, _ = choose_scope(root, ["BancoDeQuestoes/figuras/unknown.png"])
        assert mode == "full"
        assert len(questions) == 4
        assert choose_test_profile(
            root, ["BancoDeQuestoes/figuras/unknown.png"], mode
        ) == "full"

    print("ci_test_scope regression checks: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
