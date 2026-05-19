#!/usr/bin/env bash

# ~/.bash_setup/pkgs.d/julia.sh

pkg_julia() {
  local action="$1"
  local opt_dir="$HOME/.local/opt/julia"
  local install_dir="$HOME/.local/bin"
  local target_bin="$install_dir/julia"
  local repo="JuliaLang/julia"
  local tmp_dir="/tmp/julia_dl_$RANDOM"

  if ! _tool_online; then
    _tool_die "No Internet access"
  fi

  case "$action" in
    install | update)
      _tool_log "Installing/Updating Julia"

      local required_install=0
      local local_ver remote_ver remote_ver_clean

      remote_ver=$(_tool_get_latest_release_tag "$repo")

      if [[ -z "$remote_ver" ]]; then
        _tool_die "Failed to get latest release of: $repo"
      fi

      # Julia tags are 'v1.10.3', we strip the 'v'
      remote_ver_clean="${remote_ver#v}"

      if [[ ! -x "$target_bin" ]]; then
        required_install=1
      else
        action="update"
      fi

      if [[ "$action" == "update" ]]; then
        # julia --version prints "julia version 1.10.3". We want the 3rd column.
        local_ver=$("$target_bin" --version 2>/dev/null | awk '{print $3}') || local_ver="unknown"
        if [[ "$local_ver" != "$remote_ver_clean" ]]; then
          required_install=1
        fi
      fi

      if [[ "$required_install" -ne 1 ]]; then
        _tool_log "Julia is already up to date"
        return 0
      fi

      _tool_log "Downloading Julia $remote_ver_clean from Official S3 Servers"

      local major_minor os arch os_folder arch_folder asset url archive

      # Extract just the "1.10" from "1.10.3" for the S3 folder path
      major_minor="${remote_ver_clean%.*}"

      os=$(_tool_os)
      arch=$(_tool_arch)

      # Map to Julia's specific S3 folder structure and naming convention
      if [[ "$os" == "macos" ]]; then
        os_folder="mac"
        if [[ "$arch" == "amd64" || "$arch" == "x86_64" ]]; then
          arch_folder="x64"
          asset="julia-${remote_ver_clean}-mac64.tar.gz"
        else
          arch_folder="aarch64"
          asset="julia-${remote_ver_clean}-macaarch64.tar.gz"
        fi
      else
        os_folder="linux"
        if [[ "$arch" == "amd64" || "$arch" == "x86_64" ]]; then
          arch_folder="x64"
          asset="julia-${remote_ver_clean}-linux-x86_64.tar.gz"
        else
          arch_folder="aarch64"
          asset="julia-${remote_ver_clean}-linux-aarch64.tar.gz"
        fi
      fi

      # Construct the official Julia S3 download URL
      url="https://julialang-s3.julialang.org/bin/${os_folder}/${arch_folder}/${major_minor}/${asset}"
      archive="$tmp_dir/$asset"

      _tool_makedirs "$tmp_dir"
      _tool_download "$url" "$archive" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      _tool_log "Extracting and Installing Julia"
      _tool_unpack "$archive" "$tmp_dir" || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      # Clean up the old installation if it exists
      rm -rf "$opt_dir" >/dev/null

      rm -f "${archive}" >/dev/null

      mv -f "$tmp_dir"/julia-* "$opt_dir" >/dev/null || {
        rm -rf "$tmp_dir" >/dev/null
        return 1
      }

      ln -sf "$opt_dir/bin/julia" "$target_bin"

      _tool_log "Cleaning up..."
      rm -rf "$tmp_dir" >/dev/null

      _tool_log "Installed Julia version: $remote_ver_clean"
      ;;

    remove)
      _tool_log "Removing Julia..."
      rm -rf "$opt_dir" >/dev/null
      rm -f "$target_bin" >/dev/null
      _tool_log "Julia removed successfully"
      ;;

    *)
      _tool_warn "Unknown action: $action"
      return 1
      ;;
  esac
}
