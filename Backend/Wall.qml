import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: wall

    required property var cfg
    required property var store
    property string next: ""
    property string lead: ""
    property string ahead: ""
    property bool warm: false
    property var quick: null
    property bool want: false
    property int serial: 0
    property int owed: -1
    readonly property string script: decodeURIComponent(Qt.resolvedUrl("Wall.sh").toString().replace(/^file:\/\//, ""))
    readonly property bool given: typeof cfg?.dolphin_Background === "string"
    readonly property real sat: Math.max(-1, Math.min(1, Number(cfg?.dolphin_BackgroundSaturation ?? 0) || 0))
    readonly property string plan: !given ? "" : [cfg.dolphin_Background, cfg.dolphin_BackgroundTransition ?? "wave", cfg.dolphin_BackgroundDuration ?? 1, cfg.dolphin_ThemeMatch ?? 0.7, sat].join("\n")
    readonly property string folder: String(cfg?.settings_WallpaperFolder ?? "~/Dolphin/Data/Static/Images/Wallpaper").replace(/\/+$/, "")
    readonly property string folderPath: folder.startsWith("/") ? folder : String(Quickshell.env("HOME") ?? "") + "/" + folder.replace(/^~?\/*/, "")
    readonly property bool ripples: cfg?.dolphin_BackgroundRipple !== false
    readonly property real swift: Math.max(0.05, Number(cfg?.dolphin_BackgroundNextTime ?? 0.9) || 0.9)
    readonly property int pace: Math.max(60, cfg?.dolphin_BackgroundNextEvery ?? 220, ripples ? 0 : Math.round(swift * 1000) + 40)
    readonly property int rest: Math.round(swift * 1000) + 300

    function film(path) { return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path) }
    function link(path) { return "file://" + path.split("/").map(encodeURIComponent).join("/") }
    function apply() {
        if (plan === "") return
        if (run.running) { next = plan; run.running = false; return }
        next = ""
        const args = plan.split("\n")
        if (quick && quick.type === "none") args[1] = "none"
        else if (quick) {
            args[1] = quick.type
            args[2] = String(swift)
            args.push(quick.spot, "quick", String(Math.max(10, Math.min(240, Math.round(Number(cfg?.dolphin_BackgroundNextFps ?? 60) || 60)))))
            settle.restart()
        } else settle.stop()
        quick = null
        run.command = ["sh", script].concat(args)
        run.running = true
    }
    function finish() {
        if (waves.count > 0) {
            sweep.tag = serial
            if (lead !== "" && lead !== String(cfg?.dolphin_Background ?? "")) {
                owed = serial
                quick = { type: "none", spot: "" }
                store.set("dolphin_Background", lead)
            } else sweep.restart()
            return
        }
        if (plan === "") return
        if (run.running || beat.running) { settle.restart(); return }
        const args = plan.split("\n")
        run.command = ["sh", script, args[0], "none", "0", args[3], args[4], "", "settle"]
        run.running = true
    }
    function take(text) {
        const line = text.trim().split("\n").pop()
        let got = null
        try { got = JSON.parse(line) } catch (e) { return }
        if (got === null || typeof got !== "object") return
        const out = {}
        for (const k in got) out[k.charAt(0).toUpperCase() + k.slice(1)] = got[k]
        store.swap("Wallpaper", out)
    }
    function step() {
        want = true
        if (beat.running) return
        beat.start()
        advance()
    }
    function advance() {
        want = false
        if (lister.running) return
        lister.command = ["sh", "-c", lister.script, "sh", folderPath, (lead !== "" ? lead : String(cfg?.dolphin_Background ?? "")).split("/").pop(), String(sat)]
        lister.running = true
    }
    function cycle(text) {
        const rows = String(text).split("\n"), name = rows[0] ?? "", still = rows[1] ?? "", at = (rows[2] ?? "").replace(/^@/, ""), toned = rows[3] === "1"
        if (name === "") return
        const now = lead !== "" ? lead : String(cfg?.dolphin_Background ?? ""), choice = folder + "/" + name
        if (choice === now) return
        const m = /^(-?\d+),\s*(-?\d+)$/.exec(at.trim()), mon = Hyprland.focusedMonitor, k = mon && mon.scale > 0 ? mon.scale : 1
        const wide = mon ? mon.width / k : 0, tall = mon ? mon.height / k : 0, ok = !!m && wide > 0 && tall > 0
        const x = ok ? Math.max(0, Math.min(wide, Number(m[1]) - mon.x)) : wide / 2, y = ok ? Math.max(0, Math.min(tall, Number(m[2]) - mon.y)) : tall / 2
        if (ripples && wide > 0 && (still !== "" || !film(name))) {
            lead = choice
            waves.append({ src: link(still !== "" ? still : folderPath + "/" + name), cx: x, cy: y, tag: ++serial, plain: toned || /\.gif$/i.test(name) })
            ahead = (rows[4] ?? "") !== "" ? link(rows[4]) : ""
            warm = true
            cool.restart()
            settle.restart()
            return
        }
        waves.clear()
        lead = ""
        quick = { type: String(cfg?.dolphin_BackgroundNextTransition ?? "grow"), spot: ok ? (x / wide).toFixed(3) + "," + (1 - y / tall).toFixed(3) : "" }
        store.set("dolphin_Background", choice)
    }
    function landed(tag) {
        for (let i = 0; i < waves.count; i++) {
            if (waves.get(i).tag !== tag) continue
            if (i > 0) waves.remove(0, i)
            return
        }
    }
    function ended() {
        if (next !== "") return apply()
        if (owed !== serial || !waves.count) return
        owed = -1
        sweep.restart()
    }
    function failed(tag) {
        for (let i = 0; i < waves.count; i++) if (waves.get(i).tag === tag) { waves.remove(i); break }
        if (waves.count > 0 || lead === "") return
        const choice = lead
        lead = ""
        settle.stop()
        quick = { type: "none", spot: "" }
        store.set("dolphin_Background", choice)
    }

    onPlanChanged: apply()
    Component.onCompleted: apply()

    GlobalShortcut { appid: "wallpaper"; name: "next"; onPressed: wall.step() }

    ListModel { id: waves }
    Timer { id: beat; interval: wall.pace; repeat: true; onTriggered: wall.want ? wall.advance() : beat.stop() }
    Timer { id: settle; interval: wall.rest; onTriggered: wall.finish() }
    Timer { id: cool; interval: 20000; onTriggered: wall.warm = false }
    Timer {
        id: sweep
        property int tag: 0
        interval: 250
        onTriggered: {
            if (tag !== wall.serial) return
            waves.clear()
            wall.lead = ""
            wall.ahead = ""
        }
    }

    Process {
        id: run
        stdout: StdioCollector { onStreamFinished: wall.take(text) }
        onExited: wall.ended()
    }
    Process {
        id: lister
        readonly property string script: [
            "cd \"$1\" 2>/dev/null || exit",
            "l=$(ls -1 | grep -iE '\\.(png|jpe?g|webp|gif|bmp|mp4|mkv|webm|mov|avi|m4v)$' | sort)",
            "after() { printf '%s\\n' \"$l\" | awk -v c=\"$1\" 'NR==1{f=$0} d==1{print; d=2; exit} $0==c{d=1} END{if(d!=2 && NR>0) print f}'; }",
            "film() { case \"$1\" in *.[mM][pP]4|*.[mM][kK][vV]|*.[wW][eE][bB][mM]|*.[mM][oO][vV]|*.[aA][vV][iI]|*.[mM]4[vV]) return 0 ;; esac; return 1; }",
            "frame() { printf '/tmp/dolphin-wall-%s.png' \"$(printf %s \"$1\" | md5sum | cut -c1-12)\"; }",
            "toned() {",
            "case \"$3\" in 0|0.0|-0|'') return 1 ;; esac",
            "case \"$2\" in *.[gG][iI][fF]) return 1 ;; esac",
            "o=\"/tmp/dolphin-sat-$(printf %s \"$1|$3\" | md5sum | cut -c1-12).png\"",
            "[ -s \"$o\" ] && [ \"$o\" -nt \"$1\" ] && printf %s \"$o\"",
            "}",
            "n=$(after \"$2\")",
            "s=''",
            "k=0",
            "if film \"$n\"; then",
            "s=$(frame \"$1/$n\")",
            "[ -f \"$s\" ] && [ \"$s\" -nt \"$n\" ] || ffmpeg -v error -nostdin -y -i \"$n\" -frames:v 1 \"$s\" >/dev/null 2>&1 </dev/null",
            "[ -s \"$s\" ] || s=''",
            "fi",
            "if [ -n \"$n\" ] && { [ -n \"$s\" ] || ! film \"$n\"; }; then t=$(toned \"${s:-$1/$n}\" \"$n\" \"$3\") && { s=\"$t\"; k=1; }; fi",
            "m=$(after \"$n\")",
            "a=''",
            "if [ -n \"$m\" ] && [ \"$m\" != \"$n\" ]; then",
            "if film \"$m\"; then a=$(frame \"$1/$m\"); [ -s \"$a\" ] || a=''; else a=\"$1/$m\"; fi",
            "[ -n \"$a\" ] && t=$(toned \"$a\" \"$m\" \"$3\") && a=\"$t\"",
            "fi",
            "printf '%s\\n%s\\n@%s\\n%s\\n%s\\n' \"$n\" \"$s\" \"$(hyprctl cursorpos 2>/dev/null)\" \"$k\" \"$a\""
        ].join("\n")
        stdout: StdioCollector { onStreamFinished: wall.cycle(text) }
    }

    LazyLoader {
        active: waves.count > 0 || wall.warm

        PanelWindow {
            id: pond
            readonly property real dots: pond.screen?.devicePixelRatio ?? 1
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "dolphin-ripple"
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}

            Item {
                anchors.fill: parent

            Image {
                anchors.fill: parent
                visible: false
                source: wall.ahead
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Math.round(pond.width * pond.dots)
                sourceSize.height: Math.round(pond.height * pond.dots)
            }
            Repeater {
                model: waves

                Item {
                    id: drop
                    required property string src
                    required property real cx
                    required property real cy
                    required property int tag
                    required property bool plain
                    readonly property real reach: Math.hypot(Math.max(cx, width - cx), Math.max(cy, height - cy)) + 2
                    property real size: 0
                    property bool whole: false
                    anchors.fill: parent

                    Image {
                        id: shot
                        anchors.fill: parent
                        visible: false
                        source: drop.src
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: Math.round(pond.width * pond.dots)
                        sourceSize.height: Math.round(pond.height * pond.dots)
                        onStatusChanged: {
                            if (status === Image.Ready) grow.start()
                            else if (status === Image.Error) wall.failed(drop.tag)
                        }
                    }
                    Item {
                        id: stencil
                        anchors.fill: parent
                        visible: false
                        layer.enabled: !drop.whole
                        Rectangle { x: drop.cx - drop.size; y: drop.cy - drop.size; width: drop.size * 2; height: width; radius: drop.size; color: "#000000" }
                    }
                    MultiEffect {
                        anchors.fill: parent
                        visible: shot.status === Image.Ready && drop.size > 0
                        source: shot
                        saturation: drop.plain ? 0 : wall.sat
                        maskEnabled: !drop.whole
                        maskSource: stencil
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                    }
                    Rectangle {
                        visible: !drop.whole && drop.size > 0
                        x: drop.cx - drop.size
                        y: drop.cy - drop.size
                        width: drop.size * 2
                        height: width
                        radius: drop.size
                        color: "transparent"
                        border.width: Math.max(1, Math.round(4 * (1 - drop.size / drop.reach)))
                        border.color: Qt.rgba(1, 1, 1, 0.55 * (1 - drop.size / drop.reach))
                    }
                    NumberAnimation {
                        id: grow
                        target: drop
                        property: "size"
                        from: 0
                        to: drop.reach
                        duration: Motion.span(Math.round(wall.swift * 1000))
                        easing.type: Easing.OutQuad
                        onFinished: { drop.whole = true; wall.landed(drop.tag) }
                    }
                    Component.onCompleted: if (shot.status === Image.Ready) grow.start()
                }
            }
            }
        }
    }
}
