#!/usr/bin/env bash
# Codex CLI configuration helpers.

resolve_codex_home() {
    if [ -n "${CODEX_HOME:-}" ]; then
        printf '%s\n' "$CODEX_HOME"
        return 0
    fi

    printf '%s\n' "$HOME/.codex"
}

ensure_codex_keymap() {
    local codex_home="${1:-$(resolve_codex_home)}"
    local config_file="$codex_home/config.toml"
    local keymap_line='insert_newline = ["shift-enter", "alt-enter", "ctrl-j", "ctrl-m", "enter"]'

    mkdir -p "$codex_home"
    chmod 700 "$codex_home" 2>/dev/null || true

    if [ ! -e "$config_file" ]; then
        printf '[tui.keymap.editor]\n%s\n' "$keymap_line" > "$config_file"
    else
        local tmp_file
        tmp_file="$(mktemp)"
        awk -v keymap_line="$keymap_line" '
            BEGIN {
                in_section = 0
                saw_section = 0
                wrote_binding = 0
                skip_old_binding = 0
            }

            function write_missing_binding() {
                if (in_section && !wrote_binding) {
                    print keymap_line
                    wrote_binding = 1
                }
            }

            skip_old_binding {
                if ($0 ~ /\]/) {
                    skip_old_binding = 0
                }
                next
            }

            /^[[:space:]]*\[tui\.keymap\.editor\][[:space:]]*(#.*)?$/ {
                write_missing_binding()
                in_section = 1
                saw_section = 1
                wrote_binding = 0
                print
                next
            }

            /^[[:space:]]*\[/ {
                write_missing_binding()
                in_section = 0
            }

            in_section && /^[[:space:]]*insert_newline[[:space:]]*=/ {
                if (!wrote_binding) {
                    print keymap_line
                    wrote_binding = 1
                }
                if ($0 ~ /\[/ && $0 !~ /\]/) {
                    skip_old_binding = 1
                }
                next
            }

            { print }

            END {
                write_missing_binding()
                if (!saw_section) {
                    print ""
                    print "[tui.keymap.editor]"
                    print keymap_line
                }
            }
        ' "$config_file" > "$tmp_file"

        if cmp -s "$config_file" "$tmp_file"; then
            rm -f "$tmp_file"
        else
            mv "$tmp_file" "$config_file"
        fi
    fi

    chmod 600 "$config_file" 2>/dev/null || true
    printf '%s\n' "$config_file"
}
