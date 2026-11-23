pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "../Data/Dynamic"

Singleton {
    id: hw

    readonly property var cfg: Config.values
    readonly property bool ready: probed

    readonly property bool shift: cfg?.system_PixelShift === true
    readonly property int shiftRadius: Math.max(1, Math.min(8, Math.round(cfg?.system_PixelShiftRadius ?? 3)))
    readonly property real shiftEvery: Math.max(0.1, cfg?.system_PixelShiftInterval ?? 3)
    readonly property var shiftPath: spiral(shiftRadius)
    property int shiftAt: 0
    property bool armed: false

    readonly property bool motion: cfg?.system_Animations !== false
    readonly property bool motionWindows: cfg?.system_AnimationsWindows !== false
    readonly property bool calm: !motion && motionWindows
    property bool calmed: false

    readonly property bool adaptive: cfg?.system_AutoBrightness === true
    readonly property real autoMin: Math.max(0.02, Math.min(1, cfg?.system_AutoBrightnessMin ?? 0.15))
    readonly property real autoMax: Math.max(autoMin, Math.min(1, cfg?.system_AutoBrightnessMax ?? 1))
    readonly property real autoLux: Math.max(10, cfg?.system_AutoBrightnessLux ?? 400)
    readonly property int autoEvery: Math.max(1000, cfg?.system_AutoBrightnessInterval ?? 3000)
    readonly property real autoStep: Math.max(0.01, Math.min(0.5, cfg?.system_AutoBrightnessStep ?? 0.04))
    readonly property real bias: Math.max(-0.6, Math.min(0.6, cfg?.system_AutoBrightnessBias ?? 0))
    readonly property real curve: Math.max(1, cfg?.system_BrightnessCurve ?? 4)

    readonly property int keyWant: Math.round(cfg?.system_KeyboardLight ?? -1)
    readonly property int limitWant: Math.max(20, Math.min(100, Math.round(cfg?.system_ChargeLimit ?? 100)))

    readonly property bool warn: cfg?.system_BatteryWarn !== false
    readonly property real warnAt: Math.max(1, Math.min(60, Number(cfg?.system_BatteryWarnAt ?? 5) || 5))
    readonly property real juice: { const d = UPower.displayDevice, p = d ? Number(d.percentage) || 0 : 0; return p > 1 ? p : p * 100 }
    readonly property bool draining: UPower.onBattery
    property bool warned: false

    onJuiceChanged: sip()
    onDrainingChanged: sip()

    function say(text) { return Config.words[text]?.[String(cfg?.dolphin_Language ?? "en")] ?? text }
    function sip() {
        if (!draining || juice > warnAt + 2) { warned = false; return }
        if (!warn || warned || juice <= 0 || juice > warnAt) return
        warned = true
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Dolphin", "-i", "battery-caution", say("Battery low"), Math.round(juice) + "%  \u00b7  " + say("Plug in the charger")])
    }

    property bool probed: false
    property bool hasCtl: false
    property string keyDevice: ""
    property int keyMax: 0
    property int keyNow: 0
    property string luxFile: ""
    property real luxScale: 1
    property real lux: -1
    property string lightDir: ""
    property int lightMax: 0
    property int lightRaw: 0
    property int lightSet: -1
    property real goal: -1
    property real touched: 0
    property string limitFile: ""
    property bool limitOpen: false
    property int limitNow: 100
    property bool hasProfiles: false
    property bool canInstall: false
    property bool installing: false
    property string note: ""

    readonly property bool hasKeyboardLight: keyDevice !== "" && keyMax > 0 && hasCtl
    readonly property bool hasLightSensor: luxFile !== ""
    readonly property bool hasBacklight: lightDir !== "" && lightMax > 0 && hasCtl
    readonly property bool hasChargeLimit: limitFile !== ""
    readonly property real brightness: lightMax > 0 ? Math.pow(Math.max(0, lightRaw) / lightMax, 1 / curve) : 0
    readonly property bool autoOn: adaptive && hasLightSensor && hasBacklight

    readonly property string probeScript: [
        "for d in /sys/class/leds/*kbd_backlight*; do [ -r \"$d/max_brightness\" ] || continue; echo \"key=${d##*/}\"; echo \"keymax=$(cat \"$d/max_brightness\")\"; echo \"keynow=$(cat \"$d/brightness\")\"; break; done",
        "for f in /sys/bus/iio/devices/*/in_illuminance_input /sys/bus/iio/devices/*/in_illuminance_raw /sys/bus/iio/devices/*/in_intensity_both_raw; do [ -r \"$f\" ] || continue; echo \"lux=$f\"; s=\"${f%_*}_scale\"; [ -r \"$s\" ] && [ \"${f##*_}\" = raw ] && echo \"luxscale=$(cat \"$s\")\"; break; done",
        "d=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1); [ -n \"$d\" ] && { echo \"light=$d\"; echo \"lightmax=$(cat \"$d/max_brightness\")\"; echo \"lightraw=$(cat \"$d/brightness\")\"; }",
        "for f in /sys/class/power_supply/*/charge_control_end_threshold; do [ -r \"$f\" ] || continue; echo \"limit=$f\"; echo \"limitnow=$(cat \"$f\")\"; [ -w \"$f\" ] && echo limitopen=1; break; done",
        "command -v brightnessctl >/dev/null 2>&1 && echo ctl=1",
        "command -v powerprofilesctl >/dev/null 2>&1 && echo profiles=1",
        "command -v pacman >/dev/null 2>&1 && command -v pkexec >/dev/null 2>&1 && echo install=1",
        "echo done=1"
    ].join("\n")
    readonly property string allowScript: [
        "printf '%s\\n' 'ACTION==\"add|change\", SUBSYSTEM==\"power_supply\", ATTR{type}==\"Battery\", RUN+=\"/bin/chmod a+w /sys%p/charge_control_end_threshold\"' > /etc/udev/rules.d/90-dolphin-charge.rules",
        "chmod a+w /sys/class/power_supply/*/charge_control_end_threshold"
    ].join("\n")

    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)) }
    function spiral(radius) {
        const out = [], steps = radius * radius * 16
        const add = (x, y) => {
            const l = out[out.length - 1]
            if (!l || l[0] !== x || l[1] !== y) out.push([x, y])
        }
        for (let i = 0; i <= steps; i++) {
            const t = i / steps, a = t * radius * 2 * Math.PI
            add(Math.floor(radius * t * Math.cos(a) + 0.5), Math.floor(radius * t * Math.sin(a) + 0.5))
        }
        for (let i = out.length - 2; i >= 1; i--) add(out[i][0], out[i][1])
        return out
    }
    function shader(x, y) {
        return "#version 300 es\nprecision highp float;\nin vec2 v_texcoord;\nuniform sampler2D tex;\nout vec4 fragColor;\nvoid main() {\n"
            + "    vec2 uv = v_texcoord - vec2(" + x.toFixed(1) + ", " + y.toFixed(1) + ") / vec2(textureSize(tex, 0));\n"
            + "    bool off = any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)));\n"
            + "    fragColor = off ? vec4(0.0, 0.0, 0.0, 1.0) : texture(tex, uv);\n}\n"
    }
    function hypr(lua) { Quickshell.execDetached(["sh", "-c", "hyprctl eval \"$1\" >/dev/null 2>&1", "hypr", lua]) }
    function show() {
        if (!shift || shiftProc.running) return
        const o = shiftPath[shiftAt] ?? [0, 0], dir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp", file = dir + "/dolphin-shift-" + shiftAt + ".frag"
        shiftProc.command = ["sh", "-c", "hyprctl eval \"$1\" >/dev/null 2>&1; printf %s \"$2\" > \"$3\" && hyprctl eval \"$4\" >/dev/null 2>&1; true", "shift",
            "hl.config({ debug = { damage_tracking = 1 } })", shader(o[0], o[1]), file, "hl.config({ decoration = { screen_shader = \"" + file + "\" } })"]
        shiftProc.running = true
    }
    function arm() {
        if (!shift) return
        armed = true
        if (shiftAt > 0) show()
        else hypr("hl.config({ debug = { damage_tracking = 1 } })")
    }
    function nudge() {
        if (!shift) return
        shiftAt = (shiftAt + 1) % shiftPath.length
        show()
    }
    function still() {
        if (!armed) return
        armed = false
        shiftAt = 0
        Quickshell.execDetached(["sh", "-c", "hyprctl eval 'hl.config({ decoration = { screen_shader = \"\" } })' >/dev/null 2>&1; hyprctl eval 'hl.config({ debug = { damage_tracking = 2 } })' >/dev/null 2>&1; rm -f \"${XDG_RUNTIME_DIR:-/tmp}\"/dolphin-shift-*.frag"])
    }
    function hush() {
        if (calm) { calmed = true; hypr("hl.config({ animations = { enabled = false } })") }
        else if (calmed) { calmed = false; hypr("hl.config({ animations = { enabled = true } })") }
    }
    function restore() {
        if (shift) arm()
        if (calm) hush()
    }
    function installProfiles() {
        if (install.running) return
        note = ""
        installing = true
        install.running = true
    }

    function refresh() { if (!probe.running) probe.running = true }
    function read(line) {
        const i = line.indexOf("=")
        if (i <= 0) return
        const k = line.slice(0, i), v = line.slice(i + 1).trim(), n = Number(v)
        if (k === "key") found.key = v
        else if (k === "keymax") found.keyMax = n || 0
        else if (k === "keynow") found.keyNow = n || 0
        else if (k === "lux") found.lux = v
        else if (k === "luxscale") found.luxScale = n > 0 ? n : 1
        else if (k === "light") found.light = v
        else if (k === "lightmax") found.lightMax = n || 0
        else if (k === "lightraw") found.lightRaw = n || 0
        else if (k === "limit") found.limit = v
        else if (k === "limitnow") found.limitNow = n || 100
        else if (k === "limitopen") found.limitOpen = true
        else if (k === "ctl") found.ctl = true
        else if (k === "profiles") found.profiles = true
        else if (k === "install") found.install = true
    }
    property var found: ({})
    function settle() {
        const f = found, first = !probed
        found = ({})
        hasCtl = f.ctl === true
        keyDevice = f.key ?? ""
        keyMax = f.keyMax ?? 0
        keyNow = f.keyNow ?? 0
        luxFile = f.lux ?? ""
        luxScale = f.luxScale ?? 1
        lightDir = f.light ?? ""
        lightMax = f.lightMax ?? 0
        if (!ramp.running && !setProc.running && Date.now() - touched > 1500) lightRaw = f.lightRaw ?? 0
        limitFile = f.limit ?? ""
        limitOpen = f.limitOpen === true
        limitNow = f.limitNow ?? 100
        hasProfiles = f.profiles === true
        canInstall = f.install === true
        probed = true
        if (!first) return
        if (hasKeyboardLight && keyWant >= 0 && keyWant !== keyNow) setKeyboardLight(keyWant)
        if (hasChargeLimit && limitOpen && limitWant !== limitNow) writeLimit(limitWant)
        restore()
    }

    function setKeyboardLight(level) {
        if (!hasKeyboardLight) return
        const n = clamp(Math.round(level), 0, keyMax)
        if (n === keyNow) return
        keyNow = n
        Quickshell.execDetached(["brightnessctl", "-q", "-d", keyDevice, "set", String(n)])
    }
    function push(level) {
        if (!hasBacklight) return
        const v = clamp(level, 0, 1)
        if (setProc.running) { setProc.next = v; return }
        setProc.next = -1
        setProc.command = ["sh", "-c", "brightnessctl -q -e" + curve + " -n2 set \"$1\"; cat \"$2\"", "light", Math.round(v * 100) + "%", lightDir + "/brightness"]
        setProc.running = true
    }
    function preview(level) {
        ramp.stop()
        goal = -1
        lightSet = -1
        touched = Date.now()
        lightRaw = Math.round(Math.pow(clamp(level, 0, 1), curve) * lightMax)
        push(level)
    }
    function setBrightness(level) {
        preview(level)
        if (autoOn && lux >= 0) Config.set("system_AutoBrightnessBias", Math.round(clamp(level - (target(lux) - bias), -0.6, 0.6) * 100) / 100)
    }
    function target(l) { return clamp(autoMin + (autoMax - autoMin) * clamp(Math.log(1 + Math.max(0, l)) / Math.log(1 + autoLux), 0, 1) + bias, 0.02, 1) }
    function sense(text) {
        const rows = String(text).trim().split("\n")
        if (rows.length < 2) return
        const l = Number(rows[0]) * luxScale, raw = Number(rows[1])
        if (isNaN(l) || isNaN(raw)) return
        lux = l
        if (ramp.running || setProc.running || Date.now() - touched < 1500) return
        const now = Math.pow(Math.max(0, raw) / lightMax, 1 / curve)
        if (lightSet >= 0 && Math.abs(raw - lightSet) > Math.max(1, lightMax * 0.01)) {
            const base = target(l) - bias
            Config.set("system_AutoBrightnessBias", Math.round(clamp(now - base, -0.6, 0.6) * 100) / 100)
            lightSet = raw
            lightRaw = raw
            return
        }
        lightRaw = raw
        const want = target(l)
        if (Math.abs(want - now) < autoStep && lightSet >= 0) return
        goal = want
        ramp.from = now
        ramp.at = 0
        ramp.restart()
    }
    function writeLimit(n) {
        if (!hasChargeLimit || !limitOpen) return
        limitNow = n
        Quickshell.execDetached(["sh", "-c", "echo \"$1\" > \"$2\"", "limit", String(n), limitFile])
    }
    function allowChargeLimit() {
        if (allow.running) return
        note = ""
        allow.running = true
    }

    onShiftChanged: shift ? arm() : still()
    onShiftRadiusChanged: if (shift && armed) { shiftAt = 0; show() }
    onCalmChanged: if (probed) hush()
    onAutoOnChanged: {
        ramp.stop()
        goal = -1
        lightSet = -1
        if (autoOn) senseProc.running = true
    }
    onKeyWantChanged: if (probed && keyWant >= 0 && keyWant !== keyNow) setKeyboardLight(keyWant)
    onLimitWantChanged: if (probed && limitOpen && limitWant !== limitNow) writeLimit(limitWant)
    Component.onCompleted: refresh()

    Process {
        id: probe
        command: ["sh", "-c", hw.probeScript]
        stdout: SplitParser { onRead: line => hw.read(line) }
        onExited: (exitCode, exitStatus) => hw.settle()
    }
    Process { id: shiftProc }
    Process {
        id: install
        command: ["pkexec", "sh", "-c", "pacman -S --noconfirm --needed power-profiles-daemon && systemctl enable --now power-profiles-daemon"]
        onExited: (exitCode, exitStatus) => {
            hw.installing = false
            hw.note = exitCode === 0 ? "" : "Power modes could not be installed."
            hw.refresh()
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") hw.restore() }
    }
    Process {
        id: setProc
        property real next: -1
        stdout: StdioCollector {
            onStreamFinished: {
                const n = Number(String(text).trim())
                if (isNaN(n)) return
                hw.lightRaw = n
                if (hw.autoOn && hw.goal >= 0) hw.lightSet = n
            }
        }
        onExited: (exitCode, exitStatus) => { if (next >= 0) hw.push(next) }
    }
    Process {
        id: senseProc
        command: ["sh", "-c", "cat \"$1\" \"$2\"", "sense", hw.luxFile, hw.lightDir + "/brightness"]
        stdout: StdioCollector { onStreamFinished: hw.sense(text) }
    }
    Process {
        id: allow
        command: ["pkexec", "sh", "-c", hw.allowScript]
        onExited: (exitCode, exitStatus) => {
            hw.note = exitCode === 0 ? "" : "The charge limit could not be unlocked."
            hw.refresh()
        }
    }

    Timer { interval: Math.round(hw.shiftEvery * 60000); repeat: true; running: hw.shift && hw.probed; onTriggered: hw.nudge() }
    Timer { interval: hw.autoEvery; repeat: true; running: hw.autoOn; onTriggered: if (!senseProc.running) senseProc.running = true }
    Timer {
        id: ramp
        property real from: 0
        property int at: 0
        readonly property int steps: 6
        interval: 80
        repeat: true
        onTriggered: {
            at++
            hw.push(from + (hw.goal - from) * at / steps)
            if (at >= steps) stop()
        }
    }
}
