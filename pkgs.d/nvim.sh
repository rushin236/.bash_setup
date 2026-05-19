#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/nvim.sh

pkg_nvim() {
  local action="$1"
  local opt_dir="$HOME/.local/opt/nvim"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/nvim"
  local repo="neovim/neovim"
  local tmp_dir="/tmp/nvim_dl_$RANDOM"

  if ! _tool_online; then
    _tool_die "No Internet access"
  fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating Neovim"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # Neovim tags are 'v0.10.0', we strip the 'v'
      remote_ver_clean="${remote_ver#v}"

      if [[ ! -x "$target_bin" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        # nvim --version prints "NVIM v0.10.0". We want the 2nd column, stripped of the 'v'.
        local_ver=$("$target_bin" --version 2>/dev/null | head -n1 | awk '{print $2}') || local_ver="unknown"
        local_ver="${local_ver#v}"

        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "Neovim is already up to date"
        return 0
      fi

      _tool_log "Downloading Neovim $remote_ver_clean from GitHub"

      local os arch asset url archive
      os=$(_tool_os)
      arch=$(_tool_arch)

      # Map to Neovim's NEW specific release naming convention
      if [[ "$os" == "macos" ]]; then
        [[ "$arch" == "arm64" || "$arch" == "aarch64" ]] && asset="nvim-macos-arm64.tar.gz"
        [[ "$arch" == "amd64" || "$arch" == "x86_64" ]] && asset="nvim-macos-x86_64.tar.gz"
      else
        # Linux (Now with official ARM64 support!)
        [[ "$arch" == "arm64" || "$arch" == "aarch64" ]] && asset="nvim-linux-arm64.tar.gz"
        [[ "$arch" == "amd64" || "$arch" == "x86_64" ]] && asset="nvim-linux-x86_64.tar.gz"
      fi

      url="https://github.com/${repo}/releases/download/${remote_ver}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing Neovim"
      _tool_unpack "$archive" "$tmp_dir" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      # Clean up the old installation if it exists
      rm -rf "$opt_dir" >/dev/null

      # --- THE BULLETPROOF TRICK ---
      # Remove the tarball so the wildcard ONLY matches the extracted folder
      rm -f "$tmp_dir"/*.tar.gz >/dev/null

      _tool_makedirs "$HOME/.local/opt"
      _tool_makedirs "$install_dir"

      # Move the ENTIRE extracted folder using the wildcard outside the quotes
      mv -f "$tmp_dir"/nvim-* "$opt_dir" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }
      # -----------------------------

      # Symlink the binary to ~/.local/bin so it's in your PATH
      ln -sf "$opt_dir/bin/nvim" "$target_bin"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed Neovim version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing Neovim..."
      rm -rf "$opt_dir" >/dev/null
      rm -f "$target_bin" >/dev/null
      _tool_log "Neovim removed successfully"
      ;;

    *)
      _tool_warn "Unknown action: $action"
      return 1
      ;;
  esac
}
