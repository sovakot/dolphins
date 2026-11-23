import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Backend"
import "../../Data/Dynamic"

Kit {
    id: root

    required property var bar
    required property var panel

    base: ({
        editor_Show: true, editor_Color: "Background", editor_TextColor: "Text", editor_ActiveColor: "Active", editor_DangerColor: "#e06c75", editor_TextSize: 13, editor_Radius: 16,
        editor_Snap: 0.1, editor_HandleOpacity: 0.16, editor_Width: 17, editor_InspectorWidth: 25, editor_History: 80, editor_Margin: 24, editor_PanelStep: 0.5, editor_PanelMin: 4, editor_PanelMax: 60,
        editor_ResetKeys: ["catbar_Position", "catbar_Height", "catbar_SideAuto", "desktop_X", "desktop_Y", "desktop_Scale"],
        editor_Hidden: [["Catbar", "catbar", "f0c9"], ["Desktop widgets", "desktop", "f017"], ["Taskbar", "poodlebar", "f2d2"], ["Sidebar", "sidebar", "f0db"], ["Touchpad gestures", "touchpad", "f185"], ["Updater", "updater", "f021"], ["Panda Hypr AI", "hyprai", "f1b0"]],
        editor_Binded: [["Snoopy Settings", "settings", "f013"], ["Snoopy Manager", "manager", "f080"], ["AI window", "ai", "f086"], ["Media Player", "media", "f001"], ["Network Connections", "connections", "f0e8"], ["Window view", "windowview", "f009"], ["Lock screen", "lockscreen", "f023"], ["Session menu", "session", "f011"], ["Screenshot tool", "snip", "f0c4"]]
    })

    readonly property bool editing: Reveal.editor && s("editor_Show")
    readonly property color bg: col(s("editor_Color"))
    readonly property color tx: col(s("editor_TextColor"))
    readonly property color hi: col(s("editor_ActiveColor"))
    readonly property color bad: col(s("editor_DangerColor"))
    readonly property real px: Math.max(9, s("editor_TextSize"))
    readonly property real rad: Math.max(0, s("editor_Radius"))
    readonly property real snap: Math.max(0.01, s("editor_Snap"))
    readonly property var sizes: ["Position", "PositionSide", "Scale", "IconScale"]
    property string picked: ""
    property string hot: ""
    property var pending: null
    property var menu: null
    property bool listing: false
    property bool asking: false
    property real dockX: -1
    property real dockY: -1
    property var past: []
    property var ahead: []
    property real stamp: 0
    property bool guide: false
    readonly property var layers: Object.keys(Config.stock).filter(k => /^widget_[A-Za-z0-9]+Show$/.test(k)).map(k => k.slice(7, -4)).sort()
    readonly property var rows: {
        const out = [], stock = Config.stock
        if (picked === "") return out
        for (const k in stock) {
            if (!k.startsWith(picked) || k === picked) continue
            const v = stock[k], t = typeof v
            if (v === null || (t === "object" && !Array.isArray(v))) continue
            const listed = t === "number" && Number.isInteger(v) && Math.abs(v) < 4 && /(Position|Style|Type|Mode|Index)$/.test(k) && !k.startsWith("widget_")
            out.push({ key: k, label: k.slice(picked.length).replace(/([a-z0-9])([A-Z])/g, "$1 $2"), kind: t === "boolean" ? "bool" : t === "number" && !listed ? "num" : "link" })
        }
        return out
    }

    onEditingChanged: {
        Reveal.all = editing
        if (editing) return
        flush()
        calm()
        picked = ""
        hot = ""
        if (panel.open) panel.open = false
    }

    function cap(k) { return k.charAt(0).toUpperCase() + k.slice(1) }
    function name(k) { return word(cap(String(k))) }
    function fit(v, a, b) { return Math.max(a, Math.min(b, v)) }
    function near(v, step) { return Number((Math.round(v / step) * step).toFixed(3)) }
    function size(v) { return near(fit(v, Math.max(1, s("editor_PanelMin")), Math.max(2, s("editor_PanelMax"))), Math.max(0.05, s("editor_PanelStep"))) }
    function calm() {
        menu = null
        listing = false
        asking = false
    }
    function inspect(k) {
        picked = k
        Reveal.inspect(k)
    }
    function pick(k) {
        calm()
        picked = picked === k ? "" : k
    }
    function old(k) {
        if (k.charAt(0) !== "@") return cfg?.[k]
        const at = k.indexOf("|")
        return cfg?.GroupedPanels?.[k.slice(1, at)]?.[k.slice(at + 1)]
    }
    function write(map) {
        const flat = {}
        for (const k in map) {
            if (map[k] === undefined) continue
            if (k.charAt(0) !== "@") { flat[k] = map[k]; continue }
            const at = k.indexOf("|")
            Config.panel(k.slice(1, at), k.slice(at + 1), map[k])
        }
        Config.many(flat)
    }
    function commit(map) {
        const was = {}, keys = Object.keys(map).sort().join(","), now = Date.now(), log = past.slice()
        let changed = false
        for (const k in map) {
            was[k] = old(k)
            if (JSON.stringify(was[k]) !== JSON.stringify(map[k])) changed = true
        }
        if (!changed) return
        const last = log[log.length - 1]
        if (last && last.keys === keys && now - stamp < 900) log[log.length - 1] = { keys: keys, from: last.from, to: Object.assign({}, last.to, map) }
        else log.push({ keys: keys, from: was, to: Object.assign({}, map) })
        while (log.length > Math.max(1, s("editor_History"))) log.shift()
        stamp = now
        past = log
        ahead = []
        write(map)
    }
    function undo() {
        flush()
        if (!past.length) return
        const log = past.slice(), step = log.pop()
        past = log
        ahead = ahead.concat([step])
        stamp = 0
        if (panel.open) panel.open = false
        write(step.from)
    }
    function redo() {
        flush()
        if (!ahead.length) return
        const log = ahead.slice(), step = log.pop()
        ahead = log
        past = past.concat([step])
        stamp = 0
        if (panel.open) panel.open = false
        write(step.to)
    }
    function live(k) { return pending && k in pending ? pending[k] : cfg?.[k] }
    function fine(key) {
        const b = Number(Config.stock[key]) || 0, a = Math.abs(b)
        return Number.isInteger(b) && a >= 4 ? 1 : a >= 10 ? 0.5 : a >= 1 ? 0.05 : 0.01
    }
    function bump(key, way, big) {
        const v = Number(live(key) ?? Config.stock[key]) || 0
        put(key, Number((v + way * fine(key) * (big ? 10 : 1)).toFixed(4)))
    }
    function chosen() { return picked.startsWith("widget_") ? bar.widgets[picked.slice(7).toLowerCase()] ?? null : null }
    function nudge(key, big) {
        const w = chosen(), back = key === Qt.Key_Left || key === Qt.Key_Up, flat = key === Qt.Key_Left || key === Qt.Key_Right, n = big ? 5 : 1
        if (w) {
            if (flat !== bar.vert) put(spotKey(w), near(Math.max(0, Number(live(spotKey(w)) ?? w.s(w.spot + (bar.vert ? "Side" : "")) ?? 0) + (back ? -1 : 1) * snap * n), snap))
            else grow(key === Qt.Key_Up || key === Qt.Key_Right ? 1 : -1)
        } else if (picked === "catbar_") commit({ catbar_Position: [Qt.Key_Up, Qt.Key_Down, Qt.Key_Right, Qt.Key_Left].indexOf(key) })
        else if (picked === "desktop_") {
            const k = flat ? "desktop_X" : "desktop_Y"
            put(k, near(fit(Number(live(k) ?? 0.5) + (back ? -1 : 1) * 0.005 * n, 0, 1), 0.001))
        }
    }
    function grow(way) {
        const w = chosen()
        if (w) { const n = sizeName(w); put(w.prefix + n, near(fit(Number(live(w.prefix + n) ?? w.s(n) ?? 1) + way * 0.05, 0.3, 3), 0.05)) }
        else if (picked === "catbar_") put("catbar_Height", near(fit(Number(live("catbar_Height") ?? 0.035) + way * 0.001, 0.02, 0.08), 0.001))
        else if (picked === "desktop_") put("desktop_Scale", near(fit(Number(live("desktop_Scale") ?? 1) + way * 0.05, 0.3, 3), 0.05))
    }
    function cycle(way) {
        const all = Object.keys(bar.widgets).filter(k => !!bar.widgets[k] && !bar.widgets[k].ghost).sort().map(k => "widget_" + cap(k)).concat(["catbar_", "desktop_"])
        const at = all.indexOf(picked)
        calm()
        picked = all[(at + way + all.length) % all.length]
    }
    function shown(layer) { return cfg?.["widget_" + layer + "Show"] !== false }
    function show(layer, yes) {
        const out = {}
        out["widget_" + layer + "Show"] = yes
        commit(out)
    }
    function put(key, value) {
        const p = pending ?? ({})
        p[key] = value
        pending = p
        if (!beat.running) beat.start()
    }
    function flush() {
        beat.stop()
        const p = pending
        pending = null
        if (p) commit(p)
    }
    function edge(x, y, w, h) {
        const d = { top: y, bottom: h - y, left: x, right: w - x }
        return Object.keys(d).sort((a, b) => d[a] - d[b])[0]
    }
    function spotKey(w) { return w.prefix + w.spot + (bar.vert ? "Side" : "") }
    function sizeName(w) { return typeof w.s("Scale") === "number" ? "Scale" : "IconScale" }
    function groupFor(key) { return bar.groups.find(g => g.members.includes(key)) ?? null }
    function others(key) { return Object.keys(bar.widgets).filter(k => k !== key && !!bar.widgets[k] && !bar.widgets[k].ghost).sort() }
    function links(key) { return "widget_" + cap(key) + "Grouped" }
    function away(key) { return (cfg?.[links(key)] ?? []).filter(x => !(String(x).toLowerCase() in bar.widgets)) }
    function join(key, other) {
        const cur = (cfg?.[links(key)] ?? []).filter(x => String(x).toLowerCase() !== other)
        const out = {}
        out[links(key)] = cur.concat([cap(other)])
        if (panel.open) panel.open = false
        commit(out)
    }
    function leave(key) {
        const g = groupFor(key), out = {}
        if (!g) return
        const rest = g.members.filter(m => m !== key)
        out[links(key)] = away(key)
        rest.forEach((m, i) => out[links(m)] = away(m).concat(i === 0 ? rest.slice(1).map(cap) : []))
        if (panel.open) panel.open = false
        commit(out)
    }
    function showPanel(key) {
        const g = groupFor(key), w = bar.widgets[key]
        if (!g || !g.paged || !w || (panel.open && panel.activeId === g.id)) return
        panel.click(g, w, w.start + w.span / 2)
    }
    function revert(key) {
        const stock = Config.stock, out = {}
        for (const n of sizes) {
            const k = "widget_" + cap(key) + n
            if (stock[k] !== undefined && cfg?.[k] !== stock[k]) out[k] = stock[k]
        }
        flush()
        commit(out)
    }
    function restore() {
        flush()
        const stock = Config.stock, extra = s("editor_ResetKeys"), out = {}
        for (const k in stock) {
            if (!/^widget_[A-Za-z0-9]+(Position|PositionSide|Scale|IconScale|Grouped)$/.test(k) && !extra.includes(k)) continue
            if (JSON.stringify(cfg?.[k]) !== JSON.stringify(stock[k])) out[k] = stock[k]
        }
        if (panel.open) panel.open = false
        const mine = cfg?.GroupedPanels ?? {}, first = stock.GroupedPanels ?? {}
        for (const id in mine) {
            for (const key of ["Width", "Height", "Scale"]) {
                const d = first[id]?.[key] ?? first.Default?.[key]
                if (d !== undefined && mine[id]?.[key] !== d) out["@" + id + "|" + key] = d
            }
        }
        stamp = 0
        commit(out)
        dockX = -1
        dockY = -1
    }

    Timer { id: beat; interval: 50; onTriggered: root.flush() }
    GlobalShortcut { appid: "editor"; name: "toggle"; onPressed: Reveal.editor = !Reveal.editor }

    component Chip: Rectangle {
        id: chip
        property string label: ""
        property string code: ""
        property bool lit: false
        signal tapped()
        width: parent ? parent.width : 0
        height: Math.round(root.px * 2.5)
        radius: height / 2
        color: lit ? Qt.alpha(root.hi, 0.22) : chipArea.containsMouse ? Qt.alpha(root.tx, 0.12) : Qt.alpha(root.tx, 0.05)
        Behavior on color { Tint {} }
        Text { x: Math.round(root.px * 0.9); width: Math.round(root.px * 1.6); anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: root.glyph(chip.code); font.family: root.iconFont; font.pixelSize: root.px; color: chip.lit ? root.hi : root.tx }
        Text { x: Math.round(root.px * 3.1); width: parent.width - x - 10; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: root.word(chip.label); font.family: root.font; font.pixelSize: root.px; color: root.tx }
        MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; onClicked: chip.tapped() }
    }

    component Tag: Rectangle {
        id: tag
        property string label: ""
        property bool lit: false
        signal tapped()
        width: tagText.implicitWidth + Math.round(root.px * 1.6)
        height: Math.round(root.px * 2.1)
        radius: height / 2
        color: lit ? root.hi : tagArea.containsMouse ? Qt.alpha(root.tx, 0.16) : Qt.alpha(root.tx, 0.07)
        Behavior on color { Tint {} }
        Text { id: tagText; anchors.centerIn: parent; text: tag.label; font.family: root.font; font.pixelSize: root.px - 1; color: tag.lit ? root.bg : root.tx }
        MouseArea { id: tagArea; anchors.fill: parent; hoverEnabled: true; onClicked: tag.tapped() }
    }

    component Tool: Rectangle {
        id: tool
        property string label: ""
        property string code: ""
        property bool lit: false
        property bool danger: false
        signal tapped()
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: toolRow.width + Math.round(root.px * 1.6)
        height: Math.round(root.px * 2.4)
        radius: height / 2
        color: lit ? root.hi : toolArea.containsMouse ? (danger ? root.bad : Qt.alpha(root.tx, 0.16)) : Qt.alpha(root.tx, 0.07)
        Behavior on color { Tint {} }
        Row {
            id: toolRow
            anchors.centerIn: parent
            spacing: 6
            Text { visible: tool.code !== ""; anchors.verticalCenter: parent.verticalCenter; text: root.glyph(tool.code); font.family: root.iconFont; font.pixelSize: root.px; color: tool.lit ? root.bg : root.tx }
            Text { visible: tool.label !== ""; anchors.verticalCenter: parent.verticalCenter; text: root.word(tool.label); font.family: root.font; font.pixelSize: root.px; color: tool.lit ? root.bg : root.tx }
        }
        MouseArea { id: toolArea; anchors.fill: parent; hoverEnabled: true; onClicked: tool.tapped() }
    }

    component Head: Text {
        topPadding: Math.round(root.px * 0.6)
        font.family: root.font
        font.pixelSize: root.px
        font.weight: Font.DemiBold
        color: root.hi
    }

    component Card: Rectangle {
        property bool shown: false
        visible: shown
        radius: root.rad
        color: root.bg
        border.width: 1
        border.color: Qt.alpha(root.tx, 0.14)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
    }

    LazyLoader {
        active: root.editing

        PanelWindow {
            id: win
            readonly property var bar: root.bar
            readonly property bool vert: bar.vert
            readonly property real thick: Math.max(1, bar.thick)
            property string aim: ""
            screen: root.bar.screen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "dolphin-editor"
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {
                item: dock
                Region { item: shade }
                Region { item: strip }
                Region { item: deskGrip }
                Region { item: knob }
                Region { item: shut }
                Region { item: list }
                Region { item: sure }
                Region { item: card }
                Region { item: probe }
            }

            Item {
                id: face
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: {
                    if (root.menu || root.listing || root.asking) root.calm()
                    else if (root.picked !== "") root.picked = ""
                    else Reveal.editor = false
                }
                Keys.onPressed: e => {
                    const k = e.key, ctrl = !!(e.modifiers & Qt.ControlModifier), shift = !!(e.modifiers & Qt.ShiftModifier)
                    if (ctrl && k === Qt.Key_Z) { if (shift) root.redo(); else root.undo() }
                    else if (ctrl && k === Qt.Key_Y) root.redo()
                    else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) root.cycle(k === Qt.Key_Backtab || shift ? -1 : 1)
                    else if (k === Qt.Key_Left || k === Qt.Key_Right || k === Qt.Key_Up || k === Qt.Key_Down) root.nudge(k, shift)
                    else if (k === Qt.Key_Plus || k === Qt.Key_Equal) root.grow(1)
                    else if (k === Qt.Key_Minus) root.grow(-1)
                    else if (k === Qt.Key_Delete) { if (root.picked.startsWith("widget_")) root.show(root.picked.slice(7), false) }
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (root.picked !== "") root.inspect(root.picked) }
                    else return
                    e.accepted = true
                }

                Item {
                    id: shade
                    width: root.menu || root.listing || root.asking ? win.width : 0
                    height: width > 0 ? win.height : 0
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: root.calm() }
                }

                Repeater {
                    model: win.aim === "" ? [] : ["top", "bottom", "right", "left"]
                    Rectangle {
                        required property string modelData
                        readonly property bool flat: modelData === "top" || modelData === "bottom"
                        x: modelData === "right" ? win.width - width : 0
                        y: modelData === "bottom" ? win.height - height : 0
                        width: flat ? win.width : win.thick
                        height: flat ? win.thick : win.height
                        color: Qt.alpha(root.hi, win.aim === modelData ? 0.5 : 0.12)
                        Behavior on color { Tint {} }
                    }
                }

                Item {
                    id: strip
                    x: (win.bar.pos === "right" ? win.width - win.bar.size : 0) + win.bar.body.x
                    y: (win.bar.pos === "bottom" ? win.height - win.bar.size : 0) + win.bar.body.y
                    width: win.bar.body.width
                    height: win.bar.body.height

                    Rectangle { visible: root.guide; z: 4; x: win.vert ? 0 : Math.round(parent.width / 2); y: win.vert ? Math.round(parent.height / 2) : 0; width: win.vert ? parent.width : 1; height: win.vert ? 1 : parent.height; color: root.tx }
                    Rectangle { anchors.fill: parent; color: "transparent"; border.width: root.picked === "catbar_" ? 2 : 1; border.color: Qt.alpha(root.hi, 0.7) }
                    MouseArea {
                        property real sx: 0
                        property real sy: 0
                        property bool moved: false
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeAllCursor
                        onContainsMouseChanged: {
                            if (containsMouse) root.hot = "catbar"
                            else if (root.hot === "catbar") root.hot = ""
                        }
                        onPressed: m => { sx = m.x; sy = m.y; moved = false; root.calm() }
                        onPositionChanged: m => {
                            if (!pressed || (!moved && Math.abs(m.x - sx) + Math.abs(m.y - sy) < 12)) return
                            const p = mapToItem(face, m.x, m.y)
                            moved = true
                            win.aim = root.edge(p.x, p.y, win.width, win.height)
                        }
                        onReleased: {
                            const a = win.aim
                            win.aim = ""
                            if (moved && a !== "" && a !== win.bar.pos) root.commit({ catbar_Position: ["top", "bottom", "right", "left"].indexOf(a) })
                        }
                        onClicked: if (!moved) root.picked = "catbar_"
                        onDoubleClicked: root.inspect("catbar_")
                        onWheel: e => root.put("catbar_Height", root.near(root.fit(Number(root.cfg?.catbar_Height ?? 0.035) + (e.angleDelta.y > 0 ? 0.001 : -0.001), 0.02, 0.08), 0.001))
                    }

                    Repeater {
                        model: Object.keys(win.bar.widgets).filter(k => {
                            const w = win.bar.widgets[k]
                            return !!w && !w.ghost && typeof w.s(w.spot) === "number"
                        }).sort()

                        Rectangle {
                            id: grip
                            required property string modelData
                            readonly property var w: win.bar.widgets[modelData] ?? null
                            readonly property string name: "widget_" + root.cap(modelData)
                            readonly property real own: !w ? 0 : win.vert ? w.height : w.width
                            readonly property real at: !w ? 0 : win.vert ? w.y : w.x
                            readonly property real len: Math.max(14, own)
                            readonly property real off: (len - own) / 2
                            readonly property real spot: (drag >= 0 ? drag : at) - off
                            readonly property bool chosen: root.picked === name || (!!root.menu && root.menu.key === modelData)
                            property real drag: -1
                            visible: !!w
                            z: gripArea.pressed ? 3 : gripArea.containsMouse || chosen ? 2 : 1
                            x: win.vert ? 0 : spot
                            y: win.vert ? spot : 0
                            width: win.vert ? strip.width : len
                            height: win.vert ? len : strip.height
                            radius: Math.min(width, height, root.rad) / 2
                            color: Qt.alpha(root.hi, gripArea.pressed || chosen ? 0.42 : gripArea.containsMouse ? 0.3 : root.s("editor_HandleOpacity"))
                            border.width: chosen ? 2 : gripArea.containsMouse ? 1 : 0
                            border.color: root.hi
                            Behavior on color { Tint {} }

                            MouseArea {
                                id: gripArea
                                property real hold: 0
                                property bool moved: false
                                property bool other: false
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: pressed && !other ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                onContainsMouseChanged: {
                                    if (containsMouse) root.hot = grip.modelData
                                    else if (root.hot === grip.modelData) root.hot = ""
                                }
                                onPressed: m => {
                                    other = m.button === Qt.RightButton
                                    hold = win.vert ? m.y : m.x
                                    moved = false
                                    if (!other) root.calm()
                                }
                                onPositionChanged: m => {
                                    if (!pressed || other || !grip.w) return
                                    const p = mapToItem(strip, m.x, m.y), room = (win.vert ? strip.height : strip.width) - grip.own
                                    const raw = root.fit((win.vert ? p.y : p.x) - hold + grip.off, 0, Math.max(0, room)), centred = Math.abs(raw - room / 2) < 6
                                    const pos = centred ? room / 2 : raw
                                    if (!moved && Math.abs(pos - grip.at) < 4) return
                                    if (!moved && win.vert && win.bar.setting("SideAuto") !== false) root.put("catbar_SideAuto", false)
                                    moved = true
                                    root.guide = centred
                                    grip.drag = pos
                                    root.put(root.spotKey(grip.w), root.near(pos / win.thick, root.snap))
                                }
                                onReleased: {
                                    if (moved) root.flush()
                                    grip.drag = -1
                                    root.guide = false
                                }
                                onClicked: m => {
                                    if (moved) return
                                    root.picked = grip.name
                                    if (m.button !== Qt.RightButton) return
                                    const p = mapToItem(face, m.x, m.y)
                                    root.listing = false
                                    root.asking = false
                                    root.menu = { key: grip.modelData, x: p.x, y: p.y }
                                }
                                onDoubleClicked: m => { if (m.button === Qt.LeftButton) root.inspect(grip.name) }
                                onWheel: e => {
                                    if (!grip.w) return
                                    const n = root.sizeName(grip.w)
                                    root.put(grip.w.prefix + n, root.near(root.fit(Number(grip.w.s(n) ?? 1) + (e.angleDelta.y > 0 ? 0.05 : -0.05), 0.3, 3), 0.05))
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: deskGrip
                    readonly property rect r: Reveal.desk
                    readonly property string name: "desktop_"
                    readonly property bool shown: root.cfg?.desktop_Show === true && r.width > 0 && r.height > 0
                    property real dx: -1
                    property real dy: -1
                    visible: shown
                    x: (dx >= 0 ? dx : r.x) - 12
                    y: (dy >= 0 ? dy : r.y) - 12
                    width: shown ? r.width + 24 : 0
                    height: shown ? r.height + 24 : 0
                    radius: root.rad
                    color: Qt.alpha(root.hi, deskArea.pressed || root.picked === name ? 0.3 : deskArea.containsMouse ? 0.2 : root.s("editor_HandleOpacity") / 2)
                    border.width: root.picked === name ? 2 : 1
                    border.color: root.hi
                    Behavior on color { Tint {} }

                    MouseArea {
                        id: deskArea
                        property real hx: 0
                        property real hy: 0
                        property bool moved: false
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse) root.hot = "desktop"
                            else if (root.hot === "desktop") root.hot = ""
                        }
                        onPressed: m => { hx = m.x; hy = m.y; moved = false; root.calm() }
                        onPositionChanged: m => {
                            if (!pressed) return
                            const p = mapToItem(face, m.x, m.y), r = deskGrip.r
                            const x = root.fit(p.x - hx + 12, 0, Math.max(0, win.width - r.width)), y = root.fit(p.y - hy + 12, 0, Math.max(0, win.height - r.height))
                            if (!moved && Math.abs(x - r.x) + Math.abs(y - r.y) < 6) return
                            moved = true
                            deskGrip.dx = x
                            deskGrip.dy = y
                            root.put("desktop_X", root.near((x + r.width / 2) / win.width, 0.001))
                            root.put("desktop_Y", root.near((y + r.height / 2) / win.height, 0.001))
                        }
                        onReleased: {
                            if (moved) root.flush()
                            deskGrip.dx = -1
                            deskGrip.dy = -1
                        }
                        onClicked: if (!moved) root.picked = deskGrip.name
                        onDoubleClicked: root.inspect(deskGrip.name)
                        onWheel: e => root.put("desktop_Scale", root.near(root.fit(Number(root.cfg?.desktop_Scale ?? 1) + (e.angleDelta.y > 0 ? 0.05 : -0.05), 0.3, 3), 0.05))
                    }
                }

                Rectangle {
                    id: frame
                    readonly property rect r: root.panel.area
                    readonly property bool shown: root.panel.open && r.width > 0 && r.height > 0
                    readonly property bool flipX: win.bar.pos === "right"
                    readonly property bool flipY: win.bar.pos === "bottom"
                    readonly property real dot: shown ? Math.round(root.px * 2.2) : 0
                    visible: shown
                    x: r.x - 4
                    y: r.y - 4
                    width: r.width + 8
                    height: r.height + 8
                    radius: root.rad
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.alpha(root.hi, 0.8)
                }
                Rectangle {
                    id: knob
                    visible: frame.shown
                    x: (frame.flipX ? frame.x : frame.x + frame.width) - width / 2
                    y: (frame.flipY ? frame.y : frame.y + frame.height) - height / 2
                    width: frame.dot
                    height: frame.dot
                    radius: width / 2
                    color: root.hi
                    scale: knobArea.pressed ? 1.15 : 1
                    Behavior on scale { Glide {} }
                    Text { anchors.centerIn: parent; text: root.glyph("f065"); font.family: root.iconFont; font.pixelSize: root.px; color: root.bg }
                    MouseArea {
                        id: knobArea
                        property real sx: 0
                        property real sy: 0
                        property real w0: 0
                        property real h0: 0
                        anchors.fill: parent
                        cursorShape: frame.flipX !== frame.flipY ? Qt.SizeBDiagCursor : Qt.SizeFDiagCursor
                        onPressed: m => {
                            const p = mapToItem(face, m.x, m.y)
                            sx = p.x
                            sy = p.y
                            w0 = Number(root.panel.v("Width")) || 13
                            h0 = Number(root.panel.v("Height")) || 27
                            root.calm()
                        }
                        onPositionChanged: m => {
                            if (!pressed) return
                            const p = mapToItem(face, m.x, m.y), u = Math.max(1, root.panel.unit), id = root.panel.activeId
                            const dx = (p.x - sx) * (frame.flipX ? -1 : 1) / u, dy = (p.y - sy) * (frame.flipY ? -1 : 1) / u
                            root.put("@" + id + "|Width", root.size(w0 + dx * (win.vert ? 1 : 2)))
                            root.put("@" + id + "|Height", root.size(h0 + dy * (win.vert ? 2 : 1)))
                        }
                        onReleased: root.flush()
                    }
                }
                Rectangle {
                    id: shut
                    visible: frame.shown
                    x: (frame.flipX ? frame.x + frame.width : frame.x) - width / 2
                    y: knob.y
                    width: frame.dot
                    height: frame.dot
                    radius: width / 2
                    color: shutArea.containsMouse ? root.bad : root.bg
                    border.width: 1
                    border.color: Qt.alpha(root.tx, 0.3)
                    Behavior on color { Tint {} }
                    Text { anchors.centerIn: parent; text: root.glyph("f00d"); font.family: root.iconFont; font.pixelSize: root.px; color: root.tx }
                    MouseArea { id: shutArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.panel.open = false }
                }

                Rectangle {
                    id: dock
                    readonly property real edge: Math.max(0, root.s("editor_Margin"))
                    readonly property real homeX: win.width - width - edge - (win.bar.pos === "right" ? win.bar.size : 0)
                    readonly property real homeY: edge + (win.bar.pos === "top" ? win.bar.size : 0)
                    readonly property string tips: root.word("Drag to move  ·  scroll to resize  ·  right-click for more  ·  double-click for settings")
                    x: root.fit(root.dockX >= 0 ? root.dockX : homeX, 0, Math.max(0, win.width - width))
                    y: root.fit(root.dockY >= 0 ? root.dockY : homeY, 0, Math.max(0, win.height - height))
                    width: dockRow.width + Math.round(root.px * 2)
                    height: Math.round(root.px * 3.4)
                    radius: height / 2
                    color: root.bg
                    border.width: 1
                    border.color: Qt.alpha(root.tx, 0.14)
                    NumberAnimation on opacity { from: 0; to: 1; duration: Motion.time * 2 }
                    NumberAnimation on scale { from: 0.94; to: 1; duration: Motion.time * 2; easing.type: Motion.ease }

                    MouseArea {
                        property real hx: 0
                        property real hy: 0
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        onPressed: m => { face.forceActiveFocus(); hx = m.x; hy = m.y }
                        onPositionChanged: m => {
                            if (!pressed) return
                            const p = mapToItem(face, m.x, m.y)
                            root.dockX = root.fit(p.x - hx, 0, Math.max(0, win.width - dock.width))
                            root.dockY = root.fit(p.y - hy, 0, Math.max(0, win.height - dock.height))
                        }
                    }

                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: Math.round(root.px * 0.7)
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.glyph("f047"); font.family: root.iconFont; font.pixelSize: root.px; color: root.tx; opacity: 0.5 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.word("Editor"); font.family: root.font; font.pixelSize: root.px + 2; font.weight: Font.DemiBold; color: root.tx }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: text !== ""
                            width: Math.min(implicitWidth, Math.round(root.px * Math.max(12, root.s("editor_Width")) * 2.4))
                            elide: Text.ElideRight
                            text: frame.shown ? root.word("Panel") + " " + root.panel.activeId + "  ·  " + root.panel.v("Width") + " × " + root.panel.v("Height") + "  ·  " + root.word("drag the corner to resize")
                                : root.hot !== "" ? root.name(root.hot) + "  ·  " + dock.tips : ""
                            font.family: root.font
                            font.pixelSize: root.px - 1
                            color: root.tx
                            opacity: 0.6
                        }
                        Tool { code: "f112"; opacity: root.past.length ? 1 : 0.35; onTapped: root.undo() }
                        Tool { code: "f064"; opacity: root.ahead.length ? 1 : 0.35; onTapped: root.redo() }
                        Tool { label: "Modules"; code: "f009"; lit: root.listing; onTapped: { const on = !root.listing; root.calm(); root.listing = on } }
                        Tool { label: "Reset"; code: "f0e2"; danger: true; onTapped: { const on = !root.asking; root.calm(); root.asking = on } }
                        Tool { label: "Done"; code: "f00c"; lit: true; onTapped: Reveal.editor = false }
                    }
                }

                Card {
                    id: list
                    readonly property real colW: Math.round(root.px * Math.max(12, root.s("editor_Width")))
                    shown: root.listing
                    z: 10
                    width: shown ? listRow.width + Math.round(root.px * 2) : 0
                    height: shown ? listRow.height + Math.round(root.px * 2) : 0
                    x: root.fit(dock.x + dock.width - width, 8, Math.max(8, win.width - width - 8))
                    y: dock.y + dock.height + 8 + height > win.height ? Math.max(8, dock.y - height - 8) : dock.y + dock.height + 8

                    Row {
                        id: listRow
                        x: Math.round(root.px)
                        y: Math.round(root.px)
                        spacing: Math.round(root.px)
                        Column {
                            width: list.colW
                            spacing: 4
                            Head { text: root.word("Hidden") }
                            Repeater {
                                model: root.s("editor_Hidden")
                                Chip {
                                    required property var modelData
                                    label: String(modelData[0])
                                    code: String(modelData[2] ?? "")
                                    lit: root.picked === modelData[1] + "_"
                                    onTapped: root.pick(modelData[1] + "_")
                                }
                            }
                        }
                        Column {
                            width: list.colW
                            spacing: 4
                            Head { text: root.word("Binded") }
                            Repeater {
                                model: root.s("editor_Binded")
                                Chip {
                                    required property var modelData
                                    label: String(modelData[0])
                                    code: String(modelData[2] ?? "")
                                    lit: root.picked === modelData[1] + "_"
                                    onTapped: root.pick(modelData[1] + "_")
                                }
                            }
                        }
                        Column {
                            width: list.colW
                            spacing: 4
                            Head { text: root.word("Widgets") }
                            Repeater {
                                model: root.layers
                                Item {
                                    id: layer
                                    required property string modelData
                                    readonly property bool seen: root.shown(modelData)
                                    width: list.colW
                                    height: Math.round(root.px * 2.5)
                                    Chip {
                                        label: layer.modelData
                                        code: layer.seen ? "f06e" : "f070"
                                        lit: root.picked === "widget_" + layer.modelData
                                        opacity: layer.seen ? 1 : 0.55
                                        onTapped: root.pick("widget_" + layer.modelData)
                                    }
                                    MouseArea { width: Math.round(root.px * 3); height: parent.height; onClicked: root.show(layer.modelData, !layer.seen) }
                                }
                            }
                        }
                    }
                }

                Card {
                    id: probe
                    readonly property real edge: Math.max(0, root.s("editor_Margin"))
                    shown: root.picked !== "" && root.rows.length > 0 && !root.listing
                    z: 9
                    width: shown ? Math.round(root.px * Math.max(16, root.s("editor_InspectorWidth"))) : 0
                    height: shown ? Math.min(win.height * 0.7, probeCol.height + Math.round(root.px * 4.6)) : 0
                    x: edge + (win.bar.pos === "left" ? win.bar.size : 0)
                    y: Math.round((win.height - height) / 2)

                    Item {
                        x: Math.round(root.px)
                        y: Math.round(root.px * 0.7)
                        width: parent.width - x * 2
                        height: Math.round(root.px * 2.2)
                        Text { width: parent.width - Math.round(root.px * 2); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: root.picked.replace(/_$/, "").replace(/^widget_/, ""); font.family: root.font; font.pixelSize: root.px + 2; font.weight: Font.DemiBold; color: root.tx }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.glyph("f00d")
                            font.family: root.iconFont
                            font.pixelSize: root.px
                            color: root.tx
                            opacity: probeShut.containsMouse ? 1 : 0.5
                            MouseArea { id: probeShut; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.picked = "" }
                        }
                    }
                    Flickable {
                        x: Math.round(root.px * 0.6)
                        y: Math.round(root.px * 3.2)
                        width: parent.width - x * 2
                        height: parent.height - y - Math.round(root.px * 0.8)
                        contentHeight: probeCol.height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        Column {
                            id: probeCol
                            width: parent.width
                            Repeater {
                                model: root.rows
                                Rectangle {
                                    id: prop
                                    required property var modelData
                                    readonly property var value: root.cfg?.[modelData.key]
                                    readonly property string kind: String(modelData.kind)
                                    width: probeCol.width
                                    height: Math.round(root.px * 2.5)
                                    radius: height / 2
                                    color: propArea.containsMouse ? Qt.alpha(root.tx, 0.08) : "transparent"
                                    MouseArea {
                                        id: propArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (prop.kind === "bool") { const out = {}; out[prop.modelData.key] = prop.value !== true; root.commit(out) }
                                            else if (prop.kind === "link") Reveal.inspect(prop.modelData.key)
                                        }
                                    }
                                    Text { x: Math.round(root.px * 0.8); width: parent.width * 0.52; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: String(prop.modelData.label); font.family: root.font; font.pixelSize: root.px; color: root.tx }
                                    Rectangle {
                                        visible: prop.kind === "bool"
                                        anchors.right: parent.right
                                        anchors.rightMargin: Math.round(root.px * 0.8)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.round(root.px * 2.7)
                                        height: Math.round(root.px * 1.4)
                                        radius: height / 2
                                        color: prop.value === true ? root.hi : Qt.alpha(root.tx, 0.18)
                                        Behavior on color { Tint {} }
                                        Rectangle { y: 2; x: prop.value === true ? parent.width - width - 2 : 2; width: parent.height - 4; height: width; radius: width / 2; color: root.bg; Behavior on x { Glide {} } }
                                    }
                                    Row {
                                        visible: prop.kind === "num"
                                        anchors.right: parent.right
                                        anchors.rightMargin: Math.round(root.px * 0.5)
                                        height: parent.height
                                        spacing: 2
                                        Text {
                                            width: Math.round(root.px * 1.8); height: parent.height; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                            text: "\u2212"; font.family: root.font; font.pixelSize: root.px + 3; color: root.tx; opacity: lessArea.containsMouse ? 1 : 0.5
                                            MouseArea { id: lessArea; anchors.fill: parent; hoverEnabled: true; onClicked: m => root.bump(prop.modelData.key, -1, !!(m.modifiers & Qt.ShiftModifier)) }
                                        }
                                        Text { width: Math.round(root.px * 4.2); height: parent.height; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: typeof prop.value === "number" ? String(Number(prop.value.toFixed(3))) : ""; font.family: root.font; font.pixelSize: root.px; color: root.hi; WheelHandler { onWheel: e => root.bump(prop.modelData.key, e.angleDelta.y > 0 ? 1 : -1, !!(e.modifiers & Qt.ShiftModifier)) } }
                                        Text {
                                            width: Math.round(root.px * 1.8); height: parent.height; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                            text: "+"; font.family: root.font; font.pixelSize: root.px + 3; color: root.tx; opacity: moreArea.containsMouse ? 1 : 0.5
                                            MouseArea { id: moreArea; anchors.fill: parent; hoverEnabled: true; onClicked: m => root.bump(prop.modelData.key, 1, !!(m.modifiers & Qt.ShiftModifier)) }
                                        }
                                    }
                                    Text { visible: prop.kind === "link"; anchors.right: parent.right; anchors.rightMargin: Math.round(root.px * 0.8); width: parent.width * 0.4; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; text: Array.isArray(prop.value) ? prop.value.join(", ") : String(prop.value ?? ""); font.family: root.font; font.pixelSize: root.px - 1; color: root.tx; opacity: 0.55 }
                                }
                            }
                        }
                    }
                }

                Card {
                    id: sure
                    shown: root.asking
                    z: 10
                    width: shown ? Math.round(root.px * 26) : 0
                    height: shown ? sureCol.height + Math.round(root.px * 2) : 0
                    x: root.fit(dock.x + dock.width - width, 8, Math.max(8, win.width - width - 8))
                    y: dock.y + dock.height + 8 + height > win.height ? Math.max(8, dock.y - height - 8) : dock.y + dock.height + 8

                    Column {
                        id: sureCol
                        x: Math.round(root.px)
                        y: Math.round(root.px)
                        width: parent.width - x * 2
                        spacing: Math.round(root.px * 0.6)
                        Text { text: root.word("Reset the layout?"); font.family: root.font; font.pixelSize: root.px + 2; font.weight: Font.DemiBold; color: root.tx }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: root.word("Widget positions, sizes and groups, panel sizes, the catbar edge and the desktop widgets go back to their defaults.")
                            font.family: root.font
                            font.pixelSize: root.px
                            color: root.tx
                            opacity: 0.6
                        }
                        Item {
                            width: parent.width
                            height: Math.round(root.px * 2.6)
                            Row {
                                anchors.right: parent.right
                                height: parent.height
                                spacing: 8
                                Tool { label: "Reset"; code: "f0e2"; danger: true; onTapped: { root.restore(); root.calm() } }
                                Tool { label: "Cancel"; onTapped: root.calm() }
                            }
                        }
                    }
                }

                Card {
                    id: card
                    readonly property string key: root.menu ? String(root.menu.key) : ""
                    readonly property var w: key !== "" ? win.bar.widgets[key] ?? null : null
                    readonly property var g: w ? root.groupFor(key) : null
                    readonly property var mates: g ? g.members.filter(m => m !== key) : []
                    readonly property bool showing: !!g && root.panel.open && root.panel.activeId === g.id
                    readonly property real px0: root.menu ? root.menu.x : 0
                    readonly property real py0: root.menu ? root.menu.y : 0
                    shown: !!w
                    z: 20
                    width: shown ? Math.round(root.px * 20) : 0
                    height: shown ? cardCol.height + Math.round(root.px * 1.6) : 0
                    x: root.fit(px0 + 10, 8, Math.max(8, win.width - width - 8))
                    y: py0 + 10 + height > win.height - 8 ? Math.max(8, py0 - height - 10) : py0 + 10

                    Column {
                        id: cardCol
                        x: Math.round(root.px * 0.8)
                        y: Math.round(root.px * 0.8)
                        width: parent.width - x * 2
                        spacing: 4

                        Item {
                            width: parent.width
                            height: Math.round(root.px * 2.2)
                            Text { x: Math.round(root.px * 0.6); width: parent.width - x - Math.round(root.px * 2.4); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: root.name(card.key) + (card.mates.length ? "  ·  " + (card.g ? card.g.id : "") : ""); font.family: root.font; font.pixelSize: root.px + 1; font.weight: Font.DemiBold; color: root.tx }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Math.round(root.px * 0.5)
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.glyph("f00d")
                                font.family: root.iconFont
                                font.pixelSize: root.px
                                color: root.tx
                                opacity: cardShut.containsMouse ? 1 : 0.5
                                MouseArea { id: cardShut; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.menu = null }
                            }
                        }
                        Chip { visible: !!card.g && card.g.paged; label: card.showing ? "Hide panel" : "Show panel"; code: "f2d0"; lit: card.showing; onTapped: { if (card.showing) root.panel.open = false; else root.showPanel(card.key) } }
                        Chip { label: "Open its settings"; code: "f013"; onTapped: { const k = "widget_" + root.cap(card.key); root.menu = null; root.inspect(k) } }
                        Chip { label: "Reset this widget"; code: "f0e2"; onTapped: root.revert(card.key) }
                        Chip { visible: card.mates.length > 0; label: "Remove from group"; code: "f127"; onTapped: root.leave(card.key) }
                        Head { text: root.word("Group with") }
                        Flow {
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: card.shown ? root.others(card.key) : []
                                Tag {
                                    required property string modelData
                                    label: root.name(modelData)
                                    lit: card.mates.includes(modelData)
                                    onTapped: lit ? root.leave(modelData) : root.join(card.key, modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
