#!/bin/sh
shrink() { ffmpeg -loglevel error -i "$1" -frames:v 1 -vf "scale='min(1024,iw)':-2" -f image2pipe -vcodec png - 2>/dev/null | base64 -w0; }

if [ "$1" = "--clip" ]; then
  for t in $(wl-paste -l 2>/dev/null); do
    case "$t" in image/*) printf 'IMG '; wl-paste -t "$t" | shrink -; echo; exit 0 ;; esac
  done
  echo TEXT
  exit 0
fi

f=$1
[ -f "$f" ] || { echo "ERR not found"; exit 0; }
ext=$(printf %s "${f##*.}" | tr '[:upper:]' '[:lower:]')
case "$ext" in
  png|jpg|jpeg|webp|gif|bmp|tif|tiff|avif|heic)
    printf 'IMG '; shrink "$f"; echo ;;
  mp4|mkv|webm|mov|avi|m4v)
    d=$(mktemp -d)
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)
    r=$(awk -v d="${dur:-4}" 'BEGIN { if (d <= 0) d = 4; printf "%.4f", 4 / d }')
    ffmpeg -loglevel error -i "$f" -vf "fps=$r,scale='min(768,iw)':-2" -frames:v 4 "$d/%02d.png" 2>/dev/null
    for i in "$d"/*.png; do [ -f "$i" ] && { printf 'IMG '; base64 -w0 "$i"; echo; }; done
    rm -rf "$d" ;;
  pdf)
    if command -v pdftotext >/dev/null; then echo TXT; pdftotext -layout "$f" - 2>/dev/null | head -c 100000
    else echo "BIN PDF document (install poppler to read PDFs)"; fi ;;
  *)
    if [ ! -s "$f" ] || grep -Iq . "$f" 2>/dev/null; then echo TXT; head -c 100000 -- "$f"
    else echo "BIN $(file -b -- "$f" | head -c 200), $(du -h -- "$f" | cut -f1)"; fi ;;
esac