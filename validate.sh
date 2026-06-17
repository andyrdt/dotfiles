#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ZSH_BIN=$(command -v zsh)

echo "Checking shell syntax..."
zsh -n "$SCRIPT_DIR/config/zshenv.sh"
zsh -n "$SCRIPT_DIR/config/zshrc.sh"
zsh -n "$SCRIPT_DIR/config/aliases.sh"
bash -n "$SCRIPT_DIR/install.sh"
bash -n "$SCRIPT_DIR/deploy.sh"
bash -n "$SCRIPT_DIR/setup_github.sh"
bash -n "$SCRIPT_DIR/config/auto_update_check.sh"
bash -n "$SCRIPT_DIR/config/codex_config.sh"
bash -n "$SCRIPT_DIR/config/pnpm_nfs_check.sh"
bash -n "$SCRIPT_DIR/start/display_quote.sh"

echo "Checking zshenv behavior in an isolated environment..."
TEST_ROOT=$(mktemp -d)
cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

TEST_HOME="$TEST_ROOT/home"
TEST_PNPM_HOME="$TEST_ROOT/pnpm-home"
TEST_FNM_DIR="$TEST_ROOT/fnm-dir"
TEST_FNM_MULTISHELL="$TEST_ROOT/fnm-multishell"
TEST_MISSING_PATH="$TEST_ROOT/does-not-exist"
TEST_USER="codex-validate-$$"

mkdir -p \
  "$TEST_HOME/.local/bin" \
  "$TEST_HOME/.cargo/bin" \
  "$TEST_HOME/.cargo" \
  "$TEST_PNPM_HOME" \
  "$TEST_FNM_DIR" \
  "$TEST_FNM_MULTISHELL/bin"

cat > "$TEST_HOME/.cargo/env" <<EOF
export PATH="$TEST_HOME/.cargo/bin:\$PATH"
EOF

cat > "$TEST_FNM_DIR/fnm" <<EOF
#!/bin/sh
if [ "\$1" = "env" ] && [ "\$2" = "--shell" ] && [ "\$3" = "zsh" ]; then
  cat <<'EOS'
export FNM_MULTISHELL_PATH="$TEST_FNM_MULTISHELL"
export PATH="$TEST_FNM_MULTISHELL/bin:\$PATH"
EOS
else
  exit 1
fi
EOF
chmod +x "$TEST_FNM_DIR/fnm"

env -i \
  HOME="$TEST_HOME" \
  USER="$TEST_USER" \
  PATH="/usr/bin:/bin:$TEST_PNPM_HOME:$TEST_MISSING_PATH" \
  PNPM_HOME="$TEST_PNPM_HOME" \
  FNM_DIR="$TEST_FNM_DIR" \
  VIRTUAL_ENV="$TEST_ROOT/missing-venv" \
  TMPDIR="$TEST_ROOT/missing-tmp" \
  REPO_DIR="$SCRIPT_DIR" \
  TEST_PNPM_HOME="$TEST_PNPM_HOME" \
  TEST_FNM_DIR="$TEST_FNM_DIR" \
  TEST_FNM_MULTISHELL="$TEST_FNM_MULTISHELL" \
  TEST_MISSING_PATH="$TEST_MISSING_PATH" \
  "$ZSH_BIN" -fc '
    source "$REPO_DIR/config/zshenv.sh"

    [[ -z "${TMPDIR-}" ]] || { print -u2 "TMPDIR was not cleared"; exit 1; }
    [[ -z "${VIRTUAL_ENV-}" ]] || { print -u2 "VIRTUAL_ENV was not cleared"; exit 1; }
    [[ "$PNPM_HOME" == "$TEST_PNPM_HOME" ]] || { print -u2 "PNPM_HOME was overwritten"; exit 1; }
    [[ -z "${CODEX_HOME-}" ]] || { print -u2 "CODEX_HOME should stay unset by default"; exit 1; }
    [[ "${path[1]}" == "$HOME/.local/bin" ]] || { print -u2 "Expected ~/.local/bin first in PATH"; exit 1; }
    [[ "${path[2]}" == "$TEST_PNPM_HOME" ]] || { print -u2 "Expected PNPM_HOME second in PATH"; exit 1; }

    typeset -i pnpm_count=0
    typeset -i local_bin_count=0
    typeset -i fnm_dir_count=0
    typeset -i fnm_multishell_count=0
    local entry
    for entry in $path; do
      [[ "$entry" == "$TEST_PNPM_HOME" ]] && (( pnpm_count++ ))
      [[ "$entry" == "$HOME/.local/bin" ]] && (( local_bin_count++ ))
      [[ "$entry" == "$TEST_FNM_DIR" ]] && (( fnm_dir_count++ ))
      [[ "$entry" == "$TEST_FNM_MULTISHELL/bin" ]] && (( fnm_multishell_count++ ))
      [[ "$entry" == "$TEST_MISSING_PATH" ]] && { print -u2 "Missing path entry survived cleanup"; exit 1; }
    done

    (( pnpm_count == 1 )) || { print -u2 "PNPM_HOME duplicated in PATH"; exit 1; }
    (( local_bin_count == 1 )) || { print -u2 "~/.local/bin duplicated in PATH"; exit 1; }
    (( fnm_dir_count == 1 )) || { print -u2 "FNM_DIR missing from PATH"; exit 1; }
    (( fnm_multishell_count == 1 )) || { print -u2 "fnm multishell path missing from PATH"; exit 1; }
  '

