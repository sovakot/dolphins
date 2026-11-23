import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import "../../../../Backend"

Widget {
    id: spk
    key: "sound"
    hot: true
    tip: muted ? t("Muted") : Math.round(volume * 100) + "%"
    len: size

    readonly property real size: unit * 0.62
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink && !!sink.audio && sink.audio.muted
    readonly property real volume: sink && sink.audio ? Math.min(1, sink.audio.volume) : 0
    readonly property real vol: muted ? 0 : volume
    property real a1: vol > 0.005 ? 1 : 0
    property real a2: vol >= 0.4 ? 1 : 0
    property real a3: vol >= 0.75 ? 1 : 0
    property real x0: vol <= 0.005 ? 1 : 0

    Behavior on a1 { NumberAnimation { duration: Motion.span(350); easing.type: Easing.OutCubic } }
    Behavior on a2 { NumberAnimation { duration: Motion.span(350); easing.type: Easing.OutCubic } }
    Behavior on a3 { NumberAnimation { duration: Motion.span(350); easing.type: Easing.OutCubic } }
    Behavior on x0 { NumberAnimation { duration: Motion.span(350); easing.type: Easing.OutCubic } }

    PwObjectTracker { objects: spk.sink ? [spk.sink] : [] }

    Item {
        anchors.centerIn: parent
        width: spk.size
        height: spk.size

        Rectangle { x: spk.size * 0.08; y: spk.size * 0.37; width: spk.size * 0.17; height: spk.size * 0.26; radius: spk.size * 0.03; color: spk.ink }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: spk.ink; strokeColor: "transparent"
                startX: spk.size * 0.22; startY: spk.size * 0.37
                PathLine { x: spk.size * 0.44; y: spk.size * 0.17 }
                PathLine { x: spk.size * 0.44; y: spk.size * 0.83 }
                PathLine { x: spk.size * 0.22; y: spk.size * 0.63 }
                PathLine { x: spk.size * 0.22; y: spk.size * 0.37 }
            }
            ShapePath {
                strokeColor: Qt.alpha(spk.ink, spk.a1); strokeWidth: spk.size * 0.07; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: spk.size * 0.44; centerY: spk.size * 0.5; radiusX: spk.size * 0.17 * (0.6 + 0.4 * spk.a1); radiusY: radiusX; startAngle: -40; sweepAngle: 80 }
            }
            ShapePath {
                strokeColor: Qt.alpha(spk.ink, spk.a2); strokeWidth: spk.size * 0.07; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: spk.size * 0.44; centerY: spk.size * 0.5; radiusX: spk.size * 0.3 * (0.6 + 0.4 * spk.a2); radiusY: radiusX; startAngle: -40; sweepAngle: 80 }
            }
            ShapePath {
                strokeColor: Qt.alpha(spk.ink, spk.a3); strokeWidth: spk.size * 0.07; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: spk.size * 0.44; centerY: spk.size * 0.5; radiusX: spk.size * 0.43 * (0.6 + 0.4 * spk.a3); radiusY: radiusX; startAngle: -40; sweepAngle: 80 }
            }
        }
        Repeater {
            model: [45, -45]
            Rectangle {
                required property real modelData
                width: spk.size * 0.34 * spk.x0
                height: spk.size * 0.07
                radius: height / 2
                x: spk.size * 0.73 - width / 2
                y: spk.size * 0.5 - height / 2
                rotation: modelData
                opacity: spk.x0
                color: spk.ink
            }
        }
    }
}
