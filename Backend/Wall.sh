#!/bin/sh
TYPE="${2:-wave}"
TIME="${3:-1}"
MATCH="${4:-0.7}"
SAT="${5:-0}"
POS="$6"
MODE="$7"
FPS="$8"
n=0
until awww query >/dev/null 2>&1; do
    n=$((n + 1))
    [ "$n" -gt 100 ] && exit 1
    sleep 0.1
done
case "$1" in
    /*) p="$1" ;;
    *) p="$HOME/${1#"~/"}" ;;
esac
ROOT=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
RUN="${XDG_RUNTIME_DIR:-/tmp}"
mute() {
    jq -c --argjson m "$MATCH" '
        def h: explode | map(if . >= 97 then . - 87 else . - 48 end) | .[0] * 16 + .[1];
        def x: [(. / 16 | floor), (. % 16)] | map(if . < 10 then . + 48 else . + 87 end) | implode;
        map_values(ascii_downcase | ltrimstr("#") | [.[0:2], .[2:4], .[4:6]] | map(h)
        | (.[0] * 0.299 + .[1] * 0.587 + .[2] * 0.114) as $g
        | "#" + (map($g + (. - $g) * $m | round | x) | join("")))'
}
plan() {
    for c in "$ROOT/Data/Static/Matugen/config.toml" "$HOME/dolphin/matugen/config.toml"; do
        [ -f "$c" ] || continue
        t=$(sed -n "s/^[[:space:]]*input_path[[:space:]]*=[[:space:]]*['\"]\(.*\)['\"].*/\1/p" "$c" | head -n 1)
        case "$t" in "~/"*) t="$HOME/${t#"~/"}" ;; /*) ;; ?*) t="$(dirname "$c")/$t" ;; esac
        [ -f "$t" ] || t="$(dirname "$c")/theme.json"
        [ -f "$t" ] && { printf %s "$t"; return; }
    done
    t="$1/theme.json"
    printf '%s\n' '{"background":"{{colors.surface.default.hex}}","accent":"{{colors.surface_container.default.hex}}","accent2":"{{colors.outline_variant.default.hex}}","text":"{{colors.on_surface.default.hex}}","inactive":"{{colors.surface_container_highest.default.hex}}","active":"{{colors.primary.default.hex}}","extra":"#ffffff"}' > "$t"
    printf %s "$t"
}
spare() {
    ffmpeg -v error -nostdin -i "$1" -frames:v 1 -vf scale=24:24 -f rawvideo -pix_fmt rgb24 - 2>/dev/null | od -An -v -tu1 | awk '
        function hex(h, s, l,    c, x, m, r, g, b, k) {
            c = (1 - (2 * l - 1 < 0 ? 1 - 2 * l : 2 * l - 1)) * s; k = h / 60; x = c * (1 - ((k % 2) - 1 < 0 ? 1 - (k % 2) : (k % 2) - 1)); m = l - c / 2
            if (k < 1) { r = c; g = x; b = 0 } else if (k < 2) { r = x; g = c; b = 0 } else if (k < 3) { r = 0; g = c; b = x }
            else if (k < 4) { r = 0; g = x; b = c } else if (k < 5) { r = x; g = 0; b = c } else { r = c; g = 0; b = x }
            return sprintf("#%02x%02x%02x", int((r + m) * 255 + 0.5), int((g + m) * 255 + 0.5), int((b + m) * 255 + 0.5))
        }
        { for (i = 1; i <= NF; i++) v[n++] = $i / 255 }
        END {
            if (n < 3) exit 1
            for (i = 0; i + 2 < n; i += 3) {
                r = v[i]; g = v[i + 1]; b = v[i + 2]
                top = r > g ? (r > b ? r : b) : (g > b ? g : b); low = r < g ? (r < b ? r : b) : (g < b ? g : b); c = top - low
                ar += r; ag += g; ab += b; an++
                if (c < 0.12 || top < 0.2) continue
                w = c * top; wr += r * w; wg += g * w; wb += b * w; ww += w
            }
            if (ww > an * 0.01) { r = wr / ww; g = wg / ww; b = wb / ww } else { r = ar / an; g = ag / an; b = ab / an }
            top = r > g ? (r > b ? r : b) : (g > b ? g : b); low = r < g ? (r < b ? r : b) : (g < b ? g : b); c = top - low
            if (c < 0.0001) h = 0
            else if (top == r) h = 60 * ((g - b) / c) + (g < b ? 360 : 0)
            else if (top == g) h = 60 * ((b - r) / c + 2)
            else h = 60 * ((r - g) / c + 4)
            k = c < 0.04 ? 0 : 1
            printf "{\"background\":\"%s\",\"accent\":\"%s\",\"accent2\":\"%s\",\"text\":\"%s\",\"inactive\":\"%s\",\"active\":\"%s\",\"extra\":\"#ffffff\"}\n", hex(h, 0.17 * k, 0.08), hex(h, 0.12 * k, 0.13), hex(h, 0.08 * k, 0.29), hex(h, 0.29 * k, 0.9), hex(h, 0.08 * k, 0.21), hex(h, 0.64 * k, 0.82)
        }'
}
pal() {
    d="$RUN/dolphin-matugen"
    e="$RUN/dolphin-theme.err"
    mkdir -p "$d" 2>/dev/null || d="$RUN"
    rm -f "$d/out.json"
    if command -v matugen >/dev/null 2>&1; then
        printf "[config]\n\n[templates.dolphin]\ninput_path = '%s'\noutput_path = '%s'\n" "$(plan "$d")" "$d/out.json" > "$d/config.toml"
        m=$(matugen image "$1" -c "$d/config.toml" -m dark --source-color-index 0 2>&1 >/dev/null </dev/null)
        if [ -s "$d/out.json" ] && o=$(sed 's/,*\s*$//' "$d/out.json" | mute 2>/dev/null) && [ -n "$o" ]; then
            rm -f "$e"
            printf '%s\n' "$o"
            return
        fi
        printf '%s\n' "${m:-matugen ran but wrote no colours.}" | tail -n 6 > "$e"
    else
        printf '%s\n' "matugen is not installed." > "$e"
    fi
    spare "$1" | mute
}
tone() {
    case "$SAT" in 0|0.0|-0|"") printf %s "$1"; return ;; esac
    case "$(printf %s "$1" | tr '[:upper:]' '[:lower:]')" in *.gif) printf %s "$1"; return ;; esac
    o="/tmp/dolphin-sat-$(printf %s "$1|$SAT" | md5sum | cut -c1-12).png"
    [ -f "$o" ] && [ "$o" -nt "$1" ] || ffmpeg -v error -nostdin -y -i "$1" -vf "eq=saturation=$(awk "BEGIN { print 1 + $SAT }")" -frames:v 1 "$o" >/dev/null 2>&1
    if [ -s "$o" ]; then printf %s "$o"; else printf %s "$1"; fi
}
fade() {
    awww img --transition-type "$TYPE" --transition-duration "$TIME" ${POS:+--transition-pos "$POS"} ${FPS:+--transition-fps "$FPS"} "$1" >/dev/null 2>&1
}
if [ -z "$1" ] || [ ! -f "$p" ]; then
    pkill -x mpvpaper
    awww clear 000000 >/dev/null 2>&1
    exit
fi
case "$(printf %s "$p" | tr '[:upper:]' '[:lower:]')" in
    *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v)
        f="/tmp/dolphin-wall-$(printf %s "$p" | md5sum | cut -c1-12).png"
        [ -f "$f" ] && [ "$f" -nt "$p" ] || ffmpeg -v error -nostdin -y -i "$p" -frames:v 1 "$f" >/dev/null 2>&1
        pkill -x mpvpaper
        if [ "$MODE" != settle ] && [ -f "$f" ]; then
            fade "$(tone "$f")"
            [ "$MODE" = quick ] && exit
            [ "$TYPE" = none ] || sleep "$TIME"
        fi
        setsid -f mpvpaper -p -l background -o "no-audio --loop-file=inf --hwdec=auto --panscan=1.0 --saturation=$(awk "BEGIN { printf \"%d\", $SAT * 100 }")" "*" "$p" >/dev/null 2>&1
        ffmpeg -v error -nostdin -y -ss 1 -i "$p" -frames:v 1 "$RUN/dolphin-wall.png" >/dev/null 2>&1 && pal "$RUN/dolphin-wall.png"
        ;;
    *)
        t="$(tone "$p")"
        if [ "$MODE" != settle ]; then
            pkill -x mpvpaper
            fade "$t"
            [ "$MODE" = quick ] && exit
        fi
        pal "$t"
        ;;
esac
