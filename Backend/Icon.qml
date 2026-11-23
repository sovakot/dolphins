import QtQuick
import QtQuick.Shapes

Item {
    id: icon

    property string source: ""
    property string family: ""
    property color color: "#000000"
    property real size: 0
    property real grow: 1.15
    property color rim: "transparent"

    readonly property string path: Art.path(source)
    readonly property bool drawn: path !== ""
    readonly property real box: Math.round(size * grow / 2) * 2

    implicitWidth: drawn ? box : ink.tightBoundingRect.width
    implicitHeight: drawn ? box : ink.tightBoundingRect.height

    Shape {
        visible: icon.drawn
        width: icon.box
        height: icon.box
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: icon.color
            strokeColor: icon.rim
            strokeWidth: icon.rim.a > 0 ? 1.2 : -1
            scale: Qt.size(icon.box / 24, icon.box / 24)
            PathSvg { path: icon.path }
        }
    }

    TextMetrics { id: ink; font: label.font; text: label.text }
    Text {
        id: label
        visible: !icon.drawn
        x: -ink.tightBoundingRect.x
        y: -(baselineOffset + ink.tightBoundingRect.y)
        text: icon.drawn ? "" : icon.source
        color: icon.color
        style: icon.rim.a > 0 ? Text.Outline : Text.Normal
        styleColor: icon.rim
        font.family: icon.family
        font.pixelSize: Math.max(1, icon.size)
    }
}
