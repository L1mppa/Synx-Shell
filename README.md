# Synx Shell

Personal bspwm desktop configuration for X11. Config files keep their usual
paths under `.config`; the terminal wallpaper picker is included under
`.local/bin`.

## Install

Install with the Synx Shell curl command. Since this repository is private, first
create a GitHub token with read access to repository contents. Enter it when
prompted; it is not saved in the repository or shell history.

```sh
read -rsp 'GitHub read token: ' GH_TOKEN; printf '\n'; export GH_TOKEN
bash -c "$(curl --config <(printf 'header = \"Authorization: Bearer %s\"\n' \"$GH_TOKEN\") -fsSL 'https://raw.githubusercontent.com/L1mppa/Synx-Shell/main/install/install.sh')"
```

The bootstrap prints the Synx Shell logo, downloads the repository snapshot to
`~/.cache/synx-shell`, and opens a numbered menu for regional settings,
dependencies, repository wallpapers, and final config deployment. The token
needs repository contents read access only.

Choose settings, dependencies, wallpapers, and config deployment from the
installer menu. Existing config files are backed up under
`~/.local/state/synx-shell/backups/`.

On Arch Linux, the dependency installer uses `yay` or `paru` if present. If
neither exists, it builds `yay` from the AUR as the current user. It needs git,
`base-devel`, and sudo access for package installation. Other supported
distributions install the packages available in their repositories; the script
prints a note for packages that need manual installation there. Arch package
conflict and replacement prompts are automatically answered yes so pacman can
resolve the package transaction.

## Installer steps

The curl bootstrap offers:

1. Set system language, X11 keyboard layout, timezone, and Polybar's 12/24-hour clock.
2. Install the programs required by the desktop and wallpaper picker.
3. Copy repository wallpapers to `~/Wallpapers` (or `WALLFINDER_DIR`).
4. Install Synx Shell and deploy the configs.

Place wallpaper images in `wallpapers/` before building or running the installer.
Supported formats are JPG, PNG, and WebP. This repository currently has no
wallpaper image assets.

## Wallpaper picker

`wallfinder` is launched with **Super + W**. It uses fzf and ueberzugpp for a
sharp raster preview in X11, feh to set the wallpaper, and optionally Matugen
to generate colors. Chafa provides a text preview fallback if ueberzugpp is
unavailable. By default it looks for images in `~/Wallpapers`; set
`WALLFINDER_DIR` to use a different directory. The Arch dependency installer
includes ueberzugpp.

## Included configuration

- bspwm and sxhkd
- Alacritty, Polybar, Rofi, Picom, and Dunst
- Fastfetch
- pywal color scheme and templates
- Polybar MPRIS helper scripts
- the `wallfinder` wallpaper picker

Some optional shortcuts require flameshot, greenclip, bemoji,
rofi-power-menu, and dmenu-bluetooth. Review the configs for machine-specific
paths and adjust them before starting bspwm. Select bspwm in your display
manager, or start it with `startx`.
