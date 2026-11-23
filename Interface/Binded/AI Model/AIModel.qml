import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../Backend"

Kit {
    id: root

    base: ({
        ai_Show: true, ai_Title: "AI Model (Local)", ai_Icon: "ee9c", ai_Width: 0, ai_Height: 0, ai_AutoWidth: 0.32, ai_AutoMargin: 20, ai_TextSize: 14,
        ai_Color: "Background", ai_InputColor: "Accent", ai_UserColor: "Accent2", ai_TextColor: "Text", ai_ActiveColor: "Active",
        ai_HoverColor: "Accent2", ai_BorderColor: "Accent2", ai_InactiveColor: "Inactive", ai_ErrorColor: "#e06c75",
        ai_ModelsFolder: "Data/Static/AI Models", ai_Server: "llama-server", ai_Port: 8089, ai_ExtraArgs: [],
        ai_System: "", ai_Thinking: false, ai_Files: true, ai_Root: "~/Dolphin", ai_Memory: 0, ai_ToolRounds: 6, ai_HistoryLimit: 50,
        ai_Context: 8192, ai_Slots: 1, ai_MaxModels: 1, ai_Unload: 10, ai_GpuLayers: 99, ai_Threads: 0, ai_Temperature: 0.7, ai_MaxTokens: -1,
        ai_Safety: true, ai_Reserve: 1, ai_Panic: 0.8, ai_Pressure: 40, ai_HardLimit: true, ai_FitContext: true, ai_GpuFallback: true, ai_Trim: true,
        ai_LoadTimeout: 180, ai_StallTimeout: 300
    })

    readonly property color bg: col(s("ai_Color"))
    readonly property color field: col(s("ai_InputColor"))
    readonly property color mine: col(s("ai_UserColor"))
    readonly property color tx: col(s("ai_TextColor"))
    readonly property color hi: col(s("ai_ActiveColor"))
    readonly property color lo: col(s("ai_InactiveColor"))
    readonly property color hv: col(s("ai_HoverColor"))
    readonly property color bd: col(s("ai_BorderColor"))
    readonly property color bad: col(s("ai_ErrorColor"))
    readonly property real px: Math.max(9, s("ai_TextSize"))

    readonly property string home: String(Quickshell.shellDir).replace(/\/+$/, "")
    readonly property string here: home + "/Interface/Binded/AI Model"
    readonly property string modelsDir: place(s("ai_ModelsFolder"))
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string rootAbs: settings.folder.replace(/^~(?=\/|$)/, Quickshell.env("HOME"))
    readonly property string noThink: "\n\n/no_think"
    readonly property var toolDefs: [
        { type: "function", function: { name: "list_dir", description: "List the files and folders in a folder. Read-only.", parameters: { type: "object", properties: { path: { type: "string", description: "Folder path relative to the allowed root, e.g. '.' or 'Interface'" } }, required: ["path"] } } },
        { type: "function", function: { name: "find_files", description: "Find files whose name contains some text, searching a folder recursively. Read-only.", parameters: { type: "object", properties: { path: { type: "string", description: "Folder to search, relative to the allowed root" }, name: { type: "string", description: "Part of the file name to look for" } }, required: ["path", "name"] } } },
        { type: "function", function: { name: "read_file", description: "Read the contents of a text file. Read-only.", parameters: { type: "object", properties: { path: { type: "string", description: "File path relative to the allowed root" } }, required: ["path"] } } }
    ]

    property bool open: false
    property bool picking: false
    property bool loading: false
    property string note: ""
    property bool noteOk: false
    property string view: "chat"
    property string lastModel: ""
    property string draft: ""
    property string draftFolder: ""
    property string typed: ""
    property string side: "left"
    property int room: 0
    property int epoch: 0
    property bool hopping: false
    property int keepW: 0
    property int keepH: 0
    property int nowW: 0
    property int nowH: 0
    property int nextPort: Math.max(1024, s("ai_Port"))
    property real memAvail: -1
    property var servers: ({})
    property var sessions: []
    property var cs: null
    property var attachments: []
    property var loadQueue: []
    property var procs: []
    readonly property var srv: cs && cs.model ? (servers[cs.model] ?? null) : null
    readonly property bool ready: !!srv && srv.ready
    readonly property bool vision: !!cs && cs.model !== "" && projFor(cs.model) !== ""
    readonly property bool anyBusy: sessions.some(x => x.busy)
    readonly property bool curBusy: !!cs && cs.busy
    readonly property bool anyServerRunning: Object.keys(servers).some(k => servers[k].proc.running)
    readonly property bool anyLoading: Object.keys(servers).some(k => servers[k].proc.running && !servers[k].ready)
    signal pasteText()

    Component.onCompleted: {
        Faults.sweep("ai-")
        Quickshell.execDetached(["pkill", "-f", settings.server.split("/").pop() + " -m " + modelsDir])
        cs = newSession("", "")
    }

    onOpenChanged: {
        if (open) { if (cs) ensureServer(cs.model, false) }
        else {
            picking = false
            if (hopping) return
            keepW = 0
            keepH = 0
            if (settings.unload === 0 && !anyBusy) stopServers()
        }
    }

    function spot() {
        const t = Hyprland.toplevels.values.find(h => h.title === "dolphin-ai" || h.title === "dolphin-ai-right")
        return t?.workspace?.id ?? t?.lastIpcObject?.workspace?.id ?? room
    }
    function show(dir) {
        side = dir
        room = Hyprland.focusedWorkspace?.id ?? 0
        epoch++
        open = true
    }
    function toggle() {
        if (!s("ai_Show") || hop.running) return
        if (!open) return show("left")
        const now = Hyprland.focusedWorkspace?.id ?? 0, at = spot()
        if (at === now) { open = false; return }
        hopping = true
        keepW = nowW
        keepH = nowH
        open = false
        side = at > now ? "right" : "left"
        hop.restart()
    }

    function place(p) {
        const t = String(p ?? "").trim()
        if (t.startsWith("/")) return t.replace(/\/+$/, "")
        if (t === "~" || t.startsWith("~/")) return (Quickshell.env("HOME") + t.slice(1)).replace(/\/+$/, "")
        return (home + "/" + t).replace(/\/+$/, "")
    }
    function link(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/") }
    function nice(f) { return (f ?? "").replace(/\.gguf$/, "") }
    function flash(t, ok) { note = t; noteOk = !!ok; noteTimer.restart() }
    function close() { if (picking) picking = false; else if (view !== "chat") view = "chat"; else open = false }
    function fault(id, title, detail, steps) { Faults.raise("ai-" + id, title, detail, steps) }

    function projFor(m) {
        const b = nice(m)
        for (let i = 0; i < projs.count; i++) if (projs.get(i, "fileName") === b + ".mmproj") return modelsDir + "/" + b + ".mmproj"
        return ""
    }

    function fileSizeGB(list, name) {
        for (let i = 0; i < list.count; i++) if (list.get(i, "fileName") === name) return list.get(i, "fileSize") / 1073741824
        return 0
    }

    function needGB(m, ctx) {
        return fileSizeGB(models, m) * 1.1 + fileSizeGB(projs, nice(m) + ".mmproj") + ctx * settings.slots * 0.00015 + 0.4
    }

    function guard(avail, stall) {
        if (isNaN(avail)) return
        memAvail = avail
        if (!settings.safety) return
        const low = avail < Math.min(settings.panic, settings.reserve * 0.6)
        const choked = settings.pressure > 0 && !isNaN(stall) && stall > settings.pressure
        if (!low && !choked) return
        let hit = false
        for (const x of sessions) if (x.busy) stop(x)
        for (const k in servers) {
            if (!servers[k].proc.running) continue
            hit = true
            servers[k].halt(word("Stopped to protect your system: free memory got too low. Close some apps or use a smaller model."))
        }
        if (!hit) return
        flash(word("Model stopped: memory almost full"))
    }

    function fileIcon(name, kind) {
        if (kind === "image") return ""
        const e = (name.split(".").pop() || "").toLowerCase()
        if (["qml", "js", "ts", "py", "sh", "lua", "java", "c", "cpp", "h", "rs", "go", "json", "xml", "html", "css", "yml", "yaml", "toml", "conf"].includes(e)) return ""
        if (e === "pdf") return ""
        if (["mp4", "mkv", "webm", "mov", "avi", "m4v"].includes(e)) return ""
        if (["zip", "tar", "gz", "xz", "7z", "rar"].includes(e)) return ""
        return ""
    }

    function mentions(text) {
        const out = []
        const re = /(~\/[^\s'"`,;()]+|\/home\/[^\s'"`,;()]+|[\w.\/-]+\.(?:qml|json|sh|lua|py|js|ts|conf|md|txt|java|xml|css|toml|yaml|yml|html|c|cpp|h|rs|go|ini))/gi
        let m
        while ((m = re.exec(text)) && out.length < 4) {
            const p = m[1].replace(/[.:!?]+$/, "")
            if (p && !out.includes(p)) out.push(p)
        }
        return out
    }

    function row(who, m) {
        return { who: who, content: m.content ?? "", api: m.api ?? "", files: m.files ?? "", images: m.images ?? "", cards: m.cards ?? "", thinking: m.thinking ?? "", tools: m.tools ?? "", streaming: m.streaming ?? false, showThink: m.showThink ?? false }
    }

    function ensureServer(m, retry) {
        if (!m) return
        let sv = servers[m]
        if (!sv) {
            sv = serverC.createObject(root, { model: m, port: nextPort })
            nextPort++
            const n = Object.assign({}, servers)
            n[m] = sv
            servers = n
        }
        if (sv.proc.running || sv.checking || (!retry && sv.error)) return
        const live = Object.keys(servers).filter(k => k !== m && servers[k].proc.running)
        if (live.length >= settings.maxModels) for (const k of live) if (!sessions.some(x => x.busy && x.model === k)) servers[k].stop()
        sv.start()
    }

    function stopServers() { for (const k in servers) servers[k].stop() }

    function restartServers() { for (const k in servers) if (servers[k].proc.running) servers[k].start() }

    function clearAll() {
        killer.running = true
        for (const k in servers) servers[k].stopping = true
        for (const x of sessions) if (x.busy) stop(x)
        stopServers()
    }

    function parseProcs(t) {
        procs = t.split("\n").filter(l => l.trim()).map(l => {
            const i = l.indexOf(" ")
            const cmd = l.slice(i + 1)
            const m = cmd.match(/-m\s+(.+?\.gguf)/)
            const p = cmd.match(/--port\s+(\d+)/)
            return { pid: l.slice(0, i), file: m ? m[1].split("/").pop() : "", model: m ? nice(m[1].split("/").pop()) : cmd.split(" ")[0], port: p ? p[1] : "" }
        })
    }

    function newSession(sid, model) {
        const x = sessionC.createObject(root, { sid: sid || (Date.now().toString(36) + Math.floor(Math.random() * 1e4)), model: model ?? "" })
        sessions = sessions.concat([x])
        return x
    }

    function dropSession(x) {
        sessions = sessions.filter(y => y !== x)
        x.destroy()
    }

    function newChat() {
        attachments = []
        view = "chat"
        if (cs && !cs.msgs.count && !cs.busy) return
        cs = newSession("", cs ? cs.model : lastModel)
    }

    function openChat(h) {
        const old = cs
        let x = sessions.find(y => y.sid === h.id)
        if (!x) {
            let mf = ""
            for (let i = 0; i < models.count; i++) if (nice(models.get(i, "fileName")) === h.model) mf = models.get(i, "fileName")
            x = newSession(h.id, mf || (cs ? cs.model : lastModel))
            for (const m of h.messages) x.msgs.append(row(m.who, m))
        }
        cs = x
        view = "chat"
        if (old && old !== x && !old.msgs.count && !old.busy) dropSession(old)
        if (open) ensureServer(x.model, false)
    }

    function deleteChat(id) {
        history.chats = history.chats.filter(h => h.id !== id)
        histFile.writeAdapter()
        const x = sessions.find(y => y.sid === id)
        if (x) {
            if (x.busy) stop(x)
            const wasCur = x === cs
            dropSession(x)
            if (wasCur) { cs = null; cs = newSession("", lastModel) }
        }
    }

    function setModel(m) {
        if (!cs) cs = newSession("", "")
        if (cs.busy) return flash(word("Wait for this chat to finish first"))
        const old = cs.model
        cs.model = m
        if (old && old !== m && !sessions.some(x => x.model === old)) Faults.clear("ai-" + old)
        if (m) { lastModel = m; ensureServer(m, true) }
    }

    function systemPrompt(x) {
        let t = settings.system.trim()
        if (settings.files) t += "\n\nYou have read-only access to the user's files inside " + settings.folder + ". Files the user mentions are read for you automatically and included in their message inside <file> tags, so use that content directly. For anything else, use the list_dir, find_files and read_file tools. Paths are relative to " + settings.folder + ". You cannot create, edit, move or delete anything, and nothing outside " + settings.folder + " is reachable. Never claim you can't access files inside " + settings.folder + "."
        if (settings.memory > 0) {
            const past = history.chats.filter(h => h.id !== x.sid).slice(0, settings.memory)
            if (past.length) {
                t += "\n\nEarlier conversations with the user, for context only:"
                for (const h of past) {
                    t += "\n\n[" + h.title + " — " + Qt.formatDateTime(new Date(h.updated), "MMM d") + "]"
                    for (const m of h.messages.slice(-6)) t += "\n" + (m.who === "user" ? "User: " : "You: ") + (m.content ?? "").slice(0, 300)
                }
            }
        }
        return t.trim()
    }

    function send(text) {
        const x = cs
        text = text.trim()
        if (!x || (!text && !attachments.length) || !ready || x.busy || loading) return false
        let apiText = text
        const imgs = [], names = []
        for (const a of attachments) {
            const b = a.name.replace(/ #\d+$/, "")
            if (!names.includes(b)) names.push(b)
            if (a.kind === "text") apiText += "\n\n<file name=\"" + a.name + "\">\n" + a.data + "\n</file>"
            else imgs.push(a.data)
        }
        const cards = attachments.filter(a => a.kind === "text").map(a => ({ name: a.name, info: a.data.startsWith("[Binary") ? "binary" : a.data.split("\n").length + " lines" }))
        x.msgs.append(row("user", { content: text, api: apiText, files: names.join(", "), images: JSON.stringify(imgs), cards: JSON.stringify(cards) }))
        let msgs = []
        const sys = systemPrompt(x)
        if (sys) msgs.push({ role: "system", content: sys })
        const past = []
        for (let i = 0; i < x.msgs.count - 1; i++) {
            const m = x.msgs.get(i)
            const t = m.who === "user" ? (m.api || m.content) : m.content
            if (t) past.push({ role: m.who, content: t })
        }
        let start = 0
        if (settings.trim && past.length) {
            const room = Math.max(1024, srv.ctx * 0.7) * 3
            let sum = sys.length + apiText.length + imgs.length * 2400
            start = past.length
            for (let i = past.length - 1; i >= 0; i--) {
                sum += past[i].content.length + 16
                if (sum > room) break
                start = i
            }
            if (start < past.length && past[start].role === "assistant") start++
            if (start > 0) flash(word("Older messages were left out to fit the context"), true)
        }
        msgs = msgs.concat(past.slice(start))
        const ask = (apiText || (imgs.length ? "Look at this." : "")) + (settings.thinking ? "" : noThink)
        msgs.push({ role: "user", content: imgs.length ? [{ type: "text", text: ask }].concat(imgs.map(u => ({ type: "image_url", image_url: { url: u } }))) : ask })
        attachments = []
        x.msgs.append(row("assistant", { streaming: true, showThink: true }))
        x.cur = x.msgs.count - 1
        x.turn = msgs
        x.rounds = 0
        x.stopped = false
        x.busy = true
        x.pre = settings.files ? mentions(text) : []
        saveSession(x)
        if (x.pre.length) prefetch(x)
        else request(x)
        return true
    }

    function inject(x, label, out) {
        const add = "\n\n<file path=\"" + label + "\">\n" + out + "\n</file>"
        const put = str => str.endsWith(noThink) ? str.slice(0, -noThink.length) + add + noThink : str + add
        const t = x.turn.slice()
        const last = Object.assign({}, t[t.length - 1])
        if (Array.isArray(last.content)) {
            const parts = last.content.slice()
            parts[0] = { type: "text", text: put(parts[0].text) }
            last.content = parts
        } else last.content = put(last.content)
        t[t.length - 1] = last
        x.turn = t
    }

    function prefetch(x) {
        if (x.stopped) return finalize(x)
        if (!x.pre.length) return request(x)
        x.prePath = x.pre[0]
        x.pre = x.pre.slice(1)
        x.preMode = true
        addTool(x, "  Read " + x.prePath)
        x.tool.command = ["sh", here + "/Tools.sh", rootAbs, "auto", x.prePath, ""]
        x.tool.running = true
    }

    function request(x) {
        const sv = servers[x.model]
        if (!sv || !sv.ready) { x.rawOut = word("The model isn't loaded."); return finalize(x) }
        x.raw = ""
        x.rawOut = ""
        x.base = x.msgs.get(x.cur).content
        x.calls = []
        x.beat = Date.now()
        const body = { messages: x.turn, stream: true, temperature: settings.temperature, chat_template_kwargs: { enable_thinking: settings.thinking } }
        if (settings.maxTokens > 0) body.max_tokens = settings.maxTokens
        if (settings.files) body.tools = toolDefs
        x.body.setText(JSON.stringify(body))
        x.req.command = ["curl", "-sSN", "http://127.0.0.1:" + sv.port + "/v1/chat/completions", "-H", "Content-Type: application/json", "--data-binary", "@" + x.bodyPath]
        x.req.running = true
    }

    function feed(x, line) {
        if (x.cur < 0) return
        const t = line.trim()
        if (!t) return
        x.beat = Date.now()
        if (!t.startsWith("data:")) { x.rawOut += t + "\n"; return }
        const d = t.slice(5).trim()
        if (d === "[DONE]") return
        let j
        try { j = JSON.parse(d) } catch (e) { x.rawOut += t + "\n"; return }
        if (j.error) { x.rawOut += (j.error.message ?? JSON.stringify(j.error)) + "\n"; return }
        const delta = j.choices?.[0]?.delta ?? {}
        if (delta.reasoning_content) x.msgs.setProperty(x.cur, "thinking", x.msgs.get(x.cur).thinking + delta.reasoning_content)
        if (delta.content) {
            x.raw += delta.content
            const m = x.raw.match(/^\s*<think>([\s\S]*?)(<\/think>([\s\S]*))?$/)
            if (m) { x.msgs.setProperty(x.cur, "thinking", m[1].trim()); x.msgs.setProperty(x.cur, "content", x.base + (m[3] ?? "").trim()) }
            else x.msgs.setProperty(x.cur, "content", x.base + x.raw)
        }
        for (const tc of delta.tool_calls ?? []) {
            const i = tc.index ?? 0
            if (!x.calls[i]) x.calls[i] = { id: "", name: "", args: "" }
            if (tc.id) x.calls[i].id = tc.id
            if (tc.function?.name) x.calls[i].name += tc.function.name
            if (tc.function?.arguments) x.calls[i].args += tc.function.arguments
        }
    }

    function finish(x) {
        if (x.cur < 0) return
        const pending = x.calls.filter(c => c && c.name)
        if (!x.stopped && pending.length && x.rounds < settings.rounds) {
            x.rounds++
            const ids = pending.map((c, i) => c.id || ("call" + x.rounds + "_" + i))
            x.turn = x.turn.concat([{ role: "assistant", content: x.raw.replace(/<think>[\s\S]*?<\/think>/, "").trim(), tool_calls: pending.map((c, i) => ({ id: ids[i], type: "function", function: { name: c.name, arguments: c.args || "{}" } })) }])
            x.queue = pending.map((c, i) => ({ id: ids[i], name: c.name, args: c.args }))
            runTool(x)
            return
        }
        finalize(x)
    }

    function addTool(x, t) { x.msgs.setProperty(x.cur, "tools", (x.msgs.get(x.cur).tools ? x.msgs.get(x.cur).tools + "\n" : "") + t) }

    function runTool(x) {
        if (x.stopped) return finalize(x)
        if (!x.queue.length) return request(x)
        const t = x.queue[0]
        let a = {}
        try { a = JSON.parse(t.args || "{}") } catch (e) {}
        const op = t.name === "list_dir" ? "list" : t.name === "read_file" ? "read" : t.name === "find_files" ? "find" : "none"
        const p = String(a.path ?? ".")
        addTool(x, op === "read" ? "  Read " + p : op === "find" ? "  Searched " + p + " for \"" + (a.name ?? "") + "\"" : "  Listed " + p)
        x.tool.command = ["sh", here + "/Tools.sh", rootAbs, op, p, String(a.name ?? "")]
        x.tool.running = true
    }

    function toolDone(x, out) {
        if (x.preMode) {
            x.preMode = false
            inject(x, x.prePath, out || "(no output)")
            return prefetch(x)
        }
        const t = x.queue[0]
        x.queue = x.queue.slice(1)
        if (t) x.turn = x.turn.concat([{ role: "tool", tool_call_id: t.id, content: out || "(no output)" }])
        runTool(x)
    }

    function finalize(x) {
        if (x.cur >= 0) {
            x.msgs.setProperty(x.cur, "streaming", false)
            const m = x.msgs.get(x.cur)
            if (!m.content && !m.thinking) {
                const full = /exceed|context size|too large|too long/i.test(x.rawOut)
                x.msgs.setProperty(x.cur, "content", x.rawOut ? (full ? "**" + word("This chat no longer fits in the model's context.") + "** " + word("Start a new chat, attach less, or raise Context per chat in settings.") + "\n\n" : "") + "**" + word("Server said:") + "**\n\n" + x.rawOut : "*" + word("The request returned nothing.") + "*")
            }
        }
        x.cur = -1
        x.busy = false
        x.stopped = false
        x.queue = []
        x.pre = []
        x.preMode = false
        saveSession(x)
    }

    function stop(x) {
        x.stopped = true
        x.queue = []
        x.pre = []
        if (x.tool.running) x.tool.running = false
        if (x.req.running) x.req.running = false
        else finalize(x)
    }

    function saveSession(x) {
        if (!x.msgs.count) return
        const msgs = []
        for (let i = 0; i < x.msgs.count; i++) {
            const m = x.msgs.get(i)
            msgs.push({ who: m.who, content: m.content, api: m.api, files: m.files, cards: m.cards, thinking: m.thinking, tools: m.tools })
        }
        const first = msgs.find(m => m.who === "user")
        const head = (first?.content || first?.files || "New chat").slice(0, 60)
        const entry = { id: x.sid, title: head, model: nice(x.model), updated: Date.now(), messages: msgs }
        history.chats = [entry].concat(history.chats.filter(h => h.id !== x.sid)).slice(0, Math.max(1, settings.keep))
        histFile.writeAdapter()
    }

    function attach(paths) {
        loadQueue = loadQueue.concat(paths)
        if (!loader.running) loadNext()
    }

    function loadNext() {
        if (!loadQueue.length) { loading = false; return }
        loading = true
        const p = loadQueue[0]
        loader.name = p.split("/").pop()
        loader.command = ["sh", here + "/Attach.sh", p]
        loader.running = true
    }

    function addImages(lines, name) {
        const imgs = lines.filter(l => l.startsWith("IMG ") && l.length > 10)
        if (!imgs.length) return flash(word("Couldn't read") + " " + name)
        if (!vision) return flash(word("Images and videos need a vision model"))
        attachments = attachments.concat(imgs.map((l, i) => ({ kind: "image", name: imgs.length > 1 ? name + " #" + (i + 1) : name, data: "data:image/png;base64," + l.slice(4).trim() })))
    }

    function loaded(out) {
        const lines = out.split("\n")
        const head = lines[0] ?? ""
        if (head.startsWith("TXT")) attachments = attachments.concat([{ kind: "text", name: loader.name, data: lines.slice(1).join("\n") }])
        else if (head.startsWith("BIN")) attachments = attachments.concat([{ kind: "text", name: loader.name, data: "[Binary file: " + head.slice(4) + ". Its contents can't be read as text.]" }])
        else if (head.startsWith("ERR")) flash(word("Can't open") + " " + loader.name)
        else addImages(lines, loader.name)
        loadQueue = loadQueue.slice(1)
        loadNext()
    }

    function pasteClip() {
        if (clip.running) return
        flash(word("Reading clipboard…"), true)
        clip.running = true
    }

    function clipDone(out) {
        if (out.startsWith("TEXT")) { flash(word("Clipboard has no image")); return pasteText() }
        const before = attachments.length
        addImages(out.split("\n"), "screenshot.png")
        if (attachments.length > before) flash(word("Screenshot attached"), true)
    }

    QtObject {
        id: settings
        readonly property string system: root.s("ai_System")
        readonly property string folder: root.s("ai_Root").trim() || "~/Dolphin"
        readonly property string server: root.s("ai_Server").trim() || "llama-server"
        readonly property bool thinking: root.s("ai_Thinking")
        readonly property bool files: root.s("ai_Files")
        readonly property bool safety: root.s("ai_Safety")
        readonly property bool hard: root.s("ai_HardLimit")
        readonly property bool fit: root.s("ai_FitContext")
        readonly property bool fallback: root.s("ai_GpuFallback")
        readonly property bool trim: root.s("ai_Trim")
        readonly property int memory: Math.max(0, root.s("ai_Memory"))
        readonly property int unload: root.s("ai_Unload")
        readonly property int ctx: Math.max(1024, root.s("ai_Context"))
        readonly property int slots: Math.max(1, root.s("ai_Slots"))
        readonly property int maxModels: Math.max(1, root.s("ai_MaxModels"))
        readonly property int layers: Math.max(0, root.s("ai_GpuLayers"))
        readonly property int threads: Math.max(0, root.s("ai_Threads"))
        readonly property int rounds: Math.max(0, root.s("ai_ToolRounds"))
        readonly property int keep: Math.max(1, root.s("ai_HistoryLimit"))
        readonly property int maxTokens: root.s("ai_MaxTokens")
        readonly property int loadTime: Math.max(0, root.s("ai_LoadTimeout"))
        readonly property int stallTime: Math.max(0, root.s("ai_StallTimeout"))
        readonly property real temperature: Math.max(0, root.s("ai_Temperature"))
        readonly property real reserve: Math.max(0, root.s("ai_Reserve"))
        readonly property real panic: Math.max(0, root.s("ai_Panic"))
        readonly property real pressure: Math.max(0, root.s("ai_Pressure"))
        readonly property var extra: root.s("ai_ExtraArgs").map(a => String(a))
    }

    Component {
        id: serverC
        QtObject {
            id: sv
            property string model: ""
            property int port: 8089
            property int ctx: 8192
            property int layers: 99
            property int limit: 0
            property int code: 0
            property bool ready: false
            property bool stopping: false
            property bool checking: false
            property bool retried: false
            property string error: ""
            property string hint: ""
            property var log: []
            readonly property string path: root.modelsDir + "/" + model

            onReadyChanged: if (ready) Faults.clear("ai-" + model)

            function start() {
                stopping = proc.running
                proc.running = false
                ready = false
                retried = false
                error = ""
                hint = ""
                log = []
                layers = settings.layers
                Faults.clear("ai-" + model)
                checking = true
                if (!mem.running) mem.running = true
            }

            function fail(title, text, steps) {
                error = text
                root.fault(model, title, text, steps)
            }

            function refuse(text) { error = text }

            function tips() {
                return "1. Open the AI window and go to settings.\n2. Lower Context per chat, or set Run on to Processor.\n3. If it still fails, run this in a terminal to read the full message:\n" + settings.server + " -m \"" + path + "\" -c 4096"
            }

            function checked(avail, total) {
                checking = false
                const name = root.nice(model)
                const size = root.fileSizeGB(models, model)
                if (size <= 0) return fail("The AI model " + name + " is missing", "The file " + path + " is not there any more.", "1. Put the model file back in " + root.modelsDir + "\n2. Or pick another model in the AI window.")
                let c = settings.ctx
                if (settings.safety && !isNaN(avail)) {
                    const room = avail - settings.reserve
                    if (!isNaN(total) && root.needGB(model, 2048) > total)
                        return refuse(name + " " + root.word("is too big for this computer. It needs about") + " " + root.needGB(model, 2048).toFixed(1) + " GB " + root.word("even with the smallest context, and this computer has") + " " + total.toFixed(1) + " GB.")
                    if (settings.fit) while (c > 2048 && root.needGB(model, c) > room) c = Math.max(2048, Math.floor(c / 2))
                    const need = root.needGB(model, c)
                    if (need > room)
                        return refuse(root.word("Not enough free memory for") + " " + name + ": " + root.word("it needs about") + " " + need.toFixed(1) + " GB " + root.word("plus") + " " + settings.reserve + " GB " + root.word("kept free, and only") + " " + avail.toFixed(1) + " GB " + root.word("is available. Close some apps, lower the context or parallel chats, or pick a smaller model."))
                    limit = settings.hard ? Math.max(512, Math.floor(room * 1024)) : 0
                    if (c < settings.ctx) hint = root.word("Loaded with a smaller context to fit in memory:") + " " + Math.round(c / 1024) + "K"
                } else limit = 0
                ctx = c
                Qt.callLater(() => { sv.proc.running = true })
            }

            function stop() {
                checking = false
                if (!proc.running) return
                stopping = true
                proc.running = false
            }

            function halt(text) {
                error = text
                stop()
            }

            function line() {
                for (let i = log.length - 1; i >= 0; i--) if (/error|fail|unable|cannot|not found|out of memory|invalid/i.test(log[i])) return log[i]
                return log.length ? log[log.length - 1] : ""
            }

            function gone() {
                const loadedOnce = ready
                ready = false
                const was = stopping
                stopping = false
                if (was || error) return
                const name = root.nice(model)
                if (code === 127)
                    return refuse("\"" + settings.server + "\" " + root.word("is not installed. The AI window needs llama.cpp to run models."))
                if (code === 9 || code === 137)
                    return refuse(name + " " + root.word("was stopped because it used more memory than it was allowed") + (limit > 0 ? " (" + (limit / 1024).toFixed(1) + " GB)" : "") + ". " + root.word("Close some apps, lower the context or parallel chats, or pick a smaller model."))
                if (!loadedOnce && layers > 0 && settings.fallback && !retried) {
                    retried = true
                    layers = 0
                    log = []
                    hint = root.word("The graphics card could not load it, so it runs on the processor")
                    Qt.callLater(() => { sv.proc.running = true })
                    return
                }
                const said = line()
                if (loadedOnce) fail(name + " stopped unexpectedly", said || "llama-server closed while the model was loaded.", tips())
                else fail(name + " could not be loaded", said || "llama-server closed before the model finished loading.", tips())
            }

            property Process mem: Process {
                command: ["awk", "/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 } /^SwapFree:/ { s = $2 } END { print (a + s * 0.5) / 1048576, t / 1048576 }", "/proc/meminfo"]
                stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(/\s+/); sv.checked(parseFloat(p[0]), parseFloat(p[1])) } }
            }

            property Process proc: Process {
                command: ["sh", root.here + "/Run.sh", String(sv.limit), settings.server, "-m", sv.path, "--host", "127.0.0.1", "--port", String(sv.port), "--jinja", "--reasoning-format", "deepseek", "-c", String(sv.ctx * settings.slots), "-np", String(settings.slots), "-ngl", String(sv.layers)].concat(settings.threads > 0 ? ["-t", String(settings.threads)] : []).concat(root.projFor(sv.model) ? ["--mmproj", root.projFor(sv.model), "--no-mmproj-offload"] : []).concat(settings.extra)
                stdout: SplitParser { onRead: data => {} }
                stderr: SplitParser { onRead: data => { const t = data.trim(); if (t) sv.log = sv.log.slice(-11).concat([t]) } }
                onExited: (exitCode, exitStatus) => { sv.code = exitCode }
                onRunningChanged: {
                    if (running) { sv.code = 0; return }
                    Qt.callLater(() => sv.gone())
                }
            }

            property Process health: Process {
                command: ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "http://127.0.0.1:" + sv.port + "/health"]
                stdout: StdioCollector { onStreamFinished: if (text.trim() === "200" && sv.proc.running) sv.ready = true }
            }

            property Timer poll: Timer {
                interval: 400
                repeat: true
                running: sv.proc.running && !sv.ready
                onTriggered: if (!sv.health.running) sv.health.running = true
            }

            property Timer patience: Timer {
                interval: Math.max(1, settings.loadTime) * 1000
                running: settings.loadTime > 0 && sv.proc.running && !sv.ready
                onTriggered: {
                    const said = sv.line()
                    sv.refuse(root.nice(sv.model) + " " + root.word("was still loading after") + " " + settings.loadTime + " " + root.word("seconds, so it was stopped. Raise Load timeout in settings if this model needs longer.") + (said ? " " + said : ""))
                    sv.stop()
                }
            }
        }
    }

    Component {
        id: sessionC
        QtObject {
            id: ss
            property string sid: ""
            property string model: ""
            property bool busy: false
            property bool stopped: false
            property bool preMode: false
            property string prePath: ""
            property int cur: -1
            property int rounds: 0
            property real beat: 0
            property string raw: ""
            property string rawOut: ""
            property string base: ""
            property var turn: []
            property var calls: []
            property var queue: []
            property var pre: []
            readonly property string bodyPath: root.runDir + "/dolphin-ai-" + sid + ".json"

            property ListModel msgs: ListModel {}

            property FileView body: FileView {
                path: ss.bodyPath
                blockWrites: true
                printErrors: false
            }

            property Process req: Process {
                stdout: SplitParser { onRead: data => root.feed(ss, data) }
                stderr: SplitParser { onRead: data => { if (data.trim()) ss.rawOut += data.trim() + "\n" } }
                onRunningChanged: if (!running) root.finish(ss)
            }

            property Process tool: Process {
                stdout: StdioCollector { onStreamFinished: root.toolDone(ss, text) }
            }
        }
    }

    FolderListModel {
        id: models
        folder: root.link(root.modelsDir)
        nameFilters: ["*.gguf"]
        showDirs: false
    }

    FolderListModel {
        id: projs
        folder: root.link(root.modelsDir)
        nameFilters: ["*.mmproj"]
        showDirs: false
    }

    FileView {
        id: histFile
        path: root.home + "/Data/Dynamic/ai.json"
        blockLoading: true
        printErrors: false
        JsonAdapter {
            id: history
            property var chats: []
        }
    }

    Timer { id: saveTimer; interval: 800; onTriggered: { root.save("ai_System", root.draft); if (root.draftFolder) root.save("ai_Root", root.draftFolder) } }
    Timer { id: noteTimer; interval: 3500; onTriggered: root.note = "" }
    Timer { id: hop; interval: 80; onTriggered: { root.hopping = false; root.show(root.side) } }

    Timer {
        interval: Math.max(1, settings.unload) * 60000
        running: !root.open && settings.unload > 0 && !root.anyBusy
        onTriggered: root.stopServers()
    }

    Timer {
        interval: root.anyLoading ? 500 : 2000
        repeat: true
        triggeredOnStart: true
        running: root.anyServerRunning || (root.open && root.view === "settings")
        onTriggered: if (!memWatch.running) memWatch.running = true
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.open && root.view === "settings"
        onTriggered: if (!scan.running) scan.running = true
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.anyBusy && settings.stallTime > 0
        onTriggered: {
            const now = Date.now()
            for (const x of root.sessions) {
                if (!x.busy || !x.req.running || now - x.beat < settings.stallTime * 1000) continue
                x.rawOut += root.word("The model sent nothing for") + " " + settings.stallTime + " " + root.word("seconds, so the request was stopped.") + "\n"
                root.stop(x)
            }
        }
    }

    Process {
        id: memWatch
        command: ["sh", "-c", "awk '/^MemAvailable:/ { a = $2 } /^some/ { split($2, p, \"=\"); s = p[2] } END { print a / 1048576, s + 0 }' /proc/meminfo /proc/pressure/memory 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(/\s+/); root.guard(parseFloat(p[0]), parseFloat(p[1])) } }
    }

    Process {
        id: loader
        property string name: ""
        stdout: StdioCollector { onStreamFinished: root.loaded(text) }
    }

    Process {
        id: clip
        command: ["sh", root.here + "/Attach.sh", "--clip"]
        stdout: StdioCollector { onStreamFinished: root.clipDone(text) }
    }

    Process {
        id: scan
        command: ["pgrep", "-a", "-x", "llama-server|llama-cli"]
        stdout: StdioCollector { onStreamFinished: root.parseProcs(text) }
    }

    Process {
        id: killer
        command: ["sh", "-c", "pkill -x llama-server; pkill -x llama-cli; sleep 1; pkill -9 -x llama-server; pkill -9 -x llama-cli; true"]
        onRunningChanged: if (!running) scan.running = true
    }

    GlobalShortcut { appid: "ai"; name: "toggle"; onPressed: root.toggle() }

    IpcHandler {
        target: "ai"
        function toggle(): void { root.toggle() }
    }

    LazyLoader {
        active: root.open && root.s("ai_Show")

        FloatingWindow {
            id: win
            property int mine: -1
            title: root.side === "right" ? "dolphin-ai-right" : "dolphin-ai"
            implicitWidth: Math.max(320, root.keepW > 0 ? root.keepW : root.s("ai_Width") > 0 ? root.s("ai_Width") : Math.round((win.screen?.width ?? 1440) * root.s("ai_AutoWidth")))
            implicitHeight: Math.max(400, root.keepH > 0 ? root.keepH : root.s("ai_Height") > 0 ? root.s("ai_Height") : (win.screen?.height ?? 900) - root.s("ai_AutoMargin") * 2)
            color: root.bg
            Component.onCompleted: mine = root.epoch
            onVisibleChanged: if (!visible && mine === root.epoch && !root.hopping) root.open = false
            onWidthChanged: if (visible && width >= 320) root.nowW = Math.round(width)
            onHeightChanged: if (visible && height >= 400) root.nowH = Math.round(height)

            Connections {
                target: root
                function onPasteText() { input.paste() }
            }

            DropArea {
                id: drop
                anchors.fill: parent
                onDropped: d => { if (d.hasUrls) root.attach(Array.from(d.urls).map(u => decodeURIComponent(String(u).replace(/^file:\/\//, "")))) }
            }

            Rectangle {
                anchors.fill: parent
                z: 100
                color: "transparent"
                border.width: drop.containsDrag ? 2 : 0
                border.color: root.hi
            }

            Item {
                anchors.fill: parent
                anchors.margins: 18
                id: deck
                property int pickAt: -1
                property int histAt: -1
                focus: true
                Component.onCompleted: input.forceActiveFocus()
                Keys.onEscapePressed: root.close()
                Keys.onPressed: e => { if (deck.key(e)) e.accepted = true }

                function scroll(part) {
                    const f = root.view === "history" ? histList : root.view === "settings" ? setFlick : list
                    f.contentY = Math.max(f.originY, Math.min(f.originY + Math.max(0, f.contentHeight - f.height), f.contentY + f.height * part))
                }
                function key(e) {
                    const k = e.key, ctrl = !!(e.modifiers & Qt.ControlModifier)
                    if (root.picking && root.view === "chat") {
                        const n = models.count + 1
                        if (k === Qt.Key_Up) pickAt = (Math.max(0, pickAt) + n - 1) % n
                        else if (k === Qt.Key_Down) pickAt = (pickAt + 1) % n
                        else if (k === Qt.Key_Return || k === Qt.Key_Enter) { root.setModel(pickAt > 0 ? models.get(pickAt - 1, "fileName") : ""); root.picking = false }
                        else return false
                        return true
                    }
                    if (root.view === "history" && !ctrl) {
                        const all = history.chats, at = all[histAt]
                        if (k === Qt.Key_Up) histAt = Math.max(0, histAt - 1)
                        else if (k === Qt.Key_Down) histAt = Math.min(all.length - 1, histAt + 1)
                        else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (at) root.openChat(at) }
                        else if (k === Qt.Key_Delete) { if (at) { root.deleteChat(at.id); histAt = Math.min(histAt, history.chats.length - 1) } }
                        else if (k !== Qt.Key_PageUp && k !== Qt.Key_PageDown) return false
                        if (k === Qt.Key_Up || k === Qt.Key_Down) { histList.positionViewAtIndex(histAt, ListView.Contain); return true }
                        if (k !== Qt.Key_PageUp && k !== Qt.Key_PageDown) return true
                    }
                    if (k === Qt.Key_PageUp || k === Qt.Key_PageDown) { scroll(k === Qt.Key_PageUp ? -0.85 : 0.85); return true }
                    if (!ctrl) return false
                    if (k === Qt.Key_Up || k === Qt.Key_Down) scroll(k === Qt.Key_Up ? -0.2 : 0.2)
                    else if (k === Qt.Key_N) root.newChat()
                    else if (k === Qt.Key_H) root.view = root.view === "history" ? "chat" : "history"
                    else if (k === Qt.Key_Comma) root.view = root.view === "settings" ? "chat" : "settings"
                    else if (k === Qt.Key_M) { root.view = "chat"; root.picking = !root.picking }
                    else return false
                    return true
                }

                Connections {
                    target: root
                    function onPickingChanged() {
                        let at = 0
                        for (let i = 0; i < models.count; i++) if (root.cs && models.get(i, "fileName") === root.cs.model) at = i + 1
                        deck.pickAt = root.picking ? at : -1
                    }
                    function onViewChanged() {
                        deck.histAt = root.view === "history" ? 0 : -1
                        if (root.view === "chat") input.forceActiveFocus()
                        else deck.forceActiveFocus()
                    }
                }

                Item {
                    id: header
                    width: parent.width
                    height: 40

                    Column {
                        width: header.width - hdrRow.width - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Row {
                            spacing: 8
                            Text { text: root.glyph(root.s("ai_Icon")); font.family: root.iconFont; font.pixelSize: root.px + 4; color: root.tx; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: root.word(root.s("ai_Title")); font.family: root.font; font.pixelSize: root.px + 4; font.bold: true; color: root.tx; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: !root.cs || !root.cs.model ? root.word("No model") : !root.srv ? root.nice(root.cs.model) : root.srv.error ? root.word("Not loaded:") + " " + root.nice(root.cs.model) : root.srv.ready ? root.nice(root.cs.model) + (root.vision ? "  ·  " + root.word("vision") : "") + "  ·  " + Math.round(root.srv.ctx / 1024) + "K" + (root.srv.layers > 0 ? "" : "  ·  " + root.word("processor")) : root.srv.checking ? root.word("Checking memory…") : root.srv.proc.running ? root.word("Loading") + " " + root.nice(root.cs.model) + "…" : root.nice(root.cs.model) + "  ·  " + root.word("not loaded")
                            font.family: root.font
                            font.pixelSize: root.px - 3
                            color: root.srv && root.srv.error ? root.bad : root.tx
                            opacity: root.srv && root.srv.error ? 1 : 0.5
                        }
                    }

                    Row {
                        id: hdrRow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: [["", "history"], ["", "new"], ["", "settings"], ["", "close"]]
                            Rectangle {
                                required property var modelData
                                width: 34
                                height: 34
                                radius: 17
                                color: hb.containsMouse || root.view === modelData[1] ? root.hv : "transparent"
                                Text { anchors.centerIn: parent; text: parent.modelData[0]; font.family: root.iconFont; font.pixelSize: root.px + 1; color: root.tx }
                                MouseArea {
                                    id: hb
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        const k = parent.modelData[1]
                                        if (k === "new") root.newChat()
                                        else if (k === "close") root.open = false
                                        else root.view = root.view === k ? "chat" : k
                                    }
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: list
                    visible: root.view === "chat"
                    anchors.top: header.bottom
                    anchors.topMargin: 14
                    anchors.bottom: composer.top
                    anchors.bottomMargin: 14
                    width: parent.width
                    clip: true
                    spacing: 18
                    model: root.cs ? root.cs.msgs : null
                    onCountChanged: positionViewAtEnd()
                    onModelChanged: positionViewAtEnd()
                    onContentHeightChanged: if (root.curBusy) positionViewAtEnd()

                    delegate: Item {
                        id: msg
                        required property int index
                        required property string who
                        required property string content
                        required property string files
                        required property string images
                        required property string cards
                        required property string thinking
                        required property string tools
                        required property bool streaming
                        required property bool showThink
                        width: ListView.view.width
                        height: who === "user" ? bubble.height : reply.height

                        Rectangle {
                            id: bubble
                            readonly property var imgs: msg.images ? JSON.parse(msg.images) : []
                            readonly property var docs: msg.cards ? JSON.parse(msg.cards) : []
                            readonly property bool rich: imgs.length > 0 || docs.length > 0
                            visible: msg.who === "user"
                            anchors.right: parent.right
                            width: rich ? parent.width * 0.85 : Math.min(Math.max(ut.implicitWidth, ft.implicitWidth) + 28, parent.width * 0.85)
                            height: bcol.height + 20
                            radius: 16
                            color: root.mine
                            Column {
                                id: bcol
                                x: 14
                                y: 10
                                width: parent.width - 28
                                spacing: 8
                                Flow {
                                    visible: bubble.rich
                                    width: parent.width
                                    spacing: 6
                                    Repeater {
                                        model: bubble.imgs
                                        ClippingRectangle {
                                            id: thumb
                                            required property var modelData
                                            width: 84
                                            height: 84
                                            radius: 10
                                            color: root.bg
                                            Image { anchors.fill: parent; source: thumb.modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                        }
                                    }
                                    Repeater {
                                        model: bubble.docs
                                        Rectangle {
                                            id: doc
                                            required property var modelData
                                            width: Math.min(220, bcol.width)
                                            height: 44
                                            radius: 10
                                            color: root.bg
                                            Row {
                                                x: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 10
                                                Text { text: root.fileIcon(doc.modelData.name, "text"); font.family: root.iconFont; font.pixelSize: root.px + 4; color: root.hi; anchors.verticalCenter: parent.verticalCenter }
                                                Column {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    Text { width: Math.min(implicitWidth, 160); elide: Text.ElideMiddle; text: doc.modelData.name; font.family: root.font; font.pixelSize: root.px - 2; color: root.tx }
                                                    Text { text: doc.modelData.info; font.family: root.font; font.pixelSize: root.px - 4; color: root.tx; opacity: 0.5 }
                                                }
                                            }
                                        }
                                    }
                                }
                                TextEdit {
                                    id: ut
                                    visible: msg.content !== ""
                                    width: parent.width
                                    text: msg.content
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    font.family: root.font
                                    font.pixelSize: root.px
                                    color: root.tx
                                }
                                Text {
                                    id: ft
                                    visible: msg.files !== "" && !bubble.rich
                                    width: parent.width
                                    text: "  " + msg.files
                                    wrapMode: Text.Wrap
                                    font.family: root.font
                                    font.pixelSize: root.px - 3
                                    color: root.tx
                                    opacity: 0.7
                                }
                            }
                        }

                        Column {
                            id: reply
                            visible: msg.who === "assistant"
                            width: parent.width
                            spacing: 8

                            Item {
                                visible: msg.thinking !== "" || (msg.streaming && !msg.content && !msg.tools)
                                width: parent.width
                                height: 22

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    Text { text: ""; font.family: root.iconFont; font.pixelSize: root.px - 1; color: root.hi; anchors.verticalCenter: parent.verticalCenter }
                                    Text {
                                        text: msg.streaming && !msg.content ? (msg.thinking ? root.word("Thinking…") : root.word("Working…")) : root.word("Thought process")
                                        font.family: root.font
                                        font.pixelSize: root.px - 1
                                        color: root.tx
                                        opacity: 0.6
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        visible: msg.thinking !== ""
                                        text: msg.showThink ? "" : ""
                                        font.family: root.iconFont
                                        font.pixelSize: root.px - 4
                                        color: root.tx
                                        opacity: 0.6
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea { anchors.fill: parent; onClicked: list.model.setProperty(msg.index, "showThink", !msg.showThink) }
                            }

                            Item {
                                visible: msg.showThink && msg.thinking !== ""
                                width: parent.width
                                height: tt.height
                                Rectangle { width: 2; height: parent.height; radius: 1; color: root.bd }
                                TextEdit {
                                    id: tt
                                    x: 14
                                    width: parent.width - 14
                                    text: msg.thinking
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    font.family: root.font
                                    font.pixelSize: root.px - 2
                                    font.italic: true
                                    color: root.tx
                                    opacity: 0.55
                                }
                            }

                            Text {
                                visible: msg.tools !== ""
                                width: parent.width
                                text: msg.tools
                                wrapMode: Text.Wrap
                                lineHeight: 1.3
                                font.family: root.font
                                font.pixelSize: root.px - 2
                                color: root.hi
                                opacity: 0.8
                            }

                            TextEdit {
                                visible: msg.content !== ""
                                width: parent.width
                                text: msg.content
                                textFormat: TextEdit.MarkdownText
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                font.family: root.font
                                font.pixelSize: root.px
                                color: root.tx
                            }
                        }
                    }
                }

                Scroller { view: list; visible: list.visible }

                Column {
                    visible: root.view === "chat" && (!root.cs || root.cs.msgs.count === 0)
                    anchors.centerIn: list
                    width: list.width * 0.85
                    spacing: 10
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.glyph(root.s("ai_Icon")); font.family: root.iconFont; font.pixelSize: root.px + 24; color: root.hi }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: !root.cs || !root.cs.model ? root.word("Choose a model to start") : root.srv && root.srv.error ? root.word("Model not loaded") : root.ready ? root.word("How can I help?") : root.srv && root.srv.checking ? root.word("Checking memory…") : root.srv && root.srv.proc.running ? root.word("Loading model…") : root.word("Click the model below to load it")
                        font.family: root.font
                        font.pixelSize: root.px + 4
                        color: root.tx
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        visible: text !== ""
                        text: root.srv && root.srv.error ? root.srv.error : !root.cs || !root.cs.model ? (models.count ? root.word("Pick one from the model menu below") : root.word("No models yet. Put .gguf files in") + " " + root.s("ai_ModelsFolder")) : root.srv && root.srv.hint ? root.srv.hint : root.word("Mention a file by name, drop files here, or paste a screenshot with Ctrl+V")
                        font.family: root.font
                        font.pixelSize: root.px - 2
                        color: root.srv && root.srv.error ? root.bad : root.tx
                        opacity: root.srv && root.srv.error ? 1 : 0.5
                    }
                }

                ListView {
                    id: histList
                    visible: root.view === "history"
                    anchors.top: header.bottom
                    anchors.topMargin: 14
                    anchors.bottom: parent.bottom
                    width: parent.width
                    clip: true
                    spacing: 6
                    model: history.chats

                    delegate: Rectangle {
                        id: hrow
                        required property var modelData
                        readonly property var live: root.sessions.find(x => x.sid === modelData.id) ?? null
                        width: ListView.view.width
                        height: 56
                        radius: 12
                        required property int index
                        color: hm.containsMouse || deck.histAt === index || (root.cs && modelData.id === root.cs.sid) ? root.hv : "transparent"
                        border.width: deck.histAt === index ? 1 : 0
                        border.color: root.hi

                        Rectangle {
                            visible: !!hrow.live && hrow.live.busy
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: root.hi
                        }

                        Column {
                            x: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 62
                            spacing: 3
                            Text { width: parent.width; text: hrow.modelData.title; elide: Text.ElideRight; font.family: root.font; font.pixelSize: root.px - 1; color: root.tx }
                            Text {
                                width: parent.width
                                text: (hrow.live && hrow.live.busy ? root.word("Generating…") + "  ·  " : "") + Qt.formatDateTime(new Date(hrow.modelData.updated), "MMM d, h:mm ap") + (hrow.modelData.model ? "  ·  " + hrow.modelData.model : "")
                                elide: Text.ElideRight
                                font.family: root.font
                                font.pixelSize: root.px - 3
                                color: root.tx
                                opacity: 0.5
                            }
                        }

                        MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; onClicked: root.openChat(hrow.modelData) }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            height: 30
                            radius: 15
                            visible: hm.containsMouse || dm.containsMouse
                            color: dm.containsMouse ? root.lo : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: root.px - 1; color: root.tx }
                            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: root.deleteChat(hrow.modelData.id) }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !history.chats.length
                        text: root.word("No chats yet")
                        font.family: root.font
                        font.pixelSize: root.px
                        color: root.tx
                        opacity: 0.5
                    }
                }

                Scroller { view: histList; visible: histList.visible }

                Flickable {
                    id: setFlick
                    visible: root.view === "settings"
                    anchors.top: header.bottom
                    anchors.topMargin: 20
                    anchors.bottom: parent.bottom
                    width: parent.width
                    contentHeight: setCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: setCol
                        width: parent.width
                        spacing: 18

                        Rectangle {
                            width: parent.width
                            height: runCol.height + 24
                            radius: 12
                            color: "transparent"
                            border.width: 1
                            border.color: root.bd

                            Column {
                                id: runCol
                                x: 12
                                y: 12
                                width: parent.width - 24
                                spacing: 8

                                Item {
                                    width: parent.width
                                    height: 30
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text { text: root.word("Running models"); font.family: root.font; font.pixelSize: root.px - 1; font.bold: true; color: root.tx }
                                        Text {
                                            text: (killer.running ? root.word("Stopping…") : root.procs.length ? root.procs.length + " " + (root.procs.length === 1 ? root.word("process") : root.word("processes")) + " " + root.word("running") : root.word("Nothing running")) + (root.memAvail >= 0 ? "  ·  " + root.memAvail.toFixed(1) + " GB " + root.word("free") : "")
                                            font.family: root.font
                                            font.pixelSize: root.px - 3
                                            color: root.tx
                                            opacity: 0.5
                                        }
                                    }
                                    Rectangle {
                                        visible: root.procs.length > 0 && !killer.running
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: stopText.implicitWidth + 24
                                        height: 28
                                        radius: 14
                                        color: stopHover.hovered ? root.bad : "transparent"
                                        border.width: 1
                                        border.color: root.bad
                                        Text { id: stopText; anchors.centerIn: parent; text: root.word("Stop all"); font.family: root.font; font.pixelSize: root.px - 2; color: stopHover.hovered ? root.bg : root.bad }
                                        HoverHandler { id: stopHover }
                                        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: root.clearAll() }
                                    }
                                }

                                Repeater {
                                    model: root.procs
                                    Text {
                                        required property var modelData
                                        readonly property int chats: root.sessions.filter(x => x.model === modelData.file && x.msgs.count > 0).length
                                        width: runCol.width
                                        elide: Text.ElideRight
                                        text: "  " + modelData.model + (modelData.port ? "   port " + modelData.port : "") + (chats ? "   " + chats + " " + (chats === 1 ? root.word("chat") : root.word("chats")) : "") + "   PID " + modelData.pid
                                        font.family: root.font
                                        font.pixelSize: root.px - 2
                                        color: root.tx
                                        opacity: 0.8
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8
                            Text { text: root.word("Instructions"); font.family: root.font; font.pixelSize: root.px; font.bold: true; color: root.tx }
                            Text { text: root.word("Sent to the model before every chat"); font.family: root.font; font.pixelSize: root.px - 3; color: root.tx; opacity: 0.5 }
                            Rectangle {
                                id: sysBox
                                width: parent.width
                                height: 180
                                radius: 12
                                color: root.field
                                border.width: 1
                                border.color: root.bd
                                Flickable {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    contentHeight: sysEdit.contentHeight
                                    clip: true
                                    TextEdit {
                                        id: sysEdit
                                        width: parent.width
                                        wrapMode: TextEdit.Wrap
                                        font.family: root.font
                                        font.pixelSize: root.px - 1
                                        color: root.tx
                                        Component.onCompleted: { root.draft = settings.system; text = settings.system }
                                        onTextChanged: if (text !== root.draft) { root.draft = text; saveTimer.restart() }
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: [
                                ["Thinking by default", "ai_Thinking"],
                                ["File access (read-only)", "ai_Files"],
                                ["Memory safety", "ai_Safety"],
                                ["Hard memory limit", "ai_HardLimit"],
                                ["Shrink context to fit memory", "ai_FitContext"],
                                ["Retry on processor if graphics fails", "ai_GpuFallback"],
                                ["Leave out old messages when full", "ai_Trim"]
                            ]
                            Item {
                                id: tog
                                required property var modelData
                                readonly property bool active: root.s(modelData[1])
                                width: parent.width
                                height: 28
                                Text { anchors.verticalCenter: parent.verticalCenter; text: root.word(tog.modelData[0]); font.family: root.font; font.pixelSize: root.px - 1; color: root.tx }
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 42
                                    height: 24
                                    radius: 12
                                    color: tog.active ? root.hi : root.lo
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: tog.active ? parent.width - width - 3 : 3
                                        color: tog.active ? root.bg : root.tx
                                        Behavior on x { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: root.save(tog.modelData[1], !tog.active) }
                                }
                            }
                        }

                        Column {
                            visible: settings.files
                            width: parent.width
                            spacing: 8
                            Text { text: root.word("Allowed folder"); font.family: root.font; font.pixelSize: root.px - 1; color: root.tx }
                            Rectangle {
                                width: parent.width
                                height: 36
                                radius: 10
                                color: root.field
                                border.width: 1
                                border.color: root.bd
                                TextInput {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    font.family: root.font
                                    font.pixelSize: root.px - 1
                                    color: root.tx
                                    Component.onCompleted: { root.draftFolder = settings.folder; text = settings.folder }
                                    onTextChanged: if ((text.trim() || "~/Dolphin") !== root.draftFolder) { root.draftFolder = text.trim() || "~/Dolphin"; saveTimer.restart() }
                                }
                            }
                            Text { text: root.word("The model can only view files inside this folder"); font.family: root.font; font.pixelSize: root.px - 3; color: root.tx; opacity: 0.5 }
                        }

                        Repeater {
                            model: [
                                ["Models at once", "ai_MaxModels", [[1, "1"], [2, "2"]], false],
                                ["Keep free", "ai_Reserve", [[0.5, "0.5 GB"], [1, "1 GB"], [2, "2 GB"], [4, "4 GB"]], false],
                                ["Remember chats", "ai_Memory", [[0, "Off"], [3, "3"], [5, "5"]], false],
                                ["Unload model", "ai_Unload", [[0, "On close"], [10, "10 min"], [30, "30 min"], [-1, "Never"]], false],
                                ["Context per chat", "ai_Context", [[4096, "4K"], [8192, "8K"], [16384, "16K"], [32768, "32K"]], true],
                                ["Parallel chats", "ai_Slots", [[1, "1"], [2, "2"], [3, "3"]], true],
                                ["Run on", "ai_GpuLayers", [[99, "Graphics card"], [0, "Processor"]], true],
                                ["Answer length", "ai_MaxTokens", [[-1, "No limit"], [512, "Short"], [2048, "Long"]], false],
                                ["Style", "ai_Temperature", [[0.2, "Precise"], [0.7, "Balanced"], [1, "Creative"]], false],
                                ["Load timeout", "ai_LoadTimeout", [[60, "1 min"], [180, "3 min"], [600, "10 min"], [0, "Never"]], false],
                                ["Stop if silent", "ai_StallTimeout", [[0, "Off"], [120, "2 min"], [300, "5 min"]], false],
                                ["Text size", "ai_TextSize", [[12, "Small"], [14, "Normal"], [16, "Large"]], false]
                            ]
                            Item {
                                id: opt
                                required property var modelData
                                width: parent.width
                                height: 30
                                Text { anchors.verticalCenter: parent.verticalCenter; text: root.word(opt.modelData[0]); font.family: root.font; font.pixelSize: root.px - 1; color: root.tx }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    Repeater {
                                        model: opt.modelData[2]
                                        Rectangle {
                                            id: chip
                                            required property var modelData
                                            readonly property bool sel: root.s(opt.modelData[1]) === modelData[0]
                                            width: chipText.implicitWidth + 20
                                            height: 26
                                            radius: 13
                                            color: sel ? root.hi : "transparent"
                                            border.width: 1
                                            border.color: root.bd
                                            Text { id: chipText; anchors.centerIn: parent; text: root.word(chip.modelData[1]); font.family: root.font; font.pixelSize: root.px - 2; color: chip.sel ? root.bg : root.tx }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    root.save(opt.modelData[1], chip.modelData[0])
                                                    if (opt.modelData[3] && !root.anyBusy) restart.restart()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Timer { id: restart; interval: 500; onTriggered: if (!root.anyBusy) root.restartServers() }
                    }
                }

                Scroller { view: setFlick; visible: setFlick.visible; pass: [sysBox] }

                Rectangle {
                    id: picker
                    visible: root.picking && root.view === "chat"
                    anchors.bottom: composer.top
                    anchors.bottomMargin: 8
                    width: Math.min(parent.width, 300)
                    height: pickCol.height + 16
                    radius: 14
                    color: root.bg
                    border.width: 1
                    border.color: root.bd
                    z: 10

                    Column {
                        id: pickCol
                        x: 8
                        y: 8
                        width: parent.width - 16
                        Repeater {
                            model: models.count + 1
                            Rectangle {
                                required property int index
                                readonly property string name: index === 0 ? "" : models.get(index - 1, "fileName")
                                width: pickCol.width
                                height: 36
                                radius: 10
                                color: pm.containsMouse || deck.pickAt === index ? root.hv : "transparent"
                                Text {
                                    x: 10
                                    width: parent.width - 80
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.name ? root.nice(parent.name) : root.word("None")
                                    font.family: root.font
                                    font.pixelSize: root.px - 1
                                    color: root.tx
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.cs && root.cs.model === parent.name ? "" : parent.index > 0 ? (models.get(parent.index - 1, "fileSize") / 1e9).toFixed(1) + " GB" : ""
                                    font.family: root.font
                                    font.pixelSize: root.px - 3
                                    color: root.tx
                                    opacity: 0.6
                                }
                                MouseArea {
                                    id: pm
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: { root.setModel(parent.name); root.picking = false }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: root.note !== "" && root.view === "chat"
                    anchors.bottom: composer.top
                    anchors.bottomMargin: 6
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.note
                    font.family: root.font
                    font.pixelSize: root.px - 2
                    color: root.noteOk ? root.hi : root.bad
                }

                Rectangle {
                    id: composer
                    visible: root.view === "chat"
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: inFlick.y + inFlick.height + 52
                    radius: 20
                    color: root.field
                    border.width: 1
                    border.color: root.bd

                    TapHandler { onTapped: input.forceActiveFocus() }

                    Flow {
                        id: chips
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 6
                        visible: root.attachments.length > 0 || root.loading
                        Repeater {
                            model: root.attachments
                            ClippingRectangle {
                                id: att
                                required property var modelData
                                required property int index
                                readonly property bool img: modelData.kind === "image"
                                width: img ? 56 : Math.min(attName.width + 60, chips.width)
                                height: img ? 56 : 40
                                radius: 10
                                color: root.hv
                                Image {
                                    anchors.fill: parent
                                    visible: att.img
                                    source: att.img ? att.modelData.data : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                                Row {
                                    visible: !att.img
                                    x: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    Text { text: root.fileIcon(att.modelData.name, att.modelData.kind); font.family: root.iconFont; font.pixelSize: root.px + 2; color: root.hi; anchors.verticalCenter: parent.verticalCenter }
                                    Text { id: attName; width: Math.min(implicitWidth, chips.width - 70); elide: Text.ElideMiddle; text: att.modelData.name; font.family: root.font; font.pixelSize: root.px - 3; color: root.tx; anchors.verticalCenter: parent.verticalCenter }
                                }
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 3
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#cc000000"
                                    Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: 9; color: "white" }
                                    MouseArea { anchors.fill: parent; onClicked: root.attachments = root.attachments.filter((x, i) => i !== att.index) }
                                }
                            }
                        }
                        Text {
                            visible: root.loading
                            height: 26
                            verticalAlignment: Text.AlignVCenter
                            text: root.word("Attaching…")
                            font.family: root.font
                            font.pixelSize: root.px - 3
                            color: root.tx
                            opacity: 0.5
                        }
                    }

                    Flickable {
                        id: inFlick
                        x: 16
                        y: chips.visible ? chips.y + chips.height + 10 : 14
                        width: parent.width - 32
                        height: Math.max(20, Math.min(input.contentHeight, 140))
                        contentHeight: input.contentHeight
                        interactive: input.contentHeight > height
                        clip: true
                        TextEdit {
                            id: input
                            width: inFlick.width
                            wrapMode: TextEdit.Wrap
                            focus: true
                            font.family: root.font
                            font.pixelSize: root.px
                            color: root.tx
                            Component.onCompleted: { text = root.typed; cursorPosition = text.length }
                            onTextChanged: root.typed = text
                            Keys.onPressed: e => {
                                if (deck.key(e)) {
                                    e.accepted = true
                                } else if (e.key === Qt.Key_Escape) {
                                    e.accepted = true
                                    root.close()
                                } else if (e.key === Qt.Key_V && (e.modifiers & Qt.ControlModifier)) {
                                    e.accepted = true
                                    root.pasteClip()
                                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    if (e.modifiers & Qt.ShiftModifier) return
                                    e.accepted = true
                                    if (root.send(text)) text = ""
                                }
                            }
                        }
                        Text {
                            visible: !input.text
                            text: !root.cs || !root.cs.model ? root.word("Select a model first") : root.srv && root.srv.error ? root.word("Model not loaded") : root.ready ? root.word("Message…") : root.srv && (root.srv.checking || root.srv.proc.running) ? root.word("Loading model…") : root.word("Model not loaded")
                            font.family: root.font
                            font.pixelSize: root.px
                            color: root.tx
                            opacity: 0.4
                        }
                    }

                    Row {
                        x: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        spacing: 6

                        Rectangle {
                            width: Math.min(mText.implicitWidth + 24, composer.width * 0.45)
                            height: 30
                            radius: 15
                            color: mm.containsMouse || root.picking ? root.hv : "transparent"
                            Text {
                                id: mText
                                anchors.centerIn: parent
                                width: Math.min(implicitWidth, parent.width - 24)
                                elide: Text.ElideRight
                                text: (root.cs && root.cs.model ? root.nice(root.cs.model) : root.word("No model")) + "  "
                                font.family: root.font
                                font.pixelSize: root.px - 2
                                color: root.tx
                            }
                            MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; onClicked: root.picking = !root.picking }
                        }

                        Rectangle {
                            width: tText.implicitWidth + 24
                            height: 30
                            radius: 15
                            color: settings.thinking ? root.hi : "transparent"
                            border.width: 1
                            border.color: root.bd
                            Text {
                                id: tText
                                anchors.centerIn: parent
                                text: "  " + root.word("Thinking")
                                font.family: root.font
                                font.pixelSize: root.px - 2
                                color: settings.thinking ? root.bg : root.tx
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.save("ai_Thinking", !settings.thinking) }
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: pc.containsMouse ? root.hv : "transparent"
                            border.width: 1
                            border.color: root.bd
                            Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: root.px - 1; color: root.tx }
                            MouseArea { id: pc; anchors.fill: parent; hoverEnabled: true; onClicked: root.pasteClip() }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        width: 32
                        height: 32
                        radius: 16
                        color: root.curBusy || ((input.text.trim() || root.attachments.length) && root.ready) ? root.hi : root.lo
                        Text {
                            anchors.centerIn: parent
                            text: root.curBusy ? "" : ""
                            font.family: root.iconFont
                            font.pixelSize: root.px - 1
                            color: root.bg
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.curBusy ? root.stop(root.cs) : (root.send(input.text) && (input.text = ""))
                        }
                    }
                }
            }
        }
    }
}
