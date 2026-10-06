#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="L1mppa"
REPO_NAME="Synx-Shell"
REPO_BRANCH="main"
REPO_SLUG="$REPO_OWNER/$REPO_NAME"
DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/synx-shell"
REPO_DIR="$DATA_ROOT/repo"
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
    if [[ -n "${GH_TOKEN:-}" ]]; then
        command -v curl >/dev/null 2>&1 || { echo 'Synx Shell needs curl to download its files.' >&2; exit 1; }
        command -v tar >/dev/null 2>&1 || { echo 'Synx Shell needs tar to unpack its files.' >&2; exit 1; }
        mkdir -p "$DATA_ROOT" "$CACHE_ROOT"
        ARCHIVE="$(mktemp "$CACHE_ROOT/archive.XXXXXX")"
        STAGING="$(mktemp -d "$DATA_ROOT/.repo-stage.XXXXXX")"
        trap 'rm -f -- "${ARCHIVE:-}"; [[ -z "${STAGING:-}" ]] || rm -rf -- "$STAGING"' EXIT

        printf 'Downloading Synx Shell from %s...\n' "$REPO_SLUG"
        if ! curl --config <(printf 'header = "Authorization: Bearer %s"\n' "$GH_TOKEN") \
            --fail --location --silent --show-error \
            "https://api.github.com/repos/$REPO_SLUG/tarball/$REPO_BRANCH" \
            --output "$ARCHIVE"; then
            echo 'Download failed. Check GH_TOKEN access and your network connection.' >&2
            exit 1
        fi

        tar -xzf "$ARCHIVE" --strip-components=1 -C "$STAGING"
        if ! is_project_root "$STAGING"; then
            echo 'The downloaded archive is missing required Synx Shell files.' >&2
            exit 1
        fi

        PREVIOUS=""
        if [[ -e "$REPO_DIR" || -L "$REPO_DIR" ]]; then
            PREVIOUS="$DATA_ROOT/.repo-previous.$$"
            rm -rf -- "$PREVIOUS"
            mv -- "$REPO_DIR" "$PREVIOUS"
        fi
        if ! mv -- "$STAGING" "$REPO_DIR"; then
            [[ -z "$PREVIOUS" ]] || mv -- "$PREVIOUS" "$REPO_DIR"
            echo 'Could not install the downloaded Synx Shell checkout.' >&2
            exit 1
        fi
        STAGING=""
        [[ -z "$PREVIOUS" ]] || rm -rf -- "$PREVIOUS"
        PROJECT_ROOT="$REPO_DIR"
    else
        cat >&2 <<'EOF'
This repository is private. Set GH_TOKEN to a GitHub token with read access to
L1mppa/Synx-Shell, then run the curl installer again.
EOF
        exit 1
    fi
fi

# Keep linked configuration sources in stable user data storage, even when
# this script was started from a temporary checkout or a manual clone.
if [[ "$PROJECT_ROOT" != "$REPO_DIR" ]]; then
    mkdir -p "$DATA_ROOT"
    STAGING="$(mktemp -d "$DATA_ROOT/.repo-stage.XXXXXX")"
    trap '[[ -z "${STAGING:-}" ]] || rm -rf -- "$STAGING"' EXIT
    tar -cf - -C "$PROJECT_ROOT" --exclude=.git --exclude=dist . | tar -xf - -C "$STAGING"
    if ! is_project_root "$STAGING"; then
        echo 'Could not prepare a stable Synx Shell checkout.' >&2
        exit 1
    fi
    PREVIOUS=""
    if [[ -e "$REPO_DIR" || -L "$REPO_DIR" ]]; then
        PREVIOUS="$DATA_ROOT/.repo-previous.$$"
        rm -rf -- "$PREVIOUS"
        mv -- "$REPO_DIR" "$PREVIOUS"
    fi
    if ! mv -- "$STAGING" "$REPO_DIR"; then
        [[ -z "$PREVIOUS" ]] || mv -- "$PREVIOUS" "$REPO_DIR"
        echo 'Could not move Synx Shell into its stable data directory.' >&2
        exit 1
    fi
    STAGING=""
    [[ -z "$PREVIOUS" ]] || rm -rf -- "$PREVIOUS"
    PROJECT_ROOT="$REPO_DIR"
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

