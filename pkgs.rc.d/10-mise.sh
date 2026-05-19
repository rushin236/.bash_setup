#!/usr/bin/env bash

command -v mise >/dev/null  || return 0

eval "$(mise activate bash)"
