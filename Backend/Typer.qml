import QtQuick

Text {
    id: typer

    property string want: ""
    property string caret: "_"
    property bool wipe: true
    property string typed: ""

    text: typed + (typed !== want ? caret : "")
    onWantChanged: if (wipe && want !== "" && !want.startsWith(typed)) typed = ""

    Timer {
        interval: Motion.type
        repeat: true
        running: typer.typed !== typer.want
        onTriggered: typer.typed = !Motion.on ? typer.want : typer.want.startsWith(typer.typed) ? typer.want.slice(0, typer.typed.length + 1) : typer.typed.slice(0, -1)
    }
}
