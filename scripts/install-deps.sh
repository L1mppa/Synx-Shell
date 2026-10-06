#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/install-deps.sh

Detect a supported package manager and install bspwm, the bundled desktop
tools, and the command line tools used by wallfinder and Polybar.
On Arch Linux, an installed yay or paru helper is used for AUR packages;
otherwise yay is built from the AUR when needed.
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    "") ;;
    *) usage >&2; exit 2 ;;
esac

if command -v pacman >/dev/null 2>&1; then
    manager=pacman
elif command -v apt-get >/dev/null 2>&1; then
    manager=apt
elif command -v dnf >/dev/null 2>&1; then
    manager=dnf
elif command -v zypper >/dev/null 2>&1; then
    manager=zypper
elif command -v xbps-install >/dev/null 2>&1; then
    manager=xbps
elif command -v apk >/dev/null 2>&1; then
    manager=apk
else
    echo 'Could not detect a supported package manager (pacman, apt, dnf, zypper, xbps, apk).' >&2
    exit 1
fi

as_root() {
    if (( EUID == 0 )); then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo 'This installer needs root access; install sudo or run it as root.' >&2
        return 1
    fi
}

install_packages() {
    case "$manager" in
        pacman)
            local -a pacman_options=(--needed)
            if pacman -S --help 2>&1 | grep -q -- '--ask'; then
                pacman_options+=(--ask=4)
            else
                echo 'This pacman does not expose --ask in install help; package conflicts will use pacman’s normal prompts.' >&2
            fi
            printf 'Arch package installation runs pacman -Syu, which upgrades the whole system. Review the transaction and confirm it in pacman.\n' >&2
            as_root pacman -Syu "${pacman_options[@]}" "$@"
            ;;
        apt)
            local package
            for package in "$@"; do
                if ! as_root apt-get install -y "$package"; then
                    printf 'Warning: apt could not install %s; continuing with the remaining packages.\n' "$package" >&2
                fi
            done
            ;;
        dnf)
            local package
            for package in "$@"; do
                if ! as_root dnf install -y "$package"; then
                    printf 'Warning: dnf could not install %s; continuing with the remaining packages.\n' "$package" >&2
                fi
            done
            ;;
        zypper|xbps|apk)
            local package
            for package in "$@"; do
                case "$manager" in
                    zypper) if ! as_root zypper --non-interactive install "$package"; then printf 'Warning: zypper could not install %s; continuing.\n' "$package" >&2; fi ;;
                    xbps) if ! as_root xbps-install -y "$package"; then printf 'Warning: xbps could not install %s; continuing.\n' "$package" >&2; fi ;;
                    apk) if ! as_root apk add "$package"; then printf 'Warning: apk could not install %s; continuing.\n' "$package" >&2; fi ;;
                esac
            done
            ;;
    esac
}

case "$manager" in
    pacman)
        repo_packages=(bash git base-devel bspwm sxhkd alacritty feh picom dunst polybar rofi fastfetch fzf chafa ueberzugpp libnotify playerctl pamixer flameshot matugen python iproute2 xorg-server xorg-xinit xorg-setxkbmap xclip xdotool ttf-iosevka-nerd ttf-terminus-nerd)
        aur_packages=(zscroll greenclip bemoji rofi-power-menu dmenu-bluetooth)

        helper=''
        if command -v yay >/dev/null 2>&1; then
            helper=yay
        elif command -v paru >/dev/null 2>&1; then
            helper=paru
        fi

        install_packages "${repo_packages[@]}"
        if [[ -z "$helper" ]]; then
            if (( EUID == 0 )); then
                echo 'AUR helpers must be built as a regular user. Run this script as your normal user with sudo available.' >&2
                exit 1
            fi
            echo 'No yay or paru found; building yay from the AUR.'
            build_dir="$(mktemp -d "${TMPDIR:-/tmp}/synx-shell-yay.XXXXXX")"
            trap 'rm -rf -- "$build_dir"' EXIT
            if ! git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"; then
                echo 'Could not download yay from the AUR. Install yay or paru manually, then rerun this step.' >&2
                exit 1
            fi
            if ! (cd "$build_dir/yay" && makepkg -si --noconfirm); then
                echo 'Could not build or install yay. Install yay or paru manually, then rerun this step.' >&2
                exit 1
            fi
            helper=yay
        fi
        helper_options=(--needed --noconfirm)
        if pacman -S --help 2>&1 | grep -q -- '--ask'; then
            helper_options+=(--ask=4)
        fi
        "$helper" -S "${helper_options[@]}" "${aur_packages[@]}"
        ;;
    apt)
        as_root apt-get update
        install_packages bash git build-essential iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify-bin playerctl pamixer flameshot python3 xorg xinit x11-xkb-utils xclip xdotool fonts-iosevka fonts-terminus
        echo 'Matugen, Fastfetch, ueberzugpp, AUR-only extras, and Nerd Font variants may need manual installation on Debian/Ubuntu; Polybar glyphs may be missing.'
        ;;
    dnf)
        install_packages bash git make gcc iproute bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3 xorg-x11-server-Xorg xorg-x11-xinit xorg-x11-xkb-utils xclip xdotool iosevka-fonts terminus-fonts
        echo 'Matugen, Fastfetch, ueberzugpp, Nerd Font variants, and AUR-only extras may need manual installation on Fedora; Polybar glyphs may be missing.'
        ;;
    zypper)
        install_packages bash git make gcc iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify-tools playerctl pamixer flameshot python3 xorg-x11-server xinit setxkbmap xclip xdotool iosevka-fonts terminus-fonts
        echo 'Matugen, Fastfetch, ueberzugpp, Nerd Font variants, and AUR-only extras may need manual installation on openSUSE; Polybar glyphs may be missing.'
        ;;
    xbps)
        as_root xbps-install -S
        install_packages bash git base-devel iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3 xorg-server xinit setxkbmap xclip xdotool
        echo 'Matugen, Fastfetch, ueberzugpp, Nerd Font variants, and AUR-only extras may need manual installation on Void; Polybar glyphs may be missing.'
        ;;
    apk)
        install_packages bash git build-base iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3 xorg-server xinit setxkbmap xclip xdotool
        echo 'Some desktop packages may not be available for your Alpine release; review the warnings above.'
        echo 'Nerd Font variants may need manual installation on Alpine; Polybar glyphs may be missing.'
        ;;
esac

echo "Dependency installation finished using $manager."
