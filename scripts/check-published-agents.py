#!/usr/bin/env python3
"""Check current GitHub branch/tag history for the root AGENTS.md before publication."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys


def gh(*arguments: str) -> str:
    """Read GitHub data; never create a comment or change repository settings."""
    result = subprocess.run(
        ["gh", *arguments], text=True, capture_output=True, check=False
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "GitHub request failed")
    return result.stdout.strip()


def main() -> int:
    """Report root-file history on every current branch and tag."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", help="Explicit GitHub OWNER/REPOSITORY")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repository):
        parser.error("Expected OWNER/REPOSITORY, not a URL or an inferred remote.")
    try:
        refs = gh(
            "api", "--paginate", f"repos/{args.repository}/git/refs", "--jq", ".[].ref"
        ).splitlines()
        refs = [ref for ref in refs if ref.startswith(("refs/heads/", "refs/tags/"))]
        if not refs:
            print(
                "No published branches or tags found; no history was verified.",
                file=sys.stderr,
            )
            return 2
        found = False
        for ref in refs:
            count = gh(
                "api",
                "--method",
                "GET",
                f"repos/{args.repository}/commits",
                "-f",
                "path=AGENTS.md",
                "-f",
                f"sha={ref}",
                "-f",
                "per_page=1",
                "--jq",
                "length",
            )
            if count not in ("0", "1"):
                raise RuntimeError("Unexpected GitHub history response")
            print(
                f"{ref}: {'FOUND root AGENTS.md history' if count == '1' else 'no root AGENTS.md history'}"
            )
            found |= count == "1"
        print(
            "Scope: current branch/tag history for root AGENTS.md; deleted refs, forks and nested instruction files are not covered."
        )
        return 1 if found else 0
    except (OSError, RuntimeError) as error:
        print(f"Verification failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
