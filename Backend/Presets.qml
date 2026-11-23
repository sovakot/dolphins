pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Data/Dynamic"

Singleton {
    id: root

    readonly property string home: String(Quickshell.shellDir).replace(/\/+$/, "")
    readonly property string dir: home + "/Data/Dynamic/Presets"
    readonly property string stockName: "Default"
    readonly property string current: String(Config.values?.dolphin_Preset ?? "") || stockName
    readonly property var skipped: ["dolphin_Preset", "GroupedPanels"]
    property var names: []
    property string target: ""
    property bool busy: false
    property string note: ""

    function file(name) { return name === stockName ? home + "/Data/Static/backup.json" : dir + "/" + name + ".json" }
    function clean(name) { return String(name ?? "").replace(/[\/\\\u0000-\u001f]/g, "").trim().replace(/^\.+/, "").trim().slice(0, 40) }
    function taken(name) { return name.toLowerCase() === stockName.toLowerCase() || names.some(n => n.toLowerCase() === name.toLowerCase()) }
    function free(stem) {
        if (!taken(stem)) return stem
        let n = 2
        while (taken(stem + " " + n)) n++
        return stem + " " + n
    }
    function same(a, b, top) {
        if (a === b) return true
        if (a === null || b === null || typeof a !== "object" || typeof b !== "object" || Array.isArray(a) !== Array.isArray(b)) return false
        const keys = Object.keys(a).filter(k => !top || !skipped.includes(k)), other = Object.keys(b).filter(k => !top || !skipped.includes(k))
        if (keys.length !== other.length) return false
        for (const k of keys) if (!same(a[k], b[k], false)) return false
        return true
    }
    function changed() { return !same(Config.values, Config.stock, true) }
    function stamp(text, name) {
        const v = JSON.stringify(name), re = /("dolphin_Preset"\s*:\s*)"(?:[^"\\]|\\.)*"/
        if (re.test(text)) return text.replace(re, (m, a) => a + v)
        const open = text.indexOf("{")
        return open < 0 ? text : text.slice(0, open + 1) + "\n    \"dolphin_Preset\" : " + v + "," + text.slice(open + 1)
    }
    function run(script, args) {
        if (busy) return false
        busy = true
        note = ""
        job.command = ["sh", "-c", "mkdir -p \"$1\" && cd \"$1\" && " + script, "presets", dir].concat(args)
        job.running = true
        return true
    }
    function refresh() { if (!lister.running) lister.running = true }
    function add(name) {
        const n = clean(name)
        if (n === "" || taken(n) || !Config.valid) return false
        if (!run("{ [ -z \"$4\" ] || cp -f \"$2\" \"./$4.json\"; } && cp -f \"$2\" \"./$3.json\"", [Config.where, n, current !== stockName ? current : ""])) return false
        Config.set("dolphin_Preset", n)
        return true
    }
    function rename(old, name) {
        const n = clean(name)
        if (old === stockName || n === "" || (taken(n) && n.toLowerCase() !== old.toLowerCase())) return false
        if (n === old) return true
        if (!run("mv -f \"./$2.json\" \"./$3.json\"", [old, n])) return false
        if (current === old) Config.set("dolphin_Preset", n)
        return true
    }
    function remove(name) {
        if (name === stockName || !run("rm -f \"./$2.json\"", [name])) return false
        if (current === name) Config.set("dolphin_Preset", stockName)
        return true
    }
    function use(name) {
        if (busy || !Config.valid || (name === current && name !== stockName)) return false
        const keep = current !== stockName ? current : changed() ? free("Custom") : ""
        if (name === stockName && keep === "") return true
        busy = true
        note = ""
        target = name
        loader.command = ["sh", "-c", "mkdir -p \"$1\" && { [ -z \"$2\" ] || cp -f \"$3\" \"$1/$2.json\"; } && cat \"$4\"", "presets", dir, keep, Config.where, file(name)]
        loader.running = true
        return true
    }
    function took(text) {
        busy = false
        if (Config.obj(text) === null) note = "This preset could not be read."
        else Config.write(stamp(text, target))
        refresh()
    }

    Component.onCompleted: refresh()

    Process {
        id: lister
        command: ["sh", "-c", "mkdir -p \"$1\" && cd \"$1\" && for f in *.json; do [ -f \"$f\" ] && printf '%s\\n' \"${f%.json}\"; done; true", "presets", root.dir]
        stdout: StdioCollector { onStreamFinished: root.names = text.split("\n").filter(n => n !== "").sort((a, b) => a.localeCompare(b)) }
    }
    Process {
        id: job
        onExited: (exitCode, exitStatus) => {
            root.busy = false
            if (exitCode !== 0) root.note = "That did not work."
            root.refresh()
        }
    }
    Process {
        id: loader
        stdout: StdioCollector { onStreamFinished: root.took(text) }
    }
}
