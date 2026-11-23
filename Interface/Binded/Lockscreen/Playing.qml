import QtQuick
import Quickshell.Services.Mpris
import "../../../Backend"

Row {
    id: tune

    readonly property var host: parent
    readonly property real unit: host && host.unit > 0 ? host.unit : 16
    readonly property color ink: host ? host.ink : "#ffffff"
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property string line: !player ? "" : String(player.trackTitle ?? "").trim() + (player.trackArtist ? "  ·  " + player.trackArtist : "")
    readonly property bool shown: line !== ""

    spacing: unit * 0.7

    Disc {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(tune.unit * 2.2)
        height: width
        art: String(tune.player?.trackArtUrl ?? "")
        spinning: tune.shown
        spinTime: tune.host ? tune.host.spinTime : 9000
        plate: tune.host ? tune.host.plate : "#0b0b0b"
        ink: tune.ink
        hole: tune.ink
        sign: String.fromCodePoint(0xf001)
        signFont: tune.host ? tune.host.iconFont : ""
        grooves: 2
    }
    Fade {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, tune.unit * 40)
        elide: Text.ElideRight
        want: tune.line
        color: tune.ink
        font.family: tune.host ? tune.host.font : ""
        font.pixelSize: tune.unit
    }
}
