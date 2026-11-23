import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications as Notif
import "../../../../Backend"

Widget {
    id: note
    key: "notification"
    icon: sign(dnd ? s("OffArt") ?? "f13e7" : fresh ? s("NewArt") ?? "f116b" : s("Art") ?? "f0f3")
    lit: fresh > 0
    label: fresh ? fresh + " " + t("new") : ""
    tip: dnd ? t("Do not disturb") : fresh ? fresh + " " + t("new") : t("No notifications")
    len: along(mark)

    readonly property bool dnd: s("Dnd") === true
    readonly property int fresh: Math.min(unread, server.trackedNotifications.values.length)
    readonly property var look: ({
        title: 0.3, body: 0.28, pad: 0.3, radius: 0.3, gap: 0.2, alpha: 0.6,
        toastW: 9, toastGap: 0.25, toastPad: 0.35, max: 100
    })
    property int unread: 0
    property bool viewing: false

    Notif.NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        function trim() {
            const all = trackedNotifications.values.slice()
            for (let i = 0; i < all.length - note.look.max; i++) all[i].dismiss()
        }
        Component.onCompleted: Qt.callLater(trim)
        onNotification: n => {
            n.tracked = true
            trim()
            if (!note.viewing) {
                note.unread++
                if (!note.dnd) toast.show(n)
            }
        }
    }

    Icon {
        id: mark
        anchors.centerIn: parent
        source: note.icon
        family: note.iconFont
        size: note.unit * 0.5
        color: note.ink
    }

    PanelWindow {
        id: toast
        property string app: ""
        property string summary: ""
        property string body: ""
        property bool showing: false

        function show(n) {
            app = n.appName || "App"
            summary = n.summary
            body = n.body
            if (!showing) limit.restart()
            showing = true
            hold.restart()
        }

        screen: note.bar.screen
        anchors { top: true; right: true }
        margins {
            top: Math.round(note.base * note.look.toastGap + (note.bar.pos === "top" ? note.bar.gap + note.bar.thick : 0))
            right: Math.round(note.base * note.look.toastGap + (note.bar.pos === "right" ? note.bar.gap + note.bar.thick : 0))
        }
        implicitWidth: note.base * note.look.toastW
        implicitHeight: card.height
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "dolphin-toast"
        mask: Region {}
        color: "transparent"
        visible: card.opacity > 0

        Timer { id: hold; interval: note.s("ToastTime") ?? 1000; onTriggered: toast.showing = false }
        Timer { id: limit; interval: note.s("ToastLimit") ?? 5000; onTriggered: toast.showing = false }

        Rectangle {
            id: card
            readonly property real pad: note.base * note.look.toastPad
            width: toast.width
            height: words.height + pad * 2
            radius: note.base * 0.4
            color: note.pc("Color")
            border.width: 2
            border.color: note.pc("ActiveColor")
            opacity: toast.showing ? 1 : 0
            x: toast.showing ? 0 : note.base * 0.5
            Behavior on opacity { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }

            Column {
                id: words
                x: card.pad
                y: card.pad
                width: card.width - card.pad * 2
                spacing: note.base * 0.05
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: toast.app + " • " + toast.summary
                    color: note.pc("ActiveColor"); font.family: note.textFont; font.weight: Font.DemiBold; font.pixelSize: note.base * note.look.title
                }
                Text {
                    width: parent.width
                    visible: !!toast.body
                    text: toast.body
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                    opacity: 0.7
                    color: note.pc("TextColor"); font.family: note.textFont; font.pixelSize: note.base * note.look.body
                }
            }
        }
    }

    page: Component {
        Parts.Section {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open

            readonly property var items: server.trackedNotifications.values.slice().reverse()
            title: "Notifications"
            on: !note.dnd
            marked: keyed && cur === 0

            readonly property bool keyed: parent.keyed
            property int cur: 0

            function key(k) {
                const n = items.length + 2
                if (cur >= n) cur = n - 1
                if (k === "up") cur = (cur + n - 1) % n
                else if (k === "down") cur = (cur + 1) % n
                else if (k === "enter") {
                    const it = items[cur - 2]
                    if (cur === 0) toggled()
                    else if (cur === 1) clear()
                    else if (it) it.dismiss()
                } else return false
                return true
            }
            onToggled: note.bar.save("widget_NotificationDnd", !note.dnd)
            onActiveChanged: { note.viewing = active; if (active) note.unread = 0 }
            Component.onDestruction: note.viewing = false

            function clear() { for (const n of server.trackedNotifications.values.slice()) n.dismiss() }

            tools: Parts.Btn {
                text: "Clear all"; c: page.c; unit: page.unit
                marked: page.keyed && page.cur === 1
                enabled: page.items.length > 0
                opacity: enabled ? 1 : 0.4
                onClicked: page.clear()
            }

            Item {
                width: parent.width
                height: page.room - y

                Text {
                    anchors.centerIn: parent
                    text: note.t("No notifications")
                    opacity: page.items.length ? 0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Motion.span(page.c.fade) } }
                    color: page.c.text; font.family: page.c.font; font.pixelSize: page.unit * note.look.title
                }

                ListView {
                    id: scrollList
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: page.unit * note.look.gap
                    model: ScriptModel { values: page.items }
                    currentIndex: page.cur - 2
                    onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.span(page.c.fade) } }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: Motion.span(page.c.fade); easing.type: Easing.OutCubic }
                        NumberAnimation { property: "opacity"; to: 1; duration: Motion.span(page.c.fade) }
                    }

                    delegate: Rectangle {
                        id: box
                        required property var modelData
                        required property int index
                        readonly property bool picked: page.keyed && page.cur === index + 2
                        readonly property real pad: page.unit * note.look.pad
                        width: ListView.view.width
                        height: lines.height + pad * 2
                        radius: page.unit * note.look.radius
                        color: Qt.alpha(page.c.inactive, note.look.alpha)
                        border.width: picked ? 2 : 1
                        border.color: Qt.alpha(page.c.active, picked ? 1 : 0.5)

                        Column {
                            id: lines
                            x: box.pad
                            y: box.pad
                            width: box.width - box.pad * 2 - close.width
                            spacing: page.unit * 0.05
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: (box.modelData.appName || "App") + " • " + box.modelData.summary
                                color: page.c.active; font.family: page.c.font2; font.weight: Font.DemiBold; font.pixelSize: page.unit * note.look.title
                            }
                            Text {
                                width: parent.width
                                visible: !!box.modelData.body
                                text: box.modelData.body
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                                opacity: 0.7
                                color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * note.look.body
                            }
                        }
                        Parts.Btn {
                            id: close
                            anchors.right: parent.right; anchors.rightMargin: box.pad * 0.4
                            anchors.top: parent.top; anchors.topMargin: box.pad * 0.4
                            round: true
                            text: String.fromCodePoint(0xf0156); textColor: page.c.text; size: page.c.iconSmall
                            c: page.c; unit: page.unit
                            onClicked: box.modelData.dismiss()
                        }
                    }
                }
                Scroller { view: scrollList }
            }
        }
    }
}
