import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../../Backend"

Kit {
    id: root

    base: ({
        connections_Show: true, connections_Title: "NETWORK CONNECTIONS", connections_Icon: "f1e0", connections_Inverted: false,
        connections_Width: 0.6, connections_Height: 0.72, connections_TextSize: 13, connections_Radius: 14, connections_Interval: 2500, connections_View: "overview",
        connections_Sections: [
            { Key: "Internet", Icon: "f0ac", Color: "Active" }, { Key: "Bluetooth", Icon: "f294", Color: "Active" },
            { Key: "Network", Icon: "f0e8", Color: "Active" }, { Key: "Devices", Icon: "f287", Color: "Active" },
            { Key: "Power", Icon: "f1e6", Color: "Active" }, { Key: "Displays", Icon: "f108", Color: "Active" },
            { Key: "Storage", Icon: "f0a0", Color: "Active" }, { Key: "Sessions", Icon: "f120", Color: "Active" }
        ],
        connections_Rows: 5, connections_History: 60, connections_Motion: true,
        connections_Color: "Background", connections_PanelColor: "Accent", connections_TextColor: "Text", connections_IconColor: "Text",
        connections_ActiveColor: "Active", connections_BorderColor: "Accent2", connections_HostColor: "Active",
        connections_DownColor: "#9ece6a", connections_UpColor: "#f7768e"
    })

    readonly property color bg: tone("connections_Color")
    readonly property color tx: tone("connections_TextColor")
    readonly property color mark: tone("connections_IconColor")
    readonly property color hi: tone("connections_ActiveColor")
    readonly property color bd: tone("connections_BorderColor")
    readonly property color pane: tone("connections_PanelColor")
    readonly property color core: tone("connections_HostColor")
    readonly property color soft: Qt.rgba(tx.r, tx.g, tx.b, 0.06)
    readonly property color softer: Qt.rgba(tx.r, tx.g, tx.b, 0.12)
    readonly property color glow: Qt.rgba(hi.r, hi.g, hi.b, 0.18)
    readonly property color fall: tone("connections_DownColor")
    readonly property color rise: tone("connections_UpColor")
    readonly property real px: Math.max(9, s("connections_TextSize"))
    readonly property real rad: Math.max(0, s("connections_Radius"))
    readonly property real rowH: Math.round(px * 2.1)
    readonly property real colMem: Math.round(px * 6.5)
    readonly property real colRate: Math.round(px * 8.8)
    readonly property real colAge: Math.round(px * 5.6)
    readonly property string here: String(Quickshell.shellDir).replace(/\/+$/, "") + "/Interface/Binded/Network Connections"
    readonly property bool chart: s("connections_View") !== "list"
    readonly property bool moving: s("connections_Motion") && Motion.on
    readonly property var arrows: ({ [Qt.Key_Up]: "up", [Qt.Key_Down]: "down", [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Return]: "enter", [Qt.Key_Enter]: "enter" })
    readonly property string sectionSig: JSON.stringify(s("connections_Sections"))
    readonly property var sections: shape(sectionSig)
    readonly property int total: { tick; storeRev; return sections.reduce((a, e) => a + (stores[e.key] ? stores[e.key].count : 0), 0) }

    property bool open: false
    property bool hopping: false
    property bool polled: false
    property int room: 0
    property int epoch: 0
    property int keepW: 0
    property int keepH: 0
    property int nowW: 0
    property int nowH: 0
    property string hostName: "laptop"
    property string error: ""
    property var stores: ({})
    property int storeRev: 0
    property var buffer: []
    property real lastPoll: 0
    property int clock: 0
    property int tick: 0
    property var detail: null
    property var history: []
    property var cur: null
    property bool keys: false

    signal bring(var item)

    onOpenChanged: {
        if (open) { Hyprland.refreshToplevels(); return }
        if (hopping) return
        keepW = 0
        keepH = 0
        reset()
    }

    function paint(n) {
        n = String(n)
        if (!s("connections_Inverted") || n.startsWith("#")) return col(n)
        const c = Qt.alpha(col(n), 1)
        return Qt.rgba(1 - c.r, 1 - c.g, 1 - c.b, 1)
    }
    function tone(k) { return paint(s(k)) }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function lum(c) { return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b }
    function over(c) {
        const flip = lum(bg) < lum(tx)
        return lum(c) > 0.5 ? (flip ? bg : tx) : (flip ? tx : bg)
    }

    function shape(sig) {
        let list = []
        try { list = JSON.parse(sig) } catch (e) {}
        const out = [], seen = {}
        for (const e of list) {
            const k = String(e?.Key ?? "")
            if (k === "" || seen[k]) continue
            seen[k] = true
            out.push({ key: k, icon: String(e?.Icon ?? ""), color: String(e?.Color ?? "Active") })
        }
        return out
    }
    function store(k) { storeRev; return stores[k] ?? null }
    function part(k) { return sections.find(e => e.key === k) ?? null }

    function reset() {
        for (const e of sections) {
            const st = stores[e.key]
            if (!st) continue
            st.items.clear()
            st.count = 0
            st.mem = 0
            st.rxRate = 0
            st.txRate = 0
        }
        buffer = []
        history = []
        cur = null
        keys = false
        lastPoll = 0
        polled = false
        detail = null
        error = ""
    }

    function poll() {
        if (pollProc.running) return
        buffer = []
        pollProc.running = true
    }

    function apply(code) {
        const lines = buffer
        buffer = []
        polled = true
        if (!lines.length) {
            error = word("No data. Network Connections needs bash and Collect.sh.") + " (" + code + ")"
            return
        }
        error = ""
        const now = Date.now(), first = lastPoll === 0, dt = first ? 0 : (now - lastPoll) / 1000
        lastPoll = now
        clock = Math.floor(now / 1000)
        const seen = {}
        for (const line of lines) {
            const f = line.split("\t")
            const st = stores[f[0]]
            if (f.length < 10 || !st) continue
            if (!seen[f[0]]) seen[f[0]] = {}
            seen[f[0]][f[1]] = true
            take(st.items, f, dt, first)
        }
        for (const e of sections) if (stores[e.key]) sweep(stores[e.key], seen[e.key] || {})
        const net = stores.Internet ?? stores.Network
        if (net && !first) history = history.concat([[net.rxRate, net.txRate]]).slice(-Math.max(10, Math.round(s("connections_History"))))
        tick++
    }

    function take(m, f, dt, first) {
        const uid = f[1], mem = Number(f[4]) || 0, rx = Number(f[5]) || 0, tx = Number(f[6]) || 0, since = Number(f[7]) || 0, sub = Number(f[10]) || 0
        for (let k = 0; k < m.count; k++) {
            const o = m.get(k)
            if (o.uid !== uid) continue
            m.set(k, {
                name: f[2], summary: f[3], mem: mem, rx: rx, tx: tx,
                rxRate: dt > 0 && rx >= o.rx ? (rx - o.rx) / dt : 0,
                txRate: dt > 0 && tx >= o.tx ? (tx - o.tx) / dt : 0,
                since: since || o.since, rate: f[8], details: f[9], sub: sub, gone: false
            })
            return
        }
        m.append({
            uid: uid, name: f[2], summary: f[3], mem: mem, rx: rx, tx: tx, rxRate: 0, txRate: 0,
            since: since || (first ? 0 : clock), rate: f[8], details: f[9], sub: sub, open: false, gone: false
        })
    }

    function sweep(st, seen) {
        const m = st.items
        let n = 0, mem = 0, rx = 0, tx = 0
        for (let k = m.count - 1; k >= 0; k--) {
            const o = m.get(k)
            if (seen[o.uid]) { n++; mem += o.mem; rx += o.rxRate; tx += o.txRate }
            else if (o.gone) m.remove(k)
            else m.setProperty(k, "gone", true)
        }
        st.count = n
        st.mem = mem
        st.rxRate = rx
        st.txRate = tx
    }

    function label(name, sub) { return sub > 0 ? name + " (" + sub + ")" : name }

    function lookup(section, uid) {
        const st = stores[section]
        if (!st) return null
        const m = st.items
        if (!uid) {
            const names = []
            for (let k = 0; k < m.count; k++) {
                const o = m.get(k)
                if (!o.gone) names.push(label(o.name, o.sub) + "=" + memText(o.mem))
            }
            return { section: section, uid: "", name: word(section), sub: st.count, summary: st.count + " " + word("connected"), mem: st.mem, rx: 0, tx: 0, rxRate: st.rxRate, txRate: st.txRate, since: 0, rate: "", details: names.join("\x1f"), group: true }
        }
        for (let k = 0; k < m.count; k++) {
            const o = m.get(k)
            if (o.uid === uid && !o.gone) return { section: section, uid: o.uid, name: o.name, sub: o.sub, summary: o.summary, mem: o.mem, rx: o.rx, tx: o.tx, rxRate: o.rxRate, txRate: o.txRate, since: o.since, rate: o.rate, details: o.details, group: false }
        }
        return null
    }

    function fields(o) {
        const out = []
        if (!o) return out
        const counted = o.rx > 0 || o.tx > 0 || o.rxRate > 0 || o.txRate > 0
        out.push(["Overview"])
        if (!o.group) {
            out.push(["ID", o.uid.replace(/^[a-z]+:/, "")])
            out.push(["Connected for", ago(o.since)])
            if (o.rate) out.push(["Speed", o.rate])
        }
        out.push(["Memory", memText(o.mem)])
        out.push(["Traffic"])
        if (counted) {
            out.push(["Download", speed(o.rxRate)])
            out.push(["Upload", speed(o.txRate)])
            if (!o.group) {
                out.push(["Received", bytes(o.rx)])
                out.push(["Sent", bytes(o.tx)])
            }
        } else out.push(["Bandwidth", word("not measurable for this connection")])
        const extra = o.details.split("\x1f").filter(p => p.indexOf("=") > 0 && p[0] !== "@")
        if (extra.length) out.push([o.group ? "Connected" : "Details"])
        for (const p of extra) {
            const i = p.indexOf("=")
            out.push([p.slice(0, i), p.slice(i + 1)])
        }
        return out
    }

    function procs(o) {
        if (!o) return []
        const raw = o.details.split("\x1f").find(p => p.startsWith("@procs="))
        if (!raw) return []
        return raw.slice(7).split("\x1e").map(r => {
            const f = r.split("\x1d")
            return { pid: f[0], name: f[1] + (f[2] ? " · " + f[2] : ""), mem: Number(f[3]) || 0, threads: f[4] || "–", since: Number(f[5]) || 0, socks: f[6] || "0" }
        }).sort((a, b) => b.mem - a.mem)
    }

    function bytes(n) {
        if (!(n > 0)) return "0 B"
        const unit = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (n >= 1024 && i < 4) { n /= 1024; i++ }
        return (i === 0 || n >= 100 ? Math.round(n) : n.toFixed(1)) + " " + unit[i]
    }
    function memText(kb) { return kb > 0 ? bytes(kb * 1024) : "–" }
    function speed(b) { return bytes(b) + "/s" }
    function ago(since) {
        if (!(since > 0)) return "–"
        const v = Math.max(0, clock - since), d = Math.floor(v / 86400), h = Math.floor(v % 86400 / 3600), m = Math.floor(v % 3600 / 60)
        return d ? d + "d " + h + "h" : h ? h + "h " + m + "m" : m ? m + "m " + v % 60 + "s" : v + "s"
    }
    function level(b) { return Math.min(1, Math.log(1 + Math.max(0, b) / 1024) / 9) }

    function spot() {
        const t = Hyprland.toplevels.values.find(h => h.title === "dolphin-connections")
        return t?.workspace?.id ?? t?.lastIpcObject?.workspace?.id ?? room
    }
    function show() {
        room = Hyprland.focusedWorkspace?.id ?? 0
        epoch++
        open = true
    }
    function toggle() {
        if (!s("connections_Show") || hop.running) return
        if (!open) return show()
        if (spot() === (Hyprland.focusedWorkspace?.id ?? 0)) { open = false; return }
        hopping = true
        keepW = nowW
        keepH = nowH
        open = false
        hop.restart()
    }
    function back() {
        if (detail !== null) detail = null
        else open = false
    }
    function at(section, uid) { return keys && cur !== null && cur.section === section && cur.uid === uid }
    function flip() {
        detail = null
        cur = null
        save("connections_View", chart ? "list" : "overview")
    }
    function pick(section, uid) { detail = { section: section, uid: uid } }

    Instantiator {
        model: root.sections
        delegate: QtObject {
            id: shelf
            required property var modelData
            readonly property string key: modelData.key
            property int count: 0
            property real mem: 0
            property real rxRate: 0
            property real txRate: 0
            readonly property ListModel items: ListModel {}
            Component.onCompleted: { root.stores[key] = shelf; root.storeRev++ }
            Component.onDestruction: if (root.stores[key] === shelf) { delete root.stores[key]; root.storeRev++ }
        }
    }

    FileView {
        path: "/etc/hostname"
        blockLoading: true
        printErrors: false
        onLoaded: { const h = text().trim(); if (h) root.hostName = h }
    }

    Process {
        id: pollProc
        command: ["bash", root.here + "/Collect.sh"].concat(root.sections.map(e => e.key))
        stdout: SplitParser { onRead: line => root.buffer.push(line) }
        onExited: (exitCode, exitStatus) => { if (root.open) root.apply(exitCode) }
    }

    Timer {
        interval: Math.max(500, root.s("connections_Interval"))
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Timer { id: hop; interval: 80; onTriggered: { root.hopping = false; root.show() } }

    GlobalShortcut { appid: "connections"; name: "toggle"; onPressed: root.toggle() }

    IpcHandler {
        target: "connections"
        function toggle(): void { root.toggle() }
    }

    component T: Text {
        color: root.tx
        font.family: root.font
        font.pixelSize: root.px
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property string icon: ""
        signal tapped()
        width: pillRow.implicitWidth + Math.round(root.px * 1.8)
        height: Math.round(root.px * 2.3)
        radius: height / 2
        color: pillHover.hovered ? root.softer : root.soft
        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8
            Text { visible: pill.icon !== ""; anchors.verticalCenter: parent.verticalCenter; text: pill.icon; font.family: root.iconFont; font.pixelSize: root.px; color: root.tx }
            T { anchors.verticalCenter: parent.verticalCenter; text: pill.label }
        }
        HoverHandler { id: pillHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: pill.tapped() }
    }

    component Stat: Rectangle {
        id: stt
        property string label: ""
        property string value: ""
        property string mark: ""
        property color ink: root.tx
        width: Math.max(Math.round(root.px * 10.5), sttCol.implicitWidth + Math.round(root.px * 2.4))
        height: Math.round(root.px * 4.8)
        radius: root.rad
        color: root.soft
        Column {
            id: sttCol
            x: Math.round(root.px * 1.2)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            T { text: root.word(stt.label); font.pixelSize: root.px - 2; opacity: 0.6 }
            Row {
                spacing: 6
                T { visible: stt.mark !== ""; anchors.verticalCenter: parent.verticalCenter; text: stt.mark; color: stt.ink; font.pixelSize: root.px + 4; font.bold: true }
                T { anchors.verticalCenter: parent.verticalCenter; text: stt.value; font.pixelSize: root.px + 4; font.weight: Font.DemiBold }
            }
        }
    }

    component Wire: Item {
        id: wr
        property real fromX: 0
        property real fromY: 0
        property real toX: 0
        property real toY: 0
        property real rx: 0
        property real tx: 0
        property real phase: 0
        property color ink: root.tx
        readonly property real level: Math.max(root.level(rx), root.level(tx))
        readonly property bool live: rx + tx > 0
        readonly property real midX: (fromX + toX) / 2
        readonly property real along: rx >= tx ? 1 - phase : phase
        function curve(a, b, c, d, t) {
            const u = 1 - t
            return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.alpha(wr.live ? wr.ink : root.tx, wr.live ? 0.3 + 0.5 * wr.level : 0.14)
                strokeWidth: 1.5 + 2.5 * wr.level
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: wr.fromX
                startY: wr.fromY
                PathCubic { x: wr.toX; y: wr.toY; control1X: wr.midX; control1Y: wr.fromY; control2X: wr.midX; control2Y: wr.toY }
            }
        }
        Rectangle {
            visible: wr.live && root.moving
            width: 6
            height: 6
            radius: 3
            x: wr.curve(wr.fromX, wr.midX, wr.midX, wr.toX, wr.along) - 3
            y: wr.curve(wr.fromY, wr.fromY, wr.toY, wr.toY, wr.along) - 3
            color: wr.rx >= wr.tx ? root.fall : root.rise
        }
    }

    component FieldList: Column {
        id: fl
        property var rows: []
        property real keyWidth: Math.round(root.px * 11.5)
        spacing: 3
        Repeater {
            model: fl.rows
            Item {
                id: fr
                required property var modelData
                readonly property bool head: modelData.length === 1
                width: fl.width
                height: head ? frHead.implicitHeight + 16 : Math.max(frKey.implicitHeight, frVal.implicitHeight)
                T { id: frHead; visible: fr.head; y: 12; text: fr.head ? root.word(fr.modelData[0]) : ""; font.weight: Font.DemiBold; color: root.hi }
                T { id: frKey; visible: !fr.head; width: fl.keyWidth; elide: Text.ElideRight; text: fr.head ? "" : root.word(fr.modelData[0]); opacity: 0.55 }
                T { id: frVal; visible: !fr.head; x: fl.keyWidth + 10; width: Math.max(0, fl.width - x); wrapMode: Text.Wrap; text: fr.head ? "" : fr.modelData[1] }
            }
        }
    }

    component ProcBox: Column {
        id: pb
        property var list: []
        property string owner: ""
        property bool expanded: false
        readonly property real colPid: Math.round(root.px * 5)
        readonly property real colNum: Math.round(root.px * 5.4)
        onOwnerChanged: expanded = false
        visible: list.length > 0
        spacing: 2

        Rectangle {
            width: pb.width
            height: Math.round(root.px * 2.3)
            radius: height / 2
            color: pbHover.containsMouse ? root.softer : root.soft
            Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                font.family: root.iconFont
                font.pixelSize: root.px - 4
                color: root.tx
                rotation: pb.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: Motion.span(180); easing.type: Easing.OutCubic } }
            }
            T { x: 32; anchors.verticalCenter: parent.verticalCenter; text: root.word("Processes") + " (" + pb.list.length + ")"; font.bold: true }
            T { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: pb.expanded ? root.word("click to close") : root.word("click to open"); opacity: 0.5 }
            MouseArea { id: pbHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.expanded = !pb.expanded }
        }

        Item {
            visible: pb.expanded
            width: pb.width
            height: root.rowH
            T { x: 12; width: pb.colPid; anchors.verticalCenter: parent.verticalCenter; text: "PID"; opacity: 0.55 }
            T { x: 24 + pb.colPid; anchors.verticalCenter: parent.verticalCenter; text: root.word("Process"); opacity: 0.55 }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                T { width: root.colMem; horizontalAlignment: Text.AlignRight; text: root.word("Memory"); opacity: 0.55 }
                T { width: pb.colNum; horizontalAlignment: Text.AlignRight; text: root.word("Threads"); opacity: 0.55 }
                T { width: pb.colNum; horizontalAlignment: Text.AlignRight; text: root.word("Sockets"); opacity: 0.55 }
                T { width: root.colAge; horizontalAlignment: Text.AlignRight; text: root.word("Running"); opacity: 0.55 }
            }
        }

        Repeater {
            model: pb.expanded ? pb.list : []
            Rectangle {
                id: pr
                required property var modelData
                required property int index
                width: pb.width
                height: root.rowH
                radius: root.rad / 2
                color: index % 2 ? "transparent" : Qt.alpha(root.tx, 0.05)
                T { x: 12; width: pb.colPid; anchors.verticalCenter: parent.verticalCenter; text: pr.modelData.pid }
                T { x: 24 + pb.colPid; width: Math.max(0, prStats.x - x - 10); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: pr.modelData.name }
                Row {
                    id: prStats
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    T { width: root.colMem; horizontalAlignment: Text.AlignRight; text: root.memText(pr.modelData.mem) }
                    T { width: pb.colNum; horizontalAlignment: Text.AlignRight; text: pr.modelData.threads }
                    T { width: pb.colNum; horizontalAlignment: Text.AlignRight; text: pr.modelData.socks }
                    T { width: root.colAge; horizontalAlignment: Text.AlignRight; text: root.ago(pr.modelData.since) }
                }
            }
        }
    }

    component Entry: Item {
        id: en
        required property int index
        required property string uid
        required property string name
        required property string summary
        required property real mem
        required property real rx
        required property real tx
        required property real rxRate
        required property real txRate
        required property real since
        required property string rate
        required property string details
        required property int sub
        required property bool open
        required property bool gone
        property string section: ""
        property color ink: root.hi
        property bool born: false
        readonly property bool counted: rx > 0 || tx > 0
        readonly property bool marked: root.at(section, uid)
        onMarkedChanged: if (marked) root.bring(en)
        function snap() { return { section: section, uid: uid, name: name, sub: sub, summary: summary, mem: mem, rx: rx, tx: tx, rxRate: rxRate, txRate: txRate, since: since, rate: rate, details: details, group: false } }
        height: born && !gone ? enBody.height : 0
        opacity: born && !gone ? 1 : 0
        clip: true
        Component.onCompleted: born = true
        Behavior on height { NumberAnimation { duration: Motion.span(260); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Motion.span(260) } }

        Column {
            id: enBody
            width: en.width

            Rectangle {
                width: parent.width
                height: root.rowH
                radius: root.rad / 2
                color: enHover.containsMouse || en.marked ? Qt.alpha(root.tx, 0.08) : "transparent"
                border.width: en.marked ? 2 : 0
                border.color: root.hi

                Text {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.family: root.iconFont
                    font.pixelSize: root.px - 4
                    color: en.open ? en.ink : root.tx
                    rotation: en.open ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: Motion.span(180); easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    x: 30
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 3.5
                    color: en.ink
                    opacity: 0.35 + Math.max(root.level(en.rxRate), root.level(en.txRate)) * 0.65
                }
                T { id: enName; x: 46; anchors.verticalCenter: parent.verticalCenter; width: Math.min(Math.round(root.px * 21), parent.width * 0.26); elide: Text.ElideRight; text: root.label(en.name, en.sub); font.bold: true }
                T {
                    x: enName.x + enName.width + 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, enStats.x - x - 14)
                    elide: Text.ElideRight
                    text: en.summary
                    opacity: 0.6
                }
                Row {
                    id: enStats
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    T { width: root.colMem; horizontalAlignment: Text.AlignRight; text: root.memText(en.mem) }
                    T { width: root.colRate; horizontalAlignment: Text.AlignRight; text: en.counted ? "↓ " + root.speed(en.rxRate) : "–"; color: en.rxRate > 0 ? root.fall : root.tx; opacity: en.rxRate > 0 ? 1 : 0.45 }
                    T { width: root.colRate; horizontalAlignment: Text.AlignRight; text: en.counted ? "↑ " + root.speed(en.txRate) : "–"; color: en.txRate > 0 ? root.rise : root.tx; opacity: en.txRate > 0 ? 1 : 0.45 }
                    T { width: root.colAge; horizontalAlignment: Text.AlignRight; text: root.ago(en.since); opacity: 0.6 }
                }
                MouseArea {
                    id: enHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { const st = root.stores[en.section]; if (st) st.items.setProperty(en.index, "open", !en.open) }
                }
            }

            Item {
                visible: en.open
                width: parent.width
                height: en.open ? enMore.height + 20 : 0
                Rectangle { x: 15; y: 2; width: 1; height: parent.height - 12; color: en.ink; opacity: 0.5 }
                Column {
                    id: enMore
                    x: 46
                    y: 2
                    width: parent.width - 60
                    spacing: 10
                    FieldList { width: parent.width; rows: en.open ? root.fields(en.snap()) : [] }
                    ProcBox { width: parent.width; owner: en.uid; list: en.open ? root.procs(en.snap()) : [] }
                }
            }
        }
    }

    Component {
        id: listC

        Item {
            function nav(k) {
                const list = []
                for (const e of root.sections) {
                    const st = root.stores[e.key]
                    if (!st) continue
                    for (let i = 0; i < st.items.count; i++) {
                        const o = st.items.get(i)
                        if (!o.gone) list.push({ section: e.key, uid: o.uid, index: i })
                    }
                }
                const n = list.length
                if (!n) return
                let i = root.cur ? list.findIndex(o => o.section === root.cur.section && o.uid === root.cur.uid) : -1
                if (k === "up" || k === "down" || i < 0) i = i < 0 ? 0 : (i + (k === "down" ? 1 : n - 1)) % n
                else {
                    const st = root.stores[list[i].section], o = st.items.get(list[i].index)
                    if (k === "enter" || (k === "right") !== o.open) st.items.setProperty(list[i].index, "open", k === "enter" ? !o.open : k === "right")
                }
                root.cur = list[i]
            }
            Connections {
                target: root
                function onBring(item) {
                    const y = item.mapToItem(lf.contentItem, 0, 0).y, end = Math.max(0, lf.contentHeight - lf.height)
                    if (y < lf.contentY) lf.contentY = Math.max(0, y - 8)
                    else if (y + root.rowH > lf.contentY + lf.height) lf.contentY = Math.min(end, y + root.rowH + 8 - lf.height)
                }
            }
            Flickable {
                id: lf
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                contentHeight: lfCol.height + 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: lfCol
                    width: lf.width

                    Repeater {
                        model: root.sections
                        Column {
                            id: block
                            required property var modelData
                            readonly property var st: root.store(modelData.key)
                            readonly property color ink: root.paint(modelData.color)
                            readonly property int count: st ? st.count : 0
                            readonly property real mem: st ? st.mem : 0
                            readonly property real rxRate: st ? st.rxRate : 0
                            readonly property real txRate: st ? st.txRate : 0
                            width: lfCol.width

                            Item { width: 1; height: 14 }
                            Rectangle {
                                width: parent.width
                                height: Math.round(root.px * 2.5)
                                radius: root.rad
                                color: root.soft
                                Text { x: 12; width: Math.round(root.px * 1.6); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: root.glyph(block.modelData.icon); font.family: root.iconFont; font.pixelSize: root.px + 2; color: block.ink }
                                T { x: 46; anchors.verticalCenter: parent.verticalCenter; text: root.word(block.modelData.key) + " (" + block.count + ")"; font.bold: true }
                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 14
                                    T { width: root.colMem; horizontalAlignment: Text.AlignRight; text: block.mem > 0 ? root.memText(block.mem) : ""; opacity: 0.8 }
                                    T { width: root.colRate; horizontalAlignment: Text.AlignRight; visible: block.rxRate + block.txRate > 0; text: "↓ " + root.speed(block.rxRate); color: root.fall }
                                    T { width: root.colRate; horizontalAlignment: Text.AlignRight; visible: block.rxRate + block.txRate > 0; text: "↑ " + root.speed(block.txRate); color: root.rise }
                                    Item { width: root.colAge; height: 1 }
                                }
                            }
                            Item { width: 1; height: 4 }
                            Item {
                                width: parent.width
                                height: root.rowH
                                visible: block.st === null || block.st.items.count === 0
                                T { x: 46; anchors.verticalCenter: parent.verticalCenter; text: root.word("nothing connected"); opacity: 0.4 }
                            }
                            Repeater {
                                model: block.st ? block.st.items : null
                                Entry { width: block.width; section: block.modelData.key; ink: block.ink }
                            }
                        }
                    }
                }
            }
            Scroller { view: lf }
        }
    }

    Component {
        id: overC

        Item {
            id: map
            readonly property var net: root.store("Internet") ?? root.store("Network")
            readonly property real down: net ? net.rxRate : 0
            readonly property real up: net ? net.txRate : 0
            readonly property real mem: { root.tick; root.storeRev; return root.sections.reduce((a, e) => a + (root.stores[e.key] ? root.stores[e.key].mem : 0), 0) }
            readonly property int most: Math.max(1, Math.round(root.s("connections_Rows")))
            readonly property real line: Math.round(root.px * 2.4)
            readonly property real nodeH: Math.round(root.px * 3.8)
            readonly property real space: Math.round(root.px * 1.1)
            readonly property real pad: 20
            readonly property real hostW: Math.round(root.px * 12)
            readonly property real nodeW: Math.round(root.px * 17)
            readonly property real listW: Math.max(Math.round(root.px * 15), Math.min(Math.round(root.px * 30), width * 0.34))
            readonly property real wire: Math.max(Math.round(root.px * 3), (width - pad * 2 - hostW - nodeW - listW) / 2)
            readonly property real nodeX: pad + hostW + wire
            readonly property real listX: nodeX + nodeW + wire
            readonly property var lines: { root.tick; root.storeRev; const top = most; return root.sections.map(e => { const n = root.stores[e.key] ? root.stores[e.key].count : 0; return Math.min(n, top) + (n > top ? 1 : 0) }) }
            readonly property var talls: lines.map(n => Math.max(nodeH, n * line))
            readonly property real total: talls.reduce((a, h) => a + h, 0) + space * Math.max(0, talls.length - 1)
            readonly property real first: Math.max(pad, (flow.height - total) / 2)
            readonly property var tops: { let y = first; const gap = space; return talls.map(h => { const t = y; y += h + gap; return t }) }
            readonly property real hostY: flow.contentY + flow.height / 2
            readonly property var row: { root.tick; return root.detail ? root.lookup(root.detail.section, root.detail.uid) : null }
            readonly property var seen: row ?? shown
            readonly property var seenPart: seen ? root.part(seen.section) : null
            readonly property color seenInk: seenPart ? root.paint(seenPart.color) : root.hi
            property var shown: null
            property real phase: 0
            onRowChanged: if (row) shown = row

            function rowsOf(key) {
                root.tick
                const st = root.stores[key], out = []
                if (!st) return out
                const m = st.items
                for (let k = 0; k < m.count; k++) {
                    const o = m.get(k)
                    if (!o.gone) out.push({ uid: o.uid, name: root.label(o.name, o.sub), rx: o.rxRate, tx: o.txRate, mem: o.mem })
                }
                out.sort((a, b) => (b.rx + b.tx) - (a.rx + a.tx) || b.mem - a.mem || a.name.localeCompare(b.name))
                return out.slice(0, most)
            }

            function nav(k) {
                const list = []
                root.sections.forEach((e, at) => {
                    const st = root.stores[e.key]
                    if (!st || st.count === 0) return
                    list.push({ section: e.key, uid: "", at: at })
                    for (const r of rowsOf(e.key)) list.push({ section: e.key, uid: r.uid, at: at })
                })
                const n = list.length
                if (!n) return
                let i = root.cur ? list.findIndex(o => o.section === root.cur.section && o.uid === root.cur.uid) : -1
                if (i < 0) i = 0
                else if (k === "enter") { root.pick(list[i].section, list[i].uid); return }
                else if (k === "left") i = list.findIndex(o => o.section === list[i].section)
                else if (k === "right") { if (list[i].uid === "" && i + 1 < n && list[i + 1].section === list[i].section) i++ }
                else i = (i + (k === "down" ? 1 : n - 1)) % n
                root.cur = list[i]
                const y = tops[list[i].at] ?? 0, h = talls[list[i].at] ?? 0, end = Math.max(0, flow.contentHeight - flow.height)
                if (y - pad < flow.contentY) flow.contentY = Math.max(0, y - pad)
                else if (y + h + pad > flow.contentY + flow.height) flow.contentY = Math.min(end, y + h + pad - flow.height)
            }

            NumberAnimation on phase { from: 0; to: 1; duration: 1500; loops: Animation.Infinite; running: root.moving && map.down + map.up > 0 }

            Row {
                id: stats
                x: map.pad
                y: map.pad
                spacing: Math.round(root.px * 0.8)
                Stat { label: "Download"; mark: "↓"; ink: root.fall; value: root.speed(map.down) }
                Stat { label: "Upload"; mark: "↑"; ink: root.rise; value: root.speed(map.up) }
                Stat { label: "Connections"; value: String(root.total) }
                Stat { label: "Memory"; value: root.memText(map.mem) }
            }

            Rectangle {
                id: graph
                readonly property var points: root.history
                readonly property real peak: points.reduce((a, p) => Math.max(a, p[0], p[1]), 1024)
                x: stats.x + stats.width + stats.spacing
                y: stats.y
                width: Math.max(0, map.width - x - map.pad)
                height: stats.height
                visible: width > root.px * 12
                radius: root.rad
                color: root.soft

                function trace(i) {
                    const list = points, n = list.length, w = width - 24, h = height - 30, top = peak
                    if (n < 2) return [Qt.point(12, height - 8), Qt.point(12 + w, height - 8)]
                    const out = []
                    for (let k = 0; k < n; k++) out.push(Qt.point(12 + w * k / (n - 1), height - 8 - h * Math.min(1, list[k][i] / top)))
                    return out
                }

                T { x: 12; y: 6; text: root.word("Traffic"); font.pixelSize: root.px - 3; opacity: 0.55 }
                T { anchors.right: parent.right; anchors.rightMargin: 12; y: 6; text: root.word("peak") + " " + root.speed(graph.peak); font.pixelSize: root.px - 3; opacity: 0.55 }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.fall
                        strokeWidth: 1.5
                        fillColor: "transparent"
                        joinStyle: ShapePath.RoundJoin
                        PathPolyline { path: graph.trace(0) }
                    }
                    ShapePath {
                        strokeColor: root.rise
                        strokeWidth: 1.5
                        fillColor: "transparent"
                        joinStyle: ShapePath.RoundJoin
                        PathPolyline { path: graph.trace(1) }
                    }
                }
            }

            Flickable {
                id: flow
                y: stats.y + stats.height + Math.round(root.px * 0.4)
                width: parent.width
                height: parent.height - y
                contentHeight: Math.max(height, map.total + map.pad * 2)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                MouseArea { width: flow.width; height: flow.contentHeight; onClicked: root.detail = null }

                Repeater {
                    model: root.sections
                    Wire {
                        required property var modelData
                        required property int index
                        readonly property var st: root.store(modelData.key)
                        width: flow.width
                        height: flow.contentHeight
                        fromX: map.pad + map.hostW
                        fromY: map.hostY
                        toX: map.nodeX
                        toY: (map.tops[index] ?? 0) + (map.talls[index] ?? 0) / 2
                        rx: st ? st.rxRate : 0
                        tx: st ? st.txRate : 0
                        ink: root.paint(modelData.color)
                        phase: map.phase
                        opacity: st && st.count > 0 ? 1 : 0.5
                    }
                }

                Repeater {
                    model: root.sections
                    Item {
                        id: blk
                        required property var modelData
                        required property int index
                        readonly property var st: root.store(modelData.key)
                        readonly property color ink: root.paint(modelData.color)
                        readonly property int count: st ? st.count : 0
                        readonly property real rx: st ? st.rxRate : 0
                        readonly property real tx: st ? st.txRate : 0
                        readonly property real tall: map.talls[index] ?? map.nodeH
                        readonly property real mid: (map.tops[index] ?? 0) + tall / 2
                        readonly property var rows: map.rowsOf(modelData.key)
                        readonly property real rowsTop: mid - (map.lines[index] ?? 0) * map.line / 2
                        readonly property bool picked: root.detail !== null && root.detail.section === modelData.key && root.detail.uid === ""
                        width: flow.width
                        height: flow.contentHeight

                        Repeater {
                            model: blk.rows.length
                            Wire {
                                required property int index
                                readonly property var o: blk.rows[index] ?? null
                                width: blk.width
                                height: blk.height
                                fromX: map.nodeX + map.nodeW
                                fromY: blk.mid
                                toX: map.listX
                                toY: blk.rowsTop + index * map.line + map.line / 2
                                rx: o ? o.rx : 0
                                tx: o ? o.tx : 0
                                ink: blk.ink
                                phase: map.phase
                            }
                        }

                        Rectangle {
                            x: map.nodeX
                            y: blk.mid - map.nodeH / 2
                            width: map.nodeW
                            height: map.nodeH
                            radius: root.rad
                            color: blk.picked ? root.glow : nodeArea.containsMouse ? root.softer : root.soft
                            border.width: root.at(blk.modelData.key, "") ? 2 : 0
                            border.color: root.hi
                            Behavior on color { Tint {} }
                            opacity: blk.count > 0 ? 1 : 0.5
                            Rectangle {
                                id: chip
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(root.px * 2.4)
                                height: width
                                radius: width / 2
                                color: Qt.alpha(blk.ink, 0.16)
                                Text { anchors.centerIn: parent; text: root.glyph(blk.modelData.icon); font.family: root.iconFont; font.pixelSize: root.px + 1; color: blk.ink }
                            }
                            Column {
                                x: chip.x + chip.width + 10
                                width: parent.width - x - 10
                                anchors.verticalCenter: parent.verticalCenter
                                T { width: parent.width; elide: Text.ElideRight; text: root.word(blk.modelData.key); font.weight: Font.DemiBold }
                                T {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    font.pixelSize: root.px - 2
                                    opacity: 0.6
                                    text: blk.count === 0 ? root.word("nothing connected")
                                        : blk.count + " " + root.word("connected") + (blk.rx + blk.tx > 0 ? "  ·  ↓ " + root.speed(blk.rx) + "  ↑ " + root.speed(blk.tx) : "")
                                }
                            }
                            MouseArea { id: nodeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pick(blk.modelData.key, "") }
                        }

                        Repeater {
                            model: blk.rows.length
                            Rectangle {
                                id: rw
                                required property int index
                                readonly property var o: blk.rows[index] ?? null
                                readonly property bool busy: !!o && o.rx + o.tx > 0
                                readonly property bool picked: !!o && root.detail !== null && root.detail.section === blk.modelData.key && root.detail.uid === o.uid
                                x: map.listX
                                y: blk.rowsTop + index * map.line + 2
                                width: map.listW
                                height: map.line - 4
                                radius: height / 2
                                color: picked ? root.glow : rwArea.containsMouse ? root.softer : root.soft
                                border.width: !!o && root.at(blk.modelData.key, o.uid) ? 2 : 0
                                border.color: root.hi
                                Behavior on color { Tint {} }
                                Rectangle { x: 11; anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: blk.ink; opacity: rw.busy ? 1 : 0.35 }
                                T { x: 26; width: Math.max(0, rwRate.x - x - 8); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: rw.o ? rw.o.name : "" }
                                T {
                                    id: rwRate
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: root.px - 2
                                    opacity: 0.7
                                    text: !rw.o ? "" : rw.busy ? "↓ " + root.speed(rw.o.rx) + "  ↑ " + root.speed(rw.o.tx) : rw.o.mem > 0 ? root.memText(rw.o.mem) : ""
                                }
                                MouseArea { id: rwArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (rw.o) root.pick(blk.modelData.key, rw.o.uid) }
                            }
                        }

                        T {
                            visible: blk.count > map.most
                            x: map.listX + 26
                            y: blk.rowsTop + blk.rows.length * map.line
                            height: map.line
                            verticalAlignment: Text.AlignVCenter
                            text: "+ " + (blk.count - map.most) + " " + root.word("more")
                            opacity: moreArea.containsMouse ? 1 : 0.55
                            MouseArea { id: moreArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.flip() }
                        }
                    }
                }

                Rectangle {
                    x: map.pad
                    y: map.hostY - height / 2
                    width: map.hostW
                    height: Math.round(root.px * 6.6)
                    radius: root.rad
                    color: root.soft
                    border.width: 1
                    border.color: Qt.alpha(root.core, 0.7)
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 4
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.glyph("f109"); font.family: root.iconFont; font.pixelSize: root.px + 10; color: root.core }
                        T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: root.hostName; font.weight: Font.DemiBold }
                        T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: root.word("this computer"); font.pixelSize: root.px - 2; opacity: 0.6 }
                    }
                }
            }
            Scroller { view: flow }

            T {
                anchors.horizontalCenter: flow.horizontalCenter
                y: flow.y + flow.height - Math.round(root.px * 2.4)
                visible: root.error !== "" || !root.polled
                text: root.error !== "" ? root.error : root.word("Reading…")
                opacity: 0.6
            }

            Rectangle {
                id: card
                readonly property bool up: root.detail !== null
                z: 10
                width: Math.min(Math.round(root.px * 43), map.width * 0.52)
                height: Math.min(map.height - 32, cardCol.height + 32)
                x: up ? map.width - width - 16 : map.width + 8
                y: 16
                radius: root.rad
                color: root.bg
                border.color: root.softer
                border.width: 1
                Behavior on x { NumberAnimation { duration: Motion.time * 2; easing.type: Motion.ease } }

                MouseArea { anchors.fill: parent; onWheel: w => {} }

                Flickable {
                    id: cardFlick
                    x: 16
                    y: 16
                    width: parent.width - 32
                    height: parent.height - 32
                    contentHeight: cardCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: cardCol
                        width: parent.width
                        spacing: 8
                        Item {
                            width: parent.width
                            height: Math.max(cardChip.height, cardHead.height)
                            Rectangle {
                                id: cardChip
                                width: Math.round(root.px * 2.8)
                                height: width
                                radius: width / 2
                                color: Qt.alpha(map.seenInk, 0.16)
                                Text { anchors.centerIn: parent; text: map.seenPart ? root.glyph(map.seenPart.icon) : ""; font.family: root.iconFont; font.pixelSize: root.px + 3; color: map.seenInk }
                            }
                            Column {
                                id: cardHead
                                x: cardChip.width + 12
                                width: parent.width - x - Math.round(root.px * 2)
                                spacing: 2
                                T { width: parent.width; elide: Text.ElideRight; text: map.shown ? root.label(map.shown.name, map.shown.sub) + (map.row ? "" : "  · " + root.word("disconnected")) : ""; font.pixelSize: root.px + 4; font.weight: Font.DemiBold }
                                T { width: parent.width; wrapMode: Text.Wrap; text: map.shown ? root.word(map.shown.section) + "  ·  " + map.shown.summary : ""; opacity: 0.6 }
                            }
                        }
                        FieldList { width: parent.width; keyWidth: Math.round(root.px * 10); rows: root.fields(map.seen) }
                        ProcBox { width: parent.width; owner: map.shown ? map.shown.uid : ""; list: root.procs(map.seen) }
                    }
                }
                Scroller { view: cardFlick }
                Item {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    y: 8
                    width: Math.round(root.px * 2)
                    height: width
                    Rectangle { anchors.fill: parent; radius: width / 2; color: cardShut.hovered ? root.softer : "transparent" }
                    Text { anchors.centerIn: parent; text: root.glyph("f00d"); font.family: root.iconFont; font.pixelSize: root.px; color: root.tx; opacity: cardShut.hovered ? 1 : 0.6 }
                    HoverHandler { id: cardShut; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.detail = null }
                }
            }
        }
    }

    LazyLoader {
        active: root.open && root.s("connections_Show")

        FloatingWindow {
            id: win
            property int mine: -1
            title: "dolphin-connections"
            implicitWidth: Math.max(720, root.keepW > 0 ? root.keepW : Math.round((win.screen?.width ?? 1440) * root.s("connections_Width")))
            implicitHeight: Math.max(480, root.keepH > 0 ? root.keepH : Math.round((win.screen?.height ?? 900) * root.s("connections_Height")))
            color: root.bg
            Component.onCompleted: mine = root.epoch
            onVisibleChanged: if (!visible && mine === root.epoch && !root.hopping) root.open = false
            onWidthChanged: if (visible && width >= 720) root.nowW = Math.round(width)
            onHeightChanged: if (visible && height >= 480) root.nowH = Math.round(height)

            Item {
                id: face
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.back()
                Keys.onPressed: e => {
                    const k = root.arrows[e.key]
                    if (!k || !view.item || typeof view.item.nav !== "function") return
                    root.keys = true
                    view.item.nav(k)
                    e.accepted = true
                }
                Keys.onTabPressed: root.flip()
                Component.onCompleted: forceActiveFocus()

                Item {
                    id: crown
                    x: 20
                    width: parent.width - 40
                    height: Math.round(root.px * 4.4)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.glyph(root.s("connections_Icon")); font.family: root.iconFont; font.pixelSize: root.px + 11; color: root.mark }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.word(root.s("connections_Title")); font.family: root.font; font.pixelSize: root.px + 2; font.weight: Font.DemiBold; font.letterSpacing: 1; color: root.tx }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        T { anchors.verticalCenter: parent.verticalCenter; opacity: 0.6; text: root.hostName + "  ·  " + root.total + " " + root.word("connections") }
                        Pill {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: root.glyph(root.chart ? "f03a" : "f0e8")
                            label: root.chart ? root.word("List view") : root.word("Overview")
                            onTapped: root.flip()
                        }
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(root.px * 2.4)
                            height: width
                            Rectangle { anchors.fill: parent; radius: width / 2; color: shut.hovered ? "#e06c75" : "transparent" }
                            Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: root.px + 1; color: shut.hovered ? "#ffffff" : root.tx }
                            HoverHandler { id: shut }
                            TapHandler { onTapped: root.open = false }
                        }
                    }
                }
                Rectangle {
                    x: 10
                    y: crown.height
                    width: parent.width - 20
                    height: foot.y - y
                    radius: root.rad * 1.6
                    color: root.pane
                }
                NumberAnimation { id: rise; target: view; property: "opacity"; from: 0; to: 1; duration: Motion.time * 2; easing.type: Motion.ease }
                Loader {
                    id: view
                    onLoaded: rise.restart()
                    x: 10
                    y: crown.height
                    width: parent.width - 20
                    height: foot.y - y
                    clip: true
                    sourceComponent: root.chart ? overC : listC
                }

                Item {
                    id: foot
                    x: 20
                    y: parent.height - height
                    width: parent.width - 40
                    height: Math.round(root.px * 2.6)
                    T {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - footNote.implicitWidth - 20
                        elide: Text.ElideRight
                        opacity: 0.5
                        text: root.error !== "" && !root.chart ? root.error : root.chart
                            ? root.word("click a group or a connection for details")
                            : root.word("click a row for details") + "  ·  " + root.word("process bandwidth counts TCP only")
                    }
                    T { id: footNote; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; opacity: 0.5; text: root.word("updates every") + " " + Math.max(500, root.s("connections_Interval")) / 1000 + " s  ·  Tab: " + (root.chart ? root.word("List view") : root.word("Overview")) }
                }
            }
        }
    }
}
