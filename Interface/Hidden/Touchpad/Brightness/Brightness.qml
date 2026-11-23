import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../../Backend"

PanelWindow {
    id: bw

    required property var pad
    signal opened()

    property real widthRatio: 7
    property int holdTime: 2000
    property real curve: 4
    property int moonAt: 49
    property int morphTime: 450
    property string keyStep: "5%"

    property int max: 0
    property int raw: 0
    property int want: -1
    property bool shown: false
    property bool up: false
    property bool ready: false
    property bool keyMode: false
    property color ink: pad.tone("Text")
    readonly property real level: max ? Math.pow(raw / max, 1 / curve) : 0
    readonly property bool busy: bhov.hovered || bbar.pressed

    function s(k) { return pad.cfg?.["brightnessbar_" + k] }
    function show() { opened(); shown = true; bhold.restart() }
    function hide() { shown = false; keyMode = false; bhold.stop() }
    function toggle() { if (shown) hide(); else { show(); keyMode = true } }
    function grab() { show(); keyMode = true }
    function nudge(dir) {
        bhold.restart()
        if (!bstep.running) { bstep.command = ["brightnessctl", "-q", "-e" + curve, "-n2", "set", keyStep + dir]; bstep.running = true }
    }
    function setLevel(v) {
        want = Math.max(1, Math.round(Math.pow(v, curve) * max))
        if (!setter.running) { setter.command = ["brightnessctl", "-q", "set", String(want)]; setter.running = true }
    }

    onRawChanged: if (ready) show()
    onBusyChanged: if (!busy && shown) bhold.restart()
    Behavior on ink { Tint {} }

    Timer { id: bhold; interval: bw.holdTime; onTriggered: if (!bw.busy) { bw.shown = false; bw.keyMode = false } }
    GlobalShortcut { appid: "brightnessbar"; name: "show"; onPressed: bw.toggle() }

    Process {
        running: true
        command: ["sh", "-c", "d=$(ls -d /sys/class/backlight/* | head -n1); cat $d/max_brightness $d/brightness; udevadm monitor --kernel --subsystem-match=backlight | while read -r l; do cat $d/brightness; done"]
        stdout: SplitParser {
            onRead: line => {
                const n = parseInt(line)
                if (isNaN(n)) return
                if (!bw.max) { bw.max = n; return }
                bw.raw = n
                bw.ready = true
            }
        }
    }
    Process {
        id: setter
        onExited: if (command[3] !== String(bw.want)) { command = ["brightnessctl", "-q", "set", String(bw.want)]; running = true }
    }
    Process { id: bstep }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "brightnessbar"
    WlrLayershell.keyboardFocus: bw.keyMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    mask: Region { item: bpill }
    visible: bw.up
    onShownChanged: if (shown) up = true

    Rectangle {
        id: bpill
        readonly property real h: Math.round((bw.screen ? bw.screen.height : 0) * (bw.s("Height") ?? 0.045) * (bw.s("Scale") ?? 1))
        readonly property real hiddenY: -h - 4
        width: h * bw.widthRatio
        height: h
        x: (bw.width - width) / 2
        y: bw.shown ? (bw.s("Margin") ?? 10) : hiddenY
        radius: Math.min(bw.s("Radius") ?? 100, h / 2)
        color: bw.pad.tone(bw.s("Color") ?? "Background")
        border.width: 2
        border.color: bw.pad.tone("Accent2")
        Behavior on y { NumberAnimation { duration: Motion.span(bw.s("SlideTime") ?? 300); easing.type: Easing[bw.s("SlideEasing")] ?? Easing.OutExpo; onRunningChanged: if (!running && !bw.shown) bw.up = false } }
        Behavior on color { Tint {} }

        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Right) bw.nudge("+")
            else if (e.key === Qt.Key_Left) bw.nudge("-")
            else if (e.key === Qt.Key_Escape) bw.hide()
            else return
            e.accepted = true
        }

        HoverHandler { id: bhov }

        Item {
            id: sun
            readonly property real s: bpill.h * 0.5 * (bw.s("IconScale") ?? 1)
            readonly property bool moon: Math.round(bbar.shownV * 100) <= bw.moonAt
            readonly property real r: s * (0.24 + 0.16 * m)
            readonly property real br: s * 0.34
            property real m: moon ? 1 : 0
            Behavior on m { NumberAnimation { duration: Motion.span(bw.morphTime); easing.type: Easing.InOutCubic } }
            x: bpill.h * 0.35
            anchors.verticalCenter: parent.verticalCenter
            width: s
            height: s
            clip: true

            Repeater {
                model: 8
                Item {
                    required property int index
                    anchors.centerIn: parent
                    width: sun.s
                    height: sun.s
                    rotation: index * 45 + sun.m * 90
                    opacity: 1 - sun.m
                    Rectangle {
                        readonly property real len: sun.s * 0.13 * (1 - sun.m)
                        width: sun.s * 0.07
                        height: len
                        radius: width / 2
                        x: (sun.s - width) / 2
                        y: sun.s / 2 - sun.s * 0.38 * (1 - 0.4 * sun.m) - len / 2
                        color: bw.ink
                    }
                }
            }
            Rectangle {
                width: sun.r * 2
                height: width
                radius: width / 2
                x: sun.s / 2 - sun.r
                y: sun.s / 2 - sun.r
                color: bw.ink
            }
            Rectangle {
                visible: sun.m > 0
                width: sun.br * 2
                height: width
                radius: width / 2
                x: sun.s / 2 + sun.s * (0.7 - 0.48 * sun.m) - sun.br
                y: sun.s / 2 - sun.s * (0.7 - 0.52 * sun.m) - sun.br
                color: bpill.color
            }
        }

        Text {
            id: bnum
            anchors.right: parent.right
            anchors.rightMargin: bpill.h * 0.4
            anchors.verticalCenter: parent.verticalCenter
            width: bwidest.width
            horizontalAlignment: Text.AlignRight
            text: Math.round(bbar.shownV * 100)
            color: bw.ink
            font.family: bw.pad.cfg?.dolphin_TextFont ?? ""
            font.pixelSize: Math.max(1, bpill.h * 0.5 * (bw.s("TextScale") ?? 1))
        }
        TextMetrics { id: bwidest; font: bnum.font; text: "100" }

        Bar {
            id: bbar
            anchors { left: sun.right; leftMargin: bpill.h * 0.3; right: bnum.left; rightMargin: bpill.h * 0.3; verticalCenter: parent.verticalCenter }
            height: bpill.h * 0.5
            value: bw.level
            fillColor: bw.pad.tone("Active")
            handleColor: bw.ink
            emptyColor: bw.pad.tone("Inactive")
            onMoved: v => bw.setLevel(v)
        }
    }
}
