#!/usr/bin/env bash
# bash_setup.sh - Main entry point

export BASH_SETUP_DIR="$HOME/.bash_setup"

# 1. Load internal libraries
source "$BASH_SETUP_DIR/lib/utils.sh"
source "$BASH_SETUP_DIR/lib/completion.sh"
source "$BASH_SETUP_DIR/lib/engine.sh"

# 2. Source environment scripts (your 'env sourcing' loop)
if [[ -d "$BASH_SETUP_DIR/env.d" ]]; then
  for file in "$BASH_SETUP_DIR/env.d"/*.sh; do
    [[ -f "$file" ]] && source "$file"
  done
fi

# 3. Source runtime pluginrc scripts (your 'installed tools' loop)
if [[ -d "$BASH_SETUP_DIR/pkgs.rc.d" ]]; then
  for file in "$BASH_SETUP_DIR/pkgs.rc.d"/*.sh; do
    [[ -f "$file" ]] && source "$file"
  done
fi

# 3. Register autocompletion
complete -F _tool_completions tool
