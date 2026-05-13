#!/usr/bin/env python3
"""Populate newly-created GitHub Releases with grouped release notes.

Reads new release tags (one per line) from stdin or argv. For each tag:
  1. Find the previous release tag for the same chart.
  2. Fetch the commits between them via the GitHub compare API.
  3. Extract PR numbers from commit messages.
  4. For each PR with the chart's matching component label, pull its release
     note from its template comment.
  5. Group notes by the primary type label (feature / bug / infrastructure).
  6. `gh release edit <tag> --notes <body>` to replace the release body.

If the chart has no prior release, the new release is left untouched.
"""

import json
import os
import re
import subprocess
import sys
from collections import defaultdict

from _common import find_release_note, github_request, paginate

CHART_LABELS = {
    "memgraph": "memgraph",
    "memgraph-high-availability": "memgraph-ha",
    "memgraph-lab": "memgraph-lab",
}
TYPE_SECTIONS = [
    ("feature", "Features"),
    ("bug", "Bug fixes"),
    ("infrastructure", "Infrastructure"),
]
PR_REF = re.compile(r"\(#(\d+)\)")


def parse_tag(tag: str) -> tuple[str, str] | None:
    for chart in sorted(CHART_LABELS, key=len, reverse=True):
        prefix = f"{chart}-"
        if tag.startswith(prefix):
            return chart, tag[len(prefix):]
    return None


def version_key(version: str) -> tuple[int, ...]:
    parts: list[int] = []
    for p in version.split("."):
        m = re.match(r"\d+", p)
        parts.append(int(m.group()) if m else 0)
    return tuple(parts)


def previous_tag(chart: str, current_version: str, all_tags: list[str]) -> str | None:
    current_key = version_key(current_version)
    prefix = f"{chart}-"
    prior: list[tuple[tuple[int, ...], str]] = []
    for tag in all_tags:
        if not tag.startswith(prefix):
            continue
        v = tag[len(prefix):]
        if v == current_version:
            continue
        key = version_key(v)
        if key < current_key:
            prior.append((key, tag))
    if not prior:
        return None
    prior.sort()
    return prior[-1][1]


def list_all_release_tags() -> list[str]:
    out = subprocess.check_output(
        ["gh", "release", "list", "--limit", "500", "--json", "tagName", "--jq", ".[].tagName"],
        text=True,
    )
    return [line.strip() for line in out.splitlines() if line.strip()]


def commits_between(repo: str, base: str, head: str, token: str) -> list[dict]:
    url = f"https://api.github.com/repos/{repo}/compare/{base}...{head}?per_page=250"
    with github_request(url, token) as resp:
        data = json.loads(resp.read())
    commits = data.get("commits", [])
    if len(commits) == 250:
        print(f"::warning::compare {base}...{head} returned 250 commits; some may be missing.")
    return commits


def extract_pr_numbers(commits: list[dict]) -> list[int]:
    seen: set[int] = set()
    ordered: list[int] = []
    for commit in commits:
        message = commit.get("commit", {}).get("message", "")
        # Only look at the first line (squash-merge PR refs are in the subject).
        subject = message.split("\n", 1)[0]
        for match in PR_REF.finditer(subject):
            n = int(match.group(1))
            if n not in seen:
                seen.add(n)
                ordered.append(n)
    return ordered


def fetch_pr(repo: str, pr_number: int, token: str) -> dict:
    with github_request(f"https://api.github.com/repos/{repo}/pulls/{pr_number}", token) as resp:
        return json.loads(resp.read())


def fetch_pr_comment_bodies(repo: str, pr_number: int, token: str) -> list[str]:
    url = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments?per_page=100"
    return [c.get("body") or "" for page in paginate(url, token) for c in page]


def primary_type(labels: list[str]) -> str | None:
    for label, _ in TYPE_SECTIONS:
        if label in labels:
            return label
    return None


def build_body(grouped: dict[str, list[str]]) -> str:
    out: list[str] = []
    for label, heading in TYPE_SECTIONS:
        items = grouped.get(label)
        if not items:
            continue
        out.append(f"## {heading}")
        out.append("")
        out.extend(f"- {note}" for note in items)
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def process_tag(tag: str, repo: str, token: str, all_tags: list[str]) -> None:
    parsed = parse_tag(tag)
    if not parsed:
        print(f"::warning::Tag '{tag}' does not match any known chart; skipping.")
        return
    chart, version = parsed
    component_label = CHART_LABELS[chart]

    prev = previous_tag(chart, version, all_tags)
    if not prev:
        print(f"No previous release for chart '{chart}'; skipping {tag}.")
        return
    print(f"Processing {tag} (previous: {prev})")

    commits = commits_between(repo, prev, tag, token)
    pr_numbers = extract_pr_numbers(commits)
    print(f"  {len(commits)} commit(s), {len(pr_numbers)} PR(s): {pr_numbers}")

    grouped: dict[str, list[str]] = defaultdict(list)
    for pr_number in pr_numbers:
        pr = fetch_pr(repo, pr_number, token)
        labels = [l["name"] for l in pr.get("labels", [])]
        if component_label not in labels:
            continue
        type_label = primary_type(labels)
        if not type_label:
            print(f"  PR #{pr_number}: no type label; skipping")
            continue
        note = next(
            (n for n in (find_release_note(b) for b in fetch_pr_comment_bodies(repo, pr_number, token)) if n),
            None,
        )
        if not note:
            print(f"  PR #{pr_number}: no release note found; skipping")
            continue
        grouped[type_label].append(note)

    if not any(grouped.values()):
        print(f"  No user-facing notes; leaving {tag} untouched.")
        return

    body = build_body(grouped)
    print(f"  Updating {tag} with:\n{body}")
    subprocess.run(["gh", "release", "edit", tag, "--notes", body], check=True)


def main() -> int:
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        print("::error::GITHUB_TOKEN or GH_TOKEN is required.")
        return 1
    repo = os.environ.get("GITHUB_REPOSITORY")
    if not repo:
        print("::error::GITHUB_REPOSITORY is required.")
        return 1

    tags = sys.argv[1:] if len(sys.argv) > 1 else [l.strip() for l in sys.stdin if l.strip()]
    if not tags:
        print("No new release tags given; nothing to do.")
        return 0

    all_tags = list_all_release_tags()
    for tag in tags:
        process_tag(tag, repo, token, all_tags)
    return 0


if __name__ == "__main__":
    sys.exit(main())
