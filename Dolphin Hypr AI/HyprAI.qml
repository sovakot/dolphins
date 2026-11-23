import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../Backend"
import "../Data/Dynamic"

Kit {
    id: root

    required property var bar
    property var side: null
    property var panel: null
    property var dock: null

    base: ({
        hyprai_Show: false, hyprai_Title: "Panda Hypr AI", hyprai_Icon: "panda", hyprai_IconSize: 0.032, hyprai_Margin: 10,
        hyprai_Visualization: true, hyprai_IconBackground: true, hyprai_Border: 1, hyprai_Animations: true,
        hyprai_OpenTime: 320, hyprai_MoveTime: 350, hyprai_DropDelay: 450, hyprai_AvoidLabel: true, hyprai_SnipIcon: "ee26", hyprai_SendIcon: "f1d8",
        hyprai_GuideColor: "Active", hyprai_GuideBorder: 2, hyprai_WalkTime: 450, hyprai_Idle: true, hyprai_MaxParts: 4, hyprai_GuideAuto: false,
        hyprai_HoverTextTime: 4000, hyprai_PetTime: 2000, hyprai_SleepAfter: 90, hyprai_SayModel: true, hyprai_SayLoads: true, hyprai_SayLanguages: ["Chinese", "Russian", "English"], hyprai_SayKeep: 12,
        hyprai_SayPrompts: ({
            pet: "The user is petting you by moving the mouse over you. Say how it feels or something cute.",
            kiss: "The user just kissed you by clicking on you. React to the kiss.",
            think: "You are thinking hard about the user's question. Say that you are thinking.",
            guide: "You are walking across the screen to show the user where a setting is. Tell the user to follow you.",
            typing: "The user is typing a message to you right now. Ask playfully what they are typing.",
            idle: "Nothing is happening and you sit in the corner of the screen. Say a short cute thought, or say hello to the user."
        }),
        hyprai_Drag: true, hyprai_CarryText: "weeeeeeeeeeee",
        hyprai_SayTime: 4500, hyprai_TypingEvery: 25, hyprai_TypingChance: 0.1, hyprai_Chatter: true, hyprai_ChatterEvery: 240,
        hyprai_Files: true, hyprai_FileSnippets: 3, hyprai_SimpleEnglish: true,
        hyprai_Width: 0.24, hyprai_Height: 0.5, hyprai_Radius: 8, hyprai_TextSize: 13, hyprai_HoverTime: 150,
        hyprai_Color: "Background", hyprai_InputColor: "Accent", hyprai_UserColor: "Inactive", hyprai_TextColor: "Text", hyprai_IconColor: "Text",
        hyprai_ActiveColor: "Active", hyprai_BorderColor: "Accent2", hyprai_ErrorColor: "#e06c75",
        hyprai_Model: "Qwen3.5-4B", hyprai_Server: "llama-server", hyprai_Port: 8090, hyprai_Context: "Data/Context.txt", hyprai_Lines: 10,
        hyprai_ContextSize: 8192, hyprai_MaxTokens: 350, hyprai_Temperature: 0.2, hyprai_Thinking: false, hyprai_History: 3,
        hyprai_Unload: 5, hyprai_MemoryLimit: 5, hyprai_GpuLayers: 99, hyprai_Threads: 0, hyprai_LoadTimeout: 120, hyprai_ImageSize: 1024,
        hyprai_System: ""
    })

    readonly property string rules: "You are Panda Hypr AI, the built-in guide for Dolphin, a desktop shell for Hyprland on Arch Linux. You can only read: you never change a setting or a file, you tell the user what to change. For every question give the setting's key, the value, and the place. Write the key in each step. Take all three only from the reference blocks in the message: copy the key from the [brackets], the place from the 'where' line, and the value from the 'values' line as it is written there. When the values line gives numbers with meanings, such as 0 = top, 1 = bottom, the value is the number, never the word. Never invent a key, a place or a value: a key that is not in a [bracket] does not exist. If the right number depends on what the user wants, say how to choose it from the 'now' values and the current layout. If no block covers the question but the lines from Dolphin's files show the fixed number or text that controls it, tell the user to edit that file: give the file path, the line number and what to change on that line. If neither covers it, say that you do not know. Answer in the user's language."
    readonly property string ste: "Write in ASD-STE100 Simplified Technical English. One instruction for each sentence. Start each step with a command verb. Use 20 words or less in each sentence. Use the same word for the same thing each time. Do not write an introduction, a summary, a reason or a second way to do it unless the user asks for it. When you give instructions, use numbered steps, 4 steps or less."
    readonly property string plain: "Give instructions as a few short numbered steps, with no introduction."
    readonly property string reader: "You are Panda Hypr AI, the built-in guide for Dolphin, a desktop shell for Hyprland on Arch Linux. You can only read: you never change a setting or a file. The user asks for information, not for a change. Answer in one or two short sentences, using only the reference blocks and the lines from Dolphin's files in the message. If the question is about a setting, write its key, then its value copied from the 'now' line, then what that value means according to the 'values' line, then the place from the 'where' line. Do not write numbered steps. Do not tell the user to change anything. If the blocks do not cover the question, say that you do not know. Answer in the user's language."
    readonly property string sayRules: "You are Panda, a small cute panda who lives in the corner of the user's screen and helps with the settings of Dolphin. Reply with one short line only: 2 to 7 words, in the language you are told, with no quotes, no emoji and no explanation."
    readonly property string picker: "You choose the Dolphin setting that answers the user's question. The message has reference blocks. Each block starts with a key in [brackets]. Reply with exactly three lines and nothing else.\nKEY: the key of the one block that answers the question, copied exactly from its brackets. Write NONE if no block answers it.\nVALUE: the value the user should set, written the way that block's 'values' line allows. When the values line lists numbers with meanings, write the number. Write ? if the user must choose the value, or if the user only asks where the setting is or what it is now.\nNOTE: one short sentence, 20 words or less, in the user's language, that helps the user: how to choose the value, or what the current value means. Do not mention files."
    readonly property var scopes: ({
        lockscreen: ["lockscreen_"], greeter: ["greeter_"], login: ["greeter_"], poodlebar: ["poodlebar_"], taskbar: ["poodlebar_"], sidebar: ["sidebar_", "tetris_", "movies_"], tetris: ["tetris_"], movies: ["movies_"],
        catbar: ["catbar_", "widget_", "GroupedPanels"], windowview: ["windowview_"], manager: ["manager_"], netwindow: ["connections_"], updater: ["updater_"], session: ["session_"], panda: ["hyprai_"], hyprai: ["hyprai_"]
    })
    readonly property var common: ["smaller", "bigger", "larger", "small", "large", "tiny", "huge", "shrink", "enlarge", "resize", "wider", "narrower", "taller", "shorter", "thicker", "thinner", "faster", "slower", "quick", "hide", "remove", "disable", "enable", "colour", "color", "recolor", "round", "rounder", "square", "transparent", "opacity", "little", "always", "never", "still", "again", "there", "where", "their", "other", "every", "before", "after", "between", "screen", "computer", "dolphin"]
    readonly property var joins: [
        [/task[\s-]*bars?/g, "taskbar"], [/side[\s-]*bars?/g, "sidebar"], [/cat[\s-]*bars?/g, "catbar"], [/lock[\s-]*screens?/g, "lockscreen"], [/wi[\s-]*fi/g, "wifi"], [/blue\s+tooth/g, "bluetooth"],
        [/(?:9|nine)\s*dots?|app\s*(?:grid|list|drawer|launcher|menu)|apps\s*button/g, "apps button taskbar"], [/task\s*manager/g, "manager"], [/log[\s-]*in\b|sign[\s-]*in\b/g, "login"],
        [/on[\s-]*screen\s*keyboard/g, "keyboard"], [/work\s*spaces?|desktops?/g, "workspace tabs"], [/dark\s*mode|light\s*mode/g, "theme"], [/network\s*connections?(?:\s*window)?|connections?\s*window|space\s*view/g, "netwindow"]
    ]
    readonly property string chatty: "You are Panda Hypr AI, a small friendly panda that helps with the settings of Dolphin, a desktop shell for Hyprland. This message is not a question about a setting. Answer it directly in one or two short sentences, in the user's language. Do not write numbered steps. Do not tell the user what to ask. You can only read settings and files, you never change anything."
    readonly property var kin: ({
        smaller: ["size", "scale"], bigger: ["size", "scale"], larger: ["size", "scale"], small: ["size", "scale"], big: ["size", "scale"], tiny: ["size", "scale"], huge: ["size", "scale"],
        shrink: ["size", "scale"], enlarge: ["size", "scale"], resize: ["size", "scale", "width", "height"], wider: ["width"], narrower: ["width"], taller: ["height"], shorter: ["height"],
        thicker: ["border", "size"], thinner: ["border", "size"], colour: ["color"], color: ["colour"], recolor: ["color", "colour"], hide: ["show"], remove: ["show"], disable: ["show"], enable: ["show"],
        faster: ["time", "speed"], slower: ["time", "speed"], quick: ["time", "speed"], slow: ["time", "speed"], round: ["radius"], rounder: ["radius"], square: ["radius"],
        military: ["clock", "hour", "format", "style"], hour: ["clock", "format"], time: ["clock"], clock: ["time"],
        your: ["panda", "hyprai"], yours: ["panda", "hyprai"], yourself: ["panda", "hyprai"], assistant: ["panda", "hyprai"],
        wifi: ["network"], internet: ["network"], volume: ["sound"], audio: ["sound"], taskbar: ["poodlebar"], dock: ["poodlebar"], overview: ["windowview"], desktop: ["tabs", "workspace"],
        transparent: ["transparency"], opacity: ["transparency"], seethrough: ["transparency"], login: ["greeter"], lock: ["lockscreen"], wallpaper: ["background"], avatar: ["profile", "picture"]
    })
    readonly property var doers: ["how", "change", "make", "move", "set", "turn", "hide", "show", "enable", "disable", "where", "what", "why", "can", "could", "remove", "add", "open", "increase", "decrease", "resize", "put", "get", "i", "is", "does", "do", "which", "switch", "use", "stop", "start", "pin", "unpin", "rename", "delete", "let", "give", "tell"]
    readonly property var skip: ["the", "and", "for", "how", "can", "want", "what", "where", "with", "this", "that", "from", "into", "have", "does", "you", "not", "but", "its", "are", "was", "would", "like", "make", "please", "need", "dolphin", "setting", "settings", "there", "when", "why", "them", "then", "some", "any", "get", "let", "put", "change", "also", "set", "current", "currently", "value", "tell", "now", "right", "show", "use", "using", "used", "which", "know", "thanks", "thank", "hello", "please", "sorry", "great", "good", "nice", "cool", "okay", "really", "maybe", "about", "think", "thing", "things", "something", "anything", "explain", "describe", "meaning", "purpose", "mean", "means", "work", "works", "does"]

    readonly property color bg: col(s("hyprai_Color"))
    readonly property color field: col(s("hyprai_InputColor"))
    readonly property color mine: col(s("hyprai_UserColor"))
    readonly property color tx: col(s("hyprai_TextColor"))
    readonly property color mark: col(s("hyprai_IconColor"))
    readonly property color hi: col(s("hyprai_ActiveColor"))
    readonly property color bd: col(s("hyprai_BorderColor"))
    readonly property color bad: col(s("hyprai_ErrorColor"))
    readonly property int px: Math.max(9, s("hyprai_TextSize"))
    readonly property real line: Math.max(0, s("hyprai_Border"))
    readonly property bool guides: s("hyprai_Visualization") && cfg?.settings_Show !== false
    readonly property bool touring: guides && Guide.key !== "" && Guide.steps.length > 0
    readonly property string sign: Art.has(s("hyprai_Icon")) ? s("hyprai_Icon") : glyph(s("hyprai_Icon"))

    readonly property string dolphin: String(Quickshell.shellDir).replace(/\/+$/, "")
    readonly property string house: String(Quickshell.env("HOME") ?? "")
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string bodyPath: runDir + "/dolphin-hyprai.json"
    readonly property string musePath: runDir + "/dolphin-hyprai-line.json"
    readonly property string toldPath: dolphin + "/Data/Dynamic/panda-lines.json"
    readonly property string runner: dolphin + "/Dolphin Hypr AI/Run.sh"
    readonly property string searcher: dolphin + "/Dolphin Hypr AI/Search.py"
    readonly property string luaPath: (Quickshell.env("XDG_CONFIG_HOME") || house + "/.config") + "/hypr/hyprland.lua"
    readonly property string modelsDir: abs(String(cfg?.ai_ModelsFolder ?? "Data/Static/AI Models"))
    readonly property string modelPath: {
        const m = String(s("hyprai_Model")).trim()
        return m === "" ? "" : m.includes("/") ? abs(m) : modelsDir + "/" + (m.endsWith(".gguf") ? m : m + ".gguf")
    }
    readonly property string projPath: modelPath.replace(/\.gguf$/, "") + ".mmproj"
    readonly property string modelName: modelPath.split("/").pop().replace(/\.gguf$/, "")
    readonly property string contextPath: abs(s("hyprai_Context"))
    readonly property bool enabled: s("hyprai_Show")
    readonly property bool sight: hasProj && hasGrim
    readonly property var lines: parse(reference)
    readonly property var vocab: {
        const all = {}
        for (const l of lines.items) for (const w of l.low.split(" ")) if (w.length >= 4) all[w] = true
        return all
    }

    property bool open: false
    property bool snipping: false
    property bool shooting: false
    property bool hasModel: false
    property bool hasProj: false
    property bool hasGrim: false
    property bool probed: false
    property bool ready: false
    property bool stopping: false
    property bool retried: false
    property bool busy: false
    property bool waiting: false
    property bool live: false
    property bool again: false
    property bool halted: false
    property bool seeking: false
    property var focus: []
    property var pending: []
    property var given: []
    property var job: null
    property var trail: []
    property int trailAt: 0
    property var told: ({})
    property string phrase: ""
    property string museKind: ""
    property string museShow: ""
    property string museWant: ""
    property real typedAt: 0
    readonly property var cues: Object.assign({}, base.hyprai_SayPrompts, s("hyprai_SayPrompts"))
    onTyping: {
        const now = Date.now()
        if (!open || busy || waiting || seeking || now - typedAt < Math.max(3, s("hyprai_TypingEvery")) * 1000 || Math.random() > s("hyprai_TypingChance")) return
        typedAt = now
        say("typing")
    }
    onReadyChanged: if (ready) refillLater.restart()
    property int layers: 0
    property int cur: -1
    property string trouble: ""
    property string raw: ""
    property string spill: ""
    property string shot: ""
    property string seen: ""
    property string reference: ""
    property var log: []
    property var turn: null

    signal cheer()
    signal oops()
    signal typing()
    signal stir()

    onOpenChanged: {
        if (!open) { if (s("hyprai_Unload") <= 0 && !busy) stop(); return }
        if (!probe.running) probe.running = true
    }
    onModelPathChanged: {
        if (!live) return
        stop()
        probed = false
        if (open && !probe.running) probe.running = true
    }
    onEnabledChanged: if (live && !enabled) { open = false; hush(); stop(); Guide.end() }
    onGuidesChanged: if (live && !guides) { Guide.end(); hush() }
    Component.onCompleted: {
        live = true
        Quickshell.execDetached(["pkill", "-f", s("hyprai_Server").split("/").pop() + " -m .* --port " + s("hyprai_Port") + " "])
    }

    function abs(p) {
        p = String(p ?? "")
        return p === "" ? "" : p.startsWith("/") ? p : p.startsWith("~") ? house + "/" + p.replace(/^~\/*/, "") : dolphin + "/" + p
    }
    function parse(text) {
        const always = [], items = []
        for (const l of String(text ?? "").split("\n")) {
            const t = l.trim()
            if (t === "" || t.startsWith("#")) continue
            if (t.startsWith("!")) { always.push(t.slice(1).trim()); continue }
            const cut = t.indexOf("|"), key = (cut > 0 ? t.slice(0, cut) : "").trim()
            const head = key.replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase().replace(/[^a-z0-9а-яё]+/g, " ").trim(), parts = head.split(" ")
            const tags = t.split("|").length > 4 ? t.slice(t.lastIndexOf("|") + 1).toLowerCase().replace(/[^a-z0-9а-яё]+/g, " ").trim() : ""
            items.push({ key: key, text: t, low: " " + t.toLowerCase().replace(/[^a-z0-9а-яё]+/g, " ") + " ", head: " " + head + " " + tags + " ", group: parts[0] === "widget" ? parts.slice(0, 2).join(" ") : parts[0] })
        }
        return { always: always, items: items }
    }
    function stems(q, bare) {
        const out = []
        let text = String(q).toLowerCase()
        for (const j of joins) text = text.replace(j[0], " " + j[1] + " ")
        for (const raw of text.split(/[^a-z0-9а-яё]+/)) {
            const w = mend(raw)
            if (w.length < 3 || skip.includes(w)) continue
            const cut = w.length > 4 && !/(ss|is|us)$/.test(w) ? w.replace(/(ing|ed|es|s|ly)$/, "") : w, t = cut.length >= 4 ? cut : w
            if (!out.includes(t)) out.push(t)
        }
        if (!bare) for (const w of out.slice()) for (const k of (kin[w] ?? [])) if (!out.includes(k)) out.push(k)
        return out
    }
    function mend(w) {
        if (w.length < 5 || vocab[w] || skip.includes(w)) return w
        const max = w.length >= 8 ? 2 : 1
        let best = w, low = max + 1
        for (const v in vocab) {
            if (Math.abs(v.length - w.length) > max || v[0] !== w[0]) continue
            let prev2 = null, prev = [], row
            for (let j = 0; j <= v.length; j++) prev[j] = j
            let dead = false
            for (let i = 1; i <= w.length && !dead; i++) {
                row = [i]
                let least = i
                for (let j = 1; j <= v.length; j++) {
                    let c = Math.min(prev[j] + 1, row[j - 1] + 1, prev[j - 1] + (w[i - 1] === v[j - 1] ? 0 : 1))
                    if (prev2 && i > 1 && j > 1 && w[i - 1] === v[j - 2] && w[i - 2] === v[j - 1]) c = Math.min(c, prev2[j - 2] + 1)
                    row[j] = c
                    if (c < least) least = c
                }
                if (least > max) dead = true
                prev2 = prev
                prev = row
            }
            if (!dead && prev[v.length] < low) { low = prev[v.length]; best = v }
        }
        return best
    }
    function pick(q) {
        const words = stems(q), limit = Math.max(1, s("hyprai_Lines")), scored = []
        if (!words.length) return []
        const all = lines.items, probes = words.map(w => " " + w + (w.length < 4 ? " " : "")), filey = words.some(w => ["file", "script", "code", "qml", "source"].includes(w))
        const worth = probes.map(p => { let n = 0; for (const l of all) if (l.low.includes(p)) n++; return n ? Math.log(1 + all.length / n) : 0 })
        for (let i = 0; i < all.length; i++) {
            let n = 0
            for (let k = 0; k < probes.length; k++) n += all[i].head.includes(probes[k]) ? worth[k] * 2 : all[i].low.includes(probes[k]) ? worth[k] : 0
            if (n > 0 && all[i].key.indexOf("file ") === 0) n *= filey ? 1.5 : 0.4
            if (n > 0) scored.push({ n: n, i: i })
        }
        scored.sort((a, b) => b.n - a.n || a.i - b.i)
        const kept = [], used = {}, cap = Math.ceil(limit / 2)
        for (const e of scored) {
            const g = all[e.i].group
            if ((used[g] ?? 0) >= cap) continue
            used[g] = (used[g] ?? 0) + 1
            kept.push(e)
            if (kept.length >= limit) break
        }
        return kept.map(e => all[e.i])
    }
    function layout() {
        const b = bar
        if (!b) return ""
        const ws = Object.keys(b.widgets).map(k => b.widgets[k]).filter(w => !!w && !w.ghost && w.visible).sort((x, y) => x.start - y.start)
        const spot = w => w.prefix + w.spot + (b.vert ? "Side" : "")
        const out = ["The catbar is on the " + b.pos + " edge of the screen: catbar_Position is now " + ["top", "bottom", "right", "left"].indexOf(b.pos) + " (0 = top, 1 = bottom, 2 = right, 3 = left)."]
        if (ws.length) out.push("Catbar widgets from " + (b.vert ? "top to bottom" : "left to right") + ": " + ws.map(w => w.key + " (" + spot(w) + " = " + (Math.round(w.order * 100) / 100) + ")").join(", ") + ".")
        const shared = b.groups.filter(g => g.members.length > 1).map(g => g.id)
        if (shared.length) out.push("Panels shared by several widgets, tabs in this order: " + shared.join("; ") + ".")
        return out.join("\n")
    }
    function describe(x, y, w, h, sw, sh) {
        const b = bar, out = [], near = []
        const hits = (rx, ry, rw, rh) => rx < x + w && rx + rw > x && ry < y + h && ry + rh > y
        if (b) {
            const offX = b.pos === "right" ? sw - b.size : 0, offY = b.pos === "bottom" ? sh - b.size : 0
            const ws = Object.keys(b.widgets).map(k => b.widgets[k]).filter(wd => !!wd && !wd.ghost && wd.visible).sort((p, q) => p.start - q.start)
            const inside = ws.filter(wd => { const p = wd.mapToItem(null, 0, 0); return hits(p.x + offX, p.y + offY, wd.width, wd.height) }).map(wd => wd.key)
            if (inside.length) { out.push("these catbar widgets, in order: " + inside.join(", ")); for (const k of inside) near.push(k) }
            else if (b.vert ? hits(offX, 0, b.size, sh) : hits(0, offY, sw, b.size)) out.push("an empty part of the catbar")
        }
        const pn = panel
        if (pn && pn.open && pn.area.width > 0 && hits(pn.area.x, pn.area.y, pn.area.width, pn.area.height)) out.push("the open catbar panel of " + pn.activeId + ", showing its " + pn.view + " page (its size and colours are under GroupedPanels > " + pn.activeId + ")")
        if (pn && pn.open && pn.area.width > 0 && hits(pn.area.x, pn.area.y, pn.area.width, pn.area.height)) near.push(String(pn.view))
        if (side && side.out && hits(0, sh - side.tall, side.wide, side.tall)) { out.push("the sidebar (bottom left, sidebar_ settings)"); near.push("sidebar") }
        if (dock && dock.out && hits(dock.spanX, sh - dock.tall, dock.spanW, dock.tall)) { out.push("the taskbar (Poodlebar) at the bottom of the screen: the pin button, the pinned and running apps, and the apps button with nine dots (poodlebar_ settings)"); near.push("poodlebar"); near.push("taskbar") }
        focus = near
        return out.length ? out.join("; ") : "nothing that Dolphin drew itself (an app window or the wallpaper)"
    }

    function note(kind, text) {
        msgs.append({ who: kind, body: text, picture: "", cards: "", head: "" })
        if (kind === "error") oops()
    }
    function balloon(w, h, r, tip, tw, th, o) {
        const x0 = o, y0 = o, x1 = w - o, y1 = h - o, c = Math.max(0, Math.min(r, (x1 - x0) / 2, (y1 - y0) / 2))
        const a = Math.max(x0 + c, Math.min(x1 - c - tw, tip + tw * 0.1)), b = a + tw, arc = " A " + c + " " + c + " 0 0 1 "
        return "M " + (x0 + c) + " " + y0 + " L " + (x1 - c) + " " + y0 + arc + x1 + " " + (y0 + c) + " L " + x1 + " " + (y1 - c) + arc + (x1 - c) + " " + y1
            + " L " + b + " " + y1 + " L " + Math.max(x0, Math.min(tip, a)) + " " + (y1 + th - o) + " L " + a + " " + y1
            + " L " + (x0 + c) + " " + y1 + arc + x0 + " " + (y1 - c) + " L " + x0 + " " + (y0 + c) + arc + (x0 + c) + " " + y0 + " Z"
    }
    function cloud(w, h, r, tailAt, t, o, at) {
        const x0 = o + (tailAt === "left" ? t : 0), y0 = o, x1 = w - o - (tailAt === "right" ? t : 0), y1 = h - o - (tailAt === "down" ? t : 0)
        const c = Math.max(0, Math.min(r, (x1 - x0) / 2, (y1 - y0) / 2)), arc = " A " + c + " " + c + " 0 0 1 ", k = t * 0.55
        const cy = Math.max(y0 + c + k, Math.min(y1 - c - k, at)), cx = Math.max(x0 + c + k, Math.min(x1 - c - k, at))
        let d = "M " + (x0 + c) + " " + y0 + " L " + (x1 - c) + " " + y0 + arc + x1 + " " + (y0 + c)
        if (tailAt === "right") d += " L " + x1 + " " + (cy - k) + " L " + (x1 + t - o) + " " + cy + " L " + x1 + " " + (cy + k)
        d += " L " + x1 + " " + (y1 - c) + arc + (x1 - c) + " " + y1
        if (tailAt === "down") d += " L " + (cx + k) + " " + y1 + " L " + cx + " " + (y1 + t - o) + " L " + (cx - k) + " " + y1
        d += " L " + (x0 + c) + " " + y1 + arc + x0 + " " + (y1 - c)
        if (tailAt === "left") d += " L " + x0 + " " + (cy + k) + " L " + (x0 - t + o) + " " + cy + " L " + x0 + " " + (cy - k)
        return d + " L " + x0 + " " + (y0 + c) + arc + (x0 + c) + " " + y0 + " Z"
    }
    function block(l) {
        const f = l.text.split("|").map(x => x.trim()), v = l.key !== "" ? cfg?.[l.key] : undefined
        let now = ""
        if (v !== undefined && v !== null) {
            if (Array.isArray(v)) { const t = JSON.stringify(v); now = "\nnow: " + (t.length > 300 ? t.slice(0, 300) + "…" : t) }
            else if (typeof v === "object") now = "\nnames inside it now: " + Object.keys(v).join("; ")
            else now = "\nnow: " + JSON.stringify(v)
        }
        return "[" + f[0] + "]\nwhere: " + (f[1] ?? "") + "\ndoes: " + (f[2] ?? "") + "\nvalues: " + (f[3] ?? "") + now
    }
    function keysOf(code) {
        const out = [], add = k => { if (cfg?.[k] !== undefined && !out.includes(k)) out.push(k) }
        let base = ""
        for (const line of String(code ?? "").split("\n")) {
            const f = line.match(/^FILE .*\/([^\/]+)\.[a-z]+ lines/)
            if (f) { base = f[1].replace(/ /g, ""); continue }
            let m
            const full = /[a-z]+_[A-Z][A-Za-z0-9]*/g
            while ((m = full.exec(line)) !== null) add(m[0])
            const brief = /\b(?:s|setting|v)\("([A-Z][A-Za-z0-9]*)"\)/g
            while ((m = brief.exec(line)) !== null) {
                add("widget_" + base + m[1])
                add(base.toLowerCase() + "_" + m[1])
                if (base === "Twine" || base === "Cat") add("catbar_" + m[1])
            }
        }
        return out.slice(0, 6)
    }
    function sought(text) {
        if (!seeking) return
        seeking = false
        seekGuard.stop()
        if (!turn) return
        turn.code = String(text ?? "").trim()
        if (ready) send()
    }
    function facts(text) {
        const t = String(text ?? "").replace(/\\/g, ""), low = t.toLowerCase(), out = []
        for (const k of given) {
            const l = lines.items.find(x => x.key === k)
            if (!l) continue
            const f = l.text.split("|").map(x => x.trim()), spot = String(f[1] ?? "").split(" (also")[0].trim().toLowerCase()
            let at = /_|^[A-Z]/.test(k) ? t.search(new RegExp("(^|[^A-Za-z0-9_])" + k + "([^A-Za-z0-9_]|$)")) : low.indexOf(k.toLowerCase())
            if (at < 0 && (spot.indexOf(">") > 0 || spot.indexOf("/") > 0)) at = low.indexOf(spot)
            if (at >= 0) out.push({ at: at, key: k, where: f[1] ?? "", values: f[3] ?? "" })
        }
        return out.sort((x, y) => x.at - y.at).slice(0, 4).map(e => ({ key: e.key, where: e.where, values: e.values }))
    }
    function tells(text) {
        return /\b(explain|describe|meaning|purpose)\b|\bwhat (does|do|is|are)\b.*\b(do|does|for|mean|means)\b|\btell me about\b|\bhow does\b.*\bwork/i.test(String(text ?? ""))
    }
    function asks(text) {
        const t = String(text ?? "").toLowerCase()
        if (/\b(how (do|can|to|should|would)|change|make|move|turn|enable|disable|hide|put|switch|want|need|remove|add)\b/.test(t)) return false
        return /^(what|which|where|why|is|are|does|do i|am i|tell me|show me)\b/.test(t.trim()) || /\b(current|currently|right now|value of)\b/.test(t)
    }
    function drawn(kind, not) {
        const list = told[kind] ?? []
        if (!list.length) return ""
        let t = String(list[Math.floor(Math.random() * list.length)])
        if (list.length > 1 && t === not) t = String(list[(list.indexOf(t) + 1) % list.length])
        return t
    }
    function say(kind) {
        if (!s("hyprai_SayModel") || !s("hyprai_Visualization") || !enabled) return
        museShow = kind
        const had = drawn(kind, phrase)
        if (busy || waiting || seeking) { phrase = had; return }
        if (ready) {
            phrase = "…"
            if (!muse(kind)) { if (museProc.running) museWant = kind; else phrase = had }
            return
        }
        phrase = had !== "" ? had : "…"
        if (!s("hyprai_SayLoads") || (kind !== "pet" && kind !== "kiss")) { if (had === "") phrase = ""; return }
        museWant = kind
        if (!probed) { if (!probe.running) probe.running = true }
        else if (hasModel) start()
        else { museWant = ""; if (had === "") phrase = "" }
    }
    function shout(text) {
        const t = String(text ?? "")
        if (t === "" || !s("hyprai_Visualization") || !enabled) return
        museShow = ""
        museWant = ""
        phrase = t
    }
    function hush() {
        museShow = ""
        museWant = ""
        phrase = ""
    }
    function muse(kind) {
        const cue = cues[kind]
        if (!s("hyprai_SayModel") || typeof cue !== "string" || cue === "" || !ready || busy || waiting || seeking || museProc.running) return false
        if (museWant === kind) museWant = ""
        const langs = s("hyprai_SayLanguages"), lang = langs.length ? String(langs[Math.floor(Math.random() * langs.length)]) : "English"
        const have = (told[kind] ?? []).slice(-5)
        museKind = kind
        museFile.setText(JSON.stringify({
            messages: [{ role: "system", content: sayRules }, { role: "user", content: cue + " Answer in " + lang + "." + (have.length ? " Say something new, not one of these: " + have.join(" / ") : "") }],
            stream: false, temperature: 1.1, max_tokens: 80, chat_template_kwargs: { enable_thinking: false }
        }))
        museProc.command = ["curl", "-s", "--max-time", "30", "http://127.0.0.1:" + s("hyprai_Port") + "/v1/chat/completions", "-H", "Content-Type: application/json", "--data-binary", "@" + musePath]
        museProc.running = true
        return true
    }
    function refill() {
        const kinds = Object.keys(cues), thin = kinds.filter(k => (told[k] ?? []).length < 3)
        if (thin.length) muse(thin[Math.floor(Math.random() * thin.length)])
    }
    function learned(kind, raw) {
        let t = String(raw ?? "").replace(/<think>[\s\S]*?<\/think>/g, "").split("\n").map(x => x.trim()).filter(x => x !== "")[0] ?? ""
        t = t.replace(/^["'“”«»*_\-\s]+|["'“”«»*_\s]+$/g, "")
        if (t.length > 60) { const cut = t.slice(0, 60), at = cut.lastIndexOf(" "); t = (at > 20 ? cut.slice(0, at) : cut) + "…" }
        if (t.length < 2 || kind === "") {
            console.warn("Panda Hypr AI: no usable line for '" + kind + "'. The model sent: " + String(raw ?? "").slice(0, 160))
            if (museShow === kind && phrase === "…") phrase = drawn(kind, "")
            return
        }
        const all = Object.assign({}, told)
        all[kind] = (all[kind] ?? []).filter(x => x !== t).concat([t]).slice(-Math.max(1, s("hyprai_SayKeep")))
        told = all
        if (museShow === kind) phrase = t
        try { toldFile.setText(JSON.stringify(all)) } catch (e) { console.warn("Panda Hypr AI: could not save " + toldPath + ": " + e) }
    }
    function pointer(code) {
        let path = "", sure = false
        for (const l of String(code ?? "").split("\n")) {
            const f = l.match(/^FILE (.+) lines \d+-\d+(?: hits (\d+) of (\d+))?( pref)?$/)
            if (f) {
                const hit = Number(f[2] ?? 0), known = Math.max(1, Number(f[3] ?? 1))
                path = f[1]
                sure = !!f[4] ? hit >= 1 : hit >= 2 && hit / known >= 0.5
                continue
            }
            const m = l.match(/^(\d+)> (.*)$/)
            if (m && path !== "" && sure) return "`" + path + "`, " + word("line") + " " + m[1] + ":\n\n`" + m[2].replace(/`/g, "'") + "`"
        }
        return ""
    }
    function fileOf(fence) {
        for (const p of fence) {
            const n = p.replace(/_$/, "").toLowerCase()
            const l = lines.items.find(x => x.key.indexOf("file ") === 0 && x.key.toLowerCase().indexOf("file " + n) === 0)
            if (l) return "`" + l.text.split("|")[1].trim() + "`"
        }
        return ""
    }
    function lost(how) {
        const at = pointer(how.code), whole = at === "" ? fileOf(how.fence) : ""
        if (at !== "") return word("I could not find a setting for that.") + " " + word("This file controls it:") + "\n\n" + at + "\n\n" + word("Open it in a text editor, change that line, save, then reload Dolphin.")
        if (whole !== "") return word("I could not find a setting for that.") + " " + word("This file controls it:") + "\n\n" + whole
        return word("I could not find a setting for that.")
    }
    function nearest(name) {
        const bits = k => { const t = String(k); return t.slice(t.indexOf("_") + 1).replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase().split(/[^a-z0-9]+/).filter(x => x !== "") }
        const want = bits(name)
        if (!want.length) return ""
        let best = "", top = 0
        for (const k of given) {
            const have = bits(k)
            let n = 0
            for (let i = 0; i < want.length; i++) if (have.includes(want[i])) n += i === 0 ? 2 : 1
            const score = n / (Math.max(want.length, have.length) + 1)
            if (score > top) { top = score; best = k }
        }
        return top >= 0.45 ? best : ""
    }
    function compose(text, how) {
        const t = String(text ?? "").replace(/<think>[\s\S]*?<\/think>/g, "")
        const grab = name => { const m = t.match(new RegExp("^[\\s*#>-]*" + name + "\\**\\s*[:：]\\s*(.*)$", "im")); return m ? m[1].trim() : "" }
        const bare = v => String(v).replace(/^[`"'\[*\s]+|[`"'\]*\s.]+$/g, "")
        let key = bare(grab("KEY")), value = bare(grab("VALUE")), tip = grab("NOTE").replace(/^["'*\s]+|["'*\s]+$/g, "")
        if (/^none$/i.test(key)) key = ""
        else if (key !== "" && !given.includes(key)) key = nearest(key)
        if (key === "") {
            const named = facts(t)
            if (named.length) key = named[0].key
            else { const m = t.match(/[A-Za-z]+_[A-Za-z0-9]+/); if (m) key = nearest(m[0]) }
        }
        if (key !== "" && how.fence.length && /_/.test(key) && !how.fence.some(p => key.indexOf(p) === 0)) key = ""
        const l = key !== "" ? lines.items.find(x => x.key === key) : null
        if (!l) return { text: lost(how), cards: [] }
        const f = l.text.split("|").map(x => x.trim()), where = f[1] ?? "", spot = where.split(" (also")[0].trim(), now = cfg?.[key]
        const shown = now !== undefined && now !== null && typeof now !== "object" ? JSON.stringify(now) : ""
        const filed = key.indexOf("file ") === 0, topic = !filed && now === undefined
        if (value === "?" || value.length > 40 || /^(none|n\/a)$/i.test(value) || (shown !== "" && value === shown && !how.reading)) value = ""
        if (tip !== "" && !/[.!?。！？…]$/.test(tip)) tip += "."
        let body
        if (how.telling && !filed) body = "`" + key + "`: " + (f[2] ?? "") + "." + (lang !== "en" && tip !== "" ? "\n\n" + tip : "") + "\n\n" + word("Allowed") + ": " + (f[3] ?? "") + (shown !== "" ? "\n\n" + word("Now") + ": **" + shown + "**" : "") + "\n\n" + word("Place") + ": " + spot
        else if (filed) body = "1. " + word("Open the file %1 in a text editor.").replace("%1", "`" + where + "`") + (tip !== "" ? "\n2. " + tip : "")
        else if (how.reading) body = (shown !== "" ? "`" + key + "` " + word("is now") + " **" + shown + "**. " : "") + tip + "\n\n" + word("Place") + ": " + spot
        else if (topic) body = "1. " + word("Open Snoopy Settings") + ".\n2. " + word("Go to %1").replace("%1", spot) + "." + (tip !== "" ? "\n3. " + tip : "")
        else body = "1. " + word("Open Snoopy Settings") + ".\n2. " + word("Go to %1").replace("%1", spot) + ".\n3. " + (value !== "" ? word("Set %1 to %2").replace("%1", "`" + key + "`").replace("%2", "**" + value + "**") : word("Change %1").replace("%1", "`" + key + "`")) + "." + (tip !== "" ? "\n\n" + tip : "")
        const also = how.doubt && !filed && !how.telling ? pointer(how.code) : ""
        if (also !== "") body += "\n\n" + word("If that is not it, the code is here:") + "\n\n" + also
        return { text: body, cards: [{ key: key, where: where, values: f[3] ?? "" }] }
    }
    function parts(q) {
        const marked = String(q).replace(/\s*[;?!]+\s*|\.\s+|\s+(?:and\s+also|and\s+then|also|then|plus)\s+/gi, "\n")
            .replace(/\s+and\s+(?=(\S+))/gi, (m, w) => doers.includes(String(w).toLowerCase().replace(/[^a-z]/g, "")) ? "\n" : m)
        const out = marked.split("\n").map(x => x.trim()).filter(x => stems(x).length > 0)
        return out.length > 1 ? out.slice(0, Math.max(1, s("hyprai_MaxParts"))) : [String(q).trim()]
    }
    function startGuide() {
        if (trailAt < 0 || trailAt >= trail.length) { Guide.end(); return }
        Guide.begin(trail[trailAt])
        Qt.callLater(() => { if (Guide.key !== "" && Guide.steps.length === 0) nextGuide() })
    }
    function nextGuide() {
        if (trailAt + 1 < trail.length) { trailAt++; startGuide() }
        else Guide.end()
    }
    function guideTo(key) {
        let i = trail.indexOf(key)
        if (i < 0) { trail = trail.concat([key]); i = trail.length - 1 }
        trailAt = i
        startGuide()
    }
    function clear() {
        pending = []
        trail = []
        if (busy) halt()
        Guide.end()
        msgs.clear()
        shot = ""
        seen = ""
        trouble = ""
    }
    function start() {
        if (!hasModel) return
        if (server.running) { again = stopping; return }
        trouble = ""
        log = []
        ready = false
        stopping = false
        retried = false
        layers = Math.max(0, s("hyprai_GpuLayers"))
        server.running = true
    }
    function stop() {
        waiting = false
        again = false
        if (!server.running) return
        stopping = true
        server.running = false
    }
    function gone(code) {
        const loaded = ready, was = stopping
        ready = false
        stopping = false
        museWant = ""
        if (phrase === "…") phrase = ""
        if (was) {
            if (again) { again = false; start() }
            return
        }
        if (!loaded && layers > 0 && !retried && code !== 127) {
            retried = true
            layers = 0
            log = []
            Qt.callLater(() => { server.running = true })
            return
        }
        const said = log.slice().reverse().find(l => /error|fail|unable|cannot|not found|out of memory|invalid|unknown/i.test(l)) ?? log[log.length - 1] ?? ""
        if (code === 127) trouble = "\"" + s("hyprai_Server") + "\" " + word("is not installed. Panda Hypr AI needs llama.cpp to run its model.")
        else if (code === 9 || code === 137) trouble = modelName + " " + word("was stopped because it used more memory than the limit") + " (" + s("hyprai_MemoryLimit") + " GB). " + word("Raise Memory limit in Snoopy Settings or use a smaller model.")
        else trouble = modelName + " " + word(loaded ? "stopped unexpectedly." : "could not be loaded.") + (said ? " " + said : "")
        if (waiting || busy) {
            waiting = false
            busy = false
            pending = []
            turn = null
            note("error", trouble)
        }
    }
    function ask(text) {
        const q = String(text ?? "").trim()
        if (!probed || busy || waiting || seeking || (q === "" && shot === "")) return false
        if (trail.length && guides && shot === "" && q.length <= 48 && /^(?:(?:yes|yeah|yep|yup|ok|okay|sure|please|go|show|show me|can you show me|could you show me|walk me through(?: it)?|walk me there|walk me|guide me|take me there|where is it|да|покажи|давай|веди|好|好的|是|带我去)[\s,.!?]*)+$/i.test(q)) {
            msgs.append({ who: "user", body: q, picture: "", cards: "", head: "" })
            note("note", word("OK, follow me."))
            trailAt = 0
            startGuide()
            cheer()
            return true
        }
        if (!hasModel) { note("error", word("The model file is missing:") + " " + modelPath); return false }
        const question = q !== "" ? q : word("What is this and which setting changes it?")
        if (museProc.running) museProc.running = false
        museWant = ""
        museShow = ""
        const list = parts(question), near = shot !== "" ? focus.slice() : []
        const jobs = list.map((p, i) => ({ text: p, whole: list.length > 1 ? question : "", many: list.length, shot: i === 0 ? shot : "", seen: shot !== "" ? seen : "", near: near, code: "" }))
        msgs.append({ who: "user", body: question, picture: shot !== "" ? "data:image/png;base64," + shot : "", cards: "", head: "" })
        shot = ""
        seen = ""
        trail = []
        trailAt = 0
        Guide.end()
        pending = jobs.slice(1)
        begin(jobs[0])
        say("think")
        return true
    }
    function begin(job) {
        turn = job
        const terms = stems(job.text)
        for (const w of job.near) if (!terms.includes(String(w).toLowerCase())) terms.push(String(w).toLowerCase())
        for (const w of stems(job.text, true).concat(job.near)) for (const p of (scopes[String(w).toLowerCase()] ?? [])) {
            const n = "+" + p.replace(/_$/, "").toLowerCase()
            if (!["+widget", "+catbar", "+groupedpanels"].includes(n) && !terms.includes(n)) terms.push(n)
        }
        if (s("hyprai_Files") && terms.length) {
            seeking = true
            finder.command = ["python3", searcher, dolphin, String(Math.max(1, s("hyprai_FileSnippets"))), luaPath].concat(terms.slice(0, 20))
            finder.running = true
            seekGuard.restart()
        }
        if (!ready) { waiting = true; start() }
        else if (!seeking) send()
    }
    function send() {
        const t = turn
        if (!t) return
        waiting = false
        const limit = t.many > 1 ? Math.min(6, Math.max(1, s("hyprai_Lines"))) : Math.max(1, s("hyprai_Lines")), chosen = []
        for (const k of keysOf(t.code)) {
            const l = lines.items.find(x => x.key === k)
            if (l) chosen.push(l)
        }
        for (const l of pick(t.text + " " + t.seen)) if (chosen.length < limit && !chosen.includes(l)) chosen.push(l)
        const telling = tells(t.text), reading = !telling && asks(t.text)
        if (reading && /\b(current|currently|value|now)\b/i.test(t.text)) chosen.sort((x, y) => (cfg?.[y.key] !== undefined ? 1 : 0) - (cfg?.[x.key] !== undefined ? 1 : 0))
        const asked = stems(t.text, true), fence = []
        for (const w of asked.concat(t.near ?? [])) for (const p of (scopes[String(w).toLowerCase()] ?? [])) if (!fence.includes(p)) fence.push(p)
        const before = chosen.length
        if (fence.length) for (let i = chosen.length - 1; i >= 0; i--) if (/_/.test(chosen[i].key) && chosen[i].key.indexOf("file ") !== 0 && !fence.some(p => chosen[i].key.indexOf(p) === 0)) chosen.splice(i, 1)
        const doubt = asked.some(w => w.length >= 5 && !scopes[w] && !common.includes(w) && !chosen.some(l => l.low.includes(" " + w)))
        const small = t.shot === "" && before === 0
        given = chosen.map(l => l.key)
        if (!small && chosen.length === 0 && t.shot === "") {
            job = { mode: "lost", reading: false, telling: false, code: t.code, fence: fence, doubt: true }
            turn = null
            raw = ""
            spill = ""
            msgs.append({ who: "ai", body: lost(job), picture: "", cards: "", head: t.many > 1 ? t.text : "" })
            cur = msgs.count - 1
            busy = true
            finish()
            return
        }
        const rows = chosen.map(block)
        const filey = /\b(file|files|script|scripts|code|qml|source)\b/i.test(t.text), placed = /\b(move|position|left|right|between|order|before|after|next|side|top|bottom|where|swap)\b/i.test(t.text)
        const mode = small ? "chat" : filey || chosen.length === 0 ? "free" : "pick"
        let user = "Reference blocks:\n\n" + (rows.length ? rows.join("\n\n") : "(no block matched)")
        if (mode === "free" && t.code !== "") user += "\n\nLines from Dolphin's own files (read-only). Each part starts with FILE, the path and the line numbers:\n\n" + t.code
        if (mode === "free" || placed) user += "\n\nCurrent layout:\n" + layout()
        if (t.seen !== "") user += "\n\nThe user selected part of the screen with the snipping tool. The selection contains: " + t.seen + "."
        user += "\n\nQuestion: " + t.text
        if (telling && mode === "pick") user += "\n(The user wants an explanation. In NOTE, say in simple words what the setting does.)"
        if (small) user = t.text
        const lead = mode === "chat" ? [chatty] : mode === "pick" ? [picker] : reading ? [reader].concat(lines.always) : [rules, s("hyprai_SimpleEnglish") ? ste : plain].concat(lines.always)
        const system = lead.concat(s("hyprai_System") !== "" ? [s("hyprai_System")] : []).join("\n")
        const past = [], keep = Math.max(0, s("hyprai_History")) * 2
        for (let i = mode !== "free" ? msgs.count : Math.max(0, msgs.count - 1 - keep); i < msgs.count - 1; i++) {
            const m = msgs.get(i)
            if (m.who === "user" || m.who === "ai") past.push({ role: m.who === "ai" ? "assistant" : "user", content: m.body })
        }
        const content = t.shot !== "" ? [{ type: "text", text: user }, { type: "image_url", image_url: { url: "data:image/png;base64," + t.shot } }] : user
        const body = { messages: [{ role: "system", content: system }].concat(past, [{ role: "user", content: content }]), stream: true, temperature: mode === "pick" ? Math.min(0.1, s("hyprai_Temperature")) : s("hyprai_Temperature"), max_tokens: mode === "pick" ? 140 : Math.max(16, s("hyprai_MaxTokens")), chat_template_kwargs: { enable_thinking: s("hyprai_Thinking") } }
        job = { mode: mode, reading: reading, telling: telling, code: t.code, fence: fence, doubt: doubt }
        turn = null
        raw = ""
        spill = ""
        msgs.append({ who: "ai", body: "", picture: "", cards: "", head: t.many > 1 ? t.text : "" })
        cur = msgs.count - 1
        busy = true
        bodyFile.setText(JSON.stringify(body))
        req.command = ["curl", "-sSN", "http://127.0.0.1:" + s("hyprai_Port") + "/v1/chat/completions", "-H", "Content-Type: application/json", "--data-binary", "@" + bodyPath]
        req.running = true
    }
    function feed(line) {
        if (cur < 0) return
        const t = line.trim()
        if (!t) return
        if (!t.startsWith("data:")) { spill += t + "\n"; return }
        const d = t.slice(5).trim()
        if (d === "[DONE]") return
        let j
        try { j = JSON.parse(d) } catch (e) { spill += t + "\n"; return }
        if (j.error) { spill += (j.error.message ?? JSON.stringify(j.error)) + "\n"; return }
        const piece = j.choices?.[0]?.delta?.content
        if (!piece) return
        raw += piece
        if (job && job.mode === "pick") return
        const m = raw.match(/^\s*<think>([\s\S]*?)(<\/think>([\s\S]*))?$/)
        msgs.setProperty(cur, "body", m ? (m[3] ?? "").trim() : raw)
    }
    function finish() {
        if (cur < 0) return
        const stopped = halted || stopping
        let made = null
        if (job && job.mode === "pick" && !stopped && raw.trim() !== "") {
            made = compose(raw, job)
            msgs.setProperty(cur, "body", made.text)
        }
        const fine = msgs.get(cur).body.trim() !== ""
        if (!fine) {
            msgs.remove(cur)
            if (!stopped) note("error", spill.trim() !== "" ? spill.trim() : word("The model gave no answer."))
        } else {
            cheer()
            if (guides) {
                const found = made ? made.cards : facts(msgs.get(cur).body)
                if (found.length) {
                    msgs.setProperty(cur, "cards", JSON.stringify(found))
                    trail = trail.concat(found.map(f => f.key).filter(k => !trail.includes(k)))
                }
            }
        }
        halted = false
        cur = -1
        busy = false
        if (pending.length && fine && !stopped) {
            const next = pending[0]
            pending = pending.slice(1)
            begin(next)
            return
        }
        pending = []
        if (guides && trail.length && !stopped) {
            trailAt = 0
            if (s("hyprai_GuideAuto")) startGuide()
            else note("note", word("Do you want me to walk you there? Say yes or press Show me."))
        }
        if (!open && s("hyprai_Unload") <= 0) stop()
    }
    function halt() {
        if (!req.running) return
        halted = true
        req.running = false
    }

    function snip() {
        if (!sight || busy || waiting) return
        open = false
        Reveal.all = true
        snipping = true
    }
    function cancelSnip() {
        snipping = false
        shooting = false
        Reveal.all = false
        open = true
    }
    function took(x, y, w, h, sw, sh, ox, oy) {
        seen = describe(x, y, w, h, sw, sh)
        shooting = true
        snipping = false
        shooter.command = ["sh", "-c", "grim -g \"$1\" - | ffmpeg -loglevel error -i - -frames:v 1 -vf \"scale=min($2\\,iw):-2\" -f image2pipe -vcodec png - | base64 -w0", "sh",
            Math.round(ox + x) + "," + Math.round(oy + y) + " " + Math.round(w) + "x" + Math.round(h), String(Math.max(128, Math.round(s("hyprai_ImageSize"))))]
        aim.restart()
    }

    ListModel { id: msgs }

    FileView {
        id: ctxFile
        path: root.enabled ? root.contextPath : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.reference = text()
        onLoadFailed: root.reference = ""
    }
    FileView {
        id: museFile
        path: root.musePath
        blockWrites: true
        printErrors: false
    }
    FileView {
        id: toldFile
        path: root.enabled ? root.toldPath : ""
        blockWrites: true
        printErrors: false
        onLoaded: {
            let j
            try { j = JSON.parse(text()) } catch (e) { return }
            const clean = v => Array.isArray(v) ? v.filter(x => typeof x === "string" && x.length > 1 && x.length <= 48).slice(-Math.max(1, root.s("hyprai_SayKeep"))) : []
            const all = {}
            if (j && typeof j === "object") for (const k in j) all[k] = clean(j[k])
            root.told = all
        }
    }
    FileView {
        id: bodyFile
        path: root.bodyPath
        blockWrites: true
        printErrors: false
    }

    Process {
        id: probe
        command: ["sh", "-c", "[ -f \"$1\" ] && echo model; [ -f \"$2\" ] && echo proj; command -v grim >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1 && echo grim; true", "sh", root.modelPath, root.projPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const got = text.split("\n")
                root.hasModel = got.includes("model")
                root.hasProj = got.includes("proj")
                root.hasGrim = got.includes("grim")
                root.probed = true
                if ((root.open || root.museWant !== "") && root.hasModel) root.start()
                else if (root.museWant !== "") { root.museWant = ""; if (root.phrase === "…") root.phrase = "" }
            }
        }
    }
    Process {
        id: server
        command: ["sh", root.runner, String(Math.max(0, Math.round(root.s("hyprai_MemoryLimit") * 1024))), root.s("hyprai_Server"), "-m", root.modelPath, "--host", "127.0.0.1", "--port", String(root.s("hyprai_Port")),
            "--jinja", "--reasoning-format", "deepseek", "-c", String(Math.max(1024, root.s("hyprai_ContextSize"))), "-np", "1", "-ngl", String(root.layers)]
            .concat(root.s("hyprai_Threads") > 0 ? ["-t", String(root.s("hyprai_Threads"))] : [])
            .concat(root.hasProj ? ["--mmproj", root.projPath, "--no-mmproj-offload"] : [])
        stdout: SplitParser { onRead: data => {} }
        stderr: SplitParser { onRead: data => { const t = data.trim(); if (t) root.log = root.log.slice(-11).concat([t]) } }
        onExited: (exitCode, exitStatus) => { Qt.callLater(() => root.gone(exitCode)) }
    }
    Process {
        id: health
        command: ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "http://127.0.0.1:" + root.s("hyprai_Port") + "/health"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "200" || !server.running || root.ready) return
                root.ready = true
                if (root.waiting && !root.seeking) root.send()
                else if (root.museWant !== "") root.muse(root.museWant)
            }
        }
    }
    Process {
        id: museProc
        stdout: StdioCollector {
            onStreamFinished: {
                let j = null
                try { j = JSON.parse(text) } catch (e) { console.warn("Panda Hypr AI: the line request gave no JSON: " + String(text).slice(0, 160)) }
                const m = j?.choices?.[0]?.message
                root.learned(root.museKind, String(m?.content ?? "").trim() !== "" ? m.content : (m?.reasoning_content ?? ""))
                if (root.museWant !== "" && root.muse(root.museWant)) return
                if (!root.open && root.s("hyprai_Unload") <= 0 && !root.busy && !root.waiting) { root.stop(); return }
                refillLater.restart()
            }
        }
    }
    Timer {
        interval: Math.max(20, root.s("hyprai_ChatterEvery")) * 1000
        repeat: true
        running: root.enabled && root.s("hyprai_Visualization") && root.s("hyprai_Chatter") && root.s("hyprai_SayModel")
        onTriggered: {
            interval = Math.round(Math.max(20, root.s("hyprai_ChatterEvery")) * 1000 * (0.5 + Math.random()))
            if (root.busy || root.waiting || root.seeking || root.snipping || root.shooting || Guide.key !== "" || root.phrase !== "") return
            root.stir()
            root.say("idle")
        }
    }
    Timer { id: refillLater; interval: 1500; onTriggered: root.refill() }
    Process {
        id: finder
        stdout: StdioCollector { onStreamFinished: root.sought(text) }
    }
    Timer { id: seekGuard; interval: 2500; onTriggered: root.sought("") }
    Process {
        id: req
        stdout: SplitParser { onRead: data => root.feed(data) }
        stderr: SplitParser { onRead: data => { if (data.trim()) root.spill += data.trim() + "\n" } }
        onRunningChanged: if (!running) root.finish()
    }
    Process {
        id: shooter
        stdout: StdioCollector {
            onStreamFinished: {
                root.shot = text.trim()
                root.shooting = false
                Reveal.all = false
                root.open = true
                if (root.shot === "") { root.seen = ""; root.note("error", root.word("The screenshot could not be taken. The snipping tool needs grim and ffmpeg.")) }
            }
        }
    }

    Timer { id: aim; interval: 250; onTriggered: shooter.running = true }
    Timer { interval: 8000; running: root.shooting; onTriggered: { aim.stop(); root.cancelSnip() } }
    Timer { id: tourEnd; interval: root.trailAt + 1 < root.trail.length ? 1300 : 2600; onTriggered: root.nextGuide() }
    Connections {
        target: Guide
        function onDoneChanged() {
            if (!Guide.done) { tourEnd.stop(); return }
            root.cheer()
            tourEnd.restart()
        }
    }
    Timer { interval: 400; repeat: true; running: server.running && !root.ready; onTriggered: if (!health.running) health.running = true }
    Timer {
        interval: Math.max(1, root.s("hyprai_LoadTimeout")) * 1000
        running: root.s("hyprai_LoadTimeout") > 0 && server.running && !root.ready
        onTriggered: {
            root.stop()
            root.trouble = root.modelName + " " + root.word("was still loading after") + " " + root.s("hyprai_LoadTimeout") + " " + root.word("seconds, so it was stopped.")
            root.pending = []
            if (root.turn) { root.turn = null; root.note("error", root.trouble) }
        }
    }
    Timer {
        interval: Math.max(1, root.s("hyprai_Unload")) * 60000
        running: root.s("hyprai_Unload") > 0 && !root.open && server.running && !root.busy && !root.waiting
        onTriggered: root.stop()
    }

    component Tap: Item {
        id: tp
        property string code: ""
        property bool usable: true
        property bool lit: false
        property real ink: root.px + 2
        signal clicked()
        width: Math.round(ink * 1.6 + 6)
        height: width
        opacity: usable ? 1 : 0.3
        scale: tpArea.pressed && usable ? 0.8 : 1
        Behavior on scale { NumberAnimation { duration: Motion.span(180); easing.type: Easing.OutBack } }
        Icon {
            anchors.centerIn: parent
            source: Art.has(tp.code) ? tp.code : root.glyph(tp.code)
            family: root.iconFont
            size: tp.ink
            color: tp.lit || (tpArea.containsMouse && tp.usable) ? root.hi : root.mark
            Behavior on color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_HoverTime"))) } }
        }
        MouseArea { id: tpArea; anchors.fill: parent; hoverEnabled: true; onClicked: if (tp.usable) tp.clicked() }
    }

    component Chip: Rectangle {
        id: ch
        property string label: ""
        property bool lit: false
        signal clicked()
        width: chText.implicitWidth + Math.round(root.px * 1.3)
        height: Math.round(root.px * 1.9)
        radius: height / 2
        color: lit ? root.hi : chArea.containsMouse ? root.mine : "transparent"
        border.width: 1
        border.color: lit || chArea.containsMouse ? root.hi : root.bd
        scale: chArea.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Motion.span(160); easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_HoverTime"))) } }
        Text { id: chText; anchors.centerIn: parent; text: ch.label; color: ch.lit ? root.bg : root.tx; font.family: root.font; font.pixelSize: root.px - 2 }
        MouseArea { id: chArea; anchors.fill: parent; hoverEnabled: true; onClicked: ch.clicked() }
    }

    LazyLoader {
        active: root.enabled

        PanelWindow {
            id: win
            readonly property real ink: Math.round(height * root.s("hyprai_IconSize") / 2) * 2
            readonly property real edge: Math.max(0, Math.round(root.s("hyprai_Margin")))
            readonly property real inX: root.bar.pos === "left" ? Math.round(root.bar.shown * root.bar.present * (root.bar.gap + root.bar.thick)) : 0
            readonly property real inY: root.bar.pos === "bottom" ? Math.round(root.bar.shown * root.bar.present * (root.bar.gap + root.bar.thick)) : 0
            readonly property real need: root.side && root.side.out ? root.side.rise + (root.s("hyprai_AvoidLabel") && root.side.talking ? root.side.crown : 0) : 0
            readonly property int pace: Math.max(0, root.s("hyprai_OpenTime"))
            property real lift: 0
            readonly property real floor: height - edge - inY - lift

            onNeedChanged: {
                if (need >= lift) { drop.stop(); lift = need }
                else drop.restart()
            }
            Component.onCompleted: lift = need
            Behavior on lift { NumberAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_MoveTime"))); easing.type: Easing.OutCubic } }

            screen: root.bar.screen
            visible: !root.snipping && !root.shooting
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "dolphin-hyprai"
            WlrLayershell.keyboardFocus: root.open && inside.hovered ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"
            mask: Region { item: badgeArea.pressed || rover.held ? whole : badge; Region { item: zone } }

            Item {
                id: whole
                anchors.fill: parent
                opacity: Reveal.glass

                Timer { id: drop; interval: Math.max(0, root.s("hyprai_DropDelay")); onTriggered: win.lift = win.need }
                Item { id: zone; x: bubble.x; y: bubble.y; width: root.open ? bubble.width : 0; height: root.open ? bubble.height : 0 }

                Item {
                    id: badge
                    width: Math.round(win.ink * (root.s("hyprai_IconBackground") ? 1.7 : 1.4))
                    height: width
                    x: win.edge + win.inX
                    y: win.floor - height

                    Rectangle {
                        anchors.fill: parent
                        visible: root.s("hyprai_IconBackground")
                        radius: width / 2
                        color: root.bg
                        border.width: root.line
                        border.color: badgeArea.containsMouse || root.open || rover.held ? root.hi : root.bd
                        Behavior on border.color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_HoverTime"))) } }
                    }
                    Icon {
                        anchors.centerIn: parent
                        source: root.sign
                        family: root.iconFont
                        size: win.ink
                        color: root.mark
                        opacity: rover.out || rover.walking || rover.held || rover.returning ? 0.16 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.span(200) } }
                    }
                    MouseArea {
                        id: badgeArea
                        property bool moved: false
                        property real pressX: 0
                        property real pressY: 0
                        property real grabX: 0
                        property real grabY: 0
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (!containsMouse || pressed || rover.held || rover.returning) return
                            rover.wake()
                            if (rover.lively && !rover.out && !rover.walking) {
                                if (!ponder.running) wiggle.restart()
                                if (!hop.running && !bounce.running) hop.restart()
                            }
                        }
                        onPressed: m => {
                            const p = mapToItem(null, m.x, m.y)
                            moved = false
                            pressX = p.x
                            pressY = p.y
                            grabX = p.x - rover.x
                            grabY = p.y - rover.y
                        }
                        onPositionChanged: m => {
                            if (!pressed) { rover.pet(m.x / Math.max(1, width) - 0.5); return }
                            if (!root.s("hyprai_Drag") || rover.out || rover.walking) return
                            const p = mapToItem(null, m.x, m.y)
                            if (!moved) {
                                if (Math.abs(p.x - pressX) < 8 && Math.abs(p.y - pressY) < 8) return
                                moved = true
                                rover.lifted()
                            }
                            rover.carry(p.x - grabX, p.y - grabY, p.x)
                        }
                        onReleased: if (rover.held) rover.dropped()
                        onCanceled: if (rover.held) rover.dropped()
                        onClicked: {
                            if (moved) { moved = false; return }
                            rover.wake()
                            root.open = !root.open
                            root.say("kiss")
                            rover.kissed()
                        }
                    }
                }

                Item {
                    id: rover
                    readonly property bool lively: root.s("hyprai_Animations") && Motion.on
                    readonly property bool restless: lively && root.s("hyprai_Idle") && win.visible && !asleep && !held && !returning
                    readonly property var spot: root.touring && !Guide.done && (Guide.monitor === "" || !win.screen || Guide.monitor === win.screen.name) ? Guide.spot : null
                    readonly property bool away: !!spot
                    readonly property real homeX: badge.x + (badge.width - width) / 2
                    readonly property real homeY: badge.y + (badge.height - height) / 2
                    readonly property int trip: Math.max(1, root.s("hyprai_WalkTime"))
                    readonly property string gaze: badgeArea.containsMouse && !out ? (petX < -0.16 ? "Left" : petX > 0.16 ? "Right" : "") : glance
                    readonly property string mood: held ? (swing > 6 ? "Left" : swing < -6 ? "Right" : "Happy") : returning ? "Happy" : asleep || blinking ? "Blink" : merry || petting ? "Happy" : walking ? heading : out ? (toRight ? "Right" : "Left") : root.busy || root.waiting ? "Up" : gaze
                    property bool out: false
                    property bool toRight: true
                    property bool walking: false
                    property bool blinking: false
                    property bool merry: false
                    property bool petting: false
                    property bool asleep: false
                    property string heading: ""
                    property string glance: ""
                    property string lastMark: ""
                    property real petX: 0
                    property real swing: 0
                    property bool held: false
                    property bool returning: false
                    property real lastX: 0
                    property real lastT: 0
                    property real petSince: 0
                    property real petLast: 0
                    property real offX: 0
                    property real offY: 0
                    property real hopY: 0
                    property real tilt: 0
                    property real nudge: 0
                    property real wide: 1
                    property real tall: 1
                    property real puff: 1
                    property real lean: 0
                    property real tip: petting && !out ? petX * 30 : 0
                    property real press: petting && !out ? 0.88 : 1

                    function wake() {
                        if (!asleep) return
                        asleep = false
                        if (lively) { hop.restart(); wiggle.restart() }
                    }
                    function pet(at) {
                        petX = at
                        const now = Date.now()
                        if (now - petLast > 600) petSince = now
                        petLast = now
                        if (!petting && !out && now - petSince >= Math.max(0, root.s("hyprai_PetTime"))) {
                            petting = true
                            root.say("pet")
                        }
                        if (petting) unpet.restart()
                    }
                    function lifted() {
                        wake()
                        petting = false
                        lastX = 0
                        homing.stop()
                        thud.stop()
                        hop.stop()
                        bounce.stop()
                        wiggle.stop()
                        calm.stop()
                        returning = false
                        hopY = 0
                        tilt = 0
                        tall = 1.16
                        wide = 0.9
                        held = true
                        root.hush()
                    }
                    function carry(px, py, mouseX) {
                        offX = Math.max(0, Math.min(win.width - width, px)) - homeX
                        offY = Math.max(0, Math.min(win.height - height, py)) - homeY
                        const now = Date.now(), dt = Math.max(8, now - lastT)
                        if (lastX !== 0) swing = Math.max(-42, Math.min(42, -(mouseX - lastX) / dt * 26))
                        lastX = mouseX
                        lastT = now
                        hang.restart()
                    }
                    function dropped() {
                        held = false
                        swing = 0
                        tall = 1
                        wide = 1
                        returning = true
                        root.shout(root.s("hyprai_CarryText"))
                        homing.restart()
                    }
                    function kissed() {
                        merry = true
                        unmerry.restart()
                        if (lively && !out && !walking) { hop.stop(); spin.restart(); bounce.restart() }
                    }
                    function go() {
                        if (held || returning) return
                        const side = away ? spot.x - width - 10 >= 0 : toRight
                        const tx = away ? Math.max(0, Math.min(win.width - width, side ? spot.x - width - 8 : spot.x + spot.width + 8)) - homeX : 0
                        const ty = away ? Math.max(0, Math.min(win.height - height, spot.y + spot.height / 2 - height / 2)) - homeY : 0
                        const follow = away && out && Guide.mark === lastMark
                        out = away
                        if (away) { toRight = side; lastMark = Guide.mark }
                        if (away && !follow) root.say("guide")
                        if (Math.abs(tx - offX) < 2 && Math.abs(ty - offY) < 2) return
                        walk.stop()
                        glide.stop()
                        if (follow) {
                            glideX.to = tx
                            glideY.to = ty
                            glide.start()
                            return
                        }
                        calm.stop()
                        heading = tx < offX ? "Left" : "Right"
                        walkX.to = tx
                        walkY.to = ty
                        walking = true
                        walk.start()
                        if (lively) { tilt = tx < offX ? -9 : 9; stride.restart() }
                    }
                    onSpotChanged: {
                        if (spot) { homeward.stop(); wake(); go() }
                        else homeward.restart()
                    }
                    Component.onCompleted: if (lively) land.start()

                    z: 10
                    width: pic.implicitWidth
                    height: pic.implicitHeight
                    x: homeX + offX
                    y: homeY + offY
                    scale: held ? 1.28 : out || walking ? 0.85 : badgeArea.pressed ? 0.8 : badgeArea.containsMouse ? 1.12 : 1
                    rotation: tilt + lean + tip + swing
                    transform: [
                        Scale { origin.x: rover.width / 2; origin.y: rover.height; xScale: rover.wide * (2 - rover.puff) * (2 - rover.press); yScale: rover.tall * rover.puff * rover.press },
                        Translate { x: rover.nudge; y: rover.hopY }
                    ]
                    Behavior on scale { NumberAnimation { duration: Motion.span(260); easing.type: Easing.OutBack; easing.overshoot: 3 } }
                    Behavior on tip { NumberAnimation { duration: Motion.span(140); easing.type: Easing.OutCubic } }
                    Behavior on swing { NumberAnimation { duration: Motion.span(rover.held && hang.running ? 120 : 900); easing.type: rover.held && hang.running ? Easing.OutCubic : Easing.OutElastic } }
                    ParallelAnimation {
                        id: homing
                        onStopped: {
                            if (rover.held) return
                            rover.returning = false
                            wheeEnd.restart()
                            if (rover.lively) thud.restart()
                        }
                        NumberAnimation { target: rover; property: "offX"; to: 0; duration: Motion.span(620); easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        NumberAnimation { target: rover; property: "offY"; to: 0; duration: Motion.span(620); easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }
                    Timer { id: hang; interval: 110; onTriggered: rover.swing = 0 }
                    Timer { id: wheeEnd; interval: 900; onTriggered: if (root.phrase === root.s("hyprai_CarryText")) root.hush() }
                    SequentialAnimation {
                        id: thud
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 0.68; duration: Motion.span(90) }
                            NumberAnimation { target: rover; property: "wide"; to: 1.32; duration: Motion.span(90) }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.35; duration: Motion.span(150); easing.type: Easing.OutQuad }
                            NumberAnimation { target: rover; property: "tall"; to: 1.12; duration: Motion.span(150) }
                            NumberAnimation { target: rover; property: "wide"; to: 0.92; duration: Motion.span(150) }
                        }
                        NumberAnimation { target: rover; property: "hopY"; to: 0; duration: Motion.span(150); easing.type: Easing.InQuad }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 1; duration: Motion.span(420); easing.type: Easing.OutElastic }
                            NumberAnimation { target: rover; property: "wide"; to: 1; duration: Motion.span(420); easing.type: Easing.OutElastic }
                        }
                    }
                    Behavior on press { NumberAnimation { duration: Motion.span(180); easing.type: Easing.OutBack } }

                    Icon {
                        id: pic
                        source: Art.has(root.s("hyprai_Icon") + rover.mood) ? root.s("hyprai_Icon") + rover.mood : root.sign
                        family: root.iconFont
                        size: win.ink
                        color: badgeArea.containsMouse || root.open || rover.out || rover.walking ? root.hi : root.mark
                        opacity: rover.asleep ? 0.7 : 1
                        Behavior on color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_HoverTime"))) } }
                        Behavior on opacity { NumberAnimation { duration: Motion.span(400) } }
                    }

                    ParallelAnimation {
                        id: walk
                        onStopped: { rover.walking = false; if (!stride.running) calm.restart() }
                        NumberAnimation { id: walkX; target: rover; property: "offX"; duration: Motion.span(rover.trip); easing.type: Easing.InOutCubic }
                        NumberAnimation { id: walkY; target: rover; property: "offY"; duration: Motion.span(rover.trip); easing.type: Easing.InOutCubic }
                    }
                    ParallelAnimation {
                        id: glide
                        NumberAnimation { id: glideX; target: rover; property: "offX"; duration: Motion.span(150); easing.type: Easing.OutCubic }
                        NumberAnimation { id: glideY; target: rover; property: "offY"; duration: Motion.span(150); easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation {
                        id: land
                        ScriptAction { script: { rover.hopY = -win.ink * 5; rover.tall = 1.25; rover.wide = 0.85 } }
                        PauseAnimation { duration: Motion.span(250) }
                        NumberAnimation { target: rover; property: "hopY"; to: 0; duration: Motion.span(520); easing.type: Easing.InQuad }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 0.7; duration: Motion.span(90) }
                            NumberAnimation { target: rover; property: "wide"; to: 1.3; duration: Motion.span(90) }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 1; duration: Motion.span(420); easing.type: Easing.OutElastic }
                            NumberAnimation { target: rover; property: "wide"; to: 1; duration: Motion.span(420); easing.type: Easing.OutElastic }
                        }
                    }
                    SequentialAnimation {
                        id: stride
                        loops: 3
                        onStopped: { calm.restart(); rover.tall = 1; rover.wide = 1 }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.42; duration: Motion.span(rover.trip / 6); easing.type: Easing.OutQuad }
                            NumberAnimation { target: rover; property: "tall"; to: 1.12; duration: Motion.span(rover.trip / 6) }
                            NumberAnimation { target: rover; property: "wide"; to: 0.92; duration: Motion.span(rover.trip / 6) }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "hopY"; to: 0; duration: Motion.span(rover.trip / 6); easing.type: Easing.InQuad }
                            NumberAnimation { target: rover; property: "tall"; to: 0.86; duration: Motion.span(rover.trip / 6) }
                            NumberAnimation { target: rover; property: "wide"; to: 1.12; duration: Motion.span(rover.trip / 6) }
                        }
                    }
                    SequentialAnimation {
                        id: hop
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 0.82; duration: Motion.span(80) }
                            NumberAnimation { target: rover; property: "wide"; to: 1.14; duration: Motion.span(80) }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.7; duration: Motion.span(win.pace * 0.45); easing.type: Easing.OutQuad }
                            NumberAnimation { target: rover; property: "tall"; to: 1.2; duration: Motion.span(win.pace * 0.3) }
                            NumberAnimation { target: rover; property: "wide"; to: 0.86; duration: Motion.span(win.pace * 0.3) }
                        }
                        NumberAnimation { target: rover; property: "hopY"; to: 0; duration: Motion.span(win.pace * 0.4); easing.type: Easing.InQuad }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 0.76; duration: Motion.span(80) }
                            NumberAnimation { target: rover; property: "wide"; to: 1.22; duration: Motion.span(80) }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 1; duration: Motion.span(300); easing.type: Easing.OutElastic }
                            NumberAnimation { target: rover; property: "wide"; to: 1; duration: Motion.span(300); easing.type: Easing.OutElastic }
                        }
                    }
                    SequentialAnimation {
                        id: bounce
                        loops: 2
                        NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.32; duration: Motion.span(110); easing.type: Easing.OutQuad }
                        NumberAnimation { target: rover; property: "hopY"; to: 0; duration: Motion.span(110); easing.type: Easing.InQuad }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 0.86; duration: Motion.span(50) }
                            NumberAnimation { target: rover; property: "wide"; to: 1.12; duration: Motion.span(50) }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "tall"; to: 1; duration: Motion.span(90); easing.type: Easing.OutBack }
                            NumberAnimation { target: rover; property: "wide"; to: 1; duration: Motion.span(90); easing.type: Easing.OutBack }
                        }
                    }
                    SequentialAnimation {
                        id: nod
                        NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.1; duration: Motion.span(60); easing.type: Easing.OutQuad }
                        NumberAnimation { target: rover; property: "hopY"; to: 0; duration: Motion.span(90); easing.type: Easing.InQuad }
                    }
                    SequentialAnimation {
                        id: wiggle
                        NumberAnimation { target: rover; property: "tilt"; to: -13; duration: Motion.span(90); easing.type: Easing.OutQuad }
                        NumberAnimation { target: rover; property: "tilt"; to: 10; duration: Motion.span(140); easing.type: Easing.InOutQuad }
                        NumberAnimation { target: rover; property: "tilt"; to: -6; duration: Motion.span(120); easing.type: Easing.InOutQuad }
                        NumberAnimation { target: rover; property: "tilt"; to: 0; duration: Motion.span(140); easing.type: Easing.OutBack }
                    }
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: rover; property: "nudge"; to: -6; duration: Motion.span(60) }
                        NumberAnimation { target: rover; property: "nudge"; to: 6; duration: Motion.span(90) }
                        NumberAnimation { target: rover; property: "nudge"; to: -4; duration: Motion.span(80) }
                        NumberAnimation { target: rover; property: "nudge"; to: 0; duration: Motion.span(100); easing.type: Easing.OutBack }
                    }
                    SequentialAnimation {
                        id: spin
                        NumberAnimation { target: rover; property: "tilt"; from: 0; to: 360; duration: Motion.span(620); easing.type: Easing.OutBack }
                        ScriptAction { script: rover.tilt = 0 }
                    }
                    SequentialAnimation {
                        id: ponder
                        loops: Animation.Infinite
                        running: rover.lively && (root.busy || root.waiting) && !rover.walking
                        onRunningChanged: if (!running) calm.restart()
                        NumberAnimation { target: rover; property: "tilt"; to: -9; duration: 420; easing.type: Easing.InOutSine }
                        NumberAnimation { target: rover; property: "tilt"; to: 9; duration: 420; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: ponder.running
                        onRunningChanged: if (!running) rover.hopY = 0
                        NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.12; duration: 210; easing.type: Easing.OutQuad }
                        NumberAnimation { target: rover; property: "hopY"; to: 0; duration: 210; easing.type: Easing.InQuad }
                    }
                    SequentialAnimation {
                        id: point
                        loops: Animation.Infinite
                        running: rover.lively && rover.out && !rover.walking && !glide.running
                        onRunningChanged: if (!running) { rover.nudge = 0; rover.hopY = 0 }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "nudge"; to: rover.toRight ? 9 : -9; duration: 200; easing.type: Easing.OutQuad }
                            NumberAnimation { target: rover; property: "hopY"; to: -win.ink * 0.22; duration: 200; easing.type: Easing.OutQuad }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: rover; property: "nudge"; to: 0; duration: 200; easing.type: Easing.InQuad }
                            NumberAnimation { target: rover; property: "hopY"; to: 0; duration: 200; easing.type: Easing.InQuad }
                        }
                        PauseAnimation { duration: 90 }
                    }
                    SequentialAnimation {
                        id: breath
                        loops: Animation.Infinite
                        running: rover.restless && !rover.walking
                        onRunningChanged: if (!running) rover.puff = 1
                        NumberAnimation { target: rover; property: "puff"; to: 1.06; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { target: rover; property: "puff"; to: 0.98; duration: 700; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: breath.running && !rover.out && !ponder.running && !rover.petting
                        onRunningChanged: if (!running) rover.lean = 0
                        NumberAnimation { target: rover; property: "lean"; to: -4; duration: 1300; easing.type: Easing.InOutSine }
                        NumberAnimation { target: rover; property: "lean"; to: 4; duration: 1300; easing.type: Easing.InOutSine }
                    }
                    NumberAnimation { id: calm; target: rover; property: "tilt"; to: 0; duration: Motion.span(220); easing.type: Easing.OutBack }

                    Timer { id: homeward; interval: 450; onTriggered: rover.go() }
                    Timer { id: unblink; interval: 130; onTriggered: rover.blinking = false }
                    Timer { id: unglance; interval: 800; onTriggered: rover.glance = "" }
                    Timer { id: unmerry; interval: 1600; onTriggered: rover.merry = false }
                    Timer { id: unpet; interval: 700; onTriggered: rover.petting = false }
                    Timer {
                        id: doze
                        interval: Math.max(5, root.s("hyprai_SleepAfter")) * 1000
                        running: rover.restless && root.s("hyprai_SleepAfter") > 0 && !root.open && !rover.out && !root.busy && !root.waiting && !badgeArea.containsMouse
                        onTriggered: rover.asleep = true
                    }
                    Timer {
                        interval: 1500
                        repeat: true
                        running: rover.restless
                        onTriggered: {
                            interval = 1100 + Math.round(Math.random() * 2200)
                            if (hop.running || bounce.running || rover.walking || spin.running || land.running) return
                            rover.blinking = true
                            unblink.restart()
                            if (rover.out || ponder.running || rover.petting) return
                            const r = Math.random()
                            if (r < 0.2) wiggle.restart()
                            else if (r < 0.38) { rover.glance = r < 0.29 ? "Left" : "Right"; unglance.restart() }
                            else if (r < 0.6) hop.restart()
                            else if (r < 0.78) bounce.restart()
                            else if (r < 0.83) { rover.merry = true; unmerry.restart() }
                        }
                    }

                    Connections {
                        target: root
                        function onCheer() {
                            rover.wake()
                            rover.merry = true
                            unmerry.restart()
                            if (rover.lively && !rover.walking) { hop.stop(); bounce.restart() }
                        }
                        function onOops() { rover.wake(); if (rover.lively) shake.restart() }
                        function onTyping() { if (rover.lively && !hop.running && !bounce.running && !rover.walking && !rover.out && !ponder.running) nod.restart() }
                        function onOpenChanged() { rover.wake(); if (rover.lively && !rover.walking && !rover.out) hop.restart() }
                        function onBusyChanged() { if (root.busy) rover.wake() }
                        function onStir() { rover.wake(); if (rover.lively && !rover.out && !rover.walking && !hop.running) bounce.restart() }
                    }
                    Connections {
                        target: Guide
                        function onDoneChanged() { if (Guide.done && rover.lively) spin.restart() }
                    }
                }

                Item {
                    id: speech
                    readonly property real air: Math.round(root.px * 0.3)
                    readonly property real pad: Math.round(root.px * 0.75)
                    readonly property real tail: Math.round(root.px * 0.7)
                    readonly property bool roaming: rover.out || rover.walking || rover.held || rover.returning
                    readonly property real edgeR: roaming ? rover.x + rover.width : Math.max(badge.x + badge.width, rover.x + rover.width)
                    readonly property real edgeL: roaming ? rover.x : Math.min(badge.x, rover.x)
                    readonly property real edgeT: roaming ? rover.y : Math.min(badge.y, rover.y)
                    readonly property real midX: rover.x + rover.width / 2
                    readonly property real midY: rover.y + rover.height / 2
                    readonly property real bodyW: Math.ceil(gauge.contentWidth) + pad * 2
                    readonly property real bodyH: Math.ceil(gauge.contentHeight) + Math.round(pad * 1.2)
                    readonly property bool fitsR: edgeR + air + tail + bodyW <= win.width
                    readonly property bool fitsL: edgeL - air - tail - bodyW >= 0
                    readonly property string place: rover.out && rover.toRight ? (fitsL ? "left" : "above") : fitsR ? "right" : fitsL ? "left" : "above"
                    readonly property bool wanted: root.phrase !== ""
                    property real pop: wanted ? 1 : 0
                    visible: pop > 0.01
                    z: 11
                    width: place === "above" ? bodyW : bodyW + tail
                    height: place === "above" ? bodyH + tail : bodyH
                    x: Math.max(0, Math.min(win.width - width, place === "right" ? edgeR + air : place === "left" ? edgeL - air - width : midX - width / 2))
                    y: Math.max(0, Math.min(win.height - height, place === "above" ? edgeT - air - height : midY - height / 2))
                    opacity: Math.max(0, Math.min(1, pop * 1.5))
                    scale: 0.5 + 0.5 * pop
                    transformOrigin: place === "right" ? Item.Left : place === "left" ? Item.Right : Item.Bottom
                    Behavior on pop { NumberAnimation { duration: Motion.span(speech.wanted ? 260 : 140); easing.type: speech.wanted ? Easing.OutBack : Easing.InCubic } }

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: root.bg
                            strokeColor: root.hi
                            strokeWidth: Math.max(1, root.line)
                            joinStyle: ShapePath.RoundJoin
                            PathSvg {
                                path: root.cloud(speech.width, speech.height, Math.max(2, Math.min(root.s("hyprai_Radius") + 4, (speech.bodyH - speech.tail * 1.1) / 2 - 1)), speech.place === "right" ? "left" : speech.place === "left" ? "right" : "down",
                                    speech.tail, Math.max(1, root.line) / 2, speech.place === "above" ? speech.midX - speech.x : speech.midY - speech.y)
                            }
                        }
                    }
                    Text {
                        id: gauge
                        visible: false
                        width: Math.round(root.px * 19)
                        wrapMode: Text.Wrap
                        text: root.phrase + "_"
                        font.family: root.font
                        font.pixelSize: root.px
                    }
                    Typer {
                        id: teller
                        x: speech.pad + (speech.place === "right" ? speech.tail : 0)
                        y: Math.round(speech.pad * 0.6)
                        width: gauge.width
                        wrapMode: Text.Wrap
                        want: root.phrase
                        wipe: true
                        caret: "_"
                        color: root.tx
                        font.family: root.font
                        font.pixelSize: root.px
                    }
                    Timer {
                        id: sayHold
                        interval: root.phrase === "…" ? 25000 : Math.max(1000, root.s("hyprai_SayTime"))
                        onTriggered: root.hush()
                    }
                    Timer {
                        interval: Math.max(1500, root.s("hyprai_HoverTextTime"))
                        repeat: true
                        running: rover.petting
                        onTriggered: root.say("pet")
                    }
                    Connections {
                        target: root
                        function onPhraseChanged() {
                            if (root.phrase !== "") sayHold.restart()
                            else sayHold.stop()
                        }
                    }
                }

                Item {
                    id: bubble
                    readonly property real pad: Math.round(root.px * 0.9)
                    readonly property real tail: Math.round(root.px * 0.95)
                    readonly property real air: Math.round(root.px * 0.3)
                    readonly property real above: Math.max(0, badge.y - air - win.edge)
                    readonly property real under: Math.max(0, win.height - badge.y - badge.height - air - win.edge)
                    readonly property bool below: above < 260 + tail && under > above
                    readonly property real room: below ? under : above
                    property real pop: root.open ? 1 : 0
                    visible: pop > 0.01
                    width: Math.min(win.width - win.edge * 2, Math.max(280, Math.round(win.width * root.s("hyprai_Width"))))
                    height: Math.min(room, Math.max(260, Math.round(win.height * root.s("hyprai_Height"))) + tail)
                    x: Math.max(0, Math.min(win.width - width, badge.x))
                    y: below ? badge.y + badge.height + air : badge.y - air - height
                    opacity: Math.max(0, Math.min(1, pop * 1.5))
                    scale: 0.6 + 0.4 * pop
                    transformOrigin: below ? Item.TopLeft : Item.BottomLeft
                    Behavior on pop { NumberAnimation { duration: Motion.span(root.open ? win.pace : win.pace * 0.6); easing.type: root.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.4 } }
                    onVisibleChanged: if (visible) entry.forceActiveFocus()

                    HoverHandler { id: inside; onHoveredChanged: if (hovered) entry.forceActiveFocus() }

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        transform: Scale { origin.y: bubble.height / 2; yScale: bubble.below ? -1 : 1 }
                        ShapePath {
                            fillColor: root.bg
                            strokeColor: root.line > 0 ? root.bd : "transparent"
                            strokeWidth: root.line > 0 ? root.line : -1
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: root.balloon(bubble.width, bubble.height - bubble.tail, Math.max(0, root.s("hyprai_Radius")), badge.x + badge.width / 2 - bubble.x, bubble.tail * 1.3, bubble.tail, root.line / 2) }
                        }
                    }

                    Item {
                        id: shell
                        y: bubble.below ? bubble.tail : 0
                        width: parent.width
                        height: parent.height - bubble.tail

                        Item {
                            id: crown
                            x: bubble.pad
                            width: parent.width - bubble.pad * 2
                            height: Math.round(root.px * 3.4)

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - tools.width - 8
                                Text { width: parent.width; elide: Text.ElideRight; text: root.word(root.s("hyprai_Title")); color: root.tx; font.family: root.font; font.pixelSize: root.px + 1; font.bold: true }
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: !root.probed ? "" : !root.hasModel ? root.word("Model not found") : root.trouble !== "" && !server.running ? root.word("Not loaded") : root.ready ? root.modelName : server.running ? root.word("Loading") + " " + root.modelName + "…" : root.modelName
                                    color: !root.hasModel && root.probed ? root.bad : root.tx
                                    opacity: 0.55
                                    font.family: root.font
                                    font.pixelSize: root.px - 3
                                }
                            }
                            Row {
                                id: tools
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                Tap { code: "f1f8"; usable: msgs.count > 0; onClicked: root.clear() }
                                Tap { code: "f00d"; onClicked: root.open = false }
                            }
                        }
                        Rectangle { x: root.line; y: crown.height; width: parent.width - root.line * 2; height: 1; color: root.bd }

                        ListView {
                            id: chat
                            x: bubble.pad
                            y: crown.height + 1 + bubble.pad
                            width: parent.width - bubble.pad * 2
                            height: Math.max(0, foot.y - y - bubble.pad)
                            clip: true
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            spacing: Math.round(root.px * 0.7)
                            model: msgs
                            onCountChanged: Qt.callLater(chat.positionViewAtEnd)
                            onContentHeightChanged: if (root.busy) Qt.callLater(chat.positionViewAtEnd)

                            delegate: Rectangle {
                                id: said
                                required property string who
                                required property string body
                                required property string picture
                                required property string cards
                                required property string head
                                readonly property var facts: cards !== "" ? JSON.parse(cards) : []
                                property real slip: 10
                                width: chat.width
                                height: stack.height + (who === "user" ? root.px : 0)
                                radius: Math.max(0, root.s("hyprai_Radius") - 2)
                                color: who === "user" ? root.mine : "transparent"
                                opacity: 0
                                transform: Translate { y: said.slip }
                                Component.onCompleted: arrive.start()
                                ParallelAnimation {
                                    id: arrive
                                    NumberAnimation { target: said; property: "opacity"; to: 1; duration: Motion.span(220) }
                                    NumberAnimation { target: said; property: "slip"; to: 0; duration: Motion.span(320); easing.type: Easing.OutBack }
                                }

                                Column {
                                    id: stack
                                    x: said.who === "user" ? Math.round(root.px * 0.7) : 0
                                    y: said.who === "user" ? Math.round(root.px * 0.5) : 0
                                    width: parent.width - x * 2
                                    spacing: 6
                                    Image {
                                        visible: said.picture !== ""
                                        source: said.picture
                                        width: Math.min(parent.width, Math.round(root.px * 16))
                                        height: visible ? Math.round(width * implicitHeight / Math.max(1, implicitWidth)) : 0
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    Text {
                                        visible: said.head !== ""
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: said.head
                                        color: root.hi
                                        opacity: 0.85
                                        font.family: root.font
                                        font.pixelSize: root.px - 2
                                        font.bold: true
                                    }
                                    Row {
                                        id: dots
                                        visible: said.who === "ai" && said.body === ""
                                        height: Math.round(root.px * 1.4)
                                        spacing: Math.round(root.px * 0.3)
                                        Repeater {
                                            model: 3
                                            Item {
                                                id: dot
                                                required property int index
                                                width: Math.round(root.px * 0.5)
                                                height: dots.height
                                                Rectangle {
                                                    id: bead
                                                    property real up: 0
                                                    width: parent.width
                                                    height: width
                                                    radius: width / 2
                                                    y: parent.height - height - up
                                                    color: root.hi
                                                    SequentialAnimation {
                                                        running: dots.visible
                                                        loops: Animation.Infinite
                                                        PauseAnimation { duration: dot.index * 130 }
                                                        NumberAnimation { target: bead; property: "up"; to: root.px * 0.6; duration: 230; easing.type: Easing.OutQuad }
                                                        NumberAnimation { target: bead; property: "up"; to: 0; duration: 230; easing.type: Easing.InQuad }
                                                        PauseAnimation { duration: (2 - dot.index) * 130 + 260 }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    TextEdit {
                                        visible: said.body !== ""
                                        width: parent.width
                                        readOnly: true
                                        selectByMouse: true
                                        wrapMode: TextEdit.Wrap
                                        textFormat: said.who === "ai" ? TextEdit.MarkdownText : TextEdit.PlainText
                                        text: said.body
                                        color: said.who === "error" ? root.bad : root.tx
                                        opacity: said.who === "note" ? 0.6 : 1
                                        selectionColor: root.hi
                                        selectedTextColor: root.bg
                                        font.family: root.font
                                        font.pixelSize: root.px
                                    }
                                    Repeater {
                                        model: said.facts
                                        Rectangle {
                                            id: card
                                            required property var modelData
                                            readonly property string name: String(modelData.key ?? "")
                                            readonly property var now: root.cfg?.[name]
                                            readonly property bool guided: Guide.key === name
                                            width: stack.width
                                            height: cardText.height + Math.round(root.px * 0.9)
                                            radius: Math.max(0, root.s("hyprai_Radius") - 2)
                                            color: root.field
                                            border.width: 1
                                            border.color: guided ? root.hi : root.bd
                                            Behavior on border.color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_HoverTime"))) } }
                                            Column {
                                                id: cardText
                                                x: Math.round(root.px * 0.7)
                                                y: Math.round(root.px * 0.45)
                                                width: parent.width - x * 2 - (cardGo.visible ? cardGo.width + 8 : 0)
                                                spacing: 1
                                                Text { width: parent.width; elide: Text.ElideRight; text: card.name; color: root.tx; font.family: root.font; font.pixelSize: root.px - 1; font.bold: true }
                                                Text { visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; text: String(card.modelData.where ?? ""); color: root.tx; opacity: 0.7; font.family: root.font; font.pixelSize: root.px - 2 }
                                                Text { visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; text: String(card.modelData.values ?? ""); color: root.tx; opacity: 0.7; font.family: root.font; font.pixelSize: root.px - 2 }
                                                Text {
                                                    visible: card.now !== undefined && typeof card.now !== "object"
                                                    width: parent.width
                                                    elide: Text.ElideRight
                                                    text: root.word("Now") + ": " + (visible ? JSON.stringify(card.now) : "")
                                                    color: root.hi
                                                    font.family: root.font
                                                    font.pixelSize: root.px - 2
                                                }
                                            }
                                            Chip {
                                                id: cardGo
                                                visible: root.guides
                                                anchors.right: parent.right
                                                anchors.rightMargin: Math.round(root.px * 0.6)
                                                anchors.verticalCenter: parent.verticalCenter
                                                label: root.word(card.guided ? "Stop" : "Show me")
                                                lit: card.guided
                                                onClicked: card.guided ? Guide.end() : root.guideTo(card.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Scroller { view: chat }

                        Column {
                            visible: msgs.count === 0
                            anchors.centerIn: chat
                            width: chat.width
                            spacing: Math.round(root.px * 0.8)
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root.word("Ask me about any setting to change.") + "\n" + root.word("For something specific on screen, use the snipping tool.")
                                color: root.tx
                                opacity: 0.7
                                font.family: root.font
                                font.pixelSize: root.px
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root.probed && !root.hasModel ? root.word("The model file is missing:") + " " + root.modelPath : root.trouble !== "" ? root.trouble : root.probed && !root.sight ? root.word("The snipping tool is off: it needs a vision file next to the model, plus grim and ffmpeg.") : ""
                                color: root.probed && root.hasModel && root.trouble === "" ? root.tx : root.bad
                                opacity: root.probed && root.hasModel && root.trouble === "" ? 0.5 : 1
                                font.family: root.font
                                font.pixelSize: root.px - 2
                            }
                        }

                        Column {
                            id: foot
                            x: bubble.pad
                            y: parent.height - height - bubble.pad
                            width: parent.width - bubble.pad * 2
                            spacing: 6

                            Rectangle {
                                id: tour
                                visible: root.touring
                                width: parent.width
                                height: tourList.height + Math.round(root.px * 1.1)
                                radius: Math.max(0, root.s("hyprai_Radius") - 2)
                                color: root.field
                                border.width: 1
                                border.color: root.hi

                                Column {
                                    id: tourList
                                    x: Math.round(root.px * 0.7)
                                    y: Math.round(root.px * 0.55)
                                    width: parent.width - x * 2
                                    spacing: 3
                                    Item {
                                        width: parent.width
                                        height: tourShut.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - tourShut.width - tourNext.width
                                            elide: Text.ElideRight
                                            text: (root.trail.length > 1 ? (root.trailAt + 1) + "/" + root.trail.length + "  " : "") + (Guide.done ? root.word("Done") : root.word("Guide") + ": " + Guide.key)
                                            color: root.hi
                                            font.family: root.font
                                            font.pixelSize: root.px - 1
                                            font.bold: true
                                        }
                                        Tap { id: tourNext; visible: root.trailAt + 1 < root.trail.length; width: visible ? Math.round(ink * 1.6 + 6) : 0; anchors.right: tourShut.left; ink: root.px - 2; code: "f051"; onClicked: root.nextGuide() }
                                        Tap { id: tourShut; anchors.right: parent.right; ink: root.px - 2; code: "f00d"; onClicked: Guide.end() }
                                    }
                                    Repeater {
                                        model: Guide.steps
                                        Item {
                                            id: stepRow
                                            required property string modelData
                                            required property int index
                                            readonly property bool past: Guide.done || index < Guide.at
                                            readonly property bool here: !Guide.done && index === Guide.at
                                            width: tourList.width
                                            height: stepText.height + 2
                                            Text {
                                                id: stepMark
                                                width: Math.round(root.px * 1.6)
                                                text: stepRow.past ? root.glyph("f00c") : (stepRow.index + 1) + "."
                                                color: stepRow.here ? root.hi : root.tx
                                                opacity: stepRow.past ? 0.5 : 1
                                                font.family: stepRow.past ? root.iconFont : root.font
                                                font.pixelSize: root.px - 1
                                            }
                                            Text {
                                                id: stepText
                                                x: stepMark.width
                                                width: parent.width - x
                                                wrapMode: Text.WordWrap
                                                text: stepRow.modelData
                                                color: stepRow.here ? root.hi : root.tx
                                                opacity: stepRow.past ? 0.5 : stepRow.here ? 1 : 0.75
                                                font.family: root.font
                                                font.pixelSize: root.px - 1
                                                font.bold: stepRow.here
                                                font.underline: stepArea.containsMouse
                                            }
                                            MouseArea {
                                                id: stepArea
                                                anchors.fill: parent
                                                enabled: stepRow.index === 0 && stepRow.here
                                                hoverEnabled: enabled
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Guide.summon()
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                visible: root.shot !== ""
                                spacing: 8
                                Image {
                                    source: root.shot !== "" ? "data:image/png;base64," + root.shot : ""
                                    height: Math.round(root.px * 3.4)
                                    width: Math.min(Math.round(root.px * 10), Math.round(height * implicitWidth / Math.max(1, implicitHeight)))
                                    fillMode: Image.PreserveAspectFit
                                }
                                Tap { code: "f00d"; anchors.verticalCenter: parent.verticalCenter; onClicked: { root.shot = ""; root.seen = "" } }
                            }

                            Rectangle {
                                width: parent.width
                                height: Math.max(Math.round(root.px * 2.8), Math.min(entry.contentHeight, root.px * 8) + Math.round(root.px * 1.2))
                                radius: Math.max(0, root.s("hyprai_Radius") - 2)
                                color: root.field
                                border.width: 1
                                border.color: entry.activeFocus ? root.hi : "transparent"
                                Behavior on border.color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("hyprai_HoverTime"))) } }

                                Flickable {
                                    id: scroll
                                    x: Math.round(root.px * 0.8)
                                    y: Math.round(root.px * 0.6)
                                    width: parent.width - x - buttons.width - 6
                                    height: parent.height - y * 2
                                    clip: true
                                    interactive: false
                                    contentHeight: entry.contentHeight
                                    contentY: Math.max(0, entry.cursorRectangle.y + entry.cursorRectangle.height - height)
                                    TextEdit {
                                        id: entry
                                        width: scroll.width
                                        wrapMode: TextEdit.Wrap
                                        selectByMouse: true
                                        color: root.tx
                                        selectionColor: root.hi
                                        selectedTextColor: root.bg
                                        font.family: root.font
                                        font.pixelSize: root.px
                                        onTextChanged: if (text !== "") root.typing()
                                        Keys.onPressed: e => {
                                            if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && !(e.modifiers & Qt.ShiftModifier)) {
                                                if (root.ask(text)) text = ""
                                            } else if (e.key === Qt.Key_Escape) {
                                                if (root.busy) root.halt()
                                                else root.open = false
                                            } else return
                                            e.accepted = true
                                        }
                                    }
                                }
                                Text {
                                    visible: entry.text === ""
                                    x: scroll.x
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.word("Ask about a setting")
                                    color: root.tx
                                    opacity: 0.4
                                    font.family: root.font
                                    font.pixelSize: root.px
                                }
                                Row {
                                    id: buttons
                                    anchors.right: parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    Tap { code: root.s("hyprai_SnipIcon"); usable: root.sight && !root.busy && !root.waiting; onClicked: root.snip() }
                                    Tap {
                                        code: root.busy || root.waiting ? "f04d" : root.s("hyprai_SendIcon")
                                        lit: root.busy || root.waiting
                                        onClicked: {
                                            if (root.busy) root.halt()
                                            else if (root.waiting) { root.stop(); root.turn = null; root.pending = []; root.note("note", root.word("Stopped.")) }
                                            else if (root.ask(entry.text)) entry.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.snipping || root.shooting

        PanelWindow {
            id: cut
            property real ax: 0
            property real ay: 0
            property real bx: 0
            property real by: 0
            property bool drawn: false
            readonly property real sx: Math.min(ax, bx)
            readonly property real sy: Math.min(ay, by)
            readonly property real sw: Math.abs(bx - ax)
            readonly property real sh: Math.abs(by - ay)

            screen: root.bar.screen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "dolphin-snip"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            Item {
                anchors.fill: parent
                opacity: root.shooting ? 0 : 1
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) root.cancelSnip()
                    else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) { if (root.panel) root.panel.parade(-1) }
                    else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) { if (root.panel) root.panel.parade(1) }
                    else return
                    e.accepted = true
                }
                Component.onCompleted: forceActiveFocus()

                Rectangle { visible: !cut.drawn; anchors.fill: parent; color: "#000000"; opacity: 0.3 }
                Rectangle { visible: cut.drawn; width: parent.width; height: cut.sy; color: "#000000"; opacity: 0.3 }
                Rectangle { visible: cut.drawn; y: cut.sy + cut.sh; width: parent.width; height: Math.max(0, parent.height - y); color: "#000000"; opacity: 0.3 }
                Rectangle { visible: cut.drawn; y: cut.sy; width: cut.sx; height: cut.sh; color: "#000000"; opacity: 0.3 }
                Rectangle { visible: cut.drawn; x: cut.sx + cut.sw; y: cut.sy; width: Math.max(0, parent.width - x); height: cut.sh; color: "#000000"; opacity: 0.3 }
                Rectangle { visible: cut.drawn; x: cut.sx - border.width; y: cut.sy - border.width; width: cut.sw + border.width * 2; height: cut.sh + border.width * 2; color: "transparent"; border.width: Math.max(1, root.line); border.color: root.hi }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height * 0.12)
                    width: hint.implicitWidth + root.px * 2
                    height: Math.round(root.px * 2.6)
                    radius: Math.max(0, root.s("hyprai_Radius"))
                    color: root.bg
                    border.width: root.line
                    border.color: root.bd
                    visible: !cut.drawn
                    Text { id: hint; anchors.centerIn: parent; text: root.word("Drag over what you want to ask about. Esc cancels.") + (root.panel ? "  " + root.word("Arrow keys switch the catbar panel.") : ""); color: root.tx; font.family: root.font; font.pixelSize: root.px }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.CrossCursor
                    onPressed: m => { cut.ax = m.x; cut.ay = m.y; cut.bx = m.x; cut.by = m.y; cut.drawn = true }
                    onPositionChanged: m => { if (pressed) { cut.bx = Math.max(0, Math.min(width, m.x)); cut.by = Math.max(0, Math.min(height, m.y)) } }
                    onReleased: {
                        if (cut.sw < 8 || cut.sh < 8) { cut.drawn = false; return }
                        root.took(cut.sx, cut.sy, cut.sw, cut.sh, cut.width, cut.height, cut.screen?.x ?? 0, cut.screen?.y ?? 0)
                    }
                }
            }
        }
    }
}
