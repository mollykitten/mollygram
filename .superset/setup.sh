#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
workspace_root="$PWD"

# Worktrees do not contain ignored local configuration. Never replace a
# workspace's own values, and never print secret contents in the setup log.
if [[ -n "${SUPERSET_ROOT_PATH:-}" && -d "$SUPERSET_ROOT_PATH" ]]; then
  source_root="$(cd "$SUPERSET_ROOT_PATH" && pwd -P)"
  if [[ "$source_root" != "$(pwd -P)" ]]; then
    shopt -s nullglob dotglob
    for directory in . website packages/app; do
      for source in "$source_root/$directory"/.env "$source_root/$directory"/.env.* "$source_root/$directory"/*.env; do
        [[ -f "$source" ]] || continue
        relative="${source#"$source_root/"}"
        # Only local, ignored files need transferring; tracked examples are
        # already present in the worktree.
        git -C "$source_root" check-ignore -q -- "$relative" || continue
        destination="$workspace_root/$relative"
        if [[ ! -e "$destination" && ! -L "$destination" ]]; then
          mkdir -p "$(dirname "$destination")"
          cp -p "$source" "$destination"
          printf 'Copied local configuration: %s\n' "$relative"
        fi
      done
    done
    if [[ -f "$source_root/config/telegram.json" && ! -e config/telegram.json && ! -L config/telegram.json ]]; then
      mkdir -p config
      cp -p "$source_root/config/telegram.json" config/telegram.json
      printf 'Copied local configuration: config/telegram.json\n'
    fi
  fi
fi

command -v fvm >/dev/null || { printf 'Install FVM before running workspace setup.\n' >&2; exit 1; }
command -v node >/dev/null || { printf 'Install Node.js 22 or newer for the website preview.\n' >&2; exit 1; }
command -v python3 >/dev/null || { printf 'Install Python 3 for the website preview.\n' >&2; exit 1; }
node -e 'if (Number(process.versions.node.split(".")[0]) < 22) { console.error("Node.js 22 or newer is required."); process.exit(1); }'

git submodule update --init --recursive
fvm install
fvm flutter pub get

# website/package.json has no dependencies; its build needs only Node.js.
node website/build.mjs
printf 'Workspace ready. Run starts the website preview; Flutter desktop is launched separately.\n'
