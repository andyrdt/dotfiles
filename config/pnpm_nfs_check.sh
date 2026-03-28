#!/bin/bash
# On NFS, a running binary that pnpm already deleted becomes a .nfs* file.
# pnpm hangs trying to rmdir the parent. This detects processes running from
# the pnpm global store and offers to kill them before an update attempt.
#
# Returns 0 = safe to proceed, 1 = user chose to skip.

check_stale_pnpm_processes() {
    local pnpm_store="${PNPM_HOME:-$HOME/.local/share/pnpm}/global/5/.pnpm"
    [[ -d "$pnpm_store" ]] || return 0

    local pids=()
    local pid exe
    while IFS= read -r pid; do
        [[ -z "$pid" ]] && continue
        exe=$(readlink "/proc/$pid/exe" 2>/dev/null) || continue
        [[ "$exe" == "$pnpm_store"/* ]] || continue
        pids+=("$pid")
    done < <(ps -u "$(id -u)" -o pid= 2>/dev/null)
    (( ${#pids[@]} == 0 )) && return 0

    echo ""
    echo "Running processes would block pnpm update (NFS file handles):"
    for pid in "${pids[@]}"; do
        ps -p "$pid" -o pid=,args= 2>/dev/null | sed 's/^/  /'
    done
    echo ""

    if [[ ! -t 0 ]]; then
        echo "Non-interactive shell — skipping. Kill manually: ${pids[*]}"
        return 1
    fi

    local response
    echo -n "Kill these processes so pnpm can proceed? (y/n): "
    if [[ -n "$ZSH_VERSION" ]]; then
        read -r -k 1 response
    else
        read -r -n 1 response
    fi
    echo
    if [[ "$response" =~ ^[Yy]$ ]]; then
        kill "${pids[@]}" 2>/dev/null || true
        sleep 2
        return 0
    fi
    echo "Skipping pnpm update."
    return 1
}
