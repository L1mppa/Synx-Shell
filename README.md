# Bspwm Dots

Personal bspwm desktop configuration for X11. The repository keeps the configuration under the same `.config` paths used in a home directory, plus the wallpaper picker in `.local/bin/wallfinder`.

## Included

- bspwm window manager and autostart
- sxhkd keyboard shortcuts
- Alacritty terminal, Polybar, Rofi, Picom, and Dunst
- Fastfetch configuration
- pywal color scheme and templates
- `wallfinder`, a terminal wallpaper picker that applies wallpapers with feh and can refresh Matugen colors

## Dependencies

Core setup: bspwm, sxhkd, Alacritty, feh, Picom, Dunst, Polybar, and Rofi.

The wallpaper picker needs Bash, fzf, chafa, feh, and notify-send. Matugen and Python 3 are optional for wallpaper color generation. The Polybar scripts may also need playerctl, mpris, zscroll, and pamixer, depending on the modules enabled in the config. Some shortcuts use flameshot, greenclip, bemoji, rofi-power-menu, and dmenu-bluetooth.

## Install

Review the configs first, then copy them into your home directory while preserving the directory structure:

```sh
cp -r .config "$HOME/"
mkdir -p "$HOME/.local/bin"
cp .local/bin/wallfinder "$HOME/.local/bin/wallfinder"
chmod +x "$HOME/.local/bin/wallfinder"
```

Set `WALLFINDER_DIR` to your wallpaper directory if it is not `$HOME/Wallpapers`. The Polybar and Rofi configs may contain local paths; adjust them for your machine before launching the session.

The wallpaper picker is bound to **Super + W** in sxhkd. bspwm restores the last selected wallpaper from `~/.local/state/wallfinder/last-wallpaper`.
