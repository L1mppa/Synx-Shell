#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="L1mppa"
REPO_NAME="Bspwm-Dots"
REPO_BRANCH="main"
REPO_SLUG="$REPO_OWNER/$REPO_NAME"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/synx-shell"

show_banner() {
    cat <<'EOF'

   _____                  __  __          _ _
  / ____|                |  \/  |        | | |
 | (___  _   _ _ __  ___ | \  / | ___  __| | |
  \___ \| | | | '_ \/ __|| |\/| |/ _ \/ _` | |
  ____) | |_| | | | \__ \| |  | |  __/ (_| |_|
 |_____/ \__, |_| |_|___/|_|  |_|\___|\__,_(_)
          __/ |
         |___/                 SYNX SHELL

EOF
}

show_banner

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

printf 'Starting the Synx Shell installer...\n\n'
bash "$PROJECT_ROOT/install.sh" "$@"
