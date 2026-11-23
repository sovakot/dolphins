pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string key: ""
    property var steps: []
    property int at: 0
    property bool done: false
    property var spot: null
    property string mark: ""
    property string monitor: ""

    signal summon()

    function begin(k) {
        done = false
        key = String(k ?? "")
    }
    function end() {
        key = ""
        done = false
        spot = null
        mark = ""
        monitor = ""
    }
}
