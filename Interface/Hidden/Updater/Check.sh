#!/bin/sh
root="$1"
[ -r "$root/Data/Static/backup.json" ] || root=$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd)
cfg="$root/Data/Dynamic/config.json"
bak="$root/Data/Static/backup.json"
hypr="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
tty=""
[ -t 1 ] && tty=1
out() {
    _c="$6"
    case "$_c" in "pkexec "*) [ -n "$agent" ] || _c="term:sudo ${_c#pkexec }" ;; esac
    if [ -n "$tty" ]; then printf '\n! %s\n' "$2"; printf '%s\n%s\n' "$3" "$4" | sed 's/\\n/\n    /g; s/^/    /'
    else printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$_c"; fi
}
have() { command -v "$1" >/dev/null 2>&1; }
path() { case "$1" in /*) printf '%s' "$1" ;; *) printf '%s' "$HOME/${1#"~/"}" ;; esac; }
rel() { printf '%s' "${1#"$root"/}"; }
lines() { awk 'NF { gsub(/\t/, " "); printf "%s%s", (n++ ? "\\n" : ""), $0 } n >= 6 { exit }'; }
q=""
have qs && q=qs
[ -z "$q" ] && have quickshell && q=quickshell
can=""
have pacman && have pkexec && can=1
me=$(id -un)
agent=""
have pkexec && pgrep -f 'polkit.*agent|polkit-kde|hyprpolkitagent|lxpolkit|polkit-gnome' >/dev/null 2>&1 && agent=1
ins="$root/Install.sh"
repo=""
have pacman && repo=$(pacman -Slq 2>/dev/null)
inrepo() { for _p in $1; do printf '%s\n' "$repo" | grep -qxF "$_p" || return 1; done; }
get() {
    have pacman || return 0
    if inrepo "$1"; then printf 'pkexec pacman -S --noconfirm --needed %s' "$1"
    else printf "term:sh '%s' get %s" "$ins" "$1"; fi
}
pic() { find "$1" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) ! -iname "${2:-.}" 2>/dev/null | sort | head -n 1; }
short() { case "$1" in "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
llama="llama.cpp-vulkan-git"
inrepo "llama-cpp llama-cpp-vulkan" && [ -n "$repo" ] && llama="llama-cpp llama-cpp-vulkan"
cr=$(printf '\r')
restore="1. Extract the latest Dolphin archive into $root again. That puts the original file back.\n2. Reload Dolphin."

J=""
B=""
if have jq; then
    J=$(sed -zE 's/,([[:space:]]*[]}])/\1/g' "$cfg" 2>/dev/null)
    B=$(cat "$bak" 2>/dev/null)
    err=$(printf '%s' "$J" | jq empty 2>&1 >/dev/null | tail -n 1)
    if [ ! -e "$cfg" ]; then
        out config "config.json is missing" "Dolphin looked for $cfg and found nothing, so it is running on its built-in defaults." "Copies Data/Static/backup.json to Data/Dynamic/config.json, so there is a config.json with every default setting in it to edit. Reload Dolphin afterwards." "Changes Settings" "mkdir -p '$root/Data/Dynamic' && cp '$bak' '$cfg'"
        J=""
    elif [ -n "$err" ] || [ -z "$J" ]; then
        out config "config.json has a mistake" "Dolphin cannot read $cfg and is running on its built-in defaults until it is fixed. ${err:-The file is empty.}" "1. Open $cfg in an editor.\n2. Go to the line and column named in the message.\n3. Look for a missing comma between two lines, a missing quote, or a bracket too many or too few.\n4. Save. Dolphin reads the file again by itself." "" ""
        J=""
    fi
fi
val() {
    v=""
    if have jq; then
        [ -n "$J" ] && v=$(printf '%s' "$J" | jq -r --arg k "$1" '.[$k] | if . == null then empty else tostring end' 2>/dev/null)
        [ -z "$v" ] && [ -n "$B" ] && v=$(printf '%s' "$B" | jq -r --arg k "$1" '.[$k] | if . == null then empty else tostring end' 2>/dev/null)
    fi
    printf '%s' "${v:-$2}"
}
on() { [ "$(val "$1" true)" != false ]; }
need() {
    have "$1" && return 0
    _g=""
    [ -n "$2" ] && _g=$(get "$2")
    if [ -n "$_g" ]; then out "pkg-$1" "$1 is not installed" "$3" "Installs $2. It asks for your password, then downloads and installs it." "Installs Programs" "$_g"
    else out "pkg-$1" "$1 is not installed" "$3" "1. Open a terminal.\n2. Install ${2:-$1} with this computer's package manager.\n3. Reload Dolphin." "" ""; fi
    return 1
}
aur() {
    have "$1" && return 0
    out "pkg-$1" "$1 is not installed" "$2" "Installs $1. If it is not in the normal package list it is built from the AUR with yay, in a terminal that asks for your password." "Installs Programs" "$(get "$1")"
}
hide() { out "$1" "$2" "$3" "Sets $4 to false in config.json, which hides the widget. Set it back to true to show it again." "Changes Settings" "set:$4=false"; }

[ -n "$q" ] || out pkg-quickshell "Quickshell is not installed" "Dolphin is drawn by Quickshell. Without it nothing can start." "1. Open a terminal.\n2. Run: sudo pacman -S --needed quickshell\n3. Start Dolphin: qs -p $root/Dolphin.qml" "Installs Programs" "$(get quickshell)"
for d in /usr/lib/qt6/qml /usr/lib64/qt6/qml /usr/lib/x86_64-linux-gnu/qt6/qml; do
    [ -d "$d/QtQuick" ] || continue
    if [ ! -d "$d/QtMultimedia" ]; then
        if [ -n "$can" ]; then out pkg-qtmultimedia "Qt Multimedia is not installed" "The movies widget plays video with it, and Dolphin cannot load at all while it is missing." "Runs: pkexec pacman -S --needed qt6-multimedia\nIt asks for your password, then downloads and installs qt6-multimedia." "Installs Programs" "pkexec pacman -S --noconfirm --needed qt6-multimedia"
        else out pkg-qtmultimedia "Qt Multimedia is not installed" "The movies widget plays video with it, and Dolphin cannot load at all while it is missing." "1. Open a terminal.\n2. Install the Qt 6 Multimedia QML module with this computer's package manager.\n3. Start Dolphin again." "" ""; fi
    fi
    break
done
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    out env-hypr "Dolphin is not running under Hyprland" "Workspaces, window previews, key shortcuts and the lock screen all talk to Hyprland. Under another desktop most of Dolphin does nothing." "1. Log out.\n2. On the login screen choose the Hyprland session.\n3. Log in again." "" ""
elif have hyprctl && have jq; then
    hv=$(hyprctl -j version 2>/dev/null | jq -r '.version // .tag // empty' 2>/dev/null)
    hv=${hv#v}
    maj=${hv%%.*}
    min=${hv#*.}
    min=${min%%[!0-9]*}
    case "$maj$min" in
        ""|*[!0-9]*) ;;
        *) [ "$maj" -eq 0 ] && [ "$min" -lt 55 ] && out env-old "Hyprland $hv is too old" "Dolphin's keys and window rules are written for the Lua config that Hyprland reads from version 0.55 on. This version ignores hyprland.lua." "1. Open a terminal.\n2. Run: sudo pacman -Syu\n3. Restart the computer." "" "" ;;
    esac
fi

if [ -n "$J" ] && [ -n "$B" ]; then
    { printf '%s\n' "$J"; printf '%s\n' "$B"; } | jq -r -s '.[0] as $c | .[1] as $b | $c | to_entries[] | select(.value != null and $b[.key] != null and (.value | type) != ($b[.key] | type)) | "\(.key)\t\(.value | type)\t\($b[.key] | type)\t\($b[.key] | tojson | .[0:60])"' 2>/dev/null | while IFS='	' read -r k got want def; do
        out "type-$k" "$k has the wrong kind of value" "config.json gives $k a $got, but Dolphin expects a $want. It ignores your value and uses the default instead." "1. Open $cfg in an editor.\n2. Find \"$k\".\n3. Write its value as a $want. The default is: $def\n4. Save. Dolphin reads the file again by itself." "" ""
    done
    if [ "$(val dolphin_ThemeBackground false)" != true ]; then
        th=$(val dolphin_Theme Default)
        { printf '%s\n' "$J"; printf '%s\n' "$B"; } | jq -e -s --arg t "$th" '((.[0].Theme // {}) + (.[1].Theme // {})) | has($t) or has(($t[0:1] | ascii_upcase) + $t[1:])' >/dev/null 2>&1 || out theme "The theme \"$th\" does not exist" "dolphin_Theme names a theme that is not in the Theme list of config.json, so every colour falls back to black." "Sets dolphin_Theme to \"Default\" in config.json. To use your own theme instead, add it to the Theme list under that exact name." "Changes Settings" "set:dolphin_Theme=\"Default\""
    fi
    la=$(val dolphin_Language en)
    langs=$(jq -r '[.[] | objects | keys[]] | unique | join(" ")' "$root/Data/Static/words.json" 2>/dev/null)
    if [ -n "$langs" ]; then
        case " en $langs " in *" $(printf '%s' "$la" | tr 'A-Z' 'a-z') "*) ;; *) out language "The language \"$la\" is not available" "dolphin_Language is set to \"$la\". Dolphin has words for: en $langs. Everything is shown in English until this is one of them." "Sets dolphin_Language to \"en\" in config.json." "Changes Settings" "set:dolphin_Language=\"en\"" ;; esac
    fi
    printf '%s\n' "$J" | jq -r 'to_entries[] | select((.key | test("Easing(Style)?$")) and (.value | type) == "string" and (.value | test("^(Linear|(In|Out|InOut|OutIn)(Quad|Cubic|Quart|Quint|Sine|Expo|Circ|Back|Elastic|Bounce))$") | not)) | "\(.key)\t\(.value)"' 2>/dev/null | while IFS="$(printf '\t')" read -r k v; do
        d=$(printf '%s' "$B" | jq -r --arg k "$k" '.[$k] // "OutExpo"' 2>/dev/null)
        out "ease-$k" "$k is not an animation curve" "config.json sets $k to \"$v\". Dolphin does not know that name, so it quietly uses the default curve instead. This is usually a typing mistake." "Sets $k back to \"${d:-OutExpo}\" in config.json." "Changes Settings" "set:$k=${d:-OutExpo}"
    done
fi

if [ -d "$root/Data/Dynamic" ] && [ ! -w "$root/Data/Dynamic" ]; then
    out files-locked "Dolphin cannot save settings" "The folder $root/Data/Dynamic cannot be written to, so toggles, pinned apps and scores are lost as soon as they change." "1. Open a terminal.\n2. Run: sudo chown -R $me: $root\n3. If the folder is on a read-only drive, copy Dolphin into your home folder instead." "Changes System" "pkexec chown -R $me: '$root'"
fi
o=$(find "$root" ! -user "$me" -print -quit 2>/dev/null)
if [ -n "$o" ]; then
    if have pkexec; then out files-owner "Some Dolphin files belong to another user" "For example $(rel "$o"). This happens when the folder was copied as root or from another computer, and it stops Dolphin from saving or updating those files." "Runs: pkexec chown -R $me: $root\nIt asks for your password, then makes you the owner of everything in the Dolphin folder." "Changes System" "pkexec chown -R $me: '$root'"
    else out files-owner "Some Dolphin files belong to another user" "For example $(rel "$o"). This happens when the folder was copied as root or from another computer, and it stops Dolphin from saving or updating those files." "1. Open a terminal.\n2. Run: sudo chown -R $me: $root" "" ""; fi
fi
for f in "$hypr/hyprland.lua" "$hypr/hypridle.conf" "$cfg"; do
    [ -f "$f" ] || continue
    o=$(grep -oE '/home/[A-Za-z0-9._-]+' "$f" 2>/dev/null | sort -u | grep -vxF "$HOME" | head -n 3 | tr '\n' ' ')
    if [ -n "$o" ]; then
        c=""
        for u in $o; do c="$c -e 's|$u\\([^A-Za-z0-9._-]\\)|$HOME\\1|g' -e 's|$u\$|$HOME|g'"; done
        t="Changes Scripts"
        [ "$f" = "$cfg" ] && t="Changes Settings"
        out "home-${f##*/}" "${f##*/} points into another user's home folder" "It mentions ${o% }, but your home folder is $HOME. Those paths do not exist for you, so whatever uses them fails." "Replaces ${o% } with $HOME everywhere in $f. Nothing else in the file is changed." "$t" "sed -i$c '$f'"
    fi
done

py=""
list=$(find "$root" \( -name Fonts -o -name Images \) -prune -o -type f \( -name '*.json' -o -name '*.sh' -o -name '*.py' \) -print 2>/dev/null)
old=$IFS
IFS='
'
set -f
for f in $list; do
    n=$(rel "$f")
    edit="1. Open $f in an editor.\n2. Go to the line named in the message and fix it.\n3. If you did not change this file yourself, extract the latest Dolphin archive into $root again to restore it."
    case "$f" in
        "$cfg") ;;
        *.json)
            if have jq && [ -s "$f" ]; then
                e=$(jq empty "$f" 2>&1 >/dev/null | sed -E 's/^jq: error \(at .*:([0-9]+)\): /line \1: /' | lines)
                [ -n "$e" ] && out "bad-$n" "${f##*/} has a mistake" "Dolphin cannot read $n until it is fixed.\n$e" "$edit" "" ""
            fi ;;
        *.sh)
            grep -q "$cr\$" "$f" 2>/dev/null && out "crlf-$n" "${f##*/} has Windows line endings" "The script $n was saved or copied through Windows. Linux reads the extra character at the end of each line as part of the command, so the script fails." "Removes the Windows character from the end of every line of $n. Nothing else in the file changes." "Changes Scripts" "sed -i 's/\\r\$//' '$f'"
            top=""
            run=sh
            IFS= read -r top < "$f" 2>/dev/null
            case "$top" in "#!"*bash*) have bash && run=bash ;; esac
            e=$($run -n "$f" 2>&1 | lines)
            [ -n "$e" ] && out "bad-$n" "${f##*/} has a mistake" "The script $n cannot run until it is fixed.\n${e#"$f": }" "$edit" "" "" ;;
        *.py)
            grep -q "$cr\$" "$f" 2>/dev/null && out "crlf-$n" "${f##*/} has Windows line endings" "The script $n was saved or copied through Windows, which can stop it from starting." "Removes the Windows character from the end of every line of $n. Nothing else in the file changes." "Changes Scripts" "sed -i 's/\\r\$//' '$f'"
            py="$py$f
