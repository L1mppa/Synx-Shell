#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/bspwm-dots/backups/$(date +%Y%m%d-%H%M%S)"
INSTALL_DEPS=1

usage() {
    cat <<'EOF'
Usage: bash install.sh [--no-deps]

Install the bundled desktop configuration into $HOME. Existing files are
backed up before they are replaced. Dependencies are installed by default.

Options:
  --no-deps  Skip package installation
  -h, --help Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --no-deps) INSTALL_DEPS=0 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
done

if (( INSTALL_DEPS )); then
    bash "$ROOT_DIR/scripts/install-deps.sh"
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

printf '\nConfiguration linked from %s\n' "$ROOT_DIR"
if [[ -d "$BACKUP_ROOT" ]]; then
    printf 'Backups are in %s\n' "$BACKUP_ROOT"
fi
printf 'Log out and select bspwm in your display manager, or start it with startx.\n'
