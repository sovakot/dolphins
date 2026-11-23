import QtQuick
import "../../../../Backend"

Item {
    id: extra

    required property var bar
    readonly property var items: bar.setting("Items", "widget_Extra") ?? []
    readonly property bool vert: bar.vert

    anchors.fill: parent

    Repeater {
        model: extra.items

        Icon {
            required property var modelData
            readonly property var pos: extra.vert ? modelData.PositionSide ?? modelData.Position : modelData.Position
            readonly property bool between: typeof pos !== "number"
            readonly property var a: between ? extra.bar.widgets[String(pos?.[0]).toLowerCase()] ?? null : null
            readonly property var b: between ? extra.bar.widgets[String(pos?.[1]).toLowerCase()] ?? null : null
            readonly property real reach: extra.vert ? height : width
            readonly property real at: a && b ? (Math.min(a.start + a.span, b.start + b.span) + Math.max(a.start, b.start) - reach) / 2 : between ? 0 : extra.bar.thick * pos
            readonly property string raw: modelData.Icon ?? ""

            visible: !between || !!(a && b)
            Behavior on x { Glide {} }
            Behavior on y { Glide {} }
            Behavior on color { Tint {} }
            x: extra.vert ? (parent.width - width) / 2 : at
            y: extra.vert ? at : (parent.height - height) / 2
            source: Art.has(raw) ? raw : /^[0-9a-fA-F]{2,6}$/.test(raw) ? String.fromCodePoint(parseInt(raw, 16)) : raw
            family: extra.bar.global("IconFont") ?? ""
            size: extra.bar.thick * 0.5 * (modelData.Scale ?? 1)
            color: extra.bar.tone(modelData.Color ?? "Text")
        }
    }
}
