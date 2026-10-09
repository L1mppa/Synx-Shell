#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="L1mppa"
REPO_NAME="Synx-Shell"
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
    command -v curl >/dev/null 2>&1 || { echo 'Synx Shell needs curl to download its files.' >&2; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo 'Synx Shell needs tar to unpack its files.' >&2; exit 1; }
    mkdir -p "$DATA_ROOT" "$CACHE_ROOT"
    ARCHIVE="$(mktemp "$CACHE_ROOT/archive.XXXXXX")"
    STAGING="$(mktemp -d "$DATA_ROOT/.repo-stage.XXXXXX")"
    trap 'rm -f -- "${ARCHIVE:-}"; [[ -z "${STAGING:-}" ]] || rm -rf -- "$STAGING"' EXIT

    release_tag="${SYNX_SHELL_TAG:-v0.1.7}"
    if [[ ! "$release_tag" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo 'Invalid Synx Shell tag. Set SYNX_SHELL_TAG to a valid release tag.' >&2
        exit 1
    fi

    printf 'Downloading Synx Shell %s from %s...\n' "$release_tag" "$REPO_SLUG"
    if ! curl --fail --location --silent --show-error \
        "https://codeload.github.com/$REPO_SLUG/tar.gz/refs/tags/$release_tag" \
        --output "$ARCHIVE"; then
        echo 'Download failed. Check the release tag and your network connection.' >&2
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
        return 0
    fi
    if [[ -d /usr/share/zoneinfo ]]; then
        find /usr/share/zoneinfo -mindepth 1 \( -type f -o -type l \) \
            ! -path '/usr/share/zoneinfo/posix/*' \
            ! -path '/usr/share/zoneinfo/right/*' \
            ! -name zone.tab ! -name zone1970.tab ! -name iso3166.tab \
            ! -name tzdata.zi ! -name leapseconds ! -name leap-seconds.list \
            ! -name localtime ! -name posixrules -printf '%P\n'
    fi
    printf 'UTC\n'
}

get_locales() {
    if command -v localectl >/dev/null 2>&1; then
        localectl list-locales --no-pager 2>/dev/null || true
    fi
    if command -v locale >/dev/null 2>&1; then
        locale -a 2>/dev/null || true
    fi
    if [[ -r /usr/share/i18n/SUPPORTED ]]; then
        awk '$2 == "UTF-8" {print $1}' /usr/share/i18n/SUPPORTED
    fi
    printf 'C\nC.UTF-8\nPOSIX\n'
}

get_keyboard_layouts() {
    if command -v localectl >/dev/null 2>&1; then
        localectl list-x11-keymap-layouts --no-pager 2>/dev/null | tr ' ' '\n' || true
    fi
    if [[ -r /usr/share/X11/xkb/rules/base.lst ]]; then
        awk '/^! layout/{in_layouts=1; next} /^!/{if (in_layouts) exit} in_layouts && NF {print $1}' \
            /usr/share/X11/xkb/rules/base.lst
    fi
    printf 'us\n'
}

locale_is_generated() {
    local wanted="$1"
    command -v locale >/dev/null 2>&1 || return 1
    locale -a 2>/dev/null | awk -v wanted="$wanted" '
        function normalized(value) {
            value = tolower(value)
            sub(/\.utf8$/, ".utf-8", value)
            return value
        }
        normalized($0) == normalized(wanted) { found=1 }
        END { exit !found }
    '
}

prepare_locale() {
    local selected="$1" entry temporary_file
    locale_is_generated "$selected" && return 0
    command -v locale-gen >/dev/null 2>&1 || return 0
    [[ -r /etc/locale.gen && -r /usr/share/i18n/SUPPORTED ]] || return 0

    entry="$(awk -v wanted="$selected" '$1 == wanted && $2 == "UTF-8" {print; exit}' \
        /usr/share/i18n/SUPPORTED)"
    [[ -n "$entry" ]] || return 0
    temporary_file="$(mktemp "${TMPDIR:-/tmp}/synx-shell-locale.XXXXXX")"
    awk -v entry="$entry" '
        {
            uncommented = $0
            sub(/^[[:space:]]*#[[:space:]]*/, "", uncommented)
            if (uncommented == entry) {
                print entry
                found = 1
            } else {
                print $0
            }
        }
        END { if (!found) print entry }
    ' /etc/locale.gen > "$temporary_file"
    if ! as_root install -m 644 "$temporary_file" /etc/locale.gen \
        || ! as_root locale-gen; then
        rm -f -- "$temporary_file"
        return 1
    fi
    rm -f -- "$temporary_file"
}

configure_settings() {
    local language layout timezone clock clock_choice current_layout current_timezone current_language current_clock
    local -a locales=() timezones=() layouts=() clock_choices=('12-hour (AM/PM)' '24-hour')
    current_language="$(localectl status --no-pager 2>/dev/null | sed -n 's/^[[:space:]]*System Locale: LANG=//p' | head -n 1 || true)"
    [[ -n "$current_language" ]] || current_language="${LANG:-C.UTF-8}"
    current_layout="$(localectl status --no-pager 2>/dev/null | sed -n 's/^[[:space:]]*X11 Layout: *//p' | head -n 1 || true)"
    timezone="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
    [[ -n "$current_layout" ]] || current_layout=us
    [[ -n "$timezone" ]] || timezone=UTC
    current_timezone="$timezone"
    current_clock=12
    if [[ -r "$HOME/.config/synx-shell/clock-format" ]]; then
        IFS= read -r current_clock < "$HOME/.config/synx-shell/clock-format" || true
        [[ "$current_clock" == 24 ]] || current_clock=12
    fi

    printf '\nChoose each setting from the available system lists. Search with /text; 0 keeps the current value.\n'
    mapfile -t locales < <(get_locales | sed '/^[[:space:]]*$/d' | sort -fu)
    [[ " ${locales[*]} " == *" $current_language "* ]] || locales+=("$current_language")
    mapfile -t layouts < <(get_keyboard_layouts | sed '/^[[:space:]]*$/d' | sort -u)
    [[ " ${layouts[*]} " == *" $current_layout "* ]] || layouts+=("$current_layout")
    mapfile -t timezones < <(get_timezones | sed '/^[[:space:]]*$/d' | sort -u)
    [[ " ${timezones[*]} " == *" $current_timezone "* ]] || timezones+=("$current_timezone")
    language="$current_language"
    layout="$current_layout"
    timezone="$current_timezone"
    clock="$current_clock"

    if select_setting 'Choose a language/locale' language "${locales[@]}"; then :; fi
    select_setting 'Choose an X11 keyboard layout' layout "${layouts[@]}" || true
    select_setting 'Choose a timezone' timezone "${timezones[@]}" || true
    if [[ "$current_clock" == 24 ]]; then
        clock_choices=('12-hour (AM/PM)' '24-hour')
    fi
    if select_setting 'Choose the Polybar clock format' clock_choice "${clock_choices[@]}"; then
        [[ "$clock_choice" == '24-hour' ]] && clock=24 || clock=12
    fi

    if [[ "$language" != "$current_language" ]]; then
        if ! prepare_locale "$language"; then
            echo 'Could not generate the selected locale; it is saved for the Synx Shell session.' >&2
        elif command -v localectl >/dev/null 2>&1 && ! as_root localectl set-locale "LANG=$language"; then
            echo 'Could not set the system locale; it is saved for the Synx Shell session.' >&2
        fi
    fi

    if command -v localectl >/dev/null 2>&1; then
        if [[ "$layout" != "$current_layout" ]] && ! as_root localectl set-x11-keymap "$layout"; then
            echo 'Could not set the X11 keyboard layout.' >&2
        fi
    else
        echo 'localectl is unavailable; locale and keyboard selections will apply to the Synx Shell session.' >&2
    fi

    if command -v timedatectl >/dev/null 2>&1 && [[ "$timezone" != "$(timedatectl show --property=Timezone --value 2>/dev/null || true)" ]]; then
        if ! as_root timedatectl set-timezone "$timezone"; then
            echo 'Could not set the timezone.' >&2
        fi
    elif ! command -v timedatectl >/dev/null 2>&1; then
        echo 'timedatectl is unavailable; the timezone selection will apply to the Synx Shell session.' >&2
    fi

    mkdir -p "$HOME/.config/synx-shell"
    printf '%s\n' "$language" > "$HOME/.config/synx-shell/locale"
    printf '%s\n' "$layout" > "$HOME/.config/synx-shell/keyboard-layout"
    printf '%s\n' "$timezone" > "$HOME/.config/synx-shell/timezone"
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
