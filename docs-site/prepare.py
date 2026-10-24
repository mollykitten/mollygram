#!/usr/bin/env python3
"""Stage the documentation sources into build/docs for Zensical.

The Markdown files stay in ../docs, where the README and the packages link to
them. This script copies the published pages next to the site's own content
(home page, styles, favicon) and turns links that leave docs/ (../packages/...)
into GitHub links, so nothing in docs/ has to change.
"""
import re
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
DOCS = HERE.parent / "docs"
CONTENT = HERE / "content"
OUT = HERE / "build" / "docs"
REPO = "https://github.com/mollybyte/mollygram"

PAGES = ["plugins.md", "privacy-store.md", "calls.md", "roadmap.md", "parity.md", "forks-research.md"]
ASSETS = ["icon.svg"]

shutil.rmtree(HERE / "build", ignore_errors=True)
shutil.copytree(CONTENT, OUT)

repo_link = re.compile(r"\]\((?:\.\./)+([^)#\s]+)(#[^)\s]*)?\)")
for name in PAGES:
    text = (DOCS / name).read_text(encoding="utf-8")
    text = repo_link.sub(lambda m: f"]({REPO}/blob/main/{m.group(1)}{m.group(2) or ''})", text)
    (OUT / name).write_text(text, encoding="utf-8")

for name in ASSETS:
    shutil.copy2(DOCS / "assets" / name, OUT / "assets" / name)

print(f"Staged {len(PAGES)} pages into {OUT.relative_to(HERE)}")
