import QtQuick

Grid {
    id: grid
    required property var sheet
    required property var host
    property int at: 0
    readonly property int year: Math.floor(at / 12)
    readonly property int month: ((at % 12) + 12) % 12
    readonly property int lead: (grid.host.weekday(year, month, 1) - sheet.first + 7) % 7
    readonly property int count: grid.host.daysIn(year, month)
    readonly property bool here: at === sheet.target

    columns: 7

    Repeater {
        model: 42
        Item {
            id: slot
            required property int index
            readonly property int day: index - grid.lead + 1
            readonly property bool valid: day >= 1 && day <= grid.count
            readonly property bool now: valid && day === grid.host.today.getDate() && grid.month === grid.host.today.getMonth() && grid.year === grid.host.today.getFullYear()
            readonly property bool picked: valid && grid.here && grid.sheet.keyed && grid.sheet.level === 1 && day === grid.sheet.pick
            readonly property real side: Math.min(width, height)
            property real fill: now && picked ? 1 : 0
            Behavior on fill { NumberAnimation { duration: Motion.span(220); easing.type: Easing.OutCubic } }
            width: grid.sheet.cell
            height: grid.sheet.unit * 0.95

            Rectangle {
                visible: slot.picked
                anchors.centerIn: parent
                width: slot.side * 0.98
                height: width
                radius: width * 0.28
                color: "transparent"
                border.width: 2
                border.color: grid.sheet.c.active
            }
            Rectangle {
                visible: slot.now
                anchors.centerIn: parent
                width: slot.side * (0.9 + 0.08 * slot.fill)
                height: width
                radius: width * (0.5 - 0.22 * slot.fill)
                color: grid.sheet.c.active
            }
            Text {
                visible: slot.valid
                anchors.centerIn: parent
                text: slot.day
                color: slot.now ? grid.sheet.c.bg : grid.sheet.c.text
                font.family: grid.sheet.c.font2; font.pixelSize: grid.sheet.unit * grid.sheet.c.listSize
            }
        }
    }
}
