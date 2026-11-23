import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../../Backend"

Widget {
    id: kb
    key: "keyboard"
    icon: sign(s("Art")) || "keyboard"
    hot: true
    held: open || linked
    tip: t("Keyboard")
    len: along(mark)
    onTapped: open = !open
    onOpenChanged: { if (open) probe.running = true; else typing = false }
    onNavChanged: if (nav) { pick = Math.max(0, codes.indexOf(code)); plate.forceActiveFocus() }
    onSavedChanged: if (saved === draft) draft = ""

    property bool open: false
    property real shown: open ? 1 : 0
    property bool ready: true
    property bool shift: false
    property var queue: []
    property real sent: 0
    property string buffer: ""
    property int sheet: 0
    property var book: ({})
    property bool over: false
    property bool typing: false
    property int pick: 0
    readonly property bool nav: open && over && !typing
    property string draft: ""
    property color cPlate: pc("Color")
    property color cEdge: pc("BorderColor")
    property color cKey: pc("TabColor")
    property color cHot: pc("ActiveColor")
    property color cText: pc("TextColor")
    readonly property bool linked: s("Linked") === true
    readonly property var codes: Object.keys(layouts)
    readonly property string saved: layouts[s("Language")] ? s("Language") : "en"

    readonly property var layouts: ({
        en: ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"],
        ru: ["1234567890", "йцукенгшщзхъ", "фывапролджэ", "ячсмитьбюё"],
        sr: ["1234567890", "љњертзуиопшђ", "асдфгхјклчћж", "ѕџцвбнм"],
        vi: ["1234567890", "qwertyuiop", "asdfghjkl", "ăâêôơưđ̣́̀̉̃", "zxcvbnm"],
        zh: ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"],
        ja: ["あいうえおかきくけこ", "さしすせそたちつてと", "なにぬねのはひふへほ", "まみむめもやゆよわを", "らりるれろんー゙゚"],
        ko: ["1234567890", "ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ", "ㅁㄴㅇㄹㅎㅗㅓㅏㅣ", "ㅋㅌㅊㅍㅠㅜㅡ"],
        fi: ["1234567890", "qwertyuiopå", "asdfghjklöä", "zxcvbnm"]
    })
    readonly property var pairs: ({
        "1": "!", "2": "@", "3": "#", "4": "$", "5": "%", "6": "^", "7": "&", "8": "*", "9": "(", "0": ")",
        ",": ";", ".": ":", "?": "/",
        "ㅂ": "ㅃ", "ㅈ": "ㅉ", "ㄷ": "ㄸ", "ㄱ": "ㄲ", "ㅅ": "ㅆ", "ㅐ": "ㅒ", "ㅔ": "ㅖ"
    })
    readonly property var marks: ({ ",": "，", ".": "。", "?": "？", ";": "；", ":": "：", "/": "、", "!": "！", "(": "（", ")": "）" })
    readonly property var faces: ({ shift: "shift", back: "backspace", enter: "enter" })
    readonly property string code: draft !== "" ? draft : saved
    readonly property var grid: {
        const rows = layouts[code].map(r => Array.from(r).map(ch => ({ ch: ch })))
        const last = rows.length - 1
        rows[last] = [{ act: "shift", w: 1.5 }].concat(rows[last]).concat([{ act: "back", w: 1.5 }])
        rows.push([{ ch: "," }, { act: "space", w: 5 }, { ch: "." }, { ch: "?" }, { act: "enter", w: 2 }])
        return rows
    }
    readonly property real cols: Math.max(...grid.map(r => r.reduce((a, k) => a + (k.w ?? 1), 0)))

    readonly property bool ime: code === "zh"
    readonly property int perSheet: 9
    readonly property string idle: "的一是不了人我在有他这中大来上国个到说们"
    readonly property var hit: {
        if (!ime) return { used: 0, chars: [] }
        if (!buffer) return { used: 0, chars: Array.from(idle) }
        for (let n = Math.min(6, buffer.length); n > 0; n--) {
            const got = book[buffer.slice(0, n)]
            if (got) return { used: n, chars: Array.from(got) }
        }
        return { used: buffer.length, chars: [] }
    }
    readonly property int sheets: Math.ceil(hit.chars.length / perSheet)
    readonly property var picks: hit.chars.slice(sheet * perSheet, (sheet + 1) * perSheet)

    onImeChanged: { buffer = ""; sheet = 0; if (!ime) book = ({}) }

    Behavior on cPlate { Tint {} }
    Behavior on cEdge { Tint {} }
    Behavior on cKey { Tint {} }
    Behavior on cHot { Tint {} }
    Behavior on cText { Tint {} }
    Behavior on shown { NumberAnimation { duration: Motion.span(kb.s("SlideTime") ?? 250); easing.type: Easing[kb.s("SlideEasing")] ?? Easing.OutCubic } }

    function choose(lang) {
        draft = lang
        commit.restart()
    }
    function hop(n) { choose(codes[(codes.indexOf(code) + n + codes.length) % codes.length]) }
    function read() {
        if (!ime) return
        try { book = JSON.parse(file.text()) } catch (e) { book = ({}) }
    }
    function upper(ch) {
        if (pairs[ch]) return pairs[ch]
        const n = ch.codePointAt(0)
        if (n >= 0x3041 && n <= 0x3096) return String.fromCodePoint(n + 0x60)
        return ch.toUpperCase()
    }
    function face(k) {
        if (k.act) return ""
        const ch = shift ? upper(k.ch) : k.ch, n = ch.codePointAt(0)
        if (ime && marks[ch]) return marks[ch]
        if (n === 0x3099) return "゛"
        if (n === 0x309a) return "゜"
        return n >= 0x300 && n <= 0x36f ? "◌" + ch : ch
    }
    function pick(i) {
        const ch = picks[i]
        if (!ch) return
        const used = hit.used
        send([ch])
        buffer = buffer.slice(used)
        sheet = 0
    }
    function flush() {
        sheet = 0
        for (let i = 0; i < 12 && buffer; i++) {
            if (!hit.chars.length) { send([buffer]); buffer = ""; break }
            pick(0)
        }
    }
    function turn(n) { sheet = Math.max(0, Math.min(sheets - 1, sheet + n)) }
    function rest(ms) {
        const had = nav
        typing = true
        idle.interval = ms
        idle.restart()
        if (had) wait.restart()
    }
    function step(d) {
        const n = codes.length + 2
        pick = (pick + d + n) % n
    }
    function poke() {
        const n = codes.length
        if (pick < n) choose(codes[pick])
        else if (pick === n) bar.save("widget_KeyboardLinked", !linked)
        else open = false
    }
    function pass(e) {
        const named = ({ [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Tab]: "Tab", [Qt.Key_Delete]: "Delete" })[e.key]
        rest(3000)
        if (named) send(["-k", named])
        else if (e.text !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) send([e.text])
    }
    function press(k) {
        rest(700)
        if (k.act === "shift") { shift = !shift; return }
        if (ime && buffer) {
            if (k.act === "back") { buffer = buffer.slice(0, -1); sheet = 0; return }
            if (k.act === "enter") { send([buffer]); buffer = ""; sheet = 0; return }
            if (k.act === "space") return hit.chars.length ? pick(0) : flush()
        }
        if (k.act === "back") return send(["-k", "BackSpace"])
        if (k.act === "enter") return send(["-k", "Return"])
        if (k.act === "space") return send(["-k", "space"])
        const high = shift, ch = high ? upper(k.ch) : k.ch
        shift = false
        if (ime) {
            if (!high && /^[a-z]$/.test(ch)) { buffer += ch; sheet = 0; return }
            if (buffer && /^[1-9]$/.test(ch)) return pick(parseInt(ch) - 1)
            flush()
            if (marks[ch]) return send([marks[ch]])
        }
        send(ch === "-" ? ["-k", "minus"] : [ch])
    }
    function send(args) {
        queue = queue.concat(args)
        pump()
    }
    function pump() {
        if (wait.running || out.running || !queue.length) return
        out.command = ["wtype"].concat(queue)
        queue = []
        sent = stamp()
        out.running = true
    }

    GlobalShortcut { appid: "keyboard"; name: "hide"; onPressed: if (!out.running && kb.stamp() - kb.sent > 300) kb.open = false }
    Process { id: out; onExited: { kb.sent = kb.stamp(); kb.pump() } }
    Timer { id: idle; interval: 700; onTriggered: kb.typing = false }
    Timer { id: wait; interval: 60; onTriggered: kb.pump() }
    Timer { id: commit; interval: 300; onTriggered: if (kb.draft !== "" && kb.draft !== kb.saved) kb.bar.save("widget_KeyboardLanguage", kb.draft); else kb.draft = "" }
    Process { id: probe; command: ["sh", "-c", "command -v wtype"]; onExited: code => kb.ready = code === 0 }
    FileView { id: file; path: kb.ime ? Qt.resolvedUrl("../../../../Data/Static/pinyin.json") : ""; onLoaded: kb.read() }

    Icon {
        id: mark
        anchors.centerIn: parent
        source: kb.icon
        family: kb.iconFont
        size: kb.unit * 0.5
        color: kb.ink
    }

    PanelWindow {
        id: board
        readonly property real gap: Math.round(kb.base * 0.18)
        readonly property real pad: Math.round(kb.base * 0.4)
        readonly property real topH: Math.round(kb.base * 1.1)
        readonly property real imeH: kb.ime ? topH : 0
        readonly property real goal: Math.round(kb.base * (kb.s("BottomMargin") ?? 0) + (kb.bar.posT === "bottom" ? kb.bar.tGap + kb.bar.tThick : 0))
        readonly property real full: Math.round((kb.bar.screen ? kb.bar.screen.height : 0) * (kb.s("Height") ?? 0.32))
        property real lift: goal
        property real tall: full
        Behavior on lift { Glide {} }
        Behavior on tall { Glide {} }

        screen: kb.bar.screen
        visible: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: kb.nav ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "dolphin-keyboard"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: Math.ceil(Math.max(tall, full) + kb.base * Math.max(0, kb.s("BottomMargin") ?? 0) + kb.bar.tGap + kb.bar.tThick)
        mask: Region { item: kb.shown > 0 ? plate : null }

        Rectangle {
            id: plate
            readonly property real keyW: (width - board.pad * 2 - board.gap * (kb.cols - 1)) / kb.cols
            readonly property real keyH: (height - board.pad * 2 - board.topH - board.imeH - board.gap * kb.grid.length) / kb.grid.length

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: board.pad + board.lift - (1 - kb.shown) * (height + board.pad + board.lift)
            width: Math.min(parent.width - board.pad * 2, height * 3.2)
            height: board.tall - board.pad
            radius: kb.base * 0.5
            opacity: 0.4 + 0.6 * kb.shown
            color: kb.cPlate
            border.width: 2
            border.color: kb.cEdge
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) kb.step(-1)
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) kb.step(1)
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) kb.poke()
                else if (e.key === Qt.Key_Escape) kb.open = false
                else kb.pass(e)
                e.accepted = true
            }

            HoverHandler { onHoveredChanged: kb.over = hovered }

            Rectangle {
                readonly property int n: kb.codes.length
                readonly property Item aim: kb.pick < n ? chipRep.itemAt(kb.pick) : kb.pick === n ? linkBtn : shutBtn
                readonly property real ax: !aim ? 0 : kb.pick < n ? chips.x + aim.x : aim.x
                readonly property real ay: !aim ? 0 : kb.pick < n ? chips.y + aim.y : aim.y
                readonly property real rim: Math.max(2, Math.round(board.gap / 2))
                visible: kb.nav && !!aim
                x: ax - rim
                y: ay - rim
                width: (aim ? aim.width : 0) + rim * 2
                height: (aim ? aim.height : 0) + rim * 2
                radius: height / 2
                color: "transparent"
                border.width: 2
                border.color: kb.cHot
            }

            Row {
                id: chips
                x: board.pad
                y: board.pad
                height: board.topH - board.gap
                spacing: board.gap

                Repeater {
                    id: chipRep
                    model: kb.codes
                    Rectangle {
                        id: chip
                        required property string modelData
                        required property int index
                        readonly property bool current: kb.code === modelData
                        width: height * 1.5
                        height: parent.height
                        radius: height / 2
                        color: current ? kb.cHot : kb.cKey
                        Text {
                            anchors.centerIn: parent
                            text: chip.modelData.toUpperCase()
                            color: chip.current ? kb.cPlate : kb.cText
                            font.family: kb.textFont; font.pixelSize: parent.height * 0.42
                        }
                        MouseArea { anchors.fill: parent; onPressed: { kb.pick = chip.index; kb.choose(chip.modelData) } }
                    }
                }
            }

            Rectangle {
                id: linkBtn
                anchors.right: parent.right
                anchors.rightMargin: board.pad + board.topH
                y: board.pad
                width: height
                height: board.topH - board.gap
                radius: height / 2
                color: kb.linked ? kb.cHot : kb.cKey
                Behavior on color { ColorAnimation { duration: Motion.span(200) } }
                Icon {
                    anchors.centerIn: parent
                    source: "link"
                    rotation: -45
                    size: parent.height * 0.55
                    color: kb.linked ? kb.cPlate : kb.cText
                }
                MouseArea { anchors.fill: parent; onPressed: kb.bar.save("widget_KeyboardLinked", !kb.linked) }
            }

            Rectangle {
                id: shutBtn
                anchors.right: parent.right
                anchors.rightMargin: board.pad
                y: board.pad
                width: height
                height: board.topH - board.gap
                radius: height / 2
                color: shut.pressed ? kb.cHot : kb.cKey
                Icon {
                    anchors.centerIn: parent
                    source: "close"
                    size: parent.height * 0.5
                    color: shut.pressed ? kb.cPlate : kb.cText
                }
                MouseArea { id: shut; anchors.fill: parent; onPressed: kb.open = false }
            }

            Text {
                visible: !kb.ready
                anchors.right: parent.right
                anchors.rightMargin: board.pad + board.topH * 2
                y: board.pad
                height: board.topH - board.gap
                verticalAlignment: Text.AlignVCenter
                text: "sudo pacman -S wtype"
                color: kb.cHot
                font.family: kb.textFont; font.pixelSize: height * 0.42
            }

            Item {
                id: strip
                visible: kb.ime
                x: board.pad
                y: board.pad + board.topH
                width: parent.width - board.pad * 2
                height: board.topH - board.gap

                Text {
                    id: typed
                    width: kb.base * 3
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideLeft
                    text: kb.buffer || "拼音"
                    opacity: kb.buffer ? 1 : 0.5
                    color: kb.buffer ? kb.cHot : kb.cText
                    font.family: kb.textFont; font.pixelSize: height * 0.42
                }

                Row {
                    x: typed.width + board.gap
                    height: parent.height
                    spacing: board.gap

                    Repeater {
                        model: kb.picks
                        Rectangle {
                            id: pickBox
                            required property string modelData
                            required property int index
                            width: height * 1.35
                            height: parent.height
                            radius: height * 0.3
                            color: pickTap.pressed ? kb.cHot : kb.cKey
                            Text {
                                anchors.centerIn: parent
                                text: pickBox.modelData
                                color: pickTap.pressed ? kb.cPlate : kb.cText
                                font.family: kb.textFont; font.pixelSize: parent.height * 0.5
                            }
                            Text {
                                visible: kb.buffer !== ""
                                x: parent.height * 0.14
                                y: parent.height * 0.06
                                text: pickBox.index + 1
                                opacity: 0.5
                                color: pickTap.pressed ? kb.cPlate : kb.cText
                                font.family: kb.textFont; font.pixelSize: parent.height * 0.24
                            }
                            MouseArea { id: pickTap; anchors.fill: parent; onPressed: kb.pick(pickBox.index) }
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: board.gap

                    Repeater {
                        model: [-1, 1]
                        Rectangle {
                            id: flip
                            required property int modelData
                            readonly property bool can: modelData < 0 ? kb.sheet > 0 : kb.sheet < kb.sheets - 1
                            width: height
                            height: parent.height
                            radius: height / 2
                            opacity: can ? 1 : 0.35
                            color: flipTap.pressed && can ? kb.cHot : kb.cKey
                            Icon {
                                anchors.centerIn: parent
                                source: "prev"
                                rotation: flip.modelData < 0 ? 0 : 180
                                size: parent.height * 0.42
                                color: kb.cText
                            }
                            MouseArea { id: flipTap; anchors.fill: parent; onPressed: kb.turn(flip.modelData) }
                        }
                    }
                }
            }

            Column {
                x: board.pad
                y: board.pad + board.topH + board.imeH
                width: parent.width - board.pad * 2
                spacing: board.gap

                Repeater {
                    model: kb.grid
                    Row {
                        id: line
                        required property var modelData
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: board.gap

                        Repeater {
                            model: line.modelData
                            Rectangle {
                                id: cap
                                required property var modelData
                                readonly property real span: modelData.w ?? 1
                                readonly property bool lit: tap.pressed || (modelData.act === "shift" && kb.shift)
                                width: plate.keyW * span + board.gap * (span - 1)
                                height: plate.keyH
                                radius: Math.min(height * 0.22, kb.base * 0.4)
                                color: lit ? kb.cHot : kb.cKey
                                Text {
                                    anchors.centerIn: parent
                                    text: kb.face(cap.modelData)
                                    color: cap.lit ? kb.cPlate : kb.cText
                                    font.family: kb.textFont; font.pixelSize: Math.min(cap.height * 0.42, kb.base * 0.7)
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    source: kb.faces[cap.modelData.act] ?? ""
                                    size: Math.min(cap.height * 0.42, kb.base * 0.7)
                                    color: cap.lit ? kb.cPlate : kb.cText
                                }
                                MouseArea { id: tap; anchors.fill: parent; onPressed: kb.press(cap.modelData) }
                            }
                        }
                    }
                }
            }
        }
    }
}
