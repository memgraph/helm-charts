#!/usr/bin/env python3
"""Dry-run the release-notes generator over a date range.

Usage:
    python .github/scripts/test_release_notes.py <since> <until>

Dates are ISO-8601; "YYYY-MM-DD" is accepted and promoted to midnight UTC.

Example:
    python .github/scripts/test_release_notes.py 2026-01-01 2026-04-01

Prints the release-notes body that would be produced for each chart over the
given range, without touching any releases on GitHub.

Auth resolution order: GITHUB_TOKEN, GH_TOKEN, then `gh auth token`.
Repo resolution: GITHUB_REPOSITORY env var, else defaults to "memgraph/helm-charts".
"""

import os
import subprocess
import sys
from collections import defaultdict

from _common import find_release_note, paginate
from update_release_notes import (
    CHART_LABELS,
    build_body,
    extract_pr_numbers,
    fetch_pr,
    fetch_pr_comment_bodies,
    primary_type,
)


def commits_in_range(repo: str, since: str, until: str, token: str) -> list[dict]:
    url = (
        f"https://api.github.com/repos/{repo}/commits"
        f"?since={since}&until={until}&per_page=100"
    )
    return [commit for page in paginate(url, token) for commit in page]


def normalize_date(value: str) -> str:
    if len(value) == 10 and value.count("-") == 2:
        return f"{value}T00:00:00Z"
    return value


def resolve_token() -> str | None:
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        return token
    try:
        return subprocess.check_output(["gh", "auth", "token"], text=True).strip()
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    since = normalize_date(sys.argv[1])
    until = normalize_date(sys.argv[2])

    token = resolve_token()
    if not token:
        print("error: no token available (set GITHUB_TOKEN or run `gh auth login`).", file=sys.stderr)
        return 1
    repo = os.environ.get("GITHUB_REPOSITORY") or "memgraph/helm-charts"

    print(f"Fetching commits on default branch in {repo} between {since} and {until}...", file=sys.stderr)
    commits = commits_in_range(repo, since, until, token)
    pr_numbers = extract_pr_numbers(commits)
    print(f"{len(commits)} commit(s), {len(pr_numbers)} unique PR(s): {pr_numbers}", file=sys.stderr)

    prs: dict[int, dict] = {}
    notes: dict[int, str | None] = {}
    for pr_number in pr_numbers:
        prs[pr_number] = fetch_pr(repo, pr_number, token)
        notes[pr_number] = next(
            (n for n in (find_release_note(b) for b in fetch_pr_comment_bodies(repo, pr_number, token)) if n),
            None,
        )

    for chart, component_label in CHART_LABELS.items():
        grouped: dict[str, list[str]] = defaultdict(list)
        for pr_number in pr_numbers:
            labels = [l["name"] for l in prs[pr_number].get("labels", [])]
            if component_label not in labels:
                continue
            type_label = primary_type(labels)
            if not type_label or not notes[pr_number]:
                continue
            grouped[type_label].append(notes[pr_number])

        print()
        print(f"===== {chart} =====")
        if not any(grouped.values()):
            print("(no user-facing notes in this range)")
            continue
        print(build_body(grouped), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
