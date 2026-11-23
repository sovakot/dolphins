import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../Backend"

Kit {
    id: root

    base: ({
        cheatsheet_Show: true, cheatsheet_Title: "Cheat sheet", cheatsheet_Width: 0.74, cheatsheet_MaxHeight: 0.82, cheatsheet_Columns: 4, cheatsheet_TextSize: 13, cheatsheet_Radius: 20,
        cheatsheet_Color: "Background", cheatsheet_TextColor: "Text", cheatsheet_ActiveColor: "Active", cheatsheet_Dim: 0.35, cheatsheet_Opacity: 0.96,
        cheatsheet_SuperLabel: "Super", cheatsheet_Hidden: [], cheatsheet_Extra: []
    })

    property bool open: false
    property string lua: ""
    readonly property color bg: col(s("cheatsheet_Color"))
    readonly property color tx: col(s("cheatsheet_TextColor"))
    readonly property color hi: col(s("cheatsheet_ActiveColor"))
    readonly property real px: Math.max(9, s("cheatsheet_TextSize"))
    readonly property var monitor: Hyprland.focusedMonitor
    readonly property var screen: Quickshell.screens.find(m => m.name === monitor?.name) ?? Quickshell.screens[0] ?? null
    readonly property int cols: Math.max(1, Math.min(8, Math.round(s("cheatsheet_Columns"))))
    readonly property string hiddenSig: s("cheatsheet_Hidden").join("\n")
    readonly property string extraSig: JSON.stringify(s("cheatsheet_Extra"))
    readonly property var groups: {
        const hidden = hiddenSig === "" ? [] : hiddenSig.split("\n"), out = Binds.parse(lua).map(g => ({ name: g.name, binds: g.binds.slice() }))
        for (const e of JSON.parse(extraSig)) {
            if (!e || typeof e !== "object") continue
            const name = String(e.Group ?? "Other"), keys = String(e.Keys ?? "").split("+").map(k => k.trim()).filter(k => k)
            if (!keys.length) continue
            let g = out.find(x => x.name === name)
            if (!g) { g = { name: name, binds: [] }; out.push(g) }
            g.binds.push({ tokens: keys, name: String(e.Text ?? ""), tail: "" })
        }
        return out.filter(g => !hidden.includes(g.name) && g.binds.length > 0)
    }
    readonly property var columns: {
        const n = cols, out = [], total = groups.reduce((a, g) => a + g.binds.length + 2.2, 0), goal = total / n
        let cur = [], sum = 0
        for (const g of groups) {
            const w = g.binds.length + 2.2
            if (cur.length && out.length < n - 1 && sum + w / 2 > goal) { out.push(cur); cur = []; sum = 0 }
            cur.push(g)
            sum += w
        }
        if (cur.length) out.push(cur)
        return out
    }

    function toggle() {
        if (!s("cheatsheet_Show")) return
        open = !open
    }
    function cap(t) { return String(t).toUpperCase() === "SUPER" ? String(s("cheatsheet_SuperLabel")) : Binds.cap(t) }

    FileView {
        path: root.open || root.lua !== "" ? Binds.file : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.lua = text()
    }

    GlobalShortcut { appid: "cheatsheet"; name: "toggle"; onPressed: root.toggle() }
    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle() }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            screen: root.screen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "dolphin-cheatsheet"
            anchors { top: true; bottom: true; left: true; right: true }

            Item {
                id: face
                anchors.fill: parent
                focus: true
                Component.onCompleted: { forceActiveFocus(); rise.start() }
                Keys.onEscapePressed: root.open = false
                Keys.onPressed: e => {
                    const step = root.px * 5, far = Math.max(0, view.contentHeight - view.height), at = slide.running ? slide.to : view.contentY
                    let to = at
                    if (e.key === Qt.Key_Down) to = at + step
                    else if (e.key === Qt.Key_Up) to = at - step
                    else if (e.key === Qt.Key_PageDown || e.key === Qt.Key_Space) to = at + view.height * 0.8
                    else if (e.key === Qt.Key_PageUp) to = at - view.height * 0.8
                    else if (e.key === Qt.Key_Home) to = 0
                    else if (e.key === Qt.Key_End) to = far
                    else return
                    e.accepted = true
                    slide.to = Math.max(0, Math.min(far, to))
                    slide.restart()
                }

                NumberAnimation { id: slide; target: view; property: "contentY"; duration: Motion.span(160); easing.type: Easing.OutCubic }
                Rectangle { id: veil; anchors.fill: parent; color: "#000000"; opacity: 0 }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.open = false }

                Rectangle {
                    id: sheet
                    readonly property real pad: Math.round(root.px * 1.8)
                    readonly property real colW: Math.floor((width - pad * 2 - (root.columns.length - 1) * pad) / Math.max(1, root.columns.length))
                    anchors.centerIn: parent
                    width: Math.round(Math.min(win.width - 40, win.width * Math.max(0.3, root.s("cheatsheet_Width"))))
                    height: Math.round(Math.min(win.height * Math.max(0.3, Math.min(0.96, root.s("cheatsheet_MaxHeight"))), head.height + flow.height + pad * 2.2))
                    radius: Math.max(0, root.s("cheatsheet_Radius"))
                    color: Qt.alpha(root.bg, Math.max(0.2, Math.min(1, root.s("cheatsheet_Opacity"))))
                    border.width: 1
                    border.color: Qt.alpha(root.tx, 0.1)
                    opacity: 0
                    scale: 0.96
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    ParallelAnimation {
                        id: rise
                        NumberAnimation { target: sheet; property: "opacity"; to: 1; duration: Motion.span(180); easing.type: Easing.OutCubic }
                        NumberAnimation { target: sheet; property: "scale"; to: 1; duration: Motion.span(260); easing.type: Easing.OutBack }
                        NumberAnimation { target: veil; property: "opacity"; to: Math.max(0, Math.min(1, root.s("cheatsheet_Dim"))); duration: Motion.span(200) }
                    }

                    Item {
                        id: head
                        width: parent.width
                        height: Math.round(root.px * 4.2)
                        Text { anchors.centerIn: parent; text: root.word(root.s("cheatsheet_Title")); color: root.tx; font.family: root.font; font.pixelSize: Math.round(root.px * 1.35); font.weight: Font.Medium }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: Math.round(root.px * 1.2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(root.px * 2.4)
                            height: width
                            radius: width / 2
                            color: shutArea.containsMouse ? Qt.alpha(root.tx, 0.12) : "transparent"
                            Behavior on color { Tint {} }
                            Icon { anchors.centerIn: parent; source: "close"; size: root.px * 1.1; color: root.tx }
                            MouseArea { id: shutArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = false }
                        }
                    }
                    Flickable {
                        id: view
                        x: sheet.pad
                        y: head.height
                        width: parent.width - sheet.pad * 2
                        height: parent.height - y - Math.round(sheet.pad * 0.8)
                        contentHeight: flow.height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Row {
                            id: flow
                            spacing: sheet.pad
                            Repeater {
                                model: root.columns
                                Column {
                                    id: lane
                                    required property var modelData
                                    width: sheet.colW
                                    spacing: Math.round(root.px * 1.3)
                                    Repeater {
                                        model: lane.modelData
                                        Column {
                                            id: part
                                            required property var modelData
                                            property real keyW: 0
                                            width: lane.width
                                            spacing: Math.round(root.px * 0.45)
                                            Text { text: root.word(part.modelData.name); color: root.tx; font.family: root.font; font.pixelSize: Math.round(root.px * 1.2); font.weight: Font.Medium; bottomPadding: Math.round(root.px * 0.3) }
                                            Repeater {
                                                model: part.modelData.binds
                                                Item {
                                                    id: line
                                                    required property var modelData
                                                    width: part.width
                                                    height: Math.round(root.px * 1.85)
                                                    Row {
                                                        id: caps
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: Math.round(root.px * 0.3)
                                                        onWidthChanged: if (width > part.keyW) part.keyW = width
                                                        Repeater {
                                                            model: line.modelData.tokens
                                                            Row {
                                                                id: unit
                                                                required property string modelData
                                                                required property int index
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                spacing: caps.spacing
                                                                Text { visible: unit.index > 0; anchors.verticalCenter: parent.verticalCenter; text: "+"; color: root.tx; opacity: 0.5; font.family: root.font; font.pixelSize: root.px - 1 }
                                                                Rectangle {
                                                                    anchors.verticalCenter: parent.verticalCenter
                                                                    width: Math.max(height, capText.implicitWidth + Math.round(root.px * 0.9))
                                                                    height: Math.round(root.px * 1.55)
                                                                    radius: Math.round(root.px * 0.4)
                                                                    color: Qt.alpha(root.tx, 0.05)
                                                                    border.width: 1
                                                                    border.color: Qt.alpha(root.tx, 0.6)
                                                                    Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - parent.radius * 2; height: 2; color: Qt.alpha(root.tx, 0.6) }
                                                                    Text { id: capText; anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: root.cap(unit.modelData); color: root.tx; font.family: root.font; font.pixelSize: root.px - 2 }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        x: Math.min(part.keyW + Math.round(root.px * 1.1), parent.width * 0.62)
                                                        width: parent.width - x
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        elide: Text.ElideRight
                                                        text: root.word(line.modelData.name) + (line.modelData.tail ? " " + line.modelData.tail : "")
                                                        color: root.tx
                                                        opacity: 0.85
                                                        font.family: root.font
                                                        font.pixelSize: root.px
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Scroller { view: view }
                }
            }
        }
    }
}
