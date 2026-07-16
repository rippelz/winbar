#!/usr/bin/env bash
# Install winbar / winmode into ~/.local/bin (+ optional configs).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN="${HOME}/.local/bin"
CFG="${HOME}/.config"
SHARE="${HOME}/.local/share/winbar"
HYPR="${HOME}/.config/hypr"
STATE="${HOME}/.local/state/winmode"

mkdir -p "$BIN" "$SHARE" "$HYPR" "$STATE" \
    "$CFG/waybar/windows" "$CFG/rofi" "$CFG/winbar"

echo "==> Installing scripts → $BIN"
for s in winbar-dock winbar-desk winbar-msg winbar-emoji winbar-clip \
         winbar-minimize winmode winmode-boot winmode-chrome toggle-waybar rofi-apps; do
    install -m 755 "$ROOT/bin/$s" "$BIN/$s"
done
ln -sfn winbar-msg "$BIN/winbar-alttab"

echo "==> Share (emoji list)"
if [ -f "$ROOT/share/emoji.txt" ]; then
    install -m 644 "$ROOT/share/emoji.txt" "$SHARE/emoji.txt"
fi

echo "==> Config (only if missing)"
install_if_missing() {
    local src="$1" dst="$2"
    if [ ! -e "$dst" ]; then
        install -m 644 "$src" "$dst"
        echo "  created $dst"
    fi
}

install_if_missing "$ROOT/config/waybar/windows/config.jsonc" \
    "$CFG/waybar/windows/config.jsonc"
install_if_missing "$ROOT/config/waybar/windows/style.css" \
    "$CFG/waybar/windows/style.css"
# Always refresh shipped rofi templates (palette is re-applied by `theme apply`)
echo "==> rofi templates → $CFG/rofi"
for f in winmode-list.rasi winmode-search.rasi winmode-start.rasi; do
    if [ -f "$ROOT/config/rofi/$f" ]; then
        install -m 644 "$ROOT/config/rofi/$f" "$CFG/rofi/$f"
        echo "  $f"
    fi
done
if [ -f "$ROOT/config/rofi/winmode-recent.sh" ]; then
    install -m 755 "$ROOT/config/rofi/winmode-recent.sh" \
        "$CFG/rofi/winmode-recent.sh"
    echo "  winmode-recent.sh"
fi
install_if_missing "$ROOT/config/winbar/theme.css" "$CFG/winbar/theme.css"
install_if_missing "$ROOT/config/winbar/night-red.glsl" \
    "$CFG/winbar/night-red.glsl"
if [ ! -e "$CFG/winbar/pinned.json" ] && \
   [ -f "$ROOT/config/winbar/pinned.json.example" ]; then
    install -m 644 "$ROOT/config/winbar/pinned.json.example" \
        "$CFG/winbar/pinned.json"
    echo "  created $CFG/winbar/pinned.json (from example)"
fi
if [ ! -e "$CFG/winbar/tray-apps.json" ] && \
   [ -f "$ROOT/config/winbar/tray-apps.json.example" ]; then
    install -m 644 "$ROOT/config/winbar/tray-apps.json.example" \
        "$CFG/winbar/tray-apps.json"
    echo "  created $CFG/winbar/tray-apps.json (from example)"
fi

if [ ! -f "$HYPR/mode.conf" ]; then
    printf '%s\n' \
        '# Managed by ~/.local/bin/winmode — currently OFF (no overrides).' \
        > "$HYPR/mode.conf"
    echo "Created $HYPR/mode.conf"
fi

if [ -d "$ROOT/plugin" ] && command -v pkg-config >/dev/null 2>&1; then
    if pkg-config --exists hyprland 2>/dev/null; then
        echo "==> Building hypr-minimize plugin"
        make -C "$ROOT/plugin" || echo "WARNING: plugin build failed (optional)"
    else
        echo "==> Skipping plugin (hyprland pkg-config not found)"
    fi
fi

if [ -f "$HYPR/hyprland.conf" ] && \
   ! grep -q 'winmode' "$HYPR/hyprland.conf" 2>/dev/null; then
    echo ""
    echo "Add to hyprland.conf if missing (see docs/hyprland-snippet.conf):"
    cat "$ROOT/docs/hyprland-snippet.conf"
fi

echo ""
echo "Installed winbar $(cat "$ROOT/VERSION" 2>/dev/null || echo dev)"
echo "  Super+W  winmode   |  Super+B  toggle taskbar"
