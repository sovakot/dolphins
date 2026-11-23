import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../../../Backend"

FloatingWindow {
    id: root

    signal gone()

    readonly property color textMain: kit.col(kit.s("movies_TextColor"))
    readonly property color textSoft: Qt.alpha(textMain, 0.65)
    readonly property color textDim: Qt.alpha(textMain, 0.38)
    readonly property color back: kit.col(kit.s("movies_Color"))
    readonly property color glass: Qt.alpha(kit.col(kit.s("movies_CardColor")), 0.85)
    readonly property color line: kit.col(kit.s("movies_BorderColor"))
    readonly property color hover: kit.col(kit.s("movies_HoverColor"))
    readonly property color lit: kit.col(kit.s("movies_ActiveColor"))
    readonly property color onLit: kit.col(kit.s("movies_ActiveTextColor"))
    readonly property real u: Math.max(0.55, Math.min(1.5, Math.min(width / 1280, height / 760)))
    readonly property real pad: 80 * u
    readonly property real round: kit.s("movies_Radius") * u
    readonly property int quick: kit.s("movies_FadeTime")

    readonly property var tabs: [
        { key: "home", label: "Home", icon: 0xf015 },
        { key: "movies", label: "Movies", icon: 0xf008 },
        { key: "anime", label: "Anime", icon: 0xf0d0 },
        { key: "shows", label: "Shows", icon: 0xf26c },
        { key: "list", label: "My list", icon: 0xf02e }
    ]
    readonly property var emptyText: ({ movies: "No movies yet", anime: "No anime yet", shows: "No shows yet", list: "Your list is empty" })
    readonly property var gridTabs: ["movies", "anime", "shows", "list"]

    property string tab: "home"
    property bool searching: false
    property int heroIndex: 0

    readonly property var all: lib.movies.concat(lib.anime, lib.shows)
    readonly property var featured: all.slice(0, 7)
    readonly property var hero: featured[heroIndex] ?? null
    readonly property bool showGrid: searching || gridTabs.includes(tab)
    readonly property var view: searching ? (search.text ? all.filter(i => (i.title ?? "").toLowerCase().includes(search.text.toLowerCase())) : []) : items(tab)
    readonly property string logoPath: kit.s("movies_Logo")
    readonly property string logoGlyph: kit.glyph((kit.cfg?.sidebar_Widgets ?? []).find(e => e?.Key === "movies")?.Icon ?? "f008") || kit.glyph("f008")

    function w(k) { return kit.word(k) }
    function mediaUrl(p) { return p ? "file://" + p.replace(/^~/, Quickshell.env("HOME")) : "" }
    function mediaKind(p) {
        const e = (p ?? "").split(".").pop().toLowerCase()
        return ["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(e) ? "video" : ["gif", "webp"].includes(e) ? "anim" : "image"
    }
    function items(key) { return key === "list" ? all.filter(i => lib.myList.includes(i.id)) : (lib[key] ?? []) }
    function inList(id) { return lib.myList.includes(id) }
    function toggleList(id) {
        lib.myList = inList(id) ? lib.myList.filter(x => x !== id) : lib.myList.concat([id])
        libFile.writeAdapter()
    }

    title: "dolphin-movies"
    implicitWidth: Math.round((Quickshell.screens[0]?.width ?? 1440) * kit.s("movies_Width"))
    implicitHeight: Math.round((Quickshell.screens[0]?.height ?? 900) * kit.s("movies_Height"))
    color: back
    onVisibleChanged: if (!visible) gone()

    Kit {
        id: kit
        base: ({
            movies_Width: 0.75, movies_Height: 0.75, movies_X: 0.125, movies_Y: 0.125,
            movies_Radius: 18, movies_FadeTime: 200, movies_HeroTime: 8000, movies_Logo: "",
            movies_Color: "Background", movies_CardColor: "Accent", movies_BorderColor: "Accent2", movies_HoverColor: "Inactive",
            movies_TextColor: "Text", movies_ActiveColor: "Active", movies_ActiveTextColor: "Background"
        })
    }

    Component { id: imgC; Image { anchors.fill: parent; source: parent.url; fillMode: Image.PreserveAspectCrop; asynchronous: true; onStatusChanged: if (status === Image.Error) parent.failed = true } }
    Component { id: animC; AnimatedImage { anchors.fill: parent; source: parent.url; fillMode: Image.PreserveAspectCrop; onStatusChanged: if (status === Image.Error) parent.failed = true } }
    Component { id: vidC; Video { anchors.fill: parent; source: parent.url; fillMode: VideoOutput.PreserveAspectCrop; loops: MediaPlayer.Infinite; muted: true; autoPlay: true; onErrorOccurred: parent.failed = true } }

    FileView {
        id: libFile
        path: Qt.resolvedUrl("../../../../Data/Dynamic/movies.json")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: lib
            property var movies: []
            property var anime: []
            property var shows: []
            property var myList: []
        }
    }

    Timer {
        interval: Math.max(1000, kit.s("movies_HeroTime"))
        repeat: true
        running: root.tab === "home" && root.featured.length > 1
        onTriggered: root.heroIndex = (root.heroIndex + 1) % root.featured.length
    }

    Item {
        id: home
        anchors.fill: parent
        opacity: root.tab === "home" && !root.searching ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.span(root.quick); easing.type: Easing.OutCubic } }

        Item {
            id: heroArea
            width: parent.width
            height: parent.height * 0.82

            Loader {
                property string url: root.mediaUrl(root.hero?.backdrop ?? "")
                property bool failed: false
                onUrlChanged: failed = false
                anchors.fill: parent
                active: url !== "" && !failed
                sourceComponent: root.mediaKind(root.hero?.backdrop) === "video" ? vidC : root.mediaKind(root.hero?.backdrop) === "anim" ? animC : imgC
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.alpha(root.back, 0.95) }
                    GradientStop { position: 0.55; color: Qt.alpha(root.back, 0.5) }
                    GradientStop { position: 1.0; color: Qt.alpha(root.back, 0.1) }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.6; color: Qt.alpha(root.back, 0) }
                    GradientStop { position: 1.0; color: root.back }
                }
            }

            Column {
                x: root.pad
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 30 * root.u
                width: Math.min(parent.width - root.pad * 2, Math.max(parent.width * 0.5, 420 * root.u))
                spacing: 22 * root.u

                Text {
                    width: parent.width
                    text: root.hero ? root.hero.title : kit.title(root.w("movies"))
                    wrapMode: Text.Wrap
                    font.family: kit.font
                    font.pixelSize: 64 * root.u
                    font.bold: true
                    font.letterSpacing: 2 * root.u
                    color: root.textMain
                }

                Row {
                    visible: !!root.hero
                    spacing: 14 * root.u
                    Repeater {
                        model: root.hero ? [[0xf005, (root.hero.rating ?? "—") + "/10"], [0xf073, root.hero.year ?? "—"], [0xf02b, root.hero.genre ?? "—"]] : []
                        Row {
                            required property var modelData
                            required property int index
                            spacing: 8 * root.u
                            Text { visible: index > 0; text: "·"; font.pixelSize: 18 * root.u; color: root.textDim; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: String.fromCodePoint(modelData[0]); font.family: kit.iconFont; font.pixelSize: 16 * root.u; color: root.textMain; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData[1]; font.family: kit.font; font.pixelSize: 18 * root.u; color: root.textMain; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.hero ? (root.hero.overview ?? "") : root.w("Nothing here yet. Add titles to movies.json and they will show up here.")
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    lineHeight: 1.3
                    font.family: kit.font
                    font.pixelSize: 18 * root.u
                    color: root.hero ? root.textMain : root.textSoft
                }

                Row {
                    visible: !!root.hero
                    spacing: 14 * root.u

                    Rectangle {
                        width: playRow.width + 64 * root.u
                        height: 60 * root.u
                        radius: height / 2
                        color: root.lit
                        opacity: playMa.containsMouse ? 0.85 : 1
                        scale: playMa.pressed ? 0.96 : 1
                        Behavior on opacity { NumberAnimation { duration: Motion.span(120) } }
                        Behavior on scale { NumberAnimation { duration: Motion.span(120); easing.type: Easing.OutCubic } }
                        Row {
                            id: playRow
                            anchors.centerIn: parent
                            spacing: 10 * root.u
                            Text { text: ""; font.family: kit.iconFont; font.pixelSize: 18 * root.u; color: root.onLit; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: root.w("Play"); font.family: kit.font; font.pixelSize: 20 * root.u; font.bold: true; color: root.onLit; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true }
                    }

                    Rectangle {
                        width: 150 * root.u
                        height: 60 * root.u
                        radius: height / 2
                        color: root.glass
                        border.width: 1
                        border.color: root.line
                        Row {
                            anchors.centerIn: parent
                            spacing: 22 * root.u
                            Text {
                                text: root.hero && root.inList(root.hero.id) ? "" : ""
                                font.family: kit.iconFont
                                font.pixelSize: 20 * root.u
                                color: root.textMain
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -12; onClicked: if (root.hero) root.toggleList(root.hero.id) }
                            }
                            Rectangle { width: 1; height: 26 * root.u; color: root.line; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: ""; font.family: kit.iconFont; font.pixelSize: 22 * root.u; color: root.textMain; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 90 * root.u
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 120 * root.u
                spacing: 8 * root.u
                visible: root.featured.length > 1
                Repeater {
                    model: root.featured.length
                    Rectangle {
                        required property int index
                        width: (index === root.heroIndex ? 40 : 10) * root.u
                        height: 10 * root.u
                        radius: height / 2
                        color: index === root.heroIndex ? root.lit : root.textDim
                        Behavior on width { NumberAnimation { duration: Motion.span(250); easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Motion.span(250) } }
                        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root.heroIndex = index }
                    }
                }
            }
        }

        Column {
            x: root.pad
            y: heroArea.height - 20 * root.u
            spacing: 14 * root.u
            Text { text: root.w("Browse by platform"); font.family: kit.font; font.pixelSize: 26 * root.u; font.bold: true; color: root.textMain }
            Text { text: root.w("No platforms yet"); font.family: kit.font; font.pixelSize: 15 * root.u; color: root.textDim }
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 130 * root.u
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        opacity: root.showGrid ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.span(root.quick); easing.type: Easing.OutCubic } }

        Text {
            id: header
            text: root.searching ? root.w("Search results") : root.w(root.tabs.find(t => t.key === root.tab)?.label ?? "")
            font.family: kit.font
            font.pixelSize: 30 * root.u
            font.bold: true
            color: root.textMain
        }

        GridView {
            id: grid
            readonly property int columns: Math.max(1, Math.floor(width / (200 * root.u)))
            anchors.fill: parent
            anchors.topMargin: header.height + 24 * root.u
            clip: true
            cellWidth: width / columns
            cellHeight: cellWidth * 1.7
            boundsBehavior: Flickable.StopAtBounds
            model: root.view
            delegate: Item {
                id: card
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    id: poster
                    x: (parent.width - width) / 2
                    width: parent.width * 0.9
                    height: width * 1.5
                    radius: root.round
                    color: kit.col(kit.s("movies_CardColor"))
                    border.width: 1
                    border.color: cardMa.containsMouse ? root.lit : root.line
                    scale: cardMa.containsMouse ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: Motion.span(180); easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: Motion.span(150) } }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: kit.iconFont
                        font.pixelSize: 34 * root.u
                        color: root.textDim
                    }
                    Loader {
                        property string url: root.mediaUrl(card.modelData.poster ?? "")
                        property bool failed: false
                        anchors.fill: parent
                        active: url !== "" && !failed
                        sourceComponent: imgC
                    }
                }

                Text {
                    anchors.top: poster.bottom
                    anchors.topMargin: 10 * root.u
                    x: poster.x
                    width: poster.width
                    text: card.modelData.title ?? ""
                    elide: Text.ElideRight
                    font.family: kit.font
                    font.pixelSize: 15 * root.u
                    color: root.textMain
                }

                Text {
                    anchors.top: poster.bottom
                    anchors.topMargin: 32 * root.u
                    x: poster.x
                    text: (card.modelData.year ?? "") + (card.modelData.rating ? "  ·  " + card.modelData.rating : "")
                    font.family: kit.font
                    font.pixelSize: 13 * root.u
                    color: root.textSoft
                }

                MouseArea { id: cardMa; anchors.fill: parent; hoverEnabled: true }
            }
        }

        Scroller { view: grid }

        Column {
            anchors.centerIn: parent
            visible: root.view.length === 0
            spacing: 12 * root.u
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.searching ? "" : String.fromCodePoint(root.tabs.find(t => t.key === root.tab)?.icon ?? 0xf008)
                font.family: kit.iconFont
                font.pixelSize: 40 * root.u
                color: root.textDim
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.searching ? root.w(search.text ? "No results found" : "Type a name to search") : root.w(root.emptyText[root.tab] ?? "")
                font.family: kit.font
                font.pixelSize: 18 * root.u
                color: root.textSoft
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 130 * root.u
        anchors.leftMargin: root.pad
        opacity: root.tab === "settings" && !root.searching ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.span(root.quick); easing.type: Easing.OutCubic } }
        Column {
            spacing: 14 * root.u
            Text { text: root.w("Settings"); font.family: kit.font; font.pixelSize: 30 * root.u; font.bold: true; color: root.textMain }
            Text { text: root.w("No settings yet"); font.family: kit.font; font.pixelSize: 15 * root.u; color: root.textDim }
        }
    }

    Item {
        x: 50 * root.u
        y: 34 * root.u
        width: 56 * root.u
        height: width

        Loader {
            id: logoLoader
            property string url: root.mediaUrl(root.logoPath)
            property bool failed: false
            onUrlChanged: failed = false
            anchors.fill: parent
            active: url !== "" && !failed
            sourceComponent: root.mediaKind(root.logoPath) === "video" ? vidC : root.mediaKind(root.logoPath) === "anim" ? animC : imgC
        }

        Text {
            anchors.centerIn: parent
            visible: !logoLoader.active || logoLoader.failed
            text: root.logoGlyph
            font.family: kit.iconFont
            font.pixelSize: 40 * root.u
            color: root.textMain
        }

        MouseArea { anchors.fill: parent; onClicked: { root.tab = "home"; root.searching = false } }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 40 * root.u
        y: 32 * root.u
        width: navRow.width + 16 * root.u
        height: 60 * root.u
        radius: height / 2
        color: root.glass
        border.width: 1
        border.color: root.line
        Behavior on width { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }

        Row {
            id: navRow
            anchors.right: parent.right
            anchors.rightMargin: 8 * root.u
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 * root.u

            Repeater {
                model: root.tabs
                Rectangle {
                    id: navItem
                    required property var modelData
                    readonly property bool sel: root.tab === modelData.key && !root.searching
                    height: 46 * root.u
                    width: navLabel.implicitWidth + (sel ? 72 : 44) * root.u
                    radius: height / 2
                    color: sel ? root.lit : navMa.containsMouse ? root.hover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on width { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Motion.span(150) } }
                    Row {
                        anchors.centerIn: parent
                        spacing: 10 * root.u
                        Text {
                            visible: navItem.sel
                            text: String.fromCodePoint(navItem.modelData.icon)
                            font.family: kit.iconFont
                            font.pixelSize: 16 * root.u
                            color: root.onLit
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: navLabel
                            text: root.w(navItem.modelData.label)
                            font.family: kit.font
                            font.pixelSize: 17 * root.u
                            color: navItem.sel ? root.onLit : root.textSoft
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: Motion.span(150) } }
                        }
                    }
                    MouseArea { id: navMa; anchors.fill: parent; hoverEnabled: true; onClicked: { root.tab = navItem.modelData.key; root.searching = false } }
                }
            }

            Rectangle { width: 1; height: 26 * root.u; color: root.line; anchors.verticalCenter: parent.verticalCenter }

            Rectangle {
                height: 46 * root.u
                width: (root.searching ? 240 : 46) * root.u
                radius: height / 2
                color: root.searching || searchMa.containsMouse ? root.hover : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                Behavior on width { NumberAnimation { duration: Motion.span(200); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Motion.span(150) } }

                Text {
                    x: 14 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.family: kit.iconFont
                    font.pixelSize: 18 * root.u
                    color: root.textMain
                }
                Text {
                    x: 44 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.searching && !search.text
                    text: root.w("Search")
                    font.family: kit.font
                    font.pixelSize: 16 * root.u
                    color: root.textDim
                }
                TextInput {
                    id: search
                    x: 44 * root.u
                    width: parent.width - 58 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.searching
                    clip: true
                    font.family: kit.font
                    font.pixelSize: 16 * root.u
                    color: root.textMain
                    Keys.onEscapePressed: { text = ""; root.searching = false }
                }
                MouseArea {
                    id: searchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.searching
                    onClicked: { root.searching = true; search.forceActiveFocus() }
                }
            }

            Rectangle {
                readonly property bool sel: root.tab === "settings" && !root.searching
                height: 46 * root.u
                width: height
                radius: height / 2
                color: sel ? root.lit : setMa.containsMouse ? root.hover : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Motion.span(150) } }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: kit.iconFont
                    font.pixelSize: 18 * root.u
                    color: parent.sel ? root.onLit : root.textMain
                }
                MouseArea { id: setMa; anchors.fill: parent; hoverEnabled: true; onClicked: { root.tab = "settings"; root.searching = false } }
            }
        }
    }
}
