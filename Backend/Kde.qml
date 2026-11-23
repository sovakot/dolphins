import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: kde

    required property var cfg
    property string done: ""
    readonly property var args: {
        const all = cfg?.Kde ?? {}, themes = cfg?.Theme ?? {}, pick = cfg?.dolphin_ThemeBackground === true ? "Wallpaper" : cfg?.dolphin_Theme ?? ""
        const cap = t => String(t).charAt(0).toUpperCase() + String(t).slice(1)
        const set = themes[pick] ?? themes[cap(pick)] ?? {}
        const rgb = h => parseInt(h.slice(1, 3), 16) + "," + parseInt(h.slice(3, 5), 16) + "," + parseInt(h.slice(5, 7), 16)
        const out = []
        for (const group in all) {
            const keys = all[group]
            if (keys === null || typeof keys !== "object") continue
            for (const k in keys) {
                const v = String(keys[k]), hex = set[v] ?? set[cap(v)] ?? v
                out.push(group, k, /^#[0-9a-fA-F]{6}$/.test(hex) ? rgb(hex) : v)
            }
        }
        return out
    }

    onArgsChanged: wait.restart()

    Timer {
        id: wait
        interval: 300
        onTriggered: {
            const now = JSON.stringify(kde.args)
            if (now === kde.done || !kde.args.length || run.running) return
            kde.done = now
            run.command = ["sh", "-c", "while [ $# -ge 3 ]; do kwriteconfig6 --notify --file kdeglobals --group \"$1\" --key \"$2\" \"$3\"; shift 3; done", "kde"].concat(kde.args)
            run.running = true
        }
    }
    Process { id: run; onExited: if (JSON.stringify(kde.args) !== kde.done) wait.restart() }
}
