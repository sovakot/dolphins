import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../../Backend"
import "../../../Data/Dynamic"

Kit {
    id: root

    base: ({
        media_Show: true, media_Follow: false, media_Effects: true, media_Corner: -1,
        media_Mini: false, media_MiniWidth: 29, media_MiniHeight: 5.8, media_MiniCorner: "bottom-right", media_MiniMarginX: 14, media_MiniMarginY: 14, media_MiniRadius: 16, media_MiniScroll: 28, media_MiniPause: 1200, media_MiniBars: 32, media_MiniBarOpacity: 0.35,
        media_Icon: "f001", media_Width: 0.3, media_Height: 0.7, media_TextSize: 13, media_ChangeTime: 600,
        media_Color: "Background", media_TextColor: "Text", media_ActiveColor: "Active", media_BarColor: "Active", media_PeakColor: "Text", media_DiscColor: "#0b0b0b",
        media_AeroColor: "Active", media_AeroColor2: "Active",
        media_Backdrop: true, media_BackdropOpacity: 0.28, media_BackdropBlur: 1,
        media_Bars: 48, media_Framerate: 60, media_Smoothing: 35, media_Smooth: 30, media_Gain: 1, media_Sharp: true,
        media_Floor: true, media_FloorStyle: "bars", media_FloorWidth: 0.7, media_FloorGain: 1.15, media_Treble: 1.4, media_Mirror: true, media_Blocks: 14,
        media_Ring: true, media_RingSpin: 40000, media_RingLength: 0.12, media_RingWidth: 0.55, media_RingGap: 0.02,
        media_Spin: true, media_SpinTime: 9000, media_FxTempo: true, media_Tempo: 1, media_TempoBase: 110,
        media_Violence: 1.5, media_Sensitivity: 0.7, media_Sync: 70, media_Loud: 0.9,
        media_FxPulse: true, media_Glow: true, media_FxWaves: true, media_FxBounce: true, media_FxShake: true, media_FxFlash: true, media_FxStrobe: false,
        media_FxSpinKick: true, media_FxScratch: false, media_FxWobble: true, media_FxBurst: true, media_FxRipple: true, media_FxSparks: true, media_FxConfetti: true,
        media_FxTint: true, media_FxZoom: true, media_FxTilt: true, media_FxEdge: true, media_FxTitle: true, media_FxGlitch: true,
        media_FxPredict: true, media_FxBuild: true, media_FxCharge: true, media_FxLoud: true,
        media_FxRainbow: false, media_FxAura: true, media_FxBeams: false, media_FxOrbits: false, media_FxBubbles: false, media_FxStars: true, media_FxVignette: true,
        media_FxHaze: true, media_FxGloss: true, media_FxBreath: true, media_FxTrails: false, media_FxReflection: false, media_FxTheme: false, media_FxVoice: false,
        media_FxLasers: false, media_FxSpot: false, media_FxEmbers: false, media_FxScan: false, media_FxFloorGlow: false, media_FxBolt: false, media_FxCorners: false,
        media_Lasers: 6, media_Spots: 3, media_Embers: 40, media_Scan: 0.18, media_FloorGlow: 0.5, media_Bolts: 2, media_Corners: 1,
        media_ThemeColor: "Accent", media_ThemeStrength: 0.2,
        media_Pulse: 0.1, media_Tint: 0.15, media_Waves: 3, media_Bounce: 0.06, media_Shake: 8, media_Flash: 0.2, media_SpinKick: 3, media_Burst: 0.4,
        media_Sparks: 24, media_Haze: 0.5, media_Trail: 420, media_Reflection: 0.3, media_Rainbow: 1, media_Build: 1,
        media_Zoom: 0.04, media_Tilt: 3, media_Glitch: 6, media_TitleKick: 0.06, media_Ripple: 0.5, media_Confetti: 30, media_Wobble: 14, media_Edge: 3,
        media_Aura: 0.6, media_Beams: 10, media_Orbits: 3, media_Bubbles: 12, media_Stars: 36, media_Vignette: 0.5, media_Breath: 0.06,
        media_VolumeStep: 0.05, media_Interval: 500, media_PreviewEvery: 2400
    })

    readonly property var groups: [
        { title: "On the beat", code: "f0e7", items: [["media_FxPulse", "Pulse"], ["media_Glow", "Glow"], ["media_FxWaves", "Rings"], ["media_FxBounce", "Bounce"], ["media_FxShake", "Shake"], ["media_FxZoom", "Zoom"], ["media_FxTilt", "Tilt"], ["media_FxFlash", "Flash"], ["media_FxStrobe", "Strobe"], ["media_FxEdge", "Edge light"], ["media_FxTint", "Colour wash"], ["media_FxSpinKick", "Spin kick"], ["media_FxScratch", "Scratch"], ["media_FxWobble", "Wobble"], ["media_FxBurst", "Bar burst"], ["media_FxRipple", "Ripple"], ["media_FxSparks", "Sparks"], ["media_FxConfetti", "Confetti"], ["media_FxTitle", "Title kick"], ["media_FxGlitch", "Glitch"], ["media_FxBolt", "Lightning"], ["media_FxCorners", "Corner marks"], ["media_FxFloorGlow", "Bass glow"]] },
        { title: "Timing", code: "f017", items: [["media_FxPredict", "Beat prediction"], ["media_FxBuild", "Build-up"], ["media_FxCharge", "Charge ring"], ["media_FxLoud", "Louder is wilder"]] },
        { title: "Atmosphere", code: "f0c2", items: [["media_FxRainbow", "Rainbow"], ["media_FxAura", "Aura"], ["media_FxBeams", "Light beams"], ["media_FxOrbits", "Orbits"], ["media_FxBubbles", "Bubbles"], ["media_FxStars", "Stars"], ["media_FxVignette", "Vignette"], ["media_FxHaze", "Haze"], ["media_FxGloss", "Gloss"], ["media_FxBreath", "Breathing cover"], ["media_Backdrop", "Cover background"], ["media_FxTheme", "Theme tint"], ["media_FxLasers", "Lasers"], ["media_FxSpot", "Spotlights"], ["media_FxEmbers", "Embers"], ["media_FxScan", "Scanlines"]] },
        { title: "Bars and disc", code: "f080", items: [["media_FxVoice", "Voice and sound"], ["media_FxTrails", "Trails"], ["media_FxReflection", "Reflection"], ["media_Ring", "Bars around the disc"], ["media_Floor", "Bottom bars"], ["media_Mirror", "Mirror"], ["media_Sharp", "Sharp bars"], ["media_Spin", "Spin the disc"], ["media_FxTempo", "Tempo spin"]] }
    ]

    property color cover: "#808080"
    property bool tinted: false
    readonly property bool matched: s("media_FxTheme") && tinted
    readonly property color deep: Qt.hsla(Math.max(0, cover.hslHue), cover.hslSaturation * 0.55, 0.09, 1)
    readonly property color bg: matched ? deep : col(s("media_Color"))
    readonly property color tx: col(s("media_TextColor"))
    readonly property color hi: matched ? cover : col(s("media_ActiveColor"))
    readonly property color beam: matched ? cover : col(s("media_BarColor"))
    readonly property color peak: col(s("media_PeakColor"))
    readonly property color aero: matched ? cover : col(s("media_AeroColor"))
    readonly property color aero2: matched ? cover : col(s("media_AeroColor2"))
    readonly property color onAero: aero.r * 0.299 + aero.g * 0.587 + aero.b * 0.114 > 0.6 ? "#15151b" : "#ffffff"
    readonly property real px: Math.max(9, s("media_TextSize"))
    readonly property int count: Math.max(8, Math.min(128, Math.round(s("media_Bars"))))
    readonly property bool lively: s("media_Effects") && Motion.on
    readonly property bool rainbow: lively && s("media_FxRainbow")
    readonly property color flare: rainbow ? Qt.hsla(hue, 0.9, 0.6, 1) : beam
    readonly property var levels: beat.levels
    readonly property real kick: lively ? beat.kick : 0
    readonly property real energy: beat.energy
    readonly property real charge: lively && s("media_FxBuild") ? beat.charge * Math.max(0, s("media_Build")) : 0
    readonly property real drive: Math.max(0, s("media_Violence")) * (s("media_FxLoud") ? 0.7 + Math.max(0, s("media_Loud")) * energy : 1)
    readonly property real surge: 1 + (fx("media_FxBurst") ? boost * Math.max(0, s("media_Burst")) * drive : 0)
    readonly property real gain: Math.max(0, s("media_Gain")) * surge
    readonly property real front: 1 - boost / Math.max(0.01, punch)
    readonly property real swell: fx("media_FxRipple") ? boost * Math.max(0, s("media_Ripple")) * drive : 0
    readonly property real corner: s("media_Sharp") ? 0 : 1
    readonly property var list: Mpris.players.values
    readonly property var playing: list.find(p => p.isPlaying) ?? null
    readonly property var player: (chosen && list.includes(chosen) ? chosen : null) ?? playing ?? (last && list.includes(last) ? last : null) ?? list[0] ?? null
    readonly property bool live: !!player && player.isPlaying
    readonly property bool demo: open && managing && !live
    readonly property bool follow: s("media_Follow")
    readonly property real length: Math.max(0, player?.length ?? 0)
    readonly property real position: Math.max(0, player?.position ?? 0)
    readonly property real slam: punch >= 1 ? punch * punch : punch * 0.6
    readonly property real shakeX: Math.cos(aim) * Math.sin(jolt * 30) * jolt * s("media_Shake") * drive * slam
    readonly property real shakeY: Math.sin(aim) * Math.sin(jolt * 30) * jolt * s("media_Shake") * drive * slam
    readonly property bool mini: s("media_Mini")
    readonly property real round: s("media_Corner") >= 0 ? s("media_Corner") : edgeRound
    readonly property color wash: matched ? cover : col(s("media_ThemeColor"))
    readonly property var flat: {
        const out = ["media_Follow", "media_Effects"]
        for (const g of groups) for (const e of g.items) out.push(e[0])
        return out
    }
    readonly property var bands: {
        const n = levels.length || count, lo = Math.round(n * 0.34), hi = Math.round(n * 0.8), sound = [], voice = []
        for (let i = 0; i < n; i++) (i >= lo && i < hi ? voice : sound).push(i)
        return { sound: sound, voice: voice }
    }
    property real edgeRound: 0
    property int at: -1
    property var last: null
    property var chosen: null
    property bool open: false
    property bool hopping: false
    property bool missing: false
    property bool managing: false
    property int room: 0
    property int epoch: 0
    property int tries: 0
    property real jolt: 0
    property real aim: 0
    property real flash: 0
    property real boost: 0
    property real punch: 1
    property real side: 1
    property real hue: 0
    property real drift: 0
    property real pace: 1

    signal struck()

    Behavior on cover { ColorAnimation { duration: Motion.span(Math.max(0, root.s("media_ChangeTime"))) } }

    onPlayingChanged: if (playing) last = playing
    onDemoChanged: beat.reset()
    onFollowChanged: glue.restart()
    onOpenChanged: {
        if (open) Hyprland.refreshToplevels()
        if (hopping) return
        missing = false
        managing = false
        at = -1
        meter.running = open
        if (open) rounder.running = true
        if (open) return
        beat.reset()
        jolt = 0
        flash = 0
        boost = 0
        pace = 1
    }

    function fx(key) { return lively && s(key) === true }
    function sample(d) {
        const sums = [], all = [0, 0, 0, 0]
        for (let i = 0; i < 12; i++) sums.push([0, 0, 0, 0])
        for (let i = 0; i + 3 < d.length; i += 4) {
            if (d[i + 3] < 128) continue
            const r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255, top = Math.max(r, g, b), c = top - Math.min(r, g, b)
            all[0] += r; all[1] += g; all[2] += b; all[3]++
            if (c < 0.12 || top < 0.2) continue
            const h = top === r ? ((g - b) / c + 6) % 6 : top === g ? (b - r) / c + 2 : (r - g) / c + 4, part = sums[Math.min(11, Math.floor(h * 2))], w = c * top
            part[0] += r * w; part[1] += g * w; part[2] += b * w; part[3] += w
        }
        if (!all[3]) { tinted = false; return }
        let best = sums[0]
        for (const p of sums) if (p[3] > best[3]) best = p
        const vivid = best[3] > all[3] * 0.01, from = vivid ? best : all
        const c = Qt.rgba(from[0] / from[3], from[1] / from[3], from[2] / from[3], 1)
        cover = Qt.hsla(Math.max(0, c.hslHue), vivid ? Math.max(0.5, c.hslSaturation) : c.hslSaturation, Math.max(0.52, Math.min(0.68, c.hslLightness)), 1)
        tinted = true
    }
    function rand(a, b) {
        const v = Math.sin(a * 127.1 + b * 311.7) * 43758.5453
        return v - Math.floor(v)
    }
    function spot() {
        const t = Hyprland.toplevels.values.find(h => h.title === "dolphin-media")
        return t?.workspace?.id ?? t?.lastIpcObject?.workspace?.id ?? room
    }
    function show() {
        room = Hyprland.focusedWorkspace?.id ?? 0
        epoch++
        open = true
    }
    function walk(key, cols) {
        const n = flat.length, was = at
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) { if (at >= 0) flip(flat[at]); return }
        if (at < 0) at = 0
        else if (key === Qt.Key_Right) at = Math.min(n - 1, at + 1)
        else if (key === Qt.Key_Left) at = Math.max(0, at - 1)
        else if (key === Qt.Key_Down) at = at < 2 ? 2 : Math.min(n - 1, at + cols)
        else if (key === Qt.Key_Up) at = at < 2 ? at : at < 2 + cols ? Math.min(1, at - 2) : at - cols
        if (at === was && key === Qt.Key_Down) at = n - 1
    }
    function shrink(small) {
        managing = false
        save("media_Mini", small)
    }
    function toggle() {
        if (!s("media_Show") || hop.running) return
        if (mini) { if (open) open = false; else show(); return }
        if (!open) return show()
        if (follow || spot() === (Hyprland.focusedWorkspace?.id ?? 0)) { open = false; return }
        hopping = true
        open = false
        hop.restart()
    }
    function stick() {
        const t = Hyprland.toplevels.values.find(h => h.title === "dolphin-media"), ipc = t?.lastIpcObject
        if (!open || pinner.running) return
        if (!ipc || !ipc.address) { if (tries++ < 8) glue.restart(); return }
        if ((ipc.pinned === true) === follow) return
        pinner.command = ["hyprctl", "dispatch", "hl.dsp.window.pin({ window = \"address:" + ipc.address + "\" })"]
        pinner.running = true
    }
    function clock(v) {
        const n = Math.max(0, Math.floor(v)), h = Math.floor(n / 3600), m = Math.floor(n % 3600 / 60), sec = String(n % 60).padStart(2, "0")
        return h ? h + ":" + String(m).padStart(2, "0") + ":" + sec : m + ":" + sec
    }
    function blend(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    function tone(pos, level) { return rainbow ? Qt.hsla((hue + pos * 0.85) % 1, 0.9, 0.5 + 0.12 * level, 1) : blend(beam, peak, level * level) }
    function swap() {
        if (list.length < 2) return
        chosen = list[(list.indexOf(player) + 1) % list.length]
    }
    function louder(way) {
        const p = player
        if (p && p.volumeSupported && p.canControl) p.volume = Math.max(0, Math.min(1, p.volume + way * Math.max(0.01, s("media_VolumeStep"))))
    }
    function flip(key) {
        save(key, s(key) !== true)
        if (managing && key !== "media_Follow" && s(key) === true) strike(1.3)
    }
    function restore() {
        const out = {}
        for (const g of groups) for (const e of g.items) {
            const first = Config.stock[e[0]] ?? base[e[0]]
            if (typeof first === "boolean" && s(e[0]) !== first) out[e[0]] = first
        }
        Config.many(out)
    }
    function strike(power) {
        if (!lively) return
        const p = Math.min(1.6, power)
        punch = p
        side = -side
        aim = Math.random() * Math.PI * 2
        boost = p
        if (s("media_FxShake")) jolt = p
        if (power >= 1 && s("media_FxFlash")) flash = 1
        struck()
    }
    function fade(dt) {
        if (jolt > 0) jolt = Math.max(0, jolt - dt * 3.2)
        if (flash > 0) flash = Math.max(0, flash - dt * 4.5)
        if (boost > 0) boost = Math.max(0, boost - dt * 1.8)
        if (rainbow) hue = (hue + dt * (0.02 + 0.2 * energy) * Math.max(0, s("media_Rainbow"))) % 1
        drift = (drift + dt * (0.03 + 0.09 * energy)) % 1000
        const want = fx("media_FxTempo") ? Math.max(0.4, Math.min(3, Math.pow((beat.tempo > 0 ? beat.tempo / Math.max(40, s("media_TempoBase")) : 1) * beat.busy, Math.max(0, s("media_Tempo"))))) : 1
        pace += (want - pace) * (1 - Math.exp(-dt / 0.7))
    }
    function fake(now) {
        const n = count, cycle = now % 10000, building = cycle >= 6000 && cycle < 9000, hush = cycle >= 9000 && cycle < 9250
        const thump = Math.exp(-(now % 500) / 110), out = []
        for (let i = 0; i < n; i++) {
            let v = 0.2 + 0.16 * Math.sin(now / 190 + i * 0.9) + 0.12 * Math.sin(now / 77 + i * 2.3)
            if (i < 5) v = building ? 0.04 : 0.25 + 0.75 * thump
            else if (building) v *= 1 + (cycle - 6000) / 3000
            else if (cycle < 2000) v *= 1.7
            if (hush) v = 0
            out.push(Math.round(Math.max(0, Math.min(1, v * (1 - i / n * 0.4))) * 1000))
        }
        return out.join(";") + ";"
    }

    Beat {
        id: beat
        edge: root.demo ? 0.2 : 0.6 - 0.58 * Math.max(0, Math.min(1, root.s("media_Sensitivity")))
        sync: Math.max(0, root.s("media_Sync"))
        predict: root.s("media_FxPredict")
        build: root.s("media_FxBuild")
        onHit: power => root.strike(power)
    }
    Process {
        id: meter
        command: ["sh", "-c", "command -v cava >/dev/null 2>&1 || exit 127; c=\"${XDG_RUNTIME_DIR:-/tmp}/dolphin-cava.conf\"; printf '[general]\\nbars = %s\\nframerate = %s\\n[smoothing]\\nnoise_reduction = %s\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 1000\\nbar_delimiter = 59\\nchannels = mono\\nmono_option = average\\n' \"$1\" \"$2\" \"$3\" > \"$c\" && exec cava -p \"$c\"", "cava", String(root.count), String(Math.max(10, Math.min(144, Math.round(root.s("media_Framerate"))))), String(Math.max(0, Math.min(100, Math.round(root.s("media_Smoothing")))))]
        stdout: SplitParser { onRead: line => { if (!root.demo) beat.feed(line, Date.now()) } }
        onExited: (exitCode, exitStatus) => { if (exitCode === 127) root.missing = true }
    }
    Process { id: pinner; onExited: (exitCode, exitStatus) => Hyprland.refreshToplevels() }
    Process {
        id: rounder
        command: ["hyprctl", "getoption", "decoration:rounding", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /"int"\s*:\s*(\d+)/.exec(text)
                if (m) root.edgeRound = Number(m[1])
            }
        }
    }
    Timer {
        interval: Math.max(250, root.s("media_Interval"))
        repeat: true
        running: root.open && root.live
        onTriggered: if (root.live) root.player.positionChanged()
    }
    Timer { interval: 33; repeat: true; running: root.demo; onTriggered: beat.feed(root.fake(Date.now()), Date.now()) }
    Timer { interval: Math.max(600, root.s("media_PreviewEvery")); repeat: true; running: root.open && root.managing && root.lively; onTriggered: root.strike(1.3) }
    Timer { id: hop; interval: 80; onTriggered: { root.hopping = false; root.show() } }
    Timer { id: glue; interval: 250; onTriggered: { if (!root.open) return; Hyprland.refreshToplevels(); settle.restart() } }
    Timer { id: settle; interval: 150; onTriggered: root.stick() }

    GlobalShortcut { appid: "media"; name: "toggle"; onPressed: root.toggle() }
    Connections {
        target: Reveal
        function onPlayer() { if (root.s("media_Show") && !root.open) root.show() }
    }
    IpcHandler {
        target: "media"
        function toggle(): void { root.toggle() }
    }

    component Swatch: Canvas {
        id: swatch
        property string art: ""
        property string held: ""
        readonly property string want: root.s("media_FxTheme") ? art : ""
        function pull() {
            if (!available) return
            if (held !== "" && held !== want) unloadImage(held)
            held = want
            if (want === "" || isImageError(want)) { root.tinted = false; return }
            if (isImageLoaded(want)) requestPaint()
            else loadImage(want)
        }
        width: 24
        height: 24
        opacity: 0
        onWantChanged: swatch.pull()
        onAvailableChanged: swatch.pull()
        onImageLoaded: {
            if (want === "") return
            if (isImageLoaded(want)) requestPaint()
            else if (isImageError(want)) root.tinted = false
        }
        onPaint: {
            if (want === "" || !isImageLoaded(want)) return
            const g = getContext("2d")
            g.clearRect(0, 0, width, height)
            g.drawImage(want, 0, 0, width, height)
            root.sample(g.getImageData(0, 0, width, height).data)
        }
    }

    component Key: Rectangle {
        id: key
        property string code: ""
        property bool strong: false
        property real shrink: 1
        property real turn: 0
        signal tapped()
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: Math.round(root.px * (strong ? 4.2 : 3.2) * shrink)
        height: width
        radius: width / 2
        color: strong ? root.hi : keyArea.containsMouse ? Qt.alpha(root.tx, 0.12) : "transparent"
        scale: keyArea.pressed ? 0.92 : 1
        Behavior on color { Tint {} }
        Behavior on scale { Glide {} }
        Text { anchors.centerIn: parent; rotation: key.turn; text: root.glyph(key.code); font.family: root.iconFont; font.pixelSize: root.px * (key.strong ? 1.5 : 1.2) * (key.shrink < 1 ? key.shrink * 1.25 : 1); color: key.strong ? root.bg : root.tx }
        MouseArea { id: keyArea; anchors.fill: parent; hoverEnabled: true; onClicked: key.tapped() }
    }

    component Sheen: Rectangle {
        property real strength: 0.45
        x: 2
        y: 1
        width: parent ? parent.width - 4 : 0
        height: parent ? parent.height * 0.46 : 0
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, strength) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.02) }
        }
    }

    component Glass: Rectangle {
        id: glass
        default property alias items: glassBody.data
        radius: Math.round(root.px * 1.3)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.3)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.2) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.06) }
            GradientStop { position: 1; color: Qt.rgba(root.aero.r, root.aero.g, root.aero.b, 0.18) }
        }
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 2
            height: Math.min(parent.height * 0.5, Math.round(root.px * 2.6))
            radius: glass.radius
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.2) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        Item { id: glassBody; anchors.fill: parent }
    }

    component Pill: Rectangle {
        id: pill
        property string code: ""
        property string label: ""
        property bool lit: false
        property bool marked: false
        property real turn: 0
        signal tapped()
        height: Math.round(root.px * 2.3)
        width: Math.max(height, pillRow.width + Math.round(root.px * 1.7))
        radius: height / 2
        border.width: marked ? 2 : 1
        border.color: marked ? root.tx : Qt.rgba(1, 1, 1, lit ? 0.65 : 0.28)
        scale: pillArea.pressed ? 0.94 : 1
        Behavior on scale { Glide {} }
        gradient: Gradient {
            GradientStop { position: 0; color: pill.lit ? Qt.lighter(root.aero, 1.35) : Qt.rgba(1, 1, 1, pillArea.containsMouse ? 0.26 : 0.16) }
            GradientStop { position: 1; color: pill.lit ? Qt.darker(root.aero, 1.5) : Qt.rgba(1, 1, 1, 0.04) }
        }
        Sheen { strength: pill.lit ? 0.6 : 0.3 }
        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: Math.round(root.px * 0.5)
            Text { visible: pill.code !== ""; anchors.verticalCenter: parent.verticalCenter; rotation: pill.turn; text: root.glyph(pill.code); font.family: root.iconFont; font.pixelSize: root.px; color: pill.lit ? root.onAero : root.tx }
            Text { visible: pill.label !== ""; anchors.verticalCenter: parent.verticalCenter; text: root.word(pill.label); font.family: root.font; font.pixelSize: root.px - 1; font.weight: Font.DemiBold; color: pill.lit ? root.onAero : root.tx }
        }
        MouseArea { id: pillArea; anchors.fill: parent; hoverEnabled: true; onClicked: pill.tapped() }
    }

    component Knob: Item {
        id: knob
        property bool lit: false
        width: Math.round(root.px * 3.3)
        height: Math.round(root.px * 1.8)
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, knob.lit ? 0.6 : 0.25)
            gradient: Gradient {
                GradientStop { position: 0; color: knob.lit ? Qt.lighter(root.aero2, 1.3) : Qt.rgba(0, 0, 0, 0.4) }
                GradientStop { position: 1; color: knob.lit ? Qt.darker(root.aero2, 1.45) : Qt.rgba(1, 1, 1, 0.1) }
            }
            Sheen { strength: knob.lit ? 0.55 : 0.18 }
        }
        Rectangle {
            y: 2
            x: knob.lit ? parent.width - width - 2 : 2
            width: parent.height - 4
            height: width
            radius: width / 2
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.2)
            gradient: Gradient {
                GradientStop { position: 0; color: "#ffffff" }
                GradientStop { position: 1; color: "#c9d8e6" }
            }
            Behavior on x { NumberAnimation { duration: Motion.span(170); easing.type: Easing.OutCubic } }
        }
    }

    component Line: Item {
        id: line
        property string key: ""
        property string label: ""
        readonly property bool lit: root.s(key) === true
        readonly property bool marked: root.at >= 0 && root.flat[root.at] === key
        signal reached()
        height: Math.round(root.px * 2.9)
        onMarkedChanged: if (marked) reached()
        Rectangle { anchors.fill: parent; anchors.margins: 2; radius: height / 2; color: Qt.rgba(1, 1, 1, lineArea.containsMouse || line.marked ? 0.1 : 0); border.width: line.marked ? 2 : 0; border.color: root.aero; Behavior on color { Tint {} } }
        Text { x: Math.round(root.px * 0.9); width: parent.width - x - lineKnob.width - Math.round(root.px * 1.6); anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: root.word(line.label); font.family: root.font; font.pixelSize: root.px; color: root.tx; opacity: line.lit ? 1 : 0.6 }
        Knob { id: lineKnob; anchors.right: parent.right; anchors.rightMargin: Math.round(root.px * 0.8); anchors.verticalCenter: parent.verticalCenter; lit: line.lit }
        MouseArea { id: lineArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.flip(line.key) }
    }

    component Bubble: Rectangle {
        id: bub
        property int seed: 0
        property real roomW: 0
        property real roomH: 0
        readonly property real size: Math.round(root.px * (1.2 + 2.8 * root.rand(seed, 1)))
        readonly property real rise: (root.drift * (0.6 + root.rand(seed, 2)) + root.rand(seed, 3)) % 1
        width: size
        height: size
        radius: size / 2
        x: roomW * root.rand(seed, 4) + Math.sin(rise * 9 + seed) * size * 0.5 - size / 2
        y: roomH + size - rise * (roomH + size * 2)
        scale: 1 + root.kick * 0.5
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.55)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.3) }
            GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.04) }
            GradientStop { position: 1; color: Qt.rgba(root.aero.r, root.aero.g, root.aero.b, 0.25) }
        }
        Rectangle { x: parent.width * 0.2; y: parent.height * 0.14; width: parent.width * 0.3; height: parent.height * 0.18; radius: height / 2; rotation: -30; color: Qt.rgba(1, 1, 1, 0.75) }
    }

    component Crawl: Item {
        id: crawl
        property string text: ""
        property color tint: root.tx
        property real size: root.px
        property int weight: Font.Normal
        property real level: 1
        readonly property real gap: Math.round(size * 3)
        readonly property bool wide: label.implicitWidth > width + 1
        readonly property real run: label.implicitWidth + gap
        clip: true
        height: label.implicitHeight
        onTextChanged: { belt.x = 0; if (roll.running) roll.restart() }
        onWideChanged: if (!wide) belt.x = 0
        Row {
            id: belt
            spacing: crawl.gap
            Text { id: label; text: crawl.text; font.family: root.font; font.pixelSize: crawl.size; font.weight: crawl.weight; color: crawl.tint; opacity: crawl.level }
            Text { visible: crawl.wide; text: crawl.text; font.family: root.font; font.pixelSize: crawl.size; font.weight: crawl.weight; color: crawl.tint; opacity: crawl.level }
        }
        SequentialAnimation {
            id: roll
            running: crawl.wide && crawl.visible && Motion.on
            loops: Animation.Infinite
            PauseAnimation { duration: Math.max(0, root.s("media_MiniPause")) }
            NumberAnimation { target: belt; property: "x"; from: 0; to: -crawl.run; duration: Math.max(200, crawl.run / Math.max(4, root.s("media_MiniScroll")) * 1000) }
        }
    }

    LazyLoader {
        active: root.open && root.s("media_Show") && root.mini

        PanelWindow {
            id: tiny
            readonly property string spot: String(root.s("media_MiniCorner"))
            readonly property bool high: spot.startsWith("top")
            readonly property bool west: spot.endsWith("left")
            readonly property real pad: Math.round(root.px * 0.7)
            readonly property string art: String(root.player?.trackArtUrl ?? "")
            readonly property int bars: Math.max(4, Math.min(96, Math.round(root.s("media_MiniBars"))))
            readonly property real lift: Math.max(0, root.s("media_Gain")) * Math.max(0, root.s("media_FloorGain"))
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "dolphin-media-mini"
            anchors { top: tiny.high; bottom: !tiny.high; left: tiny.west; right: !tiny.west }
            margins {
                left: Math.max(0, root.s("media_MiniMarginX"))
                right: Math.max(0, root.s("media_MiniMarginX"))
                top: Math.max(0, root.s("media_MiniMarginY"))
                bottom: Math.max(0, root.s("media_MiniMarginY"))
            }
            implicitWidth: Math.round(root.px * Math.max(14, root.s("media_MiniWidth")))
            implicitHeight: Math.round(root.px * Math.max(3.5, root.s("media_MiniHeight")))

            ClippingRectangle {
                id: slab
                readonly property real part: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0
                anchors.fill: parent
                radius: Math.min(height / 2, Math.max(0, root.s("media_MiniRadius")))
                color: root.bg
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.26)
                opacity: Reveal.glass

                Swatch { art: tiny.art }
                FrameAnimation {
                    running: root.open && root.lively && (root.live || root.jolt > 0 || root.flash > 0 || root.boost > 0)
                    onTriggered: {
                        if (root.live) beat.tick(Date.now())
                        root.fade(Math.min(0.05, frameTime))
                    }
                }

                Backdrop {
                    visible: root.s("media_Backdrop")
                    anchors.fill: parent
                    anchors.margins: -24
                    art: root.s("media_Backdrop") ? tiny.art : ""
                    time: Math.max(0, root.s("media_ChangeTime"))
                    opacity: Math.max(0, Math.min(1, root.s("media_BackdropOpacity") * 1.6))
                    blur: root.s("media_BackdropBlur")
                    reach: 48
                    swell: root.fx("media_FxBreath") ? Math.min(0.3, (root.kick * 2 + root.energy * 0.4) * Math.max(0, root.s("media_Breath")) * root.drive) : 0
                }
                Rectangle { visible: root.matched; anchors.fill: parent; color: root.wash; opacity: Math.max(0, Math.min(1, root.s("media_ThemeStrength"))); Behavior on color { Tint {} } }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.16) }
                        GradientStop { position: 1; color: Qt.rgba(root.aero.r, root.aero.g, root.aero.b, 0.2) }
                    }
                }
                Loader {
                    readonly property color tint: root.flare
                    readonly property real core: 0.55
                    readonly property real rim: 0
                    readonly property real hold: 0
                    readonly property real reach: 0.5
                    active: root.fx("media_FxAura")
                    x: puck.x + puck.width / 2 - width / 2
                    y: slab.height / 2 - height / 2
                    width: slab.height * 3
                    height: width
                    opacity: Math.min(1, (0.25 + root.energy * 0.5 + root.kick * 1.6) * Math.max(0, root.s("media_Aura")))
                    scale: 1 + root.kick * 0.35
                    source: Qt.resolvedUrl("Halo.qml")
                }

                Row {
                    visible: root.s("media_Floor")
                    anchors.fill: parent
                    opacity: Math.max(0, Math.min(1, root.s("media_MiniBarOpacity")))
                    Repeater {
                        model: tiny.bars
                        Item {
                            id: rod
                            required property int index
                            readonly property real pos: index / Math.max(1, tiny.bars - 1)
                            readonly property real level: Math.min(1, Math.pow(root.levels[Math.floor(index * root.levels.length / tiny.bars)] ?? 0, 0.8) * tiny.lift * root.surge * (1 + Math.max(0, root.s("media_Treble")) * pos))
                            width: slab.width / tiny.bars
                            height: slab.height
                            Rectangle {
                                anchors.bottom: parent.bottom
                                x: parent.width * 0.15
                                width: parent.width * 0.7
                                height: Math.max(2, parent.height * 0.9 * rod.level)
                                radius: width / 2 * root.corner
                                color: root.tone(rod.pos, rod.level)
                                Behavior on height { NumberAnimation { duration: Motion.span(root.s("media_Smooth")) } }
                            }
                        }
                    }
                }
                Rectangle { visible: root.fx("media_FxTint"); anchors.fill: parent; color: root.flare; opacity: Math.min(0.5, root.kick * 3 * Math.max(0, root.s("media_Tint")) * root.drive) }

                Rectangle {
                    visible: root.lively && root.s("media_Glow")
                    anchors.centerIn: puck
                    width: puck.width * puck.scale + 6
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2 + root.kick * 6
                    border.color: root.flare
                    opacity: Math.min(1, 0.25 + root.kick * 3 + root.energy * 0.4)
                }
                Disc {
                    id: puck
                    x: tiny.pad
                    anchors.verticalCenter: parent.verticalCenter
                    width: slab.height - tiny.pad * 2
                    height: width
                    art: tiny.art
                    time: Math.max(0, root.s("media_ChangeTime"))
                    spinning: root.live && root.s("media_Spin")
                    spinTime: root.s("media_SpinTime")
                    speed: root.pace
                    plate: root.col(root.s("media_DiscColor"))
                    ink: root.tx
                    hole: root.bg
                    sign: root.glyph(root.s("media_Icon"))
                    signFont: root.iconFont
                    grooves: 2
                    scale: root.fx("media_FxPulse") ? Math.min(1.08, 1 + root.kick * Math.max(0, root.s("media_Pulse")) * 3) : 1
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.shrink(false) }
                }
                Column {
                    x: puck.x + puck.width + tiny.pad * 1.2
                    width: Math.max(0, knobs.x - x - tiny.pad)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Crawl { width: parent.width; weight: Font.DemiBold; size: root.px + 1; text: root.player ? String(root.player.trackTitle || root.word("Unknown title")) : root.word("Nothing is playing") }
                    Crawl { visible: text !== ""; width: parent.width; size: root.px - 1; level: 0.7; text: String(root.player?.trackArtist ?? "") }
                    Text { visible: root.length > 0; text: root.clock(root.position) + " / " + root.clock(root.length); font.family: root.font; font.pixelSize: root.px - 2; color: root.tx; opacity: 0.5 }
                }
                Row {
                    id: knobs
                    x: slab.width - width - tiny.pad
                    height: slab.height
                    spacing: Math.round(root.px * 0.25)
                    Key { shrink: 0.62; code: "f048"; onTapped: if (root.player && root.player.canGoPrevious) root.player.previous() }
                    Key { shrink: 0.62; strong: true; code: root.live ? "f04c" : "f04b"; onTapped: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                    Key { shrink: 0.62; code: "f051"; onTapped: if (root.player && root.player.canGoNext) root.player.next() }
                    Key { shrink: 0.62; code: "f124"; turn: 270; onTapped: root.shrink(false) }
                }
                Rectangle {
                    x: 1
                    y: 1
                    width: parent.width - 2
                    height: parent.height * 0.48
                    radius: slab.radius
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, root.s("media_FxGloss") ? 0.2 : 0.08) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 3; color: Qt.alpha(root.tx, 0.12) }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width * slab.part; height: 3; color: root.flare; Behavior on width { NumberAnimation { duration: Motion.span(Math.max(250, root.s("media_Interval"))) } } }
                Rectangle {
                    visible: root.fx("media_FxEdge")
                    anchors.fill: parent
                    radius: slab.radius
                    color: "transparent"
                    border.width: Math.max(1, root.s("media_Edge")) * (1 + root.boost)
                    border.color: root.flare
                    opacity: Math.min(1, root.kick * 3 * root.drive + root.boost * 0.25)
                }
                Rectangle {
                    visible: root.fx("media_FxFlash")
                    anchors.fill: parent
                    color: root.rainbow ? root.flare : root.peak
                    opacity: Math.min(0.6, root.flash * root.flash * Math.max(0, root.s("media_Flash")) * root.drive * root.punch)
                }
            }
        }
    }

    LazyLoader {
        active: root.open && root.s("media_Show") && !root.mini

        FloatingWindow {
            id: win
            property int mine: -1
            title: "dolphin-media"
            implicitWidth: Math.max(360, Math.round((win.screen?.width ?? 1440) * root.s("media_Width")))
            implicitHeight: Math.max(480, Math.round((win.screen?.height ?? 900) * root.s("media_Height")))
            color: root.bg
            Component.onCompleted: { mine = root.epoch; root.tries = 0; glue.restart() }
            onVisibleChanged: if (!visible && mine === root.epoch && !root.hopping) root.open = false

            Item {
                id: face
                readonly property real pad: Math.round(root.px * 1.8)
                readonly property real bar: Math.round(root.px * 3.5)
                readonly property real cardW: width - pad * 2
                readonly property real cardH: Math.round(Math.min(height * 0.32, root.px * 16))
                readonly property real head: Math.round(root.px * 1.4)
                readonly property real gap: Math.round(root.px * 0.8)
                readonly property real keysY: height - Math.round(root.px * 4.2) - pad
                readonly property real seekY: keysY - Math.round(root.px * 3)
                readonly property real free: seekY - head - words.height - gap * 3
                readonly property real discWide: Math.max(72, Math.min(width - pad * 2, root.s("media_Floor") ? Math.min(free * 0.62, free - Math.round(root.px * 4)) : free))
                readonly property real discSmall: cardH * 0.7
                readonly property real wordsY: head + discWide + gap
                readonly property real floorX: discSmall * 1.48 + cardH * 0.12
                readonly property string art: String(root.player?.trackArtUrl ?? "")
                readonly property int change: Math.max(0, root.s("media_ChangeTime"))
                property real t: root.managing ? 1 : 0
                function mix(a, b) { return a + (b - a) * t }
                anchors.fill: parent
                clip: true
                focus: true
                Component.onCompleted: forceActiveFocus()
                Behavior on t { NumberAnimation { duration: Motion.span(420); easing.type: Easing.InOutCubic } }
                Keys.onPressed: e => {
                    const p = root.player
                    const arrow = e.key === Qt.Key_Left || e.key === Qt.Key_Right || e.key === Qt.Key_Up || e.key === Qt.Key_Down
                    if (e.key === Qt.Key_Escape) { if (root.managing) root.managing = false; else root.open = false }
                    else if (root.managing && (arrow || ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) && root.at >= 0))) root.walk(e.key, page.cols)
                    else if (e.key === Qt.Key_E) { root.at = -1; root.managing = !root.managing }
                    else if (e.key === Qt.Key_M) root.shrink(true)
                    else if (e.key === Qt.Key_F) root.flip("media_Follow")
                    else if (e.key === Qt.Key_Tab) root.swap()
                    else if (!p) return
                    else if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (p.canTogglePlaying) p.togglePlaying() }
                    else if (e.key === Qt.Key_Right) { if (p.canGoNext) p.next() }
                    else if (e.key === Qt.Key_Left) { if (p.canGoPrevious) p.previous() }
                    else if (e.key === Qt.Key_Up) root.louder(1)
                    else if (e.key === Qt.Key_Down) root.louder(-1)
                    else return
                    e.accepted = true
                }

                Swatch { art: face.art }
                FrameAnimation {
                    running: root.open && Motion.on && (root.live || root.managing || root.jolt > 0 || root.flash > 0 || root.boost > 0)
                    onTriggered: {
                        const dt = Math.min(0.05, frameTime), moving = root.live || root.demo
                        if (moving) beat.tick(Date.now())
                        root.fade(dt)
                        if (moving && root.s("media_Ring") && root.s("media_RingSpin") > 0) ring.rotation = (ring.rotation + dt * 360000 / Math.max(2000, root.s("media_RingSpin"))) % 360
                        if (moving && root.fx("media_FxBeams")) rays.rotation = (rays.rotation + dt * (4 + 40 * root.energy)) % 360
                    }
                }

                Backdrop {
                    visible: root.s("media_Backdrop")
                    anchors.fill: parent
                    anchors.margins: -48
                    art: root.s("media_Backdrop") ? face.art : ""
                    time: face.change
                    opacity: Math.max(0, Math.min(1, root.s("media_BackdropOpacity")))
                    blur: root.s("media_BackdropBlur")
                    swell: root.fx("media_FxBreath") ? Math.min(0.3, (root.kick * 2 + root.energy * 0.4) * Math.max(0, root.s("media_Breath")) * root.drive) : 0
                }
                Rectangle { visible: root.matched; anchors.fill: parent; color: root.wash; opacity: Math.max(0, Math.min(1, root.s("media_ThemeStrength"))); Behavior on color { Tint {} } }
                Rectangle {
                    visible: face.t > 0
                    anchors.fill: parent
                    opacity: face.t
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(root.aero.r, root.aero.g, root.aero.b, 0.3) }
                        GradientStop { position: 0.55; color: Qt.rgba(root.aero.r, root.aero.g, root.aero.b, 0.06) }
                        GradientStop { position: 1; color: Qt.rgba(root.aero2.r, root.aero2.g, root.aero2.b, 0.18) }
                    }
                }
                Repeater {
                    model: face.t > 0 ? 7 : 0
                    Bubble {
                        required property int index
                        seed: index + 40
                        roomW: face.width
                        roomH: face.height
                        opacity: face.t * 0.7
                    }
                }

                ClippingRectangle {
                    id: lens
                    readonly property real mid: stage.x + stage.width / 2
                    readonly property real centre: stage.y + stage.height / 2
                    x: face.mix(0, face.pad)
                    y: face.mix(0, face.bar)
                    width: face.mix(face.width, face.cardW)
                    height: face.mix(face.height, face.cardH)
                    radius: face.mix(Math.max(0, root.round), Math.round(root.px * 1.3))
                    color: "transparent"
                    border.width: face.t > 0 ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.3 * face.t)

                    Rectangle {
                        visible: face.t > 0
                        anchors.fill: parent
                        opacity: face.t
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.16) }
                            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.18) }
                            GradientStop { position: 1; color: Qt.rgba(root.aero.r, root.aero.g, root.aero.b, 0.16) }
                        }
                    }

                    Loader {
                        readonly property color tint: root.flare
                        readonly property real core: 0.55
                        readonly property real rim: 0
                        readonly property real hold: 0
                        readonly property real reach: 0.5
                        active: root.fx("media_FxAura")
                        x: lens.mid - width / 2
                        y: lens.centre - height / 2
                        width: stage.width * 2
                        height: width
                        opacity: Math.min(1, (0.2 + root.energy * 0.5 + root.kick * 1.6) * Math.max(0, root.s("media_Aura")))
                        scale: 1 + root.kick * 0.35
                        source: Qt.resolvedUrl("Halo.qml")
                    }
                    Item {
                        id: rays
                        visible: root.fx("media_FxBeams")
                        x: lens.mid
                        y: lens.centre
                        opacity: Math.min(1, 0.15 + root.energy * 0.6 + root.kick)
                        Repeater {
                            model: rays.visible ? Math.max(0, Math.min(24, Math.round(root.s("media_Beams")))) : 0
                            Rectangle {
                                required property int index
                                x: -width / 2
                                y: -height
                                width: stage.width * 0.1
                                height: stage.width * 1.5
                                transformOrigin: Item.Bottom
                                rotation: index * 360 / Math.max(1, Math.round(root.s("media_Beams")))
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.rgba(root.flare.r, root.flare.g, root.flare.b, 0) }
                                    GradientStop { position: 1; color: Qt.rgba(root.flare.r, root.flare.g, root.flare.b, 0.32) }
                                }
                            }
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxStars") ? Math.max(0, Math.min(120, Math.round(root.s("media_Stars")))) : 0
                        Rectangle {
                            required property int index
                            readonly property real level: root.levels[(index * 7 + 5) % root.count] ?? 0
                            x: lens.width * root.rand(index, 7)
                            y: lens.height * root.rand(index, 8)
                            width: 2 + index % 2
                            height: width
                            radius: width / 2 * root.corner
                            color: index % 3 ? root.tx : root.flare
                            opacity: Math.min(1, level * level * 2.2)
                            scale: 1 + level
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxBubbles") ? Math.max(0, Math.min(40, Math.round(root.s("media_Bubbles")))) : 0
                        Bubble {
                            required property int index
                            seed: index
                            roomW: lens.width
                            roomH: lens.height
                            opacity: 0.8
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxSpot") ? Math.max(0, Math.min(6, Math.round(root.s("media_Spots")))) : 0
                        Loader {
                            required property int index
                            readonly property color tint: root.rainbow ? Qt.hsla((root.hue + index * 0.31) % 1, 0.9, 0.6, 1) : index % 2 ? root.hi : root.flare
                            readonly property real core: 0.4
                            readonly property real rim: 0
                            readonly property real hold: 0
                            readonly property real reach: 0.5
                            width: Math.max(lens.width, lens.height) * 0.8
                            height: width
                            x: lens.width * (0.5 + 0.42 * Math.sin(root.drift * (6 + index * 2.3) + index * 2)) - width / 2
                            y: lens.height * (0.42 + 0.34 * Math.cos(root.drift * (5 + index * 1.7) + index)) - height / 2
                            opacity: Math.min(0.85, 0.12 + root.energy * 0.5 + root.kick)
                            source: Qt.resolvedUrl("Halo.qml")
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxLasers") ? Math.max(0, Math.min(16, Math.round(root.s("media_Lasers")))) : 0
                        Rectangle {
                            required property int index
                            readonly property bool east: index % 2 === 1
                            readonly property color ray: root.rainbow ? Qt.hsla((root.hue + index * 0.13) % 1, 0.9, 0.6, 1) : index % 3 === 2 ? root.hi : root.flare
                            x: (east ? lens.width : 0) - width / 2
                            y: lens.height - height
                            width: 2 + root.boost * 3
                            height: Math.hypot(lens.width, lens.height)
                            transformOrigin: Item.Bottom
                            rotation: (east ? -1 : 1) * (40 + Math.sin(root.drift * (18 + index * 3) + index * 1.7) * 32 + root.boost * root.side * 8)
                            antialiasing: true
                            opacity: Math.min(0.9, 0.1 + root.energy * 0.5 + root.kick * 1.5)
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.rgba(ray.r, ray.g, ray.b, 0) }
                                GradientStop { position: 1; color: ray }
                            }
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxEmbers") ? Math.max(0, Math.min(120, Math.round(root.s("media_Embers")))) : 0
                        Rectangle {
                            required property int index
                            readonly property real go: (root.rand(index, 22) + root.drift * (1 + root.rand(index, 21) * 2.2)) % 1
                            x: lens.width * root.rand(index, 23) + Math.sin(go * 12 + index) * 14
                            y: lens.height * (1 - go)
                            width: 2 + index % 3
                            height: width
                            radius: width / 2 * root.corner
                            color: index % 4 ? root.flare : root.tx
                            opacity: Math.sin(go * Math.PI) * Math.min(1, 0.35 + root.energy)
                        }
                    }
                    Rectangle {
                        readonly property real bass: ((root.levels[0] ?? 0) + (root.levels[1] ?? 0) + (root.levels[2] ?? 0)) / 3
                        visible: root.fx("media_FxFloorGlow")
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * Math.min(0.9, (0.1 + bass * 0.7 + root.kick * 1.2) * Math.max(0, root.s("media_FloorGlow")) * 1.6)
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.rgba(root.flare.r, root.flare.g, root.flare.b, 0) }
                            GradientStop { position: 1; color: Qt.rgba(root.flare.r, root.flare.g, root.flare.b, 0.6) }
                        }
                        Behavior on height { NumberAnimation { duration: Motion.span(90) } }
                    }
                    Rectangle { visible: root.fx("media_FxTint"); anchors.fill: parent; color: root.flare; opacity: Math.min(0.6, root.kick * 3 * Math.max(0, root.s("media_Tint")) * root.drive) }
                    Rectangle { anchors.fill: parent; color: "#000000"; opacity: Math.min(0.5, root.charge * 0.4); Behavior on opacity { NumberAnimation { duration: Motion.span(160) } } }

                    Item {
                        id: scene
                        width: parent.width
                        height: parent.height
                        x: root.shakeX
                        y: root.shakeY
                        scale: 1 + (root.fx("media_FxZoom") ? root.boost * Math.max(0, root.s("media_Zoom")) * root.drive : 0)
                        rotation: root.fx("media_FxTilt") ? root.side * root.boost * root.s("media_Tilt") * root.drive * (root.punch >= 1 ? root.punch : 0.4) : 0

                        Item {
                            id: stage
                            readonly property real squeeze: 1 - Math.min(0.12, root.charge * 0.08)
                            property real hop: 1
                            x: face.mix((face.width - face.discWide) / 2, face.cardH * 0.16)
                            y: face.mix(face.head, (face.cardH - face.discSmall) / 2)
                            width: face.mix(face.discWide, face.discSmall)
                            height: width
                            scale: hop * squeeze

                            NumberAnimation { id: jump; target: stage; property: "hop"; from: 1 + Math.max(0, root.s("media_Bounce")) * root.drive * root.punch; to: 1; duration: Motion.span(420); easing.type: Easing.OutBack }
                            Connections {
                                target: root
                                function onStruck() { if (root.s("media_FxBounce")) jump.restart() }
                            }

                            Repeater {
                                model: root.fx("media_FxSparks") ? Math.max(0, Math.min(80, Math.round(root.s("media_Sparks")))) : 0
                                Rectangle {
                                    id: spark
                                    required property int index
                                    property real turn: 0
                                    property real far: 0.3
                                    property real go: 0
                                    width: Math.max(2, Math.round(stage.width * 0.012))
                                    height: width * (1 + (index % 3))
                                    radius: width / 2 * root.corner
                                    rotation: turn * 180 / Math.PI + 90
                                    x: stage.width / 2 + Math.cos(turn) * stage.width * (0.52 + go * far) - width / 2
                                    y: stage.height / 2 + Math.sin(turn) * stage.height * (0.52 + go * far) - height / 2
                                    color: root.rainbow ? Qt.hsla((root.hue + index * 0.07) % 1, 0.9, 0.6, 1) : index % 2 ? root.peak : root.beam
                                    opacity: 0
                                    ParallelAnimation {
                                        id: fly
                                        NumberAnimation { target: spark; property: "go"; from: 0; to: 1; duration: Motion.span(520 + spark.index % 5 * 70); easing.type: Easing.OutCubic }
                                        NumberAnimation { target: spark; property: "opacity"; from: 1; to: 0; duration: Motion.span(520 + spark.index % 5 * 70); easing.type: Easing.InQuad }
                                    }
                                    Connections {
                                        target: root
                                        function onStruck() {
                                            const many = Math.max(0.15, Math.min(1, root.punch / 1.6 * (0.4 + 0.6 * root.energy))) * Math.round(root.s("media_Sparks"))
                                            if (spark.index >= many) return
                                            spark.turn = Math.random() * Math.PI * 2
                                            spark.far = (0.12 + Math.random() * 0.3) * Math.min(1.6, root.punch * root.drive)
                                            fly.restart()
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: root.fx("media_FxWaves") ? Math.max(0, Math.min(6, Math.round(root.s("media_Waves")))) : 0
                                Rectangle {
                                    id: wave
                                    required property int index
                                    anchors.centerIn: parent
                                    width: stage.width * 1.02
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.width: 2
                                    border.color: root.flare
                                    opacity: 0
                                    SequentialAnimation {
                                        id: burst
                                        PauseAnimation { duration: Motion.span(wave.index * 90) }
                                        ParallelAnimation {
                                            NumberAnimation { target: wave; property: "scale"; from: 1; to: 1.12 + (0.06 + wave.index * 0.05) * Math.min(2.4, root.drive * root.punch); duration: Motion.span(600); easing.type: Easing.OutCubic }
                                            NumberAnimation { target: wave; property: "opacity"; from: 0.8; to: 0; duration: Motion.span(600); easing.type: Easing.OutCubic }
                                        }
                                    }
                                    Connections {
                                        target: root
                                        function onStruck() { if (root.punch >= 1 || wave.index === 0) burst.restart() }
                                    }
                                }
                            }

                            Repeater {
                                model: root.fx("media_FxOrbits") ? Math.max(0, Math.min(8, Math.round(root.s("media_Orbits")))) : 0
                                Rectangle {
                                    required property int index
                                    readonly property real turn: root.drift * 40 * (1 + index * 0.35) + index * 2.1
                                    readonly property real far: stage.width * (0.55 + index * 0.045) * (1 + root.kick * 0.2)
                                    width: Math.max(4, Math.round(stage.width * 0.022))
                                    height: width
                                    radius: width / 2
                                    x: stage.width / 2 + Math.cos(turn) * far - width / 2
                                    y: stage.height / 2 + Math.sin(turn) * far - height / 2
                                    color: index % 2 ? root.peak : root.flare
                                }
                            }

                            Item {
                                id: ring
                                readonly property real reach: Math.max(0.02, root.s("media_RingLength"))
                                readonly property real inset: 0.16 - Math.max(0, Math.min(0.1, root.s("media_RingGap")))
                                anchors.fill: parent
                                Repeater {
                                    model: root.s("media_Ring") ? root.count : 0
                                    Item {
                                        id: spoke
                                        required property int index
                                        readonly property real level: Math.min(1, (root.levels[index] ?? 0) * root.gain)
                                        anchors.fill: parent
                                        rotation: index * 360 / root.count
                                        Rectangle {
                                            x: (parent.width - width) / 2
                                            y: parent.height * ring.inset - height
                                            width: Math.max(2, Math.PI * parent.width * 0.7 / root.count * Math.max(0.1, Math.min(1, root.s("media_RingWidth"))))
                                            height: parent.height * (0.008 + ring.reach * spoke.level)
                                            radius: width / 2 * root.corner
                                            color: root.tone(spoke.index / root.count, spoke.level)
                                            opacity: 0.4 + 0.6 * spoke.level
                                            Behavior on height { NumberAnimation { duration: Motion.span(root.s("media_Smooth")) } }
                                        }
                                    }
                                }
                            }

                            Shape {
                                visible: root.fx("media_FxCharge") && root.charge > 0.02
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: root.flare
                                    strokeWidth: Math.max(2, stage.width * 0.012)
                                    fillColor: "transparent"
                                    capStyle: root.corner > 0 ? ShapePath.RoundCap : ShapePath.FlatCap
                                    PathAngleArc { centerX: stage.width / 2; centerY: stage.height / 2; radiusX: stage.width * 0.33; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * Math.min(1, root.charge) }
                                }
                            }

                            Disc {
                                id: vinyl
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: width
                                art: face.art
                                time: face.change
                                spinning: root.open && (root.live || root.demo) && root.s("media_Spin")
                                spinTime: root.s("media_SpinTime")
                                speed: root.pace + (root.fx("media_FxSpinKick") ? root.boost * Math.max(0, root.s("media_SpinKick")) * root.drive : 0) + root.charge * 2 - (root.fx("media_FxScratch") ? Math.max(0, root.boost - 0.6) * 9 : 0)
                                plate: root.col(root.s("media_DiscColor"))
                                ink: root.tx
                                hole: root.bg
                                sign: root.glyph(root.s("media_Icon"))
                                signFont: root.iconFont
                                grooves: 4
                                scale: root.fx("media_FxPulse") ? Math.min(1.12, 1 + root.kick * Math.max(0, root.s("media_Pulse")) * 4 * root.drive) : 1
                                transform: Rotation {
                                    origin.x: vinyl.width / 2
                                    origin.y: vinyl.height / 2
                                    axis.x: Math.cos(root.aim)
                                    axis.y: Math.sin(root.aim)
                                    axis.z: 0
                                    angle: root.fx("media_FxWobble") ? Math.min(40, root.boost * root.s("media_Wobble") * Math.min(2, root.drive)) : 0
                                }
                            }
                            Rectangle {
                                visible: root.s("media_FxGloss")
                                anchors.centerIn: parent
                                width: vinyl.width
                                height: width
                                radius: width / 2
                                scale: vinyl.scale
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.34) }
                                    GradientStop { position: 0.48; color: Qt.rgba(1, 1, 1, 0.04) }
                                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                                }
                            }
                            Rectangle {
                                visible: root.fx("media_Glow")
                                anchors.centerIn: parent
                                width: vinyl.width
                                height: width
                                radius: width / 2
                                scale: vinyl.scale
                                color: "transparent"
                                border.width: Math.max(2, Math.round(width * 0.02))
                                border.color: root.flare
                                opacity: Math.min(1, root.kick * 4 * root.drive + root.charge * 0.6)
                            }
                        }

                        Column {
                            id: words
                            visible: opacity > 0
                            opacity: Math.max(0, 1 - face.t * 2)
                            x: face.pad
                            y: face.wordsY
                            width: face.width - face.pad * 2
                            spacing: 4
                            Item {
                                width: parent.width
                                height: title.height
                                scale: 1 + (root.fx("media_FxTitle") ? root.boost * Math.max(0, root.s("media_TitleKick")) * root.drive : 0)
                                Text { visible: root.fx("media_FxGlitch") && root.boost > 0.55; x: -(root.boost - 0.5) * root.s("media_Glitch") * root.drive; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: title.text; font: title.font; color: "#ff2a6d"; opacity: 0.7 }
                                Text { visible: root.fx("media_FxGlitch") && root.boost > 0.55; x: (root.boost - 0.5) * root.s("media_Glitch") * root.drive; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: title.text; font: title.font; color: "#05d9e8"; opacity: 0.7 }
                                Fade { id: title; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; time: face.change / 2; want: root.player ? String(root.player.trackTitle || root.word("Unknown title")) : root.word("Nothing is playing"); font.family: root.font; font.pixelSize: root.px + 7; font.weight: Font.DemiBold; color: root.tx }
                            }
                            Fade { visible: text !== ""; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; time: face.change / 2; level: 0.6; want: root.player ? [root.player.trackArtist, root.player.trackAlbum].filter(t => !!t).join("  ·  ") : ""; font.family: root.font; font.pixelSize: root.px + 1; color: root.tx }
                            Text {
                                visible: root.list.length > 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: String(root.player?.identity ?? "") + "  " + (root.list.indexOf(root.player) + 1) + "/" + root.list.length
                                font.family: root.font
                                font.pixelSize: root.px - 1
                                color: root.tx
                                opacity: originArea.containsMouse ? 1 : 0.5
                                MouseArea { id: originArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; onClicked: root.swap() }
                            }
                            Text { visible: root.missing; width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: root.word("Install the cava package to see the bars."); font.family: root.font; font.pixelSize: root.px; color: root.hi }
                        }

                        Item {
                            id: floor
                            readonly property string style: String(root.s("media_FloorStyle"))
                            readonly property real mirror: style === "middle" || !root.s("media_FxReflection") ? 0 : Math.max(0, Math.min(0.6, root.s("media_Reflection")))
                            readonly property real tall: height * (1 - mirror)
                            readonly property int steps: Math.max(3, Math.min(40, Math.round(root.s("media_Blocks"))))
                            readonly property real lift: Math.max(0, root.s("media_FloorGain")) * root.gain
                            readonly property real treble: Math.max(0, root.s("media_Treble"))
                            readonly property bool trails: root.fx("media_FxTrails")
                            readonly property bool split: root.s("media_FxVoice") && root.bands.voice.length > 1 && root.bands.sound.length > 1
                            readonly property real wideY: words.y + words.height + face.gap
                            visible: root.s("media_Floor")
                            x: face.mix(face.pad, face.floorX)
                            y: face.mix(wideY, face.cardH * 0.24)
                            width: face.mix(face.width - face.pad * 2, Math.max(40, face.cardW - face.floorX - Math.round(root.px * 1.4)))
                            height: face.mix(Math.max(0, face.seekY - wideY - face.gap), face.cardH * 0.52)

                            Rectangle {
                                visible: root.fx("media_FxHaze")
                                width: parent.width
                                height: floor.tall
                                opacity: Math.min(1, root.energy * Math.max(0, root.s("media_Haze")) * (1 + root.boost))
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(root.flare.r, root.flare.g, root.flare.b, 0.55) }
                                }
                            }
                            Row {
                                Repeater {
                                    model: floor.visible ? root.count : 0
                                    Item {
                                        id: lane
                                        required property int index
                                        readonly property int from: root.s("media_Mirror") ? Math.abs(index * 2 - root.count + 1) >> 1 : index
                                        readonly property real pos: from / Math.max(1, root.count - 1)
                                        readonly property real wash: root.swell > 0 ? root.swell * Math.exp(-Math.pow((pos - root.front) / 0.12, 2)) : 0
                                        readonly property int tap: floor.split ? root.bands.sound[Math.round(pos * (root.bands.sound.length - 1))] : from
                                        readonly property real voice: floor.split ? Math.min(1, Math.pow(root.levels[root.bands.voice[Math.round(pos * (root.bands.voice.length - 1))]] ?? 0, 0.8) * floor.lift * 1.25) : 0
                                        readonly property real level: Math.min(1, Math.pow(root.levels[tap] ?? 0, 0.8) * floor.lift * (1 + floor.treble * pos) + wash)
                                        readonly property real wide: width * Math.max(0.1, Math.min(1, root.s("media_FloorWidth")))
                                        readonly property real rise: floor.style === "blocks" ? Math.round(level * floor.steps) / floor.steps : level
                                        readonly property color ink: root.tone(pos, level)
                                        property real ghost: 0
                                        width: floor.width / root.count
                                        height: floor.height
                                        onRiseChanged: {
                                            if (!floor.trails) return
                                            if (rise >= ghost) { sink.stop(); ghost = rise }
                                            else if (!sink.running) sink.restart()
                                        }
                                        NumberAnimation { id: sink; target: lane; property: "ghost"; to: 0; duration: Motion.span(Math.max(60, root.s("media_Trail"))); easing.type: Easing.InQuad }
                                        Rectangle {
                                            visible: floor.trails && lane.ghost > lane.rise
                                            x: post.x
                                            y: floor.style === "middle" ? (floor.tall - height) / 2 : floor.tall - height
                                            width: post.width
                                            height: floor.tall * lane.ghost
                                            radius: post.radius
                                            color: lane.ink
                                            opacity: 0.25
                                        }
                                        Rectangle {
                                            id: post
                                            x: (parent.width - width) / 2
                                            y: floor.style === "middle" ? (floor.tall - height) / 2 : floor.tall - height
                                            width: lane.wide
                                            height: Math.max(2, floor.tall * lane.rise)
                                            radius: width / 2 * root.corner
                                            color: lane.ink
                                            opacity: 0.45 + 0.55 * lane.level
                                            Behavior on height { NumberAnimation { duration: Motion.span(root.s("media_Smooth")) } }
                                        }
                                        Rectangle {
                                            visible: floor.split
                                            x: (parent.width - width) / 2
                                            y: floor.style === "middle" ? (floor.tall - height) / 2 : floor.tall - height
                                            width: Math.max(1, post.width * 0.5)
                                            height: Math.max(2, floor.tall * lane.voice)
                                            radius: width / 2 * root.corner
                                            color: root.rainbow ? root.tone((lane.pos + 0.5) % 1, lane.voice) : root.peak
                                            opacity: 0.9
                                            Behavior on height { NumberAnimation { duration: Motion.span(root.s("media_Smooth")) } }
                                        }
                                        Rectangle {
                                            visible: floor.mirror > 0
                                            x: post.x
                                            y: floor.tall + 2
                                            width: post.width
                                            height: Math.max(0, (floor.height - floor.tall - 2) * lane.rise)
                                            radius: post.radius
                                            color: lane.ink
                                            opacity: 0.22 * lane.level
                                        }
                                    }
                                }
                            }
                            Repeater {
                                model: floor.visible && floor.style === "blocks" ? floor.steps - 1 : 0
                                Rectangle {
                                    required property int index
                                    y: floor.tall * (index + 1) / floor.steps - 1
                                    width: floor.width
                                    height: 2
                                    color: root.bg
                                }
                            }
                        }

                        Item {
                            id: seek
                            readonly property real part: root.length > 0 ? Math.max(0, Math.min(1, root.position / root.length)) : 0
                            visible: opacity > 0
                            opacity: Math.max(0, 1 - face.t * 2)
                            x: face.pad
                            y: face.seekY
                            width: face.width - face.pad * 2
                            height: Math.round(root.px * 2.6)
                            Rectangle { y: 5; width: parent.width; height: 2; color: Qt.alpha(root.tx, 0.14) }
                            Rectangle { y: 5; width: parent.width * seek.part; height: 2; color: root.hi; Behavior on width { NumberAnimation { duration: Motion.span(face.change / 2); easing.type: Easing.OutCubic } } }
                            Rectangle { visible: seekArea.containsMouse || seekArea.pressed; x: parent.width * seek.part - width / 2; y: 6 - height / 2; width: 10; height: 10; radius: 5; color: root.hi }
                            MouseArea {
                                id: seekArea
                                y: -4
                                width: parent.width
                                height: 20
                                hoverEnabled: true
                                onClicked: m => { if (root.player && root.player.canSeek && root.length > 0) root.player.position = Math.max(0, Math.min(1, m.x / width)) * root.length }
                            }
                            Text { y: 16; text: root.clock(root.position); font.family: root.font; font.pixelSize: root.px - 1; color: root.tx; opacity: 0.5 }
                            Text { y: 16; anchors.right: parent.right; text: root.length > 0 ? root.clock(root.length) : ""; font.family: root.font; font.pixelSize: root.px - 1; color: root.tx; opacity: 0.5 }
                        }

                        Row {
                            id: buttons
                            visible: opacity > 0
                            opacity: Math.max(0, 1 - face.t * 2)
                            x: (face.width - width) / 2
                            y: face.keysY
                            height: Math.round(root.px * 4.2)
                            spacing: Math.round(root.px * 1.4)
                            Key { code: "f048"; onTapped: if (root.player && root.player.canGoPrevious) root.player.previous() }
                            Key { strong: true; code: root.live ? "f04c" : "f04b"; onTapped: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                            Key { code: "f051"; onTapped: if (root.player && root.player.canGoNext) root.player.next() }
                        }
                    }

                    Repeater {
                        model: root.fx("media_FxConfetti") ? Math.max(0, Math.min(120, Math.round(root.s("media_Confetti")))) : 0
                        Rectangle {
                            id: bit
                            required property int index
                            property real spot: 0.5
                            property real twirl: 360
                            property real go: 0
                            width: 5 + index % 4
                            height: Math.max(3, width * 0.6)
                            radius: root.corner
                            x: lens.width * spot + Math.sin(go * 9 + index) * 18 - width / 2
                            y: go * (lens.height + 24) - 12
                            rotation: go * twirl
                            color: Qt.hsla((index * 0.13) % 1, 0.85, 0.6, 1)
                            opacity: go > 0 && go < 1 ? 1 : 0
                            NumberAnimation { id: fall; target: bit; property: "go"; from: 0; to: 1; duration: Motion.span(1200 + bit.index % 7 * 170); easing.type: Easing.InQuad }
                            Connections {
                                target: root
                                function onStruck() {
                                    if (root.punch < 1) return
                                    bit.spot = Math.random()
                                    bit.twirl = 360 + Math.random() * 720
                                    fall.restart()
                                }
                            }
                        }
                    }

                    Loader {
                        readonly property color tint: "#000000"
                        readonly property real core: 0
                        readonly property real rim: Math.max(0, Math.min(1, root.s("media_Vignette")))
                        readonly property real hold: 0.5
                        readonly property real reach: 0.72
                        active: root.fx("media_FxVignette")
                        anchors.fill: parent
                        opacity: Math.max(0.3, 1 - root.kick * 2.5)
                        source: Qt.resolvedUrl("Halo.qml")
                    }
                    Canvas {
                        visible: root.fx("media_FxScan")
                        anchors.fill: parent
                        opacity: Math.max(0, Math.min(1, root.s("media_Scan")))
                        onPaint: {
                            const g = getContext("2d")
                            g.clearRect(0, 0, width, height)
                            g.fillStyle = "#000000"
                            for (let y = 0; y < height; y += 3) g.fillRect(0, y, width, 1)
                        }
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()
                        Rectangle {
                            width: parent.width
                            height: parent.height * 0.2
                            y: ((root.drift * 4) % 1.4 - 0.2) * parent.height
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0) }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.5) }
                                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                            }
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxCorners") ? 4 : 0
                        Item {
                            id: nook
                            required property int index
                            readonly property real arm: Math.round(root.px * 2.2 * Math.max(0.3, root.s("media_Corners")))
                            readonly property real inset: Math.round(root.px * 1.1 + root.boost * root.px * 1.4 * root.drive)
                            readonly property bool east: index % 2 === 1
                            readonly property bool south: index >= 2
                            x: east ? lens.width - inset - arm : inset
                            y: south ? lens.height - inset - arm : inset
                            width: arm
                            height: arm
                            opacity: Math.min(1, 0.35 + root.kick * 3 + root.boost * 0.5)
                            Rectangle { y: nook.south ? nook.arm - 2 : 0; width: nook.arm; height: 2; color: root.flare }
                            Rectangle { x: nook.east ? nook.arm - 2 : 0; width: 2; height: nook.arm; color: root.flare }
                        }
                    }
                    Repeater {
                        model: root.fx("media_FxBolt") ? Math.max(0, Math.min(5, Math.round(root.s("media_Bolts")))) : 0
                        Shape {
                            id: bolt
                            required property int index
                            property var dots: [Qt.point(0, 0), Qt.point(0, 0)]
                            property real glow: 0
                            anchors.fill: parent
                            visible: glow > 0
                            opacity: glow * (Math.floor(glow * 11) % 3 === 1 ? 0.3 : 1)
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: root.rainbow ? root.flare : root.peak
                                strokeWidth: 1.5 + bolt.glow * 2.5
                                fillColor: "transparent"
                                PathPolyline { path: bolt.dots }
                            }
                            NumberAnimation { id: zap; target: bolt; property: "glow"; from: 1; to: 0; duration: Motion.span(420 + bolt.index * 90); easing.type: Easing.OutQuad }
                            Connections {
                                target: root
                                function onStruck() {
                                    if (root.punch < 1) return
                                    const out = [], steps = 9 + Math.floor(Math.random() * 5), reach = lens.height * (0.55 + Math.random() * 0.45)
                                    let x = lens.width * (0.15 + Math.random() * 0.7)
                                    for (let i = 0; i <= steps; i++) {
                                        out.push(Qt.point(x, reach * i / steps))
                                        x = Math.max(4, Math.min(lens.width - 4, x + (Math.random() - 0.5) * lens.width * 0.16))
                                    }
                                    bolt.dots = out
                                    zap.restart()
                                }
                            }
                        }
                    }
                    Rectangle {
                        visible: root.fx("media_FxEdge")
                        anchors.fill: parent
                        radius: lens.radius
                        color: "transparent"
                        border.width: Math.max(1, root.s("media_Edge")) * (1 + root.boost)
                        border.color: root.flare
                        opacity: Math.min(1, root.kick * 3 * root.drive + root.boost * 0.25)
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: root.rainbow ? root.flare : root.peak
                        opacity: Math.min(0.8, root.flash * root.flash * Math.max(0, root.s("media_Flash")) * root.drive * root.punch) * (root.s("media_FxStrobe") && Math.floor(root.flash * 9) % 2 ? 0.15 : 1) * (root.s("media_FxStrobe") ? 2 : 1)
                    }
                    Text { visible: face.t > 0; opacity: face.t * 0.55; x: Math.round(root.px * 0.9); y: Math.round(root.px * 0.6); text: root.word("Preview"); font.family: root.font; font.pixelSize: root.px - 2; color: root.tx }
                }

                Row {
                    visible: face.t > 0
                    opacity: face.t
                    x: face.pad
                    y: Math.round((face.bar - height) / 2)
                    spacing: Math.round(root.px * 0.6)
                    Pill { code: "f08d"; label: "Follow"; lit: root.follow; marked: root.at === 0; onTapped: root.flip("media_Follow") }
                    Pill { code: "f0d0"; label: "Effects"; lit: root.s("media_Effects"); marked: root.at === 1; onTapped: root.flip("media_Effects") }
                }
                Row {
                    x: face.width - width - face.pad
                    y: Math.round((face.bar - height) / 2)
                    spacing: Math.round(root.px * 0.6)
                    Pill { visible: root.managing; code: "f0e2"; onTapped: root.restore() }
                    Pill { visible: !root.managing; code: "f124"; turn: 90; onTapped: root.shrink(true) }
                    Pill { code: root.managing ? "f00d" : "f013"; lit: root.managing; onTapped: root.managing = !root.managing }
                }

                Flickable {
                    id: page
                    readonly property real edge: face.bar + face.cardH + Math.round(root.px * 0.9)
                    readonly property int cols: width > root.px * 34 ? 2 : 1
                    visible: face.t > 0.01
                    opacity: face.t
                    x: face.pad
                    y: edge + (1 - face.t) * 40
                    width: face.cardW
                    height: Math.max(0, face.height - edge - Math.round(root.px * 0.9))
                    contentHeight: pageCol.height
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    function bring(item) {
                        const y = item.mapToItem(pageCol, 0, 0).y
                        if (y < contentY) contentY = Math.max(0, y - 8)
                        else if (y + item.height > contentY + height) contentY = Math.min(Math.max(0, contentHeight - height), y + item.height - height + 8)
                    }

                    Column {
                        id: pageCol
                        width: page.width
                        spacing: Math.round(root.px * 0.9)

                        Repeater {
                            model: root.groups
                            Glass {
                                id: card
                                required property var modelData
                                width: pageCol.width
                                height: cardCol.height + Math.round(root.px * 1.8)
                                Column {
                                    id: cardCol
                                    x: Math.round(root.px * 0.7)
                                    y: Math.round(root.px * 0.9)
                                    width: parent.width - x * 2
                                    spacing: Math.round(root.px * 0.2)
                                    Row {
                                        x: Math.round(root.px * 0.6)
                                        height: Math.round(root.px * 2.4)
                                        spacing: Math.round(root.px * 0.7)
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Math.round(root.px * 1.9)
                                            height: width
                                            radius: width / 2
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.6)
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: Qt.lighter(root.aero, 1.35) }
                                                GradientStop { position: 1; color: Qt.darker(root.aero, 1.5) }
                                            }
                                            Sheen { strength: 0.6 }
                                            Text { anchors.centerIn: parent; text: root.glyph(String(card.modelData.code)); font.family: root.iconFont; font.pixelSize: root.px - 2; color: root.onAero }
                                        }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.word(String(card.modelData.title)); font.family: root.font; font.pixelSize: root.px + 2; font.weight: Font.DemiBold; color: root.tx }
                                    }
                                    Flow {
                                        width: parent.width
                                        Repeater {
                                            model: card.modelData.items
                                            Line {
                                                id: entry
                                                required property var modelData
                                                width: Math.floor(cardCol.width / page.cols)
                                                key: String(modelData[0])
                                                label: String(modelData[1])
                                                onReached: page.bring(entry)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    visible: page.visible && page.contentHeight > page.height
                    x: page.x + page.width + 4
                    y: page.y + page.height * page.visibleArea.yPosition
                    width: 3
                    height: Math.max(20, page.height * page.visibleArea.heightRatio)
                    radius: 1.5
                    color: Qt.rgba(1, 1, 1, 0.45)
                    opacity: face.t
                }
            }
        }
    }
}
