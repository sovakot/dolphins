import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import Quickshell.Services.UPower
import "../../../../Backend"

Widget {
    id: bat
    key: "battery"
    icon: symbol
    hot: true
    tip: Math.round(level * 100) + "%"
    spot: "IconPosition"
    len: ring.size

    readonly property var dev: UPower.displayDevice
    readonly property real level: { const p = dev ? dev.percentage : 0; return p > 1 ? p / 100 : p }
    readonly property int step: Math.max(1, Math.round(level * 10))
    readonly property string symbol: plugged ? glyph(s("ChargingIcon")) : step >= 10 ? glyph(s("Icon")) : String.fromCodePoint(0xf0079 + step)
    property bool plugged: false

    Process {
        running: true
        command: ["sh", "-c", "cat /sys/class/power_supply/A*/online; udevadm monitor --kernel --subsystem-match=power_supply | while read -r l; do cat /sys/class/power_supply/A*/online; done"]
        stdout: SplitParser { onRead: line => bat.plugged = line.trim() === "1" }
    }

    Item {
        id: ring
        readonly property real size: Math.round(bat.base * 0.7 * bat.s("IconScale") / 2) * 2
        readonly property real stroke: Math.max(1, Math.round(size * 0.1))
        anchors.centerIn: parent
        width: size
        height: size

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.alpha(bat.ink, 0.25)
                strokeWidth: ring.stroke
                fillColor: "transparent"
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: (ring.size - ring.stroke) / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: bat.ink
                strokeWidth: ring.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: (ring.size - ring.stroke) / 2; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * bat.level }
            }
        }

        Shape {
            id: sign
            x: (ring.size - boundingRect.width) / 2 - boundingRect.x
            y: (ring.size - boundingRect.height) / 2 - boundingRect.y
            width: ring.size
            height: ring.size
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: bat.ink
                strokeWidth: -1
                PathText {
                    x: 0
                    y: 0
                    text: bat.symbol
                    font.family: bat.iconFont
                    font.pixelSize: Math.max(1, Math.round(ring.size * 0.55))
                }
            }
        }
    }
}
