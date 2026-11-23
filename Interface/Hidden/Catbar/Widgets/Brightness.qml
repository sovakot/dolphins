import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import "../../../../Backend"

Widget {
    id: sun
    key: "brightness"
    hot: true
    tip: Math.round(level * 100) + "%"
    len: size

    readonly property real size: unit * 0.62
    readonly property real curve: 4
    readonly property int moonAt: 49
    property int max: 0
    property int raw: 0
    readonly property real level: max ? Math.pow(raw / max, 1 / curve) : 0
    readonly property bool moon: Math.round(level * 100) <= moonAt
    property real m: moon ? 1 : 0
    readonly property string body: disc(size / 2, size / 2, size * (0.24 + 0.16 * m), size / 2 + size * (0.7 - 0.48 * m), size / 2 - size * (0.7 - 0.52 * m), size * 0.34)

    Behavior on m { NumberAnimation { duration: Motion.span(450); easing.type: Easing.InOutCubic } }

    function disc(cx, cy, r, dx, dy, br) {
        const d = Math.hypot(dx - cx, dy - cy), pts = []
        const add = (x, y) => pts.push((Math.round(x * 100) / 100) + " " + (Math.round(y * 100) / 100))
        if (d >= r + br) {
            for (let i = 0; i < 32; i++) add(cx + r * Math.cos(i * Math.PI / 16), cy + r * Math.sin(i * Math.PI / 16))
        } else {
            const th = Math.atan2(dy - cy, dx - cx)
            const a = (r * r - br * br + d * d) / (2 * d)
            const al = Math.acos(Math.max(-1, Math.min(1, a / r)))
            const be = Math.acos(Math.max(-1, Math.min(1, (d - a) / br)))
            for (let i = 0; i <= 24; i++) {
                const g = th + al + (2 * Math.PI - 2 * al) * i / 24
                add(cx + r * Math.cos(g), cy + r * Math.sin(g))
            }
            for (let i = 1; i < 12; i++) {
                const g = th + Math.PI + be - 2 * be * i / 12
                add(dx + br * Math.cos(g), dy + br * Math.sin(g))
            }
        }
        return "M" + pts.join(" L") + " Z"
    }

    Process {
        running: true
        command: ["sh", "-c", "d=$(ls -d /sys/class/backlight/* | head -n1); cat $d/max_brightness $d/brightness; udevadm monitor --kernel --subsystem-match=backlight | while read -r l; do cat $d/brightness; done"]
        stdout: SplitParser {
            onRead: line => {
                const n = parseInt(line)
                if (isNaN(n)) return
                if (!sun.max) { sun.max = n; return }
                sun.raw = n
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: sun.size
        height: sun.size

        Repeater {
            model: 8
            Item {
                required property int index
                width: sun.size
                height: sun.size
                rotation: index * 45 + sun.m * 90
                opacity: 1 - sun.m
                Rectangle {
                    readonly property real len: sun.size * 0.13 * (1 - sun.m)
                    width: sun.size * 0.07
                    height: len
                    radius: width / 2
                    x: (sun.size - width) / 2
                    y: sun.size / 2 - sun.size * 0.38 * (1 - 0.4 * sun.m) - len / 2
                    color: sun.ink
                }
            }
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: sun.ink
                strokeWidth: -1
                PathSvg { path: sun.body }
            }
        }
    }
}
