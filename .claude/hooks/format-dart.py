#!/usr/bin/env python3
"""Format an edited, owned Dart source file with this worktree's pinned SDK."""

import json
import os
from pathlib import Path
import subprocess
import sys


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, TypeError):
        return
    if not isinstance(payload, dict) or not isinstance(payload.get("tool_input"), dict):
        return
    raw_path = payload["tool_input"].get("file_path")
    if not isinstance(raw_path, str) or not raw_path.endswith(".dart"):
        return
    root = Path(os.environ.get("CLAUDE_PROJECT_DIR", Path(__file__).resolve().parents[2])).resolve()
    target = (root / raw_path).resolve()
    try:
        relative = target.relative_to(root)
    except ValueError:
        return
    if not target.is_file() or any(p in {"third_party", "generated", ".dart_tool", "build", ".fvm"}
                                   for p in relative.parts):
        return
    if target.name.endswith((".g.dart", ".freezed.dart")):
        return
    dart = root / ".fvm/flutter_sdk/bin/dart"
    if not dart.is_file():
        print("Dart format skipped: run Superset setup / fvm install for the pinned SDK.", file=sys.stderr)
        return
    try:
        result = subprocess.run([str(dart), "format", str(target)], cwd=root,
                                capture_output=True, text=True, timeout=10)
        if result.returncode:
            print("Dart format failed; run the formatter manually for the edited file.", file=sys.stderr)
    except (OSError, subprocess.TimeoutExpired):
        print("Dart format could not finish; run the formatter manually.", file=sys.stderr)


if __name__ == "__main__":
    main()
