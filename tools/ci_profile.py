#!/usr/bin/env python3
"""Collect GitHub Actions step timings for the current BancoFisica CI job.

The profiler uses only the GitHub Actions API and Python's standard library.
It is intentionally observational: it does not alter test execution and can run
with ``if: always()`` at the end of a job.
"""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


CATEGORY_BY_STEP = {
    "Checkout repository": "checkout",
    "Detect affected questions": "scope",
    "Report CI scope": "scope",
    "Validate public demo site data": "site",
    "Install system tools and LaTeX": "setup",
    "Setup R": "setup",
    "Install R dependencies": "setup",
    "Run BancoFisica tests": "tests",
    "Audit solution blocks": "audit/report",
    "Generate quality report": "audit/report",
    "Generate teaching audit": "audit/report",
    "Upload quality report": "artifact",
}


def parse_time(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def seconds_between(started_at: str | None, completed_at: str | None) -> float | None:
    start = parse_time(started_at)
    end = parse_time(completed_at)
    if start is None or end is None:
        return None
    return max(0.0, (end - start).total_seconds())


def fetch_jobs(api_url: str, repository: str, run_id: str, token: str) -> dict[str, Any]:
    url = f"{api_url}/repos/{repository}/actions/runs/{run_id}/jobs?per_page=100"
    req = Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "BancoFisica-CI-profiler",
        },
    )
    with urlopen(req, timeout=30) as response:
        return json.load(response)


def select_job(payload: dict[str, Any], job_key: str) -> dict[str, Any]:
    jobs = payload.get("jobs", [])
    if not jobs:
        raise RuntimeError("GitHub API returned no jobs for this workflow run")

    exact = [job for job in jobs if job.get("name") == job_key]
    if len(exact) == 1:
        return exact[0]

    # Matrix/display names may differ from GITHUB_JOB. Prefer the currently
    # running job; this workflow presently has a single job, so this is a safe
    # fallback and remains conservative if more jobs are added later.
    active = [job for job in jobs if job.get("status") == "in_progress"]
    if len(active) == 1:
        return active[0]
    if len(jobs) == 1:
        return jobs[0]

    names = ", ".join(str(job.get("name")) for job in jobs)
    raise RuntimeError(f"Could not identify current job {job_key!r}; candidates: {names}")


def build_profile(job: dict[str, Any]) -> dict[str, Any]:
    steps: list[dict[str, Any]] = []
    category_seconds: dict[str, float] = {}

    for step in job.get("steps", []):
        duration = seconds_between(step.get("started_at"), step.get("completed_at"))
        # The profiler step itself is still running when the API is queried.
        # Keep incomplete steps out of the timing totals rather than guessing.
        if duration is None:
            continue

        name = str(step.get("name", "unnamed"))
        category = CATEGORY_BY_STEP.get(name, "other")
        category_seconds[category] = category_seconds.get(category, 0.0) + duration
        steps.append(
            {
                "name": name,
                "category": category,
                "status": step.get("status"),
                "conclusion": step.get("conclusion"),
                "started_at": step.get("started_at"),
                "completed_at": step.get("completed_at"),
                "seconds": duration,
            }
        )

    completed_starts = [parse_time(step["started_at"]) for step in steps]
    completed_ends = [parse_time(step["completed_at"]) for step in steps]
    completed_starts = [value for value in completed_starts if value is not None]
    completed_ends = [value for value in completed_ends if value is not None]
    observed_wall_seconds = 0.0
    if completed_starts and completed_ends:
        observed_wall_seconds = (max(completed_ends) - min(completed_starts)).total_seconds()

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "repository": os.getenv("GITHUB_REPOSITORY", ""),
        "run_id": os.getenv("GITHUB_RUN_ID", ""),
        "run_attempt": os.getenv("GITHUB_RUN_ATTEMPT", ""),
        "event_name": os.getenv("GITHUB_EVENT_NAME", ""),
        "ref": os.getenv("GITHUB_REF", ""),
        "sha": os.getenv("GITHUB_SHA", ""),
        "job_name": job.get("name"),
        "job_id": job.get("id"),
        "job_status": job.get("status"),
        "job_conclusion": job.get("conclusion"),
        "scope_mode": os.getenv("BANK_PROFILE_MODE", ""),
        "question_count": os.getenv("BANK_PROFILE_QUESTION_COUNT", ""),
        "scope_reason": os.getenv("BANK_PROFILE_REASON", ""),
        "observed_wall_seconds": observed_wall_seconds,
        "category_seconds": dict(sorted(category_seconds.items())),
        "steps": steps,
    }


