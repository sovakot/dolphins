import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property var base: ({
        greeter_Session: "start-hyprland >/dev/null 2>&1", greeter_User: "",
        greeter_Avatar: "~/Dolphin/Data/Static/Images/Lockscreen/avatar.png",
        greeter_AvatarHeight: 0.55, greeter_AvatarScale: 1.2, greeter_UserHeight: 0.6,
        greeter_PasswordHeight: 0.65, greeter_PasswordScale: 1,
        greeter_PillColor: "Background", greeter_IconColor: "Extra", greeter_TextColor: "Text",
        greeter_BorderWidth: 2, greeter_BorderColor: "Extra", greeter_FocusColor: "Active", greeter_ErrorColor: "#e06c75",
        greeter_UserIcon: "f007", greeter_LockIcon: "f023", greeter_ShowIcon: "f06e", greeter_HideIcon: "f070",
        greeter_Blur: true, greeter_DimColor: "Background", greeter_Dim: 0.3,
        greeter_TypeTime: 250, greeter_TypeEasing: "OutExpo",
        greeter_CropSize: 0.6, greeter_CropColor: "#000000", greeter_CropDim: 0, greeter_CropHint: "", greeter_CropFadeTime: 150,
        greeter_ZoomStep: 1.15, greeter_ZoomMax: 8, greeter_TouchpadSpeed: 1,
        greeter_MoveStep: 0.05, greeter_MoveFine: 0.2, greeter_MoveTime: 250, greeter_MoveEasing: "OutExpo"
    })

    readonly property string dolphin: String(Quickshell.shellDir).replace(/\/+$/, "").replace(/(\/[^\/]+){2}$/, "")
    readonly property string home: dolphin.replace(/\/[^\/]+$/, "")
    property var cfg: ({})

    function plain(v) { return v !== null && typeof v === "object" && !Array.isArray(v) }
    function parse(t) {
        try { const v = JSON.parse(t); return plain(v) ? v : null } catch (e) { return null }
    }
    function obj(t) { return parse(t) ?? parse(String(t).replace(/,(\s*[}\]])/g, "$1")) }
    function load() { cfg = obj(conf.text()) ?? obj(back.text()) ?? ({}) }
    function s(k) {
        const v = cfg?.[k], d = base[k]
        return typeof v === typeof d ? v : d
    }
    function title(t) { return String(t).charAt(0).toUpperCase() + String(t).slice(1) }
    function col(c) {
        const all = cfg?.Theme, pick = cfg?.dolphin_ThemeBackground === true ? "Wallpaper" : cfg?.dolphin_Theme ?? "", set = all?.[pick] ?? all?.[title(pick)]
        return set?.[c] ?? set?.[title(c)] ?? (String(c).startsWith("#") ? c : "#000000")
    }
    function glyph(hex) { const n = parseInt(hex ?? "", 16); return n ? String.fromCodePoint(n) : "" }
    function abs(p) { return p.startsWith("/") ? p : home + "/" + p.replace(/^~?\/+/, "") }
    function curve(k) { return Easing[s(k)] ?? Easing.OutExpo }

    Component.onCompleted: { load(); (name.text ? pass : name).forceActiveFocus() }

    FileView {
        id: conf
        path: root.dolphin + "/Data/Dynamic/config.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onLoaded: root.load()
    }

    FileView {
        id: back
        path: root.dolphin + "/Data/Static/backup.json"
        blockLoading: true
    }

    FileView {
        id: cropFile
        path: root.dolphin + "/Data/Dynamic/crop.json"
        atomicWrites: false
        blockLoading: true
        JsonAdapter {
            id: crop
            property real zoom: 1
            property real offsetX: 0
            property real offsetY: 0
        }
    }

    readonly property string font: cfg?.dolphin_TextFont ?? "Maple Mono NF"
    readonly property string iconFont: cfg?.dolphin_IconFont ?? "Maple Mono NF"
    readonly property var cypher: Array.from(typeof cfg?.dolphin_Cypher === "string" && cfg.dolphin_Cypher !== "" ? cfg.dolphin_Cypher : "•")
    readonly property string picture: typeof cfg?.dolphin_Lockscreen === "string" ? cfg.dolphin_Lockscreen : ""
    readonly property string image: picture !== "" ? "file://" + abs(picture) : ""
    readonly property string avatar: "file://" + abs(s("greeter_Avatar"))
    readonly property string ext: image.split(".").pop().toLowerCase()
    readonly property string kind: !image ? "" : ["mp4", "mkv", "webm", "mov", "avi", "m4v"].includes(ext) ? "video" : ["gif", "webp"].includes(ext) ? "anim" : "image"
    readonly property real iw: Math.max(1, av.implicitWidth)
    readonly property real ih: Math.max(1, av.implicitHeight)
    readonly property real rw: iw / Math.min(iw, ih)
    readonly property real rh: ih / Math.min(iw, ih)

    property bool reveal: false
    property bool busy: false
    property bool wrong: false
    property real shakeX: 0
    property bool viewing: false
    property bool animate: true
    property real zoom: 1
    property real fx: 0
    property real fy: 0

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "shakeX"; to: -10; duration: 50 }
        NumberAnimation { target: root; property: "shakeX"; to: 10; duration: 70 }
        NumberAnimation { target: root; property: "shakeX"; to: -6; duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 50 }
    }

    function edge(focused) {
        return col(s(wrong ? "greeter_ErrorColor" : focused ? "greeter_FocusColor" : "greeter_BorderColor"))
    }

    function fail() {
        busy = false
        chars.clear()
        pass.text = ""
        wrong = true
        shakeAnim.restart()
        pass.forceActiveFocus()
    }

    function submit() {
        if (busy) return
        if (!name.text) { name.forceActiveFocus(); return }
        if (!pass.text.length) { pass.forceActiveFocus(); return }
        busy = true
        Greetd.createSession(name.text)
    }

    function place(x, y, z, anim) {
        animate = anim
        const mx = Math.max(0, (rw * z - 1) / 2)
        const my = Math.max(0, (rh * z - 1) / 2)
        zoom = z
        fx = Math.max(-mx, Math.min(mx, x))
        fy = Math.max(-my, Math.min(my, y))
    }

    function move(dx, dy, anim) { place(fx + dx, fy + dy, zoom, anim) }

    function zoomAt(z, px, py, anim) {
        z = Math.max(1, Math.min(s("greeter_ZoomMax"), z))
        const r = z / zoom
        place(px - (px - fx) * r, py - (py - fy) * r, z, anim)
    }

    function openViewer() {
        place(crop.offsetX, crop.offsetY, Math.max(1, crop.zoom), false)
        viewing = true
        Qt.callLater(() => viewer.forceActiveFocus())
    }

    function closeViewer(save) {
        if (save) {
            crop.zoom = zoom
            crop.offsetX = fx
            crop.offsetY = fy
            cropFile.writeAdapter()
        }
        viewing = false
        Qt.callLater(() => (name.text ? pass : name).forceActiveFocus())
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(pass.text)
        }
        function onReadyToLaunch() { Greetd.launch([root.s("greeter_Session")]) }
        function onAuthFailure(message) { root.fail() }
        function onError(error) { root.fail() }
    }

    FloatingWindow {
        id: win
        color: "black"
        readonly property real u: height
        readonly property real pw: u * 0.22 * root.s("greeter_PasswordScale")
        readonly property real ph: u * 0.045 * root.s("greeter_PasswordScale")

        Item {
            id: wallItem
            anchors.fill: parent
            layer.enabled: root.s("greeter_Blur")
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: 1
            }

            Loader {
                anchors.fill: parent
                sourceComponent: root.kind === "video" ? vidC : root.kind === "anim" ? animC : root.kind === "image" ? imgC : null
            }

            Component {
                id: imgC
                Image {
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: win.width
                    sourceSize.height: win.height
                }
            }

            Component {
                id: animC
                AnimatedImage {
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                }
            }

            Component {
                id: vidC
                Video {
                    source: root.image
                    fillMode: VideoOutput.PreserveAspectCrop
                    loops: MediaPlayer.Infinite
                    muted: true
                    autoPlay: true
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: root.col(root.s("greeter_DimColor"))
            opacity: root.s("greeter_Dim")
        }

        Item {
            width: win.u * 0.1 * root.s("greeter_AvatarScale")
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.u * root.s("greeter_AvatarHeight") - height

            ClippingRectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                Image {
                    id: av
                    source: root.avatar
                    mipmap: true
                    width: root.rw * parent.width
                    height: root.rh * parent.height
                    x: (parent.width - width) / 2 + crop.offsetX * parent.width
                    y: (parent.height - height) / 2 + crop.offsetY * parent.height
                    scale: crop.zoom
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: root.s("greeter_BorderWidth")
                border.color: root.col(root.s("greeter_BorderColor"))
            }

            MouseArea { anchors.fill: parent; onClicked: root.openViewer() }
        }

        Rectangle {
            id: userPill
            anchors.horizontalCenter: parent.horizontalCenter
            width: win.pw
            height: win.ph
            y: win.u * root.s("greeter_UserHeight") - height / 2
            radius: height / 2
            color: root.col(root.s("greeter_PillColor"))
            border.width: root.s("greeter_BorderWidth")
            border.color: root.edge(name.activeFocus)
            Behavior on border.color { ColorAnimation { duration: 150 } }
            transform: Translate { x: root.shakeX }

            Text {
                id: uicon
                x: userPill.height * 0.35
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph(root.s("greeter_UserIcon"))
                font.family: root.iconFont
                font.pixelSize: userPill.height * 0.4
                color: root.col(root.s("greeter_IconColor"))
            }

            TextInput {
                id: name
                x: uicon.x + uicon.width + userPill.height * 0.25
                width: userPill.width - x * 2
                height: userPill.height
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                clip: true
                color: root.col(root.s("greeter_TextColor"))
                font.family: root.font
                font.pixelSize: userPill.height * 0.4
                cursorDelegate: Item {}
                readOnly: root.busy
                enabled: !root.viewing
                text: root.s("greeter_User")
                Component.onCompleted: (text ? pass : name).forceActiveFocus()
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Tab || e.key === Qt.Key_Down) {
                        pass.forceActiveFocus()
                        e.accepted = true
                    }
                }
                onTextChanged: root.wrong = false
                onAccepted: pass.forceActiveFocus()
            }
        }

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: win.pw
            height: win.ph
            y: win.u * root.s("greeter_PasswordHeight") - height / 2
            radius: height / 2
            color: root.col(root.s("greeter_PillColor"))
            border.width: root.s("greeter_BorderWidth")
            border.color: root.edge(pass.activeFocus)
            Behavior on border.color { ColorAnimation { duration: 150 } }
            transform: Translate { x: root.shakeX }

            Text {
                id: icon
                x: pill.height * 0.35
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph(root.s("greeter_LockIcon"))
                font.family: root.iconFont
                font.pixelSize: pill.height * 0.4
                color: root.col(root.s("greeter_IconColor"))
            }

            Text {
                id: eye
                anchors.right: parent.right
                anchors.rightMargin: pill.height * 0.35
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph(root.s(root.reveal ? "greeter_HideIcon" : "greeter_ShowIcon"))
                font.family: root.iconFont
                font.pixelSize: pill.height * 0.4
                color: root.col(root.s("greeter_TextColor"))
            }

            Item {
                id: area
                x: icon.x + icon.width + pill.height * 0.25
                width: eye.x - x - pill.height * 0.25
                height: pill.height
                clip: true

                Row {
                    x: Math.min((area.width - width) / 2, area.width - width)
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: ListModel { id: chars }
                        Text {
                            id: ch
                            required property int index
                            required property string c
                            required property string r
                            required property bool gone
                            property real grow: 0
                            text: root.reveal ? r : c
                            width: (implicitWidth + 2) * grow
                            scale: grow
                            horizontalAlignment: Text.AlignHCenter
                            color: root.col(root.s("greeter_TextColor"))
                            font.family: root.font
                            font.pixelSize: pill.height * 0.4
                            NumberAnimation { id: growIn; target: ch; property: "grow"; to: 1; duration: root.s("greeter_TypeTime"); easing.type: root.curve("greeter_TypeEasing") }
                            NumberAnimation { id: shrink; target: ch; property: "grow"; to: 0; duration: root.s("greeter_TypeTime"); easing.type: root.curve("greeter_TypeEasing"); onFinished: chars.remove(ch.index) }
                            Component.onCompleted: growIn.start()
                            onGoneChanged: if (gone) { growIn.stop(); shrink.start() }
                        }
                    }
                }
            }

            TextInput {
                id: pass
                anchors.fill: parent
                color: "transparent"
                cursorDelegate: Item {}
                echoMode: TextInput.Password
                readOnly: root.busy
                enabled: !root.viewing
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab || e.key === Qt.Key_Up) {
                        name.forceActiveFocus()
                        e.accepted = true
                    } else if (e.key === Qt.Key_Escape && !root.busy) {
                        text = ""
                        root.reveal = false
                        e.accepted = true
                    }
                }
                onTextChanged: {
                    root.wrong = false
                    let alive = 0
                    for (let i = 0; i < chars.count; i++) if (!chars.get(i).gone) alive++
                    for (; alive < length; alive++) chars.append({ c: root.cypher[alive % root.cypher.length], r: text.charAt(alive), gone: false })
                    for (let i = chars.count - 1; i >= 0 && alive > length; i--) {
                        if (!chars.get(i).gone) { chars.setProperty(i, "gone", true); alive-- }
                    }
                }
                onAccepted: root.submit()
            }

            MouseArea {
                anchors.fill: eye
                anchors.margins: -pill.height * 0.15
                onClicked: root.reveal = !root.reveal
            }
        }

        Rectangle {
            id: viewer
            anchors.fill: parent
            color: root.col(root.s("greeter_CropColor"))
            opacity: root.viewing ? 1 : 0
            visible: opacity > 0
            enabled: root.viewing
            focus: root.viewing
            clip: true
            Behavior on opacity { NumberAnimation { duration: root.s("greeter_CropFadeTime"); easing.type: Easing.OutCubic } }

            readonly property real frame: height * root.s("greeter_CropSize")
            property real vz: root.zoom
            property real vx: root.fx
            property real vy: root.fy
            Behavior on vz { enabled: root.animate; NumberAnimation { duration: root.s("greeter_MoveTime"); easing.type: root.curve("greeter_MoveEasing") } }
            Behavior on vx { enabled: root.animate; NumberAnimation { duration: root.s("greeter_MoveTime"); easing.type: root.curve("greeter_MoveEasing") } }
            Behavior on vy { enabled: root.animate; NumberAnimation { duration: root.s("greeter_MoveTime"); easing.type: root.curve("greeter_MoveEasing") } }

            Image {
                source: root.avatar
                mipmap: true
                width: root.rw * viewer.frame
                height: root.rh * viewer.frame
                x: (parent.width - width) / 2 + viewer.vx * viewer.frame
                y: (parent.height - height) / 2 + viewer.vy * viewer.frame
                scale: viewer.vz
            }

            Rectangle {
                readonly property real reach: Math.max(viewer.width, viewer.height)
                anchors.centerIn: parent
                width: viewer.frame + reach * 2
                height: width
                radius: width / 2
                color: "transparent"
                border.width: reach
                border.color: viewer.color
                opacity: root.s("greeter_CropDim")
                visible: opacity > 0
            }

            Rectangle {
                anchors.centerIn: parent
                width: viewer.frame
                height: width
                radius: width / 2
                color: "transparent"
                border.width: root.s("greeter_BorderWidth")
                border.color: root.col(root.s("greeter_BorderColor"))
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: (viewer.height + viewer.frame) / 2 + (viewer.height - viewer.frame) / 4 - height / 2
                text: root.s("greeter_CropHint")
                visible: text !== ""
                font.family: root.font
                font.pixelSize: win.u * 0.016
                color: root.col(root.s("greeter_TextColor"))
            }

            MouseArea {
                anchors.fill: parent
                property point last
                property bool dragged: false
                onPressed: (m) => { last = Qt.point(m.x, m.y); dragged = false }
                onPositionChanged: (m) => {
                    const dx = m.x - last.x, dy = m.y - last.y
                    if (!dragged && Math.abs(dx) + Math.abs(dy) < 4) return
                    dragged = true
                    last = Qt.point(m.x, m.y)
                    root.move(dx / viewer.frame, dy / viewer.frame, false)
                }
                onClicked: if (!dragged) root.closeViewer(true)
                onWheel: (w) => {
                    const pad = w.pixelDelta.y !== 0
                    const dir = w.inverted ? -1 : 1
                    const d = dir * (pad ? w.pixelDelta.y * root.s("greeter_TouchpadSpeed") / 25 : w.angleDelta.y / 120)
                    root.zoomAt(root.zoom * Math.pow(root.s("greeter_ZoomStep"), d), (w.x - width / 2) / viewer.frame, (w.y - height / 2) / viewer.frame, !pad)
                }
            }

            PinchHandler {
                target: null
                onScaleChanged: (delta) => {
                    if (delta > 0) root.zoomAt(root.zoom * delta, (centroid.position.x - viewer.width / 2) / viewer.frame, (centroid.position.y - viewer.height / 2) / viewer.frame, false)
                }
            }

            Keys.onPressed: (e) => {
                const fine = e.modifiers & Qt.ShiftModifier
                const m = root.s("greeter_MoveStep") * (fine ? root.s("greeter_MoveFine") : 1)
                const z = fine ? Math.pow(root.s("greeter_ZoomStep"), root.s("greeter_MoveFine")) : root.s("greeter_ZoomStep")
                if (e.key === Qt.Key_Left) root.move(-m, 0, true)
                else if (e.key === Qt.Key_Right) root.move(m, 0, true)
                else if (e.key === Qt.Key_Up) root.move(0, -m, true)
                else if (e.key === Qt.Key_Down) root.move(0, m, true)
                else if (e.key === Qt.Key_I || e.key === Qt.Key_Plus || e.key === Qt.Key_Equal) root.zoomAt(root.zoom * z, 0, 0, true)
                else if (e.key === Qt.Key_O || e.key === Qt.Key_Minus || e.key === Qt.Key_Underscore) root.zoomAt(root.zoom / z, 0, 0, true)
                else if (e.key === Qt.Key_R || e.key === Qt.Key_0) root.place(0, 0, 1, true)
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.closeViewer(true)
                else if (e.key === Qt.Key_Escape) root.closeViewer(false)
                else return
                e.accepted = true
            }
        }
    }
}
