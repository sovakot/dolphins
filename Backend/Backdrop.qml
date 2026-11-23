import QtQuick
import QtQuick.Effects

Cover {
    id: drop

    property real blur: 1
    property int reach: 64
    property real swell: 0
    readonly property real soft: Math.max(0, Math.min(1, blur))

    side: soft > 0.75 ? 96 : soft > 0.45 ? 256 : soft > 0.15 ? 512 : 1024
    scale: 1 + swell
    layer.enabled: visible && soft > 0 && shown > 0
    layer.effect: MultiEffect { blurEnabled: true; blur: drop.soft; blurMax: drop.reach }
}
