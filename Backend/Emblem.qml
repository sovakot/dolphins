pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Data/Dynamic"

Singleton {
    readonly property var map: Config.values.dolphin_WindowIcons ?? ({})
    readonly property string home: String(Quickshell.env("HOME") ?? "")
    readonly property var discs: Config.values.dolphin_WindowDiscs ?? ["dolphin-media"]
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: !!player && player.isPlaying
    readonly property string art: String(player?.trackArtUrl ?? "")
    readonly property color plate: tone(String(Config.values.media_DiscColor ?? "#0b0b0b"))
    readonly property real spinTime: Number(Config.values.media_SpinTime ?? 9000) || 9000
    property int stamp: 0

    function file(p) {
        p = String(p ?? "")
        const a = p.startsWith("/") ? p : home + "/" + p.replace(/^~?\/*/, "")
        return "file://" + a.split("/").map(encodeURIComponent).join("/") + (stamp > 0 ? "?" + stamp : "")
    }
    function tone(c) {
        const set = Config.tones
        return set?.[c] ?? (c.startsWith("#") ? c : "#000000")
    }
    function spins(title) {
        const t = String(title ?? "")
        return t !== "" && discs.some(k => String(k) !== "" && t.startsWith(String(k)))
    }
    function source(title, appId) {
        const t = String(title ?? "")
        for (const k in map) if (k !== "" && t.startsWith(k)) return file(map[k])
        const id = String(appId ?? "")
        return Quickshell.iconPath(DesktopEntries.heuristicLookup(id)?.icon ?? id, "application-x-executable")
    }
}