env -i \
  HOME="$TEST_HOME" \
  USER="$TEST_USER" \
  PATH="/opt/homebrew/bin:$TEST_PNPM_HOME:/usr/bin:/bin" \
  PNPM_HOME="$TEST_PNPM_HOME" \
  FNM_DIR="$TEST_FNM_DIR" \
  REPO_DIR="$SCRIPT_DIR" \
  TEST_PNPM_HOME="$TEST_PNPM_HOME" \
  "$ZSH_BIN" -fc '
    source "$REPO_DIR/config/zshenv.sh"

    # Simulate macOS ~/.zprofile running `brew shellenv` after ~/.zshenv.
    path=(/opt/homebrew/bin $path)
    source "$REPO_DIR/config/zshenv.sh"

    [[ "${path[1]}" == "$HOME/.local/bin" ]] || { print -u2 "Expected ~/.local/bin to be restored first after zprofile"; exit 1; }
    [[ "${path[2]}" == "$TEST_PNPM_HOME" ]] || { print -u2 "Expected PNPM_HOME to be restored before Homebrew after zprofile"; exit 1; }
  '

TEST_EXPLICIT_CODEX_HOME="$TEST_ROOT/explicit-codex-home"
env -i \
  HOME="$TEST_HOME" \
  USER="$TEST_USER" \
  PATH="/usr/bin:/bin" \
  CODEX_HOME="$TEST_EXPLICIT_CODEX_HOME" \
  REPO_DIR="$SCRIPT_DIR" \
  TEST_EXPLICIT_CODEX_HOME="$TEST_EXPLICIT_CODEX_HOME" \
  "$ZSH_BIN" -fc '
    source "$REPO_DIR/config/zshenv.sh"
    [[ "$CODEX_HOME" == "$TEST_EXPLICIT_CODEX_HOME" ]] || { print -u2 "Expected explicit CODEX_HOME to be preserved"; exit 1; }
  '

echo "Checking Codex config helper behavior..."
source "$SCRIPT_DIR/config/codex_config.sh"

DEFAULT_CODEX_HOME=$(
  env -i HOME="$TEST_HOME" PATH="/usr/bin:/bin" \
    bash -c 'source "$1"; resolve_codex_home' bash "$SCRIPT_DIR/config/codex_config.sh"
)
[[ "$DEFAULT_CODEX_HOME" == "$TEST_HOME/.codex" ]] || {
  echo "Codex helper defaulted outside home" >&2
  exit 1
}

