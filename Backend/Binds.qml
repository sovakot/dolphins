pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: binds

    readonly property string file: (Quickshell.env("XDG_CONFIG_HOME") || String(Quickshell.env("HOME") ?? "") + "/.config") + "/hypr/hyprland.lua"
    readonly property var actions: ({
        "session:toggle": "Session menu", "ai:toggle": "AI window", "settings:toggle": "Snoopy Settings", "taskmanager:toggle": "Snoopy Manager", "connections:toggle": "Network Connections",
        "updater:toggle": "Updater", "media:toggle": "Media Player", "cheatsheet:toggle": "Cheat sheet", "wallpaper:next": "Next wallpaper", "snip:toggle": "Screenshot", "editor:toggle": "Editor", "overview:toggle": "Window view", "lockscreen:lock": "Lock the screen", "poodlebar:search": "App search",
        "brightnessbar:show": "Brightness bar", "soundbar:show": "Sound bar", "catbar:left": "Catbar left", "catbar:right": "Catbar right",
        "catbar:up": "Catbar up", "catbar:down": "Catbar down", "catbar:enter": "Catbar select"
    })
    readonly property var dispatchNames: ({
        "window.close": "Close window", "window.float": "Toggle floating", "window.pseudo": "Pseudo-tile", "window.fullscreen": "Fullscreen",
        "window.drag": "Drag window", "window.resize": "Resize window", "window.move": "Move window to workspace", "focus": "Go to workspace",
        "layout": "Layout", "workspace.toggle_special": "Special workspace", "exit": "Exit Hyprland"
    })
    readonly property var commandNames: [
        [/Dolphin\.qml/, "Reload Dolphin"], [/wpctl set-volume .*\+$/, "Volume up"], [/wpctl set-volume .*-$/, "Volume down"],
        [/set-mute @DEFAULT_AUDIO_SINK@/, "Mute"], [/set-mute @DEFAULT_AUDIO_SOURCE@/, "Mute microphone"], [/brightnessctl .*\+$/, "Brightness up"],
        [/brightnessctl .*-$/, "Brightness down"], [/playerctl next/, "Next track"], [/playerctl previous/, "Previous track"],
        [/playerctl play-pause/, "Play or pause"], [/\bgrim\b/, "Screenshot"]
    ]
    readonly property var order: ["Dolphin", "Programs", "Windows", "Workspaces", "Mouse", "Media keys", "Other"]
    readonly property var keys: ({
        SUPER: "Super", CTRL: "Ctrl", CONTROL: "Ctrl", ALT: "Alt", SHIFT: "Shift", Return: "Enter", KP_Enter: "Enter", Escape: "Esc", space: "Space", Tab: "Tab", BackSpace: "Backspace",
        Prior: "PgUp", Next: "PgDn", left: "←", right: "→", up: "↑", down: "↓", comma: ",", period: ".", slash: "/", semicolon: ";", apostrophe: "'", minus: "-", equal: "=",
        grave: "`", bracketleft: "[", bracketright: "]", backslash: "\\", "mouse:272": "LMB", "mouse:273": "RMB", "mouse:274": "MMB", mouse_down: "Scroll ↓", mouse_up: "Scroll ↑",
        XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute", XF86AudioMicMute: "Mic", XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −",
        XF86AudioNext: "Next", XF86AudioPrev: "Prev", XF86AudioPlay: "Play", XF86AudioPause: "Pause", Print: "Print", Delete: "Del", Insert: "Ins"
    })

    function cap(token) {
        const t = String(token)
        if (keys[t] !== undefined) return keys[t]
        if (keys[t.toUpperCase()] !== undefined) return keys[t.toUpperCase()]
        return t.length === 1 ? t.toUpperCase() : t.charAt(0).toUpperCase() + t.slice(1)
    }
    function args(src, start) {
        const out = [], n = src.length, blank = " \t\r\n"
        const piece = (a, b) => {
            while (a < b && blank.includes(src[a])) a++
            while (b > a && blank.includes(src[b - 1])) b--
            return src.slice(a, b)
        }
        let i = start, depth = 0, a = start
        while (i < n) {
            const ch = src[i]
            if (ch === "\"" || ch === "'") {
                i++
                while (i < n && src[i] !== ch) i += src[i] === "\\" ? 2 : 1
                i++
                continue
            }
            if (ch === "[" && src[i + 1] === "[") {
                const e = src.indexOf("]]", i + 2)
                i = e < 0 ? n : e + 2
                continue
            }
            if (ch === "-" && src[i + 1] === "-") {
                const e = src.indexOf("\n", i)
                i = e < 0 ? n : e
                continue
            }
            if (ch === "(" || ch === "{" || ch === "[") depth++
            else if (ch === ")" || ch === "}" || ch === "]") {
                if (depth === 0) { out.push(piece(a, i)); return out }
                depth--
            } else if (ch === "," && depth === 0) { out.push(piece(a, i)); a = i + 1 }
            i++
        }
        return null
    }
    function describe(a, vars, combo) {
        const m = a.match(/^hl\.dsp\.([\w.]+)\(([\s\S]*)\)$/)
        let name = a, tail = "", group = "Other"
        if (m) {
            const fn = m[1], arg = m[2].trim()
            const lit = arg.match(/^"([\s\S]*)"$/) || arg.match(/^'([\s\S]*)'$/) || arg.match(/^\[\[([\s\S]*)\]\]$/)
            const val = lit ? lit[1] : vars[arg] !== undefined ? vars[arg] : arg
            if (fn === "global") { name = actions[val] ?? val; group = "Dolphin" }
            else if (fn === "exec_cmd" || fn === "exec_raw") {
                const known = commandNames.find(c => c[0].test(val)), prog = val.trim().split(/\s+/)[0].split("/").pop()
                group = "Programs"
                if (known) name = known[1]
                else if (/^[A-Za-z0-9][\w.+-]*$/.test(prog) && !["for", "while", "if", "sh", "bash", "env", "pkill"].includes(prog)) { name = "Run"; tail = prog }
                else name = "Run a command"
            } else {
                name = dispatchNames[fn] ?? fn
                group = fn === "focus" || fn.startsWith("workspace.") || fn === "window.move" ? "Workspaces" : "Windows"
                if (fn === "window.fullscreen" && arg.includes("maximized")) name = "Maximize"
                else if (fn === "focus" && arg.includes("e+1")) name = "Next workspace"
                else if (fn === "focus" && arg.includes("e-1")) name = "Previous workspace"
                else if (fn === "window.move" && arg.includes("special")) name = "Move window to the special workspace"
                else if (fn === "layout" && lit) tail = lit[1]
            }
        }
        if (/mouse/.test(combo)) group = "Mouse"
        else if (/XF86/.test(combo)) group = "Media keys"
        return { name: name, tail: tail, group: group }
    }
    function parse(text) {
        const vars = {}, by = {}
        if (!text) return []
        const lines = String(text).split("\n")
        let at = 0
        for (const line of lines) {
            const begin = at
            at += line.length + 1
            const v = line.match(/^\s*local\s+([A-Za-z_]\w*)\s*=\s*"([^"]*)"/)
            if (v) vars[v[1]] = v[2]
            const hit = line.indexOf("hl.bind(")
            if (hit < 0) continue
            const note = line.indexOf("--")
            if (note >= 0 && note < hit) continue
            const got = args(text, begin + hit + 8)
            if (!got || got.length < 2) continue
            const combo = got[0].split("..").map(p => {
                const t = p.trim(), q = t.match(/^"([^"]*)"$/) || t.match(/^'([^']*)'$/)
                return q ? q[1] : vars[t] !== undefined ? vars[t] : /^(key|k|i|n|num|ws|index)$/i.test(t) ? "#" : ""
            }).join("")
            const tokens = combo.split("+").map(t => t.trim()).filter(t => t)
            const d = describe(got[1], vars, combo)
            if (!tokens.length) continue
            if (!by[d.group]) by[d.group] = []
            by[d.group].push({ tokens: tokens, name: d.name, tail: d.tail })
        }
        const names = order.filter(g => by[g]).concat(Object.keys(by).filter(g => !order.includes(g)))
        return names.map(g => ({ name: g, binds: by[g] }))
    }
}
