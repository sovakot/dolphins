import QtQuick
import QtQuick.Shapes

Shape {
    id: halo

    readonly property var host: parent
    readonly property color tint: host && host.tint !== undefined ? host.tint : "#ffffff"
    readonly property real core: host && host.core !== undefined ? host.core : 0.5
    readonly property real rim: host && host.rim !== undefined ? host.rim : 0
    readonly property real hold: host && host.hold !== undefined ? host.hold : 0
    readonly property real reach: host && host.reach !== undefined ? host.reach : 0.5

    anchors.fill: parent

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillGradient: RadialGradient {
            centerX: halo.width / 2
            centerY: halo.height / 2
            centerRadius: Math.max(1, Math.max(halo.width, halo.height) * halo.reach)
            focalX: centerX
            focalY: centerY
            GradientStop { position: 0; color: Qt.rgba(halo.tint.r, halo.tint.g, halo.tint.b, halo.core) }
            GradientStop { position: Math.max(0.01, Math.min(0.98, halo.hold)); color: Qt.rgba(halo.tint.r, halo.tint.g, halo.tint.b, halo.core) }
            GradientStop { position: 1; color: Qt.rgba(halo.tint.r, halo.tint.g, halo.tint.b, halo.rim) }
        }
        startX: 0
        startY: 0
        PathLine { x: halo.width; y: 0 }
        PathLine { x: halo.width; y: halo.height }
        PathLine { x: 0; y: halo.height }
        PathLine { x: 0; y: 0 }
    }
}
