import QtQuick

Canvas {
    id: graph

    property var values: []
    property var trace: []
    property int span: 60
    property real peak: 100
    property color ink: "#ffffff"
    property color pen: "#ffffff"
    property color mesh: "#22ffffff"
    property real stroke: 2
    property real slit: 1
    property int rows: 4
    property bool frame: true

    onValuesChanged: requestPaint()
    onTraceChanged: requestPaint()
    onPeakChanged: requestPaint()
    onInkChanged: requestPaint()
    onPenChanged: requestPaint()
    onMeshChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d"), w = width, h = height
        c.reset()
        if (w <= 0 || h <= 0) return
        const top = Math.max(0.0001, peak), step = w / Math.max(1, span)
        const rise = v => Math.max(0, Math.min(1, v / top)) * (h - 1)
        c.lineWidth = 1
        c.strokeStyle = mesh
        c.beginPath()
        for (let j = 1; j < rows; j++) { const y = Math.round(h * j / rows) + 0.5; c.moveTo(0, y); c.lineTo(w, y) }
        c.stroke()
        const n = Math.min(values.length, span), from = values.length - n
        const gap = step > 3 ? slit : 0
        c.fillStyle = ink
        for (let i = 0; i < n; i++) {
            const tall = rise(values[from + i])
            if (tall < 0.5) continue
            const x = w - (n - i) * step
            c.fillRect(Math.round(x + gap / 2), Math.round(h - tall), Math.max(1, Math.round(step - gap)), Math.round(tall))
        }
        const m = Math.min(trace.length, span), start = trace.length - m
        if (m > 1) {
            c.beginPath()
            for (let i = 0; i < m; i++) {
                const x = w - (m - i) * step + step / 2, y = h - rise(trace[start + i]) - stroke / 2
                if (i === 0) c.moveTo(x, y)
                else c.lineTo(x, y)
            }
            c.lineWidth = stroke
            c.lineJoin = "round"
            c.strokeStyle = pen
            c.stroke()
        }
        if (frame) {
            c.lineWidth = 1
            c.strokeStyle = mesh
            c.strokeRect(0.5, 0.5, w - 1, h - 1)
        }
    }
}
