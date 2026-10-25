#!/bin/sh
# ACP chat roles; run from any directory inside this checkout.
set -eu
exec python3 "$(dirname "$0")/agents.py" "$@"
