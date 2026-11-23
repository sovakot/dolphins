#!/bin/sh
limit=$1
shift
command -v "$1" >/dev/null 2>&1 || exit 127
if [ "$limit" -gt 0 ] 2>/dev/null && command -v systemd-run >/dev/null 2>&1 && systemd-run --user --scope --quiet --collect -p MemoryMax=64M true 2>/dev/null; then
    exec systemd-run --user --scope --quiet --collect -p "MemoryMax=${limit}M" -- choom -n 1000 -- "$@"
fi
command -v choom >/dev/null 2>&1 && exec choom -n 1000 -- "$@"
exec "$@"
