#!/bin/sh
c="${XDG_RUNTIME_DIR:-/tmp}/dolphin-downloads"
stale="${1:-5}"
mkdir -p "$c"
for k in "$c"/*-*; do
    [ -e "$k" ] || continue
    p=${k##*/}
    [ -d "/proc/${p%%-*}" ] || rm -f "$k"
done
{
    find /proc/[0-9]*/fd -maxdepth 1 -lname '/*' ! -lname '*/.*' ! -lname '* (deleted)' ! -lname '*/steamapps/*' \
        ! -lname '/dev/*' ! -lname '/proc/*' ! -lname '/sys/*' ! -lname '/usr/*' ! -lname '/etc/*' ! -lname '/opt/*' \
        ! -lname '/var/*' ! -lname '/tmp/*' ! -lname '/run/user/*' ! -lname '/memfd:*' -printf '%h\t%f\t%l\n' 2>/dev/null |
    {
        tcp=""
        yes=" "
        no=" "
        online() {
            case "$yes" in *" $1 "*) return 0 ;; esac
            case "$no" in *" $1 "*) return 1 ;; esac
            [ -n "$tcp" ] || tcp=" $(awk 'FNR > 1 && $4 == "01" && $3 !~ /^(......7F|00000000000000000000000001000000|0000000000000000FFFF0000......7F):/ { printf "%s ", $10 }' /proc/net/tcp /proc/net/tcp6 2>/dev/null)"
            for i in $(find "/proc/$1/fd" -maxdepth 1 -lname 'socket:*' -printf '%l\n' 2>/dev/null | tr -dc '0-9\n'); do
                case "$tcp" in *" $i "*) yes="$yes$1 "; return 0 ;; esac
            done
            no="$no$1 "
            return 1
        }
        while IFS='	' read -r h fd f; do
            [ "$fd" = 2 ] && continue
            [ -f "$f" ] || continue
            p=${h#/proc/}
            p=${p%/fd}
            fl=0
            while read -r a b; do
                [ "$a" = flags: ] && fl=$b
            done 2>/dev/null < "/proc/$p/fdinfo/$fd"
            [ $((0$fl & 3)) -eq 0 ] && continue
            n=${f##*/}
            case "$n" in
                *.part) n=${n%.part} ;;
                *.crdownload) n=${n%.crdownload} ;;
                *.opdownload) n=${n%.opdownload} ;;
                *.download) n=${n%.download} ;;
                *.!qB) n=${n%.!qB} ;;
                *) online "$p" || continue ;;
            esac
            t=""
            comm=""
            read -r comm 2>/dev/null < "/proc/$p/comm"
            case "$comm" in
                curl|wget)
                    k="$c/$p-$n"
                    if [ ! -f "$k" ]; then
                        urls=$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null | grep -E '^(https?|ftp)://')
                        u=$(printf '%s\n' "$urls" | grep -m1 -F "/$n")
                        [ -z "$u" ] && u=$(printf '%s\n' "$urls" | head -n1)
                        [ -n "$u" ] && curl -sIL --max-time 5 "$u" | tr -d '\r' | awk 'tolower($1)=="content-length:"{v=$2} END{print v}' > "$k"
                    fi
                    [ -f "$k" ] && read -r t < "$k"
                    ;;
            esac
            z=$(stat -c '%s|%b' "$f" 2>/dev/null) || continue
            printf '%s|%s|%s|%s\n' "$f" "$n" "$z" "$t"
        done
    }
    for root in "$HOME/.local/share/Steam" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        v="$root/steamapps/libraryfolders.vdf"
        [ -f "$v" ] && awk -F'"' '$2 == "path" { print $4 }' "$v"
    done | sort -u |
    while read -r lib; do
        s="$lib/steamapps"
        [ -d "$s/downloading" ] || continue
        set -- "$s"/appmanifest_*.acf
        [ -e "$1" ] || continue
        awk -F'"' 'function out() { if (t + 0 > d + 0) print i "|" n "|" s; i = n = d = t = s = "" } FNR == 1 && NR > 1 { out() } $2 == "appid" { i = $4 } $2 == "name" { n = $4 } $2 == "BytesDownloaded" { d = $4 } $2 == "BytesToDownload" { t = $4 } $2 == "BytesToStage" { s = $4 } END { out() }' "$@" |
        while IFS='|' read -r id n t; do
            d="$s/downloading/$id"
            [ -d "$d" ] || continue
            printf '%s|%s|%s|0|%s\n' "$d" "$n" "$(du -sB1 "$d" 2>/dev/null | cut -f1)" "$t"
        done
    done
} | awk -F'|' -v now="$(date +%s)" -v stale="$stale" -v st="$c/state" '
    BEGIN {
        while ((getline l < st) > 0) { split(l, a, "|"); had[a[1]] = a[2]; at[a[1]] = a[3] }
        close(st)
        printf "" > st
    }
    {
        if ($1 in seen) next
        seen[$1] = 1
        v = $3 ":" $4
        t = ($1 in had) ? (had[$1] != v ? now : at[$1]) : 0
        print $1 "|" v "|" t > st
        if ($5 + 0 > 0 && $3 + 0 >= $5 + 0) next
        if (now - t <= stale) print $2 "|" $3 "|" $5
    }'