EXPLICIT_CODEX_HOME=$(
  env -i HOME="$TEST_HOME" CODEX_HOME="$TEST_EXPLICIT_CODEX_HOME" PATH="/usr/bin:/bin" \
    bash -c 'source "$1"; resolve_codex_home' bash "$SCRIPT_DIR/config/codex_config.sh"
)
[[ "$EXPLICIT_CODEX_HOME" == "$TEST_EXPLICIT_CODEX_HOME" ]] || {
  echo "Codex helper did not preserve explicit CODEX_HOME" >&2
  exit 1
}

TEST_CODEX_HOME="$TEST_ROOT/codex-home"
ensure_codex_keymap "$TEST_CODEX_HOME" >/dev/null
ensure_codex_keymap "$TEST_CODEX_HOME" >/dev/null

grep -Fq '[tui.keymap.editor]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Missing Codex keymap section" >&2
  exit 1
}
grep -Fq 'insert_newline = ["shift-enter", "alt-enter", "ctrl-j", "ctrl-m", "enter"]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Missing Codex newline binding" >&2
  exit 1
}
[[ "$(grep -Fc 'insert_newline = ["shift-enter", "alt-enter", "ctrl-j", "ctrl-m", "enter"]' "$TEST_CODEX_HOME/config.toml")" == "1" ]] || {
  echo "Codex newline binding is not idempotent" >&2
  exit 1
}

cat > "$TEST_CODEX_HOME/config.toml" <<'EOF'
model = "gpt-5.5"

[tui.keymap.editor] # existing section comment
insert_newline = ["alt-enter"]

[projects."/tmp/example"]
trust_level = "trusted"
EOF

ensure_codex_keymap "$TEST_CODEX_HOME" >/dev/null
grep -Fq 'model = "gpt-5.5"' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper did not preserve model setting" >&2
  exit 1
}
grep -Fq '[projects."/tmp/example"]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper did not preserve project settings" >&2
  exit 1
}
[[ "$(grep -Ec '^[[:space:]]*\[tui\.keymap\.editor\]' "$TEST_CODEX_HOME/config.toml")" == "1" ]] || {
  echo "Codex helper duplicated keymap section with inline comment" >&2
  exit 1
}
grep -Fq 'insert_newline = ["shift-enter", "alt-enter", "ctrl-j", "ctrl-m", "enter"]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper did not replace old newline binding" >&2
  exit 1
}
! grep -Fq 'insert_newline = ["alt-enter"]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper left the old newline binding" >&2
  exit 1
}

cat > "$TEST_CODEX_HOME/config.toml" <<'EOF'
model = "gpt-5.4"
EOF

ensure_codex_keymap "$TEST_CODEX_HOME" >/dev/null
grep -Fq 'model = "gpt-5.4"' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper did not preserve config without keymap section" >&2
  exit 1
}
grep -Fq '[tui.keymap.editor]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper did not add missing keymap section" >&2
  exit 1
}

cat > "$TEST_CODEX_HOME/config.toml" <<'EOF'
model = "gpt-5.4"

[tui.keymap.editor]
insert_newline = [
  "alt-enter",
]

[tui.model_availability_nux]
"gpt-5.5" = 4
EOF

ensure_codex_keymap "$TEST_CODEX_HOME" >/dev/null
grep -Fq '[tui.model_availability_nux]' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper did not preserve following section after multiline binding" >&2
  exit 1
}
[[ "$(grep -Ec '^[[:space:]]*insert_newline[[:space:]]*=' "$TEST_CODEX_HOME/config.toml")" == "1" ]] || {
  echo "Codex helper left duplicate newline bindings after multiline replacement" >&2
  exit 1
}
! grep -Fxq '  "alt-enter",' "$TEST_CODEX_HOME/config.toml" || {
  echo "Codex helper left old multiline binding entries" >&2
  exit 1
}

echo "All checks passed."
