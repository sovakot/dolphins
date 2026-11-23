pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string body: file.text()
    readonly property var raw: obj(body)
    property var claims: ({})
    property var spare: null
    readonly property bool valid: raw !== null
    readonly property var stock: obj(back.text()) ?? {}
    readonly property var solid: merge(raw ?? {}, stock)
    readonly property var values: solid
    readonly property var tones: shade ?? seen ?? pick(solid).set ?? ({})
    readonly property string look: { const p = pick(solid); return p.name + "|" + JSON.stringify(p.set ?? {}) }
    property var shade: null
    property var seen: null
    property var past: null
    property var goal: null
    property string wore: ""
    property int stride: 0

    onLookChanged: turn()

    function pick(v) {
        const all = v.Theme, want = v.dolphin_ThemeBackground === true ? "Wallpaper" : String(v.dolphin_Theme ?? ""), cap = want.charAt(0).toUpperCase() + want.slice(1)
        const name = plain(all) ? (plain(all[want]) ? want : plain(all[cap]) ? cap : "") : ""
        return { name: name, set: name !== "" ? all[name] : null }
    }
    function hex(a, b, t) {
        const ok = /^#[0-9a-f]{6}$/i
        if (typeof a !== "string" || typeof b !== "string" || !ok.test(a) || !ok.test(b)) return t < 0.5 ? a ?? b : b
        let out = "#"
        for (let i = 1; i < 7; i += 2) {
            const x = parseInt(a.slice(i, i + 2), 16), y = parseInt(b.slice(i, i + 2), 16)
            out += Math.round(x + (y - x) * t).toString(16).padStart(2, "0")
        }
        return out
    }
    function blend(from, to, t) {
        const out = {}
        for (const k in to) out[k] = hex(from[k], to[k], t)
        return out
    }
    function turn() {
        const now = pick(solid), time = Math.max(0, Number(solid.dolphin_ThemeFade ?? 400) || 0), before = shade ?? seen
        let moved = 0
        if (now.set && before) for (const k in now.set) if (now.set[k] !== before[k]) moved++
        if (!now.set || !before || time < 40 || solid.system_Animations === false || (now.name === wore && moved < 3)) {
            fader.stop()
            shade = null
            seen = now.set
            wore = now.name
            return
        }
        past = before
        goal = now.set
        wore = now.name
        stride = 0
        shade = before
        fader.interval = Math.max(16, Math.round(time / 10))
        fader.restart()
    }

    Timer {
        id: fader
        repeat: true
        onTriggered: {
            root.stride++
            if (root.stride < 10) { root.shade = root.blend(root.past, root.goal, root.stride / 10); return }
            stop()
            root.seen = root.goal
            root.shade = null
        }
    }
    readonly property var words: obj(dict.text()) ?? {}

    function plain(v) { return v !== null && typeof v === "object" && !Array.isArray(v) }
    function parse(t) {
        try { const v = JSON.parse(t); return plain(v) ? v : null } catch (e) { return null }
    }
    function obj(t) { return parse(t) ?? parse(String(t).replace(/,(\s*[}\]])/g, "$1")) }
    readonly property string where: String(Quickshell.shellDir).replace(/\/+$/, "") + "/Data/Dynamic/config.json"
    function read() {
        body = file.text()
        if (valid) return
        console.warn("config.json is not valid JSON, backup.json is used until it is fixed")
        report.running = true
    }
    function merge(c, b) {
        const o = {}
        for (const k in b) {
            const x = c[k], y = b[k]
            o[k] = plain(x) && plain(y) ? merge(x, y) : typeof x === typeof y && Array.isArray(x) === Array.isArray(y) ? x : y
        }
        for (const k in c) if (!(k in b)) o[k] = c[k]
        return o
    }

    function write(text) {
        if (text === body) return
        body = text
        file.setText(text)
    }
    function set(key, value) {
        if (!valid) return
        const text = body, v = JSON.stringify(value)
        const re = new RegExp("(\"" + key + "\"\\s*:\\s*)(\"(?:[^\"\\\\]|\\\\.)*\"|[^,\\n}\\]]+)")
        if (re.test(text)) return write(text.replace(re, (m, a) => a + v))
        const open = text.indexOf("{")
        write(text.slice(0, open + 1) + "\n    \"" + key + "\" : " + v + "," + text.slice(open + 1))
    }
    function list(key, value) {
        if (!valid || !Array.isArray(value)) return
        const v = JSON.stringify(value)
        const re = new RegExp("(\"" + key + "\"\\s*:\\s*)\\[[^\\]]*\\]")
        if (re.test(body)) return write(body.replace(re, (m, a) => a + v))
        const open = body.indexOf("{")
        write(body.slice(0, open + 1) + "\n    \"" + key + "\" : " + v + "," + body.slice(open + 1))
    }
    function many(o) {
        if (!valid || !plain(o)) return
        let text = body
        for (const key in o) {
            const v = JSON.stringify(o[key])
            const re = Array.isArray(o[key]) ? new RegExp("(\"" + key + "\"\\s*:\\s*)\\[[^\\]]*\\]") : new RegExp("(\"" + key + "\"\\s*:\\s*)(\"(?:[^\"\\\\]|\\\\.)*\"|[^,\\n}\\]]+)")
            if (re.test(text)) { text = text.replace(re, (m, a) => a + v); continue }
            const open = text.indexOf("{")
            text = text.slice(0, open + 1) + "\n    \"" + key + "\" : " + v + "," + text.slice(open + 1)
        }
        write(text)
    }
    function panel(id, key, value) {
        const at = valid ? body.indexOf("\"GroupedPanels\"") : -1, from = at < 0 ? -1 : body.indexOf("{", at)
        if (from < 0) return
        let end = from, depth = 0
        for (; end < body.length; end++) {
            if (body[end] === "{") depth++
            else if (body[end] === "}" && --depth === 0) break
        }
        const m = new RegExp("\"" + String(id).replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\"\\s*:\\s*\\{").exec(body.slice(from, end))
        if (!m) return
        const open = from + m.index + m[0].length - 1, close = body.indexOf("}", open)
        const inner = body.slice(open, close), v = JSON.stringify(value)
        const re = new RegExp("(\"" + key + "\"\\s*:\\s*)(\"(?:[^\"\\\\]|\\\\.)*\"|[^,\\n}]+)")
        write(body.slice(0, open) + (re.test(inner) ? inner.replace(re, (x, a) => a + v) : "{\n            \"" + key + "\" : " + v + "," + inner.slice(1)) + body.slice(close))
    }
    function swap(name, o) {
        if (!valid || !plain(o)) return
        const at = body.indexOf("\"" + name + "\"")
        if (at < 0) return
        const open = body.indexOf("{", at)
        if (open < 0) return
        let i = open, depth = 0
        for (; i < body.length; i++) {
            if (body[i] === "{") depth++
            else if (body[i] === "}" && --depth === 0) break
        }
        const pad = body.slice(body.lastIndexOf("\n", at) + 1, at)
        const rows = Object.keys(o).map(k => pad + "    \"" + k + "\" : " + JSON.stringify(o[k]))
        write(body.slice(0, open) + "{\n" + rows.join(",\n") + "\n" + pad + "}" + body.slice(i + 1))
    }
    function claim(owner, ids, base) {
        claims[owner] = ids
        if (plain(base)) spare = base
        settle.restart()
    }
    function block(o) {
        const rows = Object.keys(o).map(id => "        \"" + id + "\" : {\n"
            + Object.keys(o[id]).map(k => "            \"" + k + "\" : " + JSON.stringify(o[id][k])).join(",\n")
            + "\n        }")
        return "\"GroupedPanels\" : {\n" + rows.join(",\n") + "\n    }"
    }
    function splice(text, body) {
        const at = text.indexOf("\"GroupedPanels\"")
        if (at < 0) {
            const open = text.indexOf("{")
            return text.slice(0, open + 1) + "\n    " + body + ",\n" + text.slice(open + 1)
        }
        let i = text.indexOf("{", at), depth = 0
        for (; i < text.length; i++) {
            if (text[i] === "{") depth++
            else if (text[i] === "}" && --depth === 0) break
        }
        return text.slice(0, at) + body + text.slice(i + 1)
    }
    function syncPanels() {
        const kept = values.GroupedPanels?.Default
        const base = plain(kept) ? kept : spare
        if (!valid || !plain(base)) return
        let ids = []
        for (const o in claims) ids = ids.concat(claims[o])
        ids.sort()
        const old = plain(raw.GroupedPanels) ? raw.GroupedPanels : {}
        const free = Object.keys(old).filter(k => k !== "Default" && !ids.includes(k))
        const title = t => t.split("+").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join("+")
        const next = {}
        for (const id of ids) {
            let from = plain(old[id]) ? id : "", name = id
            if (!from) {
                const parts = id.toLowerCase().split("+")
                let most = 0
                for (const k of free) {
                    const n = k.toLowerCase().split("+").filter(m => parts.includes(m)).length
                    if (n > most && plain(old[k])) { most = n; from = k }
                }
                if (from) {
                    free.splice(free.indexOf(from), 1)
                    const kept = from.toLowerCase().split("+").filter(m => parts.includes(m))
                    name = title(kept.concat(parts.filter(m => !kept.includes(m))).join("+"))
                }
            }
            next[name] = from ? old[from] : plain(stock.GroupedPanels?.[name]) ? stock.GroupedPanels[name] : base
        }
        if (plain(old.Default)) next.Default = old.Default
        if (JSON.stringify(next) === JSON.stringify(old)) return
        write(splice(body, block(next)))
    }

    Process {
        id: report
        command: ["sh", "-c", "m=$(jq empty \"$1\" 2>&1 | tail -n1); notify-send -u critical -a Dolphin 'config.json has a mistake' \"$m\"", "report", root.where]
    }
    Timer { id: settle; interval: 300; onTriggered: root.syncPanels() }
    Timer { id: fresh; interval: 150; onTriggered: file.reload() }

    FileView {
        id: file
        path: Qt.resolvedUrl("config.json")
        watchChanges: true
        blockLoading: true
        onFileChanged: fresh.restart()
        onLoaded: root.read()
    }
    FileView {
        id: back
        path: Qt.resolvedUrl("../Static/backup.json")
        blockLoading: true
    }
    FileView {
        id: dict
        path: Qt.resolvedUrl("../Static/words.json")
        blockLoading: true
    }
}
