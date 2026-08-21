#!/usr/bin/env python3
"""Choose which BancoFisica questions need expensive CI compilation tests."""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path, PurePosixPath

GLOBAL_PREFIXES = (
    "tests/",
    "R/",
    "templates/",
)
GLOBAL_EXACT = {
    ".github/workflows/ci-image.yml",
    ".github/workflows/r-tests.yml",
    "docker/ci/Dockerfile",
    "DESCRIPTION",
    "NAMESPACE",
    "renv.lock",
    "tools/ci_test_scope.py",
    "tools/ci_compile_cache.py",
    "tools/moodle_xml_split.R",
}
GLOBAL_SUFFIXES = (".sty", ".cls", ".tex")

# Static support files for which changing the file itself cannot alter the
# question's random parameter generation. A reduced XML seed profile is only
# allowed when every BancoDeQuestoes change is one of these assets and each
# dependency can be mapped exactly to current question consumers.
STATIC_ASSET_SUFFIXES = {
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".svg",
    ".webp",
    ".pdf",
}


def normalize_changed_path(raw: str) -> str:
    path = raw.strip().replace("\\", "/")
    # Remove only an explicit relative-path prefix. str.lstrip("./") is not
    # appropriate here: it treats its argument as a set of characters and
    # therefore turns ".github/..." into "github/...".
    while path.startswith("./"):
        path = path[2:]
    return path


def all_questions(repo_root: Path) -> list[str]:
    files = []
    for path in (repo_root / "BancoDeQuestoes").rglob("*"):
        if path.is_file() and path.suffix.lower() == ".rnw":
            files.append(path.relative_to(repo_root).as_posix())
    return sorted(files)


def is_global_change(path: str) -> bool:
    if path in GLOBAL_EXACT:
        return True
    if any(path.startswith(prefix) for prefix in GLOBAL_PREFIXES):
        return True
    # R tooling can alter validation/reporting behavior even without touching a question.
    # Fall back to the full suite so changes to those helpers are exercised in CI.
    if path.startswith("tools/") and path.lower().endswith(".r"):
        return True
    if not path.startswith("BancoDeQuestoes/") and path.lower().endswith(GLOBAL_SUFFIXES):
        return True
    return False


def topic_questions(repo_root: Path, topic: str) -> list[str]:
    topic_dir = repo_root / "BancoDeQuestoes" / topic
    if not topic_dir.exists():
        return []
    return sorted(
        path.relative_to(repo_root).as_posix()
        for path in topic_dir.rglob("*")
        if path.is_file() and path.suffix.lower() == ".rnw"
    )


def read_question_text(path: Path) -> str:
    # Rnw files are expected to be UTF-8, but legacy questions occasionally contain
    # bytes from older encodings. Replacement keeps dependency discovery conservative
    # without making scope detection itself fail. Backslashes are normalized because
    # path matching elsewhere in this module is POSIX-style.
    return path.read_text(encoding="utf-8", errors="replace").replace("\\", "/")


def asset_reference_tokens(repo_root: Path, question_path: Path, asset_path: str) -> set[str]:
    """Return literal forms by which a question may reference an asset.

    Questions in the bank usually reference supplements by basename, while some use
    paths relative to the question directory or BancoDeQuestoes. Matching all of these
    forms intentionally permits false positives (extra tests) but avoids false negatives.
    """
    asset = PurePosixPath(asset_path)
    tokens = {asset.name, asset.as_posix()}

    bank_prefix = "BancoDeQuestoes/"
    if asset_path.startswith(bank_prefix):
        tokens.add(asset_path[len(bank_prefix) :])

    question_dir = question_path.parent
    asset_fs_path = repo_root / Path(*asset.parts)
    try:
        relative = os.path.relpath(asset_fs_path, start=question_dir).replace("\\", "/")
        tokens.add(relative)
        if relative.startswith("./"):
            tokens.add(relative[2:])
    except ValueError:
        # Different drives are only relevant on Windows; basename/full-path matching
        # still gives us safe dependency discovery there.
        pass

    return {token for token in tokens if token}


