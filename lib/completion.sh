#!/usr/bin/env bash

_tool_completions() {
  # local cur prev cmd
  local cur cmd
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  # prev="${COMP_WORDS[COMP_CWORD - 1]}"

  # Top-level commands
  local cmds="pkg subpkg sync sys list help version"

  # 1. Complete the main command
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    if [[ "$cur" == -* ]]; then
      COMPREPLY=($(compgen -W "--help --version -h -V" -- "$cur"))
    else
      COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
    fi
    return 0
  fi

  # 2. Extract the sub-command
  cmd="${COMP_WORDS[1]}"

  # Global flag support: Allow --help/-h on any sub-command
  if [[ "$cur" == -* ]]; then
    COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
    return 0
  fi

  # 3. Complete based on sub-command
  case "$cmd" in
    pkg)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "install update remove" -- "$cur"))
      else
        # Dynamically fetch packages using pure bash (Lightning fast, no subshells)
        local pkg_dir="${BASH_SETUP_DIR:-$HOME/.bash_setup}/pkgs.d"
        local pkgs=""

        if [[ -d "$pkg_dir" ]]; then
          for file in "$pkg_dir"/*.sh; do
            [[ -e "$file" ]] || break  # Ensure file exists
            local base="${file##*/}"   # Extract filename (strip path)
            pkgs="${pkgs} ${base%.sh}" # Strip .sh extension and append
          done
        fi

        COMPREPLY=($(compgen -W "$pkgs all" -- "$cur"))
      fi
      ;;

    subpkg)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "npm cargo rustup go mise" -- "$cur"))
      elif [[ ${COMP_CWORD} -eq 3 ]]; then
        COMPREPLY=($(compgen -W "install remove" -- "$cur"))
      else
        # Complete 'all' for the 4th argument and beyond
        COMPREPLY=($(compgen -W "all" -- "$cur"))
      fi
      ;;

    sync)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        local sync_targets="all runtimes subpkgs node python java ruby php go rust"
        COMPREPLY=($(compgen -W "$sync_targets" -- "$cur"))
      fi
      ;;

      # sys)
      #   if [[ ${COMP_CWORD} -eq 2 ]]; then
      #     COMPREPLY=($(compgen -W "update info" -- "$cur"))
      #   fi
      #   ;;
  esac
}

# Register the autocompletion function to the 'tool' command
complete -F _tool_completions tool
