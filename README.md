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
bash -c "$(curl --config <(printf 'header = "Authorization: Bearer %s"\n' "$GH_TOKEN") -fsSL 'https://raw.githubusercontent.com/L1mppa/Synx-Shell/main/install/install.sh')"
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

1. Set system language, choose from the system's X11 keyboard layouts and timezones, and select Polybar's 12/24-hour clock. Search long lists with `/text`; UTC is included.
2. Install the programs required by the desktop and wallpaper picker.
3. Copy repository wallpapers to `~/Wallpapers` (or `WALLFINDER_DIR`).
4. Install Synx Shell and deploy the configs.

Place wallpaper images in `wallpapers/` before building or running the installer.
Supported formats are JPG, PNG, and WebP. This repository currently has no
wallpaper image assets.

## Wallpaper picker

`wallfinder` is launched with **Super + W**. It uses fzf and ueberzugpp for a
sharp raster preview in X11, feh to set the wallpaper, and optionally Matugen
to generate colors. When Matugen is installed, each wallpaper updates the
bspwm window borders, Polybar outline, Rofi borders, Dunst notification frames,
and wallfinder selector colors from the generated palette. Chafa provides a
text preview fallback if ueberzugpp is unavailable. By default it looks for
images in `~/Wallpapers`; set
`WALLFINDER_DIR` to use a different directory. The Arch dependency installer
includes ueberzugpp.

## Keybindings

The main modifier is **Super** (usually the Windows key).

### Launchers and actions

| Key | Action |
| --- | --- |
| `Super + Enter` | Open Alacritty |
| `Super + Space` | Open the Rofi app and window launcher |
| `Super + W` | Open the wallpaper picker |
| `Super + P` | Start Flameshot region capture |
| `Super + E` | Open Bemoji |
| `Super + S` | Open the Rofi power menu |
| `Super + B` | Open Bluetooth controls |
| `Super + N` | Send a test notification |
| `Super + Esc` | Reload sxhkd keybindings |
| `Super + C` | Open the Greenclip clipboard menu; this conflicts with the next-window binding below |

### Window and desktop control

| Key | Action |
| --- | --- |
| `Super + Q` | Close the focused window |
| `Super + Shift + Q` | Kill the focused window |
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
| `Super + H/J/K/L` | Focus the window to the left / down / up / right |
| `Super + Shift + H/J/K/L` | Swap the focused window with the neighbor left / down / up / right |
| `Super + C` | Focus the next window in this desktop; conflicts with Greenclip above |
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
| `Super + Alt + H/J/K/L` | Expand the focused window toward the left / bottom / top / right |
| `Super + Alt + Shift + H/J/K/L` | Contract the focused window from the left / bottom / top / right |
| `Super + Arrow keys` | Move a floating window |

**Key conflict:** `Super + C` is assigned to both Greenclip and focusing the next
window. sxhkd cannot reliably run both actions for one chord; change one binding
in `.config/sxhkd/sxhkdrc` to make both available.

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
