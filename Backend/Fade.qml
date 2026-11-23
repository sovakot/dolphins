import QtQuick

Text {
    id: fade

    property string want: ""
    property real level: 1
    property real mix: 1
    property int time: 260

    opacity: level * mix
    onWantChanged: {
        if (text === "" && !swap.running) text = want
        else if (want !== text || swap.running) swap.restart()
    }

    SequentialAnimation {
        id: swap
        NumberAnimation { target: fade; property: "mix"; to: 0; duration: Motion.span(fade.time) }
        ScriptAction { script: fade.text = fade.want }
        NumberAnimation { target: fade; property: "mix"; to: 1; duration: Motion.span(fade.time) }
    }
}
