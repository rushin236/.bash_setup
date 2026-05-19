#!/usr/bin/env bash

_tool_pkg() {
  local action="$1"
  local arg pkg run_all=0

  shift

  local usage="Usage: tool pkg {install|update|remove} <name1> [name2...] [all]"

  case "$action" in
    install | update | remove)
      # Valid actions do nothing here, they just pass the check
      ;;
    *)
      _tool_warn "Unknown action: $action"
      echo "$usage"
      return 1 # Fail with an error code
      ;;
  esac

  # Check if at least one target was provided
  if [[ $# -eq 0 ]]; then
    _tool_warn "No packages specified."
    echo "$usage"
    return 1 # Fail with an error code
  fi

  # Check if 'all' is among the arguments
  for arg in "$@"; do
    if [[ "$arg" == "all" ]]; then
      run_all=1
      break
    fi
  done

  if [[ $run_all -eq 1 ]]; then
    _tool_log "Starting global '$action' for all tools..."
    local pkgs=()

    local pkg_name pkg_file

    for pkg_file in "${BASH_SETUP_DIR}"/pkgs.d/*.sh; do
      pkg_name=$(basename "$pkg_file")
      pkg_name="${pkg_name%.sh}"
      pkgs+=("$pkg_name")
    done

    for pkg in "${pkgs[@]}"; do
      _tool_pkg_exec "$pkg" "$action" || return 1
    done
  else
    # Process every package name passed in the command line
    for pkg in "$@"; do
      _tool_pkg_exec "$pkg" "$action" || return 1
    done
  fi
}

_tool_pkg_exec() {
  local pkg="$1"
  local act="$2"
  local pkg_file="${BASH_SETUP_DIR}/pkgs.d/${pkg}.sh"

  if [[ -f "$pkg_file" ]]; then
    # Sourcing is safe here as tool.sh already created the subshell
    source "$pkg_file"
    "pkg_${pkg}" "$act"
  else
    echo "Error: Package '$pkg' not found in ${BASH_SETUP_DIR}/pkg.d/"
    return 1
  fi
}
