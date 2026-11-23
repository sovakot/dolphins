#!/usr/bin/env python3
import glob
import json
import os
import re
import select
import shutil
import subprocess
import sys
import time

gap = 1.5
try:
    gap = max(0.3, float(sys.argv[1]))
except (IndexError, ValueError):
    pass
mode = sys.argv[2] if len(sys.argv) > 2 else "full"

page = os.sysconf("SC_PAGE_SIZE") // 1024
tick = os.sysconf("SC_CLK_TCK") or 100
me = os.getuid()
disks = re.compile(r"^(nvme\d+n\d+|sd[a-z]+|vd[a-z]+|mmcblk\d+)$")
vendors = {"0x1002": "AMD", "0x8086": "Intel", "0x10de": "NVIDIA"}


def booted():
    try:
        return time.time() - float(open("/proc/uptime").read().split()[0])
    except (OSError, ValueError, IndexError):
        return time.time()


def text(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def number(path):
    try:
        return int(text(path).strip())
    except ValueError:
        return None


def model():
    for line in text("/proc/cpuinfo").splitlines():
        if line.startswith("model name"):
            return line.split(":", 1)[1].strip()
    return ""


def sensor():
    for d in glob.glob("/sys/class/hwmon/hwmon*"):
        if text(d + "/name").strip() in ("k10temp", "coretemp", "zenpower", "cpu_thermal"):
            return d + "/temp1_input"
    return ""


def cards():
    out = []
    for d in sorted(glob.glob("/sys/class/drm/card[0-9]/device")):
        v = text(d + "/vendor").strip()
        if v:
            out.append((d, vendors.get(v, "GPU")))
    return out


def cpu():
    total, cores = None, []
    for line in text("/proc/stat").splitlines():
        if not line.startswith("cpu"):
            break
        p = line.split()
        v = [int(x) for x in p[1:9]]
        pair = (sum(v), v[3] + v[4])
        if p[0] == "cpu":
            total = pair
        else:
            cores.append(pair)
    return total or (0, 0), cores


def used(a, b):
    d = a[0] - b[0]
    return 0.0 if d <= 0 else max(0.0, min(100.0, (d - (a[1] - b[1])) * 100.0 / d))


def memory():
    m = {}
    for line in text("/proc/meminfo").splitlines():
        k, _, v = line.partition(":")
        if k in ("MemTotal", "MemAvailable", "Cached", "SwapTotal", "SwapFree"):
            m[k] = int(v.split()[0])
    return {"total": m.get("MemTotal", 0), "avail": m.get("MemAvailable", 0), "cached": m.get("Cached", 0),
            "swap": m.get("SwapTotal", 0), "swapFree": m.get("SwapFree", 0)}


def disk():
    r = w = busy = 0
    for line in text("/proc/diskstats").splitlines():
        p = line.split()
        if len(p) > 12 and disks.match(p[2]):
            r += int(p[5]) * 512
            w += int(p[9]) * 512
            busy = max(busy, int(p[12]))
    return r, w, busy


def space():
    try:
        s = os.statvfs("/")
        return s.f_blocks * s.f_frsize, (s.f_blocks - s.f_bfree) * s.f_frsize
    except OSError:
        return 0, 0


def net():
    rx = tx = 0
    best, name = -1, ""
    for line in text("/proc/net/dev").splitlines()[2:]:
        k, _, v = line.partition(":")
        k = k.strip()
        p = v.split()
        if k == "lo" or len(p) < 9:
            continue
        a, b = int(p[0]), int(p[8])
        rx += a
        tx += b
        if a + b > best:
            best, name = a + b, k
    for line in text("/proc/net/route").splitlines()[1:]:
        p = line.split()
        if len(p) > 1 and p[1] == "00000000":
            name = p[0]
            break
    return rx, tx, name


def gpu(found, smi):
    for d, label in found:
        busy = number(d + "/gpu_busy_percent")
        if busy is None:
            continue
        return {"name": label, "busy": busy, "used": (number(d + "/mem_info_vram_used") or 0) // 1024,
                "total": (number(d + "/mem_info_vram_total") or 0) // 1024}
    if smi:
        try:
            out = subprocess.run([smi, "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"],
                                 capture_output=True, text=True, timeout=1).stdout.splitlines()
            p = [float(x) for x in out[0].split(",")]
            return {"name": "NVIDIA", "busy": p[0], "used": int(p[1] * 1024), "total": int(p[2] * 1024)}
        except (OSError, ValueError, IndexError, subprocess.SubprocessError):
            return None
    return None


def wrote(pid):
    r = w = 0
    for line in text("/proc/" + pid + "/io").splitlines():
        if line.startswith("read_bytes:"):
            r = int(line[11:])
        elif line.startswith("write_bytes:"):
            w = int(line[12:])
    return r + w


def sockets():
    found = set()
    for path in ("/proc/net/tcp", "/proc/net/tcp6", "/proc/net/udp", "/proc/net/udp6"):
        for line in text(path).splitlines()[1:]:
            p = line.split()
            if len(p) < 10:
                continue
            far = p[2].rsplit(":", 1)[0]
            if far.strip("0") == "" or far in ("0100007F", "00000000000000000000000001000000", "0000000000000000FFFF00000100007F"):
                continue
            found.add(p[9])
    return found


def amount(v):
    try:
        n = int(v[0])
    except (ValueError, IndexError):
        return 0
    return n * 1024 if len(v) > 1 and v[1] == "MiB" else n


def handles(pid, live):
    links, spent, held, seen = 0, 0, 0, set()
    base = "/proc/" + pid + "/fd"
    try:
        names = os.listdir(base)
    except OSError:
        return 0, 0, 0
    for fd in names:
        try:
            link = os.readlink(base + "/" + fd)
        except OSError:
            continue
        if mode == "net":
            if link.startswith("socket:[") and link[8:-1] in live:
                links += 1
        elif link.startswith("/dev/dri/"):
            client, ns, hard, soft = "", 0, 0, 0
            for line in text("/proc/" + pid + "/fdinfo/" + fd).splitlines():
                k, _, v = line.partition(":")
                v = v.split()
                if k == "drm-client-id" and v:
                    client = v[0]
                elif k.startswith("drm-engine-") and not k.startswith("drm-engine-capacity"):
                    ns += amount(v)
                elif k.startswith("drm-memory-") and k != "drm-memory-cpu":
                    hard += amount(v)
                elif k.startswith("drm-resident-"):
                    soft += amount(v)
            if client in seen:
                continue
            seen.add(client)
            spent += ns
            held += hard or soft
    return links, spent, held


def wait(seconds):
    global mode
    try:
        ready = select.select([sys.stdin], [], [], seconds)[0]
    except (OSError, ValueError):
        time.sleep(seconds)
        return False
    if not ready:
        return False
    line = sys.stdin.readline()
    if line == "":
        if sys.stdin.isatty():
            return False
        raise SystemExit
    was = mode
    mode = line.strip() or "full"
    return (was == "light") != (mode == "light")


def scan(names):
    seen, out = {}, {}
    deep = mode in ("net", "gpu")
    live = sockets() if mode == "net" else None
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        raw = text("/proc/" + pid + "/stat")
        cut = raw.rfind(")")
        if cut < 0:
            continue
        p = raw[cut + 2:].split()
        if len(p) < 22 or p[1] == "2" or pid == "2":
            continue
        born = p[19]
        hit = names.get(pid)
        if not hit or hit[0] != born:
            try:
                name = os.path.basename(os.readlink("/proc/" + pid + "/exe")).replace(" (deleted)", "")
            except OSError:
                name = raw[raw.find("(") + 1:cut]
            try:
                mine = os.stat("/proc/" + pid).st_uid == me
            except OSError:
                mine = False
            hit = (born, name or "?", mine)
        seen[pid] = hit
        extra = handles(pid, live) if deep and hit[2] else (0, 0, 0)
        out[pid] = (hit[1], hit[2], int(p[11]) + int(p[12]), int(p[21]) * page, int(p[17]), wrote(pid) if hit[2] else 0, extra[0], extra[1], extra[2],
                    raw[raw.find("(") + 1:cut], int(born) // tick)
    return seen, out


def main():
    info = model()
    hot = sensor()
    found = cards()
    smi = shutil.which("nvidia-smi") if any(v == "NVIDIA" for _, v in found) else None
    speeds = glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq")
    boot = int(booted())
    names, last = {}, {}
    if mode != "light":
        names, last = scan(names)
    lastCpu, lastCores = cpu()
    lastDisk, lastNet, lastAt = disk(), net(), time.monotonic()
    pause = min(gap, 0.5)
    while True:
        if wait(pause):
            if mode != "light":
                names, last = scan(names)
                lastCpu, lastCores = cpu()
                lastDisk, lastNet, lastAt = disk(), net(), time.monotonic()
                pause = min(gap, 0.5)
                continue
            names, last = {}, {}
        pause = gap
        now = time.monotonic()
        dt = max(0.001, now - lastAt)
        nowCpu, nowCores = cpu()
        nowDisk, nowNet = disk(), net()
        size, taken = space()
        vals = [v for v in (number(p) for p in speeds) if v]
        temp = number(hot) if hot else None
        snap = {
            "cpu": round(used(nowCpu, lastCpu), 1),
            "cores": [round(used(a, b), 1) for a, b in zip(nowCores, lastCores)],
            "freq": round(sum(vals) / len(vals) / 1000) if vals else 0,
            "temp": round(temp / 1000) if temp else None,
            "model": info,
            "mem": memory(),
            "disk": {"read": max(0, nowDisk[0] - lastDisk[0]) / dt, "write": max(0, nowDisk[1] - lastDisk[1]) / dt,
                     "busy": round(max(0.0, min(100.0, (nowDisk[2] - lastDisk[2]) / (dt * 10.0))), 1), "size": size, "used": taken},
            "net": {"rx": max(0, nowNet[0] - lastNet[0]) / dt, "tx": max(0, nowNet[1] - lastNet[1]) / dt, "name": nowNet[2]},
            "gpu": gpu(found, smi if mode != "light" else None),
            "up": int(float((text("/proc/uptime").split() or ["0"])[0])),
        }
        if mode != "light":
            names, procs = scan(names)
            span = max(1, nowCpu[0] - lastCpu[0])
            groups, threads = {}, 0
            for pid, (name, mine, ticks, rss, thr, io, links, spent, held, comm, born) in procs.items():
                old = last.get(pid)
                same = old is not None and old[0] == name
                share = round((ticks - old[2]) * 100.0 / span, 1) if same and ticks >= old[2] else 0.0
                flow = round((io - old[5]) / dt) if same and io >= old[5] else 0
                draw = round(min(100.0, (spent - old[7]) / (dt * 1e7)), 1) if same and old[7] and spent >= old[7] else 0.0
                g = groups.setdefault(name, [0, 0.0, 0, [], mine, 0, 0, 0.0, 0, boot + born, []])
                g[0] += 1
                g[1] += share
                g[2] += rss
                g[3].append(int(pid))
                g[4] = g[4] and mine
                g[5] += flow
                g[6] += links
                g[7] += draw
                g[8] += held
                g[9] = min(g[9], boot + born)
                g[10].append([int(pid), comm, share, rss, flow, links, draw, held, boot + born])
                threads += thr
            snap["procs"] = len(procs)
            snap["threads"] = threads
            snap["list"] = [[n, g[0], round(g[1], 1), g[2], g[3], g[4], g[5], g[6], round(min(100.0, g[7]), 1), g[8], g[9], g[10] if g[0] > 1 else []]
                            for n, g in groups.items()]
            last = procs
        try:
            sys.stdout.write(json.dumps(snap, separators=(",", ":")) + "\n")
            sys.stdout.flush()
        except (BrokenPipeError, OSError):
            try:
                os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
            except OSError:
                pass
            return
        lastCpu, lastCores, lastDisk, lastNet, lastAt = nowCpu, nowCores, nowDisk, nowNet, now


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
