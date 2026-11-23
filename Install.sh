#!/bin/sh
root=$(cd "$(dirname "$0")" && pwd)
check="$root/Interface/Hidden/Updater/Check.sh"
cfg="$root/Data/Dynamic/config.json"
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
put() {
    k=${1%%=*}
    v=${1#*=}
    [ -s "$cfg" ] || echo '{}' > "$cfg"
    jq --arg k "$k" --arg v "$v" '.[$k] = (try ($v | fromjson) catch $v)' "$cfg" > "$cfg.new" && mv "$cfg.new" "$cfg"
}
get() {
    [ -n "$1" ] || return 0
    if have yay; then
        yay -S --needed --noconfirm $1 && return 0
        for p in $1; do yay -S --needed --noconfirm "$p" || failed="$failed $p"; done
    else
        sudo pacman -S --needed --noconfirm $1 && return 0
        for p in $1; do sudo pacman -S --needed --noconfirm "$p" || failed="$failed $p"; done
    fi
}

have pacman || { echo "This installer needs pacman (Arch Linux)."; exit 1; }
[ "$(id -u)" = 0 ] && { echo "Run this as your own user, not as root."; exit 1; }
[ -f "$check" ] || { echo "Dolphin is not complete: $check is missing."; exit 1; }
failed=""
[ -e "$HOME/Dolphin" ] || ln -s "$root" "$HOME/Dolphin"
yes=0
[ "$1" = -y ] && yes=1

say "Programs needed to install anything"
sudo pacman -S --needed --noconfirm git base-devel jq || exit 1
if ! have yay; then
    say "yay, for programs from the AUR"
    t=$(mktemp -d) && git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin" && (cd "$t/yay-bin" && makepkg -si --noconfirm)
fi

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
tried=" "
pass=0
while [ "$pass" -lt 5 ]; do
    pass=$((pass + 1))
    todo=$(sh "$check" "$root" 2>/dev/null | awk -F'\t' -v t="$tried" '$6 != "" && $1 !~ /^pkg-(list|apps)/ && index(t, " " $1 " ") == 0 { print $1 "\t" $2 "\t" $6 }')
    [ -n "$todo" ] || break
    printf '%s\n' "$todo" | awk -F'\t' '{ print "  - " $2 }'
    if [ "$pass" = 1 ]; then ask "Apply all of these? [Y/n]" y || break; fi
    n=$(printf '%s\n' "$todo" | wc -l)
    i=0
    while [ "$i" -lt "$n" ]; do
        i=$((i + 1))
        row=$(printf '%s\n' "$todo" | sed -n "${i}p")
        id=$(printf '%s' "$row" | cut -f1)
        cmd=$(printf '%s' "$row" | cut -f3- | sed 's/pkexec /sudo /g')
        tried="$tried$id "
        printf '\n> %s\n' "$(printf '%s' "$row" | cut -f2)"
        case "$cmd" in
            set:*) put "${cmd#set:}" || failed="$failed [$id]" ;;
            *) sh -c "$cmd" || failed="$failed [$id]" ;;
        esac
    done
done

say "Left for you"
left=$(sh "$check" "$root" 2>/dev/null | awk -F'\t' '$2 != "" && $1 !~ /^pkg-apps/ { print "  - " $2 }')
[ -n "$left" ] && printf '%s\n' "$left" || echo "Nothing."
[ -n "$failed" ] && printf '\nThese did not work:%s\n' "$failed"
printf '\nRestart the computer to finish. Anything listed above is also in the Updater, with its steps.\n'
