import QtQuick

Item {
    property alias text: label.text
    property alias color: label.color
    property alias font: label.font

    implicitWidth: ink.tightBoundingRect.width
    implicitHeight: ink.tightBoundingRect.height

    TextMetrics { id: ink; font: label.font; text: label.text }
    Text {
        id: label
        x: -ink.tightBoundingRect.x
        y: -(baselineOffset + ink.tightBoundingRect.y)
    }
}