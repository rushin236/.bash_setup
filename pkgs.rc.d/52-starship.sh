#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/bash_setup"
CACHE_FILE="$CACHE_DIR/starship.sh"

# Ensure the cache directory exists (safeguard)
mkdir -p "$CACHE_DIR"

# Only run the heavy binary if the cache file is missing
if [[ ! -f "$CACHE_FILE" ]]; then
  command -v starship >/dev/null && starship init bash >"$CACHE_FILE"
fi

# Instantly read the static text file
[[ -f "$CACHE_FILE" ]] && source "$CACHE_FILE"
