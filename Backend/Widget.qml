import QtQuick

Item {
    id: widget

    required property var bar
    required property string key
    property string icon: ""
    property string label: ""
    property string tip: ""
    property bool lit: false
    property bool hot: false
    property bool held: false
    property Component page: null
    property Component banner: null
    property Component backdrop: null
    property bool ghost: false
    property string spot: "Position"
    property real len: 0
    signal tapped()

    readonly property string prefix: "widget_" + key.charAt(0).toUpperCase() + key.slice(1)
    readonly property real base: bar.thick
    readonly property bool vert: bar.vert
    readonly property real order: s(spot) ?? 0
    readonly property real place: !vert ? base * order
        : bar.sides[key] !== undefined ? bar.sides[key]
        : base * (s(spot + "Side") ?? order * bar.along / Math.max(1, bar.wide))
    readonly property real start: vert ? y : x
    readonly property real span: vert ? height : width
    property real unit: base * (s("Scale") ?? 1)
    property color ink: c("Color")
    readonly property var grouped: s("Grouped") ?? []
    readonly property string group: bar.groupOf(key)
    readonly property bool solo: group !== "" && group.indexOf("+") < 0
    readonly property bool picked: group !== "" && (bar.litGroup === group || (held && solo))
    readonly property string iconFont: bar.global("IconFont") ?? ""
    readonly property string textFont: bar.global("TextFont") ?? ""

    function s(k) { return bar.setting(k, prefix) }
    function c(k) { return picked && k === "Color" ? bar.panelColor(group, "Color") : bar.color(k, prefix) }
    function p(k) { return bar.panel(group, k) }
    function pc(k) { return bar.panelColor(group, k) }
    function t(k) { return bar.word(k) }
    function glyph(hex) {
        const n = parseInt(hex ?? "", 16)
        return n > 0 && n <= 0x10FFFF ? String.fromCodePoint(n) : ""
    }
    function sign(v) {
        const n = String(v ?? "")
        return Art.has(n) ? n : /^[0-9a-fA-F]{2,6}$/.test(n) ? glyph(n) : ""
    }
    function along(item) { return vert ? item.height : item.width }
    function stamp() { return Date.now() }
    function daysIn(year, month) { return new Date(year, month + 1, 0).getDate() }
    function weekday(year, month, day) { return new Date(year, month, day).getDay() }
    function dur(t, lvl) {
        const d = Math.floor(t / 86400), h = Math.floor(t % 86400 / 3600), m = Math.floor(t % 3600 / 60)
        let out = (d ? d + "d " : "") + (d || h ? h + "h " : "") + m + "m"
        if (lvl > 0) out += " " + Math.floor(t % 60) + "s"
        if (lvl > 1) out += " " + String(Math.floor(t * 1000 % 1000)).padStart(3, "0") + "ms"
        return out
    }

    readonly property real fitEdge: Math.round(base * 0.3)
    readonly property real fitRoom: vert ? bar.body.height : bar.body.width
    readonly property real fitLen: Math.ceil(len / 2) * 2
    readonly property real fitAt: fitRoom > fitLen + fitEdge * 2 ? Math.max(fitEdge, Math.min(fitRoom - fitLen - fitEdge, Math.round(place))) : Math.round(place)

    x: vert ? 0 : fitAt
    y: vert ? fitAt : 0
    width: vert ? base : fitLen
    height: vert ? fitLen : base
    Behavior on x { enabled: !widget.bar || !widget.bar.turning; Glide {} }
    Behavior on y { enabled: !widget.bar || !widget.bar.turning; Glide {} }
    Behavior on unit { Glide {} }
    Behavior on ink { Tint {} }
    Component.onCompleted: bar.register(key, widget)
    Component.onDestruction: bar.unregister(key)
}
