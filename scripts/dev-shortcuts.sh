#!/usr/bin/env bash

PY_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)" || return
export PY_PROJECT_ROOT
PY_PROJECT_SOURCE_DIR="backend"
PY_PROJECT_TESTS_DIR="backend"
export PY_PROJECT_SOURCE_DIR PY_PROJECT_TESTS_DIR

lg() (
    set -o pipefail

    if [[ $# -eq 0 ]]; then
        printf 'Usage: lg command [arguments...]\n' >&2
        return 2
    fi

    mkdir -p -- "$PY_PROJECT_ROOT/tmp" || return

    local log_file
    log_file="$(mktemp "$PY_PROJECT_ROOT/tmp/logrun-$(date +%Y%m%d-%H%M%S)-${1##*/}-XXXXXX.log")" || return

    printf 'Log: %s\n' "$log_file"

    local run_status=0
    "$@" 2>&1 | tee "$log_file" || run_status=$?
    printf '\nExit status: %s\n' "$run_status" | tee -a "$log_file" || return
    return "$run_status"
)

frma() (
    cd "$PY_PROJECT_ROOT" || return
    local project_python="$PY_PROJECT_ROOT/.venv/bin/python"

    "$project_python" -m ruff check --fix --exit-zero . || return
    "$project_python" -m ruff format . || return
    "$project_python" -m ruff check .
)

frmpya() (
    frma || return
    cd "$PY_PROJECT_ROOT" || return
    "$PY_PROJECT_ROOT/.venv/bin/python" -m mypy .
)

_latest_python_file() {
    find "$PWD" -maxdepth 1 -type f -name '*.py' -printf '%T@ %p\n' |
        sort -nr |
        sed -n '1s/^[^ ]* //p'
}

_latest_markdown_file() {
    find "$PWD" -maxdepth 1 -type f -name '*.md' -printf '%T@ %p\n' |
        sort -nr |
        sed -n '1s/^[^ ]* //p'
}


frmal() (
    set -o pipefail
    mkdir -p "$PY_PROJECT_ROOT/tmp" || return
    frma 2>&1 | tee "$PY_PROJECT_ROOT/tmp/frma.log"
)

frmpyal() (
    set -o pipefail
    mkdir -p "$PY_PROJECT_ROOT/tmp" || return
    frmpya 2>&1 | tee "$PY_PROJECT_ROOT/tmp/frmpya.log"
)

frm() (
    local target
    target="${1:-$(_latest_python_file)}"

    if [[ -z "$target" ]]; then
        printf 'No Python files in the current directory.\n'
        return 1
    fi

    target="$(realpath -- "$target")" || return
    local display_path="${target#"$PY_PROJECT_ROOT"/}"
    printf 'Selected: %s/%s\n' "${PY_PROJECT_ROOT##*/}" "$display_path"
    cd "$PY_PROJECT_ROOT" || return
    local project_python="$PY_PROJECT_ROOT/.venv/bin/python"

    "$project_python" -m ruff check --fix --exit-zero "$target" || return
    "$project_python" -m ruff format "$target" || return
    "$project_python" -m ruff check "$target"
)

frmmd() (
    local target
    target="${1:-$(_latest_markdown_file)}"

    if [[ -z "$target" ]]; then
        printf 'No Markdown files in the current directory.\n'
        return 1
    fi

    printf 'Selected: %s\n' "${target#"$PY_PROJECT_ROOT"/}"
    "$PY_PROJECT_ROOT/.venv/bin/rumdl" check --fix -- "$target"
)

frmmda() (
    cd "$PY_PROJECT_ROOT" || return
    "$PY_PROJECT_ROOT/.venv/bin/rumdl" check --fix --respect-gitignore .
)

frmpy() (
    local target
    target="${1:-$(_latest_python_file)}"
    if [[ -z "$target" ]]; then
        printf 'No Python files in the current directory.\n'
        return 1
    fi
    target="$(realpath -- "$target")" || return

    frm "$target" || return
    cd "$PY_PROJECT_ROOT" || return
    "$PY_PROJECT_ROOT/.venv/bin/python" -m mypy "$target"
)


pt() (
    local target
    target="${1:-$(_latest_python_file)}"

    if [[ -z "$target" ]]; then
        printf 'No Python files in the current directory.\n'
        return 1
    fi

    target="$(realpath -- "$target")" || return
    local display_path="${target#"$PY_PROJECT_ROOT"/}"
    printf 'Selected: %s/%s\n' "${PY_PROJECT_ROOT##*/}" "$display_path"
    cd "$PY_PROJECT_ROOT" || return
    "$PY_PROJECT_ROOT/.venv/bin/python" -m pytest -q "$target"
)

pta() (
    cd "$PY_PROJECT_ROOT" || return
    "$PY_PROJECT_ROOT/.venv/bin/python" -m pytest -q
)

ptl() (
    set -o pipefail
    mkdir -p "$PY_PROJECT_ROOT/tmp" || return
    pt 2>&1 | tee "$PY_PROJECT_ROOT/tmp/pytest-latest.log"
)

ptal() (
    set -o pipefail
    mkdir -p "$PY_PROJECT_ROOT/tmp" || return
    pta 2>&1 | tee "$PY_PROJECT_ROOT/tmp/pytest-all.log"
)

cdt() {
    cd "$PY_PROJECT_ROOT/$PY_PROJECT_TESTS_DIR"
}

cdr() {
    cd "$PY_PROJECT_ROOT"
}

cds() {
    cd "$PY_PROJECT_ROOT/$PY_PROJECT_SOURCE_DIR"
}
o() {
    code -r "$@"
}

co() {
    touch -- "$@" || return
    o "$@"
}

sa() {
    source "$PY_PROJECT_ROOT/scripts/dev-shortcuts.sh" || return
    printf 'Reloaded shortcuts from /scripts/dev-shortcuts.sh\n'
}

rml() {
    rm -f -- "${PY_PROJECT_ROOT:?}"/tmp/*.log
}

rmla() {
    find "${PY_PROJECT_ROOT:?}/tmp" -mindepth 1 -maxdepth 1 ! -type d -delete
}

al() {
    cat <<'HELP'
frm     Fix and format the newest Python file in the current directory.
frmpy   Same as frm, then run mypy on that file; accepts an optional filename.
frma    Fix and format Python files recursively under PY_PROJECT_ROOT.
frmal   Same as frma, saving output to tmp/frma.log.
frmpya  Same as frma, then run mypy across the project.
frmpyal Same as frmpya, saving output to tmp/frmpya.log.
frmmd   Fix the newest Markdown file, or a supplied file: frmmd README.md
frmmda  Fix Markdown files across the project, respecting Git exclusions.
pt      Run pytest on the newest Python file, or a supplied test file.
pta     Run the complete project test suite.
ptl     Same as pt, saving output to tmp/pytest-latest.log.
ptal    Same as pta, saving output to tmp/pytest-all.log.
lg      Run a command visibly and save output to a unique log in this project's tmp/.
        Usage: lg command [arguments...], for example: lg git status
        Displays and logs the exit status, preserving failures.
        Runs the command in your current directory.
        Pass a command and its arguments; pipes and redirects belong to Bash.
cdt     Change to the project's tests directory.
cdr     Change to the project root directory.
cds     Change to the configured source directory.
o       Open files in the current VS Code window: o filename
co      Create files (or update their timestamps), then open them: co filename
sa      Reload these shortcuts into the current Bash session.
rml     Delete .log files directly inside this project's tmp/ directory.
rmla    Delete all files, including hidden files, directly inside this project's tmp/.
        Subdirectories and their contents remain.
al      Show this shortcut reference.

Python shortcuts require .venv/bin/python with Ruff, mypy and pytest installed.
Markdown shortcuts require the project's .venv/bin/rumdl.
Fixed log filenames are overwritten on each run; lg creates a unique log.
Loading this file replaces existing functions with the same names in this shell.
HELP
}
