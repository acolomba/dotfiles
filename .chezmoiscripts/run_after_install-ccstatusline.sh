#!/usr/bin/env bash
set -euo pipefail

command -v npm >/dev/null 2>&1 || exit 0

# global install so the claude code status line skips npx resolution on every repaint
npm install -g --silent ccstatusline@latest
