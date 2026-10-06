#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DIST_DIR="$ROOT_DIR/dist"
VERSION="$(date +%Y%m%d)"
ARCHIVE="$DIST_DIR/synx-shell-$VERSION.tar.gz"

if [[ ! -d "$ROOT_DIR/.config" ]]; then
    echo 'No .config directory found; run build.sh from the dotfiles checkout.' >&2
    exit 1
fi

mkdir -p "$DIST_DIR"
tar -czf "$ARCHIVE" -C "$ROOT_DIR" \
    --exclude=.git \
    --exclude=dist \
    README.md install.sh build.sh .xinitrc install scripts wallpapers .config .local

printf 'Built %s\n' "$ARCHIVE"
