# docs-site

Public documentation for mollygram, built with [Zensical](https://zensical.org) and published at **docs.mollygram.dev**.

The texts stay where they are, in [`docs/`](../docs): the README and the packages link to them there. This folder holds only the site config, the home page and the theme.

## Layout

| Path | What it is |
|---|---|
| `zensical.toml` | Site config: navigation, theme, palette, Markdown extensions |
| `requirements.txt` | Zensical, pinned to an exact version |
| `prepare.py` | Stages `docs/` (pages and all of `docs/assets/`), `content/` and the favicon into `build/docs` (git-ignored) |
| `content/` | Home page, `stylesheets/extra.css`, `_headers` (noindex on `*.pages.dev` previews) |

`prepare.py` copies the published pages and rewrites links that leave `docs/` (`../packages/...`) into GitHub links, so no file in `docs/` has to change. Fonts, accent colors and the light/dark palette follow `website/src/site.css`; the logo is `docs/assets/icon.svg`, the favicon is `website/public/favicon.ico`, copied by `prepare.py`.

## Published pages

- **Product:** `plugins.md`, `privacy-store.md`, `calls.md`, `roadmap.md`.
- **For developers:** `parity.md`, `forks-research.md`. They are internal working notes, but `roadmap.md` links to both, so they are published in a separate section instead of leaving broken links. To hide them, remove them from `PAGES` in `prepare.py` and from `nav` in `zensical.toml`, and edit the two links in `roadmap.md`.

To add a page, put it in `docs/`, add it to `PAGES` in `prepare.py` and to `nav` in `zensical.toml`.

## Build and preview locally

```bash
cd docs-site
python3 -m venv .venv && source .venv/bin/activate   # or: uv venv && source .venv/bin/activate
pip install -r requirements.txt
python prepare.py
zensical serve          # http://localhost:8000
zensical build --strict # writes site/, fails on warnings
```

`zensical serve` does not watch `docs/`: run `python prepare.py` again after editing the texts. A changed `zensical.toml` or `content/` needs `prepare.py` as well.

## Deploy

`.github/workflows/docs.yml` builds with `--strict` and deploys to the Cloudflare Pages project `mollygram-docs`: production from `main`, a preview for every pull request. It runs on changes to `docs/**`, `docs-site/**` and the workflow. It uses the same secrets as the website workflow (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`); without them the site is only built. The first run creates the Pages project.

### Manual step: the domain

The workflow does not touch DNS. Once the project exists, in the Cloudflare dashboard open **Workers & Pages → mollygram-docs → Custom domains → Set up a custom domain** and add `docs.mollygram.dev`. Cloudflare creates the CNAME if the zone lives in the same account.
