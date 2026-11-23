import QtQuick

Item {
    id: b

    property real value: 0
    property color fillColor
    property color handleColor
    property color emptyColor
    property real drag: -1
    readonly property bool pressed: ma.pressed
    readonly property real v: drag >= 0 ? drag : value
    property real shownV: v
    readonly property real barH: height * 0.64
    readonly property real handleW: height * 0.14
    readonly property real gap: height * 0.14
    readonly property real cut: 0.15
    readonly property real track: width - handleW - gap * 2
    readonly property real hx: track * shownV + gap
    signal moved(real val)

    onValueChanged: if (!ma.pressed) drag = -1
    Behavior on shownV { enabled: !ma.pressed; NumberAnimation { duration: Motion.span(150); easing.type: Easing.OutCubic } }

    Rectangle {
        visible: width > 0
        anchors.verticalCenter: parent.verticalCenter
        width: b.track * b.shownV
        height: b.barH
        radius: height / 2
        topRightRadius: height * b.cut
        bottomRightRadius: height * b.cut
        color: b.fillColor
    }
    Rectangle {
        x: b.hx
        width: b.handleW
        height: b.height
        radius: width / 2
        color: b.handleColor
    }
    Rectangle {
        x: b.hx + b.handleW + b.gap
        visible: width > 0
        anchors.verticalCenter: parent.verticalCenter
        width: b.width - x
        height: b.barH
        radius: height / 2
        topLeftRadius: height * b.cut
        bottomLeftRadius: height * b.cut
        color: b.emptyColor
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        preventStealing: true
        function at(x) { b.drag = Math.max(0, Math.min(1, (x - b.gap - b.handleW / 2) / b.track)); b.moved(b.drag) }
        onPressed: m => at(m.x)
        onPositionChanged: m => at(m.x)
    }
}
