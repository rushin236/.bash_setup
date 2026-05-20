#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/shellcheck.sh

pkg_shellcheck() {
  local action="$1"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/shellcheck"
  local repo="koalaman/shellcheck"
  local tmp_dir="/tmp/shellcheck_dl_$RANDOM"

  # if ! _tool_online; then
  #   _tool_die "No Internet access"
  # fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating ShellCheck"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # ShellCheck tags are 'v0.10.0', we strip the 'v'
      remote_ver_clean="${remote_ver#v}"

      if [[ ! -x "$target_bin" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        local_ver=$("$target_bin" --version 2>/dev/null | grep '^version:' | awk '{print $2}') || local_ver="unknown"
        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "ShellCheck is already up to date"
        return 0
      fi

      _tool_log "Downloading ShellCheck $remote_ver_clean from GitHub"

      local os arch asset url archive
      os=$(_tool_os)
      arch=$(_tool_arch)

      # Map your OS and Arch to ShellCheck's specific naming conventions
      [[ "$os" == "macos" ]] && os="darwin"
      [[ "$arch" == "amd64" ]] && arch="x86_64"
      [[ "$arch" == "arm64" ]] && arch="aarch64"

      # Example asset name: shellcheck-v0.10.0.linux.x86_64.tar.xz
      asset="shellcheck-${remote_ver}.${os}.${arch}.tar.xz"
      url="https://github.com/${repo}/releases/download/${remote_ver}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing ShellCheck"
      _tool_unpack "$archive" "$tmp_dir" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_makedirs "$install_dir"

      # ShellCheck extracts to a folder named exactly after the remote_ver (e.g., shellcheck-v0.10.0)
      mv -f "$tmp_dir/shellcheck-${remote_ver}/shellcheck" "$target_bin" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }
      chmod +x "$target_bin"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed ShellCheck version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing ShellCheck..."
      rm -f "$target_bin" >/dev/null
      _tool_log "ShellCheck removed successfully"
      ;;

    *)
      _tool_warn "Unknown action: $action"
      return 1
      ;;
  esac
}
