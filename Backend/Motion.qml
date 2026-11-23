pragma Singleton
import QtQuick
import Quickshell
import "../Data/Dynamic"

Singleton {
    readonly property bool on: Config.values.system_Animations !== false
    readonly property int time: on ? Math.max(0, Config.values.dolphin_SettingsChangeTime ?? 100) : 0
    readonly property int type: Math.max(5, Config.values.dolphin_TypeAnimationTime ?? 15)
    readonly property real scroll: Math.max(0.1, Config.values.dolphin_ScrollSpeed ?? 1)
    readonly property int ease: Easing[Config.values.dolphin_SettingsEasingStyle] ?? Easing.OutExpo

    function span(v) { return on ? v : 0 }
}
