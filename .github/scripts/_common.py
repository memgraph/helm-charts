"""Shared helpers for pre-merge and post-release scripts."""

import json
import re
import urllib.request

TEMPLATE_ANCHOR = "### Documentation checklist"
RELEASE_NOTE_HEADING = re.compile(r"^\s*-\s*\[.\]\s*Write a release note\b", re.IGNORECASE)
PLACEHOLDER_TEXT = (
    "What has changed? What does it mean for a user? What should a user do with it? "
    "[#{{PR_number}}]({{link to the PR}})"
)
LIST_MARKER = re.compile(r"^[-*]\s*(\[.\]\s*)?")


def github_request(url: str, token: str, *, method: str = "GET", body: dict | None = None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url,
        method=method,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    return urllib.request.urlopen(req)


def next_page_url(link_header: str) -> str | None:
    for part in link_header.split(","):
        m = re.search(r"<([^>]+)>\s*;\s*rel=\"next\"", part)
        if m:
            return m.group(1)
    return None


def paginate(url: str, token: str):
    while url:
        with github_request(url, token) as resp:
            yield json.loads(resp.read())
            link = resp.headers.get("Link", "")
        url = next_page_url(link)


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
        if not line.startswith((" ", "\t")):
            break
        content = LIST_MARKER.sub("", stripped).strip()
        if not content or content == PLACEHOLDER_TEXT:
            continue
        return content
    return None
