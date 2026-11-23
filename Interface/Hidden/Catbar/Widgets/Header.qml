import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../../Backend"

Widget {
    id: header
    key: "header"
    icon: sign(s("Icon"))
    hot: vert
    tip: vert ? (kind ? kind + " · " : "") + title : ""
    len: vert ? mark.height : row.implicitWidth

    readonly property real iconScale: s("IconScale") ?? 0.75
    readonly property var win: ToplevelManager.activeToplevel
    readonly property bool empty: !win || (Hyprland.focusedWorkspace?.toplevels?.values?.length ?? 1) === 0
    readonly property var match: empty ? null : ((s("Apps") ?? []).find(a => (win.appId || "").toLowerCase().includes(a[0])) ?? null)
    readonly property string kind: t(empty ? "Desktop" : match ? match[1] : "Application")
    readonly property string title: empty ? t("Workspace") + " " + (Hyprland.focusedWorkspace?.id ?? 1)
        : match && match[2] ? match[2]
        : pretty(win.appId) || win.title

    function pretty(id) {
        const t = (id || "").split(".").pop()
        return t.charAt(0).toUpperCase() + t.slice(1)
    }

    Icon {
        id: mark
        visible: header.vert
        anchors.centerIn: parent
        source: header.icon
        family: header.iconFont
        size: header.unit * 0.8 * header.iconScale
        grow: 1
        color: header.ink
    }

    Row {
        id: row
        visible: !header.vert
        anchors.centerIn: parent
        spacing: header.unit * 0.3

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: height
            height: labels.height

            Icon {
                anchors.centerIn: parent
                source: header.icon
                family: header.iconFont
                size: labels.height * header.iconScale
                grow: 1
                color: header.ink
            }
        }

        Column {
            id: labels
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: header.kind
                opacity: 0.5
                font.family: header.textFont
                font.pixelSize: header.unit * 0.33
                font.weight: header.s("Bold") ? Font.Bold : Font.Normal
                color: header.ink
            }

            Text {
                text: header.title
                width: Math.min(implicitWidth, header.unit * 12)
                elide: Text.ElideRight
                font.family: header.textFont
                font.pixelSize: header.unit * 0.48
                font.weight: header.s("Bold") ? Font.Bold : Font.Normal
                color: header.ink
            }
        }
    }
}
