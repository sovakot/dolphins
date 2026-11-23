import QtQuick
import "../../../../Backend"

Widget {
    id: wx
    key: "weather"
    icon: symbol
    tip: Sky.online ? t(kindName) : t("No internet")
    len: along(row)

    readonly property bool metric: s("Unit") === "C"
    readonly property var chosen: s("Art") ?? ({})
    readonly property var arts: ({
        clearDay: "sun", clearNight: "moon", cloudyDay: "cloudSun", cloudyNight: "cloudMoon",
        rainDay: "rainSun", rainNight: "rainMoon", snowDay: "snowSun", snowNight: "snowMoon",
        thunderDay: "boltSun", thunderNight: "boltMoon"
    })
    readonly property var names: ({ clear: "Clear", cloudy: "Cloudy", rain: "Rain", snow: "Snow", thunder: "Thunderstorm" })
    readonly property string kindName: names[Sky.kind] ?? "Clear"
    readonly property string symbol: Sky.online ? pick(Sky.kind, Sky.night) : sign(s("OfflineArt")) || "cloudOff"
    readonly property string temp: Sky.online && Sky.now ? deg(Sky.now.temp_C, Sky.now.temp_F) : ""
    readonly property var facts: !Sky.now ? [] : [
        ["Feels like", deg(Sky.now.FeelsLikeC, Sky.now.FeelsLikeF)],
        ["Humidity", Sky.now.humidity + "%"],
        ["Wind", metric ? Sky.now.windspeedKmph + " km/h" : Sky.now.windspeedMiles + " mph"],
        ["Sunrise", Sky.sun ? Sky.sun.sunrise : ""],
        ["Sunset", Sky.sun ? Sky.sun.sunset : ""]
    ]

    function deg(c, f) { return (metric ? c : f) + "°" }
    function pick(kind, night) {
        const k = kind + (night ? "Night" : "Day")
        return sign(chosen[k.charAt(0).toUpperCase() + k.slice(1)]) || arts[k] || "cloud"
    }
    function dayName(day, index) {
        if (index === 0) return t("Today")
        const p = String(day.date).split("-")
        return bar.locale.dayName(weekday(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2])), Locale.LongFormat)
    }

    Grid {
        id: row
        anchors.centerIn: parent
        columns: wx.vert ? 1 : 2
        spacing: wx.unit * (wx.vert ? 0.04 : 0.25)
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Icon {
            source: wx.symbol
            family: wx.iconFont
            size: wx.unit * 0.5
            color: wx.ink
        }
        Text {
            visible: wx.temp !== ""
            text: wx.temp
            font.family: wx.textFont
            font.weight: Font.Normal
            font.pixelSize: wx.unit * (wx.vert ? 0.4 : 0.5)
            color: wx.ink
        }
    }

    page: Component {
        Parts.Sheet {
            id: page
            c: parent.c
            unit: parent.unit
            shown: parent.shown
            open: parent.open
            title: Sky.online && Sky.place ? Sky.place + (Sky.country ? ", " + Sky.country : "") : "Weather"
            onActiveChanged: if (active) Sky.refresh(false)

            Row {
                visible: !Sky.online
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: page.unit * 0.3
                opacity: 0.6

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    source: wx.symbol
                    family: page.c.font
                    size: page.unit * 0.5
                    color: page.c.text
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: wx.t("No internet")
                    color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                }
            }

            Row {
                visible: Sky.online
                spacing: page.unit * 0.5

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    source: wx.symbol
                    family: page.c.font
                    size: page.unit * 1.3
                    color: page.c.active
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: wx.temp; color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * 0.8 }
                    Text { text: wx.t(wx.kindName); opacity: 0.6; color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize }
                }
            }

            Repeater {
                model: Sky.online ? wx.facts : []
                Parts.Info { required property var modelData; key: modelData[0]; value: modelData[1]; c: page.c; unit: page.unit }
            }

            Rectangle { visible: Sky.online; width: parent.width; height: 1; color: page.c.inactive }

            Repeater {
                model: Sky.online ? Sky.days : []
                Item {
                    id: day
                    required property var modelData
                    required property int index
                    readonly property var noon: modelData.hourly && modelData.hourly[4] ? modelData.hourly[4] : null
                    width: parent.width
                    height: page.unit * page.c.rowH

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: wx.dayName(day.modelData, day.index)
                        color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                    }
                    Icon {
                        x: parent.width * 0.6 - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        source: wx.pick(Sky.kindOf(day.noon ? parseInt(day.noon.weatherCode) : 113), false)
                        family: page.c.font
                        size: page.unit * 0.5
                        color: page.c.active
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: wx.deg(day.modelData.maxtempC, day.modelData.maxtempF) + " / " + wx.deg(day.modelData.mintempC, day.modelData.mintempF)
                        color: page.c.text; font.family: page.c.font2; font.pixelSize: page.unit * page.c.listSize
                    }
                }
            }
        }
    }
}
