#!/usr/bin/evn bash

# ~/.bash_setup/pkgs.d/blesh.sh

pkg_blesh() {
  local action="$1"
  local clone_dir="/tmp/blesh_src_$RANDOM"
  local check_dir="$HOME/.local/share/blesh"
  local install_dir="$HOME/.local/"
  local repo="akinomyoga/ble.sh"

  # if ! _tool_online; then
  #   _tool_die "No Internet access" && return 1
  # fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating Blesh"

      local required_install=0
      local local_ver
      local remote_ver

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      if [[ ! -d "$check_dir" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        local_ver=$(bash "$HOME/.local/share/blesh/ble.sh" --version | awk '{print $6}') || local_ver="unknown"
        if [[ "v${local_ver%+*}" != "$remote_ver" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "Blesh is already up to date"
        return 0
      fi

      _tool_log "Cloning Blesh from GitHub"

      git clone --recursive \
        "https://github.com/${repo}.git" \
        "$clone_dir" &>/dev/null && cd "$clone_dir" || return 1

      git checkout "$remote_ver" &>/dev/null && git submodule update --init --recursive &>/dev/null || return 1

      _tool_log "Building and Installing Blesh"

      make >/dev/null && make install PREFIX="$install_dir" >/dev/null && rm -rf "$clone_dir" >/dev/null || return 1

      _tool_log "Installed ble.sh version: $remote_ver"
      ;;
    remove)
      _tool_log "Removing Blesh..."
      rm -rf "$clone_dir" >/dev/null
      rm -f "$install_dir" >/dev/null
      _tool_log "Blesh removed successfully"
      ;;
  esac
}
