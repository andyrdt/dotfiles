#!/bin/bash
# On NFS, a running binary that pnpm already deleted becomes a .nfs* file.
# pnpm hangs trying to rmdir the parent. This finds and offers to kill those processes.
#
# Returns 0 = safe to proceed, 1 = user chose to skip.

check_stale_pnpm_processes() {
    local pnpm_pnpm="${PNPM_HOME:-$HOME/.local/share/pnpm}/global/5/.pnpm"
    [[ -d "$pnpm_pnpm" ]] || return 0
    command -v fuser &>/dev/null || return 0

    local nfs_files
    nfs_files=$(find "$pnpm_pnpm" -name ".nfs*" 2>/dev/null)
    [[ -z "$nfs_files" ]] && return 0

    # Collect unique PIDs
    local pids=""
    while IFS= read -r f; do
        local pid
        pid=$(fuser "$f" 2>/dev/null | grep -oE '[0-9]+' | head -1)
        [[ -z "$pid" ]] && continue
        case " $pids " in
            *" $pid "*) ;;
            *) pids="$pids $pid" ;;
        esac
    done <<< "$nfs_files"
    pids="${pids# }"
    [[ -z "$pids" ]] && return 0

    echo ""
    echo "Running processes are blocking pnpm updates (stale NFS handles):"
    for pid in $pids; do
        ps -p "$pid" -o pid=,args= 2>/dev/null | sed 's/^/  /'
    done
    echo ""

    if [[ ! -t 0 ]]; then
        echo "Non-interactive shell — skipping. Kill manually: $pids"
        return 1
    fi

    echo -n "Kill these processes so pnpm can proceed? (y/n): "
    read -r -n 1 response
    echo
    if [[ "$response" =~ ^[Yy]$ ]]; then
        kill $pids 2>/dev/null || true
        sleep 2
        return 0
    fi
    echo "Skipping pnpm update."
    return 1
}
