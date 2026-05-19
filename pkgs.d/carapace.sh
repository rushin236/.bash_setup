#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/carapace.sh

pkg_carapace() {
  local action="$1"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/carapace"
  local repo="carapace-sh/carapace-bin"
  local tmp_dir="/tmp/carapace_dl_$RANDOM"

  if ! _tool_online; then
    _tool_die "No Internet access"
  fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating carapace"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # Carapace tags are 'v1.0.4', but the release files use '1.0.4'.
      remote_ver_clean="${remote_ver#v}"

      if [[ ! -x "$target_bin" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        # carapace --version prints "carapace-bin 1.0.4". We want the 2nd column.
        local_ver=$("$target_bin" --version 2>/dev/null | awk '{print $2}') || local_ver="unknown"
        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "carapace is already up to date"
        return 0
      fi

      _tool_log "Downloading carapace $remote_ver_clean from GitHub"

      # Determine OS and Arch
      local os arch asset url archive
      os=$(_tool_os)
      arch=$(_tool_arch)

      # Map to Carapace's specific release naming convention
      [[ "$os" == "macos" ]] && os="darwin"
      [[ "$arch" == "x86_64" ]] && arch="amd64"
      [[ "$arch" == "aarch64" ]] && arch="arm64"

      # Example: carapace-bin_1.0.4_linux_amd64.tar.gz
      asset="carapace-bin_${remote_ver_clean}_${os}_${arch}.tar.gz"
      url="https://github.com/${repo}/releases/download/${remote_ver}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing carapace"
      _tool_unpack "$archive" "$tmp_dir" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_makedirs "$install_dir"
      mv -f "$tmp_dir/carapace" "$target_bin" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }
      chmod +x "$target_bin"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed carapace version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing carapace..."
      rm -f "$target_bin" >/dev/null
      _tool_log "carapace removed successfully"
      ;;
  esac
}
