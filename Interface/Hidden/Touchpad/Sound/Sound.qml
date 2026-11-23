import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../../../Backend"

PanelWindow {
    id: sw

    required property var pad
    signal opened()

    property real widthRatio: 7
    property int holdTime: 2000
    property real rowRatio: 0.75
    property real wave2: 0.4
    property real wave3: 0.75
    property int morphTime: 350
    property real silence: 0.001
    property int quietTime: 1500
    property real keyStep: 0.05

    property bool shown: false
    property bool up: false
    property bool ready: false
    property bool keyMode: false
    property int sel: 0
    property color ink: pad.tone("Text")
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink && !!sink.audio && sink.audio.muted
    readonly property real volume: sink && sink.audio ? Math.min(1, sink.audio.volume) : 0
    readonly property bool busy: shov.hovered || sbar.pressed
    readonly property var candidates: {
        const out = [], g = links.linkGroups
        for (let i = 0; i < g.length; i++) {
            const s = g[i].source
            if (s && s.isStream && !out.includes(s)) out.push(s)
        }
        return out
    }
    readonly property var streams: meters.instances.filter(m => m.loud || m.silenced).map(m => m.modelData)

    function s(k) { return pad.cfg?.["soundbar_" + k] }
    function show() { opened(); shown = true; shold.restart() }
    function hide() { shown = false; keyMode = false; shold.stop() }
    function toggle() { if (shown) hide(); else { show(); keyMode = true; sel = 0 } }
    function grab() { show(); keyMode = true }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
    function nudge(dir) {
        shold.restart()
        if (sel === 0) {
            if (!sstep.running) { sstep.command = ["wpctl", "set-volume"].concat(dir > 0 ? ["-l", "1"] : []).concat(["@DEFAULT_AUDIO_SINK@", Math.round(keyStep * 100) + (dir > 0 ? "%+" : "%-")]); sstep.running = true }
        } else {
            const n = streams[sel - 1]
            if (n && n.audio) n.audio.volume = Math.max(0, Math.min(1, n.audio.volume + keyStep * dir))
        }
    }

    onStreamsChanged: if (sel > streams.length) sel = streams.length
    onSinkChanged: if (ready) show()
    onBusyChanged: if (!busy && shown) shold.restart()
    Behavior on ink { Tint {} }

    PwNodeLinkTracker { id: links; node: sw.sink }
    PwObjectTracker { objects: sw.sink ? [sw.sink].concat(sw.candidates) : [] }
    Variants {
        id: meters
        model: sw.candidates
        Scope {
            id: mt
            required property var modelData
            property bool loud: false
            readonly property bool silenced: !!mt.modelData.audio && (mt.modelData.audio.muted || mt.modelData.audio.volume <= 0.005)
            PwNodePeakMonitor {
                node: mt.modelData
                enabled: sw.shown
                onPeakChanged: if (peak > sw.silence) { mt.loud = true; quiet.restart() }
            }
            Timer { id: quiet; interval: sw.quietTime; onTriggered: mt.loud = false }
        }
    }
    Connections {
        target: sw.sink ? sw.sink.audio : null
        function onVolumeChanged() { if (sw.ready) sw.show() }
        function onMutedChanged() { if (sw.ready) sw.show() }
    }
    Timer { running: true; interval: 1000; onTriggered: sw.ready = true }
    Timer { id: shold; interval: sw.holdTime; onTriggered: if (!sw.busy) { sw.shown = false; sw.keyMode = false } }
    Process { id: sstep }
    GlobalShortcut { appid: "soundbar"; name: "show"; onPressed: sw.toggle() }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "soundbar"
    WlrLayershell.keyboardFocus: sw.keyMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    mask: Region { item: spill }
    visible: sw.up
    onShownChanged: if (shown) up = true

    Rectangle {
        id: spill
        readonly property real h: Math.round((sw.screen ? sw.screen.height : 0) * (sw.s("Height") ?? 0.045) * (sw.s("Scale") ?? 1))
        readonly property real hiddenY: -height - 4
        width: h * sw.widthRatio
        height: scol.height + (sw.streams.length ? h * 0.15 : 0)
        x: (sw.width - width) / 2
        y: sw.shown ? (sw.s("Margin") ?? 10) : hiddenY
        clip: true
        radius: Math.min(sw.s("Radius") ?? 100, h / 2)
        color: sw.pad.tone(sw.s("Color") ?? "Background")
        border.width: 2
        border.color: sw.pad.tone("Accent2")
        Behavior on height { NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Motion.span(sw.s("SlideTime") ?? 300); easing.type: Easing[sw.s("SlideEasing")] ?? Easing.OutExpo; onRunningChanged: if (!running && !sw.shown) sw.up = false } }
        Behavior on color { Tint {} }

        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Right) sw.nudge(1)
            else if (e.key === Qt.Key_Left) sw.nudge(-1)
            else if (e.key === Qt.Key_Up) { sw.sel = Math.max(0, sw.sel - 1); shold.restart() }
            else if (e.key === Qt.Key_Down) { sw.sel = Math.min(sw.streams.length, sw.sel + 1); shold.restart() }
            else if (e.key === Qt.Key_Escape) sw.hide()
            else return
            e.accepted = true
        }

        HoverHandler { id: shov }

        Rectangle {
            readonly property real rowH: sw.sel === 0 ? spill.h : spill.h * sw.rowRatio
            visible: sw.keyMode && sw.streams.length > 0
            x: spill.h * 0.15
            width: spill.width - spill.h * 0.3
            height: rowH * 0.8
            y: (sw.sel === 0 ? 0 : spill.h + (sw.sel - 1) * spill.h * sw.rowRatio) + rowH * 0.1
            radius: height / 2
            color: Qt.alpha(sw.pad.tone("Active"), 0.15)
            Behavior on y { NumberAnimation { duration: Motion.span(150); easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: Motion.span(150); easing.type: Easing.OutCubic } }
        }

        Column {
            id: scol
            width: spill.width

            Item {
                width: scol.width
                height: spill.h

                Item {
                    id: spk
                    readonly property real s: spill.h * 0.5 * (sw.s("IconScale") ?? 1)
                    readonly property real vol: sw.muted ? 0 : sbar.shownV
                    readonly property color ink: sw.ink
                    property real a1: vol > 0.005 ? 1 : 0
                    property real a2: vol >= sw.wave2 ? 1 : 0
                    property real a3: vol >= sw.wave3 ? 1 : 0
                    property real x0: vol <= 0.005 ? 1 : 0
                    Behavior on a1 { NumberAnimation { duration: Motion.span(sw.morphTime); easing.type: Easing.OutCubic } }
                    Behavior on a2 { NumberAnimation { duration: Motion.span(sw.morphTime); easing.type: Easing.OutCubic } }
                    Behavior on a3 { NumberAnimation { duration: Motion.span(sw.morphTime); easing.type: Easing.OutCubic } }
                    Behavior on x0 { NumberAnimation { duration: Motion.span(sw.morphTime); easing.type: Easing.OutCubic } }
                    x: spill.h * 0.35
                    anchors.verticalCenter: parent.verticalCenter
                    width: s
                    height: s
                    TapHandler { onTapped: sw.toggleMute() }

                    Rectangle { x: spk.s * 0.08; y: spk.s * 0.37; width: spk.s * 0.17; height: spk.s * 0.26; radius: spk.s * 0.03; color: spk.ink }
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: spk.ink; strokeColor: "transparent"
                            startX: spk.s * 0.22; startY: spk.s * 0.37
                            PathLine { x: spk.s * 0.44; y: spk.s * 0.17 }
                            PathLine { x: spk.s * 0.44; y: spk.s * 0.83 }
                            PathLine { x: spk.s * 0.22; y: spk.s * 0.63 }
                            PathLine { x: spk.s * 0.22; y: spk.s * 0.37 }
                        }
                        ShapePath {
                            strokeColor: Qt.alpha(spk.ink, spk.a1); strokeWidth: spk.s * 0.07; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: spk.s * 0.44; centerY: spk.s * 0.5; radiusX: spk.s * 0.17 * (0.6 + 0.4 * spk.a1); radiusY: radiusX; startAngle: -40; sweepAngle: 80 }
                        }
                        ShapePath {
                            strokeColor: Qt.alpha(spk.ink, spk.a2); strokeWidth: spk.s * 0.07; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: spk.s * 0.44; centerY: spk.s * 0.5; radiusX: spk.s * 0.3 * (0.6 + 0.4 * spk.a2); radiusY: radiusX; startAngle: -40; sweepAngle: 80 }
                        }
                        ShapePath {
                            strokeColor: Qt.alpha(spk.ink, spk.a3); strokeWidth: spk.s * 0.07; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: spk.s * 0.44; centerY: spk.s * 0.5; radiusX: spk.s * 0.43 * (0.6 + 0.4 * spk.a3); radiusY: radiusX; startAngle: -40; sweepAngle: 80 }
                        }
                    }
                    Repeater {
                        model: [45, -45]
                        Rectangle {
                            required property real modelData
                            readonly property real len: spk.s * 0.34 * spk.x0
                            width: len
                            height: spk.s * 0.07
                            radius: height / 2
                            x: spk.s * 0.73 - width / 2
                            y: spk.s * 0.5 - height / 2
                            rotation: modelData
                            opacity: spk.x0
                            color: spk.ink
                        }
                    }
                }

                Text {
                    id: snum
                    anchors.right: parent.right
                    anchors.rightMargin: spill.h * 0.4
                    anchors.verticalCenter: parent.verticalCenter
                    width: swidest.width
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(sbar.shownV * 100)
                    color: sw.ink
                    font.family: sw.pad.cfg?.dolphin_TextFont ?? ""
                    font.pixelSize: Math.max(1, spill.h * 0.5 * (sw.s("TextScale") ?? 1))
                }
                TextMetrics { id: swidest; font: snum.font; text: "100" }

                Bar {
                    id: sbar
                    anchors { left: spk.right; leftMargin: spill.h * 0.3; right: snum.left; rightMargin: spill.h * 0.3; verticalCenter: parent.verticalCenter }
                    height: spill.h * 0.5
                    value: sw.volume
                    fillColor: sw.pad.tone("Active")
                    handleColor: sw.ink
                    emptyColor: sw.pad.tone("Inactive")
                    onMoved: v => { if (sw.sink && sw.sink.audio) { sw.sink.audio.volume = v; if (v > 0) sw.sink.audio.muted = false } }
                }
            }

            Repeater {
                model: ScriptModel { values: sw.streams }
                Item {
                    id: row
                    required property var modelData
                    readonly property var p: modelData.properties || ({})
                    readonly property string iconName: p["application.icon-name"] || (DesktopEntries.heuristicLookup(p["application.name"] || p["application.process.binary"] || "")?.icon ?? "")
                    width: scol.width
                    height: spill.h * sw.rowRatio
                    opacity: 0
                    Component.onCompleted: opacity = 1
                    Behavior on opacity { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }

                    IconImage {
                        x: spk.x + (spk.width - width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: row.height * 0.6
                        source: Quickshell.iconPath(row.iconName, "audio-x-generic")
                    }
                    Bar {
                        id: rowBar
                        x: sbar.x
                        width: sbar.width
                        anchors.verticalCenter: parent.verticalCenter
                        height: row.height * 0.5
                        value: row.modelData.audio ? Math.min(1, row.modelData.audio.volume) : 0
                        fillColor: sw.pad.tone("Active")
                        handleColor: sw.ink
                        emptyColor: sw.pad.tone("Inactive")
                        onMoved: v => { if (row.modelData.audio) row.modelData.audio.volume = v }
                    }
                    Text {
                        x: snum.x
                        width: snum.width
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(rowBar.shownV * 100)
                        color: sw.ink
                        font.family: sw.pad.cfg?.dolphin_TextFont ?? ""
                        font.pixelSize: Math.max(1, spill.h * 0.5 * (sw.s("TextScale") ?? 1))
                    }
                }
            }
        }
    }
}
