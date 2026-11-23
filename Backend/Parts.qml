import QtQuick

// small shared pieces; other files use them as Parts.Btn, Parts.Section, ...
QtObject {

    // text with a hover box; set x: -padX to line the text up with other text
    component Btn: Item {
        id: b
        property string text
        property var c
        property real unit: 30
        property real size: c.btnSize
        property color textColor: c.active
        property bool round: false             // true = circle box (width = height)
        property bool symbol: round            // true = the text is an icon, centered by its visible shape
        property bool marked: false
        readonly property real padX: unit * c.btnPad
        signal clicked()
        width: round ? height : label.implicitWidth + padX * 2
        height: unit * c.btnH
        HoverHandler { id: hov }
        MouseArea { anchors.fill: parent; onPressed: b.clicked() }
        Rectangle { anchors.fill: parent; radius: height / 2; color: b.c.inactive; opacity: hov.hovered || b.marked ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } } }
        TextMetrics { id: ink; font: label.font; text: label.text }
        Text {
            id: label
            x: b.symbol ? (b.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x : (b.width - width) / 2
            y: b.symbol ? (b.height - ink.tightBoundingRect.height) / 2 - baselineOffset - ink.tightBoundingRect.y : (b.height - height) / 2
            text: (b.c.words && b.c.words[b.text] && b.c.words[b.text][b.c.lang]) || b.text
            color: b.textColor; font.family: b.c.font; font.pixelSize: b.unit * b.size
        }
    }

    // key on the left, value on the right
    component Info: Item {
        id: i
        property string key
        property string value
        property var c
        property real unit: 30
        width: parent.width
        height: unit * c.infoH
        Text { id: tag; anchors.verticalCenter: parent.verticalCenter; text: (i.c.words && i.c.words[i.key] && i.c.words[i.key][i.c.lang]) || i.key; opacity: 0.6; color: i.c.text; font.family: i.c.font; font.pixelSize: i.unit * i.c.infoSize }
        Text {
            anchors.left: tag.right; anchors.leftMargin: i.unit * 0.3
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
            text: i.value; color: i.c.text; font.family: i.c.font; font.pixelSize: i.unit * i.c.infoSize
        }
    }

    // label + switch; big = page title
    component Toggle: Item {
        id: t
        property string label
        property bool on
        property bool big: false
        property bool user: false
        property bool marked: false
        property var c
        property real unit: 30
        readonly property real labelW: txt.width
        signal toggled()
        width: parent.width
        height: unit * (big ? c.titleH : c.labelH)
        onVisibleChanged: user = false

        // capital letters are centered on the switch, measured from the real glyph
        Text {
            id: txt
            y: Math.round(t.height / 2 + cap.tightBoundingRect.height / 2 - baselineOffset + (t.big ? t.c.titleY : 0))
            text: (t.c.words && t.c.words[t.label] && t.c.words[t.label][t.c.lang]) || t.label
            font.family: t.c.font; font.pixelSize: t.unit * (t.big ? t.c.titleSize : t.c.labelSize)
            color: t.c.text
        }
        TextMetrics { id: cap; font: txt.font; text: "H" }


        Rectangle {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: t.unit * t.c.switchW; height: t.unit * t.c.switchH; radius: height / 2
            color: t.on ? t.c.active : t.c.inactive
            Behavior on color { enabled: t.user; ColorAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
            Rectangle {
                visible: t.marked
                anchors.fill: parent
                anchors.margins: -Math.max(3, Math.round(t.unit * 0.1))
                radius: height / 2
                color: "transparent"; border.width: 2; border.color: t.c.active
            }
            Rectangle {
                width: parent.height * 0.7; height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: t.on ? parent.width - width - parent.height * 0.15 : parent.height * 0.15
                color: t.on ? t.c.bg : t.c.text
                Behavior on x { enabled: t.user; NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                Behavior on color { enabled: t.user; ColorAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
            }
            MouseArea { anchors.fill: parent; onPressed: { t.user = true; t.toggled() } }
        }
    }

    // settings header: back arrow with hover box, then the name
    component Head: Item {
        id: h
        property string name
        property bool marked: false
        property var c
        property real unit: 30
        signal back()
        width: parent.width
        height: unit * c.rowH

        Btn {
            id: arrow
            x: -padX
            anchors.verticalCenter: parent.verticalCenter
            symbol: true
            text: String.fromCodePoint(0xf004d); textColor: h.c.text; size: h.c.iconSmall
            c: h.c; unit: h.unit
            marked: h.marked
            onClicked: h.back()
        }
        Text {
            anchors.left: arrow.right; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: h.name; elide: Text.ElideRight; color: h.c.active
            font.family: h.c.font2; font.pixelSize: h.unit * h.c.listSize
        }
    }

    // filled pill | gap | thin handle | gap | empty pill
    component Slider: Item {
        id: s
        property real value: 0                 // 0..1 from outside
        property var c
        property real unit: 30
        property real barH: unit * 0.45
        property real handleW: unit * 0.1
        property real gap: unit * 0.1
        property real cut: 0.15                // corner size next to the handle, as a share of barH
        property real drag: -1
        property bool marked: false
        readonly property real v: drag >= 0 ? drag : value
        readonly property real track: width - handleW - gap * 2
        readonly property real hx: track * v + gap
        signal released(real val)
        signal moved(real val)
        width: parent.width
        height: unit * 0.65
        onValueChanged: drag = -1

        Rectangle {
            visible: s.marked
            anchors.fill: parent
            anchors.leftMargin: -Math.max(4, Math.round(s.unit * 0.14)); anchors.rightMargin: anchors.leftMargin
            anchors.topMargin: -Math.max(3, Math.round(s.unit * 0.1)); anchors.bottomMargin: anchors.topMargin
            radius: height / 2
            color: "transparent"; border.width: 2; border.color: s.c.active
        }
        Rectangle {
            visible: width > 0
            anchors.verticalCenter: parent.verticalCenter
            width: s.track * s.v; height: s.barH
            radius: height / 2; topRightRadius: height * s.cut; bottomRightRadius: height * s.cut
            color: s.c.active
        }
        Rectangle {
            x: s.hx
            width: s.handleW; height: s.height; radius: width / 2
            color: s.c.text
        }
        Rectangle {
            x: s.hx + s.handleW + s.gap
            visible: width > 0
            anchors.verticalCenter: parent.verticalCenter
            width: s.width - x; height: s.barH
            radius: height / 2; topLeftRadius: height * s.cut; bottomLeftRadius: height * s.cut
            color: s.c.inactive
        }
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            function at(x) { s.drag = Math.max(0, Math.min(1, (x - s.gap - s.handleW / 2) / s.track)); s.moved(s.drag) }
            onPressed: m => at(m.x)
            onPositionChanged: m => at(m.x)
            onReleased: s.released(s.drag)
        }
    }

    // page layout: title + switch, then the page's content; fades in and out
    component Section: Column {
        id: sec
        property string title
        property bool on
        property bool marked: false
        property bool shown: false
        property bool open: false
        readonly property bool active: shown && open      // page is on screen, used to run scans only then
        property var c
        property real unit: 30
        readonly property real room: sec.height - inner.y
        default property alias content: inner.data
        property alias head: top.data
        property alias tools: tray.data
        signal toggled()
        spacing: unit * 0.2

        Column { id: top; visible: children.length > 0; width: sec.width; spacing: sec.unit * 0.2 }
        Item {
            width: sec.width
            height: switcher.height
            Toggle { id: switcher; label: sec.title; big: true; on: sec.on; marked: sec.marked; c: sec.c; unit: sec.unit; onToggled: sec.toggled() }
            Row {
                id: tray
                x: Math.max(0, Math.min(switcher.labelW + sec.unit * 0.3, parent.width - sec.unit * (sec.c.switchW + 0.3) - width))
                anchors.verticalCenter: parent.verticalCenter
                spacing: sec.unit * 0.2
            }
        }
        Column { id: inner; width: sec.width; spacing: sec.unit * 0.2 }
    }

    // page layout without a switch: optional title, then the page's content; fades in and out
    component Sheet: Column {
        id: sh
        property string title
        property bool shown: false
        property bool open: false
        readonly property bool active: shown && open
        property var c
        property real unit: 30
        property var sel: null
        readonly property real room: sh.height - body.y
        default property alias content: body.data
        function back() { sel = null }
        spacing: unit * 0.2

        Text {
            visible: sh.title !== ""
            height: sh.unit * sh.c.titleH
            verticalAlignment: Text.AlignVCenter
            text: (sh.c.words && sh.c.words[sh.title] && sh.c.words[sh.title][sh.c.lang]) || sh.title
            color: sh.c.text; font.family: sh.c.font; font.pixelSize: sh.unit * sh.c.titleSize
        }
        Column { id: body; width: sh.width; spacing: sh.unit * 0.2 }
    }
}
