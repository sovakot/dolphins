pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property var list: []

    function raise(id, title, detail, steps, tag, cmd) {
        const row = { id: String(id), title: String(title ?? ""), detail: String(detail ?? ""), steps: String(steps ?? ""), tag: String(tag ?? ""), cmd: String(cmd ?? "") }
        const old = list.find(i => i.id === row.id)
        if (old && old.title === row.title && old.detail === row.detail && old.steps === row.steps) return
        list = list.filter(i => i.id !== row.id).concat([row])
    }
    function clear(id) { if (list.some(i => i.id === id)) list = list.filter(i => i.id !== id) }
    function sweep(prefix) { if (list.some(i => i.id.startsWith(prefix))) list = list.filter(i => !i.id.startsWith(prefix)) }
}
