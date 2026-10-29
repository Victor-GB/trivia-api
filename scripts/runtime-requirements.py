#!/usr/bin/env python3
"""Read the runtime requirements selected for local checks and CI."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path


def main() -> int:
    """Print the selected existing path, or fail when a required path is unavailable."""
    root = Path(__file__).resolve().parents[1]
    try:
        config = tomllib.loads((root / "pyproject.toml").read_text(encoding="utf-8"))
        settings = config.get("tool", {}).get("python-bootstrap", {})
        if not isinstance(settings, dict):
            raise ValueError("[tool.python-bootstrap] must be a table")
        value = settings.get("runtime-requirements", "requirements.txt")
        required = settings.get("runtime-requirements-required", False)
        if not isinstance(value, str) or not re.fullmatch(r"[\w./-]+", value):
            raise ValueError("Runtime requirements must be a project-relative path")
        if not isinstance(required, bool):
            raise ValueError("runtime-requirements-required must be true or false")
        relative = Path(value)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Runtime requirements cannot escape the project")
        path = root / relative
        for component in (path, *path.parents):
            if component == root:
                break
            if component.is_symlink():
                raise ValueError("Runtime requirements cannot use symbolic links")
        if path.exists() and not path.is_file():
            raise ValueError(f"Runtime requirements is not a file: {value}")
        if not path.is_file():
            if required:
                raise ValueError(
                    f"Required runtime requirements file is missing: {value}"
                )
            return 0
        print(relative.as_posix())
        return 0
    except (OSError, ValueError, TypeError) as error:
        print(f"Runtime requirements configuration error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
