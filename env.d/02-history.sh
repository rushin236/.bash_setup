# ~/.bashrc.d/source/03-history.sh

# --- History ---
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=50000
export HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "
export HISTIGNORE="\
ls:ll:la:l:ls -al:\
cd:cd ..:cd ~:\
pwd:clear:c:\
exit:q:\
history*:\
bg:fg:jobs:\
btop:htop:*ps"

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND+=("history -a" "history -n")

_async_history_clean() {
  local marker="$HOME/.cache/bash_history_cleaner.marker"
  local hist_file="$HOME/.bash_history"

  mkdir -p "$HOME/.cache"

  # Check marker (bails out if younger than 60 mins)
  if [[ -f "$marker" ]] && [[ -z $(find "$marker" -mmin +60 2>/dev/null) ]]; then
    return 0
  fi
  touch "$marker"

  # Background process
  (
    local tmp_file="${hist_file}.tmp"
    >"$tmp_file" # Ensure temp file is empty

    # Split your dynamic HISTIGNORE variable by colons into an array
    IFS=':' read -ra ignore_patterns <<<"$HISTIGNORE"

    # Associative array to track duplicates
    local -A seen
    local skip_next_timestamp=false

    # Process the file backwards using tac
    while IFS= read -r cmd && IFS= read -r timestamp; do

      # Skip malformed entries
      [[ ! "$timestamp" =~ ^#[0-9]+$ ]] && continue
      [[ -z "$cmd" ]] && continue

      # HISTIGNORE matching
      for pattern in "${ignore_patterns[@]}"; do
        [[ "$cmd" == $pattern ]] && continue 2
      done

      # Duplicate removal
      [[ -n "${seen[$cmd]}" ]] && continue

      # Keep command
      printf '%s\n%s\n' "$cmd" "$timestamp" >>"$tmp_file"

      # Mark as seen
      seen["$cmd"]=1

    done < <(tac "$hist_file")

    # Reverse it back and safely overwrite the original history file
    tac "$tmp_file" >"$hist_file"
    rm -f "$tmp_file"
  ) >/dev/null  &
  disown
}

# Trigger the check instantly on boot
_async_history_clean
