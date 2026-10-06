# Synx Shell

Personal bspwm desktop configuration for X11. The installer deploys the
configuration files and scripts, then keeps their source checkout at
`~/.local/share/synx-shell/repo` so cache cleanup does not break the desktop.

## Install

This repository is private. Create a GitHub token with read access to
repository contents, then run the curl installer:

```sh
read -rsp 'GitHub read token: ' GH_TOKEN; printf '\n'; export GH_TOKEN
bash -c "$(curl --config <(printf 'header = "Authorization: Bearer %s"\n' "$GH_TOKEN") -fsSL 'https://raw.githubusercontent.com/L1mppa/Synx-Shell/main/install/install.sh')"
```

The token is read by the installer and is not written to the repository. The
installer stages downloads before replacing the stable checkout, then presents
settings, dependencies, wallpaper copy, and deployment steps. Re-running it
updates the checkout in place; deployed links continue to use the same path.
Existing user configuration is backed up under
`~/.local/state/synx-shell/backups/` when it is first replaced.

On Arch Linux, the dependency step performs a full `pacman -Syu` transaction
and uses `yay` or `paru` for AUR packages. It builds `yay` if neither helper is
installed. The Arch package step runs a full `pacman -Syu` transaction, so it
may upgrade existing system packages; review and confirm pacman's transaction.
It installs an X server, `xinit`, Iosevka Nerd Font Mono, an…764 tokens truncated…
| `Super + Alt + Q` | Quit bspwm |
| `Super + Alt + R` | Restart bspwm |
| `Super + T` | Set tiled state |
| `Super + Shift + T` | Set pseudo-tiled state |
| `Super + V` | Set floating state |
| `Super + F` | Set fullscreen state |
| `Super + M` | Toggle tiled and monocle layouts |
| `Super + G` | Swap the focused window with the largest window |
| `Super + Y` | Move the newest marked window to the newest preselected node |
| `Super + Ctrl + M/X/Y/Z` | Set the marked / locked / sticky / private flag |
| `Super + H/J/K/L` | Focus the window left / down / up / right |
| `Super + Shift + H/J/K/L` | Swap the focused window with its neighbor |
| `Super + C` | Focus the next window in this desktop |
| `Super + Shift + C` | Focus the previous window in this desktop |
| `Super + [` / `Super + ]` | Focus the previous / next desktop |
| `Super + Grave` | Focus the last window |
| `Super + Tab` | Focus the last desktop |
| `Super + O` / `Super + I` | Focus the older / newer window in focus history |
| `Super + 1…9` / `Super + 0` | Focus desktop 1…9 / desktop 10 |
| `Super + Shift + 1…9` / `Super + Shift + 0` | Send the focused window to desktop 1…9 / desktop 10 |

### Tiling and floating window movement

| Key | Action |
| --- | --- |
| `Super + Ctrl + H/J/K/L` | Preselect left / down / up / right for the next tiled window |
| `Super + Ctrl + 1…9` | Set the preselection ratio to 0.1…0.9 |
| `Super + Ctrl + Space` | Cancel the focused node's preselection |
| `Super + Ctrl + Shift + Space` | Cancel preselection for all windows on the desktop |
| `Super + Alt + H/J/K/L` | Expand the focused window left / down / up / right |
| `Super + Alt + Shift + H/J/K/L` | Contract the focused window from the left / bottom / top / right |
| `Super + Arrow keys` | Move a floating window |

## Included configuration

- bspwm, sxhkd, and guarded desktop autostart
- Alacritty, Polybar, Rofi, Picom, and Dunst
- Fastfetch and Polybar MPRIS controls
- `wallfinder` with optional Matugen color generation

The X11 Bemoji shortcut sets `BEMOJI_PICKER_CMD=rofi`,
`BEMOJI_CLIP_CMD=xclip`, and `BEMOJI_TYPE_CMD=xdotool`. This matches bemoji's
documented X11 tools; install `xclip` for clipboard copying and `xdotool` for
typing. Some optional shortcuts also use Flameshot, Greenclip,
`rofi-power-menu`, and `dmenu-bluetooth`.
