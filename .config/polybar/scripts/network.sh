#!/usr/bin/env bash
set -u

if ! command -v ip >/dev/null 2>&1; then
    printf 'NET offline'
    exit 0
fi

interface="$(ip -o route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") {print $(i + 1); exit}}')"
if [[ -z "$interface" ]]; then
    printf 'NET offline'
    exit 0
fi

address="$(ip -o -4 addr show dev "$interface" scope global 2>/dev/null | awk 'NR == 1 {sub(/\/.*/, "", $4); print $4}')"
[[ -n "$address" ]] || address='connected'
if [[ -d "/sys/class/net/$interface/wireless" ]]; then
    ssid="$(iwgetid -r 2>/dev/null || true)"
    printf 'WIFI %s %s' "${ssid:-$interface}" "$address"
else
    printf 'NET %s %s' "$interface" "$address"
fi
