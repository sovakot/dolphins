import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: sunset

    required property var cfg
    property var next: null
    readonly property bool on: cfg?.dolphin_Night === true
    readonly property int heat: Math.round(6500 - Math.max(0, Math.min(1, cfg?.dolphin_NightStrength ?? 0.5)) * 3500)

    function send(args) {
        if (tune.running) { next = args; return }
        next = null
        tune.command = ["sh", "-c", "pgrep -x hyprsunset >/dev/null && hyprctl hyprsunset \"$@\" >/dev/null 2>&1; true", "sunset"].concat(args)
        tune.running = true
    }
    function apply() {
        if (!on) {
            glow.running = false
            send(["identity"])
            return
        }
        if (glow.running) { send(["temperature", String(heat)]); return }
        glow.command = ["sh", "-c", "if pgrep -x hyprsunset >/dev/null; then hyprctl hyprsunset temperature \"$1\" >/dev/null 2>&1; else exec hyprsunset -t \"$1\"; fi", "sunset", String(heat)]
        glow.running = true
    }

    onOnChanged: apply()
    onHeatChanged: if (on) send(["temperature", String(heat)])
    Component.onCompleted: if (on) apply()

    Process { id: glow }
    Process { id: tune; onExited: if (sunset.next) sunset.send(sunset.next) }
}
