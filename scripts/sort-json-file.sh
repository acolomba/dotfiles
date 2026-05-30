#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  exit 0
fi

status=0

for file in "$@"; do
  [ -f "$file" ] || continue

  tmp="$(mktemp)"
  if jq -S . "$file" > "$tmp"; then
    if ! cmp -s "$file" "$tmp"; then
      cat "$tmp" > "$file"
      echo "sort-json-files: sorted $file" >&2
      status=1
    fi
  else
    echo "sort-json-files: failed to parse $file" >&2
    status=1
  fi
  rm -f "$tmp"
done

exit "$status"
