# --- CLI Framework ---
TOOL_VERSION="0.1.0"

_tool_run_cmd() {
  local cmd="$1"
  local status=0

  shift

  _tool_require_any curl wget
  _tool_require_all git make tar xz

  case "$cmd" in
    pkg)
      (source "${BASH_SETUP_DIR}/cmds/pkg.sh" && _tool_pkg "$@")
      status=$?
      ;;
    subpkg)
      (source "${BASH_SETUP_DIR}/cmds/subpkg.sh" && tool_sub_pkg "$@")
      status=$?
      ;;
    sync)
      (source "${BASH_SETUP_DIR}/cmds/sync.sh" && tool_sync "$@")
      status=$?
      ;;
  esac

  [[ "$status" -eq 0 ]] &&
    _tool_refresh_shell_runtime &&
    _tool_ensure_mise_config

  return "$status"
}

_tool_help() {
  cat <<EOF
Usage: tool <command> [options]

A modular CLI engine for managing packages, runtimes, and system configurations.

Commands:
  pkg       Manage primary packages (install, update, remove)
  subpkg    Manage language-specific sub-packages (npm, cargo, etc.)
  sync      Synchronize runtimes and sub-packages
  sys       System utilities
  list      List available primary packages
  help      Show this help message
  version   Show current tool version

Options:
  -h, --help     Show help for a specific command (e.g., tool pkg --help)
  -V, --version  Show version information

EOF
}

tool() {
  local cmd="$1"
  local status=0

  # Handle Global Flags
  case "$cmd" in
    -h | --help | help)
      _tool_help
      return 0
      ;;
    -V | --version | version)
      echo "bash_setup tool v${TOOL_VERSION}"
      return 0
      ;;
  esac

  # Shift past the command argument, but guard against empty arguments
  if [[ $# -gt 0 ]]; then shift; fi

  # Intercept sub-command help requests (e.g., `tool pkg --help`)
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    case "$cmd" in
      pkg) echo "Usage: tool pkg {install|update|remove} <name1> [name2...] [all]" ;;
      subpkg) echo "Usage: tool subpkg {npm|cargo|rustup|go|mise} {install|remove} <name|all>" ;;
      sync) echo "Usage: tool sync [all|runtimes|subpkgs|node|python|java|ruby|php|go|rust]" ;;
      sys) echo "Usage: tool sys [args...]" ;;
      *) _tool_help ;;
    esac
    return 0
  fi

  case "$cmd" in
    pkg | subpkg | sync)
      _tool_run_cmd "$cmd" "$@"
      status=$?
      ;;
    sys)
      (source "${BASH_SETUP_DIR}/cmds/sys.sh" && _tool_sys "$@")
      status=$?
      ;;
    list | "")
      (source "${BASH_SETUP_DIR}/cmds/list.sh" && _tool_list)
      status=$?
      ;;
    *)
      _tool_warn "Unknown command: $cmd"
      _tool_help
      return 0
      ;;
  esac

  return "$status"
}

tool-update() {
  (
    # 1. Check if the path exists (works for both directories and symlinks to directories)
    if [[ ! -d "$BASH_SETUP_DIR" ]]; then
      echo "Error: '$BASH_SETUP_DIR' (directory or symlink) not found."
      return 1
    fi

    # 2. Check if it is a git repo
    if ! git -C "$BASH_SETUP_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Error: '$BASH_SETUP_DIR' is not a git repository."
      return 1
    fi

    # 3. Pull the changes
    echo "Updating $BASH_SETUP_DIR..."
    if git -C "$BASH_SETUP_DIR" pull origin main; then
      echo -e "\n.bash_setup is updated. Please restart your shell or source ~/.bashrc for changes to take effect."
    else
      echo "Error: Failed to pull updates."
      return 1
    fi
  )
}
