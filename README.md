# winbar

Windows-style desktop mode for [Hyprland](https://hyprland.org/): bottom taskbar, grouped app icons, start menu, desktop icons, Alt+Tab previews, minimize.

| Component | Role |
|-----------|------|
| `winmode` | Toggle Windows mode on/off (`Super+W`) |
| `winmode-boot` | Login restore (waybar ± dock + desk) |
| `winbar-dock` | Grouped taskbar app icons (overlay, above waybar strip) |
| `winbar-desk` | Per-monitor desktop icons |
| `winbar-msg` | IPC to dock (start / alt-tab / taskview / minimize / …) |
| `toggle-waybar` | `Super+B` hide/show bar; in winmode also dock icons |
| `plugin/` | `hypr-minimize` titlebar minimize → dock |

## Install

```bash
./install.sh
```

Wire Hyprland (see `docs/hyprland-snippet.conf`):

```conf
exec-once = ~/.local/bin/winmode-boot
bind = $mainMod, W, exec, ~/.local/bin/winmode
bind = $mainMod, B, exec, ~/.local/bin/toggle-waybar
source = ~/.config/hypr/mode.conf   # last; written by winmode
```

Optional plugin:

```bash
make -C plugin
# load from winmode / winmode-boot when ~/.local/lib/hypr-minimize.so exists
```

## Dependencies

- Hyprland, waybar, rofi (start menu themes under `config/rofi/`)
- Python 3 + PyGObject + gtk-layer-shell
- `grim` (window thumbnails), optional `cliphist` / `playerctl` / `hyprsunset`

## Layout

```
bin/                 scripts installed to ~/.local/bin
config/waybar/windows/   winmode waybar strip
config/rofi/         start / search themes
config/winbar/       theme.css, examples for pinned/tray
share/emoji.txt      WIN+. picker list
plugin/              hypr-minimize source
```

Runtime state lives outside the repo: `~/.config/winbar/`, `~/.local/state/winmode/`, `~/.cache/winbar/`.

## Keys (while winmode is on)

| Bind | Action |
|------|--------|
| Super+W | Toggle winmode |
| Super+B | Hide/show taskbar (+ dock icons) |
| Super+R | Start menu |
| Super+Tab | Task view |
| Super+M | Minimize / restore active |
| Super+. | Emoji picker |
| Alt+Tab | Window switcher (dock overlay) |

## License

Private. All rights reserved.
