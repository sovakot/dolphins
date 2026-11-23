import QtQuick
import Quickshell.Io
import "../../../../Backend"

Widget {
    id: night
    key: "night"
    ghost: true
    visible: false
    icon: sign(s("Art")) || "moon"
    lit: on
    onTapped: flip()

    readonly property bool saved: bar.global("Night") === true
    readonly property real savedStrength: Math.max(0, Math.min(1, bar.global("NightStrength") ?? 0.5))
    property bool on: saved
    property real strength: savedStrength
    onSavedChanged: on = saved
    onSavedStrengthChanged: strength = savedStrength

    function flip() {
        on = !on
        bar.save("dolphin_Night", on)
    }
    function preview(v) {
        if (!on || tune.running) return
        tune.command = ["hyprctl", "hyprsunset", "temperature", String(Math.round(6500 - v * 3500))]
        tune.running = true
    }
    function keep(v) {
        if (v < 0) return
        strength = v
        bar.save("dolphin_NightStrength", Math.round(v * 100) / 100)
    }

    Process { id: tune }

    page: Component {
        Parts.Section {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open
            title: "Night light"
            on: night.on
            onToggled: night.flip()

            marked: keyed && cur === 0

            readonly property bool keyed: parent.keyed
            property int cur: 0

            function key(k) {
                if (k === "up" || k === "down") cur = 1 - cur
                else if (k === "enter" && cur === 0) night.flip()
                else if (cur === 1 && (k === "left" || k === "right")) {
                    const v = Math.max(0, Math.min(1, Math.round((night.strength + (k === "left" ? -0.05 : 0.05)) * 100) / 100))
                    night.preview(v)
                    night.keep(v)
                } else return false
                return true
            }

            Parts.Info { key: "Strength"; value: Math.round(strip.v * 100) + "%"; c: page.c; unit: page.unit }
            Parts.Slider {
                id: strip
                value: night.strength
                marked: page.keyed && page.cur === 1
                c: page.c
                unit: page.unit
                onMoved: v => night.preview(v)
                onReleased: v => night.keep(v)
            }
        }
    }
}
