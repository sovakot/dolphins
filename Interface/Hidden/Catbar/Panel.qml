import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Backend"

Item {
    id: panel

    required property var bar
    property string activeId: ""
    property string tab: ""
    property real anchorAt: 0
    property bool open: false
    property bool warm: false
    property bool jump: false
    property bool staged: false
    property real slide: Math.max(0, paged.indexOf(view))
    property real shown: open ? 1 : 0
    property var tipOwner: null
    property string tipText: ""
    property real tipAt: 0

    readonly property var look: ({
        pad: 0.5,
        tileIcon: 0.5, tileLabel: 0.28,
        titleSize: 0.4, titleH: 0.85, titleY: 0,
        switchW: 0.85, switchH: 0.46,
        labelSize: 0.3, labelH: 0.7,
        listSize: 0.32, rowH: 0.75, iconSmall: 0.38,
        infoSize: 0.29, infoH: 0.55,
        btnSize: 0.29, btnH: 0.6, btnPad: 0.3,
        fade: 200, glide: 260,
    })
    property int depth: 0
    property string cursor: ""
    readonly property var stops: {
        const out = []
        for (const g of bar.groups) {
            const parts = g.members.map(m => bar.widgets[m]).filter(w => !!w && !w.ghost).sort((a, b) => a.start - b.start)
            if (parts.length) out.push({ g: g, w: parts[0] })
        }
        return out.sort((a, b) => a.w.start - b.w.start)
    }
    property color cBg: col("Color")
    property color cBorder: col("BorderColor")
    property color cText: col("TextColor")
    property color cActive: col("ActiveColor")
    property color cInactive: col("TabColor")
    readonly property var k: Object.assign({
        bg: cBg, border: cBorder, text: cText,
        active: cActive, inactive: cInactive,
        font: bar.global("IconFont") ?? "", font2: bar.global("TextFont") ?? "",
        lang: bar.lang, words: bar.words
    }, look)

    readonly property bool live: shown > 0
    readonly property bool vert: bar.vert
    readonly property string side: bar.pos
    readonly property int push: bar.far ? -1 : 1
    readonly property real origin: vert ? bar.body.y : bar.body.x
    readonly property real tipEdge: Math.round(bar.gap + bar.thick * 1.15)
    readonly property real boxEdge: Math.round(bar.gap + bar.thick + offset)
    readonly property var group: bar.groups.find(g => g.id === activeId) ?? null
    readonly property var members: group ? group.members : []
    readonly property string first: members.find(m => !!bar.widgets[m]?.page) ?? ""
    readonly property string view: members.includes(tab) && !!bar.widgets[tab]?.page ? tab : first
    readonly property var paged: members.filter(m => !!bar.widgets[m]?.page)
    readonly property var titled: members.map(m => bar.widgets[m]).find(w => !!w && !!w.banner) ?? null
    property real unit: bar.thick * v("Scale")
    readonly property real pad: unit * look.pad
    readonly property real offset: unit * v("Gap")
    property real boxWidth: unit * v("Width")
    property real boxHeight: unit * v("Height")

    readonly property rect area: {
        if (!(live || warm) || !bar.screen) return Qt.rect(0, 0, 0, 0)
        const at = slot(anchorAt, vert ? boxHeight : boxWidth, offset)
        const x = vert ? (side === "left" ? boxEdge : bar.screen.width - boxEdge - boxWidth) : at
        const y = vert ? at : (side === "top" ? boxEdge : bar.screen.height - boxEdge - boxHeight)
        return Qt.rect(x, y, boxWidth, boxHeight)
    }

    function v(key) { return bar.panel(activeId, key) }
    function col(key) { return bar.panelColor(activeId, key) }
    function slot(at, size, pad) { return Math.round(Math.max(pad, Math.min(bar.along - size - pad, origin + at - size / 2))) }
    function click(g, w, cx) {
        bar.busy = true
        if (!g.paged) { if (w) w.tapped(); return }
        closer.stop()
        if (open && activeId === g.id) { open = false; return }
        const fresh = activeId !== g.id
        jump = true
        if (fresh) {
            activeId = g.id
            tab = ""
        }
        anchorAt = cx
        depth = paged.length > 1 ? 0 : 1
        jump = false
        if (open) return
        warm = true
        bar.stage(() => { panel.warm = false; panel.open = true })
    }
    function key(name) {
        const p = pageOf(view)
        if (depth > 0 && p && typeof p.key === "function" && p.key(name)) return
        if (name === "back") { open = false; return }
        if (name === "left" || name === "right") {
            const n = paged.length
            if (n > 1) tab = paged[(paged.indexOf(view) + (name === "left" ? n - 1 : 1)) % n]
        }
        else if (depth === 0 && (name === "down" || name === "enter")) depth = 1
        else if (depth > 0 && name === "up" && paged.length > 1) depth = 0
    }
    function nav(name) {
        if (open) { key(name); return }
        const list = stops, n = list.length
        if (!n) return
        const i = list.findIndex(s => s.g.id === cursor)
        const next = name === (vert ? "down" : "right"), prev = name === (vert ? "up" : "left")
        if (next || prev) { cursor = list[i < 0 ? (next ? 0 : n - 1) : (i + (next ? 1 : n - 1)) % n].g.id; return }
        if (name !== "enter" || i < 0) return
        const s = list[i], p = pills.itemAt(bar.groups.findIndex(g => g.id === s.g.id))
        click(s.g, s.w, p ? p.at + p.len / 2 : s.w.start + s.w.span / 2)
    }
    function settle() {
        if (!open || bar.hold || boxHov.hovered || Reveal.all) return
        const page = pageOf(view)
        if (page && page.typing === true) return
        for (let i = 0; i < pills.count; i++) {
            const it = pills.itemAt(i)
            if (it && it.over && it.current) return
        }
        if (!closer.running) closer.restart()
    }
    function hint(owner, text, cx) {
        if (text) { tipOwner = owner; tipText = text; tipAt = cx }
        else if (tipOwner === owner) { tipOwner = null; tipText = "" }
    }
    function keep() { closer.stop() }
    function leave() { if (open && !bar.hold && !Reveal.all) closer.restart() }
    function parade(way) {
        const list = stops.filter(s => s.g.paged), n = list.length
        if (!n) return
        if (open && way !== 0) {
            const k = paged.indexOf(view) + way
            if (k >= 0 && k < paged.length) { tab = paged[k]; return }
        }
        const i = list.findIndex(s => s.g.id === activeId)
        const s = list[!open || i < 0 ? (way < 0 ? n - 1 : 0) : (i + way + n) % n]
        if (open && s.g.id === activeId) return
        const p = pills.itemAt(bar.groups.findIndex(g => g.id === s.g.id))
        closer.stop()
        staged = true
        click(s.g, s.w, p ? p.at + p.len / 2 : s.w.start + s.w.span / 2)
        if (way < 0 && paged.length) tab = paged[paged.length - 1]
    }
    function pageOf(key) {
        const i = members.indexOf(key)
        const l = i < 0 ? null : pages.itemAt(i)
        return l ? l.item : null
    }
    function tap(key) {
        const w = bar.widgets[key]
        if (w && !w.page) { w.tapped(); return }
        const p = pageOf(key)
        if (view !== key) tab = key
        else if (p && p.sel) p.back()
    }

    anchors.fill: parent

    Behavior on cBg { enabled: panel.open; Tint {} }
    Behavior on cBorder { enabled: panel.open; Tint {} }
    Behavior on cText { enabled: panel.open; Tint {} }
    Behavior on cActive { enabled: panel.open; Tint {} }
    Behavior on cInactive { enabled: panel.open; Tint {} }
    Behavior on unit { enabled: panel.open; Glide {} }
    Behavior on boxWidth { enabled: panel.open; Glide {} }
    Behavior on boxHeight { enabled: panel.open; Glide {} }
    onOpenChanged: if (open) keys.forceActiveFocus()
    Behavior on slide { enabled: !panel.jump; NumberAnimation { duration: Motion.span(panel.look.glide); easing.type: Easing.OutCubic } }
    Behavior on shown { NumberAnimation { duration: Motion.span(panel.v("SlideTime")); easing.type: Easing.OutCubic } }
    Timer { id: closer; interval: 300; onTriggered: if (!Reveal.all) panel.open = false }
    Connections {
        target: Reveal
        function onAllChanged() {
            if (Reveal.all) { if (!panel.open && !Reveal.editor) panel.parade(0); return }
            if (panel.staged) { panel.staged = false; panel.open = false }
        }
    }
    Timer { interval: 1000; repeat: true; running: panel.open; onTriggered: panel.settle() }
    Binding { target: panel.bar; property: "litGroup"; value: panel.open ? panel.activeId : "" }
    Connections {
        target: panel.bar
        function onGroupsChanged() { panel.tipOwner = null; panel.tipText = "" }
        function onHoldChanged() { if (!panel.bar.hold) { panel.cursor = ""; panel.settle() } }
    }

    Repeater {
        id: pills
        model: panel.bar.groups

        Item {
            id: pill
            required property var modelData
            readonly property var parts: modelData.members.map(m => panel.bar.widgets[m]).filter(w => !!w && !w.ghost)
            readonly property real a1: parts.length ? Math.min(...parts.map(i => i.start)) : 0
            readonly property real a2: parts.length ? Math.max(...parts.map(i => i.start + i.span)) : 0
            readonly property real span: a2 - a1
            readonly property real side: Math.round(panel.bar.thick * 0.3)
            readonly property real slim: Math.round(panel.bar.thick * (panel.vert ? 0.9 : 0.75) / 2) * 2
            readonly property bool single: parts.length === 1
            readonly property bool round: single && span <= panel.bar.thick
            readonly property real tall: round ? Math.round(Math.min(panel.bar.thick, Math.max(panel.bar.thick * 0.75, span + side)) / 2) * 2 : slim
            readonly property real len: round ? tall : span + side * 2
            readonly property real at: Math.round((a1 + a2 - len) / 2)
            readonly property bool current: (panel.open && panel.activeId === modelData.id) || (single && parts[0].held)
            readonly property bool chosen: panel.cursor === modelData.id
            readonly property bool over: hov.hovered
            readonly property var near: {
                if (chosen) return parts.slice().sort((a, b) => a.start - b.start)[0]
                const p = at + (panel.vert ? hov.point.position.y : hov.point.position.x)
                let best = parts[0], far = 1e9
                for (const w of parts) {
                    const d = Math.abs(w.start + w.span / 2 - p)
                    if (d < far) { far = d; best = w }
                }
                return best
            }
            readonly property string tip: (hov.hovered || chosen) && near ? near.tip : ""

            visible: parts.length > 0
            x: panel.vert ? 0 : at
            y: panel.vert ? at : 0
            width: panel.vert ? parent.width : len
            height: panel.vert ? len : parent.height
            onTipChanged: panel.hint(pill, tip, near ? near.start + near.span / 2 : 0)
            onNearChanged: if (tip) panel.hint(pill, tip, near.start + near.span / 2)

            Rectangle {
                anchors.centerIn: parent
                width: panel.vert ? pill.tall : pill.len
                height: panel.vert ? pill.len : pill.tall
                radius: Math.min(width, height) / 2
                color: panel.bar.panelColor(pill.modelData.id, pill.current ? "ActiveColor" : "PillColor")
                opacity: pill.current || hov.hovered || pill.chosen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
            }

            Rectangle {
                visible: pill.chosen
                anchors.centerIn: parent
                width: panel.vert ? pill.tall : pill.len
                height: panel.vert ? pill.len : pill.tall
                radius: Math.min(width, height) / 2
                color: "transparent"
                border.width: Math.max(2, Math.round(panel.bar.thick * 0.06))
                border.color: panel.bar.panelColor(pill.modelData.id, "ActiveColor")
            }

            HoverHandler { id: hov; onHoveredChanged: hovered && pill.current ? panel.keep() : panel.leave() }
            MouseArea { anchors.fill: parent; onPressed: panel.click(pill.modelData, pill.near, pill.at + pill.len / 2) }
        }
    }

    PanelWindow {
        id: tipWin
        screen: panel.bar.screen
        visible: panel.tipText !== "" && !panel.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        implicitWidth: tipBox.width
        implicitHeight: tipBox.height
        anchors { top: panel.side !== "bottom"; bottom: panel.side === "bottom"; left: panel.side !== "right"; right: panel.side === "right" }
        margins {
            top: panel.vert ? panel.slot(panel.tipAt, tipBox.height, 0) : panel.side === "top" ? panel.tipEdge : 0
            bottom: panel.side === "bottom" ? panel.tipEdge : 0
            left: !panel.vert ? panel.slot(panel.tipAt, tipBox.width, 0) : panel.side === "left" ? panel.tipEdge : 0
            right: panel.side === "right" ? panel.tipEdge : 0
        }

        Rectangle {
            id: tipBox
            width: Math.ceil(tipLabel.implicitWidth + panel.bar.thick * 0.7)
            height: Math.round(panel.bar.thick * 0.8)
            radius: height / 2
            color: panel.bar.panelColor("", "Color")
            border.width: panel.bar.panel("", "Border") ? panel.bar.panel("", "BorderSize") : 0
            border.color: panel.bar.panelColor("", "BorderColor")

            Text {
                id: tipLabel
                anchors.centerIn: parent
                text: panel.tipText
                color: panel.bar.panelColor("", "TextColor")
                font.family: panel.bar.global("TextFont") ?? ""
                font.pixelSize: panel.bar.thick * 0.4
            }
        }
    }

    PanelWindow {
        id: win
        screen: panel.bar.screen
        visible: panel.live || panel.warm
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: panel.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        implicitWidth: panel.boxWidth
        implicitHeight: panel.boxHeight
        anchors { top: panel.side !== "bottom"; bottom: panel.side === "bottom"; left: panel.side !== "right"; right: panel.side === "right" }
        margins {
            top: panel.vert ? panel.slot(panel.anchorAt, panel.boxHeight, panel.offset) : panel.side === "top" ? panel.boxEdge : 0
            bottom: panel.side === "bottom" ? panel.boxEdge : 0
            left: !panel.vert ? panel.slot(panel.anchorAt, panel.boxWidth, panel.offset) : panel.side === "left" ? panel.boxEdge : 0
            right: panel.side === "right" ? panel.boxEdge : 0
        }

        Item {
            id: keys
            readonly property var names: ({ [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down", [Qt.Key_Return]: "enter", [Qt.Key_Enter]: "enter", [Qt.Key_Space]: "enter", [Qt.Key_Escape]: "back" })
            anchors.fill: parent
            clip: true
            focus: true
            Keys.onPressed: e => {
                const name = names[e.key]
                if (!name || !keys.activeFocus) return
                panel.key(name)
                e.accepted = true
            }
            HoverHandler { id: boxHov; onHoveredChanged: hovered ? panel.keep() : panel.leave() }

            Rectangle {
                id: box
                width: parent.width
                height: parent.height
                x: panel.vert ? (panel.shown - 1) * panel.unit * panel.push : 0
                y: panel.vert ? 0 : (panel.shown - 1) * panel.unit * panel.push
                opacity: Math.max(panel.shown, panel.warm ? 0.01 : 0)
                radius: panel.unit * panel.v("BorderRadius")
                clip: true
                color: panel.k.bg
                border.width: panel.v("Border") ? panel.v("BorderSize") : 0
                border.color: panel.k.border

                Loader {
                    readonly property var owner: panel.bar.widgets[panel.view] ?? null
                    readonly property real radius: Math.max(0, box.radius - box.border.width)
                    readonly property var c: panel.k
                    readonly property real unit: panel.unit
                    readonly property bool open: panel.open
                    anchors.fill: parent
                    anchors.margins: box.border.width
                    active: (panel.live || panel.warm) && !!owner && !!owner.backdrop
                    sourceComponent: owner ? owner.backdrop : null
                }

                Loader {
                    id: title
                    readonly property var c: panel.k
                    readonly property real unit: panel.unit
                    readonly property bool open: panel.open
                    x: panel.pad
                    y: panel.pad
                    width: parent.width - panel.pad * 2
                    sourceComponent: panel.titled ? panel.titled.banner : null
                }

                Row {
                    id: tiles
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: title.item ? title.y + title.height + panel.unit * 0.3 : panel.pad
                    spacing: panel.unit * 0.2

                    Repeater {
                        model: panel.members

                        Column {
                            id: tile
                            required property string modelData
                            readonly property var item: panel.bar.widgets[modelData] ?? null
                            readonly property string sym: item ? item.icon : ""
                            readonly property bool lit: panel.view === modelData || (!!item && (item.lit || item.held))

                            width: panel.unit * 2.6
                            spacing: panel.unit * 0.1

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: panel.unit * 1.6
                                height: panel.unit
                                HoverHandler { id: over }
                                MouseArea { anchors.fill: parent; onPressed: panel.tap(tile.modelData) }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: tile.lit ? panel.k.active : panel.k.inactive
                                    opacity: tile.lit || over.hovered ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    visible: tile.sym !== ""
                                    source: tile.sym
                                    family: panel.k.font
                                    size: panel.unit * panel.look.tileIcon
                                    color: tile.lit ? panel.k.bg : panel.k.text
                                    Behavior on color { ColorAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: tile.sym === ""
                                    text: tile.modelData.charAt(0).toUpperCase() + tile.modelData.slice(1)
                                    font.family: panel.k.font2
                                    font.pixelSize: panel.unit * panel.look.tileLabel
                                    color: tile.lit ? panel.k.bg : panel.k.text
                                    Behavior on color { ColorAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                                }
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: tile.item ? tile.item.label : ""
                                font.family: panel.k.font2
                                font.pixelSize: panel.unit * panel.look.tileLabel
                                color: panel.k.text
                            }
                        }
                    }
                }

                Item {
                    id: stack
                    readonly property real bleed: Math.min(panel.pad, panel.unit * 0.35)
                    readonly property real lift: panel.unit * 0.12
                    x: panel.pad - bleed
                    y: tiles.y + tiles.height + panel.unit * 0.4 - lift
                    width: parent.width - panel.pad * 2 + bleed * 2
                    height: parent.height - y - panel.pad + bleed
                    clip: true

                    Repeater {
                        id: pages
                        model: panel.members

                        Loader {
                            required property string modelData
                            readonly property var c: panel.k
                            readonly property real unit: panel.unit
                            readonly property bool shown: panel.view === modelData
                            readonly property bool open: panel.open
                            readonly property bool keyed: panel.open && panel.depth > 0 && panel.view === modelData
                            readonly property int spot: panel.paged.indexOf(modelData)
                            function refocus() { keys.forceActiveFocus() }
                            x: stack.bleed + (spot - panel.slide) * (stack.width + panel.pad)
                            y: stack.lift
                            width: stack.width - stack.bleed * 2
                            height: stack.height - stack.lift - stack.bleed
                            visible: spot >= 0 && Math.abs(spot - panel.slide) < 1
                            sourceComponent: panel.bar.widgets[modelData]?.page ?? null
                        }
                    }
                }
            }
        }
    }
}
