# ~/.bashrc.d/source/00-path.sh

add_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

export GOPATH="$HOME/.local/share/go"
export GOBIN="$GOPATH/bin"

add_path "$HOME/.local/bin"
add_path "$HOME/.local/share/mise/shims"
add_path "$GOBIN"
add_path "$HOME/.cargo/bin"

export PATH
