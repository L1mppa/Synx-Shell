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

# Pacman defaults conflict-removal questions to "no". Feed yes responses to
# package transactions so replacement/conflict prompts are resolved as requested.
# Disable pipefail for this pipeline because `yes` exits on SIGPIPE when pacman
# finishes; still return pacman's exit status.
run_with_yes() {
    local status
    set +o pipefail
    if yes | "$@"; then
        status=0
    else
        status=$?
    fi
    set -o pipefail
    return "$status"
}

install_packages() {
    case "$manager" in
        pacman) run_with_yes as_root pacman -S --needed "$@" ;;
        apt) as_root apt-get install -y "$@" ;;
        dnf) as_root dnf install -y "$@" ;;
        zypper) as_root zypper --non-interactive install "$@" ;;
        xbps) as_root xbps-install -Sy "$@" ;;
        apk) as_root apk add "$@" ;;
    esac
}

case "$manager" in
    pacman)
        as_root pacman -Sy
        repo_packages=(bash git base-devel bspwm sxhkd alacritty feh picom dunst polybar rofi fastfetch fzf chafa ueberzugpp libnotify playerctl pamixer flameshot matugen python)
        aur_packages=(python-pywal16 zscroll greenclip bemoji rofi-power-menu dmenu-bluetooth)

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
            build_dir="$(mktemp -d "${TMPDIR:-/tmp}/bspwm-dots-yay.XXXXXX")"
            trap 'rm -rf -- "$build_dir"' EXIT
            git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
            (cd "$build_dir/yay" && makepkg -si --noconfirm)
            helper=yay
        fi
        run_with_yes "$helper" -S --needed --noconfirm "${aur_packages[@]}"
        ;;
    apt)
        as_root apt-get update
        install_packages bash git build-essential bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify-bin playerctl pamixer flameshot python3
        echo 'Matugen, Fastfetch, ueberzugpp, pywal16, and AUR-only extras are not installed by this Debian/Ubuntu package mapping.'
        ;;
    dnf)
        install_packages bash git make gcc bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3
        echo 'Matugen, Fastfetch, ueberzugpp, pywal16, and AUR-only extras are not installed by this Fedora package mapping.'
        ;;
    zypper)
        install_packages bash git make gcc bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify-tools playerctl pamixer flameshot python3
        echo 'Matugen, Fastfetch, ueberzugpp, pywal16, and AUR-only extras are not installed by this openSUSE package mapping.'
        ;;
    xbps)
        as_root xbps-install -S
        install_packages bash git base-devel bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3
        echo 'Matugen, Fastfetch, ueberzugpp, pywal16, and AUR-only extras are not installed by this Void package mapping.'
        ;;
    apk)
        install_packages bash git build-base bspwm sxhkd alacritty feh picom dunst polybar rofi fzf chafa libnotify playerctl pamixer flameshot python3
        echo 'Some desktop packages may not be available for your Alpine release; review the package manager output.'
        ;;
esac

echo "Dependency installation finished using $manager."
