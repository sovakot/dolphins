import QtQuick

Rectangle {
    id: chip

    property string label: ""
    property string family: ""
    property real size: 13
    property color fg: "#ffffff"
    property color bg: "#000000"
    property bool live: true
    property bool lit: false
    readonly property bool hot: live && (lit || area.containsMouse)
    signal tapped()

    implicitWidth: Math.ceil(text.implicitWidth + 28)
    implicitHeight: Math.round(size * 2.4)
    color: hot ? fg : bg
    border.width: 1
    border.color: fg
    opacity: live ? 1 : 0.4

    Text {
        id: text
        anchors.centerIn: parent
        text: chip.label
        color: chip.hot ? chip.bg : chip.fg
        font.family: chip.family
        font.pixelSize: chip.size
        font.bold: true
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: if (chip.live) chip.tapped() }
}
