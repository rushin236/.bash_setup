#!/usr/bin/env bash

# ~/.bash_setup/cmds/sys.sh

_sys_usage() {
  echo "Usage: tool sys {install|remove|search|list|update} [packages...]"
  echo ""
  echo "Commands:"
  echo "  install <pkg>...   Install system packages"
  echo "  remove <pkg>...    Remove system packages"
  echo "  search <query>     Search for packages in online repositories"
  echo "  list [query]       List installed packages (optionally filter by query)"
  echo "  update             Update all system packages"
  return 1
}

# Detect the active system package manager
_get_sys_manager() {
  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  else
    echo "unknown"
  fi
}

tool_sys() {
  local action="$1"
  shift
  local pkgs=("$@")

  [[ -z "$action" ]] && {
    _sys_usage
    return 1
  }

  local mgr
  mgr=$(_get_sys_manager)

  if [[ "$mgr" == "unknown" ]]; then
    _tool_warn "No supported system package manager found (pacman, apt, dnf, zypper, apk)."
    return 1
  fi

  # Determine if we need sudo (only apply sudo if the user is not root)
  local SUDO=""
  if [[ "$EUID" -ne 0 ]]; then
    SUDO="sudo"
  fi

  case "$action" in
    install)
      [[ ${#pkgs[@]} -eq 0 ]] && {
        _tool_warn "Please provide packages to install."
        return 1
      }
      _tool_log "Installing via $mgr: ${pkgs[*]}"

      case "$mgr" in
        pacman) $SUDO pacman -S "${pkgs[@]}" ;;
        apt) $SUDO apt install "${pkgs[@]}" ;;
        dnf | yum) $SUDO "$mgr" install "${pkgs[@]}" ;;
        zypper) $SUDO zypper install "${pkgs[@]}" ;;
        apk) $SUDO apk add "${pkgs[@]}" ;;
      esac
      ;;

    remove)
      [[ ${#pkgs[@]} -eq 0 ]] && {
        _tool_warn "Please provide packages to remove."
        return 1
      }
      _tool_log "Removing via $mgr: ${pkgs[*]}"

      case "$mgr" in
        # pacman -Rs removes the package AND its unused dependencies (cleaner)
        pacman) $SUDO pacman -Rs "${pkgs[@]}" ;;
        apt) $SUDO apt remove "${pkgs[@]}" ;;
        dnf | yum) $SUDO "$mgr" remove "${pkgs[@]}" ;;
        zypper) $SUDO zypper remove "${pkgs[@]}" ;;
        apk) $SUDO apk del "${pkgs[@]}" ;;
      esac
      ;;

    update)
      _tool_log "Running full system update via $mgr..."

      case "$mgr" in
        pacman) $SUDO pacman -Syu ;;
        apt) $SUDO apt update && $SUDO apt upgrade ;;
        dnf | yum) $SUDO "$mgr" upgrade ;;
        zypper) $SUDO zypper refresh && $SUDO zypper update ;;
        apk) $SUDO apk update && $SUDO apk upgrade ;;
      esac
      ;;

    search)
      [[ ${#pkgs[@]} -eq 0 ]] && {
        _tool_warn "Please provide a search query."
        return 1
      }
      # Searching does not require sudo
      case "$mgr" in
        pacman) pacman -Ss "${pkgs[@]}" ;;
        apt) apt search "${pkgs[@]}" ;;
        dnf | yum) "$mgr" search "${pkgs[@]}" ;;
        zypper) zypper search "${pkgs[@]}" ;;
        apk) apk search "${pkgs[@]}" ;;
      esac
      ;;

    list)
      # Listing does not require sudo
      case "$mgr" in
        pacman)
          if [[ ${#pkgs[@]} -gt 0 ]]; then
            pacman -Qs "${pkgs[@]}"
          else
            pacman -Q
          fi
          ;;
        apt)
          if [[ ${#pkgs[@]} -gt 0 ]]; then
            apt list --installed | grep -i "${pkgs[*]}"
          else
            apt list --installed
          fi
          ;;
        dnf | yum)
          if [[ ${#pkgs[@]} -gt 0 ]]; then
            "$mgr" list installed | grep -i "${pkgs[*]}"
          else
            "$mgr" list installed
          fi
          ;;
        zypper)
          zypper search --installed-only "${pkgs[@]}"
          ;;
        apk)
          if [[ ${#pkgs[@]} -gt 0 ]]; then
            apk info | grep -i "${pkgs[*]}"
          else
            apk info
          fi
          ;;
      esac
      ;;

    *)
      _tool_warn "Invalid action: '$action'"
      _sys_usage
      return 1
      ;;
  esac
}
