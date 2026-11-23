import QtQuick
import Quickshell.Bluetooth as Bt
import "../../../../Backend"

Widget {
    id: bt
    key: "bluetooth"
    icon: glyph(powered ? s("Icon") : "f00b2")
    lit: powered
    label: linked.length > 1 ? "..." : linked.length ? "\"" + linked[0].name + "\"" : ""
    len: along(mark)

    readonly property var ad: Bt.Bluetooth.defaultAdapter
    readonly property bool powered: !!ad && ad.enabled
    readonly property var linked: ad ? ad.devices.values.filter(d => d.connected) : []
    property var since: ({})

    onLinkedChanged: {
        const n = {}
        for (const d of linked) n[d.dbusPath] = since[d.dbusPath] ?? stamp()
        since = n
    }

    Icon {
        id: mark
        anchors.centerIn: parent
        source: bt.icon
        family: bt.iconFont
        size: bt.unit * 0.5
        color: bt.ink
    }

    page: Component {
        Parts.Section {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open

            readonly property var ad: bt.ad
            readonly property bool powered: bt.powered
            readonly property var devs: ad ? ad.devices.values.filter(d => d.deviceName || d.paired || d.connected).sort((a, b) => b.connected - a.connected || b.paired - a.paired) : []
            readonly property string time: opened ? bt.dur((now - (bt.since[opened.dbusPath] ?? now)) / 1000, 1) : ""
            readonly property color bad: "#e06c75"
            property real now: bt.stamp()
            property var sel: null
            property var opened: null
            property var pairing: null
            property var trying: null
            property var failed: null
            property bool seen: false
            title: "Bluetooth"
            on: powered
            marked: keyed && !detailed && cur === 0

            readonly property bool keyed: parent.keyed
            readonly property bool detailed: !!sel
            readonly property var acts: ["back", "auto", "off", "forget"]
            readonly property string act: keyed && detailed ? acts[spot % acts.length] : ""
            property int cur: 0
            property int spot: 0

            function key(k) {
                if (detailed) {
                    const n = acts.length
                    if (k === "back") back()
                    else if (k === "up" || k === "left") spot = (spot + n - 1) % n
                    else if (k === "down" || k === "right") spot = (spot + 1) % n
                    else if (k === "enter") {
                        const a = acts[spot % n]
                        if (a === "back" || !opened) { back(); return true }
                        if (a === "auto") opened.trusted = !opened.trusted
                        else if (a === "off") opened.disconnect()
                        else { opened.forget(); back() }
                    } else return false
                    detailView.contentY = spot % n < 2 ? 0 : Math.max(0, detailView.contentHeight - detailView.height)
                    return true
                }
                const n = devs.length + 1
                if (cur >= n) cur = n - 1
                if (k === "up") cur = (cur + n - 1) % n
                else if (k === "down") cur = (cur + 1) % n
                else if (k === "enter") {
                    const it = devs[cur - 1]
                    if (cur === 0) toggled()
                    else if (it) it.connected ? sel = it : pick(it)
                } else return false
                return true
            }
            onToggled: if (ad) ad.enabled = !ad.enabled

            function back() { sel = null }
            function scan() { if (powered) ad.discovering = active }
            function attempt(d) { trying = d; seen = false; failed = null; giveUp.restart() }
            function settle(d) { trying = null; giveUp.stop(); failed = d; if (d) failClear.restart() }
            function pick(d) {
                if (d.connected) return d.disconnect()
                attempt(d)
                if (d.paired) d.connect()
                else { pairing = d; d.trusted = true; d.pair() }
            }
            onActiveChanged: scan()
            onPoweredChanged: scan()
            onSelChanged: { spot = 0; if (sel) opened = sel }

            Timer { interval: 1000; running: page.active && !!page.sel; repeat: true; triggeredOnStart: true; onTriggered: page.now = bt.stamp() }
            Timer { id: giveUp; interval: 20000; onTriggered: if (page.trying) page.settle(page.trying.connected ? null : page.trying) }
            Timer { id: pairCheck; interval: 600; onTriggered: if (page.trying && !page.trying.pairing && !page.trying.paired && !page.trying.connected) page.settle(page.trying) }
            Timer { id: failClear; interval: 5000; onTriggered: page.failed = null }

            Connections {
                target: page.pairing
                function onPairedChanged() { if (page.pairing.paired) { if (!page.pairing.connected) page.pairing.connect(); page.pairing = null } }
            }
            Connections {
                target: page.trying
                function onStateChanged() {
                    const d = page.trying
                    if (d.state === Bt.BluetoothDeviceState.Connecting) page.seen = true
                    else if (d.state === Bt.BluetoothDeviceState.Connected) page.settle(null)
                    else if (page.seen && d.state === Bt.BluetoothDeviceState.Disconnected) page.settle(d)
                }
                function onPairingChanged() { if (!page.trying.pairing) pairCheck.restart() }
            }
            Connections {
                target: page.sel
                function onConnectedChanged() { if (!page.sel.connected) page.back() }
            }

            Item {
                width: parent.width; height: page.room

                ListView {
                    id: scrollList
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: page.sel ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }
                    model: page.devs
                    currentIndex: page.cur - 1
                    onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool failed: page.failed === modelData
                        readonly property string status: modelData.pairing ? "Pairing…"
                            : modelData.state === Bt.BluetoothDeviceState.Connecting || page.trying === modelData ? "Connecting…"
                            : modelData.state === Bt.BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                            : failed ? "Connection failed"
                            : modelData.connected ? "Connected"
                            : modelData.paired ? "Paired" : ""
                        readonly property color tint: failed ? page.bad : modelData.connected ? page.c.active : page.c.text
                        width: ListView.view.width; height: page.unit * page.c.rowH

                        Rectangle {
                            visible: page.keyed && !page.detailed && page.cur === row.index + 1
                            anchors.fill: parent
                            radius: height / 2
                            color: "transparent"
                            border.width: 2
                            border.color: page.c.active
                        }
                        Text {
                            id: note
                            anchors.right: gear.visible ? gear.left : parent.right
                            anchors.rightMargin: gear.visible ? page.unit * 0.15 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: bt.t(row.status)
                            opacity: row.failed ? 1 : 0.6
                            color: row.failed ? page.bad : page.c.text
                            font.family: page.c.font2; font.pixelSize: page.unit * page.c.infoSize
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.right: note.left; anchors.rightMargin: page.unit * 0.25
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.name + (row.modelData.batteryAvailable ? "  " + Math.round(row.modelData.battery * 100) + "%" : "")
                            elide: Text.ElideRight; opacity: row.modelData.paired || row.failed ? 1 : 0.6
                            color: row.tint
                            font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                            TapHandler { onTapped: page.pick(row.modelData) }
                        }
                        Parts.Btn {
                            id: gear
                            visible: row.modelData.connected
                            round: true
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xf0493); textColor: page.c.text; size: page.c.iconSmall
                            c: page.c; unit: page.unit
                            onClicked: page.sel = row.modelData
                        }
                    }
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
                    opacity: page.sel ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic } }

                    Column {
                        id: detailCol
                        x: page.unit * 0.35
                        width: detailView.width - page.unit * 0.7
                        spacing: page.unit * 0.2

                        Parts.Head { name: page.opened ? page.opened.name : ""; marked: page.act === "back"; c: page.c; unit: page.unit; onBack: page.back() }
                        Parts.Toggle { label: "Auto reconnect"; marked: page.act === "auto"; on: !!page.opened && page.opened.trusted; c: page.c; unit: page.unit; onToggled: page.opened.trusted = !page.opened.trusted }
                        Parts.Info { key: "Connected for"; value: page.time; c: page.c; unit: page.unit }
                        Repeater {
                            model: page.opened ? [["Device", page.opened.deviceName], ["Battery", page.opened.batteryAvailable ? Math.round(page.opened.battery * 100) + "%" : "—"], ["Paired", bt.t(page.opened.paired ? "yes" : "no")], ["Bonded", bt.t(page.opened.bonded ? "yes" : "no")]] : []
                            Parts.Info { required property var modelData; key: modelData[0]; value: modelData[1]; c: page.c; unit: page.unit }
                        }
                        Flow {
                            x: -page.unit * page.c.btnPad
                            width: parent.width + page.unit * page.c.btnPad
                            Parts.Btn { text: "Disconnect"; marked: page.act === "off"; c: page.c; unit: page.unit; onClicked: page.opened.disconnect() }
                            Parts.Btn { text: "Forget"; marked: page.act === "forget"; c: page.c; unit: page.unit; onClicked: { page.opened.forget(); page.back() } }
                        }
                    }
                }
                Scroller { view: detailView; visible: detailView.visible }
            }
        }
    }
}
