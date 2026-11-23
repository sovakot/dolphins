#!/usr/bin/env python3
import json
import subprocess
import sys


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, timeout=4).stdout
    except Exception:
        return b""


def ask(what):
    try:
        return json.loads(run(["hyprctl", "-j", what]) or b"null")
    except Exception:
        return None


def say(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def clip(x, y, w, h, wide, tall):
    x0, y0, x1, y1 = max(0, x), max(0, y), min(wide, x + w), min(tall, y + h)
    return (x0, y0, x1 - x0, y1 - y0)


def windows(name, ox, oy, wide, tall, least):
    out = []
    mons = ask("monitors") or []
    mon = next((m for m in mons if m.get("name") == name), None)
    rooms = set()
    if mon:
        rooms.add((mon.get("activeWorkspace") or {}).get("id"))
        special = (mon.get("specialWorkspace") or {}).get("id")
        if special:
            rooms = {special}
    for c in ask("clients") or []:
        if not c.get("mapped", True) or c.get("hidden"):
            continue
        if (c.get("workspace") or {}).get("id") not in rooms:
            continue
        at, size = c.get("at") or [0, 0], c.get("size") or [0, 0]
        x, y, w, h = clip(at[0] - ox, at[1] - oy, size[0], size[1], wide, tall)
        if w >= least and h >= least:
            out.append({"x": x, "y": y, "w": w, "h": h, "kind": "window", "label": str(c.get("title") or c.get("class") or "")[:60], "top": 2 if c.get("floating") else 1})
    layers = (ask("layers") or {}).get(name, {}).get("levels", {})
    for level in layers.values():
        for l in level:
            space = str(l.get("namespace") or "")
            if space.startswith(("dolphin", "quickshell", "awww", "swww", "mpvpaper", "wallpaper", "hyprpaper")):
                continue
            x, y, w, h = clip(l.get("x", 0) - ox, l.get("y", 0) - oy, l.get("w", 0), l.get("h", 0), wide, tall)
            if w >= least and h >= least and w * h < wide * tall * 0.6:
                out.append({"x": x, "y": y, "w": w, "h": h, "kind": "layer", "label": space[:60], "top": 3})
    return out


def detect(data, factor, wide, tall, least, edge, taken):
    parts = data.split(b"\n", 3)
    if len(parts) < 4 or parts[0] != b"P6":
        return []
    w, h = (int(v) for v in parts[1].split())
    px = parts[3]
    n = w * h
    if len(px) < n * 3:
        return []
    luma = [(r * 77 + g * 150 + b * 29) >> 8 for r, g, b in zip(px[0:n * 3:3], px[1:n * 3:3], px[2:n * 3:3])]
    mark = bytearray(n)
    for i, (p, q, d) in enumerate(zip(luma, luma[1:], luma[w:])):
        if p - q > edge or q - p > edge or p - d > edge or d - p > edge:
            mark[i] = 1
    for i in range(w - 1, n, w):
        mark[i] = 0
    small = max(2, int(least * factor))
    found = []
    steps = (-w - 1, -w, -w + 1, -1, 1, w - 1, w, w + 1)
    start = mark.find(1)
    while start >= 0:
        mark[start] = 0
        stack = [start]
        x0 = x1 = start % w
        y0 = y1 = start // w
        count = 0
        while stack:
            i = stack.pop()
            count += 1
            x, y = i % w, i // w
            if x < x0:
                x0 = x
            elif x > x1:
                x1 = x
            if y > y1:
                y1 = y
            elif y < y0:
                y0 = y
            for s in steps:
                j = i + s
                if 0 <= j < n and mark[j]:
                    jx = j % w
                    if jx - x > 1 or x - jx > 1:
                        continue
                    mark[j] = 0
                    stack.append(j)
        bw, bh = x1 - x0 + 1, y1 - y0 + 1
        if bw >= small and bh >= small and count >= bw + bh:
            found.append((x0, y0, bw, bh))
        start = mark.find(1, start + 1)
    out = []
    whole = wide * tall
    for x0, y0, bw, bh in found:
        x, y, rw, rh = clip(round((x0 + 1) / factor), round((y0 + 1) / factor), round((bw - 1) / factor), round((bh - 1) / factor), wide, tall)
        if rw < least or rh < least or rw * rh > whole * 0.85:
            continue
        near = max(6, round(3 / factor))
        if any(abs(x - t["x"]) <= near and abs(y - t["y"]) <= near and abs(rw - t["w"]) <= near * 2 and abs(rh - t["h"]) <= near * 2 for t in taken):
            continue
        if any(x <= t["x"] and y <= t["y"] and x + rw >= t["x"] + t["w"] and y + rh >= t["y"] + t["h"] and rw * rh < t["w"] * t["h"] * 1.12 for t in taken):
            continue
        out.append({"x": x, "y": y, "w": rw, "h": rh, "kind": "content", "label": "", "top": 4})
    out.sort(key=lambda r: -r["w"] * r["h"])
    return out[:160]


def main():
    name = sys.argv[1]
    ox, oy, wide, tall = (int(float(v)) for v in sys.argv[2:6])
    content = sys.argv[6] == "1"
    least = max(8, int(float(sys.argv[7])))
    factor = min(1.0, max(0.1, float(sys.argv[8])))
    edge = max(1, int(float(sys.argv[9])))
    data = run(["grim", "-o", name, "-s", str(factor), "-t", "ppm", "-"]) if content else b""
    say({"ready": True})
    wins = windows(name, ox, oy, wide, tall, least)
    say({"regions": wins})
    if data:
        say({"regions": detect(data, factor, wide, tall, least, edge, wins)})


if __name__ == "__main__":
    main()
