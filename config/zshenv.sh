#!/bin/zsh
# Loads for ALL zsh (including Cursor, scripts) - ensures user bins override system

# Ensure a directory is present at the front of PATH exactly once.
prepend_path() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  typeset -a _new_path=()
  local entry
  for entry in ${(s/:/)PATH}; do
    [[ "$entry" == "$dir" ]] && continue
    _new_path+="$entry"
  done
  export PATH="$dir:${(j/:/)_new_path}"
}

LOCAL_BIN_DIR="$HOME/.local/bin"
PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
export PNPM_HOME

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

# Unset broken temp-directory settings so tools can fall back cleanly.
for _tmp_var in TMPDIR TMP TEMP; do
  _tmp_value="${(P)_tmp_var}"
  if [[ -n "$_tmp_value" ]] && [[ ! -d "$_tmp_value" || ! -w "$_tmp_value" ]]; then
    unset "$_tmp_var"
  fi
done
unset _tmp_var _tmp_value

# Cargo/Rust
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# fnm + Node - needed for codex, claude, etc. even in minimal shells
if [[ -d "$FNM_DIR" ]] && [[ -x "$FNM_DIR/fnm" ]]; then
  prepend_path "$FNM_DIR"
  eval "$(fnm env --shell zsh)"
fi

# Homebrew on Apple Silicon
prepend_path "/opt/homebrew/bin"

# Final PATH precedence: explicit user bins first, then pnpm-managed CLIs.
prepend_path "$PNPM_HOME"
prepend_path "$LOCAL_BIN_DIR"

unset -f prepend_path
