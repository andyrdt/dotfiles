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

echo "All checks passed."
