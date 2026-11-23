import QtQuick
import "../../../../Backend"

Widget {
    id: lang
    key: "language"
    icon: code.toUpperCase()
    len: along(label)

    readonly property string code: bar.lang
    readonly property var list: [["en", "English"], ["ru", "Русский"], ["sr", "Српски"], ["vi", "Tiếng Việt"], ["zh", "中文"], ["ja", "日本語"], ["ko", "한국어"], ["fi", "Suomi"]]

    Text {
        id: label
        anchors.centerIn: parent
        text: lang.code.toUpperCase()
        font.family: lang.textFont
        font.pixelSize: lang.unit * 0.5
        font.weight: lang.s("Bold") ? Font.Bold : Font.Normal
        color: lang.ink
    }

    page: Component {
        Parts.Sheet {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open
            title: "Language"

            readonly property bool keyed: parent.keyed
            property int pick: 0
            onKeyedChanged: if (keyed) pick = Math.max(0, lang.list.findIndex(l => l[0] === lang.code))

            function key(k) {
                const n = lang.list.length
                if (k === "up") pick = (pick + n - 1) % n
                else if (k === "down") pick = (pick + 1) % n
                else if (k === "enter") lang.bar.save("dolphin_Language", lang.list[pick][0])
                else return false
                return true
            }

            Repeater {
                model: lang.list
                Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: lang.code === modelData[0]
                    width: parent.width
                    height: page.unit * page.c.rowH

                    HoverHandler { id: hov }
                    MouseArea { anchors.fill: parent; onPressed: lang.bar.save("dolphin_Language", row.modelData[0]) }
                    Rectangle {
                        visible: page.keyed && page.pick === row.index
                        anchors.fill: parent
                        radius: height / 2
                        color: "transparent"
                        border.width: 2
                        border.color: page.c.active
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: row.current ? page.c.active : page.c.inactive
                        opacity: row.current || hov.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                    }
                    Text {
                        x: page.unit * 0.45
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData[1]
                        color: row.current ? page.c.bg : page.c.text
                        font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: page.unit * 0.45
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData[0].toUpperCase()
                        opacity: 0.6
                        color: row.current ? page.c.bg : page.c.text
                        font.family: page.c.font2; font.pixelSize: page.unit * page.c.infoSize
                    }
                }
            }
        }
    }
}
