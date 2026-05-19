#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/uv.sh

pkg_uv() {
  local action="$1"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/uv"
  local target_bin_x="$install_dir/uvx" # uv provides a second binary!
  local repo="astral-sh/uv"
  local tmp_dir="/tmp/uv_dl_$RANDOM"

  if ! _tool_online; then
    _tool_die "No Internet access"
  fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating uv"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # uv tags are usually '0.4.0', but we strip 'v' just in case they change conventions
      remote_ver_clean="${remote_ver#v}"

      # Require install if either binary is missing
      if [[ ! -x "$target_bin" ]] || [[ ! -x "$target_bin_x" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        # uv --version prints "uv 0.4.0 (commit-hash)". We want the 2nd column.
        local_ver=$("$target_bin" --version 2>/dev/null | head -n1 | awk '{print $2}') || local_ver="unknown"
        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "uv is already up to date"
        return 0
      fi

      _tool_log "Downloading uv $remote_ver_clean from GitHub"

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
        # Statically linked generic Linux binary
        target="${arch}-unknown-linux-musl"
      fi

      # Astral does NOT include the version number in their asset filenames
      # Example asset name: uv-x86_64-unknown-linux-musl.tar.gz
      asset="uv-${target}.tar.gz"
      url="https://github.com/${repo}/releases/download/${remote_ver}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing uv & uvx"
      _tool_unpack "$archive" "$tmp_dir" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_makedirs "$install_dir"

      # Use explicit parameter expansion pathing, but do it for BOTH binaries
      mv -f "$tmp_dir/${asset%.tar.gz}/uv" "$target_bin" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }
      mv -f "$tmp_dir/${asset%.tar.gz}/uvx" "$target_bin_x" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      chmod +x "$target_bin" "$target_bin_x"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed uv version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing uv..."
      rm -f "$target_bin" "$target_bin_x" >/dev/null
      _tool_log "uv removed successfully"
      ;;

    *)
      _tool_warn "Unknown action: $action"
      return 1
      ;;
  esac
}
