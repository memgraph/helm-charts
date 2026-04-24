#!/usr/bin/env python3
"""Validate that a pull request has the required labels."""

import json
import os
import sys

DOCS_GROUP = ["docs-changelog-only", "docs-needed", "docs-not-needed"]
COMPONENT_GROUP = ["memgraph", "memgraph-ha", "memgraph-lab", "infrastructure"]
TYPE_GROUP = ["bug", "feature", "infrastructure"]


def load_labels() -> list[str]:
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    if event_path and os.path.isfile(event_path):
        with open(event_path, encoding="utf-8") as f:
            event = json.load(f)
        pr = event.get("pull_request") or {}
        return [label["name"] for label in pr.get("labels", [])]

    raw = os.environ.get("PR_LABELS", "")
    return [name.strip() for name in raw.split(",") if name.strip()]


def check_exclusive(labels: list[str], group: list[str], description: str) -> str | None:
    matches = [label for label in group if label in labels]
    if not matches:
        return f"Missing a {description} label. Add exactly one of: {', '.join(group)}."
    if len(matches) > 1:
        return (
            f"Found multiple {description} labels ({', '.join(matches)}). "
            f"Only one of {', '.join(group)} is allowed."
        )
    return None


def check_inclusive(labels: list[str], group: list[str], description: str) -> str | None:
    matches = [label for label in group if label in labels]
    if not matches:
        return f"Missing a {description} label. Add at least one of: {', '.join(group)}."
    return None


def main() -> int:
    labels = load_labels()

    errors = [
        err
        for err in (
            check_exclusive(labels, DOCS_GROUP, "docs"),
            check_inclusive(labels, COMPONENT_GROUP, "component"),
            check_inclusive(labels, TYPE_GROUP, "type"),
        )
        if err
    ]

    if errors:
        for err in errors:
            print(f"::error::{err}")
        return 1

    print(f"Labels on PR: {', '.join(labels) if labels else '(none)'}")
    print("All required label groups satisfied.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
