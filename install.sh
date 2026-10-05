#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/synx-shell/backups/$(date +%Y%m%d-%H%M%S)"

if [[ "${SYNX_SHELL_INSTALLER:-}" != 1 ]]; then
    echo 'Use the Synx Shell curl installer to install this configuration.' >&2
    exit 2
fi

if (($#)); then
    echo 'This deploy script is managed by the Synx Shell installer.' >&2
    exit 2
fi

backup_existing() {
    local target="$1"
    local backup="$BACKUP_ROOT/${target#"$HOME"/}"
    mkdir -p "$(dirname -- "$backup")"
    mv -- "$target" "$backup"
    printf 'Backed up %s to %s\n' "$target" "$backup"
}

install_tree() {
    local source="$1" target="$2" item
    if [[ -d "$source" && ! -L "$source" ]]; then
        mkdir -p "$target"
        while IFS= read -r -d '' item; do
            install_tree "$item" "$target/$(basename -- "$item")"
        done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
        return
    fi

    mkdir -p "$(dirname -- "$target")"
    if [[ -L "$target" ]] && [[ "$(readlink -- "$target")" == "$source" ]]; then
        return
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        backup_existing "$target"
    fi
    ln -s -- "$source" "$target"
    printf 'Installed %s\n' "$target"
}

if [[ ! -d "$ROOT_DIR/.config" ]]; then
    echo 'This checkout does not contain a .config directory.' >&2
    exit 1
fi

install_tree "$ROOT_DIR/.config" "$HOME/.config"
if [[ -d "$ROOT_DIR/.local" ]]; then
    install_tree "$ROOT_DIR/.local" "$HOME/.local"
fi

clock_format_file="$HOME/.config/synx-shell/clock-format"
polybar_config="$HOME/.config/polybar/config.ini"
if [[ -r "$clock_format_file" && -f "$polybar_config" ]]; then
    clock_format="$(<"$clock_format_file")"
    if [[ "$clock_format" == 12 || "$clock_format" == 24 ]]; then
        updated_config="$(mktemp "${TMPDIR:-/tmp}/synx-polybar.XXXXXX")"
        awk -v format="$clock_format" '
            /^\[module\/date\][[:space:]]*$/ { in_date=1; print; next }
            /^\[/ { in_date=0 }
            in_date && /^[[:space:]]*date[[:space:]]*=/ {
                if (format == 24) print "date = %H:%M"
                else print "date = %l:%M %P"
                next
            }
            in_date && /^[[:space:]]*date-alt[[:space:]]*=/ {
                if (format == 24) print "date-alt = %Y-%m-%d %H:%M:%S"
                else print "date-alt = %Y-%m-%d %I:%M:%S %p"
                next
            }
            { print }
        ' "$polybar_config" > "$updated_config"
        chmod 644 "$updated_config"
        mv -f -- "$updated_config" "$polybar_config"
        printf 'Set Polybar clock to %s-hour time.\n' "$clock_format"
    fi
fi

# The GitHub file API stores uploaded files as non-executable, so set the
# runtime bits after linking the scripts and bspwm entrypoints.
for executable in \
    "$HOME/.config/bspwm/autostart" \
    "$HOME/.config/bspwm/bspwmrc" \
    "$HOME/.config/polybar/scripts/mpris/mpris_control.sh" \
    "$HOME/.config/polybar/scripts/mpris/scroll.sh" \
    "$HOME/.local/bin/wallfinder"; do
    [[ -e "$executable" ]] && chmod +x "$executable"
done

printf '\nSynx Shell configuration linked from %s\n' "$ROOT_DIR"
if [[ -d "$BACKUP_ROOT" ]]; then
    printf 'Backups are in %s\n' "$BACKUP_ROOT"
fi
printf 'Log out and select bspwm in your display manager, or start it with startx.\n'
