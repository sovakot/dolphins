import QtQuick
import Quickshell
import Quickshell.Io
import "Brightness" as Light
import "Sound" as Audio
import "../../../Data/Dynamic"

Scope {
    id: pad

    required property var cfg
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("Touchpad.py").toString().replace(/^file:\/\//, ""))
    readonly property var args: [String(s("Edge") ?? 0.1), String(s("Step") ?? 0.025), String(s("Drift") ?? 0.08), String(s("Slide") ?? "2%")]
    readonly property string plan: s("Show") === false ? "" : args.join(" ")

    function s(key) { return cfg?.["touchpad_" + key] }
    function title(t) { return String(t).charAt(0).toUpperCase() + String(t).slice(1) }
    function tone(c) {
        const set = Config.tones
        return set?.[c] ?? set?.[title(c)] ?? (String(c).startsWith("#") ? c : "#000000")
    }

    onPlanChanged: { swipe.running = false; again.restart() }
    Component.onCompleted: if (plan === "") reap.running = true

    Light.Brightness { id: light; pad: pad; onOpened: sound.hide() }
    Audio.Sound { id: sound; pad: pad; onOpened: light.hide() }

    IpcHandler {
        target: "touchpad"
        function restart(): void { swipe.running = false; again.restart() }
    }

    Process {
        id: swipe
        command: ["python3", pad.script].concat(pad.args)
        stdout: SplitParser {
            onRead: line => {
                if (pad.s("Keys") === false) return
                if (line === "left") sound.grab()
                else if (line === "right") light.grab()
            }
        }
    }
    Process { id: reap; command: ["pkill", "-u", Quickshell.env("USER") ?? "", "-f", "^python3? .*[Tt]ouchpad\\.py"] }
    Timer {
        id: again
        interval: 200
        running: true
        onTriggered: {
            swipe.running = pad.plan !== ""
            if (pad.plan === "") reap.running = true
        }
    }
}
