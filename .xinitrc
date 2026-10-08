#!/bin/sh
settings="$HOME/.config/synx-shell"

if [ -r "$settings/locale" ]; then
    IFS= read -r locale_setting < "$settings/locale"
    case "$locale_setting" in
        ''|*[!A-Za-z0-9_.@+-]*) ;;
        *) LANG=$locale_setting; export LANG ;;
    esac
fi

if [ -r "$settings/timezone" ]; then
    IFS= read -r timezone_setting < "$settings/timezone"
    case "$timezone_setting" in
        ''|*[!A-Za-z0-9_./+-]*) ;;
        *) TZ=$timezone_setting; export TZ ;;
    esac
fi

if [ -r "$settings/keyboard-layout" ]; then
    IFS= read -r keyboard_layout < "$settings/keyboard-layout"
    case "$keyboard_layout" in
        ''|*[!A-Za-z0-9_+-]*) ;;
        *)
            if command -v setxkbmap >/dev/null 2>&1; then
                setxkbmap "$keyboard_layout" || printf 'Synx Shell: could not apply keyboard layout %s\n' "$keyboard_layout" >&2
            else
                printf 'Synx Shell: setxkbmap is unavailable; could not apply keyboard layout %s\n' "$keyboard_layout" >&2
            fi
            ;;
    esac
fi

if command -v dbus-run-session >/dev/null 2>&1; then
    exec dbus-run-session bspwm
elif command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session bspwm
else
    printf 'Synx Shell: no D-Bus session launcher found; starting bspwm without a session bus.\n' >&2
    exec bspwm
fi
