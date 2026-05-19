#!/usr/bin/env bash

_tool_list() {
  local pkgs_dir="${BASH_SETUP_DIR}/pkgs.d"
  local pkg

  echo "Available Primary Packages:"

  # Check if directory exists and has files
  if [[ -d "$pkgs_dir" ]]; then
    for pkg in "$pkgs_dir"/*.sh; do
      [[ -f "$pkg" ]] || continue
      # Print the filename without the .sh extension
      basename "$pkg" .sh | awk '{print "  - " $0}'
    done
  else
    echo "  (No packages directory found)"
  fi

  echo ""
  echo "To install sub-packages (formatters/linters), edit:"
  echo "  ~/.config/bash_setup/global_tools.conf"
}
