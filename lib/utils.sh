# --- Foundation & Helpers (Prefixed for safety) ---
_tool_exists() { command -v "$1" >/dev/null; }
_tool_log() { printf '[INFO] %s\n' "$*"; }
_tool_warn() { printf '[WARN] %s\n' "$*" >&2; }
_tool_die() {
  printf '[ERROR] %s\n' "$*" >&2
  return 1
}

_tool_makedirs() {
  mkdir -p "$@" >/dev/null
}

_tool_require() { _tool_exists "$1" || _tool_die "Missing required tool: $1"; }

_tool_require_any() {
  for tool in "$@"; do _tool_exists "$tool" && return 0; done
  _tool_die "Need one of: $*"
}

_tool_require_all() {
  for tool in "$@"; do
    _tool_exists "$tool" || _tool_require "$tool"
  done
}

_tool_online() {
  if curl -Is --connect-timeout 3 https://api.github.com >/dev/null; then
    return 0
  else
    return 1
  fi
}

_tool_os() {
  case "$(uname -s)" in
    Linux)
      if [[ -r /etc/os-release ]] && [[ "$1" == "-d" ]]; then
        (
          . /etc/os-release
          printf '%s\n' "${ID:-linux}"
        )
      else
        printf 'linux\n'
      fi
      ;;
    Darwin)
      printf 'macos\n'
      ;;
    FreeBSD)
      printf 'freebsd\n'
      ;;
    OpenBSD)
      printf 'openbsd\n'
      ;;
    NetBSD)
      printf 'netbsd\n'
      ;;
    *)
      uname -s | tr '[:upper:]' '[:lower:]'
      ;;
  esac
}

_tool_arch() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64) echo arm64 ;;
    armv7l) echo armv7 ;;
    *) uname -m ;;
  esac
}

_tool_init_dirs() {
  _tool_makedirs "$HOME/.local/bin" \
    "$HOME/.local/opt" \
    "$HOME/.local/share/bash_setup/checks" \
    "$HOME/.cache/bash_setup"
}

_tool_init_dirs

_tool_download() {
  local url="$1"
  local out="$2"

  _tool_require_any curl wget || return 1

  if _tool_exists curl; then
    curl \
      --fail \
      --location \
      --silent \
      --show-error \
      --retry 3 \
      --output "$out" \
      "$url" >/dev/null
  else
    wget \
      --quiet \
      --output-document="$out" \
      "$url" >/dev/null
  fi
}

_tool_unpack() {
  local file="$1"
  local dest="$2"

  shift 2

  _tool_makedirs "$dest"

  case "$file" in
    *.tar.gz | *.tgz)
      tar -xzf "$file" -C "$dest" "$@" >/dev/null
      ;;

    *.tar.xz)
      tar -xJf "$file" -C "$dest" "$@" >/dev/null
      ;;

    *.tar.bz2)
      tar -xjf "$file" -C "$dest" "$@" >/dev/null
      ;;

    *.zip)
      unzip -q "$file" -d "$dest" >/dev/null
      ;;

    *)
      _tool_die "Unsupported archive: $file"
      return 1
      ;;
  esac
}

_tool_get_latest_release_tag() {
  local repo="$1"

  curl -fsSLw '%{url_effective}' \
    -o /dev/null \
    "https://github.com/${repo}/releases/latest" |
    xargs basename
}

_tool_refresh_shell_runtime() {
  # 1. Clear Bash's command cache
  hash -r

  if command -v mise >/dev/null; then
    # 2. Tell OS to generate shims for newly downloaded tools
    mise reshim >/dev/null || true

    # 3. The Smart Router (Using your PROMPT_COMMAND check)
    if [[ "${PROMPT_COMMAND[*]:-}" == *"_mise_hook"* ]]; then
      # ALREADY ACTIVATED: Just do a fast, stateless PATH update for the subshell
      eval "$(mise env)"
    else
      # NOT ACTIVATED YET: Run the full startup sequence
      if [[ -f "${BASH_SETUP_DIR}/pkgs.rc.d/10-mise.sh" ]]; then
        source "${BASH_SETUP_DIR}/pkgs.rc.d/10-mise.sh"
      else
        # Fallback if 10-mise.sh doesn't exist yet
        eval "$(mise activate bash)"
        # complete -r mise 2>/dev/null || true
      fi
    fi

    # 4. Clear cache again so Bash immediately sees the new shims
    hash -r
  fi
}

_tool_ensure_mise_config() {
  # Fast exit if mise isn't installed yet
  command -v mise >/dev/null || return 0

  local config_file="$HOME/.config/mise/config.toml"

  # 1. Check and Set Ruby Settings
  if [[ "$(mise settings get ruby.compile 2>/dev/null)" != "false" ]]; then
    mise settings set ruby.compile false 2>/dev/null || true
  fi

  # 2. Check and Set Global Environment Variables
  if ! grep -q "^MISE_PYTHON_GITHUB_ATTESTATIONS" "$config_file" 2>/dev/null; then
    mise config set env.MISE_PYTHON_GITHUB_ATTESTATIONS false
  fi

  if ! grep -q "^PHP_SKIP_DEPS" "$config_file" 2>/dev/null; then
    mise config set env.PHP_SKIP_DEPS '"1"'
  fi

  if ! grep -q "^PHP_CONFIGURE_OPTIONS" "$config_file" 2>/dev/null; then
    mise config set env.PHP_CONFIGURE_OPTIONS -- "--enable-bcmath --enable-calendar --enable-dba --enable-exif --enable-fpm --enable-ftp --enable-gd --enable-intl --enable-mbregex --enable-mbstring --enable-mysqlnd --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-curl --with-mhash --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-zlib --without-pcre-jit --with-readline --with-gettext --with-zip"
  fi

  # 3. Check and Set Custom Plugins
  if ! mise plugin ls 2>/dev/null | grep -qx php; then
    _tool_log "Adding custom PHP plugin..."
    mise plugin install php https://github.com/verzly/mise-php#latest
  fi
}
