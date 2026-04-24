#!/usr/bin/env python3
"""Validate that the PR has a filled-in release note in its template comment.

Skipped when the PR has the `docs-not-needed` label. Otherwise, searches
PR issue comments for the template (anchored on the `### Documentation
checklist` heading) and requires at least one sub-bullet under
`Write a release note` that is non-empty and not the unfilled placeholder.
"""

import json
import os
import re
import sys
import urllib.request

DOCS_NOT_NEEDED_LABEL = "docs-not-needed"
TEMPLATE_ANCHOR = "### Documentation checklist"
RELEASE_NOTE_HEADING = re.compile(r"^\s*-\s*\[.\]\s*Write a release note\b", re.IGNORECASE)
PLACEHOLDER_TEXT = (
    "What has changed? What does it mean for a user? What should a user do with it? "
    "[#{{PR_number}}]({{link to the PR}})"
)
LIST_MARKER = re.compile(r"^[-*]\s*(\[.\]\s*)?")


def load_pull_request() -> dict:
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    if event_path and os.path.isfile(event_path):
        with open(event_path, encoding="utf-8") as f:
            return json.load(f).get("pull_request") or {}
    return {}


def has_docs_not_needed(pr: dict) -> bool:
    return DOCS_NOT_NEEDED_LABEL in (label["name"] for label in pr.get("labels", []))


def fetch_comment_bodies(pr: dict) -> list[str]:
    comments_url = pr.get("comments_url")
    if not comments_url:
        return []
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("::error::GITHUB_TOKEN is required to fetch PR comments.")
        sys.exit(1)

    bodies: list[str] = []
    url: str | None = f"{comments_url}?per_page=100"
    while url:
        req = urllib.request.Request(
            url,
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
            },
        )
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            link = resp.headers.get("Link", "")
        bodies.extend(c.get("body") or "" for c in data)
        url = next_page_url(link)
    return bodies


def next_page_url(link_header: str) -> str | None:
    for part in link_header.split(","):
        m = re.search(r"<([^>]+)>\s*;\s*rel=\"next\"", part)
        if m:
            return m.group(1)
    return None


def find_release_note(body: str) -> str | None:
    if TEMPLATE_ANCHOR not in body:
        return None

    lines = body.splitlines()
    try:
        heading_idx = next(i for i, line in enumerate(lines) if RELEASE_NOTE_HEADING.match(line))
    except StopIteration:
        return None

    for line in lines[heading_idx + 1:]:
        stripped = line.strip()
        if not stripped:
            continue
        # A non-indented non-empty line means we've left the release-note section.
        if not line.startswith((" ", "\t")):
            break
        content = LIST_MARKER.sub("", stripped).strip()
        if not content or content == PLACEHOLDER_TEXT:
            continue
        return content
    return None


def main() -> int:
    pr = load_pull_request()
    if not pr:
        print("::error::Not running in a pull_request event; cannot load PR.")
        return 1

    if has_docs_not_needed(pr):
        print(f"Skipping release-note check: '{DOCS_NOT_NEEDED_LABEL}' label is set.")
        return 0

    for body in fetch_comment_bodies(pr):
        note = find_release_note(body)
        if note:
            print("Found release note in PR comment:")
            print(f"  {note}")
            return 0

    print(
        "::error::No release note found. Copy the PR template into a comment and fill in the "
        "'Write a release note' sub-bullet (or add the 'docs-not-needed' label if no note is required)."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