" ;;
    esac
done
set +f
IFS=$old
if [ -n "$py" ] && have python3; then
    printf '%s' "$py" | python3 -c '
import ast, sys
for p in sys.stdin.read().split("\n"):
    if not p:
        continue
    try:
        ast.parse(open(p, encoding="utf-8").read(), p)
    except SyntaxError as e:
        print("%s\tline %s: %s" % (p, e.lineno, e.msg))
    except Exception as e:
        print("%s\t%s" % (p, e))
' 2>/dev/null | while IFS='	' read -r f e; do
        out "bad-$(rel "$f")" "${f##*/} has a mistake" "The script $(rel "$f") cannot run until it is fixed.\n$e" "1. Open $f in an editor.\n2. Go to the line named in the message and fix it.\n3. If you did not change this file yourself, extract the latest Dolphin archive into $root again to restore it." "" ""
    done
fi
grep -rHo --include='*.qml' 'resolvedUrl("[^"]*")' "$root" 2>/dev/null | while IFS= read -r l; do
    f=${l%%:resolvedUrl(*}
    r=${l#*resolvedUrl(\"}
    r=${r%\")}
    case "${f%/*}/$r" in */Data/Dynamic/*) continue ;; esac
    [ -e "${f%/*}/$r" ] || out "gone-${r##*/}" "${r##*/} is missing" "$(rel "$f") needs ${r##*/}, which is not in the Dolphin folder." "$restore" "" ""
done
grep -rHoE --include='*.qml' '^import "[^"]+"' "$root" 2>/dev/null | while IFS= read -r l; do
    f=${l%%:import \"*}
    r=${l#*:import \"}
    r=${r%\"}
    [ -d "${f%/*}/$r" ] || out "gone-$(rel "$f")-$r" "A Dolphin folder is missing" "$(rel "$f") loads the folder $r, which is not there, so Dolphin cannot start." "$restore" "" ""
done

[ -n "$q" ] && NO_COLOR=1 "$q" log -p "$root/Dolphin.qml" 2>/dev/null | tail -n 4000 | awk -v root="$root" '
{ gsub(/\033\[[0-9;]*m/, "") }
/INFO: Reloading configuration/ { n = 0; split("", cnt); split("", ord); next }
/^ *(WARN|ERROR) / {
    if ($0 ~ /^ *(WARN|ERROR) (qt\.|quickshell\.qmlscanner)/) next
    if (!match($0, /@[^@[]*\.qml\[[0-9]+:/)) next
    ref = substr($0, RSTART + 1, RLENGTH - 2)
    i = index(ref, ".qml[")
    msg = substr($0, RSTART + RLENGTH)
    sub(/^[0-9]+\]:? */, "", msg)
    sub(/:$/, "", msg)
    gsub(/\t/, " ", msg)
    key = substr(ref, 1, i + 3) SUBSEP "line " substr(ref, i + 5) ": " msg
    if (!(key in cnt)) ord[++n] = key
    cnt[key]++
}
END {
    for (i = 1; i <= n; i++) {
        split(ord[i], p, SUBSEP)
        f = p[1]
        if (!(f in body)) { files[++m] = f; body[f] = "" }
        if (++shown[f] <= 5) body[f] = body[f] "\\n" p[2] (cnt[ord[i]] > 1 ? " (" cnt[ord[i]] " times)" : "")
        else extra[f]++
    }
    for (j = 1; j <= m; j++) {
        f = files[j]
        name = f
        sub(/.*\//, "", name)
        printf "qml-%s\t%s has a problem\t%s reported this while running:%s%s\t1. Open %s/%s in an editor.\\n2. Go to the line named in the message.\\n3. If you did not change this file yourself, the mistake is in Dolphin itself: pass the message on so it gets fixed there.\t\t\n", f, name, f, body[f], (extra[f] ? "\\nand " extra[f] " more" : ""), root, f
    }
}'

own="$root/hyprland.lua"
mine=""
[ -f "$own" ] && grep -qsF "${root##*/}/Dolphin.qml" "$own" && mine=1
put="mkdir -p '$hypr' && { [ ! -f '$hypr/hyprland.lua' ] || cp -f '$hypr/hyprland.lua' '$hypr/hyprland.lua.bak'; } && cp -f '$own' '$hypr/hyprland.lua'"
swap="Replaces $hypr/hyprland.lua with Dolphin's own copy, $own, which starts Dolphin and binds all its keys. The file that is there now is kept as hyprland.lua.bak. Hyprland loads the new file by itself."
if [ ! -f "$hypr/hyprland.lua" ]; then
    if [ -n "$mine" ]; then out hypr-file "hyprland.lua is missing" "Hyprland reads its settings and keys from $hypr/hyprland.lua. Without it none of Dolphin's keys are bound." "Copies Dolphin's own hyprland.lua from $own to $hypr/hyprland.lua. It starts Dolphin and binds all its keys. Hyprland loads it by itself." "Changes Scripts" "$put"
    else out hypr-file "hyprland.lua is missing" "Hyprland reads its settings and keys from $hypr/hyprland.lua. Without it none of Dolphin's keys are bound." "1. Log out and back in. Hyprland writes an example hyprland.lua when it finds none.\n2. Open $hypr/hyprland.lua and add the line that starts Dolphin: qs -p $root/Dolphin.qml\n3. Add Dolphin's key binds to it." "" ""; fi
else
    if have hyprctl && e=$(hyprctl configerrors 2>/dev/null); then
        e=$(printf '%s\n' "$e" | lines)
        [ -n "$e" ] && out hypr-error "hyprland.lua has a mistake" "Hyprland reported this when it loaded its config. Lines after the mistake may not be applied.\n$e" "1. Open $hypr/hyprland.lua in an editor.\n2. Go to the line number in the message.\n3. Fix it and save. Hyprland loads the file again by itself." "" ""
    fi
    keys=$(grep -rhoE --include='*.qml' 'appid: "[a-z]+"; name: "[a-z]+"' "$root" 2>/dev/null | sed -E 's/appid: "([a-z]+)"; name: "([a-z]+)"/\1:\2/' | sort -u)
    if [ -n "$keys" ] && ! printf '%s\n' "$keys" | grep -rqsF -f - --include='*.lua' "$hypr"; then
        if [ -n "$mine" ]; then out hypr-keys "hyprland.lua has none of Dolphin's keys" "Dolphin only reacts to keys that hyprland.lua passes on to it, and this hyprland.lua passes none. The session menu, lock screen, overview and keyboard navigation cannot be opened from the keyboard." "$swap" "Changes Scripts" "$put"
        else out hypr-keys "hyprland.lua has none of Dolphin's keys" "Dolphin only reacts to keys that hyprland.lua passes on to it, and this hyprland.lua passes none. The session menu, lock screen, overview and keyboard navigation cannot be opened from the keyboard." "1. Open $hypr/hyprland.lua in an editor.\n2. For each key you want, add a line in this form:\nhl.bind(\"SUPER + M\", hl.dsp.global(\"session:toggle\"))\n3. The names Dolphin listens for are: $(printf '%s' "$keys" | tr '\n' ' ')\n4. Save." "" ""; fi
    fi
    if [ -n "$mine" ] && [ "$own" -nt "$hypr/hyprland.lua" ] && ! cmp -s "$own" "$hypr/hyprland.lua" && grep -qsF "${root##*/}/Dolphin.qml" "$hypr/hyprland.lua"; then
        out hypr-newer "Dolphin's hyprland.lua is newer than the one in use" "$own was changed after $hypr/hyprland.lua, for example by an update from another computer, so its keys and settings are not active here yet." "$swap" "Changes Scripts" "$put"
    fi
    if ! grep -rqsF --include='*.lua' "${root##*/}/Dolphin.qml" "$hypr"; then
        if [ -n "$mine" ]; then out hypr-start "Dolphin does not start with Hyprland" "Nothing in $hypr starts Dolphin, so it will not come back after a restart." "$swap" "Changes Scripts" "$put"
        else out hypr-start "Dolphin does not start with Hyprland" "Nothing in $hypr starts Dolphin, so it will not come back after a restart." "1. Open $hypr/hyprland.lua in an editor.\n2. In the part that starts programs, add a line that runs: qs -p $root/Dolphin.qml\n3. Save." "" ""; fi
    fi
fi

conf="${XDG_CONFIG_HOME:-$HOME/.config}"
if have jq; then
    { [ -n "$J" ] && printf '%s' "$J" | jq -e 'has("updater_Carry")' >/dev/null 2>&1 && printf '%s' "$J" || printf '%s' "$B"; } | jq -r '(.updater_Carry // [])[] | strings' 2>/dev/null | while IFS= read -r n; do
        case "$n" in ""|/*|*..*) continue ;; esac
        o="$root/config/$n"
        l="$conf/$n"
        [ -e "$o" ] || continue
        if [ ! -e "$l" ]; then
            out "carry-$n" "Your $n settings are not on this computer" "Dolphin carries a copy of $l in $o, and this computer has none yet, so $n starts with its defaults." "Copies $o to $l." "Changes Settings" "mkdir -p '$(dirname "$l")' && cp -rT '$o' '$l'"
        elif ! diff -rq "$o" "$l" >/dev/null 2>&1; then
            r=$(find "$l" -type f -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-)
            [ -n "$r" ] && [ -n "$(find "$o" -type f -newer "$r" -print -quit)" ] && out "carry-new-$n" "The $n settings in Dolphin are newer than the ones in use" "$o was changed after $l, for example by an update from another computer, so those changes are not active here yet." "Copies $o over $l. What is there now is kept as $l.bak." "Changes Settings" "cp -rT '$l' '$l.bak' && cp -rT '$o' '$l'"
        fi
    done
fi
listed() {
    [ -s "$1" ] && have pacman || return 0
    gone=$(grep -vE '^[[:space:]]*(#|$)' "$1" | awk '$1 !~ /-debug$/ {print $1}' | sort -u | pacman -T - 2>/dev/null)
    [ -n "$gone" ] || return 0
    split=$({ printf '%s\n' "$repo"; echo ---; printf '%s\n' "$gone"; } | awk '/^---$/ { s = 1; next } !s { r[$0] = 1; next } NF { print (($0 in r) ? "E " : "H ") $0 }')
    easy=$(printf '%s\n' "$split" | sed -n 's/^E //p')
    hard=$(printf '%s\n' "$split" | sed -n 's/^H //p')
    if [ -n "$easy" ]; then
        n=$(printf '%s\n' "$easy" | wc -l)
        e=$(printf '%s' "$easy" | tr '\n' ' ')
        if have pacman; then out "$2" "$3 are not installed ($n)" "$1 $4 Missing here: $e" "Runs: pkexec pacman -S --needed $e\nIt asks for your password, then downloads and installs them." "Installs Programs" "pkexec pacman -S --noconfirm --needed $e"
        else out "$2" "$3 are not installed ($n)" "$1 $4 Missing here: $e" "1. Open a terminal.\n2. Install them with this computer's package manager." "" ""; fi
    fi
    if [ -n "$hard" ]; then
        n=$(printf '%s\n' "$hard" | wc -l)
        e=$(printf '%s' "$hard" | tr '\n' ' ')
        out "$2-aur" "$3 from the AUR are not installed ($n)" "They are not in the normal package list, so they are built with yay. Missing here: $e" "Opens a terminal, installs yay if it is missing, then builds and installs them. It asks for your password." "Installs Programs" "term:sh '$ins' get $e"
    fi
}
listed "$root/packages.txt" pkg-list "Programs from packages.txt" "lists the programs this Dolphin setup uses."
listed "$root/Data/Static/apps.txt" pkg-apps "Apps from apps.txt" "lists your own apps. Press Ignore to leave them out on this computer."
have jq || need jq jq "Dolphin uses jq to read colours from the wallpaper and to run these checks properly."
need curl curl "The weather and location widgets download their data with curl."
need notify-send libnotify "Dolphin sends its own messages (for example after an uninstall) with notify-send."
need fc-list fontconfig "Fonts are looked up with fontconfig."
have pkexec || out pkg-pkexec "pkexec is not installed" "Fixes that install programs or change the system ask for your password through polkit. Without it they cannot run." "1. Open a terminal.\n2. Run: sudo pacman -S --needed polkit\n3. Reload Dolphin." "Installs Programs" "term:sudo pacman -S --needed polkit"
if have pkexec && ! pgrep -f 'polkit.*agent|polkit-kde|hyprpolkitagent|lxpolkit|polkit-gnome' >/dev/null 2>&1; then
    out polkit "No password prompt is running" "A polkit agent shows the password window for fixes that install programs or change the system. None is running, so those fixes will fail." "1. Open a terminal.\n2. Run: sudo pacman -S --needed hyprpolkitagent\n3. Run: systemctl --user enable --now hyprpolkitagent\n4. Press Check again." "Installs Programs" "term:sh '$ins' get hyprpolkitagent; [ -z \"\$WAYLAND_DISPLAY\" ] || setsid -f /usr/lib/hyprpolkitagent/hyprpolkitagent >/dev/null 2>&1"
fi

gpu=""
for c in /sys/class/drm/card[0-9]; do
    [ -e "$c/device/vendor" ] || continue
    read -r v < "$c/device/vendor"
    d=""
    [ -e "$c/device/driver" ] && { d=$(readlink "$c/device/driver"); d=${d##*/}; }
    if [ "$v" = 0x10de ]; then
        if [ "$d" = nvidia ] && [ -r /sys/module/nvidia_drm/parameters/modeset ]; then
            read -r m < /sys/module/nvidia_drm/parameters/modeset
            [ "$m" = N ] && { gpu=1; out gpu-modeset "The NVIDIA driver is not in Wayland mode" "The driver is installed, but its modeset option is off. Hyprland needs it on, otherwise the screen stays black, flickers or runs without acceleration." "1. Open a terminal.\n2. Run: echo 'options nvidia_drm modeset=1' | sudo tee /etc/modprobe.d/nvidia.conf\n3. Run: sudo mkinitcpio -P\n4. Restart the computer." "Changes System" "pkexec sh -c \"echo 'options nvidia_drm modeset=1' > /etc/modprobe.d/nvidia.conf && mkinitcpio -P\""; }
        fi
        [ -n "$d" ] && [ "$d" != nouveau ] && continue
        gpu=1
        read -r id < "$c/device/device"
        name=""
        have lspci && name=$(lspci -d "10de:${id#0x}" 2>/dev/null | sed -n '1s/^[^:]*:[^:]*: //p')
        name=${name:-NVIDIA card $id}
        state="No driver is loaded for it"
        [ "$d" = nouveau ] && state="It is running on the basic nouveau driver, which is slow and often glitchy with Hyprland"
        if [ $((id)) -ge $((0x1e00)) ]; then
            base=""
            [ -r "/usr/lib/modules/$(uname -r)/pkgbase" ] && read -r base < "/usr/lib/modules/$(uname -r)/pkgbase"
            pk="nvidia-open nvidia-utils"
            [ "$base" = linux ] || pk="nvidia-open-dkms nvidia-utils${base:+ $base-headers}"
            out "gpu-${c##*/}" "Graphics driver missing: $name" "$state. This card is new enough for NVIDIA's current driver." "1. Open a terminal.\n2. Run: sudo pacman -S --needed $pk\n3. Restart the computer." "Installs Programs" "$(get "$pk")"
        elif have yay; then
            out "gpu-${c##*/}" "Graphics driver missing: $name" "$state. This card is too old for NVIDIA's current driver and needs the 580 series from the AUR." "1. Open a terminal.\n2. Run: yay -S nvidia-580xx-dkms nvidia-580xx-utils\n3. Restart the computer." "Installs Programs" "term:sh '$ins' get nvidia-580xx-dkms nvidia-580xx-utils"
        else
            out "gpu-${c##*/}" "Graphics driver missing: $name" "$state. This card is too old for NVIDIA's current driver and needs the 580 series from the AUR." "1. Open a terminal.\n2. Install an AUR helper such as yay.\n3. Run: yay -S nvidia-580xx-dkms nvidia-580xx-utils\n4. Restart the computer." "Installs Programs" "term:sh '$ins' get nvidia-580xx-dkms nvidia-580xx-utils"
        fi
        continue
    fi
    case "$v" in 0x1002) n="AMD" ;; 0x8086) n="Intel" ;; *) n="unknown" ;; esac
    [ -n "$d" ] || gpu=1
    [ -n "$d" ] || out "gpu-${c##*/}" "No driver is loaded for the $n graphics card" "The system is not using this graphics card, so the desktop will be slow or may not start. AMD and Intel cards are driven by the kernel together with the mesa package." "1. Open a terminal.\n2. Run: sudo pacman -S --needed mesa linux-firmware\n3. Restart the computer.\n4. If this is still listed, the kernel is too old for the card. Run: sudo pacman -Syu and restart again." "Installs Programs" "$(get "mesa linux-firmware")"
    if have pacman && ! pacman -Qq mesa >/dev/null 2>&1; then
        out gpu-mesa "The mesa graphics library is missing" "AMD and Intel graphics need mesa for the desktop to be drawn by the graphics card." "1. Open a terminal.\n2. Run: sudo pacman -S --needed mesa\n3. Restart the computer." "Installs Programs" "$(get mesa)"
    fi
done
set -- /dev/dri/renderD*
[ -n "$gpu" ] || [ -e "$1" ] || out gpu-none "The graphics card is not being used" "No graphics device is available to programs, so the whole desktop is drawn by the processor. Animations stutter, blur is slow and the fans run." "1. If this is a virtual machine, turn on 3D acceleration in its settings.\n2. Otherwise open a terminal and run: sudo pacman -Syu mesa linux-firmware\n3. Restart the computer." "" ""
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && have hyprctl && have jq; then
    modes=$(grep -E '^[[:space:]]*mode[[:space:]]*=[[:space:]]*"' "$hypr/hyprland.lua" 2>/dev/null | grep -cv '"highres"')
    [ "$(grep -cE '^[[:space:]]*mode[[:space:]]*=[[:space:]]*"' "$hypr/hyprland.lua" 2>/dev/null)" = 1 ] || modes=0
    hyprctl -j monitors 2>/dev/null | jq -r '.[] | . as $m | ([.availableModes[]? | capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)") | select((.w | tonumber) == $m.width and (.h | tonumber) == $m.height) | .r | tonumber] | max // 0) as $top | select($top > $m.refreshRate + 1) | "\($m.name)\t\($m.width)x\($m.height)\t\($m.refreshRate | round)\t\($top | round)"' 2>/dev/null | while IFS='	' read -r mn res now top; do
        if [ "$modes" = 1 ]; then out "screen-$mn" "Screen $mn runs at $now Hz but can do $top Hz" "Everything looks less smooth than this screen allows. This happens when hyprland.lua was written for a different screen and Hyprland falls back to a safe mode." "Sets the screen mode in $hypr/hyprland.lua to highres. With it Hyprland picks the sharpest picture each screen offers at its fastest rate, on this computer and on any other. Hyprland applies it by itself." "Changes Scripts" "sed -i -E 's/^([[:space:]]*mode[[:space:]]*=[[:space:]]*)\"[^\"]*\"/\\1\"highres\"/' '$hypr/hyprland.lua'"
        else out "screen-$mn" "Screen $mn runs at $now Hz but can do $top Hz" "Everything looks less smooth than this screen allows. This happens when hyprland.lua was written for a different screen and Hyprland falls back to a safe mode." "1. Open $hypr/hyprland.lua in an editor.\n2. Find the line that sets up monitors.\n3. Set $mn to $res@$top\n4. Save. Hyprland applies it by itself." "" ""; fi
    done
fi

if need wpctl wireplumber "Volume keys, the sound widget and the sound bar use wpctl."; then
    if wpctl status >/dev/null 2>&1; then
        sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        case "$sink" in ""|*auto_null*|*"Dummy Output"*) sleep 2; sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null) ;; esac
        case "$sink" in ""|*auto_null*|*"Dummy Output"*) out audio-none "No speakers or headphones found" "The sound server is running but has no real output to play through. On a new laptop this usually means the sound card's firmware is not installed." "1. Open a terminal.\n2. Run: sudo pacman -S --needed sof-firmware alsa-firmware\n3. Restart the computer.\n4. If it is still listed, check that the output is not disabled: wpctl status" "Installs Programs" "$(get "sof-firmware alsa-firmware")" ;; esac
    fi
    wpctl status >/dev/null 2>&1 || out audio "The sound server is not running" "PipeWire or WirePlumber is not running, so volume controls and the sound widget do nothing." "Runs: systemctl --user enable --now pipewire pipewire-pulse wireplumber\nStarts the sound services now and at every login. No password is needed." "Changes System" "systemctl --user enable --now pipewire pipewire-pulse wireplumber"
fi

if on touchpad_Show; then
    if ! grep -qi touchpad /proc/bus/input/devices 2>/dev/null; then
        out touchpad "No touchpad found" "This computer has no touchpad, so the edge swipes for volume and brightness do nothing here." "Sets touchpad_Show to false in config.json. That turns the edge swipes off and stops the Touchpad.py script that was waiting for a touchpad." "Changes Scripts" "set:touchpad_Show=false"
    elif need python3 python "The touchpad swipes run a small Python script."; then
        ev=1
        python3 -c 'import evdev' 2>/dev/null || {
            ev=""
            if [ -n "$can" ]; then out touchpad-evdev "Touchpad swipes are missing python-evdev" "The swipe script reads the touchpad through the python-evdev package, which is not installed." "Runs: pkexec pacman -S --needed python-evdev\nIt asks for your password, then downloads and installs python-evdev." "Installs Programs" "pkexec pacman -S --noconfirm --needed python-evdev"
            else out touchpad-evdev "Touchpad swipes are missing python-evdev" "The swipe script reads the touchpad through the python-evdev package, which is not installed." "1. Open a terminal.\n2. Install python-evdev with this computer's package manager.\n3. Reload Dolphin." "" ""; fi
        }
        ok=""
        for e in /dev/input/event*; do [ -r "$e" ] && { ok=1; break; }; done
        if [ -z "$ok" ]; then
            if have pkexec; then out touchpad-access "Touchpad swipes are not allowed to read the touchpad" "Your user cannot read input devices." "Runs: pkexec usermod -aG input $USER\nAdds your user to the input group so the swipe script may read the touchpad. It takes effect after you log out and back in." "Changes System" "pkexec usermod -aG input $USER"
            else out touchpad-access "Touchpad swipes are not allowed to read the touchpad" "Your user cannot read input devices." "1. Open a terminal.\n2. Run: sudo usermod -aG input $USER\n3. Log out and back in." "" ""; fi
        fi
        tp="$root/Interface/Hidden/Touchpad/Touchpad.py"
        if [ -n "$ok" ] && [ -n "$ev" ] && [ -f "$tp" ] && ! pgrep -f "Touchpad/Touchpad\.py" >/dev/null 2>&1; then
            if [ -n "$q" ]; then out touchpad-dead "The touchpad script is not running" "The edge swipes for volume and brightness do nothing while it is stopped. If it keeps stopping, run this in a terminal to see why: python3 $tp" "Starts Touchpad.py again. Nothing else is touched." "Changes Scripts" "$q -p '$root/Dolphin.qml' ipc call touchpad restart"
            else out touchpad-dead "The touchpad script is not running" "The edge swipes for volume and brightness do nothing while it is stopped." "1. Reload Dolphin.\n2. If it stops again, run this in a terminal to see why: python3 $tp" "" ""; fi
        fi
    fi
fi

set -- /sys/class/backlight/*
if [ ! -e "$1" ]; then
    on widget_BrightnessShow && hide backlight "This screen's brightness cannot be changed" "No backlight was found, which is normal for a desktop monitor. The brightness widget, bar and keys do nothing here." widget_BrightnessShow
else
    need brightnessctl brightnessctl "The brightness widget, bar and keys use brightnessctl."
fi

set -- /sys/class/power_supply/BAT*
if [ -e "$1" ]; then
    on widget_BatteryShow && need upower upower "The battery widget reads the battery through UPower."
else
    on widget_BatteryShow && hide battery "No battery found" "This computer has no battery, so the battery widget has nothing to show." widget_BatteryShow
fi

if on widget_NetworkShow; then
    i=$(val widget_NetworkInterface wlan0)
    if [ ! -e "/sys/class/net/$i" ]; then
        first=""
        for d in /sys/class/net/*/wireless; do [ -e "$d" ] && { first=${d%/wireless}; first=${first##*/}; break; }; done
        if [ -n "$first" ]; then out wifi-name "Wi-Fi device \"$i\" does not exist" "The network widget is set to \"$i\", but this computer's Wi-Fi device is called \"$first\"." "Sets widget_NetworkInterface to \"$first\" in config.json, so the network widget and Wi-Fi panel use this computer's Wi-Fi device." "Changes Settings" "set:widget_NetworkInterface=\"$first\""
        else hide wifi-none "No Wi-Fi device found" "This computer has no Wi-Fi card the system can see, so the network widget and Wi-Fi panel cannot work. A missing Wi-Fi driver also looks like this." widget_NetworkShow; fi
    fi
    if need iwctl iwd "The Wi-Fi panel lists and joins networks through iwd."; then
        systemctl is-active --quiet iwd 2>/dev/null || out wifi-iwd "The iwd service is not running" "The Wi-Fi panel talks to iwd. If this computer connects with NetworkManager instead, the panel cannot list or join networks." "1. Open a terminal.\n2. If this computer should use iwd, run: sudo systemctl enable --now iwd\n3. If it uses NetworkManager, leave iwd off and press Ignore, or set widget_NetworkShow to false in config.json." "Changes System" "pkexec systemctl enable --now iwd"
    fi
fi

if on widget_BluetoothShow; then
    set -- /sys/class/bluetooth/hci*
    if [ ! -e "$1" ]; then
        hide bluetooth "No Bluetooth adapter found" "This computer has no Bluetooth the system can see, so the Bluetooth panel stays empty." widget_BluetoothShow
    elif ! systemctl cat bluetooth.service >/dev/null 2>&1; then
        need bluetoothd bluez "The Bluetooth panel talks to the bluez service."
    elif ! systemctl is-active --quiet bluetooth 2>/dev/null; then
        if have pkexec; then out bluetooth-off "The Bluetooth service is not running" "The adapter is there, but the bluetooth service that controls it is stopped." "Runs: pkexec systemctl enable --now bluetooth\nIt asks for your password, then starts the Bluetooth service now and at every start-up." "Changes System" "pkexec systemctl enable --now bluetooth"
        else out bluetooth-off "The Bluetooth service is not running" "The adapter is there, but the bluetooth service that controls it is stopped." "1. Open a terminal.\n2. Run: sudo systemctl enable --now bluetooth" "" ""; fi
    fi
fi

on widget_KeyboardShow && need wtype wtype "The on-screen keyboard types into other apps with wtype."
if on snip_Show; then
    need grim grim "The screenshot tool takes its picture with grim."
    need wl-copy wl-clipboard "The screenshot tool puts the picture on the clipboard with wl-copy."
fi
on widget_NightShow && need hyprsunset hyprsunset "Night light changes the screen colour with hyprsunset."

np=$(pic "$root/Data/Static/Images/Wallpaper")
lp=$(pic "$root/Data/Static/Images/Lockscreen" 'avatar*')
lp=${lp:-$np}
ap=$(find "$root/Data/Static/Images/Lockscreen" -maxdepth 1 -type f -iname 'avatar*' 2>/dev/null | head -n 1)
b=$(val dolphin_Background "")
if [ -n "$b" ] && [ "$b" != true ] && [ "$b" != false ]; then
    [ -f "$(path "$b")" ] || out file-background "The wallpaper file is missing" "dolphin_Background points to $b, which does not exist, so the background stays black." "${np:+Sets dolphin_Background to $np\n}1. Put the picture back at $b, or\n2. Open $cfg and set dolphin_Background to a picture that exists." "${np:+Changes Settings}" "${np:+set:dolphin_Background=$(short "$np")}"
    aur awww "Dolphin sets the wallpaper with awww."
    if [ "$(val dolphin_ThemeBackground false)" = true ]; then
        aur matugen "Colours from the wallpaper are picked with matugen."
        te="${XDG_RUNTIME_DIR:-/tmp}/dolphin-theme.err"
        have matugen && [ -s "$te" ] && out theme-matugen "matugen could not pick the wallpaper colours" "Dolphin used its own simpler colour picker instead, so the theme still follows the wallpaper but the colours are less exact. matugen said:\n$(lines < "$te")" "1. Open a terminal.\n2. Update matugen with: yay -S matugen\n3. Change the wallpaper once. This entry goes away when matugen works again." "" ""
    fi
fi
l=$(val dolphin_Lockscreen "")
[ -n "$l" ] && [ ! -f "$(path "$l")" ] && out file-lockscreen "The lock screen picture is missing" "dolphin_Lockscreen points to $l, which does not exist, so the lock and login screens show a black background." "${lp:+Sets dolphin_Lockscreen to $lp\n}1. Put the picture back at $l, or\n2. Open $cfg and set dolphin_Lockscreen to a picture that exists." "${lp:+Changes Settings}" "${lp:+set:dolphin_Lockscreen=$(short "$lp")}"
a=$(val greeter_Avatar "~/Dolphin/Data/Static/Images/Lockscreen/avatar.png")
[ -f "$(path "$a")" ] || out file-avatar "The login picture is missing" "greeter_Avatar points to $a, which does not exist, so the login screen shows an empty circle." "${ap:+Sets greeter_Avatar to $ap\n}1. Put a square picture at $a, or\n2. Open $cfg and set greeter_Avatar to a picture that exists." "${ap:+Changes Settings}" "${ap:+set:greeter_Avatar=$(short "$ap")}"

if on lockscreen_Show; then
    p=$(val lockscreen_Pam dolphin-lock)
    if [ ! -f "/etc/pam.d/$p" ]; then
        if have pkexec; then out pam "The lock screen cannot check your password" "The file /etc/pam.d/$p is missing, so the lock screen would refuse every password. Do not lock the screen until this is repaired." "Asks for your password, then creates /etc/pam.d/$p with the single line: auth include login\nThat lets the lock screen check your normal login password." "Changes System" "pkexec sh -c \"echo 'auth include login' > /etc/pam.d/$p\""
        else out pam "The lock screen cannot check your password" "The file /etc/pam.d/$p is missing, so the lock screen would refuse every password. Do not lock the screen until this is repaired." "1. Open a terminal.\n2. Run: echo 'auth include login' | sudo tee /etc/pam.d/$p" "" ""; fi
    fi
fi

if on lockscreen_Show; then
    if need hypridle hypridle "hypridle locks the screen when the lid closes or the computer sleeps."; then
        ic=""
        [ -e "$hypr/hypridle.conf" ] || ic="mkdir -p '$hypr' && printf 'general {\\n    lock_cmd = qs -p $root/Dolphin.qml ipc call lockscreen lock\\n    before_sleep_cmd = loginctl lock-session\\n}\\n' > '$hypr/hypridle.conf'"
        if ! grep -qs "lockscreen" "$hypr/hypridle.conf"; then
            out idle-lock "Closing the lid does not lock the screen" "hypridle is not set up to call Dolphin's lock screen, so the computer wakes up unlocked or shows a different lock screen." "1. Open $hypr/hypridle.conf in an editor (create it if it is not there).\n2. Inside the general { } block set:\nlock_cmd = qs -p $root/Dolphin.qml ipc call lockscreen lock\nbefore_sleep_cmd = loginctl lock-session\n3. Save, then log out and back in." "${ic:+Changes Settings}" "$ic"
        elif ! pgrep -x hypridle >/dev/null 2>&1; then
            out idle-off "hypridle is not running" "Nothing is watching for the lid closing or the computer going to sleep, so the screen does not lock by itself." "Starts hypridle now. To have it start at every login, it also needs a line in the part of hyprland.lua that starts programs." "Changes System" "setsid -f hypridle >/dev/null 2>&1"
        fi
    fi
fi

boot="$root/Interface/Hidden/Updater/Boot.sh"
st=$(val updater_SplashTheme custom)
case "$st" in ""|*/*|*..*) st="" ;; esac
sp="$root/system/plymouth/$st"
if [ -n "$st" ] && [ -d "$sp" ]; then
    if ! have plymouth; then
        need plymouth plymouth "The picture shown while the computer starts is drawn by Plymouth."
    else
        if ! diff -rq "$sp" "/usr/share/plymouth/themes/$st" >/dev/null 2>&1 || ! grep -qs "^Theme=$st\$" /etc/plymouth/plymouthd.conf; then
            out splash-theme "The start-up picture is not Dolphin's" "Dolphin carries its start-up picture (the Plymouth theme $st) in $sp. This computer shows a different one, or none." "Copies $sp to /usr/share/plymouth/themes/$st, makes it the active theme and rebuilds the start-up image. It asks for your password and shows from the next start." "Changes System" "pkexec sh '$boot' theme '$sp' '$st'"
        fi
        if [ -f /etc/mkinitcpio.conf ] && ! grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
            out splash-hook "The start-up picture is not loaded early" "Plymouth is installed but is not part of the start-up image, so the screen shows text instead of the picture." "Adds plymouth to the HOOKS line of /etc/mkinitcpio.conf (the old file is kept as mkinitcpio.conf.bak) and rebuilds the start-up image. It asks for your password and shows from the next start." "Changes System" "pkexec sh '$boot' hook"
        fi
        if [ "$(val updater_SplashOnShutdown false)" != true ] && have systemctl; then
            loud=""
            for u in plymouth-halt plymouth-kexec plymouth-poweroff plymouth-reboot; do
                [ "$(systemctl is-enabled "$u.service" 2>/dev/null)" = masked ] || loud=1
            done
            [ -n "$loud" ] && out splash-hush "The start-up picture also shows when shutting down" "Dolphin's setup keeps the screen black while the computer shuts down or restarts. On this computer Plymouth still draws its picture then." "Masks the four Plymouth services for shutting down and restarting (halt, kexec, poweroff, reboot), so the picture only shows while starting. It asks for your password. Set updater_SplashOnShutdown to true to keep the picture instead." "Changes System" "pkexec sh '$boot' hush"
        fi
        if ! grep -qE '(^| )splash( |$)' /proc/cmdline 2>/dev/null; then
            out splash-cmdline "The start-up picture is switched off" "The kernel was started without the word splash, so Plymouth stays hidden and the start-up text shows instead." "Adds quiet and splash to the kernel line of the boot loader (systemd-boot, a unified kernel image or GRUB; the old file is kept with .bak at the end). It asks for your password and shows from the next start." "Changes System" "pkexec sh '$boot' splash"
        fi
    fi
fi
if [ -f "$root/Interface/Greeter/Greeter.qml" ] && ! grep -qs "Greeter.qml" /etc/greetd/config.toml; then
    if ! have greetd || ! have cage; then
        if [ -n "$can" ]; then out greeter-pkg "The login screen needs greetd and cage" "Dolphin's login screen is started by greetd inside cage, and they are not installed, so this computer shows a different login screen." "Runs: pkexec pacman -S --needed greetd cage\nIt asks for your password, then downloads and installs them." "Installs Programs" "pkexec pacman -S --noconfirm --needed greetd cage"
        else out greeter-pkg "The login screen needs greetd and cage" "Dolphin's login screen is started by greetd inside cage, and they are not installed, so this computer shows a different login screen." "1. Open a terminal.\n2. Install greetd and cage with this computer's package manager." "" ""; fi
    else
        out greeter-setup "Dolphin's login screen is not set up" "This computer starts with a different login screen, or with none." "Writes /etc/greetd/config.toml so that greetd starts $root/Interface/Greeter/Greeter.qml (the old file is kept as config.toml.bak), switches off other login screens (sddm, ly, gdm, lightdm) and switches greetd on. It asks for your password and shows from the next start. If the login screen ever stays black, press Ctrl+Alt+F2 to log in on a text screen." "Changes System" "pkexec sh '$boot' greeter '$root'"
    fi
fi
g=/etc/greetd/config.toml
if grep -qs "Greeter.qml" "$g"; then
    gp=$(grep -oE '[^ "=]*/Interface/Greeter/Greeter\.qml' "$g" | head -n 1)
    if [ -n "$gp" ] && [ ! -f "$gp" ]; then
        out greeter-path "The login screen points to a file that is not there" "$g starts $gp, which does not exist on this computer, so the login screen stays black." "1. Open a terminal.\n2. Run: sudo nvim $g\n3. Change the path to: $root/Interface/Greeter/Greeter.qml\n4. Save and restart the computer." "Changes System" "pkexec sed -i 's|$gp|$root/Interface/Greeter/Greeter.qml|' '$g'"
    fi
    grep -qs cage "$g" && need cage cage "The login screen is shown inside cage."
    if id greeter >/dev/null 2>&1 && have getfacl; then
        ok=1
        for d in "$HOME" "$root"; do
            case "$(stat -c %A "$d" 2>/dev/null)" in ?????????x*) continue ;; esac
            getfacl -p "$d" 2>/dev/null | grep -q '^user:greeter:..x' || ok=""
        done
        [ -n "$ok" ] || out greeter-access "The login screen is not allowed to read Dolphin" "The login screen runs as the user greeter, which cannot open $root. It shows a black screen instead of the login." "Runs these three commands, which need no password:\nsetfacl -m u:greeter:x $HOME\nsetfacl -R -m u:greeter:rX $root\nsetfacl -R -d -m u:greeter:rX $root\nThey let the greeter user pass through your home folder and read the Dolphin folder, and nothing else." "Changes System" "setfacl -m u:greeter:x '$HOME' && setfacl -R -m u:greeter:rX '$root' && setfacl -R -d -m u:greeter:rX '$root'"
    fi
fi

if have fc-list; then
    t=$(val dolphin_TextFont "Maple Mono NF")
    i=$(val dolphin_IconFont "Maple Mono NF")
    fams=$(fc-list : family 2>/dev/null)
    seen=""
    fc-list 2>/dev/null | grep -qF "$root/Data/Static/Fonts/" && seen=1
    set -- "$root"/Data/Static/Fonts/*
    if [ -z "$seen" ] && [ -e "$1" ] && ! printf '%s\n' "$fams" | grep -qiF "$t"; then
        out font-folder "This computer does not look in Dolphin's font folder" "Dolphin keeps its fonts in Data/Static/Fonts, but the system has not been told about that folder, so \"$t\" and the icons are not found." "Runs:\nmkdir -p ~/.local/share/fonts\nln -sfn $root/Data/Static/Fonts ~/.local/share/fonts/Dolphin\nfc-cache -f\nThat adds a link to Dolphin's fonts in your own font folder and refreshes the font list. No password is needed. Reload Dolphin afterwards." "Changes System" "mkdir -p \"\$HOME/.local/share/fonts\" && ln -sfn '$root/Data/Static/Fonts' \"\$HOME/.local/share/fonts/Dolphin\" && fc-cache -f"
        t=""
    fi
    fp=""
    case "$t" in "Maple Mono"*) fp=$(get maplemono-nf-unhinted) ;; esac
    fq=""
    case "$i" in "Maple Mono"*) fq=$(get maplemono-nf-unhinted) ;; esac
    [ -z "$t" ] || printf '%s\n' "$fams" | grep -qiF "$t" || out font-text "The font \"$t\" is not installed" "Text falls back to a different font, so sizes and spacing will look wrong." "1. Copy the font files into $root/Data/Static/Fonts\n2. Open a terminal and run: fc-cache -f\n3. Reload Dolphin.\nOr set dolphin_TextFont in config.json to a font this computer has. This lists them: fc-list : family" "${fp:+Installs Programs}" "$fp"
    if [ -n "$t" ] && printf '%s\n' "$fams" | grep -qiF "$i" && ! fc-list ":charset=f233" family 2>/dev/null | grep -qiF "$i"; then
        out font-glyphs "The icon font \"$i\" has no icons in it" "Dolphin draws its icons as letters from a Nerd Font. \"$i\" is installed but is the plain version without those letters, so icons show as empty boxes." "1. Download the Nerd Font version of the font (the name ends in NF or Nerd Font).\n2. Copy it into $root/Data/Static/Fonts\n3. Open a terminal and run: fc-cache -f\n4. Set dolphin_IconFont in config.json to its exact name.\n5. Reload Dolphin." "" ""
    fi
    [ -z "$t" ] || [ "$i" = "$t" ] || printf '%s\n' "$fams" | grep -qiF "$i" || out font-icon "The icon font \"$i\" is not installed" "Icons set by code will show as empty boxes." "1. Copy a Nerd Font into $root/Data/Static/Fonts\n2. Open a terminal and run: fc-cache -f\n3. Set dolphin_IconFont in config.json to that font's name.\n4. Reload Dolphin." "${fq:+Installs Programs}" "$fq"
fi

if have jq && [ -n "${J:-$B}" ]; then
    it=$(printf '%s' "${J:-$B}" | jq -r '.Kde.Icons.Theme // empty' 2>/dev/null)
    [ -n "$it" ] || it=$(printf '%s' "$B" | jq -r '.Kde.Icons.Theme // empty' 2>/dev/null)
    if [ -n "$it" ]; then
        need kwriteconfig6 kconfig "Colours and icons for apps such as the file manager are written with kwriteconfig6."
        if [ ! -d "/usr/share/icons/$it" ] && [ ! -d "$HOME/.local/share/icons/$it" ] && [ ! -d "$HOME/.icons/$it" ]; then
            case "$it" in
                Papirus*) [ -n "$can" ] && it="" && out icons "The Papirus icon theme is not installed" "App icons on the taskbar, in the overview and in the app list come from this theme. Without it many icons are blank or generic." "Runs: pkexec pacman -S --needed papirus-icon-theme\nIt asks for your password, then downloads and installs the theme." "Installs Programs" "pkexec pacman -S --noconfirm --needed papirus-icon-theme" ;;
            esac
            [ -n "$it" ] && out icons "The icon theme \"$it\" is not installed" "App icons on the taskbar, in the overview and in the app list come from this theme. Without it many icons are blank or generic." "1. Install the theme, or copy its folder into ~/.local/share/icons\n2. Or open $cfg and set Theme under Kde > Icons to a theme from /usr/share/icons\n3. Reload Dolphin." "" ""
        fi
    fi
fi

if on ai_Show; then
    srv=$(val ai_Server llama-server)
    have "$srv" || out pkg-llama "llama-server is not installed" "The AI window runs models with llama.cpp. Without it no model can load." "1. Open a terminal.\n2. Run: sudo pacman -S --needed llama-cpp llama-cpp-vulkan\n3. If pacman cannot find them, run: yay -S llama.cpp-vulkan\n4. Press Check again." "Installs Programs" "$(get "$llama")"
    need curl curl "The AI window talks to the model through curl."
    for f in Run.sh Attach.sh Tools.sh; do
        [ -f "$root/Interface/Binded/AI Model/$f" ] || out "gone-$f" "$f is missing" "Interface/Binded/AI Model/AIModel.qml needs $f, which is not in the Dolphin folder." "$restore" "" ""
    done
    need ffmpeg ffmpeg "Pictures, screenshots and videos given to the AI are resized with ffmpeg."
    need wl-paste wl-clipboard "Pasting a screenshot into the AI window reads the clipboard with wl-paste."
    md=$(val ai_ModelsFolder "Data/Static/AI Models")
    case "$md" in /*) ;; "~"|"~/"*) md="$HOME${md#"~"}" ;; *) md="$root/$md" ;; esac
    if [ ! -d "$md" ]; then
        out ai-folder "The AI models folder is missing" "The AI window looks for models in $md, and that folder does not exist." "Creates the empty folder $md. Put your .gguf model files in it afterwards." "Changes System" "mkdir -p '$md'"
    else
        set -- "$md"/*.gguf
        if [ ! -e "$1" ]; then
            out ai-empty "There are no AI models" "The folder $md has no .gguf files in it, so the AI window has nothing to load. Models in sub-folders are not used." "1. Download a model in GGUF format.\n2. Put the .gguf file directly in $md\n3. For a vision model, put its .mmproj file next to it with the same name." "" ""
        fi
        for m in "$md"/*.mmproj; do
            [ -e "$m" ] || continue
            [ -f "${m%.mmproj}.gguf" ] || out "ai-proj-${m##*/}" "${m##*/} does not belong to any model" "A vision file is only used when a model with exactly the same name sits next to it. There is no ${m%.mmproj}.gguf, so pictures will not work with the model it was meant for." "1. Open $md\n2. Rename the .mmproj file so its name matches its model, for example Model.gguf and Model.mmproj." "" ""
        done
    fi
    if [ "$(val ai_GpuLayers 99)" != 0 ]; then
        vk=""
        grep -qs 0x1002 /sys/class/drm/card[0-9]/device/vendor && vk=vulkan-radeon
        grep -qs 0x8086 /sys/class/drm/card[0-9]/device/vendor && vk="${vk:+$vk }vulkan-intel"
        set -- /usr/share/vulkan/icd.d/*.json /etc/vulkan/icd.d/*.json
        [ -e "$1" ] || [ -e "$2" ] || out ai-vulkan "AI models cannot use the graphics card" "llama.cpp reaches the graphics card through Vulkan, and no Vulkan driver is installed. Models still run, but only on the processor, which is much slower." "1. Open a terminal.\n2. For AMD graphics run: sudo pacman -S --needed vulkan-radeon\n   For Intel graphics run: sudo pacman -S --needed vulkan-intel\n   For NVIDIA the Vulkan driver comes with nvidia-utils.\n3. Restart the computer." "${vk:+Installs Programs}" "${vk:+$(get "$vk")}"
    fi
fi

if on manager_Show; then
    need python3 python "Snoopy Manager reads the processor, memory and process numbers with a small Python script."
    for f in Monitor.py Graph.qml; do
        [ -f "$root/Interface/Binded/Snoopy Manager/$f" ] || out "gone-$f" "$f is missing" "Interface/Binded/Snoopy Manager/SnoopyManager.qml needs $f, which is not in the Dolphin folder." "$restore" "" ""
    done
    w1=$(val manager_FetchLogo "neofetch -L")
    w2=$(val manager_FetchInfo "neofetch --stdout")
    w1=${w1%% *}
    w2=${w2%% *}
    [ "$w2" = "$w1" ] && w2=""
    for w in $w1 $w2; do
        have "$w" || out "fetch-$w" "$w is not installed" "The $w tab in Snoopy Manager shows the output of $w, which is missing, so the tab stays empty." "1. Install $w, or\n2. Open $cfg and set manager_FetchLogo and manager_FetchInfo to commands this computer has, for example:\nfastfetch --structure none --pipe\nfastfetch --logo none --pipe" "Installs Programs" "$(get "$w")"
    done
fi

if on connections_Show; then
    need bash bash "Network Connections gathers its list with a bash script."
    [ -f "$root/Interface/Binded/Network Connections/Collect.sh" ] || out gone-Collect.sh "Collect.sh is missing" "Interface/Binded/Network Connections/NetworkConnections.qml needs Collect.sh, which is not in the Dolphin folder, so the Network Connections window stays empty." "$restore" "" ""
    need ip iproute2 "Network Connections reads addresses and the programs that use the network with ip and ss."
fi

on media_Show && need cava cava "The Media Player draws its sound bars with cava. Without it the window still opens and plays, but the bars stay still."

if [ "$(val hyprai_Show false)" = true ]; then
    hs=$(val hyprai_Server llama-server)
    if ! on ai_Show || [ "$hs" != "$(val ai_Server llama-server)" ]; then
        have "$hs" || out pkg-llama "$hs is not installed" "Panda Hypr AI runs its model with llama.cpp. Without it the panda cannot answer." "1. Open a terminal.\n2. Run: sudo pacman -S --needed llama-cpp llama-cpp-vulkan\n3. If pacman cannot find them, run: yay -S llama.cpp-vulkan\n4. Press Check again." "Installs Programs" "$(get "$llama")"
    fi
    on ai_Show || need curl curl "Panda Hypr AI talks to its model through curl."
    if [ "$(val hyprai_Files true)" = true ]; then
        on manager_Show || on touchpad_Show || need python3 python "Panda Hypr AI searches Dolphin's scripts with a small Python script."
        [ -f "$root/Dolphin Hypr AI/Search.py" ] || out "gone-hyprai-Search.py" "Search.py is missing" "Dolphin Hypr AI/HyprAI.qml looks through Dolphin's scripts with Dolphin Hypr AI/Search.py, which is not in the Dolphin folder." "$restore" "" ""
    fi
    [ -f "$root/Dolphin Hypr AI/Run.sh" ] || out "gone-hyprai-Run.sh" "Run.sh is missing" "Dolphin Hypr AI/HyprAI.qml starts its model with Dolphin Hypr AI/Run.sh, which is not in the Dolphin folder." "$restore" "" ""
    hd=$(val ai_ModelsFolder "Data/Static/AI Models")
    case "$hd" in /*) ;; "~"|"~/"*) hd="$HOME${hd#"~"}" ;; *) hd="$root/$hd" ;; esac
    hm=$(val hyprai_Model "Qwen3.5-4B")
    case "$hm" in /*) ;; "~/"*) hm="$HOME${hm#"~"}" ;; */*) hm="$root/$hm" ;; *.gguf) hm="$hd/$hm" ;; *) hm="$hd/$hm.gguf" ;; esac
    if [ ! -f "$hm" ]; then
        if [ "${hm##*/}" = "Qwen3.5-4B.gguf" ]; then
            out hyprai-model "The Panda Hypr AI model is not downloaded" "Panda Hypr AI is turned on, but its model $hm is not there, so the panda cannot answer." "1. Open a terminal.\n2. Run: mkdir -p '$hd' && cd '$hd'\n3. Run: curl -L -o Qwen3.5-4B.gguf https://huggingface.co/SoAIHQ/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf\n4. Run: curl -L -o Qwen3.5-4B.mmproj https://huggingface.co/SoAIHQ/Qwen3.5-4B-GGUF/resolve/main/mmproj-Qwen3.5-4B-f16.gguf\n5. Press Check again." "Changes System" "term:mkdir -p '$hd' && cd '$hd' && curl -L -o Qwen3.5-4B.gguf https://huggingface.co/SoAIHQ/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf && curl -L -o Qwen3.5-4B.mmproj https://huggingface.co/SoAIHQ/Qwen3.5-4B-GGUF/resolve/main/mmproj-Qwen3.5-4B-f16.gguf"
        else
            out hyprai-model "The Panda Hypr AI model is missing" "Panda Hypr AI is set to use $hm, and that file is not there, so the panda cannot answer." "1. Open Snoopy Settings and go to Dolphin Hypr AI.\n2. Pick a model that exists under Model, or put the .gguf file in $hd" "" ""
        fi
    elif [ -f "${hm%.gguf}.mmproj" ]; then
        on snip_Show || need grim grim "The snipping tool in Panda Hypr AI takes its picture with grim."
        on ai_Show || on settings_Show || need ffmpeg ffmpeg "The snipping tool in Panda Hypr AI shrinks its picture with ffmpeg."
    fi
    hc=$(val hyprai_Context "Data/Context.txt")
    case "$hc" in /*) ;; "~/"*) hc="$HOME${hc#"~"}" ;; *) hc="$root/$hc" ;; esac
    [ -s "$hc" ] || out hyprai-context "Panda Hypr AI has nothing to read" "Everything the panda knows about Dolphin comes from $hc, and that file is missing or empty, so it can only answer that it does not know." "$restore" "" ""
fi

if on settings_Show; then
    on ai_Show || need ffmpeg ffmpeg "Snoopy Settings draws the wallpaper previews and saves a new profile picture with ffmpeg."
    i="$root/Interface/Binded/Dolphin Hyprland Settings/sovakot.png"
    [ -f "$i" ] || out settings-image "The Info picture is missing" "Snoopy Settings shows $(rel "$i") on its Info page, and that file is not there." "1. Put a picture named sovakot.png into $root/Interface/Binded/Dolphin Hyprland Settings.\n2. Reload Dolphin." "" ""
fi

if on widget_NotificationShow && have busctl; then
    pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID s org.freedesktop.Notifications 2>/dev/null | awk '{print $2}')
    if [ -n "$pid" ] && [ -r "/proc/$pid/comm" ]; then
        read -r comm < "/proc/$pid/comm"
        case "$comm" in qs|quickshell|.quickshell*) ;; *) out notify-owner "Another notification app is running ($comm)" "Only one app can receive notifications. While $comm is running, Dolphin's notification panel stays empty." "1. Open a terminal.\n2. Stop it now: pkill $comm\n3. Remove the line that starts it from hyprland.lua, or uninstall it, so it does not come back.\n4. Reload Dolphin." "" "" ;; esac
    fi
fi

[ -n "$tty" ] || echo "@ok"