def fmt_seconds(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.1f} s"
    minutes, secs = divmod(seconds, 60)
    if minutes < 60:
        return f"{int(minutes)}m {secs:04.1f}s"
    hours, minutes = divmod(int(minutes), 60)
    return f"{hours}h {minutes:02d}m {secs:04.1f}s"


def append_summary(path: Path, profile: dict[str, Any]) -> None:
    categories = profile["category_seconds"]
    total_known = sum(categories.values())
    setup = float(categories.get("setup", 0.0))
    tests = float(categories.get("tests", 0.0))

    with path.open("a", encoding="utf-8") as handle:
        handle.write("\n### CI performance profile\n\n")
        handle.write(f"- Scope: **{profile['scope_mode'] or 'unknown'}**\n")
        handle.write(f"- Questions selected: **{profile['question_count'] or 'unknown'}**\n")
        if profile.get("scope_reason"):
            handle.write(f"- Scope reason: {profile['scope_reason']}\n")
        handle.write(f"- Observed wall time: **{fmt_seconds(profile['observed_wall_seconds'])}**\n")
        handle.write(f"- Completed-step time: **{fmt_seconds(total_known)}**\n")
        if total_known > 0:
            handle.write(f"- Setup share: **{100.0 * setup / total_known:.1f}%** ({fmt_seconds(setup)})\n")
            handle.write(f"- BancoFisica test share: **{100.0 * tests / total_known:.1f}%** ({fmt_seconds(tests)})\n")

        handle.write("\n#### By category\n\n")
        handle.write("| Category | Time | Share |\n|---|---:|---:|\n")
        for category, seconds in sorted(categories.items(), key=lambda item: item[1], reverse=True):
            share = 100.0 * seconds / total_known if total_known else 0.0
            handle.write(f"| {category} | {fmt_seconds(seconds)} | {share:.1f}% |\n")

        handle.write("\n<details><summary>Step timings</summary>\n\n")
        handle.write("| Step | Category | Conclusion | Time |\n|---|---|---|---:|\n")
        for step in profile["steps"]:
            handle.write(
                f"| {step['name']} | {step['category']} | {step['conclusion'] or step['status']} | "
                f"{fmt_seconds(step['seconds'])} |\n"
            )
        handle.write("\n</details>\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="build/ci-profile.json")
    parser.add_argument("--summary", default=os.getenv("GITHUB_STEP_SUMMARY", ""))
    parser.add_argument(
        "--jobs-json",
        help="Read a saved GitHub jobs API response instead of calling the API (for local testing)",
    )
    args = parser.parse_args()

    try:
        if args.jobs_json:
            payload = json.loads(Path(args.jobs_json).read_text(encoding="utf-8"))
        else:
            token = os.getenv("GITHUB_TOKEN", "")
            repository = os.getenv("GITHUB_REPOSITORY", "")
            run_id = os.getenv("GITHUB_RUN_ID", "")
            api_url = os.getenv("GITHUB_API_URL", "https://api.github.com")
            if not token or not repository or not run_id:
                raise RuntimeError("GITHUB_TOKEN, GITHUB_REPOSITORY and GITHUB_RUN_ID are required")
            payload = fetch_jobs(api_url, repository, run_id, token)

        job = select_job(payload, os.getenv("GITHUB_JOB", "test"))
        profile = build_profile(job)

        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(profile, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

        if args.summary:
            append_summary(Path(args.summary), profile)

        print(f"CI profile written to {out}")
        for category, seconds in sorted(profile["category_seconds"].items(), key=lambda item: item[1], reverse=True):
            print(f"  {category:14s} {fmt_seconds(seconds)}")
        return 0
    except (RuntimeError, HTTPError, URLError, OSError, ValueError) as exc:
        # Profiling must never turn a valid test run red. The baseline is
        # diagnostic data, not a correctness gate.
        print(f"warning: could not collect CI profile: {exc}")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
