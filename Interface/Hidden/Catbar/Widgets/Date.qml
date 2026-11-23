import QtQuick
import Quickshell
import "../../../../Backend"

Widget {
    id: date
    key: "date"
    len: along(vert ? stack : label)

    readonly property var formats: ({ MDY: "MM/dd/yyyy", DMY: "dd/MM/yyyy", YMD: "yyyy/MM/dd", D: "dddd, MM/dd" })
    readonly property string format: formats[s("Style")] ?? formats.MDY
    readonly property var today: Now.date
    readonly property var parts: format.split(/[^A-Za-z]+/).filter(f => f).map(f => today.toLocaleString(bar.locale, f === "dddd" ? "ddd" : f))

    Text {
        id: label
        visible: !date.vert
        anchors.centerIn: parent
        text: date.today.toLocaleString(date.bar.locale, date.format)
        font.family: date.textFont
        font.pixelSize: date.unit * 0.5
        font.weight: date.s("Bold") ? Font.Bold : Font.Normal
        color: date.ink
    }

    Lines {
        id: stack
        visible: date.vert
        anchors.centerIn: parent
        list: date.vert ? date.parts : []
        limit: date.base * 0.84
        family: date.textFont
        size: date.unit * 0.5
        weight: date.s("Bold") ? Font.Bold : Font.Normal
        color: date.ink
    }

    page: Component {
        Parts.Sheet {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open

            property int year: date.today.getFullYear()
            property int month: date.today.getMonth()
            readonly property int first: date.bar.locale.firstDayOfWeek
            readonly property int lead: (date.weekday(year, month, 1) - first + 7) % 7
            readonly property int count: date.daysIn(year, month)
            readonly property real cell: Math.floor(width / 7)
            readonly property bool keyed: parent.keyed
            readonly property int target: year * 12 + month
            property real glide: target
            Behavior on glide { enabled: page.active; NumberAnimation { duration: Motion.span(260); easing.type: Easing.OutCubic } }
            property int level: 0
            property int pick: 1

            function key(k) {
                if (level === 0) {
                    if (k === "left") step(-1)
                    else if (k === "right") step(1)
                    else if (k === "down" || k === "enter") {
                        const here = month === date.today.getMonth() && year === date.today.getFullYear()
                        pick = here ? date.today.getDate() : 1
                        level = 1
                    }
                    else return false
                    return true
                }
                if (k === "left") pick = pick > 1 ? pick - 1 : count
                else if (k === "right") pick = pick < count ? pick + 1 : 1
                else if (k === "down") pick = pick + 7 <= count ? pick + 7 : (pick - 1) % 7 + 1
                else if (k === "up") { if (pick > 7) pick -= 7; else level = 0 }
                else return false
                return true
            }

            function step(n) {
                const m = month + n
                year += Math.floor(m / 12)
                month = (m % 12 + 12) % 12
            }
            onActiveChanged: if (active) { year = date.today.getFullYear(); month = date.today.getMonth(); level = 0 }

            Item {
                width: parent.width
                height: page.unit * page.c.titleH

                Rectangle {
                    visible: page.keyed && page.level === 0
                    anchors.fill: parent
                    radius: height / 2
                    color: "transparent"
                    border.width: 2
                    border.color: page.c.active
                }
                Parts.Btn {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    round: true
                    text: String.fromCodePoint(0xf004d); textColor: page.c.text; size: page.c.iconSmall
                    c: page.c; unit: page.unit
                    onClicked: page.step(-1)
                }
                Text {
                    anchors.centerIn: parent
                    text: date.bar.locale.standaloneMonthName(page.month, Locale.LongFormat) + " " + page.year
                    color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * page.c.titleSize
                }
                Parts.Btn {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    round: true
                    rotation: 180
                    text: String.fromCodePoint(0xf004d); textColor: page.c.text; size: page.c.iconSmall
                    c: page.c; unit: page.unit
                    onClicked: page.step(1)
                }
            }

            Row {
                Repeater {
                    model: 7
                    Text {
                        required property int index
                        width: page.cell
                        horizontalAlignment: Text.AlignHCenter
                        text: date.bar.locale.dayName((page.first + index) % 7, Locale.ShortFormat)
                        opacity: 0.6
                        color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * page.c.infoSize
                    }
                }
            }

            Item {
                width: parent.width
                height: page.unit * 0.95 * 6
                clip: true

                Repeater {
                    model: 2
                    MonthGrid {
                        required property int index
                        sheet: page
                        host: date
                        at: Math.floor(page.glide) + index
                        x: (at - page.glide) * parent.width
                        width: parent.width
                    }
                }
            }
        }
    }
}
