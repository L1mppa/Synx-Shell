#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="L1mppa"
REPO_NAME="Bspwm-Dots"
REPO_BRANCH="main"
REPO_SLUG="$REPO_OWNER/$REPO_NAME"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/synx-shell"

show_banner() {
    if [[ -f "$PROJECT_ROOT/install/logo.ans" ]]; then
        printf '%b\n' "$(cat -- "$PROJECT_ROOT/install/logo.ans")"
    else
        printf '\n\033[1;34m  SYNX SHELL\033[0m\n  BSPWM desktop installer\n\n'
    fi
}

is_project_root() {
    [[ -f "$1/install.sh" && -f "$1/scripts/install-deps.sh" && -d "$1/.config" ]]
}

PROJECT_ROOT=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    CANDIDATE="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
    if is_project_root "$CANDIDATE"; then
        PROJECT_ROOT="$CANDIDATE"
    fi
fi

if [[ -z "$PROJECT_ROOT" ]]; then
    command -v curl >/dev/null 2>&1 || { echo 'Synx Shell needs curl to download its files.' >&2; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo 'Synx Shell needs tar to unpack its files.' >&2; exit 1; }

    if [[ -z "${GH_TOKEN:-}" ]]; then
        cat >&2 <<'EOF'
This repository is private. Set GH_TOKEN to a GitHub token with read access to
L1mppa/Bspwm-Dots, then run the curl installer again.
EOF
        exit 1
    fi

    mkdir -p "$CACHE_ROOT"
    SOURCE_DIR="$(mktemp -d "$CACHE_ROOT/source.XXXXXX")"
    ARCHIVE="$(mktemp "$CACHE_ROOT/archive.XXXXXX")"
    trap 'rm -f -- "$ARCHIVE"' EXIT

    printf 'Downloading Synx Shell from %s...\n' "$REPO_SLUG"
    if ! curl --config <(printf 'header = "Authorization: Bearer %s"\n' "$GH_TOKEN") \
        --fail --location --silent --show-error \
        "https://api.github.com/repos/$REPO_SLUG/tarball/$REPO_BRANCH" \
        --output "$ARCHIVE"; then
        echo 'Download failed. Check GH_TOKEN access and your network connection.' >&2
        exit 1
    fi

    tar -xzf "$ARCHIVE" --strip-components=1 -C "$SOURCE_DIR"
    if ! is_project_root "$SOURCE_DIR"; then
        echo 'The downloaded archive is missing required Synx Shell files.' >&2
        exit 1
    fi
    PROJECT_ROOT="$SOURCE_DIR"
fi

show_banner

as_root() {
    if (( EUID == 0 )); then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo 'This setting needs administrator access; install sudo or run the installer as root.' >&2
        return 1
    fi
}

configure_settings() {
    local language layout timezone clock current_layout current_timezone answer
    language="${LANG:-C.UTF-8}"
    current_layout="$(localectl status --no-pager 2>/dev/null | sed -n 's/^[[:space:]]*X11 Layout: *//p' | head -n 1 || true)"
    timezone="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
    [[ -n "$current_layout" ]] || current_layout=us
    [[ -n "$timezone" ]] || timezone=UTC

    printf '\nRegional settings (press Enter to keep the current value).\n'
    read -r -p "Language/locale [$language]: " answer
    [[ -n "$answer" ]] && language="$answer"
    read -r -p "Keyboard layout [$current_layout]: " answer
    layout="${answer:-$current_layout}"
    read -r -p "Timezone [$timezone]: " answer
    timezone="${answer:-$timezone}"

    if command -v localectl >/dev/null 2>&1; then
        if [[ "$language" != "${LANG:-C.UTF-8}" ]] && ! as_root localectl set-locale "LANG=$language"; then
            echo 'Could not set the system locale; check that it is generated on this system.' >&2
        fi
        if [[ "$layout" != "$current_layout" ]] && ! as_root localectl set-x11-keymap "$layout"; then
            echo 'Could not set the X11 keyboard layout.' >&2
        fi
    else
        echo 'localectl is unavailable; language and keyboard settings were not changed.' >&2
    fi

    if command -v timedatectl >/dev/null 2>&1 && [[ "$timezone" != "$(timedatectl show --property=Timezone --value 2>/dev/null || true)" ]]; then
        if ! as_root timedatectl set-timezone "$timezone"; then
            echo 'Could not set the timezone.' >&2
        fi
    elif ! command -v timedatectl >/dev/null 2>&1; then
        echo 'timedatectl is unavailable; the system timezone was not changed.' >&2
    fi

    while :; do
        read -r -p 'Polybar clock format, 12 or 24 [12]: ' clock
        clock="${clock:-12}"
        if [[ "$clock" == 12 || "$clock" == 24 ]]; then
            break
        fi
        echo 'Choose 12 or 24.' >&2
    done
    mkdir -p "$HOME/.config/synx-shell"
    printf '%s\n' "$clock" > "$HOME/.config/synx-shell/clock-format"
    echo 'Regional settings saved.'
}

install_wallpapers() {
    local destination image count=0
    local -a images=()
    destination="${WALLFINDER_DIR:-$HOME/Wallpapers}"
    if [[ -d "$PROJECT_ROOT/wallpapers" ]]; then
        mapfile -d '' images < <(find "$PROJECT_ROOT/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)
    fi
    if ((${#images[@]} == 0)); then
        echo "No wallpaper images are bundled in this repository yet. Add images under $PROJECT_ROOT/wallpapers and run this option again."
        return 0
    fi

    mkdir -p "$destination"
    for image in "${images[@]}"; do
        if [[ -e "$destination/$(basename -- "$image")" ]]; then
            printf 'Keeping existing %s\n' "$destination/$(basename -- "$image")"
        else
            cp -- "$image" "$destination/"
            ((count += 1))
            printf 'Installed %s\n' "$destination/$(basename -- "$image")"
        fi
    done
    printf 'Installed %s wallpaper(s) to %s\n' "$count" "$destination"
}

while :; do
    printf '\n\033[1;34mSynx Shell Installer\033[0m\n'
    printf '  1) Settings: language, keyboard, timezone, and clock\n'
    printf '  2) Install dependencies\n'
    printf '  3) Install repository wallpapers\n'
    printf '  4) Install Synx Shell and deploy configs\n'
    printf '  q) Quit\n'
    read -r -p 'Choose a step: ' choice || exit 0

    case "$choice" in
        1) configure_settings ;;
        2) bash "$PROJECT_ROOT/scripts/install-deps.sh" ;;
        3) install_wallpapers ;;
        4)
            printf '\nDeploying Synx Shell...\n\n'
            bash "$PROJECT_ROOT/install.sh" --no-deps
            exit $?
            ;;
        q|Q) exit 0 ;;
        *) echo 'Choose 1, 2, 3, 4, or q.' >&2 ;;
    esac
done
