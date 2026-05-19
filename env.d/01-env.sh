# ~/.bashrc.d/source/01-env.sh

# --- Display & UI ---
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline --color='header:italic'"

# --- Editor ---
for ed in nvim vim nano; do
  if EDITOR_PATH=$(command -v "$ed" 2>/dev/null); then
    export EDITOR="$EDITOR_PATH"
    export VISUAL="$EDITOR_PATH"
    export SUDO_EDITOR="$EDITOR_PATH"
    break
  fi
done

# Enable Vim keystrokes in bash (Required for ble.sh Vi mode)
set -o vi

# --- Native Bash Completion (Crucial for Carapace/ble.sh) ---
if [[ -z "$BASH_COMPLETION_VERSINFO" ]] && [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi
