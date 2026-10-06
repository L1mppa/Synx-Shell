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
if [[ -f "$ROOT_DIR/.xinitrc" ]]; then
    install_tree "$ROOT_DIR/.xinitrc" "$HOME/.xinitrc"
fi

"$HOME/.local/bin/synx-shell-runtime"

# Older curl installs extracted source snapshots here. All deployed links now
# resolve to the stable checkout, so those stale snapshots can be removed.
legacy_cache="${XDG_CACHE_HOME:-$HOME/.cache}/synx-shell"
if [[ -d "$legacy_cache" ]]; then
    find "$legacy_cache" -mindepth 1 -maxdepth 1 -type d -name 'source.*' -exec rm -rf -- {} +
fi

printf '\nSynx Shell configuration linked from %s\n' "$ROOT_DIR"
if [[ -d "$BACKUP_ROOT" ]]; then
    printf 'Backups are in %s\n' "$BACKUP_ROOT"
fi
printf 'Log out and select bspwm in your display manager, or start it with startx.\n'
