import QtQuick
import Quickshell.Io
import "../../../../Backend"

Widget {
    id: net
    key: "network"
    icon: statusIcon
    lit: on
    label: online && ssid ? "\"" + ssid + "\"" : ""
    len: along(bars)

    property bool online: false
    property bool powered: false
    property real level: 0
    property string ssid: ""
    property real since: 0
    readonly property bool savedMs: s("TitleMs") === true
    property bool ms: savedMs
    onSavedMsChanged: ms = savedMs
    function flipMs() {
        ms = !ms
        bar.save("widget_NetworkTitleMs", ms)
    }
    readonly property bool on: powered || online
    readonly property string statusIcon: !on ? glyph("f092e") : !online ? glyph("f092f") : strength(level)

    function strength(dbm) {
        if (!(dbm < 0)) return glyph("f092f")
        return glyph(dbm >= -55 ? "f0928" : dbm >= -67 ? "f0925" : dbm >= -75 ? "f0922" : "f091f")
    }
    function readSignal(t) {
        const line = t.split("\n").find(l => l.trim().startsWith(s("Interface") + ":"))
        const f = line ? line.trim().split(/\s+/) : []
        level = parseFloat(f[3]) || 0
        online = !!(parseFloat(f[2]) || 0)
    }
    function poll() { wireless.reload(); flags.reload() }

    onOnlineChanged: { since = online ? stamp() : 0; ssidProc.running = true }

    FileView { id: wireless; path: "/proc/net/wireless"; printErrors: false; onLoaded: net.readSignal(wireless.text()) }
    FileView { id: flags; path: "/sys/class/net/" + net.s("Interface") + "/flags"; printErrors: false; onLoaded: net.powered = (parseInt(flags.text()) & 1) === 1; onLoadFailed: net.powered = false }
    Timer { interval: net.picked ? 1000 : 5000; running: true; repeat: true; onTriggered: net.poll() }
    Process {
        id: ssidProc
        command: ["iwctl", "station", net.s("Interface"), "show"]
        stdout: StdioCollector { onStreamFinished: { const m = text.match(/Connected network\s+(.+)/); net.ssid = m ? m[1].trim() : "" } }
    }

    Icon {
        id: bars
        anchors.centerIn: parent
        source: net.statusIcon
        family: net.iconFont
        size: net.unit * 0.5
        color: net.ink
    }

    banner: Component {
        Item {
            id: crown
            readonly property var c: parent.c
            readonly property real unit: parent.unit
            readonly property bool open: parent.open
            readonly property real up: up0 + (tick - t0) / 1000
            property real up0: 0
            property real t0: 0
            property real tick: net.stamp()
            readonly property bool exact: net.ms

            readonly property real big: net.s("TitleScale") ?? 1.3

            implicitHeight: unit * 0.8 * big
            onOpenChanged: if (open) uptime.reload()

            FileView { id: uptime; path: "/proc/uptime"; onLoaded: { crown.up0 = parseFloat(uptime.text()) || 0; crown.t0 = net.stamp(); crown.tick = crown.t0 } }
            Timer { interval: crown.exact ? 50 : 1000; running: crown.open; repeat: true; onTriggered: crown.tick = net.stamp() }

            Icon {
                id: cat
                anchors.verticalCenter: parent.verticalCenter
                source: String.fromCodePoint(0xf011b)
                family: crown.c.font
                size: crown.unit * 0.6 * crown.big * (net.s("TitleIconScale") ?? 1)
                color: crown.c.text
            }
            Text {
                anchors.left: cat.right
                anchors.leftMargin: crown.unit * 0.25 * crown.big
                anchors.verticalCenter: parent.verticalCenter
                text: net.t("Uptime") + ": " + net.dur(crown.up, crown.exact ? 2 : 0)
                color: crown.c.text; font.family: crown.c.font2; font.pixelSize: crown.unit * 0.4 * crown.big
            }
            MouseArea { anchors.fill: parent; onPressed: net.flipMs() }
        }
    }

    page: Component {
        Parts.Section {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open

            readonly property string iface: net.s("Interface")
            readonly property string time: net.since ? net.dur((now - net.since) / 1000, 1) : ""
            readonly property color bad: "#e06c75"
            property real now: net.stamp()
            property bool powered: false
            property var nets: []
            property var known: []
            property var info: []
            property string ask: ""
            property string sel: ""
            property string opened: ""
            property string busy: ""
            property string doing: ""
            property string failed: ""
            property bool auto: false
            property bool ready: false
            property string last: ""
            property bool scanning: false
            title: "Wi-Fi"
            on: powered
            marked: keyed && !detailed && cur === 0

            readonly property bool keyed: parent.keyed
            readonly property bool typing: ask !== ""
            readonly property bool detailed: !!sel && ready
            readonly property var acts: known.includes(opened) ? ["back", "auto", "off", "forget"] : ["back", "off", "forget"]
            readonly property string act: keyed && detailed ? acts[spot % acts.length] : ""
            property int cur: 0
            property int spot: 0
            onAskChanged: if (!ask) parent.refocus()

            function flipAuto() {
                run(["iwctl", "known-networks", opened, "set-property", "AutoConnect", auto ? "no" : "yes"])
                auto = !auto
            }
            function key(k) {
                if (ask) return true
                if (detailed) {
                    const n = acts.length
                    if (k === "back") back()
                    else if (k === "up" || k === "left") spot = (spot + n - 1) % n
                    else if (k === "down" || k === "right") spot = (spot + 1) % n
                    else if (k === "enter") {
                        const a = acts[spot % n]
                        if (a === "back") back()
                        else if (a === "auto") flipAuto()
                        else if (a === "off") run(["iwctl", "station", iface, "disconnect"])
                        else run(["iwctl", "known-networks", opened, "forget"])
                    } else return false
                    detailView.contentY = spot % n < 2 ? 0 : Math.max(0, detailView.contentHeight - detailView.height)
                    return true
                }
                const n = nets.length + 1
                if (cur >= n) cur = n - 1
                if (k === "up") cur = (cur + n - 1) % n
                else if (k === "down") cur = (cur + 1) % n
                else if (k === "enter") {
                    const it = nets[cur - 1]
                    if (cur === 0) toggled()
                    else if (it) it.on ? sel = it.name : pick(it)
                } else return false
                return true
            }
            onToggled: run(["iwctl", "device", iface, "set-property", "Powered", powered ? "off" : "on"])

            function rows(t) {
                const out = []; let d = 0
                for (const l of t.replace(/\x1b\[[0-9;]*m/g, "").split("\n")) {
                    if (/^\s*-{10,}\s*$/.test(l)) d++
                    else if (d >= 2 && l.trim()) out.push({ on: /^\s*>/.test(l), p: l.replace(/^\s*>?\s*/, "").trim().split(/\s{2,}/) })
                }
                return out
            }
            function parse(t) {
                if (t === last) return
                last = t
                const part = t.split("@@")
                powered = /Powered\s+on/.test(part[0])
                nets = rows(part[1] || "").map(r => {
                    const d = parseInt(r.p[r.p.length - 1])
                    return { name: r.p[0], sec: r.p[1], dbm: d < -200 ? d / 100 : d, on: r.on }
                }).sort((a, b) => b.on - a.on || b.dbm - a.dbm)
                known = rows(part[2] || "").map(r => r.p[0])
                sync(nets)
                if (sel && !nets.some(n => n.on && n.name === sel)) sel = ""
            }
            function sync(list) {
                for (let i = found.count - 1; i >= 0; i--) {
                    const have = found.get(i).name
                    if (!list.some(n => n.name === have)) found.remove(i)
                }
                list.forEach((n, i) => {
                    const entry = { name: String(n.name), sec: String(n.sec ?? ""), dbm: Number(n.dbm) || -100, live: !!n.on }
                    let at = -1
                    for (let j = i; j < found.count; j++) if (found.get(j).name === entry.name) { at = j; break }
                    if (at < 0) found.insert(Math.min(i, found.count), entry)
                    else {
                        if (at !== i) found.move(at, i, 1)
                        found.set(i, entry)
                    }
                })
                while (found.count > list.length) found.remove(found.count - 1)
            }
            function rescan() {
                if (scan.running || !powered) return
                scanning = true
                scan.running = true
                lull.restart()
            }
            function bars(d) { return String.fromCodePoint(d >= -55 ? 0xf0928 : d >= -67 ? 0xf0925 : d >= -75 ? 0xf0922 : 0xf091f) }
            function back() { sel = ""; ask = "" }
            function run(cmd, name, verb) {
                if (act.running) return
                busy = name ?? ""
                doing = verb ?? ""
                if (name) failed = ""
                act.command = cmd
                act.running = true
            }
            function refresh() {
                if (ask) return
                get.running = true
                if (sel) loadDetail()
            }
            function loadDetail() {
                if (detail.running) return
                detail.command = ["sh", "-c", "iwctl station \"$0\" show; echo @@; iwctl known-networks \"$1\" show", iface, sel]
                detail.running = true
            }
            function pick(n) {
                if (n.on) return run(["iwctl", "station", iface, "disconnect"], n.name, "Disconnecting…")
                if (n.sec !== "open" && !known.includes(n.name)) return ask = n.name
                run(["iwctl", "station", iface, "connect", n.name], n.name, "Connecting…")
            }

            Process {
                id: get
                command: ["sh", "-c", `iwctl device ${page.iface} show; echo @@; iwctl station ${page.iface} get-networks rssi-dbms; echo @@; iwctl known-networks list`]
                stdout: StdioCollector { onStreamFinished: page.parse(text) }
            }
            Process {
                id: detail
                onExited: if (page.sel && command[4] !== page.sel) page.loadDetail()
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (detail.command[4] !== page.sel) return
                        const part = text.split("@@")
                        page.info = page.rows(part[0]).map(r => r.p).filter(p => p.length > 1 && !/Scanning|Connected network|MCS/.test(p[0]))
                        page.auto = /AutoConnect\s+yes/.test(part[1] || "")
                        page.ready = true
                    }
                }
            }
            ListModel { id: found }
            Process { id: scan; command: ["iwctl", "station", page.iface, "scan"] }
            Timer { id: lull; interval: 2500; onTriggered: { page.scanning = false; page.last = ""; page.refresh() } }
            Process {
                id: act
                onExited: (code, status) => {
                    if (code !== 0 && page.doing === "Connecting…") { page.failed = page.busy; failClear.restart() }
                    page.busy = ""
                    page.doing = ""
                    page.last = ""
                    page.refresh()
                    net.poll()
                }
            }
            Timer { id: failClear; interval: 5000; onTriggered: page.failed = "" }
            Timer { interval: 3000; running: page.active; repeat: true; triggeredOnStart: true; onTriggered: page.refresh() }
            Timer { interval: 1000; running: page.active && !!page.sel; repeat: true; triggeredOnStart: true; onTriggered: page.now = net.stamp() }
            onActiveChanged: if (active) { scan.running = true; scanning = powered; lull.restart() }
            onOpenChanged: if (open) ssidProc.running = true
            onSelChanged: { spot = 0; if (!sel) return; ready = false; opened = sel; loadDetail() }

            Item {
                width: parent.width; height: page.room

                ListView {
                    id: scrollList
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: page.sel && page.ready ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }
                    model: found
                    currentIndex: page.cur - 1
                    onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }
                    remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }
                    move: Transition { NumberAnimation { property: "y"; duration: Motion.span(page.c.glide); easing.type: Easing.OutCubic } }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: Motion.span(page.c.glide); easing.type: Easing.OutCubic }
                        NumberAnimation { property: "opacity"; to: 1; duration: Motion.span(page.c.fade) }
                    }
                    delegate: Item {
                        id: row
                        required property int index
                        required property string name
                        required property string sec
                        required property real dbm
                        required property bool live
                        readonly property var item: ({ name: name, sec: sec, dbm: dbm, on: live })
                        readonly property bool asking: page.ask === name
                        readonly property bool failed: page.failed === name
                        readonly property bool working: page.busy === name
                        readonly property bool saved: page.known.includes(name)
                        readonly property string status: working ? page.doing : failed ? "Connection failed" : ""
                        readonly property color tint: failed ? page.bad : live ? page.c.active : page.c.text
                        readonly property real line: page.unit * page.c.rowH
                        function send() {
                            if (pass.text === "") return
                            page.run(["iwctl", "--passphrase", pass.text, "station", page.iface, "connect", row.name], row.name, "Connecting…")
                            page.ask = ""
                        }
                        width: ListView.view.width
                        height: line * (asking ? 1.9 : 1)
                        clip: true
                        onAskingChanged: if (asking) pass.text = ""
                        Behavior on height { NumberAnimation { duration: Motion.span(page.c.glide); easing.type: Easing.OutCubic } }

                        HoverHandler { id: over }
                        Rectangle {
                            anchors.fill: parent
                            radius: row.line / 2
                            color: page.c.text
                            opacity: row.asking || over.hovered ? 0.05 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }
                        }
                        Rectangle {
                            visible: page.keyed && !page.detailed && page.cur === row.index + 1
                            anchors.fill: parent
                            radius: row.line / 2
                            color: "transparent"
                            border.width: 2
                            border.color: page.c.active
                        }
                        Item {
                            width: parent.width
                            height: row.line
                            MouseArea { anchors.fill: parent; onClicked: page.pick(row.item) }
                            Icon {
                                id: sig
                                x: (page.unit * 0.7 - width) / 2
                                anchors.verticalCenter: parent.verticalCenter
                                source: page.bars(row.dbm); color: row.tint
                                family: page.c.font; size: page.unit * page.c.iconSmall
                            }
                            SequentialAnimation {
                                running: row.working && Motion.on
                                loops: Animation.Infinite
                                onStopped: sig.opacity = 1
                                NumberAnimation { target: sig; property: "opacity"; to: 0.25; duration: Motion.span(420); easing.type: Easing.InOutSine }
                                NumberAnimation { target: sig; property: "opacity"; to: 1; duration: Motion.span(420); easing.type: Easing.InOutSine }
                            }
                            Row {
                                id: side
                                anchors.right: parent.right
                                anchors.rightMargin: gear.visible ? 0 : page.unit * 0.3
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: page.unit * 0.15
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: net.t(row.status)
                                    opacity: row.failed ? 1 : 0.6
                                    color: row.failed ? page.bad : page.c.text
                                    font.family: page.c.font2; font.pixelSize: page.unit * page.c.infoSize
                                }
                                Icon {
                                    visible: row.sec !== "open" && !row.saved && !row.live && row.status === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: String.fromCodePoint(0xf033e); color: page.c.text; opacity: 0.3
                                    family: page.c.font; size: page.unit * page.c.iconSmall * 0.7
                                }
                                Parts.Btn {
                                    id: gear
                                    visible: row.live
                                    opacity: over.hovered || (page.keyed && page.cur === row.index + 1) ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade) } }
                                    round: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: String.fromCodePoint(0xf0493); textColor: page.c.text; size: page.c.iconSmall
                                    c: page.c; unit: page.unit
                                    onClicked: page.sel = row.name
                                }
                            }
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: page.unit * 0.8
                                anchors.right: side.left; anchors.rightMargin: page.unit * 0.25
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.name
                                elide: Text.ElideRight; color: row.tint
                                font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                                Behavior on color { ColorAnimation { duration: Motion.span(page.c.fade) } }
                            }
                        }
                        Item {
                            y: row.line
                            width: parent.width
                            height: row.height - row.line
                            opacity: row.asking ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }
                            Parts.Btn {
                                id: send
                                round: true
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: String.fromCodePoint(0xf0054); textColor: page.c.active; size: page.c.iconSmall
                                c: page.c; unit: page.unit
                                opacity: pass.text === "" ? 0.35 : 1
                                onClicked: row.send()
                            }
                            TextInput {
                                id: pass
                                anchors.left: parent.left; anchors.leftMargin: page.unit * 0.8
                                anchors.right: send.left; anchors.rightMargin: page.unit * 0.15
                                anchors.verticalCenter: parent.verticalCenter
                                clip: true
                                echoMode: TextInput.Password
                                color: page.c.text
                                font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                                onVisibleChanged: if (visible && row.asking) forceActiveFocus()
                                onAccepted: row.send()
                                Keys.onEscapePressed: page.ask = ""
                                Text { visible: pass.text === ""; text: net.t("Password"); opacity: 0.4; color: page.c.text; font: pass.font }
                                Rectangle { anchors.top: parent.bottom; anchors.topMargin: 2; width: parent.width; height: 1; color: page.c.active; opacity: pass.activeFocus ? 1 : 0.4 }
                            }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: opacity > 0
                    opacity: found.count === 0 && !page.sel ? 0.5 : 0
                    text: net.t(page.powered ? "Searching…" : "Wi-Fi is off")
                    color: page.c.text
                    font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade) } }
                }
                Scroller { view: scrollList; visible: scrollList.visible }

                Flickable {
                    id: detailView
                    anchors.fill: parent
                    anchors.leftMargin: -page.unit * 0.35
                    anchors.rightMargin: -page.unit * 0.35
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: detailCol.height
                    opacity: page.sel && page.ready ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }

                    Column {
                        id: detailCol
                        x: page.unit * 0.35
                        width: detailView.width - page.unit * 0.7
                        spacing: page.unit * 0.2

                        Parts.Head { name: page.opened; marked: page.act === "back"; c: page.c; unit: page.unit; onBack: page.back() }
                        Parts.Toggle {
                            visible: page.known.includes(page.opened)
                            label: "Auto reconnect"; on: page.auto; c: page.c; unit: page.unit
                            marked: page.act === "auto"
                            onToggled: page.flipAuto()
                        }
                        Parts.Info { visible: !!page.time; key: "Connected for"; value: page.time; c: page.c; unit: page.unit }
                        Repeater {
                            model: page.info
                            Parts.Info { required property var modelData; key: modelData[0]; value: modelData[1]; c: page.c; unit: page.unit }
                        }
                        Flow {
                            x: -page.unit * page.c.btnPad
                            width: parent.width + page.unit * page.c.btnPad
                            Parts.Btn { text: "Disconnect"; marked: page.act === "off"; c: page.c; unit: page.unit; onClicked: page.run(["iwctl", "station", page.iface, "disconnect"]) }
                            Parts.Btn { text: "Forget"; marked: page.act === "forget"; c: page.c; unit: page.unit; onClicked: page.run(["iwctl", "known-networks", page.opened, "forget"]) }
                        }
                    }
                }
                Scroller { view: detailView; visible: detailView.visible }
            }
        }
    }
}
