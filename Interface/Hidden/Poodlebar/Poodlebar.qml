import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../Backend"

Kit {
    id: root

    base: ({
        poodlebar_Show: true, poodlebar_Pinned: false, poodlebar_Apps: [],
        poodlebar_Height: 0.05, poodlebar_Gap: 0.2, poodlebar_Radius: 25, poodlebar_PopupRadius: 14, poodlebar_PreviewRadius: 8,
        poodlebar_Color: "Background", poodlebar_TextColor: "Text", poodlebar_ActiveColor: "Active",
        poodlebar_HoverColor: "Inactive", poodlebar_FieldColor: "Inactive",
        poodlebar_Border: true, poodlebar_BorderSize: 1, poodlebar_BorderColor: "Accent2",
        poodlebar_IconScale: 1, poodlebar_Tint: false, poodlebar_TintStrength: 0.25,
        poodlebar_SlideTime: 300, poodlebar_SlideEasing: "OutExpo", poodlebar_FadeTime: 150, poodlebar_HideDelay: 400,
        poodlebar_PreviewWidth: 4, poodlebar_PreviewHeight: 2.5, poodlebar_PreviewBlur: 0,
        poodlebar_PickerWidth: 9, poodlebar_PickerHeight: 7, poodlebar_PickerColumns: 6, poodlebar_PickerNames: true,
        poodlebar_MenuWidth: 3.4, poodlebar_MenuRadius: 0, poodlebar_MenuColor: "Background", poodlebar_MenuTextColor: "Text",
        poodlebar_MenuHoverColor: "Active", poodlebar_MenuHoverTextColor: "Background", poodlebar_MenuDangerColor: "#e06c75",
        poodlebar_PinIcon: "f0403", poodlebar_PinOffIcon: "f0404", poodlebar_AppsIcon: "f003b",
        poodlebar_Label: true, poodlebar_LabelScale: 1, poodlebar_LabelColor: "Text", poodlebar_LabelCursor: "_"
    })

    readonly property bool pinned: s("poodlebar_Pinned")
    readonly property var apps: s("poodlebar_Apps")
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("Uninstall.sh").toString().replace(/^file:\/\//, ""))
    readonly property int time: s("poodlebar_SlideTime")
    readonly property int ease: curve("poodlebar_SlideEasing")
    readonly property color tintColor: Qt.darker(col(s("poodlebar_ActiveColor")), 2)
    readonly property var openWins: openKey === "" ? [] : Hyprland.toplevels.values.filter(h => owner(h) === openKey)
    readonly property var found: {
        if (mode !== "picker" && under !== "picker") return []
        const q = query.toLowerCase().trim()
        return DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({ e: e, r: rank(e, q) })).filter(x => x.r > 0)
            .sort((a, b) => b.r - a.r || String(a.e.name).localeCompare(String(b.e.name))).map(x => x.e)
    }
    readonly property bool near: barHover.hovered || pvHover
    readonly property bool shown: pinned || Reveal.all || barHover.hovered || mode !== "" || pop > 0

    property string mode: ""
    property string held: ""
    property string under: ""
    property string openKey: ""
    property real openX: 0
    property var target: null
    property point spot: Qt.point(0, -1)
    property string query: ""
    property int sel: 0
    property int row: -1
    property bool sure: false
    property bool pvHover: false
    property bool calm: false
    property int pvSel: -1
    readonly property int targetWins: target ? Hyprland.toplevels.values.filter(h => owner(h) === target.id).length : 0
    property string hot: ""
    property string hotName: ""
    property real hotX: 0
    property real pop: mode !== "" ? 1 : 0

    Behavior on pop { NumberAnimation { duration: Motion.span(root.s("poodlebar_FadeTime")); easing.type: Easing.OutCubic } }
    onModeChanged: {
        if (mode !== "") held = mode
        if (mode !== "preview") pvHover = false
    }
    onNearChanged: near ? hide.stop() : hide.restart()
    onOpenWinsChanged: openWins.length === 0 ? empty.restart() : empty.stop()

    function owner(h) { return h.wayland ? (DesktopEntries.heuristicLookup(h.wayland.appId)?.id ?? h.wayland.appId) : "" }
    function rank(e, q) {
        if (q === "") return 1
        const n = String(e.name ?? "").toLowerCase()
        if (n.startsWith(q)) return 100
        if (n.split(/[\s\-_.]+/).some(p => p.startsWith(q))) return 80
        if (n.includes(q)) return 60
        const more = (String(e.genericName ?? "") + " " + String(e.keywords ?? "") + " " + String(e.comment ?? "") + " " + String(e.id ?? "")).toLowerCase()
        if (more.includes(q)) return 40
        let i = 0
        for (const ch of n) if (ch === q[i]) i++
        return i === q.length ? 20 : 0
    }
    function enter(key, name, x) {
        hot = key
        hotName = String(name ?? "")
        hotX = x
    }
    function leave(key) { if (hot === key) hot = "" }
    function isPinned(id) { return apps.includes(id) }
    function pin(id) { if (!apps.includes(id)) save("poodlebar_Apps", apps.concat([id])) }
    function unpin(id) { save("poodlebar_Apps", apps.filter(a => a !== id)) }
    function flip(id) { isPinned(id) ? unpin(id) : pin(id) }
    function closeAll() { under = ""; mode = "" }
    function back() { mode = under; under = "" }
    function rest() { calm = true; wake.restart() }
    function launch(e) { rest(); e.execute(); closeAll() }
    function preview(key, x) {
        if (mode === "preview" && openKey === key) return closeAll()
        Hyprland.refreshToplevels()
        openKey = key
        openX = x
        under = ""
        mode = "preview"
    }
    function pick() {
        if (mode === "picker") return closeAll()
        query = ""
        sel = 0
        under = ""
        mode = "picker"
    }
    function ask(e, x, y) {
        target = e
        spot = Qt.point(x, y)
        row = -1
        under = mode === "picker" ? "picker" : ""
        mode = "menu"
    }
    function act(i) {
        const e = target
        if (!e) return closeAll()
        if (i === 0) return launch(e)
        if (i === 1) { flip(e.id); return back() }
        sure = false
        mode = "confirm"
    }
    function remove() {
        const e = target
        if (e && !gone.running) {
            gone.app = e.id
            gone.command = ["sh", script, e.id, String(e.name ?? e.id), word("Uninstalled"), word("Uninstall failed")]
            gone.running = true
        }
        back()
    }
    function focusWin(h) {
        rest()
        go.goal = h
        go.restart()
    }
    function reach(h) {
        const ws = h.workspace?.id ?? h.lastIpcObject?.workspace?.id
        if (ws === undefined || ws === Hyprland.focusedWorkspace?.id) return h.wayland.activate()
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws + " })")
        activator.target = h.wayland
        activator.restart()
    }

    GlobalShortcut { appid: "poodlebar"; name: "search"; onPressed: root.pick() }

    Timer { id: hide; interval: root.s("poodlebar_HideDelay"); onTriggered: if (root.mode === "preview") root.closeAll() }
    Timer { id: empty; interval: 300; onTriggered: if (root.mode === "preview" && root.openWins.length === 0) root.closeAll() }
    Timer { id: wake; interval: 400; onTriggered: root.calm = false }
    Timer { id: go; property var goal: null; interval: 90; onTriggered: { if (goal) root.reach(goal); goal = null } }
    Timer { id: activator; property var target: null; interval: 120; onTriggered: { target?.activate(); target = null } }

    Process {
        id: gone
        property string app: ""
        onExited: code => { if (code === 0) root.unpin(app) }
    }

    Component {
        id: blurFx
        MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.s("poodlebar_PreviewBlur")
            blurMax: 16
        }
    }

    readonly property bool out: win.visible && shown
    readonly property real tall: win.height
    readonly property real spanX: bar.x
    readonly property real spanW: bar.width

    PanelWindow {
        id: win
        readonly property real u: Math.round(screen.height * root.s("poodlebar_Height") / 2) * 2
        readonly property real gap: u * root.s("poodlebar_Gap")
        readonly property real ink: u * root.s("poodlebar_IconScale")

        visible: root.s("poodlebar_Show")
        anchors { bottom: true; left: true; right: true }
        readonly property real labelSize: u * 0.28 * root.s("poodlebar_LabelScale")
        readonly property real labelH: root.s("poodlebar_Label") ? labelSize * 1.6 : 0
        implicitHeight: Math.ceil(labelH + u + gap * 2)
        onVisibleChanged: root.hot = ""
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "poodlebar"
        WlrLayershell.keyboardFocus: barHover.hovered && !root.calm && (root.mode === "" || root.mode === "preview") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        function stops() { return ["#pin"].concat(root.apps, ["#apps"]) }
        function aim(key) {
            if (key === "#pin") return root.enter(key, root.word(root.pinned ? "Unpin" : "Pin"), pinBtn.mapToItem(null, pinBtn.width / 2, 0).x)
            if (key === "#apps") return root.enter(key, root.word("Search apps"), appsBtn.mapToItem(null, appsBtn.width / 2, 0).x)
            const it = appsRep.itemAt(root.apps.indexOf(key))
            if (it) root.enter(key, it.entry?.name ?? key, it.mapToItem(null, it.width / 2, 0).x)
        }
        function step(d) {
            const l = stops(), n = l.length, i = l.indexOf(root.hot)
            aim(l[i < 0 ? (d > 0 ? 0 : n - 1) : (i + d + n) % n])
        }
        function poke() {
            const key = root.hot
            if (key === "#pin") return root.save("poodlebar_Pinned", !root.pinned)
            if (key === "#apps") return root.pick()
            const it = appsRep.itemAt(root.apps.indexOf(key))
            if (!it || !it.entry) return
            if (it.wins.length === 0) return root.launch(it.entry)
            root.pvSel = 0
            root.preview(key, it.mapToItem(null, it.width / 2, 0).x)
        }
        color: "transparent"
        mask: Region { item: root.shown ? zone : strip }

        Item {
            id: face
            anchors.fill: parent
            opacity: Reveal.glass
            focus: true
            Keys.onPressed: e => {
                const k = e.key
                if (root.mode === "preview") {
                    const n = root.openWins.length
                    if (n === 0) return
                    if (k === Qt.Key_Left) root.pvSel = (Math.max(0, root.pvSel) + n - 1) % n
                    else if (k === Qt.Key_Right) root.pvSel = (root.pvSel + 1) % n
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                        const h = root.openWins[Math.max(0, root.pvSel)]
                        if (h) { root.focusWin(h); root.closeAll() }
                    }
                    else if (k === Qt.Key_Escape || k === Qt.Key_Down) root.closeAll()
                    else return
                } else if (k === Qt.Key_Left || k === Qt.Key_Up) win.step(-1)
                else if (k === Qt.Key_Right || k === Qt.Key_Down) win.step(1)
                else if (k === Qt.Key_Return || k === Qt.Key_Enter) win.poke()
                else return
                e.accepted = true
            }
            HoverHandler { id: barHover; onHoveredChanged: if (hovered) face.forceActiveFocus(); else { root.calm = false; root.hot = "" } }
            Item { id: zone; x: bar.x; y: win.labelH; width: bar.width; height: parent.height - win.labelH }

            Typer {
                visible: root.s("poodlebar_Label")
                x: Math.max(0, Math.min(root.hotX - width / 2, parent.width - width))
                y: bar.y - height - win.gap * 0.4
                want: root.hot !== "" && root.mode === "" && root.shown ? root.hotName : ""
                caret: root.s("poodlebar_LabelCursor")
                font.family: root.font
                font.pixelSize: win.labelSize
                color: root.col(root.s("poodlebar_LabelColor"))
            }
            Item { id: strip; x: bar.x; y: parent.height - 2; width: bar.width; height: 2 }

            Rectangle {
                id: bar
                x: (parent.width - width) / 2
                y: root.shown ? win.labelH + win.gap : parent.height
                width: tray.width + win.u * 0.5
                height: win.u
                radius: Math.min(root.s("poodlebar_Radius"), height / 2)
                color: root.col(root.s("poodlebar_Color"))
                border.width: root.s("poodlebar_Border") ? root.s("poodlebar_BorderSize") : 0
                border.color: root.col(root.s("poodlebar_BorderColor"))
                Behavior on y { NumberAnimation { duration: Motion.span(root.time); easing.type: root.ease } }
                Behavior on width { NumberAnimation { duration: Motion.span(root.time); easing.type: root.ease } }
                Behavior on color { ColorAnimation { duration: Motion.span(root.time) } }

                Row {
                    id: tray
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: win.u * 0.15

                    Icon {
                        id: pinBtn
                        anchors.verticalCenter: parent.verticalCenter
                        scale: root.hot === "#pin" ? 1.25 : 1
                        Behavior on scale { NumberAnimation { duration: Motion.span(120); easing.type: Easing.OutCubic } }
                        source: root.glyph(root.s(root.pinned ? "poodlebar_PinIcon" : "poodlebar_PinOffIcon"))
                        family: root.iconFont
                        size: win.ink * 0.35
                        color: root.col(root.s(root.pinned ? "poodlebar_ActiveColor" : "poodlebar_TextColor"))
                        Behavior on color { ColorAnimation { duration: Motion.span(150) } }
                        TapHandler { onTapped: root.save("poodlebar_Pinned", !root.pinned) }
                        HoverHandler { onHoveredChanged: hovered ? root.enter("#pin", root.word(root.pinned ? "Unpin" : "Pin"), parent.mapToItem(null, parent.width / 2, 0).x) : root.leave("#pin") }
                    }

                    Repeater {
                        id: appsRep
                        model: root.apps.length

                        Item {
                            id: g
                            required property int index
                            readonly property string key: String(root.apps[index] ?? "")
                            readonly property var entry: {
                                const known = DesktopEntries.applications.values.length
                                return known >= 0 ? DesktopEntries.byId(key) : null
                            }
                            readonly property var wins: Hyprland.toplevels.values.filter(h => root.owner(h) === key)
                            readonly property bool focused: wins.some(h => h.activated)
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(win.u * 0.75 / 2) * 2
                            height: win.u

                            Rectangle {
                                anchors.centerIn: ic
                                width: Math.round(win.u * 0.72 / 2) * 2
                                height: width
                                radius: width * 0.28
                                color: root.col(root.s("poodlebar_HoverColor"))
                                opacity: root.hot === g.key ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Motion.span(120) } }
                            }

                            IconImage {
                                id: ic
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -Math.round(win.u * 0.06)
                                implicitSize: Math.round(win.ink * 0.55 / 2) * 2
                                source: Quickshell.iconPath(g.entry?.icon ?? "", "application-x-executable")
                                scale: tap.pressed ? 0.9 : 1
                                Behavior on scale { NumberAnimation { duration: Motion.span(120); easing.type: Easing.OutCubic } }
                            }
                            IconImage {
                                anchors.fill: ic
                                visible: root.s("poodlebar_Tint")
                                source: ic.source
                                opacity: root.s("poodlebar_TintStrength")
                                layer.enabled: visible
                                layer.effect: MultiEffect { brightness: 1.0; colorization: 1.0; colorizationColor: root.tintColor }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: win.u * 0.07
                                width: g.focused ? win.u * 0.22 : g.wins.length > 1 ? win.u * 0.12 : height
                                height: win.u * 0.05
                                radius: height / 2
                                color: root.col(root.s(g.focused ? "poodlebar_ActiveColor" : "poodlebar_TextColor"))
                                opacity: g.wins.length === 0 ? 0 : g.focused ? 1 : 0.5
                                Behavior on width { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: Motion.span(200) } }
                                Behavior on color { ColorAnimation { duration: Motion.span(200) } }
                            }

                            MouseArea {
                                id: tap
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.enter(g.key, g.entry?.name ?? g.key, g.mapToItem(null, g.width / 2, 0).x)
                                onExited: root.leave(g.key)
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                onClicked: e => {
                                    if (!g.entry) { if (e.button === Qt.RightButton) root.unpin(g.key); return }
                                    const x = g.mapToItem(null, g.width / 2, 0).x
                                    if (e.button === Qt.RightButton) return root.ask(g.entry, x, -1)
                                    if (e.button === Qt.MiddleButton || g.wins.length === 0) return root.launch(g.entry)
                                    root.pvSel = -1
                                    root.preview(g.key, x)
                                }
                            }
                        }
                    }

                    Icon {
                        id: appsBtn
                        anchors.verticalCenter: parent.verticalCenter
                        scale: root.hot === "#apps" ? 1.25 : 1
                        Behavior on scale { NumberAnimation { duration: Motion.span(120); easing.type: Easing.OutCubic } }
                        source: root.glyph(root.s("poodlebar_AppsIcon"))
                        family: root.iconFont
                        size: win.ink * 0.4
                        color: root.col(root.s(root.mode === "picker" || root.under === "picker" ? "poodlebar_ActiveColor" : "poodlebar_TextColor"))
                        Behavior on color { ColorAnimation { duration: Motion.span(150) } }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -win.u * 0.1
                            hoverEnabled: true
                            onEntered: root.enter("#apps", root.word("Search apps"), parent.mapToItem(null, parent.width / 2, 0).x)
                            onExited: root.leave("#apps")
                            onClicked: root.pick()
                        }
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.mode !== "" || root.pop > 0

        PanelWindow {
            id: over
            readonly property real u: win.u
            readonly property real roof: height - win.u - win.gap * 2
            readonly property real edge: root.s("poodlebar_Border") ? root.s("poodlebar_BorderSize") : 0
            readonly property bool list: (root.held === "picker" && root.pop > 0) || root.under === "picker"

            screen: win.screen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "poodlebar-popup"
            WlrLayershell.keyboardFocus: root.mode === "" || root.mode === "preview" ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
            color: "transparent"
            mask: Region { item: root.mode === "" ? none : root.mode === "preview" ? pv : fill }
            Component.onDestruction: root.pvHover = false

            function aim() {
                if (root.mode === "picker") {
                    if (search.text !== root.query) search.text = root.query
                    search.forceActiveFocus()
                } else keys.forceActiveFocus()
            }
            Component.onCompleted: aim()
            Connections { target: root; function onModeChanged() { over.aim() } }

            Item {
                id: fill
                anchors.fill: parent

                Item { id: none; width: 0; height: 0 }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.mode !== "" && root.mode !== "preview"
                    acceptedButtons: Qt.AllButtons
                    onPressed: root.mode === "picker" ? root.closeAll() : root.back()
                }

                Item {
                    id: keys
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) root.back()
                        else if (root.mode === "menu") {
                            if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) root.row = (root.row + 1) % 3
                            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) root.row = root.row <= 0 ? 2 : root.row - 1
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (root.row >= 0) root.act(root.row) }
                            else return
                        } else if (root.mode === "confirm") {
                            if (e.key === Qt.Key_Left || e.key === Qt.Key_Right || e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) root.sure = !root.sure
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.sure ? root.remove() : root.back()
                            else return
                        } else return
                        e.accepted = true
                    }
                }

                Rectangle {
                    id: pv
                    visible: root.held === "preview" && root.pop > 0
                    opacity: root.pop
                    scale: 0.96 + 0.04 * root.pop
                    transformOrigin: Item.Bottom
                    x: Math.max(0, Math.min(root.openX - width / 2, fill.width - width))
                    y: over.roof - height
                    width: prow.width + over.u * 0.4
                    height: prow.height + over.u * 0.4
                    radius: root.s("poodlebar_PopupRadius")
                    color: root.col(root.s("poodlebar_Color"))
                    border.width: over.edge
                    border.color: root.col(root.s("poodlebar_BorderColor"))

                    HoverHandler { onHoveredChanged: root.pvHover = hovered }

                    Row {
                        id: prow
                        anchors.centerIn: parent
                        spacing: over.u * 0.25

                        Repeater {
                            model: ScriptModel { values: root.openWins }

                            Item {
                                id: card
                                required property var modelData
                                required property int index
                                readonly property var actual: modelData.lastIpcObject?.size
                                readonly property size src: actual ? Qt.size(actual[0], actual[1]) : shot.hasContent ? shot.sourceSize : Qt.size(16, 10)
                                readonly property real fit: Math.min(over.u * root.s("poodlebar_PreviewWidth") / src.width, over.u * root.s("poodlebar_PreviewHeight") / src.height)
                                readonly property real line: Math.max(2, over.u * 0.04)
                                width: src.width * fit
                                height: src.height * fit

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: root.s("poodlebar_PreviewRadius")
                                    color: root.col(root.s("poodlebar_HoverColor"))

                                    ScreencopyView {
                                        id: shot
                                        anchors.fill: parent
                                        captureSource: card.modelData.wayland
                                        live: false
                                        Component.onCompleted: captureFrame()
                                        layer.enabled: true
                                        layer.smooth: true
                                        layer.mipmap: true
                                        layer.effect: root.s("poodlebar_PreviewBlur") > 0 ? blurFx : null
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -card.line
                                    radius: root.s("poodlebar_PreviewRadius") + card.line
                                    color: "transparent"
                                    border.width: card.line
                                    border.color: root.col(root.s("poodlebar_ActiveColor"))
                                    opacity: cardMa.containsMouse || root.pvSel === card.index ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Motion.span(120) } }
                                }

                                MouseArea {
                                    id: cardMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: { root.focusWin(card.modelData); root.closeAll() }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: picker
                    visible: over.list
                    opacity: root.under === "picker" ? 1 : root.pop
                    scale: root.under === "picker" ? 1 : 0.97 + 0.03 * root.pop
                    transformOrigin: Item.Bottom
                    x: (fill.width - width) / 2
                    y: over.roof - height
                    width: Math.min(fill.width, over.u * root.s("poodlebar_PickerWidth"))
                    height: Math.min(over.roof, over.u * root.s("poodlebar_PickerHeight"))
                    radius: root.s("poodlebar_PopupRadius")
                    color: root.col(root.s("poodlebar_Color"))
                    border.width: over.edge
                    border.color: root.col(root.s("poodlebar_BorderColor"))

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    Rectangle {
                        id: field
                        x: over.u * 0.25
                        y: over.u * 0.25
                        width: parent.width - x * 2
                        height: over.u * 0.55
                        radius: height / 2
                        color: root.col(root.s("poodlebar_FieldColor"))

                        Text {
                            anchors.fill: search
                            verticalAlignment: Text.AlignVCenter
                            visible: search.text === ""
                            text: root.word("Search apps")
                            font.family: root.font
                            font.pixelSize: search.font.pixelSize
                            color: root.col(root.s("poodlebar_TextColor"))
                            opacity: 0.5
                        }

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: field.height * 0.45
                            anchors.rightMargin: field.height * 0.45
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            font.family: root.font
                            font.pixelSize: over.u * 0.24
                            color: root.col(root.s("poodlebar_TextColor"))
                            selectionColor: root.col(root.s("poodlebar_ActiveColor"))
                            selectedTextColor: root.col(root.s("poodlebar_Color"))
                            onTextChanged: { if (root.query !== text) { root.query = text; root.sel = 0 } }
                            Keys.onPressed: e => {
                                const n = root.found.length, c = Math.max(1, root.s("poodlebar_PickerColumns"))
                                if (e.key === Qt.Key_Escape) root.closeAll()
                                else if (e.key === Qt.Key_Right) root.sel = Math.min(n - 1, root.sel + 1)
                                else if (e.key === Qt.Key_Left) root.sel = Math.max(0, root.sel - 1)
                                else if (e.key === Qt.Key_Down) root.sel = Math.min(n - 1, root.sel + c)
                                else if (e.key === Qt.Key_Up) root.sel = Math.max(0, root.sel - c)
                                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                    const a = root.found[root.sel]
                                    if (a) (e.modifiers & Qt.ShiftModifier) ? root.flip(a.id) : root.launch(a)
                                } else return
                                e.accepted = true
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: grid
                        visible: root.found.length === 0
                        text: root.word("No apps found")
                        font.family: root.font
                        font.pixelSize: over.u * 0.24
                        color: root.col(root.s("poodlebar_TextColor"))
                        opacity: 0.5
                    }

                    GridView {
                        id: grid
                        readonly property int columns: Math.max(1, root.s("poodlebar_PickerColumns"))
                        readonly property bool names: root.s("poodlebar_PickerNames")
                        anchors { fill: parent; margins: over.u * 0.2; topMargin: field.y + field.height + over.u * 0.2 }
                        clip: true
                        cellWidth: width / columns
                        cellHeight: cellWidth * (names ? 1.12 : 1)
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.found
                        currentIndex: root.sel
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                        delegate: Item {
                            id: d
                            required property var modelData
                            required property int index
                            readonly property bool fixed: root.apps.includes(modelData.id)
                            readonly property bool current: root.sel === index
                            width: grid.cellWidth
                            height: grid.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: root.s("poodlebar_PopupRadius") * 0.7
                                color: root.col(root.s("poodlebar_HoverColor"))
                                opacity: d.current ? 1 : d.fixed ? 0.45 : 0
                                border.width: d.current ? Math.max(1, over.u * 0.03) : 0
                                border.color: root.col(root.s("poodlebar_ActiveColor"))
                                Behavior on opacity { NumberAnimation { duration: Motion.span(100) } }
                            }

                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: parent.width * (grid.names ? 0.14 : 0.2)
                                implicitSize: parent.width * (grid.names ? 0.5 : 0.6)
                                source: Quickshell.iconPath(d.modelData.icon, "application-x-executable")
                            }

                            Text {
                                visible: grid.names
                                x: parent.width * 0.08
                                y: parent.width * 0.7
                                width: parent.width * 0.84
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: d.modelData.name ?? ""
                                font.family: root.font
                                font.pixelSize: over.u * 0.17
                                color: root.col(root.s("poodlebar_TextColor"))
                            }

                            Text {
                                visible: d.fixed
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: parent.width * 0.1
                                text: root.glyph(root.s("poodlebar_PinIcon"))
                                font.family: root.iconFont
                                font.pixelSize: over.u * 0.18
                                color: root.col(root.s("poodlebar_ActiveColor"))
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                onPositionChanged: root.sel = d.index
                                onClicked: e => {
                                    if (e.button === Qt.RightButton) {
                                        const p = mapToItem(fill, e.x, e.y)
                                        return root.ask(d.modelData, p.x, p.y)
                                    }
                                    if (e.button === Qt.MiddleButton) return root.flip(d.modelData.id)
                                    root.launch(d.modelData)
                                }
                            }
                        }
                    }

                    Scroller { view: grid }
                }

                Rectangle {
                    id: menu
                    readonly property var rows: root.target ? [root.word(root.targetWins > 0 ? "Open new window" : "Open"), root.word(root.isPinned(root.target.id) ? "Unpin" : "Pin"), root.word("Uninstall")] : []
                    readonly property real rowH: over.u * 0.6
                    visible: root.held === "menu" && root.pop > 0
                    opacity: root.under === "picker" && root.mode === "menu" ? 1 : root.pop
                    x: Math.max(0, Math.min(root.spot.x - width / 2, fill.width - width))
                    y: Math.max(0, (root.spot.y < 0 ? over.roof : root.spot.y) - height)
                    width: over.u * root.s("poodlebar_MenuWidth")
                    height: rowH * rows.length + over.edge * 2
                    radius: root.s("poodlebar_MenuRadius")
                    color: root.col(root.s("poodlebar_MenuColor"))
                    border.width: over.edge
                    border.color: root.col(root.s("poodlebar_BorderColor"))

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    Column {
                        x: over.edge
                        y: over.edge
                        width: parent.width - over.edge * 2

                        Repeater {
                            model: menu.rows

                            Rectangle {
                                id: entry
                                required property string modelData
                                required property int index
                                readonly property bool hot: root.row === index
                                width: parent.width
                                height: menu.rowH
                                color: hot ? root.col(root.s("poodlebar_MenuHoverColor")) : "transparent"
                                Behavior on color { ColorAnimation { duration: Motion.span(100) } }

                                Text {
                                    x: over.u * 0.25
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - x * 2
                                    elide: Text.ElideRight
                                    text: entry.modelData
                                    font.family: root.font
                                    font.pixelSize: over.u * 0.24
                                    color: root.col(root.s(entry.hot ? "poodlebar_MenuHoverTextColor" : entry.index === 2 ? "poodlebar_MenuDangerColor" : "poodlebar_MenuTextColor"))
                                    Behavior on color { ColorAnimation { duration: Motion.span(100) } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: root.row = entry.index
                                    onExited: if (root.row === entry.index) root.row = -1
                                    onClicked: root.act(entry.index)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: confirm
                    visible: root.held === "confirm" && root.pop > 0
                    opacity: root.under === "picker" && root.mode === "confirm" ? 1 : root.pop
                    x: Math.max(0, Math.min(root.spot.x - width / 2, fill.width - width))
                    y: Math.max(0, (root.spot.y < 0 ? over.roof : root.spot.y) - height)
                    width: over.u * Math.max(5, root.s("poodlebar_MenuWidth"))
                    height: sureText.height + over.u * 1.25 + over.edge * 2
                    radius: root.s("poodlebar_MenuRadius")
                    color: root.col(root.s("poodlebar_MenuColor"))
                    border.width: over.edge
                    border.color: root.col(root.s("poodlebar_BorderColor"))

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    Text {
                        id: sureText
                        x: over.u * 0.3
                        y: over.u * 0.3
                        width: parent.width - x * 2
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        text: root.word("Are you sure you want to uninstall %1?").replace("%1", String(root.target?.name ?? ""))
                        font.family: root.font
                        font.pixelSize: over.u * 0.24
                        color: root.col(root.s("poodlebar_MenuTextColor"))
                    }

                    Row {
                        x: over.edge
                        y: parent.height - height - over.edge
                        width: parent.width - over.edge * 2
                        height: over.u * 0.6

                        Repeater {
                            model: [root.title(root.word("yes")), root.title(root.word("no"))]

                            Rectangle {
                                id: choice
                                required property string modelData
                                required property int index
                                readonly property bool hot: root.sure === (index === 0)
                                width: parent.width / 2
                                height: parent.height
                                color: hot ? root.col(root.s("poodlebar_MenuHoverColor")) : "transparent"
                                Behavior on color { ColorAnimation { duration: Motion.span(100) } }

                                Text {
                                    anchors.centerIn: parent
                                    text: choice.modelData
                                    font.family: root.font
                                    font.pixelSize: over.u * 0.24
                                    color: root.col(root.s(choice.hot ? "poodlebar_MenuHoverTextColor" : choice.index === 0 ? "poodlebar_MenuDangerColor" : "poodlebar_MenuTextColor"))
                                    Behavior on color { ColorAnimation { duration: Motion.span(100) } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: root.sure = choice.index === 0
                                    onClicked: choice.index === 0 ? root.remove() : root.back()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
