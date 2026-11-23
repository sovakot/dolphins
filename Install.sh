#!/bin/sh
root=$(cd "$(dirname "$0")" && pwd)
check="$root/Interface/Hidden/Updater/Check.sh"
cfg="$root/Data/Dynamic/config.json"
skip="pkg-list pkg-list-aur pkg-apps pkg-apps-aur hyprai-model"
failed=""
yes=0
say() { printf '\n== %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
ask() {
    [ "$yes" = 1 ] && { [ "$2" = y ]; return; }
    printf '%s ' "$1"
    read -r a
    case "$a" in [nN]*) return 1 ;; "") [ "$2" = n ] && return 1 ;; esac
    return 0
}
missing() { [ -s "$1" ] && grep -vE '^[[:space:]]*(#|$)' "$1" | awk '$1 !~ /-debug$/ {print $1}' | sort -u | pacman -T - 2>/dev/null; }
helper() {
    have yay && return 0
    say "yay, for programs from the AUR"
    sudo pacman -S --needed --noconfirm git base-devel || return 1
    t=$(mktemp -d) && git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin" && (cd "$t/yay-bin" && makepkg -si --noconfirm)
}
get() {
    [ -n "$1" ] || return 0
    helper
    if have yay; then
        yay -S --needed --noconfirm $1 && return 0
        for p in $1; do yay -S --needed --noconfirm "$p" || failed="$failed $p"; done
    else
        sudo pacman -S --needed --noconfirm $1 && return 0
        for p in $1; do sudo pacman -S --needed --noconfirm "$p" || failed="$failed $p"; done
    fi
    [ -z "$failed" ]
}
put() {
    k=${1%%=*}
    v=${1#*=}
    [ -s "$cfg" ] || echo '{}' > "$cfg"
    jq --arg k "$k" --arg v "$v" '.[$k] = (try ($v | fromjson) catch $v)' "$cfg" > "$cfg.new" && mv "$cfg.new" "$cfg"
}
apply() {
    tried=" "
    pass=0
    while [ "$pass" -lt 5 ]; do
        pass=$((pass + 1))
        todo=$(sh "$check" "$root" 2>/dev/null | awk -F'\t' -v t="$tried" -v s=" $skip " '$6 != "" && index(s, " " $1 " ") == 0 && index(t, " " $1 " ") == 0 { print $1 "\t" $2 "\t" $6 }')
        [ -n "$todo" ] || break
        printf '%s\n' "$todo" | awk -F'\t' '{ print "  - " $2 }'
        if [ "$pass" = 1 ] && [ "$1" = ask ]; then ask "Apply all of these? [Y/n]" y || break; fi
        n=$(printf '%s\n' "$todo" | wc -l)
        i=0
        while [ "$i" -lt "$n" ]; do
            i=$((i + 1))
            row=$(printf '%s\n' "$todo" | sed -n "${i}p")
            id=$(printf '%s' "$row" | cut -f1)
            cmd=$(printf '%s' "$row" | cut -f3- | sed 's/^term://; s/pkexec /sudo /g')
            tried="$tried$id "
            printf '\n> %s\n' "$(printf '%s' "$row" | cut -f2)"
            case "$cmd" in
                set:*) put "${cmd#set:}" || failed="$failed [$id]" ;;
                *) sh -c "$cmd" || failed="$failed [$id]" ;;
            esac
        done
    done
}
report() {
    say "Left for you"
    left=$(sh "$check" "$root" 2>/dev/null | awk -F'\t' '$2 != "" && $1 !~ /^pkg-apps/ { print "  - " $2 }')
    [ -n "$left" ] && printf '%s\n' "$left" || echo "Nothing."
    [ -n "$failed" ] && printf '\nThese did not work:%s\n' "$failed"
}
start() {
    [ -n "$WAYLAND_DISPLAY" ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || return 1
    q=qs
    have qs || q=quickshell
    have "$q" || return 1
    have awww-daemon && ! pgrep -u "$(id -u)" -x awww-daemon >/dev/null 2>&1 && setsid -f awww-daemon --no-cache >/dev/null 2>&1
    pgrep -u "$(id -u)" -x 'qs|quickshell' >/dev/null 2>&1 || setsid -f "$q" -p "$root/Dolphin.qml" >/dev/null 2>&1
}

have pacman || { echo "This installer needs pacman (Arch Linux)."; exit 1; }
[ "$(id -u)" = 0 ] && { echo "Run this as your own user, not as root."; exit 1; }
[ -f "$check" ] || { echo "Dolphin is not complete: $check is missing."; exit 1; }

case "$1" in
    get)
        shift
        get "$*"
        exit
        ;;
    fix)
        shift
        skip="pkg-apps pkg-apps-aur hyprai-model"
        for x do skip="$skip $x"; done
        have jq || sudo pacman -S --needed --noconfirm jq || exit 1
        apply
        report
        exit 0
        ;;
    -y) yes=1 ;;
esac

[ -e "$HOME/Dolphin" ] || ln -s "$root" "$HOME/Dolphin"

say "Programs needed to install anything"
sudo pacman -S --needed --noconfirm git base-devel jq || exit 1
helper

say "Programs this Dolphin setup uses"
g=$(missing "$root/packages.txt" | tr '\n' ' ')
have qs || have quickshell || g="$g quickshell"
g=$(printf '%s\n' $g | sort -u | tr '\n' ' ')
if [ -n "$g" ]; then echo "$g"; get "$g"; else echo "All installed."; fi

a=$(missing "$root/Data/Static/apps.txt" | tr '\n' ' ')
if [ -n "$a" ]; then
    say "Your own apps"
    echo "$a"
    ask "Install them too? [y/N]" n && get "$a"
fi

say "Setting up this computer"
apply ask
report

if start; then
    printf '\nDolphin is running. It starts by itself from now on.\n'
elif ask "Restart the computer now to finish? [Y/n]" y; then
    systemctl reboot
fi
