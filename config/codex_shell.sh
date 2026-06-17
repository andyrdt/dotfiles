#!/bin/zsh
# Interactive Codex shell helpers.

cleanup_codex_arg0_tmp() {
    emulate -L zsh
    setopt null_glob

    local codex_home="${CODEX_HOME:-$HOME/.codex}"
    local arg0_dir="$codex_home/tmp/arg0"
    [[ -d "$arg0_dir" ]] || return 0

    # Codex may leave arg0 directories on networked homes. Keep directories
    # whose lock is held by a live process; remove the rest before startup.
    find "$arg0_dir" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null || true

    local dir lock_file
    for dir in "$arg0_dir"/codex-arg0*(N/); do
        lock_file="$dir/.lock"
        if [[ ! -e "$lock_file" ]]; then
            rm -rf "$dir" 2>/dev/null || true
        elif command -v fuser >/dev/null 2>&1; then
            fuser "$lock_file" >/dev/null 2>&1 || rm -rf "$dir" 2>/dev/null || true
        else
            find "$dir" -maxdepth 0 -mtime +1 -exec rm -rf {} \; 2>/dev/null || true
        fi
    done
}

codex() {
    cleanup_codex_arg0_tmp
    command codex "$@"
}
