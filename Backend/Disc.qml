import QtQuick
import Quickshell.Widgets

Item {
    id: disc

    property string art: ""
    property bool spinning: false
    property real spinTime: 9000
    property real speed: 1
    property color plate: "#0b0b0b"
    property color ink: "#ffffff"
    property color hole: "#000000"
    property string sign: ""
    property string signFont: ""
    property real part: 0.58
    property int grooves: 3
    property int time: 600

    implicitWidth: 32
    implicitHeight: implicitWidth

    FrameAnimation {
        running: disc.spinning && disc.visible && Motion.on
        onTriggered: body.rotation = (body.rotation + Math.min(0.1, frameTime) * 360000 / Math.max(500, disc.spinTime) * disc.speed) % 360
    }

    ClippingRectangle {
        id: body
        anchors.fill: parent
        radius: width / 2
        color: disc.plate

        Repeater {
            model: Math.max(0, disc.grooves)
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: parent.width * (0.94 - index * (0.3 / Math.max(1, disc.grooves)))
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(disc.ink, 0.09)
            }
        }
        ClippingRectangle {
            anchors.centerIn: parent
            width: parent.width * Math.max(0.2, Math.min(1, disc.part))
            height: width
            radius: width / 2
            color: Qt.alpha(disc.ink, 0.1)
            Cover { id: face; anchors.fill: parent; art: disc.art; time: disc.time; side: disc.width > 120 ? 512 : 128 }
            Text { anchors.centerIn: parent; visible: opacity > 0; opacity: (1 - face.shown) * 0.5; text: disc.sign; font.family: disc.signFont; font.pixelSize: parent.width * 0.42; color: disc.ink }
        }
        Rectangle { anchors.centerIn: parent; width: Math.max(2, parent.width * 0.06); height: width; radius: width / 2; color: disc.hole }
    }
}
