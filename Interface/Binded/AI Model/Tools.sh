#!/bin/sh
root=$(realpath -e -- "$1" 2>/dev/null) || { echo "error: allowed folder not found"; exit 0; }
op=$2
q=$3
case "$q" in "~"|"~/"*) q="$HOME${q#\~}" ;; esac

resolve() {
  case "$1" in /*) c=$1 ;; *) c="$root/$1" ;; esac
  t=$(realpath -e -- "$c" 2>/dev/null) || return 1
  case "$t/" in "$root"/*) return 0 ;; *) return 2 ;; esac
}

readf() {
  if [ ! -s "$1" ]; then echo "(empty file)"
  elif grep -Iq . "$1" 2>/dev/null; then head -c 40000 -- "$1"
  else echo "error: binary file"; fi
}

if [ "$op" = "auto" ]; then
  case "$q" in
    */*)
      resolve "$q"; r=$?
      [ $r -eq 2 ] && { echo "error: outside the allowed folder"; exit 0; }
      [ $r -ne 0 ] && { echo "error: not found: $3"; exit 0; } ;;
    *)
      n=$(find "$root" -name "$q" -type f -not -path '*/.git/*' 2>/dev/null | head -n 20)
      c=$(printf '%s\n' "$n" | grep -c .)
      [ "$c" -eq 0 ] && { echo "error: no file named $q in the allowed folder"; exit 0; }
      [ "$c" -gt 1 ] && { echo "Several files are named $q:"; printf '%s\n' "$n" | sed "s|^$root/||"; exit 0; }
      t=$n ;;
  esac
  if [ -d "$t" ]; then ls -lA --group-directories-first -- "$t" 2>&1 | head -n 300
  else echo "File: ${t#$root/}"; readf "$t"; fi
  exit 0
fi

resolve "$q"; r=$?
[ $r -eq 2 ] && { echo "error: outside the allowed folder"; exit 0; }
[ $r -ne 0 ] && { echo "error: not found: $3"; exit 0; }
case "$op" in
  list) [ -d "$t" ] || { echo "error: not a folder"; exit 0; }; ls -lA --group-directories-first -- "$t" 2>&1 | head -n 300 ;;
  find) [ -d "$t" ] || { echo "error: not a folder"; exit 0; }; find "$t" -iname "*$4*" -not -path '*/.git/*' 2>/dev/null | sed "s|^$root/||" | head -n 200 ;;
  read) [ -f "$t" ] || { echo "error: not a file"; exit 0; }; readf "$t" ;;
  *) echo "error: unknown operation" ;;
esac