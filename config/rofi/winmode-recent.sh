#!/usr/bin/env bash
# ============================================================
# rofi script-modi: recent files/folders + common folders
# for the windows-mode start menu.
# ============================================================

# selection made -> open it and quit
if [ -n "${1:-}" ]; then
    [ -n "${ROFI_INFO:-}" ] && setsid -f xdg-open "$ROFI_INFO" >/dev/null 2>&1
    exit 0
fi

row() { # display, icon, path
    printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' "$1" "$2" "$3"
}

# ---- quick folders ----
row "Home"      "user-home"           "$HOME"
row "Desktop"   "user-desktop"        "$HOME/Desktop"
row "Downloads" "folder-download"     "$HOME/Downloads"
row "Documents" "folder-documents"    "$HOME/Documents"
row "Pictures"  "folder-pictures"     "$HOME/Pictures"

# ---- recent files (GTK recently-used.xbel + KDE RecentDocuments) ----
python3 - <<'EOF'
import os, glob, urllib.parse, xml.etree.ElementTree as ET

items = {}  # path -> mtime

xbel = os.path.expanduser('~/.local/share/recently-used.xbel')
if os.path.exists(xbel):
    try:
        for b in ET.parse(xbel).getroot().findall('bookmark'):
            href = b.get('href', '')
            if not href.startswith('file://'):
                continue
            path = urllib.parse.unquote(href[7:])
            if os.path.exists(path):
                items[path] = max(items.get(path, ''), b.get('modified', ''))
    except Exception:
        pass

for d in glob.glob(os.path.expanduser('~/.local/share/RecentDocuments/*.desktop')):
    try:
        target = None
        for line in open(d, errors='ignore'):
            if line.startswith('URL') and '=' in line:
                url = line.split('=', 1)[1].strip()
                url = url.replace('$HOME', os.path.expanduser('~'))
                if url.startswith('file://'):
                    url = urllib.parse.unquote(url[7:])
                target = url
                break
        if target and os.path.exists(target):
            import datetime
            m = datetime.datetime.fromtimestamp(os.path.getmtime(d)).isoformat()
            items[target] = max(items.get(target, ''), m)
    except Exception:
        pass

home = os.path.expanduser('~')
for path, _ in sorted(items.items(), key=lambda kv: kv[1], reverse=True)[:15]:
    name = os.path.basename(path.rstrip('/')) or path
    ext = os.path.splitext(path)[1].lower()
    if os.path.isdir(path):
        icon = 'folder'
    elif ext in ('.mkv', '.mp4', '.webm', '.avi', '.mov'):
        icon = 'video-x-generic'
    elif ext in ('.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'):
        icon = 'image-x-generic'
    elif ext in ('.mp3', '.flac', '.ogg', '.wav', '.opus'):
        icon = 'audio-x-generic'
    elif ext == '.pdf':
        icon = 'application-pdf'
    elif ext in ('.zip', '.tar', '.gz', '.xz', '.7z', '.rar'):
        icon = 'package-x-generic'
    else:
        icon = 'text-x-generic'
    shown = path.replace(home, '~')
    print(f'{name}  ({shown})\0icon\x1f{icon}\x1finfo\x1f{path}')
EOF
