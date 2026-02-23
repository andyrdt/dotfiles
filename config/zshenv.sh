#!/bin/zsh
# Loads for ALL zsh (including Cursor, scripts) - ensures user bins override system

# Clean stale environment from parent process (e.g. Cursor inheriting old venvs)
# Strip nonexistent directories from PATH
typeset -a _clean_path=()
for _p in ${(s/:/)PATH}; do
  [[ -d "$_p" ]] && _clean_path+="$_p"
done
export PATH="${(j/:/)_clean_path}"
unset _clean_path _p
# Unset VIRTUAL_ENV if the venv no longer exists
if [[ -n "$VIRTUAL_ENV" ]] && [[ ! -d "$VIRTUAL_ENV" ]]; then
  unset VIRTUAL_ENV VIRTUAL_ENV_PROMPT
fi

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
