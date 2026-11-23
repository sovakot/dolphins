import QtQuick

Item {
    id: cover

    property string art: ""
    property int time: 600
    property int side: 256
    property int turn: 0
    property string first: ""
    property string second: ""
    readonly property real shown: Math.max(one.opacity, two.opacity)

    onArtChanged: {
        if (turn === 0) second = art
        else first = art
        turn = 1 - turn
    }

    Image {
        id: one
        anchors.fill: parent
        source: cover.first
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: cover.side
        sourceSize.height: cover.side
        opacity: cover.turn === 0 ? (status === Image.Ready ? 1 : 0) : status === Image.Ready && two.status === Image.Loading ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.span(cover.time); easing.type: Easing.InOutQuad } }
    }
    Image {
        id: two
        anchors.fill: parent
        source: cover.second
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: cover.side
        sourceSize.height: cover.side
        opacity: cover.turn === 1 ? (status === Image.Ready ? 1 : 0) : status === Image.Ready && one.status === Image.Loading ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.span(cover.time); easing.type: Easing.InOutQuad } }
    }
}
