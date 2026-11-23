import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../Backend"
import "Widgets"

Kit {
    id: root

    base: ({
        sidebar_Show: true, sidebar_Pinned: false, sidebar_Height: 0.05, sidebar_Gap: 0.2, sidebar_Radius: 18,
        sidebar_Color: "Background", sidebar_Border: true, sidebar_BorderSize: 1, sidebar_BorderColor: "Accent2",
        sidebar_IconScale: 1.15, sidebar_IconColor: "Text", sidebar_IconActiveColor: "Background",
        sidebar_HighlightColor: "Active", sidebar_HighlightLobes: 6, sidebar_HighlightDepth: 0.28, sidebar_HighlightRotation: 15,
        sidebar_Label: true, sidebar_LabelScale: 1, sidebar_LabelColor: "Text", sidebar_LabelCursor: "_",
        sidebar_Add: true, sidebar_SlideTime: 300, sidebar_SlideEasing: "OutExpo", sidebar_FadeTime: 150, sidebar_HoverTime: 180,
        sidebar_Widgets: [{ Key: "tetris", Icon: "" }, { Key: "movies", Icon: "f008" }]
    })

    readonly property var kinds: ["tetris", "movies"]
    readonly property var widgets: s("sidebar_Widgets").filter(w => w && typeof w.Key === "string")
    readonly property var labels: widgets.map(w => word(w.Key)).concat(s("sidebar_Add") ? [word("add widget")] : [])
    readonly property real widest: Math.max(0, ...labels.map(span)) + 1
    readonly property real iconScale: s("sidebar_IconScale")
    readonly property string want: hot === "" ? "" : word(hot === "+" ? "add widget" : hot)
    property var running: ({})
    property string hot: ""
    property bool calm: false
    readonly property var order: widgets.map(w => w.Key).concat(s("sidebar_Add") ? ["+"] : [])

    function span(t) {
        let n = 0
        for (const ch of String(t)) n += ch.codePointAt(0) > 0x2e7f ? 2 : 1
        return n
    }
    function flower(size, n, d) {
        const r = size / 2, pts = [], steps = 180
        for (let i = 0; i <= steps; i++) {
            const a = Math.PI * 2 * i / steps
            const rr = r * (1 - d * (1 - Math.cos(n * a)) / 2)
            pts.push(Qt.point(r + rr * Math.cos(a), r + rr * Math.sin(a)))
        }
        return pts
    }
    function isOpen(key) { return running[key] === true }
    function launch(key) {
        if (!kinds.includes(key)) return
        if (!isOpen(key)) {
            const r = Object.assign({}, running)
            r[key] = true
            running = r
            return
        }
        const sel = "\"title:^dolphin-" + key + "$\""
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + (Hyprland.focusedWorkspace?.id ?? 1) + ", window = " + sel + " })")
        Hyprland.dispatch("hl.dsp.focus({ window = " + sel + " })")
    }
    function stop(key) {
        if (!isOpen(key)) return
        const r = Object.assign({}, running)
        delete r[key]
        running = r
    }
    function enter(key) { hot = key }
    function rest() { calm = true; wake.restart() }
    function step(d) {
        const n = order.length, i = order.indexOf(hot)
        if (n) hot = order[i < 0 ? (d > 0 ? 0 : n - 1) : (i + d + n) % n]
    }
    function poke() {
        if (hot === "" || hot === "+") return
        rest()
        launch(hot)
    }
    function leave(key) { if (hot === key) hot = "" }

    Timer { id: wake; interval: 400; onTriggered: root.calm = false }

    LazyLoader {
        active: root.isOpen("tetris")
        Tetris { onGone: Qt.callLater(root.stop, "tetris") }
    }

    LazyLoader {
        active: root.isOpen("movies")
        Movies { onGone: Qt.callLater(root.stop, "movies") }
    }

    readonly property bool out: win.visible && win.shown
    readonly property real rise: win.u + win.gap
    readonly property real crown: win.labelH
    readonly property real tall: win.height
    readonly property bool talking: want !== ""
    readonly property real wide: win.width

    PanelWindow {
        id: win
        readonly property real u: Math.round(screen.height * root.s("sidebar_Height") / 2) * 2
        readonly property real cell: Math.round(u * 0.8 * root.iconScale / 2) * 2
        readonly property real gap: u * root.s("sidebar_Gap")
        readonly property real labelSize: u * 0.28 * root.s("sidebar_LabelScale")
        readonly property real labelH: root.s("sidebar_Label") ? labelSize * 1.5 + gap * 0.5 : 0
        readonly property real reach: Math.max(box.width, root.s("sidebar_Label") ? root.widest * labelSize * 0.62 : 0)
        readonly property bool shown: hover.hovered || root.s("sidebar_Pinned") || Reveal.all
        readonly property int time: root.s("sidebar_SlideTime")
        readonly property int fade: root.s("sidebar_FadeTime")
        readonly property int quick: root.s("sidebar_HoverTime")

        visible: root.s("sidebar_Show")
        anchors { bottom: true; left: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sidebar"
        WlrLayershell.keyboardFocus: hover.hovered && !root.calm ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: Math.ceil(reach + gap * 2)
        implicitHeight: Math.ceil(labelH + u + gap)
        mask: Region { item: win.shown ? content : strip; Region { item: side } }
        onShownChanged: if (shown) content.forceActiveFocus(); else { root.hot = ""; root.calm = false }

        Item {
            id: content
            anchors.fill: parent
            opacity: Reveal.glass
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) root.step(-1)
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) root.step(1)
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.poke()
                else return
                e.accepted = true
            }
            HoverHandler { id: hover }
            Item { id: strip; anchors.bottom: parent.bottom; width: parent.width; height: 2 }
            Item { id: side; width: 2; height: parent.height }

            Typer {
                visible: root.s("sidebar_Label")
                x: box.x + win.u * 0.1
                y: (win.labelH - win.gap * 0.5 - height) / 2
                want: root.want
                caret: root.s("sidebar_LabelCursor")
                font.family: root.font
                font.pixelSize: win.labelSize
                color: root.col(root.s("sidebar_LabelColor"))
            }

            Rectangle {
                id: box
                x: win.shown ? win.gap : -win.reach - win.gap
                y: win.labelH
                width: tray.width + win.u * 0.4
                height: win.u
                radius: Math.min(root.s("sidebar_Radius"), height / 2)
                color: root.col(root.s("sidebar_Color"))
                border.width: root.s("sidebar_Border") ? root.s("sidebar_BorderSize") : 0
                border.color: root.col(root.s("sidebar_BorderColor"))
                Behavior on x { NumberAnimation { duration: Motion.span(win.time); easing.type: root.curve("sidebar_SlideEasing") } }
                Behavior on width { NumberAnimation { duration: Motion.span(win.time); easing.type: root.curve("sidebar_SlideEasing") } }
                Behavior on color { ColorAnimation { duration: Motion.span(win.time) } }

                Row {
                    id: tray
                    anchors.centerIn: parent
                    spacing: win.u * 0.15

                    Repeater {
                        model: root.widgets

                        Item {
                            id: ex
                            required property var modelData
                            readonly property string key: modelData.Key
                            readonly property string sym: root.glyph(modelData.Icon)
                            readonly property bool lit: root.hot === key || root.isOpen(key)
                            readonly property color ink: root.col(root.s(lit ? "sidebar_IconActiveColor" : "sidebar_IconColor"))
                            width: win.cell
                            height: win.u

                            HoverHandler { id: exHover; onHoveredChanged: hovered ? root.enter(ex.key) : root.leave(ex.key) }

                            Shape {
                                id: ring
                                readonly property real size: Math.round(win.u * 0.75 * root.iconScale / 2) * 2
                                anchors.centerIn: parent
                                width: size
                                height: size
                                rotation: root.s("sidebar_HighlightRotation") + (root.hot === ex.key ? 30 : 0)
                                opacity: ex.lit ? 1 : 0
                                scale: ex.lit ? 1 : 0.6
                                preferredRendererType: Shape.CurveRenderer
                                Behavior on opacity { NumberAnimation { duration: Motion.span(Math.min(win.fade, win.quick)) } }
                                Behavior on scale { NumberAnimation { duration: Motion.span(win.quick); easing.type: Easing.OutBack } }
                                Behavior on rotation { NumberAnimation { duration: Motion.span(win.quick * 2); easing.type: Easing.OutCubic } }
                                ShapePath {
                                    fillColor: root.col(root.s("sidebar_HighlightColor"))
                                    strokeColor: "transparent"
                                    PathPolyline { path: root.flower(ring.size, root.s("sidebar_HighlightLobes"), root.s("sidebar_HighlightDepth")) }
                                }
                            }

                            Grid {
                                anchors.centerIn: parent
                                visible: ex.sym === ""
                                columns: 3
                                spacing: win.u * 0.015 * root.iconScale
                                Repeater {
                                    model: [1, 1, 1, 0, 1, 0]
                                    Rectangle {
                                        required property int modelData
                                        width: win.u * 0.1 * root.iconScale
                                        height: width
                                        radius: width * 0.25
                                        color: ex.ink
                                        opacity: modelData
                                        Behavior on color { ColorAnimation { duration: Motion.span(win.fade) } }
                                    }
                                }
                            }

                            Icon {
                                anchors.centerIn: parent
                                visible: ex.sym !== ""
                                source: ex.sym
                                family: root.iconFont
                                size: win.u * 0.32 * root.iconScale
                                color: ex.ink
                                Behavior on color { ColorAnimation { duration: Motion.span(win.fade) } }
                            }

                            MouseArea { anchors.fill: parent; onClicked: { root.rest(); root.launch(ex.key) } }
                        }
                    }

                    Item {
                        id: add
                        readonly property bool lit: root.hot === "+"
                        readonly property color ink: root.col(root.s(lit ? "sidebar_IconActiveColor" : "sidebar_IconColor"))
                        readonly property real line: Math.max(2, win.u * 0.04)
                        visible: root.s("sidebar_Add")
                        width: win.cell
                        height: win.u

                        HoverHandler { id: addHover; onHoveredChanged: hovered ? root.enter("+") : root.leave("+") }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(win.u * 0.55 * root.iconScale / 2) * 2
                            height: width
                            radius: width / 2
                            color: add.lit ? root.col(root.s("sidebar_HighlightColor")) : "transparent"
                            border.width: add.lit ? 0 : add.line
                            border.color: add.ink
                            scale: add.lit ? 1.1 : 1
                            Behavior on color { ColorAnimation { duration: Motion.span(win.fade) } }
                            Behavior on scale { NumberAnimation { duration: Motion.span(win.quick); easing.type: Easing.OutBack } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.45
                                height: add.line
                                radius: height / 2
                                color: add.ink
                                Behavior on color { ColorAnimation { duration: Motion.span(win.fade) } }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: add.line
                                height: parent.width * 0.45
                                radius: width / 2
                                color: add.ink
                                Behavior on color { ColorAnimation { duration: Motion.span(win.fade) } }
                            }
                        }

                        MouseArea { anchors.fill: parent }
                    }
                }
            }
        }
    }
}
