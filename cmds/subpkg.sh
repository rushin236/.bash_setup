#!/usr/bin/env bash

_subpkg_usage() {
  echo "Usage: tool subpkg {npm|cargo|rustup|go|mise} {install|remove} <name|all>"
  return 1
}

_ensure_manager() {
  local manager="$1"
  local check_cmd="$manager"

  # Both cargo and rustup rely on 'cargo' being executable
  [[ "$manager" == "rustup" ]] && check_cmd="cargo"

  # 1. Early Exit: If the manager is already installed, do nothing.
  command -v "$check_cmd" >/dev/null && return 0

  _tool_log "'$manager' missing. Resolving required runtime..."

  # 2. Source sync.sh exactly ONCE for this subshell
  source "${BASH_SETUP_DIR}/cmds/sync.sh"

  # 3. Route to the correct function inside sync.sh
  case "$manager" in
    npm) _sync_runtimes node || return 1 ;;
    cargo | rustup) _sync_runtimes rust || return 1 ;;
    go) _sync_runtimes go || return 1 ;;
    mise) _install_pkg install mise || return 1 ;;
  esac

  # 4. Final Verification: Check if the resolution actually worked
  command -v "$check_cmd" >/dev/null && _tool_log "Found $check_cmd" || {
    _tool_die "Failed to provision '$manager'"
  }
}

_get_packages() {
  local manager="$1"
  local conf_file="$HOME/.config/bash_setup/runtime_pkgs.conf"

  [[ -f "$conf_file" ]] || {
    _tool_warn "No config file found."
    return 1
  }

  awk -v mgr="$manager" '
    BEGIN { in_section=0 }
    {
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "") next
      if (line ~ /^#/) next
      if (line ~ /^\[.*\]$/) {
        in_section = (line == "[" mgr "]")
        next
      }
      if (in_section) {
        sub(/[[:space:]]+#.*$/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (line != "") print line
      }
    }
  ' "$conf_file"
}

tool_sub_pkg() {
  local manager="$1"
  local action="$2"
  local target="$3"

  [[ -z "$manager" || -z "$action" || -z "$target" ]] && {
    _subpkg_usage || return 1
  }

  shift

  case "${manager}" in
    npm | cargo | rustup | go | mise) ;; # Valid managers
    *)
      echo "Invalid manager: '$manager'"
      _subpkg_usage || return 1
      ;;
  esac

  shift

  case "${action}" in
    install | remove) ;;
    *)
      echo "Invalid action: '$action'"
      _subpkg_usage || return 1
      ;;
  esac

  _ensure_manager "$manager" || return 1

  local pkgs_to_process=()

  if [[ "$target" == "all" ]]; then
    mapfile -t pkgs_to_process < <(_get_packages "$manager")
  else
    pkgs_to_process=("$@")
  fi

  # Check if the array is completely empty
  if [[ ${#pkgs_to_process[@]} -eq 0 ]]; then
    if [[ "$target" == "all" ]]; then
      _tool_warn "No packages defined for $manager."
      _tool_warn "Please add packages under the [$manager] section in: ~/.config/bash_setup/runtime_pkgs.conf"
    else
      _tool_warn "No specific packages provided to process." && _subpkg_usage && return 0
    fi
    _subpkg_usage && return 0
  fi

  _tool_log "$action-ing $manager sub-packages: ${pkgs_to_process[*]}"

  case "$manager" in
    npm)
      for pkg in "${pkgs_to_process[@]}"; do
        if [[ "$action" == "remove" ]]; then
          if npm uninstall -g "$pkg" &>/dev/null; then
            _tool_log "Removed npm pkg: ${pkg}"
          else
            _tool_warn "Failed to remove npm package '$pkg'. Skipping..."
          fi
        else
          if npm install -g "$pkg" &>/dev/null; then
            _tool_log "Installed npm pkg: ${pkg}"
          else
            _tool_warn "Failed to install npm package '$pkg'. Skipping..."
          fi
        fi
      done
      ;;

    cargo)
      for pkg in "${pkgs_to_process[@]}"; do
        if [[ "$action" == "remove" ]]; then
          if cargo uninstall "$pkg" &>/dev/null; then
            _tool_log "Removed cargo pkg: ${pkg}"
          else
            _tool_warn "Failed to remove cargo package '$pkg'. Skipping..."
          fi
        else
          # Note: cargo install can be noisy on stderr too, you can use -q if you want it dead silent
          if cargo install -q "$pkg" &>/dev/null; then
            _tool_log "Installed cargo pkg: ${pkg}"
          else
            _tool_warn "Failed to install cargo package '$pkg'. Skipping..."
          fi
        fi
      done
      ;;

    rustup)
      for pkg in "${pkgs_to_process[@]}"; do
        if [[ "$action" == "remove" ]]; then
          if rustup component remove "$pkg" &>/dev/null; then
            _tool_log "Removed rustup pkg: ${pkg}"
          else
            _tool_warn "Failed to remove rustup component '$pkg'. Skipping..."
          fi
        else
          if rustup component add "$pkg" &>/dev/null; then
            _tool_log "Installed rustup pkg: ${pkg}"
          else
            _tool_warn "Failed to add rustup component '$pkg'. Skipping..."
          fi
        fi
      done
      ;;

    go)
      for pkg in "${pkgs_to_process[@]}"; do
        if [[ "$action" == "remove" ]]; then
          local base="${pkg##*/}"
          if rm -f "$HOME/.local/share/go/bin/${base%%@*}" &>/dev/null; then
            _tool_log "Removed go pkg: ${pkg}"
          else
            _tool_warn "Failed to remove go package '$pkg'. Skipping..."
          fi
        else
          if GOPATH="$HOME/.local/share/go" go install "$pkg" &>/dev/null; then
            _tool_log "Installed go pkg: ${pkg}"
          else
            _tool_warn "Failed to install go package '$pkg'. Skipping..."
          fi
        fi
      done
      ;;

    mise)
      for pkg in "${pkgs_to_process[@]}"; do
        if [[ "$action" == "remove" ]]; then
          if mise uninstall "$pkg" &>/dev/null; then
            _tool_log "Removed mise pkg: ${pkg}"
          else
            _tool_warn "Failed to remove mise package '$pkg'. Skipping..."
          fi
        else
          if mise use -g "$pkg" &>/dev/null; then
            _tool_log "Installed mise pkg: ${pkg}"
          else
            _tool_warn "Failed to use mise package '$pkg'. Skipping..."
          fi
        fi
      done
      ;;
  esac
}