def has_direct_static_asset_reference(
    repo_root: Path, question: str, asset_path: str, text: str
) -> bool:
    """Require strong evidence that an asset is included independently of a seed.

    General dependency discovery intentionally accepts broad literal matches so CI can
    over-select safely. The reduced `asset` profile is stricter: the current Rnw must
    contain both a literal include_supplement("...") call and a literal
    \includegraphics{...} reference to the same changed file (possibly using different
    equivalent path forms). Dynamic/conditional constructions therefore fall back to
    the historical full multi-seed profile.
    """
    question_path = repo_root / question
    tokens = asset_reference_tokens(repo_root, question_path, asset_path)

    has_supplement = False
    has_graphics = False
    for token in tokens:
        escaped = re.escape(token)
        supplement = re.compile(
            rf"include_supplement\s*\(\s*([\"']){escaped}\1"
        )
        # read_question_text() normalizes the LaTeX backslash to '/'.
        graphics = re.compile(
            rf"/includegraphics\s*(?:\[[^\]]*\]\s*)?\{{\s*{escaped}\s*\}}"
        )
        has_supplement = has_supplement or bool(supplement.search(text))
        has_graphics = has_graphics or bool(graphics.search(text))

    return has_supplement and has_graphics


def load_question_texts(repo_root: Path) -> dict[str, str]:
    """Read every question once so multi-asset PRs do not rescan the bank repeatedly."""
    return {
        question: read_question_text(repo_root / question)
        for question in all_questions(repo_root)
    }


def questions_referencing_asset(
    repo_root: Path, asset_path: str, question_texts: dict[str, str]
) -> list[str]:
    """Find questions that literally reference one changed support file."""
    matches: list[str] = []
    for question, text in question_texts.items():
        question_path = repo_root / question
        if any(token in text for token in asset_reference_tokens(repo_root, question_path, asset_path)):
            matches.append(question)
    return sorted(matches)


def support_asset_scope(
    repo_root: Path, asset_path: str, question_texts: dict[str, str]
) -> tuple[list[str], bool]:
    """Resolve an asset to dependent questions.

    Returns (questions, exact). If the changed file still exists but no literal
    dependency can be established, exact=False tells the caller to use the legacy
    conservative fallback. Deleted files with no remaining references are exact: no
    current question depends on them anymore.
    """
    matches = questions_referencing_asset(repo_root, asset_path, question_texts)
    if matches:
        return matches, True

    asset = repo_root / Path(*PurePosixPath(asset_path).parts)
    if not asset.exists():
        return [], True

    return [], False


def choose_scope(repo_root: Path, changed_paths: list[str], force_full: bool = False):
    changed = [normalize_changed_path(path) for path in changed_paths]
    changed = [path for path in changed if path]

    if force_full or any(is_global_change(path) for path in changed):
        questions = all_questions(repo_root)
        reason = "full run requested" if force_full else "global CI/test infrastructure changed"
        return "full", questions, reason

    affected: set[str] = set()
    bank_changed = False
    fallback_topics: set[str] = set()
    unresolved_shared_asset = False
    resolved_assets = 0
    question_texts: dict[str, str] | None = None

    for path in changed:
        if not path.startswith("BancoDeQuestoes/"):
            continue

        bank_changed = True
        pure = PurePosixPath(path)
        parts = pure.parts
        if len(parts) < 2:
            continue

        if pure.suffix.lower() == ".rnw":
            candidate = repo_root / Path(*parts)
            # Deleted questions do not need compilation; structural validation still runs.
            if candidate.exists():
                affected.add(pure.as_posix())
            continue

        if question_texts is None:
            question_texts = load_question_texts(repo_root)
        referenced, exact = support_asset_scope(repo_root, pure.as_posix(), question_texts)
        if referenced:
            affected.update(referenced)
            resolved_assets += 1
            continue

        if exact:
            # Usually a deleted/renamed support file that has no remaining references.
            # Any edited question pointing at its replacement is already selected above.
            resolved_assets += 1
            continue

        topic = parts[1]
        if topic == "figuras":
            unresolved_shared_asset = True
        else:
            fallback_topics.add(topic)

    if unresolved_shared_asset:
        questions = all_questions(repo_root)
        return "full", questions, "unresolved shared BancoDeQuestoes/figuras dependency changed"

    for topic in sorted(fallback_topics):
        affected.update(topic_questions(repo_root, topic))

    if affected:
        if fallback_topics:
            reason = (
                "BancoDeQuestoes changes mapped by dependency references; "
                "unresolved assets widened to topic scope"
            )
        elif resolved_assets:
            reason = "BancoDeQuestoes changes mapped to directly dependent questions"
        else:
            reason = "BancoDeQuestoes changes mapped to affected questions"
        return "incremental", sorted(affected), reason

    if bank_changed:
        return "incremental", [], "BancoDeQuestoes changed but no existing question requires compilation"

    return "none", [], "no question or shared compilation dependency changed"


