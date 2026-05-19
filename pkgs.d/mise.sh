#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/mise.sh

pkg_mise() {
  local action="$1"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/mise"
  local repo="jdx/mise"
  local tmp_dir="/tmp/mise_dl_$RANDOM"

  if ! _tool_online; then
    _tool_die "No Internet access"
  fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating mise"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # mise tags are 'v2024.5.17', we strip the 'v'
      remote_ver_clean="${remote_ver#v}"

      if [[ ! -x "$target_bin" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        # mise --version prints "mise 2024.5.17 linux-x64 (commit)". We want the 2nd column.
        local_ver=$("$target_bin" --version 2>/dev/null | head -n1 | awk '{print $1}') || local_ver="unknown"
        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "mise is already up to date"
        return 0
      fi

      _tool_log "Downloading mise $remote_ver_clean from GitHub"

      local os arch asset url archive
      os=$(_tool_os)
      arch=$(_tool_arch)

      # Map your OS and Arch to mise's specific conventions
      [[ "$arch" == "amd64" || "$arch" == "x86_64" ]] && arch="x64"
      [[ "$arch" == "aarch64" ]] && arch="arm64"

      # Example asset name: mise-v2024.5.17-linux-x64.tar.gz
      asset="mise-${remote_ver}-${os}-${arch}.tar.gz"
      url="https://github.com/${repo}/releases/download/${remote_ver}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing mise"
      _tool_unpack "$archive" "$tmp_dir" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_makedirs "$install_dir"

      # The tarball explicitly extracts to a folder named 'mise', containing 'bin/mise'
      # We provide a safe fallback just in case they package it at the root in future versions
      if [[ -f "$tmp_dir/mise/bin/mise" ]]; then
        mv -f "$tmp_dir/mise/bin/mise" "$target_bin" >/dev/null || {
          rm -rf "$tmp_dir" >/dev/null
          return 1
        }
      else
        mv -f "$tmp_dir"/*/mise "$target_bin" >/dev/null || {
          rm -rf "$tmp_dir" >/dev/null
          return 1
        }
      fi

      chmod +x "$target_bin"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed mise version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing mise..."
      rm -f "$target_bin" >/dev/null
      _tool_log "mise removed successfully"
      ;;

    *)
      _tool_warn "Unknown action: $action"
      return 1
      ;;
  esac
}
