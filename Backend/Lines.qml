import QtQuick

Column {
    id: lines

    property var list: []
    property string family: ""
    property real size: 12
    property real limit: 0
    property int weight: Font.Normal
    property color color: "#000000"
    property bool tail: false

    spacing: -size * 0.14

    Repeater {
        model: lines.list

        Text {
            required property string modelData
            required property int index
            readonly property bool small: lines.tail && index === lines.list.length - 1
            width: lines.limit
            height: contentHeight
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 6
            text: modelData
            opacity: small ? 0.6 : 1
            color: lines.color
            font.family: lines.family
            font.weight: lines.weight
            font.pixelSize: Math.max(6, lines.size * (small ? 0.72 : 1))
        }
    }
}
