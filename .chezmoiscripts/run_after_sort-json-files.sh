#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0
command -v chezmoi >/dev/null 2>&1 || exit 0

chezmoi managed | while IFS= read -r target; do
  case "$target" in
    *.json) ;;
    *) continue ;;
  esac

  case "$target" in
    /*) file="$target" ;;
    *) file="$HOME/$target" ;;
  esac

  [ -f "$file" ] || continue

  tmp="$(mktemp)"
  if jq -S . "$file" > "$tmp"; then
    if ! cmp -s "$file" "$tmp"; then
      cat "$tmp" > "$file"
    fi
  fi
  rm -f "$tmp"
done
