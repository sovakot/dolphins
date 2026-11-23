import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../../../Backend"

Widget {
    id: media
    key: "media"
    icon: glyph(s("Icon")) || glyph("f001")
    ghost: !seen
    visible: fade > 0
    opacity: fade
    tip: wordy ? "" : line
    len: wordy ? row.implicitWidth : ring.size

    readonly property var list: Mpris.players.values
    readonly property var playing: list.find(p => p.isPlaying) ?? null
    property var last: null
    readonly property var player: playing ?? (last && list.includes(last) ? last : null)
    readonly property bool wordy: !vert && s("Text") !== false
    readonly property string title: clean(player?.trackTitle)
    readonly property string artist: String(player?.trackArtist ?? "").trim()
    readonly property string line: title + (artist !== "" && s("Artist") !== false ? " • " + artist : "")
    readonly property real length: Math.max(0, player?.length ?? 0)
    readonly property real position: Math.max(0, player?.position ?? 0)
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property bool live: !!playing || (s("Paused") === true && !!player && title !== "")
    property bool seen: false
    property bool watched: false
    property real fade: seen ? 1 : 0

    function clean(t) { return String(t ?? "").replace(/\s*[\(\[][^\)\]]*(official|video|audio|lyrics?|visuali[sz]er|remaster(ed)?|hd|hq|4k)[^\)\]]*[\)\]]/gi, "").trim() }
    function clock(v) {
        const n = Math.max(0, Math.floor(v)), h = Math.floor(n / 3600), m = Math.floor(n % 3600 / 60), sec = String(n % 60).padStart(2, "0")
        return h ? h + ":" + String(m).padStart(2, "0") + ":" + sec : m + ":" + sec
    }
    function toggle() { if (player && player.canTogglePlaying) player.togglePlaying() }
    function next() { if (player && player.canGoNext) player.next() }
    function previous() { if (player && player.canGoPrevious) player.previous() }
    function seek(part) { if (player && player.canSeek && length > 0) player.position = part * length }

    onPlayingChanged: if (playing) last = playing
    onLiveChanged: {
        if (!live) { linger.restart(); return }
        linger.stop()
        seen = true
    }
    Component.onCompleted: { if (playing) last = playing; seen = live }

    Behavior on fade { Glide {} }
    Timer { id: linger; interval: Math.max(0, media.s("Linger") ?? 1500); onTriggered: media.seen = media.live }
    Timer {
        interval: Math.max(250, media.s("Interval") ?? 1000)
        repeat: true
        running: !!media.playing && media.seen && (media.bar.open || media.watched)
        triggeredOnStart: true
        onTriggered: if (media.playing) media.playing.positionChanged()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: media.unit * 0.22

        Item {
            id: ring
            readonly property real size: Math.round(media.unit * 0.62 / 2) * 2
            readonly property real stroke: Math.max(1, Math.round(size * 0.1))
            anchors.verticalCenter: parent.verticalCenter
            width: size
            height: size

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.alpha(media.ink, 0.25)
                    strokeWidth: ring.stroke
                    fillColor: "transparent"
                    PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: (ring.size - ring.stroke) / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: media.ink
                    strokeWidth: ring.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: (ring.size - ring.stroke) / 2; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * media.progress }
                }
            }
            Disc {
                visible: media.s("Disc") !== false
                anchors.centerIn: parent
                width: Math.max(4, ring.size - ring.stroke * 2 - 2)
                height: width
                art: visible ? String(media.player?.trackArtUrl ?? "") : ""
                spinning: visible && !!media.playing && media.seen && media.bar.open
                spinTime: Number(media.bar.cfg?.media_SpinTime ?? 9000) || 9000
                plate: media.bar.tone(String(media.bar.cfg?.media_DiscColor ?? "#0b0b0b"))
                ink: media.ink
                hole: media.ink
                sign: media.icon
                signFont: media.iconFont
                part: 0.82
                grooves: 0
            }
            Icon {
                visible: media.s("Disc") === false
                anchors.centerIn: parent
                source: media.playing ? media.icon : media.glyph(media.s("PauseIcon")) || media.glyph("f04c")
                family: media.iconFont
                size: ring.size * 0.42
                grow: 1
                color: media.ink
            }
        }

        Text {
            visible: media.wordy
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, media.unit * Math.max(1, media.s("Width") ?? 6))
            elide: Text.ElideRight
            text: media.line
            font.family: media.textFont
            font.pixelSize: media.unit * 0.42
            font.weight: media.s("Bold") ? Font.Bold : Font.Normal
            color: media.ink
        }
    }

    backdrop: Component {
        ClippingRectangle {
            id: back
            readonly property var cfg: media.bar.cfg
            visible: media.s("Backdrop") !== false && cfg?.media_Backdrop !== false
            radius: parent ? parent.radius : 0
            color: "transparent"

            Backdrop {
                anchors.fill: parent
                anchors.margins: -24
                art: back.visible ? String(media.player?.trackArtUrl ?? "") : ""
                time: Math.max(0, Number(back.cfg?.media_ChangeTime ?? 600) || 0)
                opacity: Math.max(0, Math.min(1, Number(back.cfg?.media_BackdropOpacity ?? 0.28) || 0))
                blur: Number(back.cfg?.media_BackdropBlur ?? 1)
                reach: 48
            }
        }
    }

    page: Component {
        Parts.Sheet {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open

            readonly property bool keyed: parent.keyed
            property int cur: 1

            onActiveChanged: media.watched = active
            Component.onDestruction: media.watched = false

            function key(k) {
                if (k === "left") cur = (cur + 2) % 3
                else if (k === "right") cur = (cur + 1) % 3
                else if (k === "enter") cur === 0 ? media.previous() : cur === 2 ? media.next() : media.toggle()
                else return false
                return true
            }

            Item {
                id: card
                readonly property real disc: media.s("Cover") !== false && !!media.player ? Math.round(page.unit * Math.max(0.5, media.s("CoverSize") ?? 1.1) * 2.5) : 0
                readonly property real gap: page.unit * 0.4
                width: parent.width
                height: Math.max(disc, side.implicitHeight)

                Disc {
                    visible: card.disc > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: card.disc
                    height: card.disc
                    art: card.disc > 0 ? String(media.player?.trackArtUrl ?? "") : ""
                    spinning: visible && !!media.playing && page.active
                    spinTime: Number(media.bar.cfg?.media_SpinTime ?? 9000) || 9000
                    plate: media.bar.tone(String(media.bar.cfg?.media_DiscColor ?? "#0b0b0b"))
                    ink: page.c.text
                    hole: page.c.bg
                    sign: media.glyph("f001")
                    signFont: media.iconFont
                    grooves: 3
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Reveal.player() }
                }
                Column {
                    id: side
                    x: card.disc > 0 ? card.disc + card.gap : 0
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: page.unit * 0.06
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: media.player ? media.title || media.t("Unknown title") : media.t("Nothing is playing")
                        color: page.c.text
                        font.family: page.c.font2
                        font.pixelSize: page.unit * page.c.titleSize
                    }
                    Text {
                        visible: text !== ""
                        width: parent.width
                        elide: Text.ElideRight
                        text: media.artist + (media.player && media.player.identity ? (media.artist !== "" ? " • " : "") + media.player.identity : "")
                        opacity: 0.6
                        color: page.c.text
                        font.family: page.c.font2
                        font.pixelSize: page.unit * page.c.infoSize
                    }
                    Item {
                        width: parent.width
                        height: page.unit * 1.05
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: media.clock(media.position) + (media.length > 0 ? " / " + media.clock(media.length) : "")
                            opacity: 0.75
                            color: page.c.text
                            font.family: page.c.font2
                            font.pixelSize: page.unit * page.c.listSize
                        }
                        Rectangle {
                            id: go
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: page.unit * 0.95
                            height: width
                            radius: width / 2
                            color: Qt.alpha(page.c.text, goArea.containsMouse ? 0.22 : 0.12)
                            border.width: page.keyed && page.cur === 1 ? 2 : 0
                            border.color: page.c.active
                            scale: goArea.pressed ? 0.92 : 1
                            Behavior on color { Tint {} }
                            Behavior on scale { Glide {} }
                            Icon { anchors.centerIn: parent; source: media.glyph(media.playing ? "f04c" : "f04b"); family: media.iconFont; size: go.width * 0.38; grow: 1; color: page.c.text }
                            MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; onClicked: media.toggle() }
                        }
                    }
                    Item {
                        width: parent.width
                        height: page.unit * 0.7
                        Parts.Btn { id: back; round: true; anchors.verticalCenter: parent.verticalCenter; text: media.glyph("f048"); textColor: page.c.text; size: page.c.iconSmall * 0.85; marked: page.keyed && page.cur === 0; c: page.c; unit: page.unit; onClicked: media.previous() }
                        Parts.Btn { id: skip; round: true; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: media.glyph("f051"); textColor: page.c.text; size: page.c.iconSmall * 0.85; marked: page.keyed && page.cur === 2; c: page.c; unit: page.unit; onClicked: media.next() }
                        Item {
                            id: seek
                            property real drag: -1
                            readonly property real part: drag >= 0 ? drag : media.progress
                            readonly property real knob: Math.max(6, Math.round(page.unit * 0.2))
                            anchors.left: back.right
                            anchors.right: skip.left
                            anchors.leftMargin: page.unit * 0.15
                            anchors.rightMargin: page.unit * 0.15
                            height: parent.height
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: Math.max(2, Math.round(seek.knob * 0.34)); radius: height / 2; color: Qt.alpha(page.c.text, 0.22) }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * seek.part; height: Math.max(2, Math.round(seek.knob * 0.34)); radius: height / 2; color: page.c.text }
                            Rectangle {
                                x: (parent.width - width) * seek.part
                                anchors.verticalCenter: parent.verticalCenter
                                width: seek.knob * (seekArea.containsMouse || seek.drag >= 0 ? 1.35 : 1)
                                height: width
                                radius: width / 2
                                color: page.c.text
                                Behavior on width { Glide {} }
                            }
                            MouseArea {
                                id: seekArea
                                anchors.fill: parent
                                anchors.topMargin: -4
                                anchors.bottomMargin: -4
                                hoverEnabled: true
                                enabled: media.length > 0
                                onPressed: m => seek.drag = Math.max(0, Math.min(1, m.x / width))
                                onPositionChanged: m => { if (pressed) seek.drag = Math.max(0, Math.min(1, m.x / width)) }
                                onReleased: { if (seek.drag >= 0) media.seek(seek.drag); seek.drag = -1 }
                                onCanceled: seek.drag = -1
                            }
                        }
                    }
                }
            }
        }
    }
}
