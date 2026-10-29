# Development tooling

This tooling comes from the verified Fyyur baseline of 29 October 2026. It does not
establish that the application is implemented or that its runtime dependencies work.

## Environment and shortcuts

Use Python 3.12.3. From this project's root in an Ubuntu Bash terminal:

```bash
source .venv/bin/activate
source scripts/dev-shortcuts.sh
al
```

Create the environment and install the pinned tools with the external bootstrap
toolkit, or with `python -m venv .venv` and then the environment's
`python -m pip install -r requirements-dev.txt`. Activate before using plain `python`.
These instructions do not install application requirements.

The external bootstrap launcher can discover an installed Python even before
`python` is selected by pyenv. During apply it creates `tmp/`, merges development
ignore rules while retaining the existing policy, and optionally creates the branch
named with `--branch`. It writes the selected version to `.python-version`.
After setup, activate the environment and load the shortcuts as shown above.

Load shortcuts in every new shell. `sa` reloads them and displays
`Reloaded shortcuts from /scripts/dev-shortcuts.sh`. Loading another project's
shortcuts changes their target. Check it using `printf '%s\n' "$PY_PROJECT_ROOT"`.
This setup does not modify `.bashrc` or install automatic environment activation.

`frm`, `frmpy` and `pt` accept an explicit filename; otherwise they select the newest
Python file directly in the current directory. `frmmd` behaves similarly for
Markdown. `frma` and `frmmda` work across the project. Formatting commands edit files;
review their diff. `frmpya` is formatting plus typing, not the complete check runner.

## Checks and evidence

```bash
bash scripts/check.sh tooling
```

This validates configuration, executable tools, installed dependency consistency,
Markdown and the development dependency audit. It does not run application imports,
lint the application, or collect tests. Its success is a tooling-readiness result.

When real implementation and meaningful tests exist:

```bash
bash scripts/check.sh full
```

Full mode adds Python formatting, linting, typing, application requirements auditing
from `backend/requirements.txt`, and tests with branch coverage. The selected path
is recorded under `[tool.python-bootstrap]` in `pyproject.toml`. An explicitly
selected file must exist; the default root file is optional when absent. The
checker and CI example read it through `scripts/runtime-requirements.py`. Runtime
dependencies are not installed by bootstrap. No test suite is
created by setup. Pytest exit status 5 remains a failure of full validation.
Requirements-based projects are supported; packaging extras and lockfiles need a
deliberate per-project audit/install policy.

Both check modes create uniquely named `tmp/check-*.log` files, preserving failures.
For other commands use `lg command arguments...`; it logs stdout, stderr and exit
status while running in your current directory. Fixed-name wrappers such as
`frmal` and `ptal` overwrite their respective logs. Preserve milestone evidence.
`rml` deletes logs in this project's `tmp/`; `rmla` deletes all immediate files there.
Neither cleanup helper runs automatically, and both leave subdirectories intact.

## Hooks and local editor settings

Commit hooks use the Fyyur policy: serious Python errors and format checks, basic
validation and whitespace helpers. The helpers can modify files; Ruff does not
automatically fix imports in the hook. The local Markdown hook checks without fixing.
An always-running local hook checks the root `AGENTS.md` exclusion, even for new files.

Full checks are defined for pre-push, but the push hook is not installed by default.
Only after full mode passes, enable it explicitly:

```bash
python -m pre_commit install --hook-type pre-push
python -m pre_commit run full-quality-check --hook-stage pre-push --all-files
```

Optional VS Code settings remain locally ignored. Select `.venv/bin/python` in the
SSH window; a previously selected interpreter may override the default setting.
Ruff and Mypy use the environment strategy. Check their Output logs for the actual
versions; a bundled fallback is not proof the project pin is being used. Markdown
lint settings match the command-line width and indentation policy. Use rumdl for
Markdown formatting so another formatter does not undo the line wrapping policy.

## Local instruction files and publication

Setup adds `/AGENTS.md` to this repository's local Git exclusion file, preserving
existing entries. It never writes instruction content or removes a tracked file.
After initialising Git in a new folder, rerun setup to apply and verify that rule.
The policy covers the root file; decide how to handle nested instruction files.

Before publishing, use an explicit repository name:

```bash
lg python scripts/check-published-agents.py OWNER/REPOSITORY
```

The check reads current GitHub branches and tags for root-file history. It cannot
prove the file was never present on deleted refs, forks or nested paths. It fails
on API/authentication errors; it never comments, changes settings or rewrites history.

## Project choices

The selected source directory is `backend`, test directory `backend` and
coverage target `backend`. Review them when adapting a flat scaffold to a package
layout. If test discovery contains the source directory, coverage excludes test
filenames rather than the entire directory. Review that rule if you use custom test
filename patterns. No coverage threshold is invented. Test docstring rules and strict
Mypy settings retain the Fyyur baseline; adapt them only when the project warrants it.
Python versions other than the validated 3.12.3 require their own compatibility run.
Application-specific dependencies, system packages, migrations and database setup are
separate from this neutral development baseline.
