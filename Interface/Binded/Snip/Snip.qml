import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../Backend"

Kit {
    id: root

    base: ({
        snip_Show: true, snip_Icon: "scissors", snip_IconScale: 1.6, snip_IconAngle: 0, snip_IconColor: "Text", snip_IconRim: true, snip_Dim: 0.4, snip_DimColor: "#000000",
        snip_BorderColor: "Active", snip_BorderSize: 2, snip_Radius: 6, snip_Size: true, snip_Folder: "", snip_Delay: 80,
        snip_Smart: true, snip_Content: true, snip_SmartMin: 48, snip_Detail: 0.5, snip_Edge: 6, snip_Guides: true, snip_Labels: true, snip_Wait: 500
    })

    property bool open: false
    property bool seeking: false
    property bool blind: false
    property var shot: null
    property var regions: []
    readonly property var monitor: Hyprland.focusedMonitor
    readonly property var screen: Quickshell.screens.find(m => m.name === monitor?.name) ?? Quickshell.screens[0] ?? null
    readonly property string here: String(Quickshell.shellDir).replace(/\/+$/, "") + "/Interface/Binded/Snip"
    readonly property string mark: String(s("snip_Icon"))
    readonly property string sign: Art.has(mark) ? mark : glyph(mark)
    readonly property color ink: col(s("snip_IconColor"))
    readonly property color rim: 0.299 * ink.r + 0.587 * ink.g + 0.114 * ink.b > 0.5 ? "#000000" : "#ffffff"
    readonly property string folder: {
        const f = String(s("snip_Folder")).trim().replace(/\/+$/, "")
        return f === "" || f.startsWith("/") ? f : String(Quickshell.env("HOME") ?? "") + "/" + f.replace(/^~?\/*/, "")
    }

    function toggle() {
        if (!s("snip_Show")) return
        if (open || seeking) { shut(); return }
        regions = []
        if (!s("snip_Smart") || !monitor) { open = true; return }
        const k = monitor.scale > 0 ? monitor.scale : 1
        seeking = true
        scout.command = ["python3", here + "/Regions.py", String(monitor.name), String(monitor.x), String(monitor.y), String(Math.round(monitor.width / k)), String(Math.round(monitor.height / k)),
            s("snip_Content") ? "1" : "0", String(Math.max(8, s("snip_SmartMin"))), String(s("snip_Detail")), String(s("snip_Edge"))]
        scout.running = true
        patience.restart()
    }
    function shut() {
        open = false
        seeking = false
        blind = false
        wait.stop()
        patience.stop()
        lapse.stop()
    }
    function begin() {
        if (!seeking) return
        seeking = false
        patience.stop()
        open = true
    }
    function learn(line) {
        let got = null
        try { got = JSON.parse(line) } catch (e) { return }
        if (!got) return
        if (got.ready) begin()
        if (Array.isArray(got.regions)) regions = regions.concat(got.regions).sort((a, b) => a.w * a.h - b.w * b.h || b.top - a.top)
    }
    function under(x, y) {
        for (const r of regions) if (x >= r.x && y >= r.y && x < r.x + r.w && y < r.y + r.h) return r
        return null
    }
    function take(x, y, w, h) {
        if (blind) return
        if (w < 4 || h < 4 || grab.running) { shut(); return }
        shot = Math.round((monitor?.x ?? 0) + x) + "," + Math.round((monitor?.y ?? 0) + y) + " " + Math.round(w) + "x" + Math.round(h)
        blind = true
        wait.restart()
        lapse.restart()
    }

    Timer { id: patience; interval: Math.max(100, root.s("snip_Wait")); onTriggered: root.begin() }
    Timer {
        id: wait
        interval: Math.max(20, root.s("snip_Delay"))
        onTriggered: {
            grab.command = ["sh", "-c", "if [ -n \"$2\" ]; then mkdir -p \"$2\" && f=\"$2/snip-$(date +%F_%H-%M-%S).png\" && grim -g \"$1\" \"$f\" && wl-copy --type image/png < \"$f\"; else grim -g \"$1\" - | wl-copy --type image/png; fi", "snip", root.shot, root.folder]
            grab.running = true
        }
    }
    Timer { id: lapse; interval: 4000; onTriggered: root.shut() }
    Process { id: grab; onExited: (exitCode, exitStatus) => root.shut() }
    Process {
        id: scout
        stdout: SplitParser { onRead: line => root.learn(line) }
        onExited: root.begin()
    }

    GlobalShortcut { appid: "snip"; name: "toggle"; onPressed: root.toggle() }
    IpcHandler {
        target: "snip"
        function toggle(): void { root.toggle() }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            screen: root.screen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "dolphin-snip"
            anchors { top: true; bottom: true; left: true; right: true }

            Item {
                id: pad
                property real ax: 0
                property real ay: 0
                property real bx: 0
                property real by: 0
                property real mx: width / 2
                property real my: height / 2
                property bool held: false
                property bool drawn: false
                property bool seen: false
                readonly property var aim: !drawn && seen && root.s("snip_Smart") ? root.under(mx, my) : null
                readonly property bool cut: drawn || !!aim
                property real restX: width / 2
                property real restY: height / 2
                onAimChanged: if (aim) { restX = aim.x + aim.w / 2; restY = aim.y + aim.h / 2 }
                readonly property real rx: drawn ? Math.min(ax, bx) : aim ? aim.x : restX
                readonly property real ry: drawn ? Math.min(ay, by) : aim ? aim.y : restY
                readonly property real rw: drawn ? Math.abs(bx - ax) : aim ? aim.w : 0
                readonly property real rh: drawn ? Math.abs(by - ay) : aim ? aim.h : 0
                property real hx: rx
                property real hy: ry
                property real hw: rw
                property real hh: rh
                readonly property color shade: Qt.alpha(root.col(root.s("snip_DimColor")), Math.max(0, Math.min(1, root.s("snip_Dim"))))
                readonly property color edge: root.col(root.s("snip_BorderColor"))
                readonly property string note: {
                    if (!cut) return ""
                    const size = root.s("snip_Size") ? Math.round(rw) + " × " + Math.round(rh) : ""
                    const name = !drawn && aim && root.s("snip_Labels") ? (aim.label !== "" ? aim.label : root.word(aim.kind === "window" ? "Window" : "Region")) : ""
                    return name !== "" && size !== "" ? name + "  ·  " + size : name + size
                }
                anchors.fill: parent
                opacity: root.blind ? 0 : 1
                focus: true
                Keys.onEscapePressed: root.shut()
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { root.take(0, 0, pad.width, pad.height); e.accepted = true }
                }
                Component.onCompleted: forceActiveFocus()
                Behavior on hx { enabled: !pad.drawn && pad.seen; Glide {} }
                Behavior on hy { enabled: !pad.drawn && pad.seen; Glide {} }
                Behavior on hw { enabled: !pad.drawn && pad.seen; Glide {} }
                Behavior on hh { enabled: !pad.drawn && pad.seen; Glide {} }

                Rectangle { width: pad.width; height: Math.max(0, pad.hy); color: pad.shade }
                Rectangle { y: pad.hy + pad.hh; width: pad.width; height: Math.max(0, pad.height - y); color: pad.shade }
                Rectangle { y: pad.hy; width: Math.max(0, pad.hx); height: pad.hh; color: pad.shade }
                Rectangle { x: pad.hx + pad.hw; y: pad.hy; width: Math.max(0, pad.width - x); height: pad.hh; color: pad.shade }
                Rectangle { visible: root.s("snip_Guides") && pad.seen && !pad.cut; x: Math.round(pad.mx); width: 1; height: pad.height; color: pad.edge; opacity: 0.35 }
                Rectangle { visible: root.s("snip_Guides") && pad.seen && !pad.cut; y: Math.round(pad.my); width: pad.width; height: 1; color: pad.edge; opacity: 0.35 }
                Rectangle {
                    visible: pad.cut
                    x: pad.hx
                    y: pad.hy
                    width: pad.hw
                    height: pad.hh
                    radius: pad.drawn ? 0 : Math.max(0, Math.min(root.s("snip_Radius"), width / 2, height / 2))
                    color: "transparent"
                    border.width: Math.max(1, root.s("snip_BorderSize"))
                    border.color: pad.edge
                }
                Rectangle {
                    visible: pad.note !== "" && pad.hw > 40
                    x: Math.max(4, Math.min(pad.width - width - 4, pad.hx))
                    y: pad.hy + pad.hh + 6 + height > pad.height ? Math.max(4, pad.hy + pad.hh - height - 6) : pad.hy + pad.hh + 6
                    width: tag.implicitWidth + 14
                    height: tag.implicitHeight + 8
                    radius: height / 2
                    color: Qt.alpha(root.col("Background"), 0.85)
                    Text {
                        id: tag
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, pad.width * 0.5)
                        elide: Text.ElideRight
                        text: pad.note
                        color: pad.edge
                        font.family: root.font
                        font.pixelSize: 13
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.BlankCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: m => {
                        if (m.button === Qt.RightButton) { root.shut(); return }
                        pad.ax = pad.bx = m.x
                        pad.ay = pad.by = m.y
                        pad.held = true
                    }
                    onPositionChanged: m => {
                        pad.mx = m.x
                        pad.my = m.y
                        pad.seen = true
                        if (!pad.held) return
                        if (!pad.drawn && Math.abs(m.x - pad.ax) + Math.abs(m.y - pad.ay) < 6) return
                        pad.bx = Math.max(0, Math.min(pad.width, m.x))
                        pad.by = Math.max(0, Math.min(pad.height, m.y))
                        pad.drawn = true
                    }
                    onReleased: m => {
                        if (m.button !== Qt.LeftButton || !pad.held) return
                        pad.held = false
                        if (pad.drawn) root.take(pad.rx, pad.ry, pad.rw, pad.rh)
                        else if (pad.aim) root.take(pad.aim.x, pad.aim.y, pad.aim.w, pad.aim.h)
                        else root.shut()
                    }
                }
                Item {
                    visible: pad.seen
                    x: pad.mx - width / 2
                    y: pad.my - height / 2
                    width: face.width
                    height: face.height
                    rotation: root.s("snip_IconAngle")
                    Icon {
                        visible: root.s("snip_IconRim")
                        anchors.centerIn: parent
                        source: root.sign
                        family: root.iconFont
                        size: face.size
                        grow: 1
                        color: root.rim
                        opacity: 0.6
                        scale: 1.22
                    }
                    Icon {
                        id: face
                        source: root.sign
                        family: root.iconFont
                        size: 14 * Math.max(0.5, root.s("snip_IconScale"))
                        grow: 1
                        color: root.ink
                    }
                }
            }
        }
    }
}
