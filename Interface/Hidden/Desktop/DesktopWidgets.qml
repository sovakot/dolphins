import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "../../../Backend"

Kit {
    id: root

    base: ({
        desktop_Show: true, desktop_Inverted: false, desktop_Contrast: false, desktop_ContrastStrength: 1, desktop_X: 0.5, desktop_Y: 0.28, desktop_Scale: 1, desktop_Spacing: 0.4, desktop_Color: "Text", desktop_AccentColor: "Active", desktop_Opacity: 0.9,
        desktop_Order: ["Greeting", "Clock", "Date", "Weather", "Battery", "Media"],
        desktop_Greeting: false, desktop_GreetingScale: 1, desktop_Battery: false, desktop_BatteryScale: 1,
        desktop_Clock: true, desktop_ClockType: "digital", desktop_ClockStyle: "12hr", desktop_ClockSeconds: false, desktop_ClockBold: false, desktop_ClockScale: 1,
        desktop_Date: true, desktop_DateStyle: "D", desktop_DateScale: 1,
        desktop_Weather: false, desktop_WeatherUnit: "F", desktop_WeatherScale: 1,
        desktop_Media: false, desktop_MediaScale: 1, desktop_MediaWidth: 30, desktop_MediaDisc: true
    })

    readonly property color inkSet: col(s("desktop_Color"))
    readonly property color accentSet: col(s("desktop_AccentColor"))
    readonly property color ink: s("desktop_Inverted") ? Qt.rgba(1 - inkSet.r, 1 - inkSet.g, 1 - inkSet.b, 1) : inkSet
    readonly property color accent: s("desktop_Inverted") ? Qt.rgba(1 - accentSet.r, 1 - accentSet.g, 1 - accentSet.b, 1) : accentSet
    readonly property bool bold: s("desktop_Contrast")
    readonly property real firm: Math.max(0, Math.min(1, s("desktop_ContrastStrength")))
    readonly property color rim: 0.299 * ink.r + 0.587 * ink.g + 0.114 * ink.b > 0.5 ? "#000000" : "#ffffff"
    readonly property color line: bold ? Qt.alpha(rim, firm) : "transparent"
    readonly property real charge: { const p = UPower.displayDevice ? UPower.displayDevice.percentage : 0; return p > 1 ? p / 100 : p }
    readonly property bool ticking: s("desktop_Show") && s("desktop_Clock") && s("desktop_ClockSeconds")
    readonly property var now: Now.date
    readonly property var locales: ({ en: "en_US", ru: "ru_RU", sr: "sr_RS", vi: "vi_VN", zh: "zh_CN", ja: "ja_JP", ko: "ko_KR", fi: "fi_FI" })
    readonly property var place: Qt.locale(locales[lang] ?? "en_US")
    readonly property var dates: ({ MDY: "MM/dd/yyyy", DMY: "dd/MM/yyyy", YMD: "yyyy/MM/dd", D: "dddd, MM/dd", L: "dddd, d MMMM" })
    readonly property var arts: ({ clear: ["sun", "moon"], cloudy: ["cloudSun", "cloudMoon"], rain: ["rainSun", "rainMoon"], snow: ["snowSun", "snowMoon"], thunder: ["boltSun", "boltMoon"] })
    readonly property var kinds: ({ clear: "Clear", cloudy: "Cloudy", rain: "Rain", snow: "Snow", thunder: "Thunderstorm" })
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property var parts: ({ Greeting: greetC, Clock: clockC, Date: dateC, Weather: weatherC, Battery: batteryC, Media: mediaC })

    function shows(name) { return s("desktop_" + name) === true && !!parts[name] }

    onTickingChanged: Now.seconds("desktop", ticking)
    Component.onCompleted: Now.seconds("desktop", ticking)

    component Label: Text {
        color: root.ink
        font.family: root.font
        horizontalAlignment: Text.AlignHCenter
        style: root.bold ? Text.Outline : Text.Normal
        styleColor: root.line
        Behavior on color { Tint {} }
    }

    Component {
        id: clockC

        Item {
            id: clock
            readonly property real unit: parent.unit * Math.max(0.2, root.s("desktop_ClockScale"))
            readonly property int h: root.now.getHours()
            readonly property int m: root.now.getMinutes()
            readonly property int sec: root.now.getSeconds()
            readonly property bool full: root.s("desktop_ClockStyle") === "24hr"
            readonly property bool secs: root.s("desktop_ClockSeconds")
            readonly property string kind: root.s("desktop_ClockType")
            readonly property string hours: String(full ? h : (h % 12 || 12)).padStart(full || kind === "stacked" ? 2 : 1, "0")
            readonly property string mins: String(m).padStart(2, "0")
            readonly property int weight: root.s("desktop_ClockBold") ? Font.DemiBold : Font.Light
            readonly property real face: unit * 9.5
            implicitWidth: kind === "analog" ? face : kind === "stacked" ? pile.width : digits.width
            implicitHeight: kind === "analog" ? face : kind === "stacked" ? pile.height : digits.height

            Row {
                id: digits
                visible: clock.kind !== "analog" && clock.kind !== "stacked"
                spacing: clock.unit * 0.15
                Label { id: big; text: clock.hours; font.pixelSize: clock.unit * 5.2; font.weight: clock.weight; font.letterSpacing: -clock.unit * 0.1 }
                Label {
                    anchors.baseline: big.baseline
                    text: ":"
                    color: root.accent
                    font.pixelSize: clock.unit * 5.2
                    font.weight: clock.weight
                    opacity: clock.secs && clock.sec % 2 ? 0.35 : 1
                    Behavior on opacity { NumberAnimation { duration: Motion.span(400) } }
                }
                Label { anchors.baseline: big.baseline; text: clock.mins; font.pixelSize: clock.unit * 5.2; font.weight: clock.weight; font.letterSpacing: -clock.unit * 0.1 }
                Column {
                    anchors.bottom: big.baseline
                    visible: clock.secs || !clock.full
                    leftPadding: clock.unit * 0.35
                    Label { visible: clock.secs; text: String(clock.sec).padStart(2, "0"); color: root.accent; font.pixelSize: clock.unit * 1.5; font.weight: Font.Medium }
                    Label { visible: !clock.full; text: clock.h < 12 ? "AM" : "PM"; font.pixelSize: clock.unit * 1.2; opacity: 0.7 }
                }
            }

            Column {
                id: pile
                visible: clock.kind === "stacked"
                spacing: -clock.unit * 1.7
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: clock.hours; font.pixelSize: clock.unit * 7.5; font.weight: Font.Bold; font.letterSpacing: -clock.unit * 0.2 }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: clock.mins; color: root.accent; font.pixelSize: clock.unit * 7.5; font.weight: Font.Bold; font.letterSpacing: -clock.unit * 0.2 }
            }

            Item {
                visible: clock.kind === "analog"
                width: clock.face
                height: clock.face

                Rectangle { visible: root.bold; anchors.fill: parent; anchors.margins: -1; radius: width / 2; color: "transparent"; border.width: Math.max(1, clock.unit * 0.1) + 2; border.color: root.line }
                Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.alpha(root.ink, 0.08); border.width: Math.max(1, clock.unit * 0.1); border.color: Qt.alpha(root.ink, root.bold ? 1 : 0.55) }
                Repeater {
                    model: clock.kind === "analog" ? 12 : 0
                    Item {
                        required property int index
                        anchors.fill: parent
                        rotation: index * 30
                        Rectangle {
                            x: (parent.width - width) / 2
                            y: clock.unit * 0.55
                            width: Math.max(1, clock.unit * (index % 3 === 0 ? 0.2 : 0.12))
                            height: index % 3 === 0 ? clock.unit * 0.75 : width
                            radius: width / 2
                            color: index % 3 === 0 ? root.accent : root.ink
                            opacity: index % 3 === 0 || root.bold ? 1 : 0.5
                            border.width: root.bold && width >= 4 ? 1 : 0
                            border.color: root.line
                        }
                    }
                }
                Repeater {
                    model: clock.kind === "analog" ? 3 : 0
                    Item {
                        id: hand
                        required property int index
                        readonly property real wide: [0.34, 0.22, clock.secs ? 0.08 : 0][index]
                        readonly property real reach: [0.5, 0.74, 0.82][index]
                        anchors.fill: parent
                        rotation: index === 0 ? (clock.h % 12 + clock.m / 60) * 30 : index === 1 ? (clock.m + (clock.secs ? clock.sec / 60 : 0)) * 6 : clock.sec * 6
                        Behavior on rotation { RotationAnimation { direction: RotationAnimation.Clockwise; duration: Motion.span(420); easing.type: Easing.OutBack } }
                        Rectangle {
                            visible: hand.wide > 0
                            x: (parent.width - width) / 2
                            y: parent.height / 2 - height + (hand.index === 2 ? clock.unit * 0.9 : width / 2)
                            width: Math.max(1, clock.unit * hand.wide)
                            height: clock.face / 2 * hand.reach + (hand.index === 2 ? clock.unit * 0.9 : 0)
                            radius: width / 2
                            color: hand.index === 2 ? root.accent : root.ink
                            border.width: root.bold && width >= 4 ? 1 : 0
                            border.color: root.line
                        }
                    }
                }
                Rectangle { anchors.centerIn: parent; width: clock.unit * 0.6; height: width; radius: width / 2; color: root.accent; border.width: Math.max(1, clock.unit * 0.12); border.color: root.ink }
            }
        }
    }

    Component {
        id: dateC

        Label {
            readonly property real unit: parent.unit * Math.max(0.2, root.s("desktop_DateScale"))
            text: root.place.toString(root.now, root.dates[root.s("desktop_DateStyle")] ?? root.dates.D)
            font.pixelSize: unit * 1.25
        }
    }

    Component {
        id: weatherC

        Row {
            id: wx
            readonly property real unit: parent.unit * Math.max(0.2, root.s("desktop_WeatherScale"))
            readonly property bool live: Sky.online && !!Sky.now
            visible: live
            spacing: unit * 0.5
            Component.onCompleted: Sky.refresh(false)
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                source: (root.arts[Sky.kind] ?? root.arts.clear)[Sky.night ? 1 : 0]
                family: root.iconFont
                size: wx.unit * 1.5
                color: root.ink
                rim: root.line
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: !wx.live ? "" : (root.s("desktop_WeatherUnit") === "C" ? Sky.now.temp_C : Sky.now.temp_F) + "°  " + root.word(root.kinds[Sky.kind] ?? "Clear")
                font.pixelSize: wx.unit * 1.15
            }
        }
    }

    Component {
        id: mediaC

        Row {
            id: tune
            readonly property real unit: parent.unit * Math.max(0.2, root.s("desktop_MediaScale"))
            readonly property string line: !root.player ? "" : String(root.player.trackTitle ?? "").trim() + (root.player.trackArtist ? " • " + root.player.trackArtist : "")
            visible: line !== ""
            spacing: unit * 0.5
            Disc {
                visible: root.s("desktop_MediaDisc")
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(tune.unit * 1.8)
                height: width
                art: String(root.player?.trackArtUrl ?? "")
                spinning: visible && tune.visible
                spinTime: Number(root.cfg?.media_SpinTime ?? 9000) || 9000
                plate: root.col(String(root.cfg?.media_DiscColor ?? "#0b0b0b"))
                ink: root.ink
                hole: root.ink
                sign: root.glyph("f001")
                signFont: root.iconFont
                grooves: 2
            }
            Icon {
                visible: !root.s("desktop_MediaDisc")
                anchors.verticalCenter: parent.verticalCenter
                source: root.glyph("f001")
                family: root.iconFont
                size: tune.unit
                grow: 1
                color: root.ink
            }
            Fade {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, tune.unit * Math.max(4, root.s("desktop_MediaWidth")))
                elide: Text.ElideRight
                want: tune.line
                color: root.ink
                font.family: root.font
                font.pixelSize: tune.unit * 1.05
            }
        }
    }

    Component {
        id: greetC

        Label {
            readonly property real unit: parent.unit * Math.max(0.2, root.s("desktop_GreetingScale"))
            readonly property int h: root.now.getHours()
            text: root.word(h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + ", " + String(Quickshell.env("USER") ?? "")
            font.pixelSize: unit * 1.3
            opacity: 0.85
        }
    }

    Component {
        id: batteryC

        Row {
            id: cell
            readonly property real unit: parent.unit * Math.max(0.2, root.s("desktop_BatteryScale"))
            visible: root.charge > 0
            spacing: unit * 0.5
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: cell.unit * 3.2
                height: cell.unit * 0.5
                radius: height / 2
                color: Qt.alpha(root.ink, 0.2)
                border.width: root.bold ? 1 : 0
                border.color: root.line
                Rectangle { width: parent.width * Math.max(0, Math.min(1, root.charge)); height: parent.height; radius: height / 2; color: root.accent; Behavior on width { Glide {} } }
            }
            Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(root.charge * 100) + "%"; font.pixelSize: cell.unit * 1.05 }
        }
    }

    Variants {
        model: root.s("desktop_Show") ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            readonly property real unit: Math.min(width, height) * 0.02 * Math.max(0.2, root.s("desktop_Scale"))
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "dolphin-desktop"
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}

            Binding { target: Reveal; property: "desk"; value: Qt.rect(stack.x, stack.y, stack.width, stack.height) }

            Column {
                id: stack
                x: Math.round(Math.max(0, Math.min(win.width - width, win.width * root.s("desktop_X") - width / 2)))
                y: Math.round(Math.max(0, Math.min(win.height - height, win.height * root.s("desktop_Y") - height / 2)))
                spacing: win.unit * Math.max(0, root.s("desktop_Spacing"))
                opacity: Math.max(0, Math.min(1, root.s("desktop_Opacity"))) * Reveal.glass
                Behavior on x { Glide {} }
                Behavior on y { Glide {} }

                Repeater {
                    model: root.s("desktop_Order").filter(n => root.shows(n))
                    Loader {
                        required property string modelData
                        readonly property real unit: win.unit
                        anchors.horizontalCenter: parent.horizontalCenter
                        sourceComponent: root.parts[modelData] ?? null
                    }
                }
            }
        }
    }
}
