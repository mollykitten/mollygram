#!/usr/bin/env python3
"""Stage the site sources into build/docs for Zensical.

The pages are written for the site and live in content/. docs/ holds the
engineering notes and the plugin specification (docs/plugins.md); the site does
not publish them. Only docs/assets (the logo) and the landing's favicon are
copied in, so there is a single source for them.
"""
import shutil
from pathlib import Path

from neon import scene

HERE = Path(__file__).resolve().parent
DOCS = HERE.parent / "docs"
WEBSITE = HERE.parent / "website"
CONTENT = HERE / "content"
OUT = HERE / "build" / "docs"

shutil.rmtree(HERE / "build", ignore_errors=True)
shutil.copytree(CONTENT, OUT)
shutil.copytree(DOCS / "assets", OUT / "assets", dirs_exist_ok=True)
shutil.copy2(WEBSITE / "public" / "favicon.ico", OUT / "assets" / "favicon.ico")

index = OUT / "index.md"
index.write_text(index.read_text(encoding="utf-8").replace("<!-- neon-scene -->", scene()), encoding="utf-8")

print(f"Staged the site into {OUT.relative_to(HERE)}")
