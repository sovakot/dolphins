import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../Backend"

Kit {
    id: root

    required property var bar
    required property var panel

    base: ({
        updater_Show: true, updater_Icon: "f233", updater_IconSize: 0.022, updater_TextSize: 13,
        updater_Width: 0.26, updater_Height: 0.5, updater_Color: "#000000", updater_TextColor: "#ffffff", updater_AlertColor: "#ff3b3b", updater_HoverColor: "Active", updater_HoverTime: 1000, updater_Margin: 8,
        updater_FixWidth: 0.32, updater_ChangeColor: "#00ff00",
        updater_Delay: 3000, updater_Interval: 0, updater_Ignored: []
    })

    readonly property string script: decodeURIComponent(Qt.resolvedUrl("Check.sh").toString().replace(/^file:\/\//, ""))
    readonly property string home: script.replace(/(\/[^\/]+){4}$/, "")
    readonly property var ignored: s("updater_Ignored")
    readonly property var all: (crash === "" ? [] : [{ id: "reload", title: "Dolphin could not reload", detail: crash, steps: "1. Read the file name and line number in the message.\n2. Open that file and fix the line.\n3. Save. Dolphin reloads by itself.", tag: "", cmd: "" }]).concat(Faults.list).concat(issues)
    readonly property var live: all.filter(i => !ignored.includes(i.id))
    readonly property bool alert: live.length > 0
    readonly property string watch: ["widget_NetworkInterface", "dolphin_TextFont", "dolphin_IconFont", "dolphin_Background", "dolphin_Lockscreen", "dolphin_ThemeBackground",
        "greeter_Avatar", "lockscreen_Pam", "touchpad_Show", "widget_NetworkShow", "widget_BluetoothShow", "widget_BatteryShow", "widget_BrightnessShow",
        "widget_KeyboardShow", "widget_NightShow", "widget_NotificationShow"].map(k => String(cfg?.[k])).join("|")
    property var issues: []
    property string crash: ""
    property var target: null
    property int pick: 0
    property bool checked: false
    property bool open: false
    property bool keyed: false
    property string wide: ""
    property int sel: 0
    property int over: -1

    onWatchChanged: if (checked) soon.restart()
    onOpenChanged: { over = -1; keyed = false; target = null; if (open) check() }

    function check() { if (!scan.running) scan.running = true }
    function take(text) {
        const lines = text.split("\n").filter(l => l !== "")
        if (lines[lines.length - 1] !== "@ok") return
        issues = lines.slice(0, -1).map(l => {
            const p = l.split("\t")
            return { id: p[0] ?? "", title: p[1] ?? "", detail: (p[2] ?? "").replace(/\\n/g, "\n"), steps: (p[3] ?? "").replace(/\\n/g, "\n"), tag: p[4] ?? "", cmd: p[5] ?? "" }
        }).filter(i => i.id !== "")
        checked = true
        const keep = ignored.filter(id => all.some(i => i.id === id))
        if (keep.length !== ignored.length) save("updater_Ignored", keep)
        if (sel >= live.length) sel = Math.max(0, live.length - 1)
        if (target && !live.some(i => i.id === target.id)) target = null
    }
    function ignore(id) { if (!ignored.includes(id)) save("updater_Ignored", ignored.concat([id])) }
    function ignoreAll() {
        if (live.length) save("updater_Ignored", ignored.concat(live.map(i => i.id)))
        open = false
    }
    function fix(i) {
        if (!i || !i.cmd || act.running) return
        if (i.cmd.startsWith("set:")) {
            const at = i.cmd.indexOf("="), raw = i.cmd.slice(at + 1)
            let v = raw
            try { v = JSON.parse(raw) } catch (e) {}
            save(i.cmd.slice(4, at), v)
            soon.restart()
            return
        }
        act.command = ["sh", "-c", i.cmd]
        act.running = true
    }
    function step(d) {
        const n = live.length
        keyed = true
        if (n) sel = (sel + d + n) % n
    }
    function flip(id) { wide = wide === id ? "" : id }
    function mend(i) { if (i) { pick = 0; target = i } }
    function confirm() { const i = target; target = null; if (i && i.tag !== "") fix(i) }

    Connections {
        target: Quickshell
        function onReloadFailed(error) { root.crash = "The files on disk have a mistake, so Dolphin kept running the last working version.\n" + String(error).replace(/qs:@\/qs\//g, "").trim() }
    }

    GlobalShortcut { appid: "updater"; name: "toggle"; onPressed: root.open = !root.open }

    IpcHandler {
        target: "updater"
        function check(): void { root.check() }
        function toggle(): void { root.open = !root.open }
    }

    Process {
        id: scan
        command: ["sh", root.script, root.home]
        stdout: StdioCollector {
            onStreamFinished: root.take(text)
        }
    }
    Process { id: act; onExited: root.check() }
    Process {
        id: mirror
        running: true
        command: ["sh", "-c", "grep -qsF \"$3\" \"$1\" && { [ ! -e \"$2\" ] || [ \"$1\" -nt \"$2\" ]; } && ! cmp -s \"$1\" \"$2\" && cp -f \"$1\" \"$2\"; true", "mirror", (Quickshell.env("XDG_CONFIG_HOME") || String(Quickshell.env("HOME") ?? "") + "/.config") + "/hypr/hyprland.lua", root.home + "/hyprland.lua", root.home.replace(/^.*\//, "") + "/Dolphin.qml"]
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded" && !mirror.running) mirror.running = true }
    }
    Timer { id: soon; interval: 1500; onTriggered: root.check() }
    Timer { interval: Math.max(500, root.s("updater_Delay")); running: true; onTriggered: root.check() }
    Timer { interval: Math.max(1, root.s("updater_Interval")) * 60000; repeat: true; running: root.s("updater_Interval") > 0; onTriggered: root.check() }

    LazyLoader {
        active: root.s("updater_Show") && (root.alert || root.open)

        PanelWindow {
            id: win
            readonly property color fg: root.col(root.s("updater_TextColor"))
            readonly property color bg: root.col(root.s("updater_Color"))
            readonly property real px: Math.max(8, root.s("updater_TextSize"))
            readonly property real rowH: Math.round(px * 2)
            readonly property real ink: Math.round(height * root.s("updater_IconSize") / 2) * 2
            readonly property real inX: root.bar.pos === "right" ? Math.round(root.bar.shown * root.bar.present * (root.bar.gap + root.bar.thick)) : 0
            readonly property real inY: root.bar.pos === "bottom" ? Math.round(root.bar.shown * root.bar.present * (root.bar.gap + root.bar.thick)) : 0
            readonly property real edge: Math.max(0, Math.round(root.s("updater_Margin")))
            readonly property real homeX: width - badge.width - inX - edge
            readonly property real homeY: height - badge.height - inY - edge
            readonly property rect pa: root.panel.area
            readonly property bool hit: pa.width > 0 && homeX < pa.x + pa.width && homeX + badge.width > pa.x && homeY < pa.y + pa.height && homeY + badge.height > pa.y
            readonly property bool roomLeft: pa.x - badge.width >= 0

            screen: root.bar.screen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "dolphin-updater"
            WlrLayershell.keyboardFocus: root.open && (inside.hovered || within.hovered) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"
            mask: Region { item: root.open ? box : badge; Region { item: hole } }

            Item {
                id: face
                anchors.fill: parent
                opacity: Reveal.glass
                focus: true
                Keys.onPressed: e => {
                    if (root.target) {
                        if (e.key === Qt.Key_Escape) root.target = null
                        else if (e.key === Qt.Key_Left || e.key === Qt.Key_Right) { root.keyed = true; if (root.target.tag !== "") root.pick = 1 - root.pick }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (root.keyed && root.pick === 1 && root.target.tag !== "") root.confirm(); else root.target = null }
                        else return
                        e.accepted = true
                        return
                    }
                    if (e.key === Qt.Key_Escape) root.open = false
                    else if (e.key === Qt.Key_Right) { root.keyed = true; root.mend(root.live[root.sel]) }
                    else if (e.key === Qt.Key_Up) root.step(-1)
                    else if (e.key === Qt.Key_Down) root.step(1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { const i = root.live[root.sel]; if (i) { root.keyed = true; root.flip(i.id) } }
                    else return
                    e.accepted = true
                }
                Connections { target: root; function onOpenChanged() { if (root.open) face.forceActiveFocus() } }
                Component.onCompleted: if (root.open) forceActiveFocus()

                Item {
                    id: badge
                    visible: root.alert && !root.open
                    width: Math.round(win.ink * 2.4)
                    height: Math.round(win.ink * 2)
                    x: win.hit && win.roomLeft ? win.pa.x - width : win.homeX
                    y: win.hit && !win.roomLeft ? Math.max(0, win.pa.y - height) : win.homeY

                    readonly property color warn: root.col(root.s("updater_AlertColor"))
                    readonly property color hot: root.col(root.s("updater_HoverColor"))
                    readonly property bool red: warn.hsvSaturation > 0.5 && (warn.hsvHue < 0.06 || warn.hsvHue > 0.94)

                    Icon {
                        id: server
                        x: Math.round((parent.width - width - mark.width) / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.glyph(root.s("updater_Icon"))
                        family: root.iconFont
                        size: win.ink
                        color: tap.containsMouse ? badge.hot : win.fg
                        Behavior on color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("updater_HoverTime"))) } }
                    }
                    Text {
                        id: mark
                        x: server.x + server.width + Math.round(win.ink * 0.12)
                        y: server.y + server.height - height * 0.82
                        text: "!"
                        font.family: root.font
                        font.bold: true
                        font.pixelSize: Math.round(win.ink * 0.9)
                        color: tap.containsMouse && !badge.red ? badge.hot : badge.warn
                        Behavior on color { ColorAnimation { duration: Motion.span(Math.max(0, root.s("updater_HoverTime"))) } }
                    }
                    MouseArea { id: tap; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = true }
                }

                Rectangle {
                    id: box
                    visible: root.open
                    width: Math.min(win.width, Math.round(win.width * root.s("updater_Width")))
                    height: Math.min(win.height, Math.round(win.height * root.s("updater_Height")))
                    x: Math.max(0, win.width - width - win.inX)
                    y: Math.max(0, win.height - height - win.inY)
                    color: win.bg
                    border.width: 1
                    border.color: win.fg

                    HoverHandler { id: inside; onHoveredChanged: if (hovered) face.forceActiveFocus() }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; hoverEnabled: true; onPositionChanged: root.keyed = false }

                    Rectangle {
                        id: head
                        x: 1
                        y: 1
                        width: box.width - 2
                        height: Math.round(win.px * 2.2)
                        color: win.fg

                        Text {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.word("Issues") + " (" + root.live.length + ")"
                            font.family: root.font
                            font.bold: true
                            font.pixelSize: win.px
                            color: win.bg
                        }
                        Rectangle {
                            width: parent.height
                            height: parent.height
                            x: parent.width - width
                            color: shut.containsMouse ? win.bg : win.fg
                            Icon { anchors.centerIn: parent; source: "close"; size: win.px; color: shut.containsMouse ? win.fg : win.bg }
                            MouseArea { id: shut; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = false }
                        }
                    }

                    Text {
                        x: 30
                        y: list.y + Math.round((win.rowH - height) / 2)
                        visible: root.live.length === 0
                        text: root.word(scan.running && !root.checked ? "Checking…" : "No issues")
                        font.family: root.font
                        font.pixelSize: win.px
                        color: win.fg
                        opacity: 0.4
                    }

                    ListView {
                        id: list
                        x: 1
                        y: head.y + head.height
                        width: box.width - 2 - (thumb.visible ? thumb.width : 0)
                        height: foot.y - y
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.live
                        currentIndex: root.sel
                        onCurrentIndexChanged: if (root.keyed) positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Column {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool wide: root.wide === modelData.id
                            readonly property bool hot: wide || root.over === index || (root.keyed && root.sel === index)
                            width: list.width

                            Rectangle {
                                width: parent.width
                                height: win.rowH
                                color: row.hot ? win.fg : "transparent"

                                Text {
                                    x: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ""
                                    rotation: row.wide ? 90 : 0
                                    font.family: root.iconFont
                                    font.pixelSize: Math.round(win.px * 0.7)
                                    color: row.hot ? win.bg : win.fg
                                }
                                Text {
                                    x: 30
                                    width: parent.width - 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    text: row.modelData.title
                                    font.family: root.font
                                    font.bold: true
                                    font.pixelSize: win.px
                                    color: row.hot ? win.bg : win.fg
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: { root.keyed = false; root.over = row.index }
                                    onExited: if (root.over === row.index) root.over = -1
                                    onClicked: { root.sel = row.index; root.flip(row.modelData.id) }
                                }
                            }

                            Item {
                                visible: row.wide
                                width: parent.width
                                height: more.height + 18

                                Rectangle { x: 14; y: 2; width: 1; height: parent.height - 10; color: win.fg; opacity: 0.3 }
                                Column {
                                    id: more
                                    x: 30
                                    y: 6
                                    width: parent.width - 44
                                    spacing: 10

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                        text: row.modelData.detail
                                        font.family: root.font
                                        font.pixelSize: win.px
                                        color: win.fg
                                        opacity: 0.75
                                    }
                                    Flow {
                                        width: parent.width
                                        spacing: 8
                                        Chip {
                                            label: root.word("Ignore")
                                            family: root.font
                                            size: win.px
                                            fg: win.fg
                                            bg: win.bg
                                            onTapped: root.ignore(row.modelData.id)
                                        }
                                        Chip {
                                            label: root.word("Fix")
                                            family: root.font
                                            size: win.px
                                            fg: win.fg
                                            bg: win.bg
                                            onTapped: root.mend(row.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Scroller { view: list }

                    Rectangle {
                        id: thumb
                        visible: list.contentHeight > list.height + 1
                        width: 6
                        x: box.width - 1 - width
                        y: list.y + Math.round(list.visibleArea.yPosition * list.height)
                        height: Math.max(win.rowH, Math.round(list.visibleArea.heightRatio * list.height))
                        color: win.fg
                    }

                    Rectangle {
                        id: foot
                        x: 1
                        y: box.height - height - 1
                        width: box.width - 2
                        height: Math.round(win.px * 2.4) + 20
                        color: win.bg

                        Rectangle { width: parent.width; height: 1; color: win.fg }
                        Row {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Chip {
                                label: root.word("Ignore all")
                                family: root.font
                                size: win.px
                                fg: win.fg
                                bg: win.bg
                                live: root.live.length > 0
                                onTapped: root.ignoreAll()
                            }
                            Chip {
                                label: root.word("Check again")
                                family: root.font
                                size: win.px
                                fg: win.fg
                                bg: win.bg
                                live: !scan.running
                                onTapped: root.check()
                            }
                        }
                    }
                }

                Item {
                    id: hole
                    readonly property bool shown: root.target !== null
                    readonly property bool auto: shown && root.target.tag !== ""
                    width: shown ? Math.min(win.width, Math.round(win.width * root.s("updater_FixWidth"))) : 0
                    height: shown ? Math.min(win.height, cap.height + band.height + sheet.height + 34) : 0
                    x: Math.round((win.width - width) / 2)
                    y: Math.round((win.height - height) / 2)

                    Rectangle {
                        anchors.fill: parent
                        visible: hole.shown
                        clip: true
                        color: win.bg
                        border.width: 1
                        border.color: win.fg

                        HoverHandler { id: within; onHoveredChanged: if (hovered) face.forceActiveFocus() }
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; hoverEnabled: true; onPositionChanged: root.keyed = false }

                        Rectangle {
                            id: cap
                            x: 1
                            y: 1
                            width: parent.width - 2
                            height: Math.round(win.px * 2.2)
                            color: win.fg

                            Text {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.word("Error Fix")
                                font.family: root.font
                                font.bold: true
                                font.pixelSize: win.px
                                color: win.bg
                            }
                            Rectangle {
                                width: parent.height
                                height: parent.height
                                x: parent.width - width
                                color: away.containsMouse ? win.bg : win.fg
                                Icon { anchors.centerIn: parent; source: "close"; size: win.px; color: away.containsMouse ? win.fg : win.bg }
                                MouseArea { id: away; anchors.fill: parent; hoverEnabled: true; onClicked: root.target = null }
                            }
                        }

                        Rectangle {
                            id: band
                            x: 1
                            y: cap.y + cap.height
                            width: parent.width - 2
                            height: hole.auto ? cap.height : 0
                            visible: hole.auto
                            color: root.col(root.s("updater_ChangeColor"))

                            Text {
                                x: 10
                                width: parent.width - 20
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: root.word(root.target?.tag ?? "")
                                font.family: root.font
                                font.bold: true
                                font.pixelSize: win.px
                                color: win.bg
                            }
                        }

                        Column {
                            id: sheet
                            x: 16
                            y: band.y + band.height + 16
                            width: parent.width - 32
                            spacing: 14

                            Text {
                                width: parent.width
                                wrapMode: Text.Wrap
                                text: root.target?.title ?? ""
                                font.family: root.font
                                font.bold: true
                                font.pixelSize: win.px
                                color: win.fg
                            }
                            Text {
                                width: parent.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 10
                                elide: Text.ElideRight
                                lineHeight: 1.25
                                text: root.target?.detail ?? ""
                                font.family: root.font
                                font.pixelSize: win.px
                                color: win.fg
                                opacity: 0.75
                            }
                            Text {
                                width: parent.width
                                wrapMode: Text.Wrap
                                lineHeight: 1.25
                                text: root.target?.steps ?? ""
                                font.family: root.font
                                font.pixelSize: win.px
                                color: win.fg
                            }
                            Row {
                                spacing: 8
                                Chip {
                                    visible: hole.auto
                                    label: root.word("Confirm")
                                    family: root.font
                                    size: win.px
                                    fg: win.fg
                                    bg: win.bg
                                    live: !act.running
                                    lit: root.keyed && root.pick === 1
                                    onTapped: root.confirm()
                                }
                                Chip {
                                    label: root.word("Cancel")
                                    family: root.font
                                    size: win.px
                                    fg: win.fg
                                    bg: win.bg
                                    lit: root.keyed && (root.pick === 0 || !hole.auto)
                                    onTapped: root.target = null
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
