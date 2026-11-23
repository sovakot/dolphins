import QtQuick

MouseArea {
    required property Flickable view
    property var pass: []

    anchors.fill: view
    acceptedButtons: Qt.NoButton
    onWheel: e => {
        for (const it of pass) {
            if (it && it.visible && it.contains(mapToItem(it, e.x, e.y))) { e.accepted = false; return }
        }
        const d = e.pixelDelta.y !== 0 ? e.pixelDelta.y : e.angleDelta.y / 120 * 60
        const top = view.originY, end = top + Math.max(0, view.contentHeight - view.height)
        view.contentY = Math.max(top, Math.min(end, view.contentY - d * Motion.scroll))
        e.accepted = true
    }
}
