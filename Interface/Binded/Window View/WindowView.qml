import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../Backend"
import "../../../Data/Dynamic"

Scope {
    id: root

    required property var cfg
    property bool open: false
    property bool warm: false
    readonly property var base: ({
        Show: true, Rows: 2, Columns: 5, Scale: 0.15, X: 0.5, Y: 0.5, Gap: 10, Radius: 10,
        Color: "Background", TileColor: "Accent", HoverColor: "Accent2", ActiveColor: "Active", SelectColor: "Active",
        TextColor: "Inactive", WindowColor: "Inactive", Border: true, BorderSize: 2, BorderColor: "Accent2",
        Live: true, Quality: 0.5, PreviewBlur: 0.5, IconTint: false, IconTintStrength: 0.5,
        OpenTime: 250, OpenEasing: "OutCubic", DragTime: 300, DragEasing: "OutExpo", DragScale: 1.05, FadeTime: 150
    })
    property real vis: open ? 1 : 0
    readonly property var sizeEvents: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen"]
    readonly property var numerals: cfg?.widget_TabsNumber ?? []
    Behavior on vis { NumberAnimation { duration: Motion.span(root.s("OpenTime")); easing.type: Easing[root.s("OpenEasing")] } }

    function s(k) {
        const v = cfg?.["windowview_" + k], d = base[k]
        return typeof v === typeof d ? v : d
    }
    function title(t) { return String(t).charAt(0).toUpperCase() + String(t).slice(1) }
    function col(c) {
        const set = Config.tones
        return set?.[c] ?? set?.[title(c)] ?? (String(c).startsWith("#") ? c : "#000000")
    }
    function toggle() {
        if (s("Show") === false) return
        if (open || warm) { stage.stop(); warm = false; open = false; return }
        warm = true
        stage.restart()
    }
    function glyph(hex) { const n = parseInt(hex ?? "", 16); return n ? String.fromCodePoint(n) : "" }
    function mediaUrl(p) { return p ? "file://" + p.replace(/^~/, Quickshell.env("HOME")) : "" }
    function mediaKind(p) {
        const e = (p ?? "").split(".").pop().toLowerCase()
        return ["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(e) ? "video" : ["gif", "webp"].includes(e) ? "anim" : "image"
    }

    Component { id: imgC; Image { anchors.fill: parent; source: parent.url; fillMode: Image.PreserveAspectCrop; sourceSize.width: width * 2; sourceSize.height: height * 2; onStatusChanged: if (status === Image.Error) parent.failed = true } }
    Component { id: animC; AnimatedImage { anchors.fill: parent; source: parent.url; fillMode: Image.PreserveAspectCrop; onStatusChanged: if (status === Image.Error) parent.failed = true } }
    Component { id: vidC; Video { anchors.fill: parent; source: parent.url; fillMode: VideoOutput.PreserveAspectCrop; loops: MediaPlayer.Infinite; muted: true; autoPlay: true; onErrorOccurred: parent.failed = true } }

    Component.onCompleted: Hyprland.refreshToplevels()
    onOpenChanged: if (open) Hyprland.refreshToplevels()

    GlobalShortcut { appid: "overview"; name: "toggle"; onReleased: root.toggle() }

    Timer { id: stage; interval: 50; onTriggered: { root.warm = false; root.open = true } }

    Timer { id: settle; interval: 60; onTriggered: Hyprland.refreshToplevels() }

    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (!root.sizeEvents.includes(e.name)) return
            Hyprland.refreshToplevels()
            if (root.open) settle.restart()
        }
    }

    LazyLoader {
        active: root.vis > 0 || root.warm
        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "overview"

            Rectangle {
                id: box
                readonly property real k: root.s("Scale")
                readonly property real tw: win.screen.width * k
                readonly property real th: win.screen.height * k
                readonly property real gap: root.s("Gap")
                readonly property int count: root.s("Rows") * root.s("Columns")
                readonly property var mon: Hyprland.focusedMonitor
                property int over: -1
                property int sel: Math.max(0, Math.min(count - 1, (Hyprland.focusedWorkspace?.id ?? 1) - 1))
                property Item picked: null
                property Item target: null
                property point hot: Qt.point(-1, -1)
                readonly property var fsTop: {
                    const m = {}, f = {}
                    for (const t of Hyprland.toplevels.values) {
                        const o = t.lastIpcObject
                        if (!o || !(o.fullscreen > 0)) continue
                        const id = o.workspace?.id ?? 0
                        if (!(id in f) || o.focusHistoryID < f[id]) { f[id] = o.focusHistoryID; m[id] = o.address }
                    }
                    return m
                }
                function ox(i) { return gap + (i % root.s("Columns")) * (tw + gap) }
                function oy(i) { return gap + Math.floor(i / root.s("Columns")) * (th + gap) }
                function cell(cx, cy) {
                    const c = Math.floor(cx / (tw + gap)), r = Math.floor(cy / (th + gap))
                    return c >= 0 && c < root.s("Columns") && r >= 0 && r < root.s("Rows") ? r * root.s("Columns") + c : -1
                }
                function winAt(px, py, skip) {
                    let best = null
                    for (let j = 0; j < wins.count; j++) {
                        const it = wins.itemAt(j)
                        if (!it || it === skip || !it.visible) continue
                        if (px >= it.x && px <= it.x + it.width && py >= it.y && py <= it.y + it.height && (!best || it.z > best.z)) best = it
                    }
                    return best
                }
                function go(dc, dr) {
                    const cols = root.s("Columns")
                    const c = Math.max(0, Math.min(cols - 1, sel % cols + dc))
                    const r = Math.max(0, Math.min(root.s("Rows") - 1, Math.floor(sel / cols) + dr))
                    sel = r * cols + c
                    picked = null
                }
                function enter() {
                    if (picked) return picked.activate()
                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + (sel + 1) + " })")
                    root.open = false
                }

                x: (win.width - width) * root.s("X")
                y: (win.height - height) * root.s("Y")
                width: root.s("Columns") * (tw + gap) + gap
                height: root.s("Rows") * (th + gap) + gap
                radius: root.s("Radius")
                color: root.col(root.s("Color"))
                border.width: root.s("Border") ? root.s("BorderSize") : 0
                border.color: root.col(root.s("BorderColor"))
                opacity: Math.max(root.vis, root.warm ? 0.01 : 0)
                scale: 0.94 + 0.06 * root.vis
                focus: true
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) root.open = false
                    else if (e.key === Qt.Key_Left) go(-1, 0)
                    else if (e.key === Qt.Key_Right) go(1, 0)
                    else if (e.key === Qt.Key_Up) go(0, -1)
                    else if (e.key === Qt.Key_Down) go(0, 1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) enter()
                    else return
                    e.accepted = true
                }

                Component {
                    id: blurFx
                    MultiEffect {
                        autoPaddingEnabled: false
                        blurEnabled: true
                        blur: root.s("PreviewBlur")
                        blurMax: 16
                    }
                }

                Repeater {
                    model: box.count
                    Rectangle {
                        required property int index
                        readonly property bool cur: (Hyprland.focusedWorkspace?.id ?? 0) === index + 1
                        readonly property bool chosen: box.sel === index && !box.picked
                        x: box.ox(index)
                        y: box.oy(index)
                        width: box.tw
                        height: box.th
                        radius: root.s("Radius") / 2
                        color: root.col(box.over === index && !box.target ? root.s("HoverColor") : root.s("TileColor"))
                        border.width: cur || chosen ? 2 : 0
                        border.color: root.col(chosen ? root.s("SelectColor") : root.s("ActiveColor"))
                        Behavior on color { ColorAnimation { duration: Motion.span(root.s("FadeTime")) } }
                        Text {
                            anchors.centerIn: parent
                            text: root.numerals[index] ?? index + 1
                            color: root.col(root.s("TextColor"))
                            font.family: (root.cfg?.dolphin_TextFont ?? "")
                            font.pixelSize: box.th * 0.25
                        }
                        TapHandler { onTapped: { Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })"); root.open = false } }
                    }
                }

                Repeater {
                    id: wins
                    model: Hyprland.toplevels
                    Item {
                        id: w
                        required property var modelData
                        readonly property var ipc: modelData.lastIpcObject
                        readonly property int ws: ipc?.workspace?.id ?? 0
                        readonly property bool inRange: ws >= 1 && ws <= box.count
                        readonly property var wl: modelData.wayland
                        readonly property string fsAddr: box.fsTop[ws] ?? ""
                        readonly property bool covered: fsAddr !== "" && fsAddr !== (ipc?.address ?? "")
                        readonly property string key: { const m = /^dolphin-(.+)$/.exec(modelData.wayland?.title ?? ""); return m ? m[1] : "" }
                        readonly property var extra: key ? ((root.cfg?.extratask_Apps ?? []).find(e => e.key === w.key) ?? null) : null
                        readonly property string media: key ? ((root.cfg?.extratask_Icons ?? {})[key] ?? "") : ""
                        readonly property bool ok: media !== "" && !mload.failed
                        readonly property bool custom: !!extra && !ok
                        readonly property bool disc: Emblem.spins(modelData.wayland?.title)
                        readonly property string sym: extra ? root.glyph(extra.icon) : ""
                        readonly property real iconSize: Math.min(width, height) * 0.35
                        property var src: null
                        property bool held: false
                        property bool got: false
                        property int tries: 0
                        property real aspect: 0
                        property size tex: Qt.size(0, 0)
                        function latch() { if (!src && wl && inRange) src = wl }
                        function recap() {
                            const s = wl
                            src = null
                            Qt.callLater(() => { if (w.inRange) w.src = s })
                        }
                        function hx() { return box.ox(ws - 1) + ((ipc?.at?.[0] ?? 0) - (box.mon?.x ?? 0)) * box.k }
                        function hy() { return box.oy(ws - 1) + ((ipc?.at?.[1] ?? 0) - (box.mon?.y ?? 0)) * box.k }
                        function home() { held = false; x = Qt.binding(() => hx()); y = Qt.binding(() => hy()) }
                        function activate() { Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + ipc.address + "\" })"); root.open = false }
                        function track() {
                            const p = box.mapFromItem(null, dh.centroid.scenePosition.x, dh.centroid.scenePosition.y)
                            const c = box.cell(p.x, p.y)
                            const t = box.winAt(p.x, p.y, w)
                            box.hot = Qt.point(p.x, p.y)
                            box.over = c
                            box.target = t && c + 1 === ws && t.ws === ws ? t : null
                        }
                        function swapWith(t) {
                            const a = ipc, b = t.ipc
                            const back = Hyprland.focusedWorkspace?.id ?? ws
                            const d = s => Hyprland.dispatch(s)
                            const addr = o => "\"address:" + o.address + "\""
                            const place = (o, at, size) => {
                                d("hl.dsp.window.move({ x = " + at[0] + ", y = " + at[1] + ", window = " + addr(o) + " })")
                                d("hl.dsp.window.resize({ x = " + size[0] + ", y = " + size[1] + ", window = " + addr(o) + " })")
                            }
                            if (!a.floating && !b.floating) {
                                d("hl.dsp.focus({ window = " + addr(a) + " })")
                                d("hl.dsp.window.swap({ target = " + addr(b) + " })")
                                if (back !== ws) d("hl.dsp.focus({ workspace = " + back + " })")
                            } else if (a.floating && b.floating) {
                                place(a, b.at, b.size)
                                place(b, a.at, a.size)
                            } else {
                                const f = a.floating ? a : b, tl = a.floating ? b : a
                                d("hl.dsp.window.float({ action = \"toggle\", window = " + addr(f) + " })")
                                d("hl.dsp.window.float({ action = \"toggle\", window = " + addr(tl) + " })")
                                place(tl, f.at, f.size)
                            }
                            held = true
                            swapped.restart()
                        }
                        function drop() {
                            const t = box.target
                            const i = box.cell(box.hot.x, box.hot.y)
                            box.over = -1
                            box.target = null
                            box.hot = Qt.point(-1, -1)
                            if (t) return swapWith(t)
                            if (i < 0 || i + 1 === ws) return home()
                            held = true
                            giveUp.restart()
                            Hyprland.dispatch("hl.dsp.window.move({ workspace = " + (i + 1) + ", follow = false, window = \"address:" + ipc.address + "\" })")
                        }

                        visible: inRange && (!covered || dh.active || held)
                        x: hx()
                        y: hy()
                        width: (ipc?.size?.[0] ?? 0) * box.k
                        height: (ipc?.size?.[1] ?? 0) * box.k
                        z: dh.active || held ? 1000 : Math.max(1, 500 - (ipc?.focusHistoryID ?? 499))
                        scale: dh.active ? root.s("DragScale") : 1
                        Component.onCompleted: { latch(); if (ipc?.focusHistoryID === 0 && ws === box.sel + 1) box.picked = w }
                        onWlChanged: latch()
                        onInRangeChanged: latch()
                        onWsChanged: {
                            if (held) home()
                            if (box.picked === w && inRange) box.sel = ws - 1
                            tries = 0
                            if (src) recap()
                        }
                        onXChanged: if (dh.active) track()
                        onYChanged: if (dh.active) track()

                        Behavior on x { enabled: !dh.active; NumberAnimation { duration: Motion.span(root.s("DragTime")); easing.type: Easing[root.s("DragEasing")] } }
                        Behavior on y { enabled: !dh.active; NumberAnimation { duration: Motion.span(root.s("DragTime")); easing.type: Easing[root.s("DragEasing")] } }
                        Behavior on width { NumberAnimation { duration: Motion.span(root.s("DragTime")); easing.type: Easing[root.s("DragEasing")] } }
                        Behavior on height { NumberAnimation { duration: Motion.span(root.s("DragTime")); easing.type: Easing[root.s("DragEasing")] } }
                        Behavior on scale { NumberAnimation { duration: Motion.span(root.s("FadeTime")); easing.type: Easing.OutCubic } }

                        Timer { id: giveUp; interval: 600; onTriggered: if (w.held) w.home() }
                        Timer { id: swapped; interval: 150; onTriggered: { Hyprland.refreshToplevels(); w.home() } }

                        Timer {
                            interval: 100
                            repeat: true
                            running: !!w.src && !cap.hasContent && w.tries < 20
                            onTriggered: { w.tries++; w.recap() }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: root.s("Radius") / 3
                            color: "transparent"

                            ShaderEffectSource {
                                anchors.fill: cap
                                sourceItem: cap
                                live: cap.hasContent
                                hideSource: false
                                smooth: true
                            }

                            ScreencopyView {
                                id: cap
                                readonly property real a: w.aspect > 0 ? w.aspect : parent.height / Math.max(1, parent.width)
                                anchors.centerIn: parent
                                width: Math.max(parent.width, parent.height / a)
                                height: width * a
                                captureSource: w.src
                                live: root.s("Live")
                                onHasContentChanged: if (hasContent) w.got = true
                                onSourceSizeChanged: if (hasContent && sourceSize.width > 0) {
                                    w.aspect = sourceSize.height / sourceSize.width
                                    w.tex = Qt.size(sourceSize.width * root.s("Quality"), sourceSize.height * root.s("Quality"))
                                }
                                layer.enabled: true
                                layer.smooth: true
                                layer.mipmap: true
                                layer.textureSize: w.tex
                                layer.effect: root.s("PreviewBlur") > 0 ? blurFx : null
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.col(root.s("WindowColor"))
                                opacity: w.got ? 0 : 1
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: Motion.span(root.s("FadeTime")) } }
                            }

                            Disc {
                                visible: !w.ok && !w.custom && w.disc
                                anchors.centerIn: parent
                                width: w.iconSize
                                height: width
                                art: visible ? Emblem.art : ""
                                spinning: visible && Emblem.playing
                                spinTime: Emblem.spinTime
                                plate: Emblem.plate
                                ink: root.col(root.s("ActiveColor"))
                                hole: root.col(root.s("WindowColor"))
                                sign: String.fromCodePoint(0xf001)
                                signFont: String(root.cfg?.dolphin_IconFont ?? "")
                            }

                            IconImage {
                                id: ic
                                anchors.centerIn: parent
                                visible: !w.ok && !w.custom && !w.disc
                                implicitSize: w.iconSize
                                source: Emblem.source(w.modelData.title, w.modelData.wayland?.appId)
                            }

                            IconImage {
                                anchors.fill: ic
                                visible: root.s("IconTint") && ic.visible
                                source: ic.source
                                opacity: root.s("IconTintStrength")
                                layer.enabled: visible
                                layer.effect: MultiEffect {
                                    brightness: 1.0
                                    colorization: 1.0
                                    colorizationColor: Qt.darker(root.col(root.s("ActiveColor")), 2)
                                }
                            }

                            ClippingRectangle {
                                anchors.centerIn: parent
                                visible: w.ok
                                width: w.iconSize
                                height: width
                                radius: width / 2
                                color: "transparent"
                                Loader {
                                    id: mload
                                    property string url: root.mediaUrl(w.media)
                                    property bool failed: false
                                    onUrlChanged: failed = false
                                    anchors.fill: parent
                                    active: w.media !== "" && !failed
                                    sourceComponent: root.mediaKind(w.media) === "video" ? vidC : root.mediaKind(w.media) === "anim" ? animC : imgC
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: w.custom && w.sym !== ""
                                text: w.sym
                                font.family: (root.cfg?.dolphin_TextFont ?? "")
                                font.pixelSize: w.iconSize * 0.8
                                color: root.col("Text")
                            }

                            Grid {
                                anchors.centerIn: parent
                                visible: w.custom && w.sym === ""
                                columns: 3
                                spacing: w.iconSize * 0.04
                                Repeater {
                                    model: [1, 1, 1, 0, 1, 0]
                                    Rectangle {
                                        required property int modelData
                                        width: w.iconSize * 0.28
                                        height: width
                                        radius: width * 0.2
                                        color: root.col("Text")
                                        opacity: modelData
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: root.s("Radius") / 3
                            color: "transparent"
                            border.width: 2
                            border.color: root.col(root.s("SelectColor"))
                            visible: box.picked === w || box.target === w
                        }

                        HoverHandler { onHoveredChanged: if (hovered && !dh.active) { box.picked = w; box.sel = w.ws - 1 } }
                        DragHandler {
                            id: dh
                            cursorShape: Qt.ClosedHandCursor
                            xAxis.minimum: -w.width / 2
                            xAxis.maximum: box.width - w.width / 2
                            yAxis.minimum: -w.height / 2
                            yAxis.maximum: box.height - w.height / 2
                            onActiveChanged: { if (active) { box.picked = w; box.sel = w.ws - 1 } else w.drop() }
                        }
                        TapHandler { onTapped: w.activate() }
                    }
                }
            }
        }
    }
}