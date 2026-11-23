import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "Backend"
import "Data/Dynamic"
import "Interface/Hidden/Catbar"
import "Interface/Hidden/Catbar/Widgets"
import "Interface/Hidden/Touchpad"
import "Interface/Hidden/Poodlebar"
import "Interface/Hidden/Sidebar"
import "Interface/Hidden/Updater"
import "Interface/Hidden/Desktop"
import "Interface/Binded/Snip"
import "Interface/Binded/Media Player"
import "Interface/Binded/Cheat Sheet"
import "Dolphin Hypr AI"
import "Dolphin Hypr AI/Editor"
import "Interface/Binded/Window View"
import "Interface/Binded/Lockscreen"
import "Interface/Binded/AI Model"
import "Interface/Binded/Snoopy Manager"
import "Interface/Binded/Network Connections"
import "Interface/Binded/Dolphin Hyprland Settings"

ShellRoot {
    Kde { cfg: Config.values }
    Keymap { cfg: Config.values }
    Wall { cfg: Config.values; store: Config }
    Sunset { cfg: Config.values }
    readonly property bool hardware: Hardware.ready
    readonly property bool gated: gate.locked
    onGatedChanged: Reveal.gate(gated)
    Touchpad { cfg: Config.values }
    WindowView { id: view; cfg: Config.values }
    Lockscreen { id: gate; cfg: Config.values; onBarred: Reveal.gate(true); onCleared: Reveal.gate(false) }
    Poodlebar { id: poodle }
    Sidebar { id: sidebar }
    Updater { bar: cat; panel: catPanel }
    HyprAI { bar: cat; side: sidebar; panel: catPanel; dock: poodle }
    AIModel {}
    SnoopyManager {}
    NetworkConnections {}
    SnoopySettings {}
    DesktopWidgets {}
    Editor { bar: cat; panel: catPanel }
    MediaPlayer {}
    Snip {}
    CheatSheet {}

    Cat {
        id: cat
        screen: catbar.screen
        hovered: catHover.hovered || catPanel.open
        viewWidth: catArt.width
        viewHeight: catArt.height
    }

    GlobalShortcut { appid: "catbar"; name: "show"; onPressed: { cat.busy = false; cat.heldAt = cat.now(); cat.hold = true } }
    GlobalShortcut {
        appid: "overview"
        name: "tap"
        onPressed: if (!cat.busy && !catPanel.open && !catPanel.warm && cat.now() - cat.heldAt <= (Config.values.windowview_TapTime ?? 400)) view.toggle()
    }
    GlobalShortcut { appid: "catbar"; name: "hide"; onPressed: cat.hold = false }
    GlobalShortcut { appid: "catbar"; name: "left"; onPressed: catPanel.nav("left") }
    GlobalShortcut { appid: "catbar"; name: "right"; onPressed: catPanel.nav("right") }
    GlobalShortcut { appid: "catbar"; name: "up"; onPressed: catPanel.nav("up") }
    GlobalShortcut { appid: "catbar"; name: "down"; onPressed: catPanel.nav("down") }
    GlobalShortcut { appid: "catbar"; name: "enter"; onPressed: catPanel.nav("enter") }

    PanelWindow {
        id: catbar
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: cat.size
        implicitHeight: cat.size
        anchors { top: cat.top; bottom: cat.bottom; left: cat.left; right: cat.right }
        mask: Region { item: catZone }

        Item {
            anchors.fill: parent
            opacity: Reveal.glass
            HoverHandler { id: catHover }

            Item {
                id: catZone
                x: cat.zone.x
                y: cat.zone.y
                width: cat.zone.width
                height: cat.zone.height
            }

            Shape {
                id: catArt
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: cat.fill
                    strokeWidth: -1
                    PathSvg { path: cat.path }
                }
            }

            Item {
                id: catBody
                x: cat.body.x
                y: cat.body.y
                width: cat.body.width
                height: cat.body.height

                Panel { id: catPanel; bar: cat }
                Repeater { model: cat.shows("Header") ? 1 : 0; Header { bar: cat } }
                Repeater { model: cat.shows("Clock") ? 1 : 0; Clock { bar: cat } }
                Repeater { model: cat.shows("Date") ? 1 : 0; Date { bar: cat } }
                Repeater { model: cat.shows("Battery") ? 1 : 0; Battery { bar: cat } }
                Repeater { model: cat.shows("Media") ? 1 : 0; Media { bar: cat } }
                Repeater { model: cat.shows("Sound") ? 1 : 0; Sound { bar: cat } }
                Repeater { model: cat.shows("Brightness") ? 1 : 0; Brightness { bar: cat } }
                Repeater { model: cat.shows("Weather") ? 1 : 0; Weather { bar: cat } }
                Repeater { model: cat.shows("Location") ? 1 : 0; Location { bar: cat } }
                Repeater { model: cat.shows("Keyboard") ? 1 : 0; Keyboard { bar: cat } }
                Repeater { model: cat.shows("Language") ? 1 : 0; Language { bar: cat } }
                Repeater { model: cat.shows("Notification") ? 1 : 0; Notification { bar: cat } }
                Repeater { model: cat.shows("Night") ? 1 : 0; Night { bar: cat } }
                Repeater { model: cat.shows("Network") ? 1 : 0; Network { bar: cat } }
                Repeater { model: cat.shows("Bluetooth") ? 1 : 0; Bluetooth { bar: cat } }
                Repeater { model: cat.shows("Extra") ? 1 : 0; Extra { bar: cat } }
                Repeater { model: cat.shows("Tabs") ? 1 : 0; Tabs { bar: cat; anchors.centerIn: parent } }
            }
        }
    }
}
