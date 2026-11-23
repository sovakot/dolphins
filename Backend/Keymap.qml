import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: map

    required property var cfg
    property string next: ""
    readonly property bool linked: cfg?.widget_KeyboardLinked === true && cfg?.widget_KeyboardShow !== false
    readonly property string lang: String(cfg?.widget_KeyboardLanguage ?? "en")
    readonly property var base: split(cfg?.dolphin_KeyboardLayout)
    readonly property var want: linked ? split((cfg?.widget_KeyboardLayouts ?? {})[lang.charAt(0).toUpperCase() + lang.slice(1)]) : base
    readonly property bool two: want[0] !== base[0] || want[1] !== base[1]
    readonly property string plan: (two ? "1" : "0") + "hl.config({ input = { kb_layout = \"" + base[0] + (two ? "," + want[0] : "")
        + "\", kb_variant = \"" + base[1] + (two ? "," + want[1] : "") + "\" } })"

    function split(name) {
        const m = /^([a-z0-9_-]+)(?:\(([a-z0-9_-]*)\))?$/i.exec(String(name ?? "us").trim())
        return m ? [m[1], m[2] ?? ""] : ["us", ""]
    }
    function apply() {
        if (run.running) { next = plan; return }
        next = ""
        run.command = ["sh", "-c", "hyprctl eval \"$1\" >/dev/null && { [ \"$2\" = 0 ] || hyprctl switchxkblayout all 1 >/dev/null; }", "keymap", plan.slice(1), plan.charAt(0)]
        run.running = true
    }

    onPlanChanged: apply()
    Component.onCompleted: apply()

    Process { id: run; onExited: if (map.next !== "") map.apply() }
}
