#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
node website/build.mjs

# Bind port 0 atomically: the OS selects an available port even when several
# workspaces start together. Python prints the actual port in the Run pane.
# Keep the server attached so Superset can stop/restart it with the pane.
exec python3 -u -m http.server 0 --bind 127.0.0.1 --directory website/dist
