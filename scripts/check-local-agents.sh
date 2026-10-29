#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_root"
git_root="$(git rev-parse --show-toplevel)"
if [[ "$git_root" != "$project_root" ]]; then
    printf 'Run this check in its own project repository.\n' >&2
    exit 2
fi
if [[ -n "$(git ls-files -- AGENTS.md)" ]]; then
    printf 'AGENTS.md is staged or tracked. Review before publication; an ignore rule does not untrack it.\n' >&2
    exit 1
fi
if ! git check-ignore -q --no-index -- AGENTS.md; then
    printf 'AGENTS.md is not ignored. Rerun bootstrap after reviewing local exclusions.\n' >&2
    exit 1
fi
printf 'Root AGENTS.md is untracked and ignored.\n'
