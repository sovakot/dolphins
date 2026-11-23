import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../../Backend"

Item {
    id: tabs
    required property var bar
    readonly property string prefix: "widget_Tabs"
    function s(k) { return bar.setting(k, prefix) }
    function c(k) { return bar.color(k, prefix) }

    readonly property bool vert: bar.vert
    readonly property var numbers: s("Number") ?? []
    readonly property int count: numbers.length
    property real unit: bar.thick * (s("Scale") ?? 1)
    readonly property real slotSize: unit * 0.7
    readonly property real step: slotSize + unit * 0.15 * (s("Spacing") ?? 1)
    readonly property real total: count > 0 ? (count - 1) * step + slotSize : 0
    property color dotColor: c("Color")
    property color activeColor: c("ActiveColor")
    readonly property color ink: Qt.darker(activeColor, 2.5)
    readonly property int fadeTime: 200
    readonly property var sizeEvents: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "activewindowv2"]
    readonly property int activeIndex: Math.max(0, Math.min(count - 1, (Hyprland.focusedWorkspace?.id ?? 1) - 1))

    property bool movingOn: true
    property real nearEdge: 0
    property real farEdge: 0

    function moveTo(i) {
        const l = i * step
        movingOn = l > nearEdge
        nearEdge = l
        farEdge = l + slotSize
    }

    onActiveIndexChanged: moveTo(activeIndex)
    onStepChanged: moveTo(activeIndex)
    Component.onCompleted: { moveTo(activeIndex); Hyprland.refreshToplevels() }

    Connections {
        target: Hyprland
        function onRawEvent(e) { if (tabs.sizeEvents.includes(e.name)) Hyprland.refreshToplevels() }
    }

    TapHandler {
        onTapped: (p) => {
            const at = tabs.vert ? p.position.y : p.position.x
            const i = Math.max(0, Math.min(tabs.count - 1, Math.floor((at + (tabs.step - tabs.slotSize) / 2) / tabs.step)))
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + (i + 1) + " })")
        }
    }

    Behavior on nearEdge { NumberAnimation { duration: Motion.span(tabs.movingOn ? tabs.s("SlideTime") : tabs.s("SlideTime") * tabs.s("Stretch")); easing.type: Easing[tabs.s("SlideEasing")] ?? Easing.OutCubic } }
    Behavior on farEdge { NumberAnimation { duration: Motion.span(tabs.movingOn ? tabs.s("SlideTime") * tabs.s("Stretch") : tabs.s("SlideTime")); easing.type: Easing[tabs.s("SlideEasing")] ?? Easing.OutCubic } }

    Binding { target: tabs.bar; property: "core"; value: tabs.total }
    Behavior on unit { Glide {} }
    Behavior on dotColor { Tint {} }
    Behavior on activeColor { Tint {} }

    implicitWidth: vert ? slotSize : total
    implicitHeight: vert ? total : slotSize

    Rectangle {
        x: tabs.vert ? 0 : tabs.nearEdge
        y: tabs.vert ? tabs.nearEdge : 0
        width: tabs.vert ? tabs.slotSize : tabs.farEdge - tabs.nearEdge
        height: tabs.vert ? tabs.farEdge - tabs.nearEdge : tabs.slotSize
        radius: tabs.slotSize / 2
        color: tabs.activeColor
    }

    Repeater {
        model: tabs.count

        Item {
            id: slot
            required property int index
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null
            readonly property bool active: tabs.activeIndex === index
            readonly property var app: {
                let best = null, min = 1e9
                for (const w of ws?.toplevels?.values ?? []) {
                    const f = w.lastIpcObject?.focusHistoryID ?? 1e8
                    if (f < min) { min = f; best = w }
                }
                return best?.wayland ?? null
            }
            readonly property bool disc: !!app && Emblem.spins(app.title)

            x: tabs.vert ? 0 : index * tabs.step
            y: tabs.vert ? index * tabs.step : 0
            width: tabs.slotSize
            height: width

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: tabs.dotColor
                opacity: slot.app && !slot.active ? 0.25 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.span(tabs.fadeTime) } }
            }

            Text {
                anchors.centerIn: parent
                visible: !slot.app
                text: tabs.numbers[slot.index] ?? ""
                color: slot.active ? tabs.ink : tabs.dotColor
                Behavior on color { ColorAnimation { duration: Motion.span(tabs.fadeTime) } }
                font.family: tabs.bar.global("TextFont") ?? ""
                font.weight: Font.Normal
                font.pixelSize: tabs.slotSize * 0.5 * (tabs.s("TextScale") ?? 1)
            }

            Disc {
                visible: slot.disc
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.72)
                height: width
                art: visible ? Emblem.art : ""
                spinning: visible && Emblem.playing && tabs.bar.open
                spinTime: Emblem.spinTime
                plate: Emblem.plate
                ink: tabs.ink
                hole: tabs.ink
                sign: String.fromCodePoint(0xf001)
                signFont: tabs.bar.global("IconFont") ?? ""
                part: 0.7
                grooves: 1
            }

            IconImage {
                id: icon
                anchors.centerIn: parent
                visible: !!slot.app && !slot.disc
                implicitSize: parent.width * 0.65
                source: slot.app ? Emblem.source(slot.app.title, slot.app.appId) : ""
            }

            IconImage {
                anchors.fill: icon
                visible: tabs.s("Tint") && icon.visible
                source: icon.source
                opacity: tabs.s("TintStrength")
                layer.enabled: visible
                layer.effect: MultiEffect {
                    brightness: 1.0
                    colorization: 1.0
                    colorizationColor: tabs.activeColor
                }
            }
        }
    }
}
