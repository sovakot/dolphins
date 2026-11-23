pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: now

    property var date: new Date()
    property var askers: ({})
    readonly property bool fine: Object.keys(askers).length > 0
    readonly property int step: fine ? 1000 : 60000

    function seconds(who, on) {
        if (!!askers[who] === !!on) return
        const a = Object.assign({}, askers)
        if (on) a[who] = true
        else delete a[who]
        askers = a
    }
    function sync() {
        const t = Date.now()
        date = new Date(t)
        beat.interval = step - t % step + 15
        beat.restart()
    }

    onStepChanged: sync()
    Component.onCompleted: sync()

    Timer { id: beat; onTriggered: now.sync() }
    Process {
        running: true
        command: ["stdbuf", "-oL", "dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        stdout: SplitParser { onRead: line => { if (line.indexOf("boolean false") >= 0) now.sync() } }
    }
}
