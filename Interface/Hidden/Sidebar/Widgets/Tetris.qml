import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../Backend"

FloatingWindow {
    id: root

    signal gone()

    readonly property int cols: 10
    readonly property int rows: 20
    readonly property var shapes: [[], [[0, 1], [1, 1], [2, 1], [3, 1]], [[0, 0], [1, 0], [0, 1], [1, 1]], [[1, 0], [0, 1], [1, 1], [2, 1]], [[1, 0], [2, 0], [0, 1], [1, 1]], [[0, 0], [1, 0], [1, 1], [2, 1]], [[0, 0], [0, 1], [1, 1], [2, 1]], [[2, 0], [0, 1], [1, 1], [2, 1]]]
    readonly property var sizes: [0, 4, 2, 3, 3, 3, 3, 3]
    readonly property var paint: { const c = kit.s("tetris_Colors"); return [kit.col(kit.s("tetris_CellColor"))].concat(kit.base.tetris_Colors.map((d, i) => typeof c[i] === "string" ? c[i] : d)) }
    readonly property color textMain: kit.col(kit.s("tetris_TextColor"))
    readonly property color textSoft: Qt.alpha(textMain, 0.6)
    readonly property color textDim: Qt.alpha(textMain, 0.38)
    readonly property color card: kit.col(kit.s("tetris_CardColor"))
    readonly property color cardBorder: kit.col(kit.s("tetris_BorderColor"))
    readonly property real round: kit.s("tetris_Radius")
    readonly property real cs: 28
    readonly property real side: cs * 6
    readonly property int glide: kit.s("tetris_MoveTime")

    property var board: Array(200).fill(0)
    property var shape: []
    property var bag: []
    property int kind: 0
    property int next: 1
    property int px: 0
    property int py: 0
    property int score: 0
    property int lines: 0
    property bool started: false
    property bool paused: false
    property bool over: false
    property real lastDown: 0
    readonly property int level: Math.floor(lines / 10) + 1
    readonly property bool live: started && !paused && !over
    readonly property int best: Math.max(score, scores.top.length ? scores.top[0].score : 0)
    readonly property int ghost: { let g = py; while (shape.length && fits(shape, px, g + 1)) g++; return g }

    function w(k) { return kit.word(k) }
    function fits(sh, x, y) {
        return sh.every(c => {
            const nx = x + c[0], ny = y + c[1]
            return nx >= 0 && nx < cols && ny < rows && (ny < 0 || board[ny * cols + nx] === 0)
        })
    }
    function draw() {
        if (!bag.length) {
            const b = [1, 2, 3, 4, 5, 6, 7]
            for (let i = b.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [b[i], b[j]] = [b[j], b[i]] }
            bag = b
        }
        const k = bag[0]
        bag = bag.slice(1)
        return k
    }
    function spawn() {
        kind = next
        next = draw()
        shape = shapes[kind].map(c => c.slice())
        px = Math.floor((cols - sizes[kind]) / 2)
        py = 0
        if (!fits(shape, px, py)) end()
    }
    function reset() {
        board = Array(rows * cols).fill(0)
        score = 0
        lines = 0
        bag = []
        next = draw()
        over = false
        paused = false
        started = true
        lastDown = 0
        spawn()
    }
    function move(dx, dy) {
        if (!live || !fits(shape, px + dx, py + dy)) return false
        px += dx
        py += dy
        return true
    }
    function rotate() {
        if (!live) return
        const n = sizes[kind]
        const r = shape.map(c => [n - 1 - c[1], c[0]])
        for (const k of [0, -1, 1, -2, 2]) if (fits(r, px + k, py)) { shape = r; px += k; return }
    }
    function soft() { if (move(0, 1)) score += 1; else if (live) lock() }
    function down(repeat) {
        const now = Date.now()
        if (!repeat && now - lastDown < kit.s("tetris_DoubleTap")) { lastDown = 0; hard(); return }
        if (!repeat) lastDown = now
        soft()
    }
    function hard() {
        if (!live) return
        let d = 0
        while (fits(shape, px, py + 1)) { py++; d++ }
        score += d * 2
        lock()
    }
    function lock() {
        const b = board.slice()
        for (const c of shape) {
            if (py + c[1] < 0) return end()
            b[(py + c[1]) * cols + px + c[0]] = kind
        }
        let cleared = 0
        for (let r = rows - 1; r >= 0; r--) {
            if (b.slice(r * cols, (r + 1) * cols).every(v => v)) {
                b.splice(r * cols, cols)
                b.unshift(...Array(cols).fill(0))
                cleared++
                r++
            }
        }
        const lv = level
        board = b
        if (cleared) { lines += cleared; score += [0, 100, 300, 500, 800][cleared] * lv }
        spawn()
    }
    function end() {
        over = true
        if (score <= 0) return
        scores.top = scores.top.concat([{ score: score, lines: lines, date: Qt.formatDateTime(new Date(), "yyyy-MM-dd") }]).sort((a, b) => b.score - a.score).slice(0, 5)
        scoresFile.writeAdapter()
    }

    title: "dolphin-tetris"
    implicitWidth: Math.round((Quickshell.screens[0]?.width ?? 1440) * kit.s("tetris_Width"))
    implicitHeight: Math.round((Quickshell.screens[0]?.height ?? 900) * kit.s("tetris_Height"))
    color: kit.col(kit.s("tetris_Color"))
    onVisibleChanged: if (!visible) gone()

    Kit {
        id: kit
        base: ({
            tetris_Width: 0.34, tetris_Height: 0.8, tetris_X: 0.33, tetris_Y: 0.1,
            tetris_Radius: 10, tetris_CellRadius: 0.15, tetris_MoveTime: 0, tetris_DoubleTap: 250,
            tetris_Color: "#000000", tetris_CardColor: "#0f0f0f", tetris_BorderColor: "#ffffff",
            tetris_TextColor: "#e8e2d9", tetris_CellColor: "#151515", tetris_FirstColor: "#e8c547",
            tetris_Colors: ["#3fb6d3", "#e8c547", "#9b6fd6", "#5fbf6a", "#d9596a", "#4f7fd9", "#e08a3c"]
        })
    }

    FileView {
        id: scoresFile
        path: Qt.resolvedUrl("../../../../Data/Dynamic/tetris.json")
        blockLoading: true
        printErrors: false
        JsonAdapter {
            id: scores
            property var top: []
        }
    }

    Timer {
        interval: Math.max(70, 800 - (root.level - 1) * 70)
        running: root.live
        repeat: true
        onTriggered: if (!root.move(0, 1)) root.lock()
    }

    Item {
        anchors.fill: parent
        focus: true
        Component.onCompleted: forceActiveFocus()
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Left) root.move(-1, 0)
            else if (e.key === Qt.Key_Right) root.move(1, 0)
            else if (e.key === Qt.Key_Down) root.down(e.isAutoRepeat)
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_X) root.rotate()
            else if (e.key === Qt.Key_Shift) { if (!e.isAutoRepeat) root.hard() }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (!e.isAutoRepeat) root.hard() }
            else if (e.key === Qt.Key_Space) (!root.started || root.over) ? root.reset() : root.hard()
            else if (e.key === Qt.Key_P || e.key === Qt.Key_Escape) { if (root.started && !root.over) root.paused = !root.paused }
            else if (e.key === Qt.Key_R) root.reset()
            else return
            e.accepted = true
        }

        Item {
            id: stage
            width: 580
            height: 780
            anchors.centerIn: parent
            scale: Math.min(root.width / width, root.height / height)

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 26
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.w("tetris").toUpperCase()
                    font.family: kit.font
                    font.pixelSize: 32
                    font.letterSpacing: 10
                    color: root.textMain
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.w("Classic") + "  ·  " + root.w("Level") + " " + root.level
                    font.family: kit.font
                    font.pixelSize: 12
                    font.letterSpacing: 3
                    color: root.textSoft
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 112
                spacing: 24

                Rectangle {
                    id: field
                    width: root.cs * root.cols + 12
                    height: root.cs * root.rows + 12
                    radius: root.round
                    color: root.card
                    border.width: 1
                    border.color: root.cardBorder

                    Item {
                        x: 6
                        y: 6
                        width: root.cs * root.cols
                        height: root.cs * root.rows

                        Repeater {
                            model: root.rows * root.cols
                            Rectangle {
                                required property int index
                                readonly property int v: root.board[index]
                                x: (index % root.cols) * root.cs + 1
                                y: Math.floor(index / root.cols) * root.cs + 1
                                width: root.cs - 2
                                height: width
                                radius: width * kit.s("tetris_CellRadius")
                                color: root.paint[v]
                                border.width: v ? 2 : 0
                                border.color: Qt.darker(color, 1.35)
                            }
                        }

                        Repeater {
                            model: root.live ? root.shape : []
                            Rectangle {
                                required property var modelData
                                x: (root.px + modelData[0]) * root.cs + 1
                                y: (root.ghost + modelData[1]) * root.cs + 1
                                width: root.cs - 2
                                height: width
                                radius: width * kit.s("tetris_CellRadius")
                                color: Qt.alpha(root.paint[root.kind], 0.12)
                                border.width: 1
                                border.color: Qt.alpha(Qt.lighter(root.paint[root.kind], 1.35), 0.5)
                                Behavior on x { NumberAnimation { duration: Motion.span(root.glide); easing.type: Easing.OutCubic } }
                            }
                        }

                        Repeater {
                            model: root.started && !root.over ? root.shape : []
                            Rectangle {
                                required property var modelData
                                visible: root.py + modelData[1] >= 0
                                x: (root.px + modelData[0]) * root.cs + 1
                                y: (root.py + modelData[1]) * root.cs + 1
                                width: root.cs - 2
                                height: width
                                radius: width * kit.s("tetris_CellRadius")
                                color: root.paint[root.kind]
                                border.width: 2
                                border.color: Qt.darker(color, 1.35)
                                Behavior on x { NumberAnimation { duration: Motion.span(root.glide); easing.type: Easing.OutCubic } }
                                Behavior on y { NumberAnimation { duration: Motion.span(root.glide); easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: kit.col(kit.s("tetris_Color"))
                        opacity: root.live ? 0 : 0.78
                        Behavior on opacity { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.w(root.over ? "Game over" : root.paused ? "Paused" : "Ready")
                                font.family: kit.font
                                font.pixelSize: 26
                                font.letterSpacing: 4
                                color: root.textMain
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: root.over
                                text: root.w("Score") + "  " + root.score
                                font.family: kit.font
                                font.pixelSize: 15
                                color: root.textSoft
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.w(root.over ? "Press Space to restart" : root.paused ? "Press P to resume" : "Press Space to start")
                                font.family: kit.font
                                font.pixelSize: 13
                                color: root.textDim
                            }
                        }
                    }
                }

                Column {
                    width: root.side
                    spacing: 14

                    Rectangle {
                        width: parent.width
                        height: nextCol.height + 24
                        radius: root.round
                        color: root.card
                        border.width: 1
                        border.color: root.cardBorder

                        Column {
                            id: nextCol
                            x: 12
                            y: 12
                            width: parent.width - 24
                            spacing: 10
                            Text { text: root.w("Next"); font.family: kit.font; font.pixelSize: 13; font.letterSpacing: 2; color: root.textSoft }
                            Item {
                                width: parent.width
                                height: root.cs * 2.6
                                Item {
                                    readonly property real s: root.cs * 0.8
                                    anchors.centerIn: parent
                                    width: root.sizes[root.next] * s
                                    height: (root.next === 1 ? 3 : 2) * s
                                    Repeater {
                                        model: root.started ? root.shapes[root.next] : []
                                        Rectangle {
                                            required property var modelData
                                            x: modelData[0] * parent.s + 1
                                            y: (modelData[1] - (root.next === 1 ? 0.5 : 0)) * parent.s + 1
                                            width: parent.s - 2
                                            height: width
                                            radius: width * kit.s("tetris_CellRadius")
                                            color: root.paint[root.next]
                                            border.width: 2
                                            border.color: Qt.darker(color, 1.35)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: statGrid.height + 24
                        radius: root.round
                        color: root.card
                        border.width: 1
                        border.color: root.cardBorder

                        Grid {
                            id: statGrid
                            x: 12
                            y: 12
                            columns: 2
                            rowSpacing: 14
                            columnSpacing: 8
                            Repeater {
                                model: [[root.w("Score"), root.score], [root.w("Best"), root.best], [root.w("Lines"), root.lines], [root.w("Level"), root.level]]
                                Column {
                                    required property var modelData
                                    width: (root.side - 32) / 2
                                    spacing: 3
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[0]; font.family: kit.font; font.pixelSize: 12; font.letterSpacing: 1; color: root.textSoft }
                                    Text { text: modelData[1]; font.family: kit.font; font.pixelSize: 20; color: root.textMain }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: boardCol.height + 24
                        radius: root.round
                        color: root.card
                        border.width: 1
                        border.color: root.cardBorder

                        Column {
                            id: boardCol
                            x: 12
                            y: 12
                            width: parent.width - 24
                            spacing: 8
                            Text { width: parent.width; elide: Text.ElideRight; text: root.w("Leaderboard"); font.family: kit.font; font.pixelSize: 13; font.letterSpacing: 1; color: root.textSoft }
                            Repeater {
                                model: scores.top
                                Item {
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    height: rank.height
                                    Text {
                                        id: rank
                                        text: (index + 1) + "."
                                        font.family: kit.font
                                        font.pixelSize: 13
                                        color: index === 0 ? kit.col(kit.s("tetris_FirstColor")) : root.textDim
                                    }
                                    Text {
                                        x: rank.width + 8
                                        text: modelData.score
                                        font.family: kit.font
                                        font.pixelSize: 13
                                        color: index === 0 ? root.textMain : root.textSoft
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        text: modelData.lines + " " + root.w("Lines").toLowerCase()
                                        font.family: kit.font
                                        font.pixelSize: 12
                                        color: root.textDim
                                    }
                                }
                            }
                            Text { visible: !scores.top.length; text: root.w("No records"); font.family: kit.font; font.pixelSize: 13; color: root.textDim }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "← → " + root.w("move") + "    ↑ " + root.w("rotate") + "    ↓ " + root.w("faster") + "    ↓↓ / Shift / Enter " + root.w("drop") + "    P " + root.w("pause") + "    R " + root.w("restart")
                font.family: kit.font
                font.pixelSize: 12
                color: root.textDim
            }
        }
    }
}
