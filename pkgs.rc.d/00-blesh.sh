#!/usr/bin/env bash

# Inline the path and check existence directly before sourcing
[[ $- == *i* ]] && [[ -f "$HOME/.local/share/blesh/ble.sh" ]] && source "$HOME/.local/share/blesh/ble.sh" --noattach
