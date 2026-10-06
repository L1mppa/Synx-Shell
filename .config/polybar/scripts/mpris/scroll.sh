#!/bin/bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# see man zscroll for documentation of the following parameters
zscroll -l 30 \
  --delay 0.1 \
  --match-command "bash $script_dir/mpris_control.sh --title" \
  --update-check true "bash $script_dir/mpris_control.sh --title" &

wait

# --match-text "Playing" "--scroll 1" \
# --match-text "Paused" "--scroll 0" \
