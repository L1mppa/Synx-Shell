# Bspwm Dots

Personal bspwm desktop configuration for X11. Config files keep their usual
paths under `.config`; the terminal wallpaper picker is included under
`.local/bin`.

## Setup

From the repository checkout, run:

```sh
bash install.sh
```

The installer detects pacman, apt, dnf, zypper, xbps, or apk and installs the
available dependencies before linking the configuration. Existing files are
backed up under `~/.local/state/bspwm-dots/backups/`. Pass `--no-deps` to only
install the dotfiles:

```sh
bash install.sh --no-deps
```

On Arch Linux, the dependency installer uses `yay` or `paru` if present. If
neither exists, it builds `yay` from the AUR as the current user. It needs git,
`base-devel`, and sudo access for package installation. Other supported
distributions install the packages available in their repositories; the script
prints a note for packages that need manual installation there.

## Build an archive

Create a dated tarball containing the configuration and installer:

```sh
bash build.sh
```

The archive is written to `dist/`.

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
