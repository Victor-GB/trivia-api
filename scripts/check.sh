#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$project_root"

# A child Bash retains fail-fast behaviour while the parent records failures.
if [[ "${1:-}" != --internal-run ]]; then
    mkdir -p -- "$project_root/tmp"
    log_file="$(mktemp "$project_root/tmp/check-$(date +%Y%m%d-%H%M%S)-XXXXXX.log")"
    printf 'Log: %s\n' "$log_file"
    run_status=0
    bash "$project_root/scripts/check.sh" --internal-run "$@" 2>&1 | tee "$log_file" || run_status=$?
    printf '\nExit status: %s\n' "$run_status" | tee -a "$log_file"
    exit "$run_status"
fi
shift

if [[ $# -gt 1 || ( "${1:-tooling}" != tooling && "${1:-tooling}" != full ) ]]; then
    printf 'Usage: scripts/check.sh [tooling|full]\n' >&2
    exit 2
fi
check_mode="${1:-tooling}"
project_python="$project_root/.venv/bin/python"
if [[ ! -x "$project_python" ]]; then
    printf 'Create .venv and install requirements-dev.txt first.\n' >&2
    exit 2
fi

printf '\n==> Bash and configuration syntax\n'
bash -n scripts/check.sh
bash -n scripts/dev-shortcuts.sh
bash -n scripts/check-local-agents.sh
"$project_python" -c 'import pathlib,tomllib; tomllib.loads(pathlib.Path("pyproject.toml").read_text()); print("TOML loaded")'
"$project_python" -m pre_commit validate-config
"$project_python" -m ruff check --show-settings pyproject.toml > /dev/null
"$project_python" -m mypy --config-file pyproject.toml /dev/null
"$project_python" -m pytest --version
"$project_python" -m pip check

if [[ -e .git ]]; then
    printf '\n==> Local instruction-file policy\n'
    bash scripts/check-local-agents.sh
else
    printf '\nPENDING: initialise Git and rerun bootstrap for local AGENTS.md exclusion.\n'
fi

printf '\n==> Markdown checks\n'
"$project_root/.venv/bin/rumdl" check --respect-gitignore .

printf '\n==> Dependency vulnerability audit\n'
audit_files=(-r requirements-dev.txt)
if [[ "$check_mode" == full ]]; then
    runtime_requirements="$("$project_python" scripts/runtime-requirements.py)"
    if [[ -n "$runtime_requirements" ]]; then
        audit_files+=(-r "$runtime_requirements")
    fi
fi
"$project_python" -m pip_audit --strict "${audit_files[@]}"

if [[ "$check_mode" == tooling ]]; then
    printf '\nTooling readiness checks passed. Application lint, typing, runtime dependencies, tests and coverage are NOT verified.\n'
    exit 0
fi

printf '\n==> Ruff formatting\n'
"$project_python" -m ruff format --check .
printf '\n==> Ruff linting\n'
"$project_python" -m ruff check .
printf '\n==> Mypy type checking\n'
"$project_python" -m mypy
printf '\n==> Pytest and coverage\n'
"$project_python" -m pytest -q --tb=short
printf '\nFull project checks passed.\n'
