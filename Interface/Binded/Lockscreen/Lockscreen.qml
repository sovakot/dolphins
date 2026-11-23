import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pam
import "../../../Backend"
import "../../../Data/Dynamic"

Scope {
    id: root

    required property var cfg
    readonly property var base: ({
        lockscreen_Show: true, lockscreen_Login: true, lockscreen_Pam: "dolphin-lock",
        lockscreen_MainTextScale: 1, lockscreen_MainTextColor: "Text", lockscreen_MainTextHeight: 0.2,
        lockscreen_TextScale: 1, lockscreen_TextColor: "Text", lockscreen_TextHeight: 0.27,
        lockscreen_PasswordHeight: 0.4, lockscreen_PasswordColor: "Background", lockscreen_PasswordBorderColor: "Extra",
        lockscreen_ErrorColor: "#e06c75", lockscreen_DimColor: "Background", lockscreen_Dim: 0.3,
        lockscreen_LockIcon: "f023", lockscreen_ShowIcon: "f06e", lockscreen_HideIcon: "f070",
        lockscreen_UnlockIcon: "f09c", lockscreen_UnlockColor: "Active",
        lockscreen_UnlockBounce: 1.08, lockscreen_UnlockBounceTime: 250,
        lockscreen_FadeTime: 250, lockscreen_FadeEasing: "OutCubic", lockscreen_Blur: true,
        lockscreen_TerminalScale: 1, lockscreen_TerminalHeight: 1, lockscreen_TerminalColor: "Text",
        lockscreen_UnlockTransition: "wave", lockscreen_UnlockDuration: 1,
        lockscreen_Downloads: true, lockscreen_DownloadTime: 1000, lockscreen_DownloadStale: 5,
        lockscreen_Media: true, lockscreen_MediaScale: 1.2, lockscreen_MediaHeight: 0.35, lockscreen_Saturation: 0,
        session_Show: true, session_Color: "Inactive", session_ActiveColor: "Active", session_IconColor: "Text",
        session_ActiveIconColor: "Background", session_TextColor: "Text", session_DimColor: "Background",
        session_Dim: 0.35, session_Blur: true, session_Radius: 14, session_ActiveRadius: 100, session_Size: 0.08,
        session_IconScale: 1, session_TextScale: 1, session_Title: "Session", session_Time: 250, session_Easing: "OutCubic",
        session_Items: [
            { Icon: "f023", Label: "Lock", Command: "lock" },
            { Icon: "f08b", Label: "Log Out", Command: "hyprctl dispatch 'hl.dsp.exit()'" },
            { Icon: "f011", Label: "Shut Down", Command: "systemctl poweroff" },
            { Icon: "f01e", Label: "Reboot", Command: "systemctl reboot" }
        ]
    })

    readonly property string font: cfg?.dolphin_TextFont ?? "Maple Mono NF"
    readonly property string iconFont: cfg?.dolphin_IconFont ?? "Maple Mono NF"
    readonly property var cypher: Array.from(typeof cfg?.dolphin_Cypher === "string" && cfg.dolphin_Cypher !== "" ? cfg.dolphin_Cypher : "•")
    readonly property string wallpaper: typeof cfg?.dolphin_Background === "string" ? cfg.dolphin_Background : ""
    readonly property string picture: typeof cfg?.dolphin_Lockscreen === "string" ? cfg.dolphin_Lockscreen : ""
    readonly property string image: picture !== "" ? "file://" + abs(picture) : ""
    readonly property string ext: image.split(".").pop().toLowerCase()
    readonly property string kind: !image ? "" : ["mp4", "mkv", "webm", "mov", "avi", "m4v"].includes(ext) ? "video" : ["gif", "webp"].includes(ext) ? "anim" : "image"
    readonly property bool waveBg: wallpaper !== "" && !/\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(wallpaper)
    readonly property int dur: Math.max(0, s("lockscreen_FadeTime"))
    readonly property int ease: Easing[s("lockscreen_FadeEasing")] ?? Easing.OutCubic
    readonly property int bounce: Math.max(0, s("lockscreen_UnlockBounceTime"))
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("Downloads.sh").toString().replace(/^file:\/\//, ""))
    readonly property var items: { const v = s("session_Items"); return Array.isArray(v) ? v : base.session_Items }
    readonly property bool locked: guard.locked
    signal barred()
    signal cleared()
    readonly property bool shown: !unlocking
    property bool reveal: false
    property bool unlocking: false
    property bool granted: false
    property bool wrong: false
    property var downloads: []
    property string attempt: ""
    property bool menu: false
    property int sel: 0
    signal failed()

    function s(k) {
        const v = cfg?.[k], d = base[k]
        return typeof v === typeof d ? v : d
    }
    function title(t) { return String(t).charAt(0).toUpperCase() + String(t).slice(1) }
    function col(c) {
        const set = Config.tones
        return set?.[c] ?? set?.[title(c)] ?? (String(c).startsWith("#") ? c : "#000000")
    }
    function glyph(hex) { const n = parseInt(hex ?? "", 16); return n ? String.fromCodePoint(n) : "" }
    function abs(p) { return p.startsWith("/") ? p : Quickshell.env("HOME") + "/" + p.replace(/^~?\/+/, "") }
    function size(b) { return b >= 1e9 ? (b / 1e9).toFixed(1) + " GB" : (b / 1e6).toFixed(0) + " MB" }
    function line(d) {
        if (!d.total) return d.name + "\n[ downloading ]  " + size(d.have)
        const w = 24
        const p = Math.min(1, d.have / d.total)
        const n = Math.round(p * w)
        return d.name + "\n[" + "#".repeat(n) + "-".repeat(w - n) + "] " + Math.floor(p * 100) + "%  " + size(d.have) + " / " + size(d.total)
    }
    function parse(t) {
        downloads = t.split("\n").filter(l => l).map(l => {
            const p = l.split("|")
            return { name: p[0], have: +p[1] || 0, total: +p[2] || 0 }
        })
    }
    function prepWall() {
        if (!waveBg) return
        if (kind === "image" || kind === "anim") Quickshell.execDetached(["awww", "img", "--transition-type", "none", abs(picture)])
        else Quickshell.execDetached(["awww", "clear", "000000"])
    }
    function waveWall() {
        if (!waveBg) return
        const sat = Math.max(-1, Math.min(1, Number(cfg?.dolphin_BackgroundSaturation ?? 0) || 0))
        Quickshell.execDetached(["sh", "-c", "sleep 0.05; f=\"$0\"; case \"$3\" in 0|0.0|-0|'') ;; *) case \"$f\" in *.[gG][iI][fF]) ;; *) o=\"/tmp/dolphin-sat-$(printf %s \"$f|$3\" | md5sum | cut -c1-12).png\"; [ -s \"$o\" ] && f=\"$o\" ;; esac ;; esac; awww img --transition-type \"$1\" --transition-duration \"$2\" \"$f\"", abs(wallpaper), s("lockscreen_UnlockTransition"), String(s("lockscreen_UnlockDuration")), String(sat)])
    }
    function lock() {
        if (s("lockscreen_Show") === false || guard.locked) return
        menu = false
        reveal = false
        wrong = false
        unlocking = false
        granted = false
        attempt = ""
        downloads = []
        Now.sync()
        guard.locked = true
        root.barred()
    }
    function toggle() {
        if (s("session_Show") === false || guard.locked) return
        sel = 0
        menu = !menu
    }
    function run(i) {
        const it = items[i]
        menu = false
        if (!it) return
        if (it.Command === "lock") lock()
        else Quickshell.execDetached(["sh", "-c", String(it.Command ?? "")])
    }
    function step(d) { if (items.length) sel = (sel + d + items.length) % items.length }

    GlobalShortcut { appid: "session"; name: "toggle"; onPressed: root.toggle() }
    GlobalShortcut { appid: "lockscreen"; name: "lock"; onPressed: root.lock() }

    IpcHandler {
        target: "lockscreen"
        function lock(): void { root.lock() }
    }

    Process {
        running: true
        command: ["sh", "-c", "f=\"${XDG_RUNTIME_DIR:-/tmp}/dolphin-login\"; [ -e \"$f\" ] && exit 1; : > \"$f\""]
        onExited: code => { if (code === 0 && root.s("lockscreen_Login")) root.lock() }
    }

    Process {
        id: dl
        command: ["sh", root.script, String(root.s("lockscreen_DownloadStale"))]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: Math.max(250, root.s("lockscreen_DownloadTime"))
        repeat: true
        running: guard.locked && !root.granted && root.s("lockscreen_Downloads")
        triggeredOnStart: true
        onTriggered: if (!dl.running) dl.running = true
    }

    PamContext {
        id: pam
        config: root.s("lockscreen_Pam")
        onPamMessage: if (responseRequired) respond(root.attempt)
        onCompleted: res => {
            root.attempt = ""
            if (res === PamResult.Success) { root.granted = true; hold.start() }
            else root.failed()
        }
    }

    Timer {
        id: hold
        interval: 310 + root.bounce * 0.6
        onTriggered: { root.unlocking = true; root.prepWall(); quit.start() }
    }

    Timer {
        id: quit
        interval: root.dur
        onTriggered: { guard.locked = false; root.waveWall(); root.cleared() }
    }

    WlSessionLock {
        id: guard

        WlSessionLockSurface {
            id: surf
            color: "black"
            readonly property real u: height

            Item {
                id: wallItem
                anchors.fill: parent
                property real amount: root.shown && root.s("lockscreen_Blur") ? 1 : 0
                readonly property real vivid: Math.max(-1, Math.min(1, root.s("lockscreen_Saturation")))
                Behavior on amount { NumberAnimation { duration: root.dur; easing.type: root.ease } }
                layer.enabled: amount > 0 || vivid !== 0
                layer.effect: MultiEffect {
                    autoPaddingEnabled: false
                    blurEnabled: wallItem.amount > 0
                    blurMax: 64
                    blur: wallItem.amount
                    saturation: wallItem.vivid
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
                        sourceSize.width: surf.width
                        sourceSize.height: surf.height
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
                color: root.col(root.s("lockscreen_DimColor"))
                opacity: root.shown ? root.s("lockscreen_Dim") : 0
                Behavior on opacity { NumberAnimation { duration: root.dur; easing.type: root.ease } }
            }

            Item {
                anchors.fill: parent
                opacity: root.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.dur; easing.type: root.ease } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: surf.u * root.s("lockscreen_MainTextHeight") - height / 2
                    text: Qt.formatDateTime(Now.date, "h:mm")
                    font.family: root.font
                    font.pixelSize: surf.u * 0.07 * root.s("lockscreen_MainTextScale")
                    color: root.col(root.s("lockscreen_MainTextColor"))
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: surf.u * root.s("lockscreen_TextHeight") - height / 2
                    text: Qt.formatDateTime(Now.date, "dddd, MMMM dd")
                    font.family: root.font
                    font.pixelSize: surf.u * 0.018 * root.s("lockscreen_TextScale")
                    color: root.col(root.s("lockscreen_TextColor"))
                }

                Rectangle {
                    id: pill
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: surf.u * 0.22
                    height: surf.u * 0.045
                    y: surf.u * root.s("lockscreen_PasswordHeight") - height / 2
                    radius: height / 2
                    color: root.col(root.s("lockscreen_PasswordColor"))
                    border.width: 2
                    border.color: root.col(root.s(root.wrong ? "lockscreen_ErrorColor" : root.granted ? "lockscreen_UnlockColor" : "lockscreen_PasswordBorderColor"))
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    transform: Translate { id: shake }

                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 10; duration: 70 }
                        NumberAnimation { target: shake; property: "x"; to: -6; duration: 60 }
                        NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
                    }

                    Connections {
                        target: root
                        function onFailed() { chars.clear(); pass.text = ""; root.wrong = true; shakeAnim.restart() }
                    }

                    Text {
                        id: icon
                        x: pill.height * 0.35
                        anchors.verticalCenter: parent.verticalCenter
                        property bool freed: false
                        readonly property bool granted: root.granted
                        text: root.glyph(root.s(freed ? "lockscreen_UnlockIcon" : "lockscreen_LockIcon"))
                        font.family: root.iconFont
                        font.pixelSize: pill.height * 0.4
                        color: root.col(root.s(root.granted ? "lockscreen_UnlockColor" : "lockscreen_PasswordBorderColor"))
                        Behavior on color { ColorAnimation { duration: 150 } }
                        onGrantedChanged: if (granted) swap.restart()

                        SequentialAnimation {
                            id: swap
                            NumberAnimation { target: icon; property: "scale"; to: 0; duration: 90; easing.type: Easing.InCubic }
                            ScriptAction { script: icon.freed = true }
                            NumberAnimation { target: icon; property: "scale"; to: 1; duration: 220; easing.type: Easing.OutBack }
                            NumberAnimation { target: pill; property: "scale"; to: root.s("lockscreen_UnlockBounce"); duration: root.bounce * 0.6; easing.type: Easing.OutCubic }
                            NumberAnimation { target: pill; property: "scale"; to: 1; duration: root.bounce * 0.4; easing.type: Easing.OutBack }
                        }
                    }

                    Text {
                        id: eye
                        anchors.right: parent.right
                        anchors.rightMargin: pill.height * 0.35
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.glyph(root.s(root.reveal ? "lockscreen_HideIcon" : "lockscreen_ShowIcon"))
                        font.family: root.iconFont
                        font.pixelSize: pill.height * 0.4
                        color: root.col(root.s("lockscreen_TextColor"))
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
                                    color: root.col(root.s("lockscreen_TextColor"))
                                    font.family: root.font
                                    font.pixelSize: pill.height * 0.4
                                    NumberAnimation { id: growIn; target: ch; property: "grow"; to: 1; duration: 250; easing.type: Easing.OutExpo }
                                    NumberAnimation { id: shrink; target: ch; property: "grow"; to: 0; duration: 250; easing.type: Easing.OutExpo; onFinished: chars.remove(ch.index) }
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
                        readOnly: pam.active || root.granted || root.unlocking
                        focus: true
                        Component.onCompleted: forceActiveFocus()
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape && !pam.active && !root.granted && !root.unlocking) {
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
                        onAccepted: if (!pam.active && !root.granted && text.length) { root.attempt = text; pam.start() }
                    }

                    MouseArea {
                        anchors.fill: eye
                        anchors.margins: -pill.height * 0.15
                        onClicked: root.reveal = !root.reveal
                    }
                }

                Loader {
                    id: song
                    readonly property real gap: pill.height * Math.max(0, root.s("lockscreen_MediaHeight"))
                    readonly property real unit: surf.u * 0.014 * root.s("lockscreen_MediaScale")
                    readonly property color ink: root.col(root.s("lockscreen_TerminalColor"))
                    readonly property color plate: root.col(String(root.cfg?.media_DiscColor ?? "#0b0b0b"))
                    readonly property real spinTime: Number(root.cfg?.media_SpinTime ?? 9000) || 9000
                    readonly property string font: root.font
                    readonly property string iconFont: root.iconFont
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: pill.y + pill.height + gap
                    active: root.s("lockscreen_Media")
                    visible: status === Loader.Ready && item.shown
                    source: Qt.resolvedUrl("Playing.qml")
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(pill.y + pill.height + pill.height * root.s("lockscreen_TerminalHeight"), song.visible ? song.y + song.height + song.gap : 0)
                    spacing: surf.u * 0.012 * root.s("lockscreen_TerminalScale")
                    visible: root.downloads.length > 0

                    Repeater {
                        model: root.downloads
                        Text {
                            required property var modelData
                            text: root.line(modelData)
                            lineHeight: 1.2
                            font.family: root.font
                            font.pixelSize: surf.u * 0.013 * root.s("lockscreen_TerminalScale")
                            color: root.col(root.s("lockscreen_TerminalColor"))
                        }
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.menu

        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: root.s("session_Blur") ? "dolphin-session-blur" : "dolphin-session"
            color: "transparent"

            readonly property real unit: screen.height * root.s("session_Size")
            readonly property int t: Math.max(0, root.s("session_Time"))
            readonly property int curve: Easing[root.s("session_Easing")] ?? Easing.OutCubic

            Item {
                id: body
                anchors.fill: parent
                focus: true
                opacity: 0
                Component.onCompleted: { opacity = 1; forceActiveFocus() }
                Behavior on opacity { NumberAnimation { duration: win.t; easing.type: win.curve } }

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) root.step(1)
                    else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) root.step(-1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.run(root.sel)
                    else if (e.key === Qt.Key_Escape) root.menu = false
                    else return
                    e.accepted = true
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.col(root.s("session_DimColor"))
                    opacity: root.s("session_Dim")
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.menu = false
                }

                Column {
                    anchors.centerIn: parent
                    spacing: win.unit * 0.3

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.s("session_Title")
                        font.family: root.font
                        font.pixelSize: win.unit * 0.3 * root.s("session_TextScale")
                        font.bold: true
                        color: root.col(root.s("session_TextColor"))
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: win.unit * 0.2

                        Repeater {
                            model: root.items

                            Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool on: root.sel === index
                                width: win.unit
                                height: win.unit
                                radius: Math.min(root.s(on ? "session_ActiveRadius" : "session_Radius"), width / 2)
                                color: root.col(root.s(on ? "session_ActiveColor" : "session_Color"))
                                Behavior on radius { NumberAnimation { duration: win.t; easing.type: win.curve } }
                                Behavior on color { ColorAnimation { duration: win.t; easing.type: win.curve } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.glyph(parent.modelData.Icon)
                                    font.family: root.iconFont
                                    font.pixelSize: win.unit * 0.32 * root.s("session_IconScale")
                                    color: root.col(root.s(parent.on ? "session_ActiveIconColor" : "session_IconColor"))
                                    Behavior on color { ColorAnimation { duration: win.t; easing.type: win.curve } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: root.sel = parent.index
                                    onClicked: root.run(parent.index)
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: label.implicitWidth + win.unit * 0.3
                        height: label.implicitHeight + win.unit * 0.12
                        radius: Math.min(root.s("session_Radius"), height / 2)
                        color: root.col(root.s("session_Color"))
                        Behavior on width { NumberAnimation { duration: win.t; easing.type: win.curve } }

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: root.items[root.sel]?.Label ?? ""
                            font.family: root.font
                            font.pixelSize: win.unit * 0.17 * root.s("session_TextScale")
                            color: root.col(root.s("session_TextColor"))
                        }
                    }
                }
            }
        }
    }
}
