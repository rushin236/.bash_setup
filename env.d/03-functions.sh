# ~/.bashrc.d/source/02-functions.sh

# --- INTERACTIVE CONDA TOGGLE ---
conda_toggle_env() {
  local backend=""
  local current_env=""
  local selected_env=""
  local deactivate_opt="[Deactivate -> System Python]"

  # Prefer micromamba
  if command -v micromamba >/dev/null ; then
    backend="micromamba"
    current_env="${CONDA_DEFAULT_ENV:-}"

  elif command -v conda >/dev/null ; then
    backend="conda"
    current_env="${CONDA_DEFAULT_ENV:-}"

  else
    echo "No micromamba or conda found"
    return 1
  fi

  selected_env=$(
    (
      echo "$deactivate_opt"

      "$backend" env list 2>/dev/null |
        awk '
          /^[^#]/ && NF {
            print $1
          }
        ' |
        grep -vE '^(base|\*)$'
    ) | sort -u |
      fzf \
        --height 40% \
        --layout=reverse \
        --border \
        --prompt="Select Env [$backend]: "
  )

  [[ -z "$selected_env" ]] && return 0

  # Full deactivate
  if [[ "$selected_env" == "$deactivate_opt" ]]; then
    while [[ -n "$CONDA_DEFAULT_ENV" ]]; do
      "$backend" deactivate >/dev/null  || break
    done
    return 0
  fi

  # Already active
  [[ "$selected_env" == "$current_env" ]] && return 0

  # Switch envs cleanly
  if [[ -n "$current_env" ]]; then
    "$backend" deactivate >/dev/null 
  fi

  "$backend" activate "$selected_env"
}

# --- DIRECTORY LOGGER ---
_tool_log_recent_dir() {
  local file="$HOME/.recent_dirs"

  [[ "$PWD" == "$LAST_LOGGED_DIR" ]] && return
  LAST_LOGGED_DIR="$PWD"

  {
    printf '%s\n' "$PWD"
    tac "$file" 2>/dev/null
  } | awk '!seen[$0]++' | head -n 50 | tac >"$file.tmp"

  mv "$file.tmp" "$file" >/dev/null 
}

PROMPT_COMMAND+=("_tool_log_recent_dir")
