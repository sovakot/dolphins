import QtQuick
import Quickshell
import "../Data/Dynamic"

Scope {
    id: kit

    property var base: ({})
    readonly property var cfg: Config.values
    readonly property string lang: String(cfg?.dolphin_Language ?? "en").toLowerCase()
    readonly property string font: cfg?.dolphin_TextFont ?? "Maple Mono NF"
    readonly property string iconFont: cfg?.dolphin_IconFont ?? "Maple Mono NF"

    function s(k) {
        const v = cfg?.[k], d = base[k]
        return typeof v === typeof d && Array.isArray(v) === Array.isArray(d) ? v : d
    }
    function title(t) { return String(t).charAt(0).toUpperCase() + String(t).slice(1) }
    function col(c) {
        const set = Config.tones
        return set?.[c] ?? set?.[title(c)] ?? (String(c).startsWith("#") ? c : "#000000")
    }
    function word(k) { return Config.words?.[k]?.[lang] ?? k }
    function glyph(hex) { const n = parseInt(hex ?? "", 16); return n ? String.fromCodePoint(n) : "" }
    function curve(k) { return Easing[s(k)] ?? Easing.OutExpo }
    function save(k, v) { Array.isArray(v) ? Config.list(k, v) : Config.set(k, v) }
}
