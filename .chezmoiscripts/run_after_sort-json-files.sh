#!/usr/bin/env bash
set -euo pipefail

command -v biome >/dev/null 2>&1 || exit 0
command -v chezmoi >/dev/null 2>&1 || exit 0

source_dir="$(chezmoi source-path)"

# format + sort keys; tolerates JSONC (comments, trailing commas) in .json files.
# flags mirror the repo's biome.json so sources and targets converge on the same
# canonical form and apply stays quiet.
biome_fmt() { # usage: biome_fmt <file> [extra biome flags...]
  local file="$1"
  shift
  local out
  if ! out="$(biome check --write \
    --json-parse-allow-comments=true \
    --json-parse-allow-trailing-commas=true \
    --linter-enabled=false \
    --indent-style=space --indent-width=2 \
    --only=assist/source/useSortedKeys \
    "$@" "$file" 2>&1)"; then
    printf '%s\n' "$out" >&2
  fi
}

chezmoi managed | while IFS= read -r target; do
  case "$target" in
    *.json) ;;
    *) continue ;;
  esac

  case "$target" in
    /*) file="$target" ;;
    *) file="$HOME/$target" ;;
  esac

  # Zed writes JSONC with trailing commas; keep them (matches the biome.json override)
  extra=""
  case "$target" in
    .config/zed/settings.json) extra="--json-formatter-trailing-commas=all" ;;
  esac

  # $extra intentionally unquoted: empty for most files, a single flag otherwise
  [ -f "$file" ] && biome_fmt "$file" $extra

  # format the source too; run from the repo so its biome.json is the config root
  src="$(chezmoi source-path "$file" 2>/dev/null || true)"
  case "$src" in
    *.json) [ -f "$src" ] && (cd "$source_dir" && biome_fmt "$src" $extra) ;;
  esac
done
