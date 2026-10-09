#!/usr/bin/env bash
set -u

script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
player_file="${XDG_STATE_HOME:-$HOME/.local/state}/synx-shell/.curplayer.log"
mkdir -p "$(dirname -- "$player_file")"

list_players() {
    mapfile -t players < <(playerctl -l 2>/dev/null)
}

select_current_player() {
    list_players
    current_player=''
    if [[ -r "$player_file" ]]; then
        IFS= read -r current_player < "$player_file" || true
    fi
    if [[ ! " ${players[*]} " == *" $current_player "* ]]; then
        current_player="${players[0]:-}"
        printf '%s\n' "$current_player" > "$player_file"
    fi
}

player_icon() {
    case "${1,,}" in
        *chrom*) printf '' ;;
        *firefox*) printf '' ;;
        *spotify*) printf '' ;;
        *vlc*) printf '嗢' ;;
        *) printf '♫' ;;
    esac
}

select_current_player

case "${1:-}" in
    --select)
        list_players
        (("${#players[@]}" > 0)) || exit 0
        options=''
        for player in "${players[@]}"; do
            options+="$(player_icon "$player")"$'\t'"$player"$'\n'
        done
        options+=$'󰈆\tExit\n'
        choice="$(printf '%s' "$options" | rofi -dmenu -i -p 'Choose Player' -location 0 -hide-scrollbar -display-columns 2)" || exit 0
        choice="${choice#*$'\t'}"
        if [[ "$choice" == Exit || -z "$choice" ]]; then
            exit 0
        fi
        printf '%s\n' "$choice" > "$player_file"
        ;;
    --icon)
        [[ -n "$current_player" ]] && player_icon "$current_player"
        ;;
    --controls)
        [[ -n "$current_player" ]] || exit 0
        printf '%%{A1:bash %s --previous:}%%{A} %%{A1:bash %s --playpause:}󰐎%%{A} %%{A1:bash %s --next:}%%{A}\n' "$script_path" "$script_path" "$script_path"
        ;;
    --title)
        if [[ -n "$current_player" ]]; then
            title="$(playerctl --player="$current_player" metadata title 2>/dev/null || true)"
            artist="$(playerctl --player="$current_player" metadata artist 2>/dev/null || true)"
            if [[ -n "$title" ]]; then
                if [[ -n "$artist" ]]; then
                    printf '%s - %s\n' "$title" "$artist"
                else
                    printf '%s\n' "$title"
                fi
            fi
        fi
        ;;
    --process)
        [[ -n "$current_player" ]] || exit 0
        playerctl --player="$current_player" metadata --format '{{ duration(position) }}/{{ duration(mpris:length) }}' 2>/dev/null || true
        ;;
    --playpause|--next|--previous)
        [[ -n "$current_player" ]] || exit 0
        case "$1" in
            --playpause) action=play-pause ;;
            --next) action=next ;;
            --previous) action=previous ;;
        esac
        playerctl --player="$current_player" "$action" 2>/dev/null || true
        ;;
    --vc)
        [[ -n "${2:-}" ]] || exit 0
        [[ -n "$current_player" ]] || exit 0
        playerctl --player="$current_player" volume "${2:-0}" 2>/dev/null || true
        ;;
esac
