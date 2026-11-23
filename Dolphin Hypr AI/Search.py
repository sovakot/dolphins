#!/usr/bin/env python3
import math
import os
import re
import sys

root = os.path.abspath(sys.argv[1])
limit = max(1, int(sys.argv[2]))
extra = [p for p in sys.argv[3].split(":") if p]
given = [w.lower() for w in sys.argv[4:] if w]
prefer = [w[1:] for w in given if w.startswith("+") and len(w) > 1]
words = [w for w in given if not w.startswith("+")]
if not words:
    sys.exit(0)

kinds = (".qml", ".sh", ".py", ".lua", ".conf")
skip_dirs = {"Data", ".git", "__pycache__"}
skip_files = {"Art.qml", "Search.py", "SnoopySettings.qml", "HyprAI.qml", "Check.sh"}
paths = []
for base, dirs, names in os.walk(root):
    dirs[:] = sorted(d for d in dirs if d not in skip_dirs)
    for n in sorted(names):
        if n.endswith(kinds) and n not in skip_files:
            paths.append(os.path.join(base, n))
paths += [p for p in extra if os.path.isfile(p)]

camel = re.compile(r"([a-z0-9])([A-Z])")
junk = re.compile(r"[^a-z0-9а-яё]+")
def flat(t):
    return " " + junk.sub(" ", camel.sub(r"\1 \2", t).lower()) + " "

probes = [" " + w + (" " if len(w) < 4 else "") for w in words]
files = []
total = 0
seen = [0] * len(words)
for p in paths:
    try:
        if os.path.getsize(p) > 600000:
            continue
        with open(p, "r", encoding="utf-8", errors="replace") as f:
            raw = f.read().split("\n")
    except OSError:
        continue
    hits = []
    for i, line in enumerate(raw):
        if len(line) > 600:
            continue
        low = flat(line)
        got = 0
        for k, pr in enumerate(probes):
            if pr in low:
                got |= 1 << k
                seen[k] += 1
        if got:
            hits.append((i, got))
    total += len(raw)
    files.append((p, raw, hits, flat(os.path.basename(p).rsplit(".", 1)[0])))

worth = [math.log(1 + total / n) if n else 0 for n in seen]
def value(mask):
    return sum(worth[k] for k in range(len(words)) if mask >> k & 1)

found = []
for p, raw, hits, name in files:
    by = dict(hits)
    named = 0
    for k, pr in enumerate(probes):
        if pr.strip() and pr.strip() in name:
            named |= 1 << k
    for i, got in hits:
        near = 0
        for j in range(i - 5, i + 6):
            if j != i:
                near |= by.get(j, 0)
        score = value(got) + 0.8 * value(near & ~got) + value(named & ~(got | near))
        kinds_hit = bin(got | near | named).count("1")
        liked = any(w in name for w in prefer)
        if len(words) > 1 and kinds_hit < 2 and not liked:
            continue
        found.append((score * (4 if liked else 1), p, i, kinds_hit, liked))

found.sort(key=lambda e: (-e[0], e[1], e[2]))
taken = []
home = os.path.expanduser("~")
known = max(1, sum(1 for n in seen if n))
for score, p, i, hit, liked in found:
    if any(q == p and abs(j - i) <= 9 for q, j, h, l in taken):
        continue
    taken.append((p, i, hit, liked))
    if len(taken) >= limit:
        break

for p, i, hit, liked in taken:
    raw = next(f[1] for f in files if f[0] == p)
    a, b = max(0, i - 5), min(len(raw), i + 4)
    shown = "~" + p[len(home):] if p.startswith(home + "/") else p
    print("FILE " + shown + " lines " + str(a + 1) + "-" + str(b) + " hits " + str(hit) + " of " + str(known) + (" pref" if liked else ""))
    for j in range(a, b):
        t = raw[j].rstrip()
        if t.strip():
            print(str(j + 1) + (">" if j == i else ":") + " " + t.strip()[:160])
    print("")
