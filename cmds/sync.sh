#!/usr/bin/env bash

# Helper for usage messages
_sync_usage() {
  echo "Usage: tool sync [all | runtimes | subpkgs] OR tool sync [python rust go java ruby node php]"
  return 1
}

_install_pkg() {
  local act="$1"
  local name="$2"

  local file="${BASH_SETUP_DIR}/cmds/pkg.sh"

  [[ -f "$file" ]] || {
    _tool_warn "Package definition not found: $name"
    return 1
  }

  source "$file"

  # Catch errors from _tool_pkg to safely abort if the installation fails
  if ! _tool_pkg "$act" "$name"; then
    _tool_warn "Failed to execute '$act' for package '$name'."
    return 1
  fi

  _tool_refresh_shell_runtime
  return 0
}

_ensure_tools() {
  local pkg

  for pkg in mise uv; do
    # 1. Check if the tool is missing
    if ! command -v "$pkg" >/dev/null; then
      _tool_log "Installing $pkg..."
      _install_pkg install "$pkg" || {
        _tool_warn "Failed to install required tool: $pkg"
        return 1
      }
    fi

    # 2. Verify installation succeeded
    command -v "$pkg" >/dev/null && _tool_log "Tool $pkg verified." || {
      _tool_die "Critical failure: $pkg could not be verified after installation."
    }
  done
}

# Refactored to batched array processing for extreme speed
_sync_runtimes() {
  _ensure_tools || return 1
  _tool_ensure_mise_config || return 1

  [[ -f "$HOME/.config/bash_setup/runtime.conf" ]] &&
    . "$HOME/.config/bash_setup/runtime.conf" || {
    _tool_warn "Runtime configuration not found. Using defaults from script."
  }

  local sync_list=()
  local runtime version

  for runtime in "$@"; do
    case "$runtime" in
      lua) version="${VERSION_LUA:-5.5.2}" ;;
      node) version="${VERSION_NODE:-24.16.0}" ;;
      python) version="${VERSION_PYTHON:-3.14.5}" ;;
      java) version="${VERSION_JAVA:-25.0.1}" ;;
      ruby) version="${VERSION_RUBY:-3.4.1}" ;;
      php) version="${VERSION_PHP:-8.5.6}" ;;
      go) version="${VERSION_GO:-1.26.3}" ;;
      rust) version="${VERSION_RUST:-1.97.0}" ;;
      *)
        _tool_warn "Unknown runtime requested: $runtime. Skipping..."
        continue
        ;;
    esac
    sync_list+=("${runtime}@${version}")
  done

  [[ ${#sync_list[@]} -eq 0 ]] && return 0

  _tool_log "Syncing runtimes: ${sync_list[*]}"

  # Run mise ONCE with the entire array of runtimes
  if mise use -g "${sync_list[@]}"; then
    _tool_refresh_shell_runtime
    _tool_log "Successfully synced runtimes: ${sync_list[*]} "
  else
    _tool_warn "Failed to sync one or more runtimes."
    return 1
  fi
}

_sync_languages() {
  # Batch process all defaults at once
  _sync_runtimes python lua rust go java ruby node php || {
    _tool_warn "Failed during global languages sync."
    return 0
  }
}

_sync_subpkgs() {
  local subpkg_script="${BASH_SETUP_DIR}/cmds/subpkg.sh"

  [[ -f "$subpkg_script" ]] || {
    _tool_warn "Subpackage manager script not found: $subpkg_script"
    return 1
  }

  source "$subpkg_script"

  tool_sub_pkg npm install all || {
    _tool_warn "npm sub-packages sync failed"
    return 0
  }
  tool_sub_pkg cargo install all || {
    _tool_warn "cargo sub-packages sync failed"
    return 0
  }
  tool_sub_pkg go install all || {
    _tool_warn "go sub-packages sync failed"
    return 0
  }
  tool_sub_pkg rustup install all || {
    _tool_warn "rustup sub-packages sync failed"
    return 0
  }
  tool_sub_pkg mise install all || {
    _tool_warn "mise sub-packages sync failed"
    return 0
  }
}

tool_sync() {
  local args=("$@")

  [[ ${#args[@]} -eq 0 ]] && args=("all")

  # Strict checking: Single argument logic
  if [[ ${#args[@]} -eq 1 ]]; then
    case "${args[0]}" in
      all)
        _sync_languages || return 1
        _sync_subpkgs || return 0
        ;;
      runtimes)
        _sync_languages || return 1
        ;;
      subpkgs)
        _sync_subpkgs || return 0
        ;;
      node | python | java | ruby | php | go | rust | lua)
        _sync_runtimes "${args[0]}" || return 1
        ;;
      *)
        _tool_warn "Unknown sync target: '${args[0]}'"
        _sync_usage
        return 1
        ;;
    esac
    return 0
  fi

  # Strict checking: Multiple arguments logic (MUST be runtimes ONLY)
  for item in "${args[@]}"; do
    case "$item" in
      all | runtimes | subpkgs)
        _tool_warn "'$item' must be run alone and cannot be combined with specific runtimes."
        _sync_usage
        return 1
        ;;
      node | python | java | ruby | php | go | rust | lua)
        # Valid runtime, let it pass
        ;;
      *)
        _tool_warn "Unknown sync target or invalid runtime: '$item'"
        _sync_usage
        return 1
        ;;
    esac
  done

  # If we make it here, all arguments are valid runtimes! Batch them in one go!
  _sync_runtimes "${args[@]}" || return 1
}