select_setting() {
    local prompt="$1" output_name="$2" filter='' answer start end index
    shift 2
    local -a values=("$@") matches=()
    local -n selected_ref="$output_name"
    local page_size=20 page=0 total pages

    while :; do
        matches=()
        if [[ -n "$filter" ]]; then
            mapfile -t matches < <(printf '%s\n' "${values[@]}" | grep -iF -- "$filter" || true)
        else
            matches=("${values[@]}")
        fi
        total=${#matches[@]}
        pages=$(( (total + page_size - 1) / page_size ))
        ((pages > 0)) || pages=1
        ((page < pages)) || page=$((pages - 1))
        start=$((page * page_size))
        end=$((start + page_size))
        ((end <= total)) || end=$total

        printf '\n%s' "$prompt" >&2
        [[ -n "$filter" ]] && printf ' (filter: %s)' "$filter" >&2
        printf '\n' >&2
        for ((index = start; index < end; index++)); do
            printf '  %2d) %s\n' "$((index - start + 1))" "${matches[index]}" >&2
        done
        printf '  n) next page  p) previous page  /text) search  0) cancel\n' >&2
        read -r -p 'Select: ' answer || return 1

        case "$answer" in
            n|N)
                if ((page + 1 < pages)); then page=$((page + 1)); else printf 'Last page.\n' >&2; fi
                ;;
            p|P)
                if ((page > 0)); then page=$((page - 1)); else printf 'First page.\n' >&2; fi
                ;;
            /*) filter="${answer#/}"; page=0 ;;
            0|q|Q) return 1 ;;
            '' ) ;;
            *)
                if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= end - start)); then
                    selected_ref="${matches[start + answer - 1]}"
                    return 0
                fi
                printf 'Choose a listed number, page control, or search.\n' >&2
                ;;
        esac
    done
}

get_timezones() {
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl list-timezones 2>/dev/null || printf 'UTC\n'
        printf 'UTC\n'
        return 0
    fi
    if [[ -r /usr/share/zoneinfo/zone1970.tab ]]; then
        awk -F '\t' '!/^#/ && NF >= 3 {print $3}' /usr/share/zoneinfo/zone1970.tab
    elif [[ -r /usr/share/zoneinfo/zone.tab ]]; then
        awk -F '\t' '!/^#/ && NF >= 3 {print $3}' /usr/share/zoneinfo/zone.tab
    fi
    printf 'UTC\n'
}

get_keyboard_layouts() {
    if command -v localectl >/dev/null 2>&1; then
        localectl list-x11-keymap-layouts --no-pager 2>/dev/null | tr ' ' '\n' || true
    fi
    if [[ -r /usr/share/X11/xkb/rules/base.lst ]]; then
        awk '/^! layout/{in_layouts=1; next} /^!/{if (in_layouts) exit} in_layouts && NF {print $1}' \
            /usr/share/X11/xkb/rules/base.lst
    fi
}

configure_settings() {
    local language layout timezone clock current_layout current_timezone answer
    local -a timezones=() layouts=()
    language="${LANG:-C.UTF-8}"
    current_layout="$(localectl status --no-pager 2>/dev/null | sed -n 's/^[[:space:]]*X11 Layout: *//p' | head -n 1 || true)"
    timezone="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
    [[ -n "$current_layout" ]] || current_layout=us
    [[ -n "$timezone" ]] || timezone=UTC
    current_timezone="$timezone"

    printf '\nRegional settings (press Enter to keep the current value).\n'
    read -r -p "Language/locale [$language]: " answer
    [[ -n "$answer" ]] && language="$answer"
    mapfile -t layouts < <(get_keyboard_layouts | sed '/^[[:space:]]*$/d' | sort -u)
    mapfile -t timezones < <(get_timezones | sed '/^[[:space:]]*$/d' | sort -u)
    if ((${#layouts[@]})); then
        printf 'Current X11 keyboard layout: %s\n' "$current_layout"
        if select_setting 'Choose an X11 keyboard layout (search with /text)' layout "${layouts[@]}"; then
            :
        else
            layout="$current_layout"
        fi
    else
        read -r -p "Keyboard layout [$current_layout]: " answer
        layout="${answer:-$current_layout}"
    fi
    if ((${#timezones[@]})); then
        printf 'Current timezone: %s\n' "$timezone"
        if select_setting 'Choose a timezone; search UTC explicitly with /UTC' timezone "${timezones[@]}"; then
            :
        else
            timezone="$current_timezone"
            [[ -n "$timezone" ]] || timezone=UTC
        fi
    else
        read -r -p "Timezone [$timezone]: " answer
        timezone="${answer:-$timezone}"
    fi

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
        mapfile -d '' images < <(find "$PROJECT_ROOT/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)
    fi
    if ((${#images[@]} == 0)); then
        echo 'There are no wallpaper files to copy.'
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
            SYNX_SHELL_INSTALLER=1 bash "$PROJECT_ROOT/install.sh"
            exit $?
            ;;
        q|Q) exit 0 ;;
        *) echo 'Choose 1, 2, 3, 4, or q.' >&2 ;;
    esac
done
