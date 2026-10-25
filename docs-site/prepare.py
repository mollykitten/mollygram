#!/usr/bin/env python3
"""Stage the site sources into build/docs for Zensical.

The pages are written for the site and live in content/. docs/ holds the
engineering notes and the plugin specification (docs/plugins.md); the site does
not publish them. Only docs/assets (the logo) and the landing's favicon are
copied in, so there is a single source for them.
"""
import json
import os
import re
import shutil
import subprocess
from datetime import date, datetime, timezone
from html import escape
from pathlib import Path

from neon import scene

HERE = Path(__file__).resolve().parent
DOCS = HERE.parent / "docs"
WEBSITE = HERE.parent / "website"
CONTENT = HERE / "content"
MANIFEST = HERE.parent / ".release-please-manifest.json"
REPO = os.environ.get("GITHUB_REPOSITORY", "mollykitten/mollygram")
OUT = HERE / "build" / "docs"



def git(*args):
    try:
        return subprocess.run(
            ["git", *args], cwd=HERE, check=True, capture_output=True, text=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def build_info():
    """Short commit hash, its full hash and the commit date; `dev` without git."""
    full = os.environ.get("GITHUB_SHA") or git("rev-parse", "HEAD")
    if not re.fullmatch(r"[0-9a-f]{7,40}", full):
        return "dev", None, date.today().strftime("%d %b %Y").lstrip("0")
    stamp = git("show", "-s", "--format=%ct", full)
    day = datetime.fromtimestamp(int(stamp), timezone.utc) if stamp.isdigit() else datetime.now(timezone.utc)
    return full[:7], full, f"{day.day} {day:%b %Y}"


def app_version():
    """Version from the release-please manifest, None until the app is released."""
    try:
        version = json.loads(MANIFEST.read_text(encoding="utf-8")).get(".", "")
    except (OSError, ValueError):
        return None
    return version if re.fullmatch(r"\d+\.\d+\.\d+\S*", version) and version != "0.0.0" else None


def footer():
    short, full, day = build_info()
    build = escape(short) if full is None else f'<a href="https://github.com/{REPO}/commit/{full}">{short}</a>'
    version = app_version()
    app = f"App v{escape(version)}" if version else "App not released yet"
    return (
        '<div class="md-copyright__highlight">\n'
        "  Mollygram is open source, GPL-3.0\n"
        f'  <span class="mg-build">{app} · docs build {build} · {day}</span>\n'
        "</div>\n"
    )


shutil.rmtree(HERE / "build", ignore_errors=True)
shutil.copytree(CONTENT, OUT)
shutil.copytree(DOCS / "assets", OUT / "assets", dirs_exist_ok=True)
shutil.copy2(WEBSITE / "public" / "favicon.ico", OUT / "assets" / "favicon.ico")

# The theme override that adds the build line to the footer (theme.custom_dir).
copyright_partial = HERE / "build" / "overrides" / "partials" / "copyright.html"
copyright_partial.parent.mkdir(parents=True)
copyright_partial.write_text(
    '<div class="md-copyright">\n'
    + footer()
    + "{% if not config.extra.generator == false %}\n"
    '  Made with <a href="https://zensical.org/" target="_blank" rel="noopener">Zensical</a>\n'
    "{% endif %}\n"
    "</div>\n",
    encoding="utf-8",
)

index = OUT / "index.md"
index.write_text(index.read_text(encoding="utf-8").replace("<!-- neon-scene -->", scene()), encoding="utf-8")

print(f"Staged the site into {OUT.relative_to(HERE)}")
