pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: sky

    property bool online: false
    property bool linked: false
    property int tries: 0
    property var now: null
    property var area: null
    property var days: []
    property real fetched: 0
    property real tick: Date.now()

    readonly property string place: area ? first(area.areaName) : ""
    readonly property string region: area ? first(area.region) : ""
    readonly property string country: area ? first(area.country) : ""
    readonly property string kind: kindOf(now ? parseInt(now.weatherCode) : 113)
    readonly property var sun: days[0] && days[0].astronomy && days[0].astronomy[0] ? days[0].astronomy[0] : null
    readonly property bool night: {
        const d = new Date(tick), m = d.getHours() * 60 + d.getMinutes()
        return m < (sun ? minutes(sun.sunrise) : 360) || m >= (sun ? minutes(sun.sunset) : 1080)
    }

    function first(list) { return list && list[0] && list[0].value ? list[0].value : "" }
    function minutes(s) {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(s || "")
        return m ? (parseInt(m[1]) % 12 + (m[3].toUpperCase() === "PM" ? 12 : 0)) * 60 + parseInt(m[2]) : 0
    }
    function kindOf(code) {
        if ([200, 386, 389, 392, 395].includes(code)) return "thunder"
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code)) return "snow"
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359].includes(code)) return "rain"
        if ([116, 119, 122, 143, 248, 260].includes(code)) return "cloudy"
        return "clear"
    }
    function take(text) {
        let d = null
        try { d = JSON.parse(text) } catch (e) {}
        if (!d || !d.current_condition || !d.current_condition[0]) {
            online = false
            if (linked && tries < 4) { tries++; again.restart() }
            return
        }
        tries = 0
        now = d.current_condition[0]
        area = d.nearest_area ? d.nearest_area[0] : null
        days = d.weather || []
        fetched = Date.now()
        online = true
    }
    function probe() {
        const v4 = /(^|\n)\S+\t00000000\t/.test(route.text())
        const v6 = route6.text().split("\n").some(l => l.startsWith("00000000000000000000000000000000 00 ") && !/\slo\s*$/.test(l))
        linked = v4 || v6
    }
    onLinkedChanged: {
        tries = 0
        if (linked) refresh(true)
        else { again.stop(); online = false }
    }
    function refresh(force) {
        if (get.running) return
        if (!force && online && Date.now() - fetched < 600000) return
        get.running = true
    }

    Process {
        id: get
        command: ["curl", "-sf", "--max-time", "15", "https://wttr.in/?format=j1"]
        stdout: StdioCollector { onStreamFinished: sky.take(text) }
    }
    Timer { interval: sky.online ? 1800000 : 120000; running: true; repeat: true; triggeredOnStart: true; onTriggered: sky.refresh(true) }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: sky.tick = Date.now() }
    Timer { id: again; interval: 15000; onTriggered: sky.refresh(true) }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { route.reload(); route6.reload() } }
    FileView { id: route; path: "/proc/net/route"; printErrors: false; onLoaded: sky.probe() }
    FileView { id: route6; path: "/proc/net/ipv6_route"; printErrors: false; onLoaded: sky.probe() }
}
