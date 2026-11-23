import QtQuick
import Quickshell
import "../../../../Backend"

Widget {
    id: clock
    key: "clock"
    len: along(vert ? stack : label)

    readonly property bool full: s("Style") === "24hr"
    readonly property var now: Now.date
    readonly property var parts: full
        ? [Qt.formatDateTime(now, "HH"), Qt.formatDateTime(now, "mm")]
        : [Qt.formatDateTime(now, "h AP").split(" ")[0], Qt.formatDateTime(now, "mm"), Qt.formatDateTime(now, "AP")]

    Text {
        id: label
        visible: !clock.vert
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.now, clock.full ? "HH:mm" : "h:mm AP")
        font.family: clock.textFont
        font.pixelSize: clock.unit * 0.5
        font.weight: clock.s("Bold") ? Font.Bold : Font.Normal
        color: clock.ink
    }

    Lines {
        id: stack
        visible: clock.vert
        anchors.centerIn: parent
        list: clock.vert ? clock.parts : []
        tail: !clock.full
        limit: clock.base * 0.84
        family: clock.textFont
        size: clock.unit * 0.5
        weight: clock.s("Bold") ? Font.Bold : Font.Normal
        color: clock.ink
    }
}
