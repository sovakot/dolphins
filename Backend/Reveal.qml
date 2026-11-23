pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Data/Dynamic"

Singleton {
    id: reveal

    property bool all: false
    property bool editor: false
    property rect desk: Qt.rect(0, 0, 0, 0)
    property bool shut: false
    property bool veiled: false
    property bool sure: true
    property real shade: veiled ? 0 : 1
    readonly property real glass: sure ? 1 : shade
    readonly property string paper: String(Config.values.dolphin_Background ?? "")
    readonly property bool still: paper === "" || /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(paper) || String(Config.values.lockscreen_UnlockTransition ?? "wave") === "none"
    readonly property int pause: still ? 150 : Math.round(Math.max(0, Number(Config.values.lockscreen_UnlockDuration ?? 1) || 0) * 1000) + 250
    readonly property int fade: Motion.span(Math.max(0, Number(Config.values.dolphin_UnlockFade ?? 600) || 0))

    signal inspect(string key)
    signal player()

    function gate(locked) {
        shut = locked
        if (locked) {
            sure = false
            veiled = true
            return
        }
        if (!veiled) { sure = true; return }
        if (Config.values.dolphin_WaitUnlock === false) { veiled = false; sure = true; return }
        if (wait.running) return
        wait.command = ["sleep", String(pause / 1000)]
        wait.running = true
    }
    function lift() {
        if (shut) return
        veiled = false
        if (last.running) return
        last.command = ["sleep", String(fade / 1000 + 0.25)]
        last.running = true
    }

    Behavior on shade { NumberAnimation { duration: reveal.veiled ? 0 : reveal.fade; easing.type: Easing.OutCubic } }
    Process { id: wait; onExited: reveal.lift() }
    Process { id: last; onExited: if (!reveal.shut) reveal.sure = true }
}
