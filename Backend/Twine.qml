import Quickshell
import QtQuick
import "../Data/Dynamic"

Scope {
    id: twine

    required property var cfg
    required property string name
    property var words: ({})
    property var store: null
    property var screen: null
    property bool hovered: false
    property bool hold: false
    property bool busy: false
    property real heldAt: 0
    function now() { return Date.now() }
    property real viewWidth: 0
    property real viewHeight: 0
    property int peekTime: 1000

    function setting(key, prefix) { return cfg?.[(prefix ?? name + "_") + key] }
    function global(key) { return cfg?.["dolphin_" + key] }
    function title(t) { return String(t).split("+").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join("+") }
    function shows(widget) { return cfg?.["widget_" + widget + "Show"] !== false }
    function tone(c) {
        const set = Config.tones
        return set?.[c] ?? set?.[title(c)] ?? (String(c).startsWith("#") ? c : "#000000")
    }
    function color(key, prefix) { return tone(setting(key, prefix) ?? "") }
    function save(key, value) { if (store) store.set(key, value) }

    readonly property string lang: global("Language") ?? "en"
    readonly property var locales: ({ en: "en_US", ru: "ru_RU", sr: "sr_RS", vi: "vi_VN", zh: "zh_CN", ja: "ja_JP", ko: "ko_KR", fi: "fi_FI" })
    readonly property var locale: Qt.locale(locales[lang] ?? "en_US")
    function word(k) { return words?.[k]?.[lang] ?? k }

    property var widgets: ({})
    property string litGroup: ""
    readonly property var groups: buildGroups()

    function register(key, item) {
        const w = Object.assign({}, widgets)
        w[key] = item
        widgets = w
    }
    property var staged: []
    function stage(job) {
        staged = staged.concat([job])
        stager.restart()
    }
    function unregister(key) {
        const w = Object.assign({}, widgets)
        delete w[key]
        widgets = w
    }
    function buildGroups() {
        const keys = Object.keys(widgets), root = {}, sets = {}
        const find = k => root[k] === k ? k : (root[k] = find(root[k]))
        for (const k of keys) root[k] = k
        for (const k of keys)
            for (const o of widgets[k].grouped) {
                const t = String(o).toLowerCase()
                if (t in root) root[find(k)] = find(t)
            }
        for (const k of keys) (sets[find(k)] = sets[find(k)] || []).push(k)
        const names = Object.keys(cfg?.GroupedPanels ?? {})
        const canon = k => k.toLowerCase().split("+").sort().join("+")
        return Object.keys(sets).map(r => sets[r])
            .filter(m => m.length > 1 || widgets[m[0]].page || widgets[m[0]].hot)
            .map(m => {
                const plainId = m.sort().join("+")
                const id = names.find(k => canon(k) === plainId) ?? title(plainId)
                return { id: id, members: id.toLowerCase().split("+"), paged: m.some(k => !!widgets[k].page) }
            })
    }
    function groupOf(key) {
        const g = groups.find(g => g.members.includes(key))
        return g ? g.id : ""
    }
    readonly property var panelBase: ({
        Width: 13, Height: 27, Scale: 1, Gap: 0.3, SlideTime: 200,
        Color: "Background", TextColor: "Text", ActiveColor: "Active", TabColor: "Inactive", PillColor: "Inactive",
        Border: true, BorderSize: 2, BorderRadius: 0.4, BorderColor: "Accent2"
    })
    function panel(id, key) {
        const p = cfg?.GroupedPanels, v = p?.[id]?.[key], d = p?.Default?.[key] ?? panelBase[key]
        return typeof v === typeof d ? v : d
    }
    function panelColor(id, key) { return tone(panel(id, key) ?? "") }

    readonly property string posT: ["top", "bottom", "right", "left"][setting("Position")] ?? "top"
    property string pos: "top"
    property bool turning: false
    readonly property bool vert: pos === "left" || pos === "right"
    readonly property bool far: pos === "bottom" || pos === "right"
    readonly property bool top: pos !== "bottom"
    readonly property bool bottom: pos !== "top"
    readonly property bool left: pos !== "right"
    readonly property bool right: pos !== "left"
    readonly property int type: setting("Type")
    readonly property real across: !screen ? 0 : vert ? screen.width : screen.height
    readonly property real along: !screen ? 0 : vert ? screen.height : screen.width
    readonly property real ref: !screen ? 0 : Math.min(screen.width, screen.height)
    readonly property real wide: !screen ? 0 : Math.max(screen.width, screen.height)
    readonly property real tThick: Math.round(ref * setting("Height") / 2) * 2
    readonly property real tGap: Math.round(ref * setting("TopMargin"))
    readonly property bool wrap: type === 0 && tGap === 0
    readonly property real tRad: type === 1 ? tThick * Math.max(0, Math.min(setting("Radius"), 0.5)) : 0
    readonly property real tHang: wrap ? Math.round(tThick / 2) : 0
    property real thick: tThick
    property real gap: tGap
    property real rad: tRad
    property real hang: tHang
    property real flare: tHang * setting("WrapStretch")
    property real m1: Math.round(along * setting("LeftSideMargin"))
    property real m2: Math.round(along * setting("RightSideMargin"))
    readonly property color base: color("Color")
    property color fill: Qt.alpha(base, 1 - setting("Transparency"))
    readonly property real depth: gap + thick + hang
    readonly property real size: Math.ceil(Math.max(depth, tGap + tThick + tHang))

    property bool peek: false
    property real present: 1
    readonly property bool pinned: setting("Pinned") === true
    readonly property bool open: hovered || hold || peek || pinned || Reveal.all
    property real shown: open ? 1 : 0
    readonly property real reach: open ? gap + thick : 1
    property real core: 0
    readonly property var sides: {
        const out = {}
        if (!vert || setting("SideAuto") === false) return out
        const all = Object.keys(widgets).map(k => widgets[k]).filter(w => !w.ghost).sort((a, b) => a.order - b.order)
        const len = along - m1 - m2, half = wide / Math.max(1, tThick) / 2
        const gap = thick * (setting("SideGap") ?? 0.5), pad = thick * (setting("SidePadding") ?? 0.5)
        const room = Math.max(0, (len - core) / 2 - pad - (core > 0 ? gap : 0))
        const stack = (list, fromEnd) => {
            const n = list.length, sum = list.reduce((a, w) => a + w.span, 0)
            const g = n > 1 ? Math.max(0, Math.min(gap, (room - sum) / (n - 1))) : 0
            let at = fromEnd ? len - pad - sum - g * (n - 1) : pad
            for (const w of list) { out[w.key] = at; at += w.span + g }
        }
        stack(all.filter(w => w.order < half), false)
        stack(all.filter(w => w.order >= half), true)
        return out
    }
    readonly property string path: shapePath()
    readonly property rect zone: vert
        ? Qt.rect(far ? viewWidth - reach : 0, m1, reach, viewHeight - m1 - m2)
        : Qt.rect(m1, far ? viewHeight - reach : 0, viewWidth - m1 - m2, reach)
    readonly property rect body: {
        const p = point(m1, gap), q = point(along - m2, gap + thick)
        return Qt.rect(Math.min(p[0], q[0]), Math.min(p[1], q[1]), Math.abs(q[0] - p[0]), Math.abs(q[1] - p[1]))
    }

    Behavior on shown { NumberAnimation { duration: Motion.span(twine.setting("SlideTime")); easing.type: Easing.OutExpo } }
    Behavior on thick { enabled: !twine.turning; Glide {} }
    Behavior on gap { enabled: !twine.turning; Glide {} }
    Behavior on rad { enabled: !twine.turning; Glide {} }
    Behavior on hang { enabled: !twine.turning; Glide {} }
    Behavior on flare { enabled: !twine.turning; Glide {} }
    Behavior on m1 { enabled: !twine.turning; Glide {} }
    Behavior on m2 { enabled: !twine.turning; Glide {} }
    Behavior on fill { Tint {} }

    Component.onCompleted: pos = posT
    onPosTChanged: {
        if (shown > 0) { turn.restart(); return }
        turning = true
        pos = posT
        calm.restart()
    }

    SequentialAnimation {
        id: turn
        NumberAnimation { target: twine; property: "present"; to: 0; duration: Motion.span(Math.min(160, twine.setting("SlideTime"))); easing.type: Easing.InCubic }
        ScriptAction { script: { twine.turning = true; twine.pos = twine.posT; twine.peek = true; peekTimer.restart() } }
        PauseAnimation { duration: 48 }
        ScriptAction { script: twine.turning = false }
        NumberAnimation { target: twine; property: "present"; to: 1; duration: Motion.span(twine.setting("SlideTime")); easing.type: Easing.OutExpo }
    }

    Timer { id: calm; interval: 64; onTriggered: twine.turning = false }

    Timer { id: stager; interval: 50; onTriggered: { const jobs = twine.staged; twine.staged = []; for (const job of jobs) job() } }
    Timer { id: peekTimer; interval: twine.peekTime; onTriggered: twine.peek = false }

    function point(u, w) {
        const d = w - (1 - shown * present) * depth
        const t = vert ? viewWidth : viewHeight
        return vert ? [far ? t - d : d, u] : [u, far ? t - d : d]
    }

    function shapePath() {
        const s = [], k = 0.552
        const T = gap + thick, a = m1, b = along - m2, r = rad, h = hang, F = flare
        const put = (c, ...n) => s.push(c + n.map(x => Math.round(x * 100) / 100).join(" "))
        const bend = (pu, pw, qu, qw, nu, nw) => {
            put("L", ...point(pu, pw))
            put("C", ...point(pu + (qu - pu) * k, pw + (qw - pw) * k), ...point(nu + (qu - nu) * k, nw + (qw - nw) * k), ...point(nu, nw))
        }
        put("M", ...point((a + b) / 2, gap))
        if (wrap && m2 === 0) {
            put("L", ...point(b, 0))
            bend(b, T + h, b, T, b - F, T)
        } else {
            bend(b - r, gap, b, gap, b, gap + r)
            bend(b, T - r, b, T, b - r, T)
        }
        if (wrap && m1 === 0) {
            bend(a + F, T, a, T, a, T + h)
            put("L", ...point(a, 0))
        } else {
            bend(a + r, T, a, T, a, T - r)
            bend(a, gap + r, a, gap, a + r, gap)
        }
        s.push("Z")
        return s.join(" ")
    }
}
