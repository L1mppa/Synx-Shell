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
            printf 'Arch package installation runs pacman -Syu, which upgrades the whole system.\n' >&2
            read -r -p 'Review the transaction carefully. Continue? [y/N] ' answer
            case "$answer" in
                y|Y|yes|YES) ;;
                *) echo 'Package installation cancelled.' >&2; return 1 ;;
            esac
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
        repo_packages=(bash git base-devel bspwm sxhkd alacritty feh picom dunst polybar rofi fastfetch fzf chafa ueberzugpp libnotify playerctl pamixer flameshot matugen python iproute2 xorg-server xorg-xinit xorg-setxkbmap xclip xdotool ttf-iosevka-nerd ttf-terminus-nerd iw bluez bluez-utils pipewire-pulse papirus-icon-theme noto-fonts dbus)
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
            if ! (cd "$build_dir/yay" && makepkg -si); then
                echo 'Could not build or install yay. Install yay or paru manually, then rerun this step.' >&2
                exit 1
            fi
            helper=yay
        fi
        "$helper" -S --needed "${aur_packages[@]}"
        ;;
    apt)
        as_root apt-get update
        install_packages bash git build-essential iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify-bin playerctl pamixer flameshot python3 xorg xinit x11-xkb-utils xclip xdotool fonts-iosevka fonts-terminus iw bluez bluez-tools pipewire-pulse papirus-icon-theme fonts-noto-core dbus-x11
        echo 'Matugen, Fastfetch, ueberzugpp, zscroll, Greenclip, bemoji, rofi-power-menu, and dmenu-bluetooth may need manual installation on Debian/Ubuntu.'
        ;;
    dnf)
        install_packages bash git make gcc iproute bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3 xorg-x11-server-Xorg xorg-x11-xinit xorg-x11-xkb-utils xclip xdotool iosevka-fonts terminus-fonts iw bluez bluez-tools pipewire-pulseaudio papirus-icon-theme google-noto-sans-mono-fonts dbus-x11
        echo 'Matugen, Fastfetch, ueberzugpp, zscroll, Greenclip, bemoji, rofi-power-menu, and dmenu-bluetooth may need manual installation on Fedora.'
        ;;
    zypper)
        install_packages bash git make gcc iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify-tools playerctl pamixer flameshot python3 xorg-x11-server xinit setxkbmap xclip xdotool iosevka-fonts terminus-fonts iw bluez bluez-tools pipewire-pulseaudio papirus-icon-theme google-noto-sans-mono-fonts dbus-1-x11
        echo 'Matugen, Fastfetch, ueberzugpp, zscroll, Greenclip, bemoji, rofi-power-menu, and dmenu-bluetooth may need manual installation on openSUSE.'
        ;;
    xbps)
        as_root xbps-install -S
        install_packages bash git base-devel iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3 xorg-server xinit setxkbmap xclip xdotool iw bluez bluez-utils pipewire-pulse papirus-icon-theme noto-fonts-ttf dbus-x11
        echo 'Matugen, Fastfetch, ueberzugpp, zscroll, Greenclip, bemoji, rofi-power-menu, and dmenu-bluetooth may need manual installation on Void.'
        ;;
    apk)
        install_packages bash git build-base iproute2 bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3 xorg-server xinit setxkbmap xclip xdotool iw bluez bluez-openrc pipewire-pulse papirus-icon-theme font-noto dbus-x11
        echo 'Some desktop packages may not be available for your Alpine release; review the warnings above.'
        echo 'Nerd Font variants may need manual installation on Alpine; Polybar glyphs may be missing.'
        ;;
esac

printf '\nNetworkManager is optional; install it only if you use it for network management. It may conflict with iwd or systemd-networkd.\n'
read -r -p 'Install optional NetworkManager? [y/N] ' answer || answer=''
case "$answer" in
    y|Y|yes|YES)
        case "$manager" in
            pacman) as_root pacman -S --needed networkmanager ;;
            apt) install_packages network-manager ;;
            dnf|zypper|xbps) install_packages NetworkManager ;;
            apk) install_packages networkmanager ;;
        esac
        ;;
esac
printf 'BlueZ is installed for the optional dmenu-bluetooth shortcut; bluetooth.service is not enabled by this installer.\n'
echo "Dependency installation finished using $manager."
