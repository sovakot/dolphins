#!/bin/sh
id="$1"
name="${2:-$1}"
done_text="${3:-Uninstalled}"
fail_text="${4:-Uninstall failed}"
say() { notify-send -a Dolphin "$name" "$1"; }
for d in "$HOME/.local/share/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications; do
    [ -e "$d/$id.desktop" ] || continue
    if flatpak uninstall -y "$id" >/dev/null 2>&1; then say "$done_text"; exit 0; fi
    say "$fail_text"
    exit 1
done
f=""
for d in /usr/share/applications /usr/local/share/applications; do
    [ -f "$d/$id.desktop" ] && { f="$d/$id.desktop"; break; }
done
[ -n "$f" ] || { say "$fail_text: no package"; exit 2; }
pkg=$(pacman -Qqo "$f" 2>/dev/null) || { say "$fail_text: no package"; exit 3; }
if out=$(pkexec pacman -Rns --noconfirm "$pkg" 2>&1); then say "$done_text: $pkg"; exit 0; fi
say "$fail_text: $(printf '%s' "$out" | tail -n 1)"
exit 1
