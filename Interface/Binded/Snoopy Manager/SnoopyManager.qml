import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../Backend"

Kit {
    id: root

    base: ({
        manager_Show: true, manager_Title: "SNOOPY MANAGER", manager_Icon: "f18b4", manager_Inverted: true, manager_Background: true,
        manager_Width: 0.5, manager_Height: 0.65, manager_CoreBars: false, manager_ProcessWindow: true, manager_ProcessWidth: 0.38, manager_ProcessHeight: 0.6,
        manager_TextSize: 13, manager_Interval: 1500, manager_History: 60, manager_Sort: "size", manager_SortDown: true,
        manager_FetchIcon: "f303", manager_FetchLabel: "neofetch", manager_FetchLogo: "neofetch -L", manager_FetchInfo: "neofetch --stdout",
        manager_Color: "Background", manager_TextColor: "Text", manager_IconColor: "Text", manager_ActiveColor: "Active", manager_HoverColor: "Inactive",
        manager_BorderColor: "Accent2", manager_BarColor: "Active", manager_BarStrength: 0.55, manager_LineColor: "Text", manager_DangerColor: "#e06c75"
    })

    readonly property color bg: tone("manager_Color")
    readonly property color tx: tone("manager_TextColor")
    readonly property color mark: tone("manager_IconColor")
    readonly property color hi: tone("manager_ActiveColor")
    readonly property color hv: { const c = tone("manager_HoverColor"); return Qt.colorEqual(c, bg) ? tx : c }
    readonly property color bd: tone("manager_BorderColor")
    readonly property color pen: tone("manager_LineColor")
    readonly property color bad: tone("manager_DangerColor")
    readonly property color bars: Qt.alpha(tone("manager_BarColor"), Math.max(0.05, Math.min(1, s("manager_BarStrength"))))
    readonly property color mesh: Qt.rgba(tx.r, tx.g, tx.b, 0.14)
    readonly property real px: Math.max(9, s("manager_TextSize"))
    readonly property real rowH: Math.round(px * 2.4)
    readonly property real colW: Math.round(px * 8.5)
    readonly property int cap: Math.max(10, s("manager_History"))
    readonly property string home: String(Quickshell.shellDir).replace(/\/+$/, "")
    readonly property bool keep: s("manager_Background")
    readonly property string mode: !(open || hopping) ? "light" : listing && gauge === "net" ? "net" : listing && gauge === "gpu" ? "gpu" : "full"
    readonly property var columns: [gauge === "mem" ? ["mem", "Memory"] : gauge === "disk" ? ["disk", "Disk"] : gauge === "net" ? ["net", "Connections"] : gauge === "gpu" ? ["gpu", "GPU"] : ["cpu", "CPU"],
        gauge === "gpu" ? ["gmem", "GPU memory"] : gauge === "cpu" ? ["mem", "Memory"] : ["cpu", "CPU"], ["start", "Started"]]
    readonly property string sortBy: ["name", "start"].includes(s("manager_Sort")) ? s("manager_Sort") : "size"
    readonly property string sortKey: sortBy === "size" ? columns[0][0] : sortBy
    readonly property string netName: {
        const n = snap?.net?.name ?? ""
        return n.startsWith("wl") ? word("Wi-Fi") : n.startsWith("e") ? word("Ethernet") : n || word("Network")
    }
    readonly property string tag: (gauge === "mem" ? word("Memory") : gauge === "disk" ? word("Disk") : gauge === "net" ? netName : gauge === "gpu" ? word("GPU") : word("CPU")).toUpperCase() + " " + word("PROCESSES")
    readonly property bool sortDown: s("manager_SortDown")

    property bool open: false
    property bool hopping: false
    property bool listing: false
    property bool late: false
    property int room: 0
    property int epoch: 0
    property int keepW: 0
    property int keepH: 0
    property int nowW: 0
    property int nowH: 0
    property int trays: 0
    property bool fetched: false
    property string fetchLogo: ""
    property var fetchInfo: []
    property string gauge: "cpu"
    property string query: ""
    property string pick: ""
    property var opened: ({})
    property string note: ""
    property string slain: ""
    property var snap: null
    property var procs: []
    property var hist: blank()
    readonly property var rows: build()
    readonly property var picked: rows.find(r => r.key === pick) ?? null

    onModeChanged: if (feed.running) feed.write(mode + "\n")
    onGaugeChanged: {
        if (gauge !== "fetch") return
        listing = false
        if (!fetched && !scout.running) scout.running = true
    }
    onOpenChanged: {
        if (open) { late = false; Hyprland.refreshToplevels(); return }
        if (hopping) return
        keepW = 0
        keepH = 0
        listing = false
        query = ""
        pick = ""
        opened = ({})
        note = ""
        fetched = false
        if (gauge === "fetch") gauge = "cpu"
        if (!keep) { snap = null; procs = []; hist = blank() }
    }

    function blank() { return { cpu: [], top: [], mem: [], swap: [], write: [], read: [], rx: [], tx: [], gpu: [], vram: [] } }
    function tone(k) {
        const n = String(s(k))
        if (!s("manager_Inverted") || n.startsWith("#")) return col(n)
        const c = Qt.alpha(col(n), 1)
        return Qt.rgba(1 - c.r, 1 - c.g, 1 - c.b, 1)
    }

    function spot() {
        const t = Hyprland.toplevels.values.find(h => h.title === "dolphin-taskmanager")
        return t?.workspace?.id ?? t?.lastIpcObject?.workspace?.id ?? room
    }
    function show() {
        room = Hyprland.focusedWorkspace?.id ?? 0
        epoch++
        open = true
    }
    function toggle() {
        if (!s("manager_Show") || hop.running) return
        if (!open) return show()
        if (spot() === (Hyprland.focusedWorkspace?.id ?? 0)) { open = false; return }
        hopping = true
        keepW = nowW
        keepH = nowH
        open = false
        hop.restart()
    }
    function back() {
        if (listing) listing = false
        else open = false
    }

    function flash(t) { note = t; quiet.restart() }
    function size(kb) { return kb >= 1048576 ? (kb / 1048576).toFixed(1) + " GB" : Math.round(kb / 1024) + " MB" }
    function bytes(b) { return b >= 1099511627776 ? (b / 1099511627776).toFixed(2) + " TB" : (b / 1073741824).toFixed(1) + " GB" }
    function rate(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : Math.round(b / 1024) + " KB/s" }
    function clock(t) {
        const two = n => (n < 10 ? "0" : "") + n
        return Math.floor(t / 86400) + ":" + two(Math.floor(t % 86400 / 3600)) + ":" + two(Math.floor(t % 3600 / 60)) + ":" + two(t % 60)
    }
    function most(a, floor) { return Math.max(floor, Math.max.apply(null, a.concat([0])) * 1.15) }

    function take(line) {
        let j
        try { j = JSON.parse(line) } catch (e) { return }
        if (!j || !j.mem || !j.disk || !j.net) return
        const add = (a, v) => a.concat([v]).slice(-cap)
        const m = j.mem, h = hist
        hist = {
            cpu: add(h.cpu, j.cpu),
            top: add(h.top, j.cores && j.cores.length ? Math.max.apply(null, j.cores) : j.cpu),
            mem: add(h.mem, m.total > 0 ? (m.total - m.avail) * 100 / m.total : 0),
            swap: add(h.swap, m.swap > 0 ? (m.swap - m.swapFree) * 100 / m.swap : 0),
            write: add(h.write, j.disk.write),
            read: add(h.read, j.disk.read),
            rx: add(h.rx, j.net.rx),
            tx: add(h.tx, j.net.tx),
            gpu: add(h.gpu, j.gpu ? j.gpu.busy : 0),
            vram: add(h.vram, j.gpu && j.gpu.total ? j.gpu.used * 100 / j.gpu.total : 0)
        }
        if (j.list) procs = j.list
        snap = j
    }

    function build() {
        const wins = {}
        for (const t of Hyprland.toplevels.values) {
            const p = t.lastIpcObject?.pid
            if (p > 0) wins[p] = true
        }
        const q = query.trim().toLowerCase(), all = []
        for (const g of procs) {
            if (q && !g[0].toLowerCase().includes(q)) continue
            const net = g[7] ?? 0, gpu = g[8] ?? 0, gmem = g[9] ?? 0
            if ((gauge === "net" && net <= 0) || (gauge === "gpu" && gpu <= 0 && gmem <= 0)) continue
            all.push({ key: "g:" + g[0], child: false, name: g[0], count: g[1], cpu: g[2], mem: g[3], pids: g[4], mine: g[5], disk: g[6] ?? 0, net: net, gpu: gpu, gmem: gmem, start: g[10] ?? 0, kids: g[11] ?? [], app: g[4].some(p => wins[p] === true) })
        }
        const k = sortKey, way = sortDown ? 1 : -1
        const rank = (a, b) => {
            if (k === "name") {
                const x = a.name.toLowerCase(), y = b.name.toLowerCase()
                return (x < y ? -1 : x > y ? 1 : 0) * way
            }
            const v = ((b[k] ?? 0) - (a[k] ?? 0)) * way
            return v !== 0 ? v : b.mem - a.mem
        }
        all.sort(rank)
        const out = []
        for (const g of all) {
            out.push(g)
            if (g.count < 2 || opened[g.name] !== true) continue
            const kids = g.kids.map(m => ({ key: "p:" + m[0], child: true, parent: g.name, name: m[1], pid: m[0], count: 1, cpu: m[2], mem: m[3], disk: m[4], net: m[5], gpu: m[6], gmem: m[7], start: m[8], pids: [m[0]], mine: g.mine, kids: [], app: false }))
            kids.sort(rank)
            for (const c of kids) out.push(c)
        }
        return out
    }

    function order(kind) {
        if (sortBy === kind) return save("manager_SortDown", !sortDown)
        save("manager_Sort", kind)
        save("manager_SortDown", true)
    }

    function tap(r) {
        if (!r.child && r.count > 1) {
            const next = Object.assign({}, opened)
            if (next[r.name] === true) { delete next[r.name]; pick = "" }
            else { next[r.name] = true; pick = r.key }
            opened = next
            return
        }
        pick = pick === r.key ? "" : r.key
    }

    function step(d) {
        if (!rows.length) return
        const i = rows.findIndex(r => r.key === pick)
        pick = rows[i < 0 ? (d > 0 ? 0 : rows.length - 1) : (i + d + rows.length) % rows.length].key
    }

    function end(g, force) {
        if (!g || slay.running) return
        const own = g.child ? g.parent : g.name
        if (own === "qs" || own === "quickshell") return flash(word("That is Dolphin itself. Restart it with Super+Shift+R instead."))
        slain = g.child ? g.name + " " + g.pid : g.name
        slay.command = ["kill"].concat(force ? ["-9"] : []).concat(g.pids.map(p => String(p)))
        slay.running = true
    }

    function fmt(g, k) {
        const v = g[k] ?? 0
        if (k === "cpu" || k === "gpu") return v.toFixed(1) + "%"
        if (k === "mem") return size(v)
        if (k === "gmem") return v > 0 ? size(v) : "–"
        if (k === "start") {
            if (v <= 0) return "–"
            const d = new Date(v * 1000)
            return Qt.formatDateTime(d, d.toDateString() === new Date().toDateString() ? "h:mm ap" : "MMM d")
        }
        if (k === "disk") return v > 0 ? rate(v) : "–"
        return v > 0 ? String(v) : "–"
    }
    function read(out) {
        const clean = String(out).replace(/\x1b\[[0-9;?]*[ -\/]*[@-~]/g, "").replace(/\x1b[()][A-Za-z0-9]/g, "").replace(/\r/g, "")
        const parts = clean.split("\n@@DOLPHIN@@\n")
        fetchLogo = (parts[0] ?? "").replace(/^\n+/, "").replace(/\s+$/, "")
        fetchInfo = (parts[1] ?? "").split("\n").map(l => l.trim()).filter(l => l !== "").map(l => {
            const at = l.indexOf(": ")
            return at > 0 ? [l.slice(0, at), l.slice(at + 2)] : ["", l]
        })
        fetched = true
    }

    function facts(key) {
        const j = snap
        if (!j) return []
        const m = j.mem
        if (key === "mem") return [[word("In use"), size(m.total - m.avail)], [word("Available"), size(m.avail)], [word("Cached"), size(m.cached)], [word("Total"), size(m.total)], [word("Swap in use"), m.swap ? size(m.swap - m.swapFree) + " / " + size(m.swap) : "–"]]
        if (key === "disk") return [[word("Write speed"), rate(j.disk.write)], [word("Read speed"), rate(j.disk.read)], [word("Active time"), Math.round(j.disk.busy) + "%"], [word("Used"), bytes(j.disk.used)], [word("Capacity"), bytes(j.disk.size)]]
        if (key === "net") return [[word("Download"), rate(j.net.rx)], [word("Upload"), rate(j.net.tx)], [word("Adapter"), j.net.name || "–"]]
        if (key === "gpu") return j.gpu ? [[word("Utilization"), Math.round(j.gpu.busy) + "%"], [word("Dedicated memory"), j.gpu.total ? size(j.gpu.used) + " / " + size(j.gpu.total) : "–"], [word("Card"), j.gpu.name]] : []
        return [[word("Utilization"), Math.round(j.cpu) + "%"], [word("Speed"), j.freq ? (j.freq / 1000).toFixed(2) + " GHz" : "–"], [word("Processes"), String(j.procs ?? "–")], [word("Threads"), String(j.threads ?? "–")], [word("Logical processors"), String(j.cores.length)], [word("Temperature"), j.temp ? j.temp + " °C" : "–"], [word("Up time"), clock(j.up)]]
    }
    function subtitle(key) {
        const j = snap
        if (!j) return ""
        return key === "mem" ? size(j.mem.total) : key === "disk" ? bytes(j.disk.size) : key === "net" ? j.net.name : key === "gpu" ? (j.gpu?.name ?? "") : j.model
    }

    Process {
        id: feed
        running: root.s("manager_Show") && (root.keep || root.open || root.hopping)
        stdinEnabled: true
        command: ["python3", root.home + "/Interface/Binded/Snoopy Manager/Monitor.py", String(Math.max(300, root.s("manager_Interval")) / 1000), root.mode]
        stdout: SplitParser { onRead: data => root.take(data) }
    }

    Process {
        id: scout
        command: ["sh", "-c", root.s("manager_FetchLogo") + " 2>/dev/null; printf '\\n@@DOLPHIN@@\\n'; " + root.s("manager_FetchInfo") + " 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.read(text) }
    }

    Process {
        id: slay
        onExited: (exitCode, exitStatus) => { if (exitCode !== 0) root.flash(root.word("Could not end") + " " + root.slain + ". " + root.word("It belongs to another user or already closed.")) }
    }

    Timer { id: hop; interval: 80; onTriggered: { root.hopping = false; root.show() } }
    Timer { id: quiet; interval: 4000; onTriggered: root.note = "" }
    Timer { interval: 3000; running: root.open && !root.snap; onTriggered: root.late = true }

    GlobalShortcut { appid: "taskmanager"; name: "toggle"; onPressed: root.toggle() }

    IpcHandler {
        target: "taskmanager"
        function toggle(): void { root.toggle() }
    }

    Component {
        id: procC

        Item {
            id: sheet
            readonly property real xLast: width - 14 - root.colW
            readonly property real xFirst: xLast - root.colW * 2
            Component.onCompleted: find.forceActiveFocus()

            Item {
                id: strip
                width: parent.width
                height: Math.round(root.px * 3.4)

                Rectangle {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Math.round(root.px * 18), parent.width - trail.width - 40)
                    height: Math.round(root.px * 2.3)
                    radius: 6
                    color: "transparent"
                    border.width: 1
                    border.color: find.activeFocus ? root.hi : root.bd
                    Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: root.iconFont; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.6 }
                    TextInput {
                        id: find
                        anchors.fill: parent
                        anchors.leftMargin: 30
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        font.family: root.font
                        font.pixelSize: root.px
                        color: root.tx
                        selectionColor: root.hi
                        selectedTextColor: root.bg
                        Component.onCompleted: text = root.query
                        onTextChanged: root.query = text
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { if (text) text = ""; else root.back() }
                            else if (e.key === Qt.Key_Down) root.step(1)
                            else if (e.key === Qt.Key_Up) root.step(-1)
                            else if (e.key === Qt.Key_Delete) root.end(root.picked, !!(e.modifiers & Qt.ShiftModifier))
                            else return
                            e.accepted = true
                        }
                    }
                    Text { visible: !find.text; x: 30; anchors.verticalCenter: parent.verticalCenter; text: root.word("Search"); font.family: root.font; font.pixelSize: root.px; color: root.tx; opacity: 0.4 }
                }

                Row {
                    id: trail
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    Text { text: root.word("Sort by"); font.family: root.font; font.pixelSize: root.px - 1; color: root.tx; opacity: 0.55; anchors.verticalCenter: parent.verticalCenter }
                    Repeater {
                        model: [["name", "Name"], ["start", "Started"], ["size", "Size"]]
                        Item {
                            id: sorter
                            required property var modelData
                            readonly property bool lit: root.sortBy === modelData[0]
                            width: sortRow.width
                            height: Math.round(root.px * 2.2)
                            anchors.verticalCenter: parent.verticalCenter
                            Row {
                                id: sortRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5
                                Text { text: root.word(sorter.modelData[1]); font.family: root.font; font.pixelSize: root.px - 1; font.bold: sorter.lit; color: root.tx; opacity: sorter.lit ? 1 : 0.6 }
                                Text { visible: sorter.lit; text: root.sortDown ? "\uf078" : "\uf077"; font.family: root.iconFont; font.pixelSize: root.px - 4; color: root.tx; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Rectangle { visible: sorter.lit; y: parent.height - 2; width: parent.width; height: 2; color: root.hi }
                            TapHandler { onTapped: root.order(sorter.modelData[0]) }
                        }
                    }
                }
            }

            Item {
                id: cols
                y: strip.height
                width: parent.width
                height: Math.round(root.px * 2.4)

                Repeater {
                    model: [["name", "Name"]].concat(root.columns)
                    Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool lit: root.sortKey === modelData[0]
                        x: index === 0 ? 14 : sheet.xFirst + (index - 1) * root.colW
                        width: index === 0 ? sheet.xFirst - 14 : root.colW
                        height: cols.height
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: cell.index === 0 ? parent.left : undefined
                            anchors.right: cell.index === 0 ? undefined : parent.right
                            spacing: 5
                            Text { text: root.word(cell.modelData[1]); font.family: root.font; font.pixelSize: root.px - 1; font.bold: cell.lit; color: root.tx; opacity: cell.lit ? 1 : 0.6 }
                        }
                    }
                }
                Rectangle { y: parent.height - 1; x: 14; width: parent.width - 28; height: 1; color: root.bd }
            }

            ListView {
                id: list
                y: cols.y + cols.height
                width: parent.width
                height: foot.y - y
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Component.onCompleted: model = root.rows

                Connections {
                    target: root
                    function onRowsChanged() {
                        const y = list.contentY
                        list.model = root.rows
                        list.contentY = y
                        list.returnToBounds()
                    }
                }

                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index
                    readonly property bool sel: root.pick === modelData.key
                    readonly property bool kid: modelData.child === true
                    readonly property bool wide: !kid && modelData.count > 1
                    readonly property real inset: kid ? Math.round(root.px * 2.6) : 0
                    readonly property color tint: sel ? root.bg : root.tx
                    width: ListView.view.width
                    height: root.rowH

                    Rectangle {
                        x: 8
                        width: parent.width - 16
                        height: parent.height
                        color: entry.sel ? root.hi : touch.hovered ? Qt.rgba(root.hv.r, root.hv.g, root.hv.b, 0.5) : "transparent"
                    }
                    Text {
                        visible: entry.wide
                        x: 14
                        width: Math.round(root.px * 0.9)
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: root.opened[entry.modelData.name] === true ? "\uf078" : "\uf054"
                        font.family: root.iconFont
                        font.pixelSize: root.px - 4
                        color: entry.tint
                        opacity: 0.7
                    }
                    Image {
                        id: logo
                        visible: entry.modelData.app === true
                        x: 14 + Math.round(root.px * 1.4)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(root.px * 1.4)
                        height: width
                        sourceSize: Qt.size(48, 48)
                        asynchronous: true
                        source: entry.modelData.app === true ? Quickshell.iconPath(DesktopEntries.heuristicLookup(entry.modelData.name)?.icon ?? entry.modelData.name, "application-x-executable") : ""
                    }
                    Rectangle {
                        visible: !logo.visible && !entry.kid
                        x: logo.x + Math.round(logo.width / 2) - 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 4
                        color: entry.tint
                        opacity: 0.35
                    }
                    Text {
                        x: logo.x + (entry.kid ? 0 : logo.width + 10) + entry.inset
                        width: sheet.xFirst - x - 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: entry.kid ? entry.modelData.name + "  ·  " + entry.modelData.pid : entry.modelData.name + (entry.modelData.count > 1 ? "  (" + entry.modelData.count + ")" : "")
                        font.family: root.font
                        font.pixelSize: entry.kid ? root.px - 1 : root.px
                        color: entry.tint
                        opacity: entry.sel ? 1 : entry.kid ? 0.75 : entry.modelData.mine ? 1 : 0.6
                    }
                    Repeater {
                        model: root.columns
                        Text {
                            required property var modelData
                            required property int index
                            readonly property real amount: entry.modelData[modelData[0]] ?? 0
                            x: sheet.xFirst + index * root.colW
                            width: root.colW
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.fmt(entry.modelData, modelData[0])
                            font.family: root.font
                            font.pixelSize: root.px
                            font.bold: root.sortKey === modelData[0]
                            color: entry.tint
                            opacity: amount > 0 || entry.sel ? 1 : 0.45
                        }
                    }

                    HoverHandler { id: touch }
                    TapHandler { onTapped: { root.tap(entry.modelData); find.forceActiveFocus() } }
                }
            }

            Scroller { view: list }

            Rectangle {
                visible: list.contentHeight > list.height + 1
                x: parent.width - 5
                y: list.y + list.visibleArea.yPosition * list.height
                width: 3
                height: Math.max(24, list.visibleArea.heightRatio * list.height)
                color: root.tx
                opacity: 0.3
            }

            Item {
                id: foot
                y: parent.height - height
                width: parent.width
                height: Math.round(root.px * 3.6)

                Rectangle { x: 14; width: parent.width - 28; height: 1; color: root.bd }
                Text {
                    x: 14
                    width: parent.width - kill.width - 42
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: root.note !== "" ? root.note : root.rows.length + " " + root.word("processes") + (root.gauge === "net" ? "  ·  " + root.word("only your own apps with open connections") : root.gauge === "gpu" ? "  ·  " + root.word("only your own apps using the graphics card") : "")
                    font.family: root.font
                    font.pixelSize: root.px - 1
                    color: root.note !== "" ? root.bad : root.tx
                    opacity: root.note !== "" ? 1 : 0.55
                }
                Rectangle {
                    id: kill
                    readonly property bool live: !!root.picked && !slay.running
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: killText.implicitWidth + 28
                    height: Math.round(root.px * 2.2)
                    radius: 6
                    color: live && press.hovered ? root.bad : "transparent"
                    border.width: 1
                    border.color: live ? root.bad : root.bd
                    opacity: live ? 1 : 0.45
                    Text { id: killText; anchors.centerIn: parent; text: root.word("End task"); font.family: root.font; font.pixelSize: root.px - 1; font.bold: true; color: kill.live ? (press.hovered ? root.bg : root.bad) : root.tx }
                    HoverHandler { id: press }
                    TapHandler { id: strike; onTapped: if (kill.live) root.end(root.picked, !!(strike.point.modifiers & Qt.ShiftModifier)) }
                }
            }
        }
    }

    LazyLoader {
        active: root.open && root.s("manager_Show")

        FloatingWindow {
            id: win
            property int mine: -1
            title: "dolphin-taskmanager"
            implicitWidth: Math.max(640, root.keepW > 0 ? root.keepW : Math.round((win.screen?.width ?? 1440) * root.s("manager_Width")))
            implicitHeight: Math.max(420, root.keepH > 0 ? root.keepH : Math.round((win.screen?.height ?? 900) * root.s("manager_Height")))
            color: root.bg
            Component.onCompleted: mine = root.epoch
            onVisibleChanged: if (!visible && mine === root.epoch && !root.hopping) root.open = false
            onWidthChanged: if (visible && width >= 640) root.nowW = Math.round(width)
            onHeightChanged: if (visible && height >= 420) root.nowH = Math.round(height)

            Item {
                id: face
                readonly property bool inside: root.listing && !root.s("manager_ProcessWindow")
                readonly property real netPeak: root.most(root.hist.rx.concat(root.hist.tx), 102400)
                readonly property real diskPeak: root.most(root.hist.write.concat(root.hist.read), 1048576)
                readonly property var cards: {
                    const j = root.snap
                    if (!j) return []
                    const m = j.mem, used = m.total - m.avail
                    const out = [
                        { key: "cpu", name: root.word("CPU"), info: Math.round(j.cpu) + "%" + (j.freq ? "  " + (j.freq / 1000).toFixed(2) + " GHz" : ""), a: "cpu", b: "top", peak: 100, first: root.word("Utilization"), second: root.word("Busiest core") },
                        { key: "mem", name: root.word("Memory"), info: (used / 1048576).toFixed(1) + "/" + (m.total / 1048576).toFixed(1) + " GB (" + Math.round(used * 100 / Math.max(1, m.total)) + "%)", a: "mem", b: "swap", peak: 100, first: root.word("In use"), second: root.word("Swap") },
                        { key: "disk", name: root.word("Disk"), info: "W " + root.rate(j.disk.write) + "  R " + root.rate(j.disk.read), a: "write", b: "read", peak: diskPeak, first: root.word("Write"), second: root.word("Read") },
                        { key: "net", name: root.netName, info: " " + root.rate(j.net.rx) + "   " + root.rate(j.net.tx), a: "rx", b: "tx", peak: netPeak, first: root.word("Download"), second: root.word("Upload") }
                    ]
                    if (j.gpu) out.push({ key: "gpu", name: root.word("GPU"), info: Math.round(j.gpu.busy) + "%", a: "gpu", b: "vram", peak: 100, first: root.word("Utilization"), second: root.word("Memory") })
                    return out
                }
                readonly property bool about: root.gauge === "fetch"
                readonly property var card: about ? null : cards.find(c => c.key === root.gauge) ?? cards[0] ?? null
                readonly property string key: about ? "fetch" : card ? card.key : "cpu"
                anchors.fill: parent
                focus: true
                function turn(d) {
                    const all = cards.map(c => c.key).concat(["fetch"]), i = all.indexOf(key)
                    root.gauge = all[(Math.max(0, i) + d + all.length) % all.length]
                }
                Keys.onEscapePressed: root.back()
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Down) root.step(1)
                    else if (e.key === Qt.Key_Up) root.step(-1)
                    else if (e.key === Qt.Key_Left) turn(-1)
                    else if (e.key === Qt.Key_Right) turn(1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (root.picked && !root.picked.child && root.picked.count > 1) root.tap(root.picked) }
                    else if (e.key === Qt.Key_Delete) root.end(root.picked, !!(e.modifiers & Qt.ShiftModifier))
                    else return
                    e.accepted = true
                }

                Item {
                    id: crown
                    x: 20
                    width: parent.width - 40
                    height: Math.round(root.px * 4.4)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Text { text: root.glyph(root.s("manager_Icon")); font.family: root.iconFont; font.pixelSize: root.px + 13; color: root.mark; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: root.word(root.s("manager_Title")); font.family: root.font; font.pixelSize: root.px + 3; font.bold: true; font.letterSpacing: 3; color: root.tx; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Item {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(root.px * 2.4)
                        height: width
                        Rectangle { anchors.fill: parent; color: shut.hovered ? root.bad : "transparent" }
                        Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: root.px + 1; color: shut.hovered ? root.bg : root.tx }
                        HoverHandler { id: shut }
                        TapHandler { onTapped: root.open = false }
                    }
                }
                Rectangle { y: crown.height; width: parent.width; height: 1; color: root.bd }

                Text {
                    anchors.centerIn: parent
                    visible: !root.snap
                    text: root.late ? root.word("No data yet. Snoopy Manager needs python3.") : root.word("Reading…")
                    font.family: root.font
                    font.pixelSize: root.px
                    color: root.tx
                    opacity: 0.5
                }

                Item {
                    id: body
                    visible: !!root.snap
                    y: crown.height + 1
                    width: parent.width
                    height: parent.height - y

                    Column {
                        id: tabs
                        y: 8
                        width: Math.round(root.px * 17.5)

                        Repeater {
                            model: face.cards
                            Item {
                                id: tab
                                required property var modelData
                                readonly property bool lit: face.key === modelData.key
                                width: tabs.width
                                height: Math.round(root.px * 4.8)

                                Rectangle { anchors.fill: parent; color: root.hv; opacity: tile.hovered && !tab.lit ? 0.35 : 0 }
                                Graph {
                                    id: mini
                                    x: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.round(root.px * 5)
                                    height: parent.height - 22
                                    values: root.hist[tab.modelData.a] ?? []
                                    span: 20
                                    peak: tab.modelData.peak
                                    ink: root.bars
                                    mesh: root.mesh
                                    rows: 1
                                    slit: 1
                                }
                                Column {
                                    x: mini.x + mini.width + 12
                                    width: parent.width - x - 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text { width: parent.width; elide: Text.ElideRight; text: tab.modelData.name; font.family: root.font; font.pixelSize: root.px + 1; font.bold: true; color: root.tx }
                                    Text { width: parent.width; elide: Text.ElideRight; text: tab.modelData.info; font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.65 }
                                }
                                Rectangle { visible: tab.lit; x: 20; y: parent.height - 2; width: parent.width - 30; height: 2; color: root.hi }
                                HoverHandler { id: tile }
                                TapHandler { onTapped: root.gauge = tab.modelData.key }
                            }
                        }

                        Item {
                            width: tabs.width
                            height: Math.round(root.px * 4.8)
                            Rectangle { anchors.fill: parent; color: root.hv; opacity: logoHover.hovered && !face.about ? 0.35 : 0 }
                            Rectangle { visible: face.about; x: 20; y: parent.height - 2; width: parent.width - 30; height: 2; color: root.hi }
                            Item {
                                id: emblem
                                x: 20
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(root.px * 5)
                                height: parent.height - 22
                                Text { anchors.centerIn: parent; text: root.glyph(root.s("manager_FetchIcon")); font.family: root.iconFont; font.pixelSize: root.px + 13; color: root.tx }
                            }
                            Column {
                                x: emblem.x + emblem.width + 12
                                width: parent.width - x - 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text { width: parent.width; elide: Text.ElideRight; text: root.word(root.s("manager_FetchLabel")); font.family: root.font; font.pixelSize: root.px + 1; font.bold: true; color: root.tx }
                                Text { width: parent.width; elide: Text.ElideRight; text: root.word("System information"); font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.65 }
                            }
                            HoverHandler { id: logoHover }
                            TapHandler { onTapped: root.gauge = "fetch" }
                        }
                    }

                    Rectangle { x: tabs.width + 10; width: 1; height: parent.height; color: root.bd }

                    Item {
                        id: pane
                        x: tabs.width + 30
                        y: 14
                        width: parent.width - x - 20
                        height: parent.height - 32

                        Item {
                            id: lead
                            width: parent.width
                            height: Math.round(root.px * 3)
                            Text { id: big; anchors.verticalCenter: parent.verticalCenter; text: face.about ? root.word(root.s("manager_FetchLabel")) : face.inside ? root.tag : face.card ? face.card.name : ""; font.family: root.font; font.pixelSize: face.inside ? root.px + 4 : root.px + 10; font.bold: true; font.letterSpacing: face.inside ? 2 : 0; color: root.tx }
                            Text {
                                x: big.width + 14
                                width: parent.width - x - more.width - 14
                                anchors.baseline: big.baseline
                                elide: Text.ElideRight
                                text: face.about || face.inside ? "" : root.subtitle(face.key)
                                font.family: root.font
                                font.pixelSize: root.px - 1
                                color: root.tx
                                opacity: 0.6
                            }
                            Rectangle {
                                id: more
                                visible: !face.about
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: moreText.implicitWidth + 28
                                height: Math.round(root.px * 2.2)
                                radius: 6
                                color: moreHover.hovered || root.listing ? root.hi : "transparent"
                                border.width: 1
                                border.color: root.hi
                                Text { id: moreText; anchors.centerIn: parent; text: face.inside ? root.word("Graph") : root.word("Processes"); font.family: root.font; font.pixelSize: root.px - 1; font.bold: true; color: moreHover.hovered || root.listing ? root.bg : root.tx }
                                HoverHandler { id: moreHover }
                                TapHandler { onTapped: root.listing = !root.listing }
                            }
                        }

                        Loader {
                            y: lead.height + 6
                            width: parent.width
                            height: parent.height - y
                            active: face.inside
                            visible: active
                            sourceComponent: procC
                        }

                        Item {
                            visible: face.about
                            y: lead.height + 14
                            width: parent.width
                            height: parent.height - y
                            clip: true

                            Text {
                                visible: !root.fetched || (root.fetchLogo === "" && root.fetchInfo.length === 0)
                                text: !root.fetched ? root.word("Reading…") : root.word("Nothing came back. Is it installed? The commands are manager_FetchLogo and manager_FetchInfo.")
                                width: parent.width
                                wrapMode: Text.Wrap
                                font.family: root.font
                                font.pixelSize: root.px
                                color: root.tx
                                opacity: 0.6
                            }
                            Text {
                                id: art
                                visible: root.fetched && root.fetchLogo !== ""
                                text: root.fetchLogo
                                font.family: root.font
                                font.pixelSize: Math.max(7, Math.min(root.px, Math.floor(parent.height / Math.max(1, root.fetchLogo.split("\n").length) / 1.25)))
                                lineHeight: 1
                                color: root.hi
                            }
                            Column {
                                visible: root.fetched
                                x: art.visible ? art.width + 28 : 0
                                width: parent.width - x
                                spacing: 4
                                Repeater {
                                    model: root.fetchInfo
                                    Row {
                                        id: fact
                                        required property var modelData
                                        spacing: 8
                                        Text { visible: fact.modelData[0] !== ""; text: fact.modelData[0]; font.family: root.font; font.pixelSize: root.px; font.bold: true; color: root.hi }
                                        Text { width: Math.max(40, parent.parent.width - (fact.modelData[0] !== "" ? x : 0)); elide: Text.ElideRight; text: fact.modelData[1]; font.family: root.font; font.pixelSize: root.px; font.bold: fact.modelData[0] === ""; color: root.tx }
                                    }
                                }
                            }
                        }

                        Item {
                            visible: !face.inside && !face.about
                            y: lead.height + 6
                            width: parent.width
                            height: parent.height - y

                            Item {
                                id: ruler
                                width: parent.width
                                height: Math.round(root.px * 1.8)
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    Rectangle { width: Math.round(root.px * 0.8); height: width; color: root.bars; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: face.card ? face.card.first : ""; font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.7 }
                                    Item { width: 8; height: 1 }
                                    Rectangle { width: Math.round(root.px * 1.4); height: 2; color: root.pen; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: face.card ? face.card.second : ""; font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.7 }
                                }
                                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: face.key === "net" ? root.rate(face.netPeak) : face.key === "disk" ? root.rate(face.diskPeak) : "100%"; font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.55 }
                            }

                            Graph {
                                id: chart
                                y: ruler.height + 4
                                width: parent.width
                                height: Math.max(80, parent.height - y - cores.height - stats.height - 28)
                                values: face.card ? (root.hist[face.card.a] ?? []) : []
                                trace: face.card ? (root.hist[face.card.b] ?? []) : []
                                span: root.cap
                                peak: face.card ? face.card.peak : 100
                                ink: root.bars
                                pen: root.pen
                                mesh: root.mesh
                                rows: 5
                            }

                            Row {
                                id: cores
                                visible: face.key === "cpu" && root.s("manager_CoreBars")
                                y: chart.y + chart.height + 10
                                width: parent.width
                                height: visible ? Math.round(root.px * 2.2) : 0
                                spacing: 2
                                Repeater {
                                    model: cores.visible && root.snap ? root.snap.cores : []
                                    Rectangle {
                                        required property var modelData
                                        width: Math.max(2, (cores.width - ((root.snap?.cores.length ?? 1) - 1) * 2) / (root.snap?.cores.length ?? 1))
                                        height: cores.height
                                        color: root.mesh
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: Math.max(1, parent.height * Math.min(1, parent.modelData / 100))
                                            color: root.bars
                                        }
                                    }
                                }
                            }

                            Flow {
                                id: stats
                                y: parent.height - height
                                width: parent.width
                                spacing: 24
                                Repeater {
                                    model: root.facts(face.key)
                                    Column {
                                        required property var modelData
                                        spacing: 1
                                        Text { text: parent.modelData[0]; font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.55 }
                                        Text { text: parent.modelData[1]; font.family: root.font; font.pixelSize: root.px + 3; font.bold: true; color: root.tx }
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
        active: root.open && root.listing && root.s("manager_ProcessWindow") && root.s("manager_Show")

        FloatingWindow {
            id: tray
            property int mine: -1
            title: "dolphin-processes"
            implicitWidth: Math.max(480, Math.round((tray.screen?.width ?? 1440) * root.s("manager_ProcessWidth")))
            implicitHeight: Math.max(360, Math.round((tray.screen?.height ?? 900) * root.s("manager_ProcessHeight")))
            color: root.bg
            Component.onCompleted: { root.trays++; mine = root.trays }
            onVisibleChanged: if (!visible && mine === root.trays && root.open && !root.hopping) root.listing = false

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.listing = false

                Item {
                    id: roof
                    x: 14
                    width: parent.width - 28
                    height: Math.round(root.px * 3.6)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text { text: root.glyph(root.s("manager_Icon")); font.family: root.iconFont; font.pixelSize: root.px + 8; color: root.mark; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: root.tag; font.family: root.font; font.pixelSize: root.px + 1; font.bold: true; font.letterSpacing: 3; color: root.tx; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Item {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(root.px * 2.2)
                        height: width
                        Rectangle { anchors.fill: parent; color: gone.hovered ? root.bad : "transparent" }
                        Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: root.px; color: gone.hovered ? root.bg : root.tx }
                        HoverHandler { id: gone }
                        TapHandler { onTapped: root.listing = false }
                    }
                }
                Rectangle { y: roof.height; width: parent.width; height: 1; color: root.bd }

                Loader {
                    y: roof.height + 1
                    width: parent.width
                    height: parent.height - y
                    sourceComponent: procC
                }
            }
        }
    }
}