def choose_test_profile(repo_root: Path, changed_paths: list[str], mode: str) -> str:
    """Choose compilation intensity independently from question scope.

    `asset` is deliberately narrow: it is allowed only for an incremental run
    consisting exclusively of static BancoDeQuestoes assets whose consumers can
    be resolved exactly and whose Rnw contains direct static supplement/graphics
    references. Any question source, dynamic support file, unresolved dependency
    or global change keeps the historical full seed profile.
    """
    if mode == "none":
        return "none"
    if mode != "incremental":
        return "full"

    changed = [normalize_changed_path(path) for path in changed_paths]
    bank_changes = [path for path in changed if path.startswith("BancoDeQuestoes/")]
    if not bank_changes:
        return "full"

    question_texts: dict[str, str] | None = None
    for path in bank_changes:
        pure = PurePosixPath(path)
        suffix = pure.suffix.lower()
        if suffix == ".rnw" or suffix not in STATIC_ASSET_SUFFIXES:
            return "full"

        if question_texts is None:
            question_texts = load_question_texts(repo_root)
        referenced, exact = support_asset_scope(repo_root, pure.as_posix(), question_texts)
        # A reduced profile is useful only when there is at least one exact
        # consumer. Unmapped/deleted-unused assets stay conservative (or select
        # no questions anyway).
        if not exact or not referenced:
            return "full"

        # Broad literal matching is sufficient for safe over-selection, but not
        # for reducing seed coverage. Require a direct, static inclusion pattern
        # in every selected consumer before using the reduced profile.
        if any(
            not has_direct_static_asset_reference(
                repo_root, question, pure.as_posix(), question_texts[question]
            )
            for question in referenced
        ):
            return "full"

    return "asset"


def read_changed_files(path: Path) -> list[str]:
    if not path.exists():
        raise FileNotFoundError(f"changed-files list not found: {path}")
    return path.read_text(encoding="utf-8").splitlines()


def write_manifest(path: Path, questions: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = "".join(f"{question}\n" for question in questions)
    path.write_text(text, encoding="utf-8")


def append_github_output(path: Path, mode: str, count: int, reason: str, test_profile: str) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(f"mode={mode}\n")
        handle.write(f"question_count={count}\n")
        handle.write(f"reason={reason}\n")
        handle.write(f"test_profile={test_profile}\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--changed-files")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--github-output")
    parser.add_argument("--full", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    if not args.full and not args.changed_files:
        parser.error("--changed-files is required unless --full is used")

    changed_paths = [] if args.full else read_changed_files(Path(args.changed_files))
    mode, questions, reason = choose_scope(repo_root, changed_paths, force_full=args.full)
    test_profile = choose_test_profile(repo_root, changed_paths, mode)

    write_manifest(Path(args.manifest), questions)
    if args.github_output:
        append_github_output(
            Path(args.github_output), mode, len(questions), reason, test_profile
        )

    print(f"CI test scope: {mode} ({len(questions)} question(s))")
    print(f"Test profile: {test_profile}")
    print(f"Reason: {reason}")
    for question in questions:
        print(question)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
