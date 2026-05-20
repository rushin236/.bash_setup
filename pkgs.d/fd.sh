#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/fd.sh

pkg_fd() {
  local action="$1"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/fd"
  local repo="sharkdp/fd"
  local tmp_dir="/tmp/fd_dl_$RANDOM"

  # if ! _tool_online; then
  #   _tool_die "No Internet access"
  # fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating fd"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # fd tags are 'v10.1.0', we strip the 'v' for version comparisons
      remote_ver_clean="${remote_ver#v}"

      if [[ ! -x "$target_bin" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        # fd --version prints "fd 10.1.0". We want the 2nd column.
        local_ver=$("$target_bin" --version 2>/dev/null | awk '{print $2}') || local_ver="unknown"
        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "fd is already up to date"
        return 0
      fi

      _tool_log "Downloading fd $remote_ver_clean from GitHub"

      # Map your OS and Arch to Rust target triples
      local os arch target asset url archive
      os=$(_tool_os)
      arch=$(_tool_arch)

      # Normalize architecture to Rust standards
      [[ "$arch" == "amd64" ]] && arch="x86_64"
      [[ "$arch" == "arm64" ]] && arch="aarch64"

      # Determine the Rust target triple
      if [[ "$os" == "macos" ]]; then
        target="${arch}-apple-darwin"
      else
        # For ANY Linux distro (arch, ubuntu, debian), use linux-musl for a statically linked, highly portable binary
        target="${arch}-unknown-linux-musl"
      fi

      # Example asset name: fd-v10.1.0-x86_64-unknown-linux-musl.tar.gz
      asset="fd-${remote_ver}-${target}.tar.gz"
      url="https://github.com/${repo}/releases/download/${remote_ver}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing fd"
      _tool_unpack "$archive" "$tmp_dir" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_makedirs "$install_dir"

      # The fd binary is inside a nested folder in the tarball (e.g., /fd-v10.1.0-x86_64-linux/fd)
      # Using `find` is the safest way to grab the binary without guessing the exact folder name
      mv -f "$tmp_dir/${asset%.tar.gz}/fd" "$target_bin" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }
      chmod +x "$target_bin"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed fd version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing fd..."
      rm -f "$target_bin" >/dev/null
      _tool_log "fd removed successfully"
      ;;

    *)
      _tool_warn "Unknown action: $action"
      return 1
      ;;
  esac
}
