#!/bin/bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if command -v zscroll >/dev/null 2>&1; then
  # See `man zscroll` for documentation of these parameters.
  zscroll -l 30 \
    --delay 0.1 \
    --match-command "bash $script_dir/mpris_control.sh --title" \
    --update-check true "bash $script_dir/mpris_control.sh --title" &
  wait
else
  printf 'Polybar: zscroll is missing; showing the MPRIS title without scrolling.\n' >&2
  while :; do
    bash "$script_dir/mpris_control.sh" --title 2>/dev/null || true
    sleep 1
  done
fi

# --match-text "Playing" "--scroll 1" \
# --match-text "Paused" "--scroll 0" \
