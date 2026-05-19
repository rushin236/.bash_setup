#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/bash_setup"
CACHE_FILE="$CACHE_DIR/carapace.sh"

mkdir -p "$CACHE_DIR"

if [[ ! -f "$CACHE_FILE" ]]; then
  command -v carapace >/dev/null && carapace _carapace >"$CACHE_FILE"
fi

[[ -f "$CACHE_FILE" ]] && source "$CACHE_FILE"
