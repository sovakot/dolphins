#!/usr/bin/env python3
# one finger sliding along the touchpad's side edges: left = volume, right = brightness
# arguments: edge step drift slide (see touchpad_Edge, touchpad_Step, touchpad_Drift, touchpad_Slide)
import ctypes
import os
import signal
import subprocess
import sys

import evdev
from evdev import ecodes as e

ctypes.CDLL(None).prctl(1, signal.SIGTERM)
if os.getppid() == 1:
    sys.exit(0)
for p in os.listdir("/proc"):
    if not p.isdigit() or int(p) == os.getpid():
        continue
    try:
        if os.stat("/proc/" + p).st_uid != os.getuid():
            continue
        with open("/proc/" + p + "/cmdline", "rb") as f:
            a = f.read().split(b"\0")
        if len(a) > 1 and b"python" in a[0] and a[1].lower().endswith(b"touchpad.py"):
            os.kill(int(p), signal.SIGTERM)
    except OSError:
        pass

arg = sys.argv[1:] + [None] * 4
EDGE = float(arg[0] or 0.10)
STEP = float(arg[1] or 0.025)
DRIFT = float(arg[2] or 0.08)
SLIDE = arg[3] or "2%"

ACTIONS = {
    "right up":   ["brightnessctl", "-q", "-e4", "-n2", "set", SLIDE + "+"],
    "right down": ["brightnessctl", "-q", "-e4", "-n2", "set", SLIDE + "-"],
    "left up":    ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", SLIDE + "+"],
    "left down":  ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", SLIDE + "-"],
}

dev = next((d for d in map(evdev.InputDevice, evdev.list_devices()) if "touchpad" in d.name.lower()), None)
if not dev:
    sys.exit(0)
xi, yi = dev.absinfo(e.ABS_X), dev.absinfo(e.ABS_Y)
w, h = xi.max - xi.min, yi.max - yi.min
MULTI = {e.BTN_TOOL_DOUBLETAP, e.BTN_TOOL_TRIPLETAP, e.BTN_TOOL_QUADTAP, e.BTN_TOOL_QUINTTAP}

x = y = x0 = ylast = 0
zone, touching, start, multi = None, False, False, False

for ev in dev.read_loop():
    if ev.type == e.EV_ABS:
        if ev.code == e.ABS_X:
            x = ev.value
        elif ev.code == e.ABS_Y:
            y = ev.value
    elif ev.type == e.EV_KEY:
        if ev.code == e.BTN_TOUCH:
            touching = ev.value == 1
            start = touching
        elif ev.code in MULTI and ev.value:
            multi = True
    elif ev.type == e.EV_SYN and ev.code == e.SYN_REPORT:
        if not touching:
            zone, multi = None, False
            continue
        if start:
            start = False
            zone = "left" if x < xi.min + EDGE * w else "right" if x > xi.max - EDGE * w else None
            x0, ylast = x, y
            continue
        if not zone:
            continue
        if multi or abs(x - x0) > DRIFT * w:
            zone = None
            continue
        d = y - ylast
        if abs(d) >= STEP * h:
            subprocess.run(ACTIONS[f"{zone} {'up' if d < 0 else 'down'}"])
            print(zone, flush=True)
            ylast = y
