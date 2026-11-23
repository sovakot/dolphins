import QtQuick

QtObject {
    id: beat

    property real edge: 0.2
    property real sync: 70
    property bool predict: true
    property bool build: true

    property var levels: []
    property real bass: 0
    property real calm: 0
    property real mood: 0
    property real energy: 0
    property real charge: 0
    property real period: 0
    property int score: 0
    property real next: 0
    property real seen: 0
    property real fired: 0
    property real fed: 0
    property real force: 0.45
    property bool hot: false
    property real rush: 0
    property real usual: 0
    property real heard: 0
    readonly property real kick: Math.max(0, bass - calm)
    readonly property bool locked: predict && score >= 4 && period > 0
    readonly property real bpm: period > 0 ? 60000 / period : 0
    readonly property real tempo: period > 0 && score >= 3 ? 60000 / period : 0
    readonly property real busy: heard > 4000 && usual > 0.05 ? Math.max(0.5, Math.min(2, rush / usual)) : 1

    signal hit(real power)

    function reset() {
        levels = []
        bass = 0
        calm = 0
        mood = 0
        energy = 0
        charge = 0
        period = 0
        score = 0
        next = 0
        seen = 0
        fired = 0
        fed = 0
        hot = false
        rush = 0
        usual = 0
        heard = 0
    }
    function ease(dt, span) { return 1 - Math.exp(-dt / span) }
    function fold(gap) {
        let v = gap
        while (v < 300) v *= 2
        while (v > 1100) v /= 2
        return v
    }
    function fire(power, now) {
        fired = now
        force = power
        hit(power)
    }
    function learn(now) {
        const raw = now - seen
        if (seen <= 0 || raw < 150 || raw > 2400) return
        const gap = fold(raw)
        if (period <= 0) { period = gap; score = 1; return }
        let fit = 0
        for (const m of [1, 2, 0.5]) if (Math.abs(gap - period * m) < period * m * 0.1) fit = m
        if (fit > 0) {
            period += (gap / fit - period) * 0.25
            score = Math.min(8, score + 1)
            return
        }
        score -= 2
        if (score > 0) return
        period = gap
        score = 1
    }
    function land(power, now) {
        learn(now)
        seen = now
        if (!locked) { next = 0; fire(power, now); return }
        const want = now + period - sync
        next = next <= 0 || Math.abs(next - want) > period * 0.3 ? want : next + (want - next) * 0.35
        if (now - fired > Math.max(140, sync + 90) || (power >= 1 && force < 1)) fire(power, now)
    }
    function tick(now) {
        if (!locked || next <= 0) return
        if (now - seen > period * 2.6) { score = 0; next = 0; return }
        if (now < next) return
        next += period
        while (next <= now) next += period
        if (now - fired > period * 0.4 && now - seen < period * 1.6) fire(hot ? 1 : 0.45, now)
    }
    function feed(line, now) {
        const p = line.split(";"), out = [], old = levels
        let low = 0, sum = 0, n = 0, rise = 0
        for (let i = 0; i < p.length; i++) {
            if (p[i] === "") continue
            const v = Math.max(0, Math.min(1, (Number(p[i]) || 0) / 1000))
            if (n < 4) low += v
            if (n < old.length && v > old[n]) rise += v - old[n]
            sum += v
            out.push(v)
            n++
        }
        if (!n) return
        const lows = Math.min(4, n), all = sum / n, rest = n > lows ? (sum - low) / (n - lows) : all
        const dt = fed > 0 ? Math.max(1, Math.min(100, now - fed)) : 16, was = kick, beatLen = period > 0 ? period : 500
        const rate = rise / n * 1000 / dt
        fed = now
        heard += dt
        levels = out
        bass = low / lows
        energy += (Math.min(1, all * 1.8) - energy) * ease(dt, 103)
        rush += (rate - rush) * ease(dt, 900)
        usual += (rate - usual) * ease(dt, Math.max(900, Math.min(15000, heard)))
        hot = all - mood > edge
        if (kick > edge && was <= edge) {
            const power = charge > 0.25 ? 1 + charge : hot ? 1 : 0.45
            charge = 0
            land(power, now)
        } else if (build && seen > 0) {
            const gap = now - seen
            if (gap > 30000 || (rest < 0.02 && gap > beatLen * 2.2 + 4000)) charge = Math.max(0, charge - dt / 1500)
            else if (gap > beatLen * 2.2 && rest > 0.04) charge = Math.min(1, charge + dt / (beatLen * 8))
        } else if (!build) charge = 0
        calm += (bass - calm) * ease(dt, 325)
        mood += (all - mood) * ease(dt, 1658)
    }
}
