# docs-site

Public documentation for mollygram, built with [Zensical](https://zensical.org) and published at **docs.mollygram.dev**.

Public documentation site config, pages and theme. The engineering notes in [`docs/`](../docs) stay where they are and are not published.

## Layout

| Path | What it is |
|---|---|
| `zensical.toml` | Site config: navigation, theme, palette, Markdown extensions |
| `requirements.txt` | Zensical, pinned to an exact version |
| `prepare.py` | Stages `content/`, `docs/assets/` and the favicon into `build/docs` (git-ignored) |
| `content/` | Pages,  `stylesheets/extra.css`, `_headers` (noindex on `*.pages.dev` previews) |

Fonts, accent colors and the light/dark palette follow `website/src/site.css`; the logo is `docs/assets/icon.svg`, the favicon is `website/public/favicon.ico`, copied by `prepare.py`.

## Where the pages come from

The pages are written for the site and live in `content/`, in four sections: Start, Using Mollygram, Plugin authors, Project. Only English for now.

[`docs/`](../docs) holds the engineering notes and the plugin specification. The site does not publish it: `docs/plugins.md` is the spec, the site is the guide, and where they disagree the code wins. Facts on the pages come from the code (`packages/shell`, `packages/app`, `packages/core`, `packages/plugin_host`, `packages/plugin_sdk`), so describe only what the app does today, and put plans on the "What's next" page.

To add a page, put it in `content/` and add it to `nav` in `zensical.toml`.

## Build and preview locally

```bash
cd docs-site
python3 -m venv .venv && source .venv/bin/activate   # or: uv venv && source .venv/bin/activate
pip install -r requirements.txt
python prepare.py
zensical serve          # http://localhost:8000
zensical build --strict # writes site/, fails on warnings
```

`zensical serve` does not watch `content/`: run `python prepare.py` again after editing a page.

## Deploy

`.github/workflows/docs.yml` builds with `--strict` and deploys to the Cloudflare Pages project `mollygram-docs`: production from `main`, a preview for every pull request. It runs on changes to `docs/assets/**`, `docs-site/**` and the workflow. It uses the same secrets as the website workflow (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`); without them the site is only built. The first run creates the Pages project.

### Manual step: the domain

The workflow does not touch DNS. Once the project exists, in the Cloudflare dashboard open **Workers & Pages → mollygram-docs → Custom domains → Set up a custom domain** and add `docs.mollygram.dev`. Cloudflare creates the CNAME if the zone lives in the same account.
