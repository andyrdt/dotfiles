#!/bin/zsh
# Loads for ALL zsh (including Cursor, scripts) - ensures user bins override system
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Cargo/Rust
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# fnm + Node - needed for codex, claude, etc. even in minimal shells
FNM_DIR="$HOME/.local/share/fnm"
if [[ -d "$FNM_DIR" ]] && [[ -x "$FNM_DIR/fnm" ]]; then
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --shell zsh)"
fi
