#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
README="$ROOT_DIR/README.md"
INSTALLER="$ROOT_DIR/install/install.sh"

usage() {
    printf 'Usage: %s vMAJOR.MINOR.PATCH\n' "$(basename -- "$0")" >&2
    exit 2
}

[[ $# == 1 ]] || usage
new_tag="$1"
[[ "$new_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage

installer_tag="$(sed -n 's/^[[:space:]]*release_tag="${SYNX_SHELL_TAG:-\(v[0-9.]*\)}"$/\1/p' "$INSTALLER")"
readme_tag="$(sed -n 's#.*raw.githubusercontent.com/L1mppa/Synx-Shell/\(v[0-9.]*\)/install/install.sh.*#\1#p' "$README")"
if [[ -z "$installer_tag" || "$installer_tag" != "$readme_tag" ]]; then
    echo 'README and installer release tags are missing or do not match.' >&2
    exit 1
fi

sed -i "s/$installer_tag/$new_tag/g" "$INSTALLER" "$README"
printf 'Updated README and installer pins: %s -> %s\n' "$installer_tag" "$new_tag"
printf 'Review the changes, commit them, then create and publish tag %s.\n' "$new_tag"
