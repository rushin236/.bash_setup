#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/fzf.sh

pkg_fzf() {
  local action="$1"
  local repo_dir="$HOME/.fzf"
  local install_dir="$HOME/.local/bin"
  local repo="junegunn/fzf"

  # --- ADD THIS LINE ---
  # Guarantee we are in a real, existing directory before doing anything
  cd "$HOME" || return 1
  # ---------------------

  if ! _tool_online; then
    _tool_die "No Internet access"
  fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating fzf"

      local required_install=0
      local local_ver
      local remote_ver

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      # Determine if we need to clone (install) or pull (update)
      if [[ ! -x "${install_dir}/fzf" ]]; then
        required_install=1
      else
        action="update"
      fi

      # If updating, check the 7-day cache or missing binary
      if [[ "$action" == "update" ]]; then
        local_ver=$(fzf --version | awk '{print $1}') || local_ver="unknown"
        if [[ "v$local_ver" != "$remote_ver" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "fzf is already up to date"
        return 0
      fi

      if [[ -d "$repo_dir" ]]; then
        _tool_log "Removing old version"
        rm -rf "$repo_dir" >/dev/null
      fi

      _tool_log "Cloning fzf from GitHub"

      # Now this will never fail, because we guaranteed we are in $HOME!
      git clone -q --depth 1 "https://github.com/junegunn/fzf.git" "$repo_dir" &>/dev/null || return 1
      "$repo_dir/install" --bin &>/dev/null || return 1
      ln -sf "$repo_dir/bin/fzf" "${install_dir}/fzf" >/dev/null || return 1

      _tool_log "Installed fzf version: $remote_ver"
      ;;

    remove)
      _tool_log "Removing fzf..."
      rm -rf "$repo_dir" >/dev/null
      rm -f "${install_dir}fzf" >/dev/null
      _tool_log "fzf removed successfully"
      ;;
  esac
}
