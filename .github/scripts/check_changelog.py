#!/usr/bin/env python3
"""Validate that the PR has a filled-in release note in its template comment.

Skipped when the PR has the `docs-not-needed` label. Otherwise, searches
PR issue comments for the template (anchored on the `### Documentation
checklist` heading) and requires at least one sub-bullet under
`Write a release note` that is non-empty and not the unfilled placeholder.

If `OPENAI_API_KEY` is set, the extracted note is then sent to an LLM for
a quality / format check. The model returns one of:
  - "pass":   silent, exit 0
  - "advise": upsert an advisory PR comment, exit 0
  - "block":  upsert an advisory PR comment, exit 1
If the API key is missing or the call fails, the LLM step is skipped.
"""

import json
import os
import sys
import urllib.error
import urllib.request

from _common import find_release_note, github_request, paginate

DOCS_NOT_NEEDED_LABEL = "docs-not-needed"
ADVISORY_MARKER = "<!-- pre-merge:changelog-advisory -->"
DEFAULT_MODEL = "gpt-5-mini"

SYSTEM_PROMPT = """\
You review release notes for the memgraph/helm-charts repository.

Required format (single line):
  "<short statement of changes> [#<PR number>](<matching PR URL>)"

Example:
  "Added new variables to the Memgraph HA template to enable remote monitoring. \
[#1234](https://github.com/memgraph/helm-charts/pull/1234)"

Rules:
- One short sentence describing the change, ending in a period.
- Immediately followed by a space and the markdown link "[#N](URL)"
  where N is the PR number and URL is the PR's html_url.
- The PR number and URL MUST match the PR provided.
- Humour is fine as long as it's professional and friendly.
- No profanity, slurs, or otherwise rude language.
- Must be meaningful content, not gibberish or leftover placeholder text.

Classify the note as exactly one of:
- "pass":   meets the format and is sensible.
- "advise": minor issues only (typos, grammar, slightly off format, trailing
            whitespace, etc.) -- worth flagging but not worth blocking the PR.
- "block":  severe issues -- profanity, gibberish, missing/wrong PR link,
            empty, or wildly off-format.

Keep "reason" to one or two sentences. If "pass", reason can be empty.
"""


def load_pull_request() -> dict:
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    if event_path and os.path.isfile(event_path):
        with open(event_path, encoding="utf-8") as f:
            return json.load(f).get("pull_request") or {}
    return {}


def has_docs_not_needed(pr: dict) -> bool:
    return DOCS_NOT_NEEDED_LABEL in (label["name"] for label in pr.get("labels", []))


def fetch_comments(pr: dict, token: str) -> list[dict]:
    comments_url = pr.get("comments_url")
    if not comments_url:
        return []
    return [
        {"id": c["id"], "body": c.get("body") or ""}
        for page in paginate(f"{comments_url}?per_page=100", token)
        for c in page
    ]


def evaluate_note(note: str, pr: dict) -> dict | None:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("::warning::OPENAI_API_KEY not set; skipping LLM quality check.")
        return None

    payload = {
        "model": os.environ.get("OPENAI_MODEL", DEFAULT_MODEL),
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"PR number: #{pr.get('number')}\n"
                    f"PR URL: {pr.get('html_url')}\n\n"
                    f"Release note to evaluate:\n{note}"
                ),
            },
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "release_note_verdict",
                "strict": True,
                "schema": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "verdict": {"type": "string", "enum": ["pass", "advise", "block"]},
                        "reason": {"type": "string"},
                    },
                    "required": ["verdict", "reason"],
                },
            },
        },
    }

    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        method="POST",
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
        content = data["choices"][0]["message"]["content"]
        verdict = json.loads(content)
    except (urllib.error.URLError, TimeoutError, KeyError, IndexError, json.JSONDecodeError) as exc:
        print(f"::warning::OpenAI quality check failed ({exc}); skipping.")
        return None

    if verdict.get("verdict") not in {"pass", "advise", "block"}:
        print(f"::warning::Unexpected verdict from model: {verdict!r}; skipping.")
        return None
    return verdict


def upsert_advisory_comment(pr: dict, token: str, body_text: str) -> None:
    full_body = f"{ADVISORY_MARKER}\n{body_text}"
    try:
        existing = next(
            (c for c in fetch_comments(pr, token) if c["body"].startswith(ADVISORY_MARKER)),
            None,
        )
        if existing:
            repo_url = pr["base"]["repo"]["url"]
            url = f"{repo_url}/issues/comments/{existing['id']}"
            with github_request(url, token, method="PATCH", body={"body": full_body}):
                pass
        else:
            with github_request(pr["comments_url"], token, method="POST", body={"body": full_body}):
                pass
    except urllib.error.HTTPError as exc:
        print(f"::warning::Could not upsert advisory comment ({exc}); continuing.")


def format_advisory(verdict: dict, note: str) -> str:
    level = verdict["verdict"]
    header = {
        "advise": "**Release note advisory**",
        "block":  "**Release note blocked**",
    }[level]
    return (
        f"{header}\n\n"
        f"> {note}\n\n"
        f"{verdict.get('reason') or '(no reason provided)'}"
    )


def main() -> int:
    pr = load_pull_request()
    if not pr:
        print("::error::Not running in a pull_request event; cannot load PR.")
        return 1

    if has_docs_not_needed(pr):
        print(f"Skipping release-note check: '{DOCS_NOT_NEEDED_LABEL}' label is set.")
        return 0

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("::error::GITHUB_TOKEN is required to fetch PR comments.")
        return 1

    note = next(
        (n for n in (find_release_note(c["body"]) for c in fetch_comments(pr, token)) if n),
        None,
    )
    if not note:
        print(
            "::error::No release note found. Copy the PR template into a comment and fill in the "
            "'Write a release note' sub-bullet (or add the 'docs-not-needed' label if no note is required)."
        )
        return 1

    print(f"Found release note: {note}")

    verdict = evaluate_note(note, pr)
    if verdict is None or verdict["verdict"] == "pass":
        return 0

    upsert_advisory_comment(pr, token, format_advisory(verdict, note))

    if verdict["verdict"] == "block":
        print(f"::error::Release note blocked by quality check: {verdict.get('reason')}")
        return 1

    print(f"::warning::Release note advisory: {verdict.get('reason')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
