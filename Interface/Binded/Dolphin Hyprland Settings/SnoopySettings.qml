import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.UPower
import "../../../Backend"
import "../../../Data/Dynamic"

Kit {
    id: root

    readonly property string infoPicture: "sovakot.png"
    readonly property string infoName: "Совакот"
    readonly property string infoText: "Dolphin Hyprland is based on Hyprland and created by sovakot. This configuration of Hyprland is created for people who want a clean and easy way to customize arch linux without having to touch a line of code. Nearly every panel is built to be as customizable as possible, and with Dolphin Hyper AI, navigating settings and customization is as easy as typing."

    base: ({
        settings_Show: true, settings_Title: "SNOOPY SETTINGS", settings_Icon: "f18b4", settings_Inverted: false,
        settings_Width: 0.6, settings_Height: 0.72, settings_TextSize: 13, settings_Radius: 6, settings_IconShift: 0, settings_StartTab: "style",
        settings_Tabs: [
            { Key: "ai", Icon: "panda", Label: "Dolphin Hypr AI" }, { Key: "editor", Icon: "f044", Label: "Editor" }, { Key: "style", Icon: "f1fc", Label: "Style" }, { Key: "interface", Icon: "f2d2", Label: "Interface" },
            { Key: "system", Icon: "f2db", Label: "System" }, { Key: "keys", Icon: "f11c", Label: "Keybinds" }, { Key: "config", Icon: "f013", Label: "Config" }, { Key: "info", Icon: "f064e", Label: "Info" }
        ],
        settings_HiddenTabs: [], settings_ContentWidth: 54, settings_Roundness: 1.8, settings_TipWidth: 26,
        settings_Color: "Background", settings_PanelColor: "Accent", settings_TextColor: "Text", settings_IconColor: "Text", settings_ActiveColor: "Active",
        settings_HoverColor: "Inactive", settings_BorderColor: "Accent2", settings_DangerColor: "#e06c75",
        settings_WallpaperFolder: "~/Dolphin/Data/Static/Images/Wallpaper", settings_ThumbSize: 480, settings_SearchLimit: 8, settings_HighlightTime: 1800
    })

    readonly property color bg: tone("settings_Color")
    readonly property color pane: tone("settings_PanelColor")
    readonly property color tx: tone("settings_TextColor")
    readonly property color mark: tone("settings_IconColor")
    readonly property color hi: tone("settings_ActiveColor")
    readonly property color hv: { const c = tone("settings_HoverColor"); return Qt.colorEqual(c, bg) ? Qt.rgba(tx.r, tx.g, tx.b, 0.12) : c }
    readonly property color bd: tone("settings_BorderColor")
    readonly property color bad: tone("settings_DangerColor")
    readonly property color soft: Qt.rgba(tx.r, tx.g, tx.b, 0.06)
    readonly property color softer: Qt.rgba(tx.r, tx.g, tx.b, 0.12)
    readonly property color glow: Qt.rgba(hi.r, hi.g, hi.b, 0.18)
    readonly property real px: Math.max(9, s("settings_TextSize"))
    readonly property real rowH: Math.round(px * 2.5)
    readonly property real gap: Math.round(px * 1.7)
    readonly property real rad: Math.max(0, s("settings_Radius")) * Math.max(0, s("settings_Roundness"))
    readonly property real round: rad * 2
    readonly property real rowPad: Math.round(px * 0.9)
    readonly property real colW: Math.round(px * Math.max(30, s("settings_ContentWidth")))

    readonly property string dolphin: String(Quickshell.shellDir).replace(/\/+$/, "")
    readonly property string house: String(Quickshell.env("HOME") ?? "")
    readonly property string here: dolphin + "/Interface/Binded/Dolphin Hyprland Settings"
    readonly property string user: String(Quickshell.env("USER") ?? "")
    readonly property string avatarFile: abs(String(cfg?.greeter_Avatar ?? "~/Dolphin/Data/Static/Images/Lockscreen/avatar.png"))
    readonly property string avatarSrc: avatarBusy ? "" : url(avatarFile)
    readonly property string infoImage: url(here + "/" + infoPicture)
    readonly property string configFile: dolphin + "/Data/Dynamic/config.json"
    readonly property string logoFile: dolphin + "/Data/Dynamic/settings-logo.png"
    readonly property string modelsDir: local(String(cfg?.ai_ModelsFolder ?? "Data/Static/AI Models"))
    readonly property string contextFile: local(String(cfg?.hyprai_Context ?? "Data/Context.txt"))
    readonly property string luaPath: (Quickshell.env("XDG_CONFIG_HOME") || house + "/.config") + "/hypr/hyprland.lua"
    readonly property var actions: Binds.actions
    readonly property var oldActions: ({})
    readonly property var dispatchNames: Binds.dispatchNames
    readonly property var commandNames: Binds.commandNames
    readonly property var groupOrder: ["Dolphin", "Programs", "Windows", "Workspaces", "Mouse", "Other"]
    readonly property var keyNames: [
        [Qt.Key_Return, "Return"], [Qt.Key_Enter, "KP_Enter"], [Qt.Key_Space, "space"], [Qt.Key_Tab, "Tab"], [Qt.Key_Backtab, "Tab"], [Qt.Key_Backspace, "BackSpace"],
        [Qt.Key_Delete, "Delete"], [Qt.Key_Insert, "Insert"], [Qt.Key_Home, "Home"], [Qt.Key_End, "End"], [Qt.Key_PageUp, "Prior"], [Qt.Key_PageDown, "Next"],
        [Qt.Key_Left, "left"], [Qt.Key_Right, "right"], [Qt.Key_Up, "up"], [Qt.Key_Down, "down"], [Qt.Key_Escape, "Escape"], [Qt.Key_Print, "Print"],
        [Qt.Key_Pause, "Pause"], [Qt.Key_Menu, "Menu"], [Qt.Key_Comma, "comma"], [Qt.Key_Period, "period"], [Qt.Key_Slash, "slash"], [Qt.Key_Semicolon, "semicolon"],
        [Qt.Key_Apostrophe, "apostrophe"], [Qt.Key_BracketLeft, "bracketleft"], [Qt.Key_BracketRight, "bracketright"], [Qt.Key_Backslash, "backslash"],
        [Qt.Key_Minus, "minus"], [Qt.Key_Equal, "equal"], [Qt.Key_QuoteLeft, "grave"], [Qt.Key_Exclam, "1"], [Qt.Key_At, "2"], [Qt.Key_NumberSign, "3"],
        [Qt.Key_Dollar, "4"], [Qt.Key_Percent, "5"], [Qt.Key_AsciiCircum, "6"], [Qt.Key_Ampersand, "7"], [Qt.Key_Asterisk, "8"], [Qt.Key_ParenLeft, "9"],
        [Qt.Key_ParenRight, "0"], [Qt.Key_Underscore, "minus"], [Qt.Key_Plus, "equal"], [Qt.Key_BraceLeft, "bracketleft"], [Qt.Key_BraceRight, "bracketright"],
        [Qt.Key_Bar, "backslash"], [Qt.Key_Colon, "semicolon"], [Qt.Key_QuoteDbl, "apostrophe"], [Qt.Key_Less, "comma"], [Qt.Key_Greater, "period"],
        [Qt.Key_Question, "slash"], [Qt.Key_AsciiTilde, "grave"]
    ]
    readonly property var keymap: parseBinds(luaText)
    readonly property var keyGroups: groupBinds(keymap)
    readonly property string logoScript: [
        "[ -f \"$1\" ] || exit 0",
        "[ -f \"$3\" ] && [ \"$3\" -nt \"$1\" ] && { [ ! -f \"$2\" ] || [ \"$3\" -nt \"$2\" ]; } && exit 0",
        "ffmpeg -v error -y -i \"$1\" -frames:v 1 -vf \"crop=w='min(iw\\,ih)/$4':h='min(iw\\,ih)/$4':x='iw/2-(0.5+($5))*min(iw\\,ih)/$4':y='ih/2-(0.5+($6))*min(iw\\,ih)/$4',scale=256:256,format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='255*clip(128-hypot(X-127.5\\,Y-127.5)\\,0\\,1)'\" \"$3\" </dev/null && echo made"
    ].join("\n")
    readonly property string editor: String(cfg?.dolphin_EditorDefault ?? "codium").trim()
    readonly property var moduleNames: ({ updater: "Updater", ai: "AI", manager: "Snoopy Manager", connections: "Network Connections", touchpad: "Touchpad gestures", windowview: "Window view", lockscreen: "Lock screen", editor: "Editor", desktop: "Desktop widgets", snip: "Screenshot tool", media: "Media Player", cheatsheet: "Cheat sheet", poodlebar: "Poodlebar", sidebar: "Sidebar", session: "Session menu", hyprai: "Panda Hypr AI" })
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || house + "/.cache") + "/dolphin/thumbs"
    readonly property string thumbScript: [
        "c=\"$1\"; w=\"$2\"; shift 2; mkdir -p \"$c\"",
        "for a in \"$@\"; do for f in \"$a\" \"$a\"/*; do",
        "[ -f \"$f\" ] || continue",
        "case \"$(printf %s \"${f##*.}\" | tr A-Z a-z)\" in png|jpg|jpeg|webp|gif|bmp) s=;; mp4|mkv|webm|mov|avi|m4v) s=\"-ss 1\";; *) continue;; esac",
        "t=\"$c/$(printf %s \"$f\" | md5sum | cut -c1-32)-$w.jpg\"",
        "[ \"$t\" -nt \"$f\" ] || nice -n 19 ffmpeg -v error -y $s -i \"$f\" -frames:v 1 -vf \"scale=$w:-2\" -q:v 4 \"$t\" </dev/null >/dev/null 2>&1",
        "[ -f \"$t\" ] && printf '%s\\t%s\\n' \"$f\" \"$t\"",
        "done; done"
    ].join("\n")

    readonly property var gaps: /[\s!-\/:-@\[-\x60{-~\u203a\u2026\u00b7]+/g
    readonly property var pageKeys: ["ai", "editor", "style", "interface", "system", "keys", "config", "info"]
    readonly property var colorKeys: ["Background", "Accent", "Accent2", "Text", "Inactive", "Active", "Extra"]
    readonly property var transitions: ["none", "simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random"]
    readonly property var images: ["png", "jpg", "jpeg", "webp", "gif", "bmp"]
    readonly property var videos: ["mp4", "mkv", "webm", "mov", "avi", "m4v"]
    readonly property var easings: ["Linear"].concat(["Quad", "Cubic", "Quart", "Quint", "Sine", "Expo", "Circ", "Back", "Elastic", "Bounce"].reduce((all, k) => all.concat(["In" + k, "Out" + k, "InOut" + k, "OutIn" + k]), []))
    readonly property var tongueNames: ({ en: "English", ru: "Русский", sr: "Српски", vi: "Tiếng Việt", zh: "中文", ja: "日本語", ko: "한국어", fi: "Suomi" })
    readonly property var named: [
        { label: "Profile picture", alt: "avatar photo crop user", tab: "style", key: "Profile" },
        { label: "Setting presets", alt: "preset profile save load copy backup restore switch default", tab: "style", key: "Profile" },
        { label: "Media Player", alt: "music song disc bars visualizer violence drop beat", tab: "interface", key: "Media Player" },
        { label: "Wallpaper", alt: "background image video picture", tab: "style", key: "Wallpaper" },
        { label: "Lock screen picture", alt: "lockscreen background", tab: "style", key: "Wallpaper" },
        { label: "Editor", alt: "edit drag move resize canvas layout arrange visual", tab: "editor", key: "Editor" },
        { label: "Catbar position", alt: "bar top bottom left right side edge move", tab: "style", key: "Catbar" },
        { label: "Desktop widgets", alt: "clock date weather background wallpaper hands analog digital now playing", tab: "style", key: "Desktop widgets" },
        { label: "Wallpaper transition", alt: "animation wave wipe fade grow", tab: "style", key: "Transition" },
        { label: "Transition duration", alt: "wallpaper speed", tab: "style", key: "Transition" },
        { label: "Text font", alt: "typeface family", tab: "style", key: "Fonts" },
        { label: "Icon font", alt: "nerd glyph symbols", tab: "style", key: "Fonts" },
        { label: "Password mask", alt: "cypher cipher dots lock", tab: "style", key: "Password mask" },
        { label: "Theme", alt: "colors palette scheme", tab: "interface", key: "Theme" },
        { label: "Theme colours", alt: "colors background accent text active inactive extra", tab: "interface", key: "Colours" },
        { label: "Wallpaper colours", alt: "colors follow match matugen", tab: "interface", key: "Wallpaper colours" },
        { label: "Language", alt: "translation locale", tab: "interface", key: "Language" },
        { label: "Keyboard layout", alt: "keys input", tab: "interface", key: "Language" },
        { label: "Animation speed", alt: "motion change time easing", tab: "interface", key: "Motion" },
        { label: "Typing speed", alt: "type animation", tab: "interface", key: "Motion" },
        { label: "Scroll speed", alt: "wheel touchpad", tab: "interface", key: "Motion" },
        { label: "Night light", alt: "sunset warm blue", tab: "interface", key: "Night light" },
        { label: "Screenshot", alt: "snip print screen scissors capture smart selection window picture region", tab: "interface", key: "Screenshot" },
        { label: "Contrast", alt: "desktop widgets readable outline halo blend wallpaper clock", tab: "style", key: "Desktop widgets" },
        { label: "Modules", alt: "enable disable show hide panels", tab: "interface", key: "Modules" },
        { label: "Pinned bars", alt: "catbar sidebar taskbar stay open pin always visible", tab: "interface", key: "Bars" },
        { label: "Screen brightness", alt: "backlight display dim bright", tab: "system", key: "Display" },
        { label: "Automatic brightness", alt: "auto adaptive ambient light sensor", tab: "system", key: "Display" },
        { label: "Pixel shift", alt: "oled burn in care screen protect", tab: "system", key: "Screen care" },
        { label: "Animations", alt: "motion slide fade effects disable turn off reduce", tab: "system", key: "Animations" },
        { label: "Keyboard backlight", alt: "keys light glow brightness", tab: "system", key: "Keyboard" },
        { label: "Charge limit", alt: "battery care health threshold stop charging", tab: "system", key: "Battery care" },
        { label: "Mini player", alt: "small music bar corner spotify pop in out compact", tab: "interface", key: "Media Player" },
        { label: "Tint strength", alt: "media player background colour theme wash", tab: "interface", key: "Media Player" },
        { label: "Background clarity", alt: "media player cover picture blur blurred clear sharp strength catbar panel", tab: "interface", key: "Media Player" },
        { label: "Tempo spin", alt: "media player disc speed faster slower song tempo bpm", tab: "interface", key: "Media Player" },
        { label: "Wallpaper saturation", alt: "colour vivid grey black white lock screen", tab: "style", key: "Wallpaper" },
        { label: "Ripples", alt: "wallpaper next spam rings pond transition", tab: "style", key: "Transition" },
        { label: "Theme fade", alt: "colour change smooth blend animation wallpaper", tab: "interface", key: "Motion" },
        { label: "Wait for the wallpaper", alt: "unlock lock screen bars widgets appear fade", tab: "interface", key: "Motion" },
        { label: "Low battery warning", alt: "battery low notification warn percent empty", tab: "system", key: "Battery care" },
        { label: "Power mode", alt: "profile performance saver balanced", tab: "system", key: "Power" },
        { label: "Panda Hypr AI", alt: "assistant helper model snipping panda", tab: "ai", key: "Panda Hypr AI" },
        { label: "Keybinds", alt: "shortcuts keys hotkeys binds", tab: "keys", key: "" },
        { label: "Open config.json", alt: "edit file editor", tab: "config", key: "" },
        { label: "About", alt: "info sovakot credits", tab: "info", key: "" }
    ]

    readonly property string tabSig: JSON.stringify(s("settings_Tabs"))
    readonly property string hiddenSig: s("settings_HiddenTabs").join("\n")
    readonly property var tabs: {
        const own = JSON.parse(tabSig).filter(t => t && pageKeys.includes(t.Key)), stock = base.settings_Tabs, hidden = hiddenSig.split("\n")
        stock.forEach((t, i) => {
            if (own.some(o => o.Key === t.Key)) return
            const at = stock.slice(i + 1).map(n => own.findIndex(o => o.Key === n.Key)).find(n => n >= 0)
            own.splice(at === undefined ? own.length : at, 0, t)
        })
        return own.filter(t => !hidden.includes(t.Key))
    }
    readonly property int tabAt: tabs.findIndex(t => t.Key === tab)
    readonly property var themes: cfg?.Theme ?? ({})
    readonly property string themeSig: Object.keys(themes).join("\n")
    readonly property var themeNames: themeSig === "" ? [] : themeSig.split("\n")
    readonly property bool wallTheme: cfg?.dolphin_ThemeBackground === true
    readonly property string themeName: {
        if (wallTheme) return "Wallpaper"
        const n = String(cfg?.dolphin_Theme ?? "")
        return themes[n] ? n : themes[title(n)] ? title(n) : n
    }
    readonly property var theme: themes[themeName] ?? ({})
    readonly property string showSig: Object.keys(cfg ?? ({})).filter(k => /^[a-z]+_Show$/.test(k) && k !== "settings_Show").join("\n")
    readonly property var showKeys: showSig === "" ? [] : showSig.split("\n")
    readonly property var tongues: {
        const seen = { en: true }, all = Config.words
        for (const k in all) for (const l in all[k]) seen[l] = true
        return Object.keys(seen)
    }
    readonly property var stock: Config.stock
    readonly property color halo: shade(String(cfg?.hyprai_GuideColor ?? "Active"))
    readonly property real haloLine: Math.max(1, Number(cfg?.hyprai_GuideBorder ?? 2) || 2)
    readonly property var friendly: ({
        dolphin_Background: ["style", "Wallpaper", ""], dolphin_Lockscreen: ["style", "Wallpaper", ""], dolphin_BackgroundTransition: ["style", "Transition", ""],
        dolphin_BackgroundDuration: ["style", "Transition", "Duration"], dolphin_TextFont: ["style", "Fonts", "Text font"], dolphin_IconFont: ["style", "Fonts", "Icon font"],
        dolphin_Cypher: ["style", "Password mask", "Mask characters"], greeter_Avatar: ["style", "Profile", ""],
        Theme: ["interface", "Colours", ""], dolphin_Theme: ["interface", "Theme", ""], dolphin_ThemeBackground: ["interface", "Wallpaper colours", "Follow the wallpaper"],
        dolphin_ThemeMatch: ["interface", "Wallpaper colours", "Colour strength"], dolphin_Language: ["interface", "Language", ""], dolphin_KeyboardLayout: ["interface", "Language", "Keyboard layout"],
        dolphin_SettingsChangeTime: ["interface", "Motion", "Change time"], dolphin_SettingsEasingStyle: ["interface", "Motion", "Easing"], dolphin_TypeAnimationTime: ["interface", "Motion", "Typing speed"],
        dolphin_ScrollSpeed: ["interface", "Motion", "Scroll speed"], dolphin_Night: ["interface", "Night light", "Warm screen colours"], dolphin_NightStrength: ["interface", "Night light", "Strength"],
        system_PixelShift: ["system", "Screen care", "Pixel shift"], system_PixelShiftRadius: ["system", "Screen care", "Shift distance"], system_PixelShiftInterval: ["system", "Screen care", "Shift every"],
        system_Animations: ["system", "Animations", "Animations"], system_AutoBrightness: ["system", "Display", "Automatic brightness"],
        system_AutoBrightnessMin: ["system", "Display", "Darkest"], system_AutoBrightnessMax: ["system", "Display", "Brightest"],
        system_KeyboardLight: ["system", "Keyboard", "Keyboard backlight"], system_ChargeLimit: ["system", "Battery care", "Charge limit"], system_BatteryWarn: ["system", "Battery care", "Low battery warning"], system_BatteryWarnAt: ["system", "Battery care", "Warn at"],
        catbar_Pinned: ["interface", "Bars", "Catbar stays open"], sidebar_Pinned: ["interface", "Bars", "Sidebar stays open"], poodlebar_Pinned: ["interface", "Bars", "Taskbar stays open"],
        hyprai_Show: ["ai", "Panda Hypr AI", "Enabled"], hyprai_Visualization: ["ai", "Panda Hypr AI", "Visualization"], hyprai_Chatter: ["ai", "Panda Hypr AI", "Talks by itself"], hyprai_Files: ["ai", "Panda Hypr AI", "Read Dolphin's files"],
        hyprai_Model: ["ai", "Panda Hypr AI", "Model"], hyprai_MaxTokens: ["ai", "Answers", "Answer length"], hyprai_Temperature: ["ai", "Answers", "Creativity"],
        hyprai_SimpleEnglish: ["ai", "Answers", "Short answers"], hyprai_Thinking: ["ai", "Answers", "Think before answering"], hyprai_MemoryLimit: ["ai", "Memory", "Memory limit"],
        hyprai_Unload: ["ai", "Memory", "Keep loaded after closing"], hyprai_GpuLayers: ["ai", "Memory", "Use the graphics card"],
        dolphin_Preset: ["style", "Profile", "Setting presets"], desktop_Inverted: ["style", "Desktop widgets", "Inverted"], desktop_Contrast: ["style", "Desktop widgets", "Contrast"], snip_Smart: ["interface", "Screenshot", "Smart selection"], snip_Content: ["interface", "Screenshot", "Find pictures and boxes"], snip_Guides: ["interface", "Screenshot", "Guide lines"], snip_Labels: ["interface", "Screenshot", "Name and size"], desktop_ContrastStrength: ["style", "Desktop widgets", "Contrast strength"],
        media_Violence: ["interface", "Media Player", "Violence"], media_Sensitivity: ["interface", "Media Player", "Drop sensitivity"], media_BackdropBlur: ["interface", "Media Player", "Background clarity"], media_BackdropOpacity: ["interface", "Media Player", "Background strength"], widget_MediaBackdrop: ["interface", "Media Player", "Cover in the catbar panel"], media_Tempo: ["interface", "Media Player", "Tempo spin"], media_Gain: ["interface", "Media Player", "Bar height"], media_Sync: ["interface", "Media Player", "Beat timing"],
        media_FloorStyle: ["interface", "Media Player", "Bar style"], media_ThemeStrength: ["interface", "Media Player", "Tint strength"], media_Mini: ["interface", "Media Player", "Mini player"],
        media_MiniCorner: ["interface", "Media Player", "Mini player corner"], media_MiniWidth: ["interface", "Media Player", "Mini player width"], media_MiniHeight: ["interface", "Media Player", "Mini player height"],
        media_MiniScroll: ["interface", "Media Player", "Title scroll speed"], dolphin_BackgroundSaturation: ["style", "Wallpaper", "Wallpaper saturation"], lockscreen_Saturation: ["style", "Wallpaper", "Lock screen saturation"],
        dolphin_BackgroundRipple: ["style", "Transition", "Ripples"], dolphin_BackgroundNextTime: ["style", "Transition", "Ripple time"], dolphin_ThemeFade: ["interface", "Motion", "Theme fade"],
        dolphin_WaitUnlock: ["interface", "Motion", "Wait for the wallpaper"], dolphin_UnlockFade: ["interface", "Motion", "Unlock fade"],
        "theme colours": ["interface", "Colours", ""], "new theme": ["interface", "Theme", ""], "profile picture": ["style", "Profile", ""], "modules": ["interface", "Modules", ""],
        "keybinds": ["keys", "", ""], "super key": ["keys", "", ""]
    })
    readonly property var settingsTop: open ? (Hyprland.toplevels.values.find(h => h.title === "dolphin-settings" || h.title === "dolphin-settings-left") ?? null) : null
    readonly property int settingsRoom: settingsTop?.workspace?.id ?? room
    readonly property bool present: open && settingsRoom === (Hyprland.focusedWorkspace?.id ?? settingsRoom)
    readonly property var guideSpot: {
        const k = Guide.key
        if (k === "" || !s("settings_Show")) return null
        let f = friendly[k]
        if (!f && showKeys.includes(k)) f = ["interface", "Modules", String(moduleNames[k.split("_")[0]] ?? human(title(k.split("_")[0])))]
        if (f && tabs.some(t => t.Key === f[0])) return { tab: f[0], group: f[1], ctl: f[2] !== "", module: "", row: "", label: word(f[2] !== "" ? f[2] : f[1]) }
        if (!tabs.some(t => t.Key === "config")) return null
        const r = rows.find(x => !x.head && (x.id === k || x.id.indexOf(k + "/") === 0))
        if (!r) return null
        return { tab: "config", group: "", ctl: false, module: r.group, row: r.id, label: r.id === k ? r.label : human(k.indexOf("_") > 0 ? k.slice(k.indexOf("_") + 1) : k) }
    }
    readonly property var guideSteps: {
        const g = guideSpot
        if (!g) return []
        const t = tabs.find(x => x.Key === g.tab)
        const out = [word("Open Snoopy Settings"), word("Click the %1 tab").replace("%1", word(String(t?.Label ?? g.tab)))]
        if (g.tab === "config") out.push(word("Click %1").replace("%1", human(title(g.module))))
        if (g.label !== "") out.push(word("Change %1").replace("%1", g.label))
        return out
    }
    readonly property int guideAt: !guideSpot || !present ? 0 : tab !== guideSpot.tab ? 1 : guideSpot.tab === "config" && module !== guideSpot.module ? 2 : guideSpot.label !== "" ? guideSteps.length - 1 : guideSteps.length
    readonly property bool guideFinal: !!guideSpot && present && guideSpot.label !== "" && guideAt === guideSteps.length - 1
    readonly property string want: {
        const g = guideSpot
        if (!g || !present || Guide.done) return ""
        if (tab !== g.tab) return "tab:" + g.tab
        if (g.tab === "config") return module !== g.module ? "chip:" + g.module : "row:" + g.row
        return g.ctl ? "ctl:" + Guide.key : g.group !== "" ? "group:" + g.group : ""
    }
    readonly property string guideNow: Guide.key === "" ? "" : JSON.stringify(cfg?.[Guide.key] ?? null)
    readonly property bool busy: cropping !== "" || !!menu || !!pick || !!browse || !!asking || !!sure || presets

    property bool open: false
    property bool keys: false
    property string zone: "rail"
    property var sel: null
    property var pageItem: null
    property var tip: null
    property var infos: ({})
    property var choices: ({})
    property string only: ""
    readonly property var arrows: ({ [Qt.Key_Up]: "up", [Qt.Key_Down]: "down", [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Return]: "enter", [Qt.Key_Enter]: "enter" })
    property bool hopping: false
    property int room: 0
    property int epoch: 0
    property int keepW: 0
    property int keepH: 0
    property int nowW: 0
    property int nowH: 0
    property string tab: "style"
    property string query: ""
    property string module: ""
    property string hit: ""
    property var sure: null
    property var aim: null
    property var menu: null
    property var pick: null
    property var browse: null
    property bool presets: false
    property int presetAt: 0
    property var asking: null
    property string luaText: ""
    property string luaNext: ""
    property bool luaSaved: false
    property bool luaMissing: false
    property string recording: ""
    property string typing: ""
    property string keyNote: ""
    property var editors: []
    property string cropping: ""
    property string side: "right"
    property string pending: ""
    property bool avatarBusy: false
    property var rows: []
    property var modules: []
    property string rowSig: ""
    property var lookup: []
    property var thumbMap: ({})
    property int thumbRev: 0
    property var thumbQueue: []
    property string guideWas: ""
    property string guideFor: ""
    property var haloItem: null
    property var haloEdge: null
    property real winX: 0
    property real winY: 0
    property bool winKnown: false
    property int rush: 0

    signal unfocus()
    signal reveal(string key)
    signal revealRow(string key)
    signal playDemo()

    onLangChanged: buildIndex()
    onKeyGroupsChanged: buildIndex()
    onTabChanged: { recording = ""; typing = ""; keyNote = ""; zone = "rail"; sel = null; tip = null }
    onWantChanged: {
        guideFor = Guide.key
        guideWas = guideFinal ? guideNow : ""
        if (want !== "") guideTimer.restart()
        rush = 8
    }
    onGuideNowChanged: if (guideFor === Guide.key && guideWas !== "" && guideNow !== "" && guideNow !== guideWas && guideFinal) Guide.done = true
    onHaloItemChanged: {
        rush = 8
        findWindow()
        locate()
    }
    onHaloEdgeChanged: locate()
    onPresentChanged: {
        rush = 8
        if (present) findWindow()
        locate()
    }
    Component.onCompleted: stampLogo()
    onOpenChanged: {
        winKnown = false
        if (open) { Hyprland.refreshToplevels(); return }
        tip = null
        sel = null
        keys = false
        zone = "rail"
        only = ""
        if (hopping) return
        keepW = 0
        keepH = 0
        menu = null
        pick = null
        browse = null
        asking = null
        recording = ""
        typing = ""
        keyNote = ""
        cropping = ""
        query = ""
        module = ""
        hit = ""
        sure = null
    }

    function tone(k) {
        const n = String(s(k))
        if (!s("settings_Inverted") || n.startsWith("#")) return col(n)
        const c = Qt.alpha(col(n), 1)
        return Qt.rgba(1 - c.r, 1 - c.g, 1 - c.b, 1)
    }
    function abs(p) {
        p = String(p ?? "")
        return p === "" ? "" : p.startsWith("/") ? p : house + "/" + p.replace(/^~?\/*/, "")
    }
    function local(p) { return p.startsWith("/") || p.startsWith("~") ? abs(p) : dolphin + "/" + p }
    function rel(p) { return p.startsWith(house + "/") ? "~/" + p.slice(house.length + 1) : p }
    function url(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "" }
    function kind(p) {
        const e = String(p ?? "").split(".").pop().toLowerCase()
        return !p ? "" : videos.includes(e) ? "video" : "image"
    }
    function isHex(v) { return /^#([0-9a-f]{6}|[0-9a-f]{8})$/i.test(String(v ?? "")) }
    function hex(c, alpha) {
        const h = v => ("0" + Math.round(v * 255).toString(16)).slice(-2)
        return "#" + (alpha && c.a < 0.999 ? h(c.a) : "") + h(c.r) + h(c.g) + h(c.b)
    }
    function shade(v) { return isHex(v) ? String(v) : col(String(v)) }
    function human(k) { return String(k).replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/_/g, " ") }
    function fonts(nerd) {
        const l = Qt.fontFamilies()
        return (nerd ? l.filter(f => /Nerd Font|\bNF[MP]?\b/.test(f)) : l).map(f => ({ text: f, value: f, family: f }))
    }
    function folderOf(file) { return file ? file.replace(/\/[^\/]*$/, "") : abs(s("settings_WallpaperFolder")) }
    function startTab() {
        const t = s("settings_StartTab")
        return tabs.some(x => x.Key === t) ? t : tabs[0]?.Key ?? "style"
    }

    function spot() {
        const t = Hyprland.toplevels.values.find(h => h.title === "dolphin-settings" || h.title === "dolphin-settings-left")
        return t?.workspace?.id ?? t?.lastIpcObject?.workspace?.id ?? room
    }
    function show(dir) {
        side = dir
        room = Hyprland.focusedWorkspace?.id ?? 0
        epoch++
        syncRows()
        open = true
    }
    function toggle() {
        if (!s("settings_Show") || hop.running) return
        if (!open) { tab = startTab(); return show("right") }
        const now = Hyprland.focusedWorkspace?.id ?? 0, at = spot()
        if (at === now) { open = false; return }
        hopping = true
        keepW = nowW
        keepH = nowH
        open = false
        side = at > now ? "right" : "left"
        hop.restart()
    }
    function back() {
        if (cropping !== "") cropping = ""
        else if (sure) sure = null
        else if (asking) asking = null
        else if (pick) pick = null
        else if (menu) menu = null
        else if (browse) browse = null
        else if (presets) presets = false
        else if (keys && zone === "page") { zone = "rail"; sel = null }
        else open = false
    }
    function presetKey(k) {
        const all = [Presets.stockName].concat(Presets.names)
        if (k === Qt.Key_Up) presetAt = Math.max(0, presetAt - 1)
        else if (k === Qt.Key_Down) presetAt = Math.min(all.length - 1, presetAt + 1)
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) Presets.use(all[Math.min(presetAt, all.length - 1)])
        else return false
        keys = true
        return true
    }
    function look(k) {
        const key = String(k), at = key.indexOf("_"), g = at > 0 ? key.slice(0, at) : key
        if (!s("settings_Show")) return
        if (!open) show("right")
        tab = "config"
        module = modules.includes(g) ? g : ""
        only = at > 0 && key.length > at + 1 ? key : ""
    }
    function hint(item, text) {
        if (!text) return
        const p = item.mapToItem(null, 0, 0)
        tip = { owner: item, text: text, x: p.x + item.width / 2, y: p.y, h: item.height }
    }
    function unhint(item) { if (tip && tip.owner === item) tip = null }
    function info(k) {
        const id = String(k), p = id.split("/")
        if (infos[id]) return infos[id]
        if (p.length > 2 && infos[p[0] + "/*/" + p.slice(2).join("/")]) return infos[p[0] + "/*/" + p.slice(2).join("/")]
        for (let i = p.length - 1; i > 0; i--) if (infos[p.slice(0, i).join("/")]) return infos[p.slice(0, i).join("/")]
        return ""
    }
    function learn(text) {
        const out = {}, picks = {}
        for (const l of String(text).split("\n")) {
            if (l === "" || l[0] === "#" || l[0] === "!" || l.startsWith("file ")) continue
            const p = l.split(" | ")
            if (p.length < 4) continue
            out[p[0]] = p[2] + "\n" + p[3]
            const col = p[3].trim(), list = []
            const rx = col[0] === "\"" ? /"([^"]+)"(?:\s*=\s*([^,"]+)|\s*\(([^)]*)\))?/g : /^a number/.test(col) ? /(-?\d+) = ([^,;]+)/g : null
            if (rx) for (let m = rx.exec(col); m; m = rx.exec(col)) list.push({ text: m[1] + (m[2] || m[3] ? "  \u00b7  " + String(m[2] || m[3]).trim() : ""), value: m[1] })
            if (list.length > 1) picks[p[0]] = list
        }
        infos = out
        choices = picks
    }
    function keyInto(item, k) {
        if (!item || !item.visible) return false
        if (typeof item.key === "function") return item.key(k) === true
        const list = item.children
        for (let i = 0; i < list.length; i++) if (keyInto(list[i], k)) return true
        return false
    }
    function reach(item) {
        const f = flickOf(item)
        if (!f) return
        const y = item.mapToItem(f.contentItem, 0, 0).y, end = Math.max(0, f.contentHeight - f.height)
        if (y - gap < f.contentY) f.contentY = Math.max(0, y - gap)
        else if (y + item.height + gap > f.contentY + f.height) f.contentY = Math.min(end, y + item.height + gap - f.height)
    }
    function arrow(k) {
        const p = pageItem, can = !!p && typeof p.nav === "function"
        tip = null
        if (!keys) {
            keys = true
            if (zone === "page" && !sel && !(can && p.held === true)) zone = "rail"
        }
        if (zone === "rail") {
            if (k === "up") step(-1)
            else if (k === "down") step(1)
            else if ((k === "right" || k === "enter") && can && p.nav("first")) zone = "page"
            return
        }
        if (can && p.nav(k)) return
        if (k === "left") { zone = "rail"; sel = null }
    }
    function step(d) {
        if (!tabs.length) return
        tab = tabs[(Math.max(0, tabAt) + d + tabs.length) % tabs.length].Key
    }

    function dig(o, path) {
        for (const k of path) {
            if (o === undefined || o === null) return undefined
            o = o[k]
        }
        return o
    }
    function span(src, path) {
        const n = src.length, W = " \t\r\n"
        let i = 0, k0 = 0
        const ws = () => { while (i < n && W.includes(src[i])) i++ }
        const str = () => { const a = i++; while (i < n && src[i] !== "\"") i += src[i] === "\\" ? 2 : 1; i++; return src.slice(a + 1, i - 1) }
        const skip = () => {
            ws()
            if (src[i] === "\"") { str(); return }
            if (src[i] === "{" || src[i] === "[") {
                let d = 0
                while (i < n) {
                    const ch = src[i]
                    if (ch === "\"") { str(); continue }
                    i++
                    if (ch === "{" || ch === "[") d++
                    else if ((ch === "}" || ch === "]") && --d === 0) return
                }
                return
            }
            while (i < n && !",}]".includes(src[i]) && !W.includes(src[i])) i++
        }
        for (let d = 0; ; d++) {
            ws()
            if (d === path.length) { const a = i; skip(); return { start: a, end: i, key: k0 } }
            if (src[i] !== "{") return null
            i++
            let found = false
            while (i < n) {
                ws()
                if (src[i] === "}") return d === path.length - 1 ? { missing: true, close: i, depth: d } : null
                if (src[i] !== "\"") return null
                const ka = i, k = str()
                ws()
                i++
                if (k === path[d]) { k0 = ka; found = true; break }
                skip()
                ws()
                if (src[i] === ",") i++
            }
            if (!found) return null
        }
    }
    function anchor(src, prefix) {
        const n = src.length, W = " \t\r\n"
        let i = 0, best = -1
        const ws = () => { while (i < n && W.includes(src[i])) i++ }
        const str = () => { const a = i++; while (i < n && src[i] !== "\"") i += src[i] === "\\" ? 2 : 1; i++; return src.slice(a + 1, i - 1) }
        const skip = () => {
            ws()
            if (src[i] === "\"") { str(); return }
            if (src[i] === "{" || src[i] === "[") {
                let d = 0
                while (i < n) {
                    const ch = src[i]
                    if (ch === "\"") { str(); continue }
                    i++
                    if (ch === "{" || ch === "[") d++
                    else if ((ch === "}" || ch === "]") && --d === 0) return
                }
                return
            }
            while (i < n && !",}]".includes(src[i]) && !W.includes(src[i])) i++
        }
        ws()
        if (src[i] !== "{") return -1
        i++
        while (i < n) {
            ws()
            if (src[i] !== "\"") return best
            const k = str()
            ws()
            i++
            skip()
            if (k.startsWith(prefix)) best = i
            else if (best >= 0) return best
            ws()
            if (src[i] === ",") i++
        }
        return best
    }
    function edit(src, path, text) {
        const r = span(src, path), W = " \t\r\n"
        if (!r) return src
        if (!r.missing) return src.slice(0, r.start) + text + src.slice(r.end)
        const under = r.depth === 0 ? String(path[0]).indexOf("_") : -1
        const spot = under > 0 ? anchor(src, String(path[0]).slice(0, under + 1)) : -1
        if (spot >= 0) return src.slice(0, spot) + ",\n    " + JSON.stringify(path[0]) + " : " + text + src.slice(spot)
        let p = r.close
        while (p > 0 && W.includes(src[p - 1])) p--
        return src.slice(0, p) + (src[p - 1] === "{" || src[p - 1] === "," ? "" : ",") + "\n" + "    ".repeat(r.depth + 1) + JSON.stringify(path[r.depth]) + " : " + text + src.slice(p)
    }
    function cut(src, path) {
        const r = span(src, path), W = " \t\r\n"
        if (!r || r.missing) return src
        let a = r.key, b = r.end, j = b
        while (j < src.length && W.includes(src[j])) j++
        if (src[j] === ",") b = j + 1
        else {
            let k = a - 1
            while (k >= 0 && W.includes(src[k])) k--
            if (src[k] === ",") a = k
        }
        while (a > 0 && " \t".includes(src[a - 1])) a--
        if (src[a - 1] === "\n") a--
        return src.slice(0, a) + src.slice(b)
    }
    function ink(v, depth) {
        if (!Config.plain(v)) return JSON.stringify(v)
        const keys = Object.keys(v), pad = "    ".repeat(depth + 1)
        if (!keys.length) return "{}"
        return "{\n" + keys.map(k => pad + JSON.stringify(k) + " : " + ink(v[k], depth + 1)).join(",\n") + "\n" + "    ".repeat(depth) + "}"
    }
    function put(src, path, v) {
        for (let n = path.length; n > 0; n--) {
            const head = path.slice(0, n)
            if (!span(src, head)) continue
            if (n === path.length) return edit(src, head, ink(v, n))
            const kept = dig(Config.values, head)
            const whole = Config.plain(kept) ? JSON.parse(JSON.stringify(kept)) : {}
            let o = whole
            for (let i = n; i < path.length - 1; i++) {
                if (!Config.plain(o[path[i]])) o[path[i]] = {}
                o = o[path[i]]
            }
            o[path[path.length - 1]] = v
            return edit(src, head, ink(whole, n))
        }
        return src
    }
    function commit(out) {
        if (!Config.valid || out === Config.body || Config.obj(out) === null) return
        Config.write(out)
    }
    function set(path, v) { commit(put(Config.body, path, v)) }
    function setMany(list) {
        let out = Config.body
        for (const e of list) out = put(out, e[0], e[1])
        commit(out)
    }
    function reset(path) {
        const first = dig(stock, path)
        if (first === undefined) commit(cut(Config.body, path))
        else set(path, first)
    }

    function useTheme(n) {
        if (n === "Wallpaper") set(["dolphin_ThemeBackground"], true)
        else setMany([[["dolphin_Theme"], n], [["dolphin_ThemeBackground"], false]])
    }
    function freeName() {
        let n = 1
        while (themes["Theme " + n]) n++
        return "Theme " + n
    }
    function addTheme(name) {
        const n = String(name ?? "").trim()
        if (n === "" || /["\\]/.test(n) || themes[n]) return false
        const copy = {}
        for (const k of colorKeys) copy[k] = String(theme[k] ?? "#000000")
        setMany([[["Theme", n], copy], [["dolphin_Theme"], n], [["dolphin_ThemeBackground"], false]])
        return true
    }
    function dropTheme(n) {
        let out = cut(Config.body, ["Theme", n])
        if (cfg?.dolphin_Theme === n) out = put(out, ["dolphin_Theme"], "Default")
        commit(out)
    }
    function renameTheme(old, name) {
        const n = String(name ?? "").trim(), src = Config.body
        if (n === old) return true
        if (n === "" || /["\\]/.test(n) || themes[n]) return false
        const r = span(src, ["Theme", old])
        if (!r || r.missing) return false
        let b = r.key + 1
        while (b < src.length && src[b] !== "\"") b += src[b] === "\\" ? 2 : 1
        let out = src.slice(0, r.key) + JSON.stringify(n) + src.slice(b + 1)
        if (cfg?.dolphin_Theme === old) out = put(out, ["dolphin_Theme"], n)
        commit(out)
        return true
    }

    function sortOf(group, key, v) {
        if (typeof v === "boolean") return "bool"
        if (typeof v === "number") return "num"
        if (typeof v !== "string") return "raw"
        if (/Color$/.test(key) || isHex(v) || (group === "Kde" && colorKeys.includes(v))) return "color"
        if (/Icon$/.test(key) && /^[0-9a-fA-F]{3,6}$/.test(v)) return "icon"
        if (/Easing(Style)?$/.test(key)) return "ease"
        if (/Font$/.test(key)) return "font"
        return "text"
    }
    function syncRows() {
        const all = Config.values, groups = {}, order = []
        const push = (g, row) => {
            if (!groups[g]) { groups[g] = []; order.push(g) }
            groups[g].push(row)
        }
        const walk = (g, path, names, o) => {
            for (const k in o) {
                const v = o[k], p = path.concat([k]), n = names.concat([human(k)])
                if (Config.plain(v)) walk(g, p, n, v)
                else push(g, { id: p.join("/"), path: p, group: g, label: n.join(" \u203a "), kind: sortOf(g, k, v) })
            }
        }
        for (const k in all) {
            const v = all[k]
            if (k === "Theme") continue
            const at = k.indexOf("_")
            if (Config.plain(v)) { walk(at > 0 ? k.slice(0, at) : k, [k], at > 0 ? [human(k.slice(at + 1))] : [], v); continue }
            const g = at > 0 ? k.slice(0, at) : "other"
            push(g, { id: k, path: [k], group: g, label: human(at > 0 ? k.slice(at + 1) : k), kind: sortOf(g, k, v) })
        }
        const first = order.indexOf("dolphin")
        if (first > 0) { order.splice(first, 1); order.unshift("dolphin") }
        const out = []
        for (const g of order) {
            out.push({ id: "#" + g, head: human(title(g)), group: g })
            for (const r of groups[g]) out.push(r)
        }
        const sig = out.map(r => r.id + ":" + (r.kind ?? "")).join("\n")
        if (sig === rowSig) return
        rowSig = sig
        modules = order
        rows = out
        buildIndex()
    }
    function buildIndex() {
        const flat = t => t.toLowerCase().replace(gaps, "")
        const words = t => t.replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase().split(gaps).filter(w => w)
        const out = []
        const add = (label, sub, key, tab, alt, bias) => out.push({ label: label, sub: sub, key: key, tab: tab, bias: bias, flat: flat(label), words: words(label), altFlat: alt ? flat(alt) : "", altWords: alt ? words(alt) : [] })
        for (const e of named) add(e.label, "", e.key, e.tab, e.alt + (word(e.label) !== e.label ? " " + word(e.label) : ""), 0)
        for (const g of keyGroups) for (const b of g.binds) add(word(b.name) + (b.tail ? " " + b.tail : ""), "", b.id, "keys", b.name + " " + b.tail + " " + b.tokens.join(" ") + " " + b.detail, 0.3)
        for (const r of rows) if (!r.head) add(r.label, human(title(r.group)), r.id, "config", r.group + " " + r.label, 0.5)
        lookup = out
    }
    function search(text) {
        const q = String(text).trim().toLowerCase(), qf = q.replace(gaps, ""), limit = Math.max(1, s("settings_SearchLimit"))
        if (!qf) return []
        const list = lookup, toks = q.split(gaps).filter(x => x), out = [], rest = []
        for (let i = 0; i < list.length; i++) {
            const e = list[i]
            let at = e.flat.indexOf(qf), sc = -1
            if (at >= 0) sc = at * 0.01 + e.flat.length * 0.0001
            else if (e.altFlat) {
                at = e.altFlat.indexOf(qf)
                if (at >= 0) sc = 0.2 + at * 0.01 + e.altFlat.length * 0.0001
            }
            if (sc >= 0) out.push({ sc: sc + e.bias, e: e })
            else rest.push(e)
        }
        if (out.length < limit) {
            let a = [], b = []
            const dist = (t, w, max) => {
                const n = t.length, m = Math.min(w.length, n + max)
                if (m < n - max) return 99
                for (let j = 0; j <= m; j++) a[j] = j
                for (let i = 1; i <= n; i++) {
                    const ch = t.charCodeAt(i - 1)
                    let low = i
                    b[0] = i
                    for (let j = 1; j <= m; j++) {
                        let v = a[j - 1] + (ch === w.charCodeAt(j - 1) ? 0 : 1)
                        if (a[j] + 1 < v) v = a[j] + 1
                        if (b[j - 1] + 1 < v) v = b[j - 1] + 1
                        b[j] = v
                        if (v < low) low = v
                    }
                    if (low > max) return 99
                    const turn = a
                    a = b
                    b = turn
                }
                let best = 99
                for (let j = Math.max(0, n - max); j <= m; j++) if (a[j] < best) best = a[j]
                return best
            }
            const fuzz = (flat, words) => {
                let total = 1
                for (let k = 0; k < toks.length; k++) {
                    const t = toks[k]
                    if (flat.includes(t)) continue
                    if (t.length < 3) return 99
                    const max = Math.max(1, Math.floor(t.length / 3))
                    let best = 99
                    for (let i = 0; i < words.length && best > 0; i++) {
                        const d = dist(t, words[i], max)
                        if (d < best) best = d
                    }
                    if (best > max) return 99
                    total += best
                }
                return total
            }
            for (let i = 0; i < rest.length; i++) {
                const e = rest[i]
                let sc = fuzz(e.flat, e.words)
                if (sc >= 99 && e.altFlat) {
                    sc = fuzz(e.altFlat, e.altWords)
                    if (sc < 99) sc += 0.2
                }
                if (sc < 99) out.push({ sc: sc + e.bias, e: e })
            }
        }
        out.sort((x, y) => x.sc - y.sc)
        return out.slice(0, limit).map(o => o.e)
    }
    function go(e) {
        menu = null
        pick = null
        browse = null
        if (e.tab === "config") module = ""
        tab = e.tab
        hit = e.key
        aim = e
        hitTimer.restart()
        goTimer.restart()
    }
    function flickOf(it) {
        let f = it ? it.parent : null
        while (f && f.contentY === undefined) f = f.parent
        return f ?? null
    }
    function findWindow() {
        if (!whereProc.running) whereProc.running = true
    }
    function placed(text) {
        let list = null
        try { list = JSON.parse(text) } catch (e) { return }
        if (!Array.isArray(list)) return
        const c = list.find(x => x && (x.title === "dolphin-settings" || x.title === "dolphin-settings-left"))
        if (!c || !Array.isArray(c.at)) return
        const mon = Hyprland.monitors.values.find(m => m.id === c.monitor)
        winX = Number(c.at[0]) - Number(mon?.x ?? 0)
        winY = Number(c.at[1]) - Number(mon?.y ?? 0)
        winKnown = true
        Guide.monitor = String(mon?.name ?? "")
        locate()
    }
    function locate() {
        const it = haloItem ?? haloEdge
        if (!it || !present || Guide.key === "" || Guide.done) { if (Guide.spot) Guide.spot = null; return }
        if (!winKnown) { findWindow(); return }
        const p = it.mapToItem(null, 0, 0), f = flickOf(it)
        let y = p.y
        if (f) {
            const v = f.mapToItem(null, 0, 0)
            y = Math.max(v.y, Math.min(v.y + f.height - it.height, y))
        }
        const next = Qt.rect(Math.round(winX + p.x), Math.round(winY + y), Math.round(it.width), Math.round(it.height))
        const was = Guide.spot
        Guide.mark = want
        if (!was || was.x !== next.x || was.y !== next.y || was.width !== next.width || was.height !== next.height) Guide.spot = next
    }
    function scrollTo(item) {
        let f = item.parent
        while (f && f.contentY === undefined) f = f.parent
        if (f) f.contentY = Math.max(0, Math.min(item.mapToItem(f.contentItem, 0, 0).y - gap, f.contentHeight - f.height))
    }

    function openMenu(item, options, current, filter, done) {
        const p = item.mapToItem(null, 0, 0)
        menu = { x: p.x, y: p.y, w: item.width, h: item.height, options: options.map(o => typeof o === "string" ? { text: o, value: o } : o), current: current, filter: filter, done: done }
    }
    function openPicker(item, value, alpha, done) {
        const p = item.mapToItem(null, 0, 0)
        pick = { x: p.x, y: p.y, h: item.height, value: value, alpha: alpha, done: done }
    }
    function browseFor(label, dir, exts, done) { browse = { title: label, dir: dir, exts: exts, done: done } }
    function paint(item, path, value, alpha) {
        const opts = colorKeys.map(k => ({ text: k, value: k, tint: col(k) })).concat([{ text: word("Custom") + "\u2026", value: "#" }])
        openMenu(item, opts, String(value), false, v => {
            if (v === "#") openPicker(item, shade(value), alpha, h => set(path, h))
            else set(path, v)
        })
    }
    function quote(t) { return "'" + String(t).replace(/'/g, "'\\''") + "'" }
    function openFile(path) {
        if (launch.running) return
        pending = path
        launch.command = ["sh", "-c", "command -v \"$1\" >/dev/null 2>&1 || exit 127; setsid -f \"$@\" >/dev/null 2>&1", "sh"].concat(editor.split(/\s+/).filter(x => x), [path])
        launch.running = true
    }
    function edited() { openFile(configFile) }
    function ask(path) {
        asking = { path: path }
        if (!probe.running) probe.running = true
    }
    function useEditor(cmd) {
        const c = String(cmd ?? "").trim(), path = asking ? asking.path : ""
        if (c === "") return false
        asking = null
        set(["dolphin_EditorDefault"], c)
        if (path !== "") openFile(path)
        return true
    }
    function openFolder(path) {
        const cmd = String(cfg?.dolphin_FileManager ?? "dolphin --new-window").trim() + " " + quote(path)
        Quickshell.execDetached(["sh", "-c", "[ \"$(hyprctl dispatch \"$1\" 2>/dev/null)\" = ok ] || setsid -f sh -c \"$2\" >/dev/null 2>&1", "sh", "hl.dsp.exec_cmd(" + JSON.stringify(cmd) + ", { float = true, center = true })", cmd])
    }

    function thumbCmd(list) { return ["sh", "-c", thumbScript, "sh", thumbDir, String(Math.max(64, Math.round(s("settings_ThumbSize"))))].concat(list) }
    function thumb(p) { return thumbRev >= 0 && p && thumbMap[p] ? url(thumbMap[p]) : "" }
    function gotThumb(line) {
        const i = line.indexOf("\t")
        if (i <= 0) return
        thumbMap[line.slice(0, i)] = line.slice(i + 1)
        thumbRev++
    }
    function wantThumbs(list) {
        const add = list.filter((p, i) => p && !thumbMap[p] && !thumbQueue.includes(p) && list.indexOf(p) === i)
        if (!add.length) return
        thumbQueue = thumbQueue.concat(add)
        if (!thumber.running) nextThumbs()
    }
    function nextThumbs() {
        if (!thumbQueue.length || !open) return
        thumber.command = thumbCmd(thumbQueue)
        thumbQueue = []
        thumber.running = true
    }
    function luaArgs(src, start) {
        const out = [], n = src.length, W = " \t\r\n"
        const piece = (a, b) => {
            while (a < b && W.includes(src[a])) a++
            while (b > a && W.includes(src[b - 1])) b--
            return { start: a, end: b, text: src.slice(a, b) }
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
        let name = a, tail = "", detail = "", group = "Other", global = ""
        if (m) {
            const fn = m[1], arg = m[2].trim()
            const lit = arg.match(/^"([\s\S]*)"$/) || arg.match(/^'([\s\S]*)'$/) || arg.match(/^\[\[([\s\S]*)\]\]$/)
            const val = lit ? lit[1] : vars[arg] !== undefined ? vars[arg] : arg
            if (fn === "global") { name = actions[val] ?? oldActions[val] ?? val; group = "Dolphin"; global = val }
            else if (fn === "exec_cmd" || fn === "exec_raw") {
                const known = commandNames.find(c => c[0].test(val)), prog = val.trim().split(/\s+/)[0].split("/").pop()
                group = "Programs"
                detail = val
                if (known) name = known[1]
                else if (/^[A-Za-z0-9][\w.+-]*$/.test(prog) && !["for", "while", "if", "sh", "bash", "env", "pkill"].includes(prog)) { name = "Run"; tail = prog }
                else name = "Run a command"
            } else {
                name = dispatchNames[fn] ?? fn + "(" + arg + ")"
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
        return { name: name, tail: tail, detail: detail, group: group, global: global }
    }
    function parseBinds(text) {
        const vars = {}, out = [], used = {}, spots = {}
        let last = -1
        if (!text) return { vars: vars, binds: out, last: last, modVar: "", spots: spots }
        const lines = text.split("\n")
        let at = 0
        for (let n = 0; n < lines.length; n++) {
            const line = lines[n], begin = at
            at += line.length + 1
            const v = line.match(/^(\s*local\s+([A-Za-z_]\w*)\s*=\s*)"([^"]*)"/)
            if (v) {
                vars[v[2]] = v[3]
                spots[v[2]] = { start: begin + v[1].length, end: begin + v[1].length + v[3].length + 2 }
            }
            const hit = line.indexOf("hl.bind(")
            if (hit < 0) continue
            const note = line.indexOf("--")
            if (note >= 0 && note < hit) continue
            const args = luaArgs(text, begin + hit + 8)
            if (!args || args.length < 2) continue
            const k = args[0].text
            let combo = "", modVar = "", editable = true
            let m = k.match(/^([A-Za-z_]\w*)\s*\.\.\s*"([^"]*)"$/)
            if (m && vars[m[1]] !== undefined) { combo = vars[m[1]] + m[2]; modVar = m[1]; used[modVar] = (used[modVar] ?? 0) + 1 }
            else if ((m = k.match(/^"([^"]*)"$/)) || (m = k.match(/^'([^']*)'$/))) combo = m[1]
            else {
                editable = false
                combo = k.split("..").map(p => {
                    const t = p.trim(), q = t.match(/^"([^"]*)"$/)
                    return q ? q[1] : vars[t] !== undefined ? vars[t] : "[" + t + "]"
                }).join("")
            }
            const tokens = combo.split("+").map(t => t.trim()).filter(t => t)
            const d = describe(args[1].text, vars, combo)
            if (line[0] !== " " && line[0] !== "\t") last = n
            out.push({ id: "L" + (n + 1), line: n, start: args[0].start, end: args[0].end, combo: editable ? combo : "", tokens: tokens, editable: editable, modVar: modVar, name: d.name, tail: d.tail, detail: d.detail, group: d.group, global: d.global, fresh: false })
        }
        let best = ""
        for (const u in used) if (best === "" || used[u] > used[best]) best = u
        return { vars: vars, binds: out, last: last, modVar: best, spots: spots }
    }
    function comboKey(tokens) { return tokens.slice(0, -1).map(t => t.toUpperCase()).sort().join("+") + "+" + String(tokens[tokens.length - 1] ?? "").toLowerCase() }
    function groupBinds(km) {
        const by = {}, have = {}, counts = {}
        for (const b of km.binds) {
            (by[b.group] = by[b.group] ?? []).push(b)
            if (b.global) have[b.global] = true
            if (b.combo) counts[comboKey(b.tokens)] = (counts[comboKey(b.tokens)] ?? 0) + 1
        }
        if (luaText !== "") for (const a in actions) if (!have[a]) (by.Dolphin = by.Dolphin ?? []).push({ id: "new:" + a, line: -1, start: 0, end: 0, combo: "", tokens: [], editable: true, modVar: "", name: actions[a], tail: "", detail: "", group: "Dolphin", global: a, fresh: true })
        return groupOrder.filter(g => by[g]).map(g => ({ name: g, binds: by[g].map(b => Object.assign({}, b, { clash: b.combo !== "" && counts[comboKey(b.tokens)] > 1 })) }))
    }
    function bindText(b, tokens) {
        const combo = tokens.join(" + ")
        if (!tokens.length || !/^[A-Za-z0-9_:+ ]+$/.test(combo) || tokens.some(t => t.includes("+"))) return ""
        const km = keymap, mv = b.modVar || km.modVar
        const expr = mv !== "" && km.vars[mv] === tokens[0] && tokens.length > 1 ? mv + " .. " + JSON.stringify(" + " + tokens.slice(1).join(" + ")) : JSON.stringify(combo)
        if (!b.fresh) return luaText.slice(0, b.start) + expr + luaText.slice(b.end)
        const lines = luaText.split("\n"), row = "hl.bind(" + expr + ", hl.dsp.global(" + JSON.stringify(b.global) + "))"
        if (km.last >= 0) lines.splice(km.last + 1, 0, row)
        else lines.push(row)
        return lines.join("\n")
    }
    function setMod(v) {
        const km = keymap, at = km.spots[km.modVar]
        if (!at || !/^[A-Za-z_]+$/.test(v)) return
        writeLua(luaText.slice(0, at.start) + JSON.stringify(v) + luaText.slice(at.end))
    }
    function setKeys(b, tokens) {
        const out = bindText(b, tokens)
        if (out === "") return false
        writeLua(out)
        return true
    }
    function typeKeys(b, text) {
        const names = { super: "SUPER", win: "SUPER", mod4: "SUPER", meta: "SUPER", ctrl: "CTRL", control: "CTRL", alt: "ALT", shift: "SHIFT" }
        return setKeys(b, String(text).split("+").map(x => x.trim()).filter(x => x).map(x => names[x.toLowerCase()] ?? (x.length === 1 ? x.toUpperCase() : x)))
    }
    function keyName(e) {
        const k = e.key
        if ((k >= Qt.Key_A && k <= Qt.Key_Z) || (k >= Qt.Key_0 && k <= Qt.Key_9)) return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1)
        const known = keyNames.find(p => p[0] === k)
        return known ? known[1] : e.nativeScanCode > 0 ? "code:" + e.nativeScanCode : ""
    }
    function capture(e) {
        const k = e.key, hold = e.modifiers & (Qt.MetaModifier | Qt.ControlModifier | Qt.AltModifier)
        if (k === Qt.Key_Escape && !hold && !(e.modifiers & Qt.ShiftModifier)) { recording = ""; return }
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr, Qt.Key_CapsLock, Qt.Key_unknown].includes(k)) return
        const name = keyName(e)
        if (name === "") return
        if (!hold && !/^(F\d+|Print|Pause|Menu)$/.test(name)) { keyNote = word("Hold Super, Ctrl or Alt together with the key."); return }
        const t = []
        if (e.modifiers & Qt.MetaModifier) t.push("SUPER")
        if (e.modifiers & Qt.ControlModifier) t.push("CTRL")
        if (e.modifiers & Qt.AltModifier) t.push("ALT")
        if (e.modifiers & Qt.ShiftModifier) t.push("SHIFT")
        t.push(name)
        let b = null
        for (const g of keyGroups) b = b ?? g.binds.find(x => x.id === recording) ?? null
        recording = ""
        keyNote = ""
        if (b) setKeys(b, t)
    }
    function writeLua(out) {
        if (out === luaText || keep.running || luaPush.running) return
        luaNext = out
        if (luaSaved) return luaPush.restart()
        keep.command = ["cp", "-f", luaPath, luaPath + ".bak"]
        keep.running = true
    }
    function pushLua() {
        luaText = luaNext
        luaFile.setText(luaNext)
        luaReload.restart()
    }
    function stampLogo() {
        if (logo.running) return
        logo.command = ["sh", "-c", logoScript, "sh", here + "/" + infoPicture, dolphin + "/Data/Dynamic/sovakot.json", logoFile, String(Math.max(1, mug.zoom)), String(mug.offsetX), String(mug.offsetY)]
        logo.running = true
    }
    function setAvatar(src) {
        if (src === avatarFile || avatarProc.running) return
        avatarBusy = true
        avatarProc.command = ["sh", "-c", "ffmpeg -v error -y -i \"$1\" -frames:v 1 \"$2\" || cp -f \"$1\" \"$2\"", "sh", src, avatarFile]
        avatarProc.running = true
    }

    Connections {
        target: Reveal
        function onInspect(key) { root.look(key) }
    }
    FileView {
        path: root.open ? root.contextFile : ""
        blockLoading: true
        printErrors: false
        onLoaded: root.learn(text())
    }
    FileView {
        id: cropFile
        path: root.dolphin + "/Data/Dynamic/crop.json"
        blockLoading: true
        watchChanges: true
        atomicWrites: false
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: crop
            property real zoom: 1
            property real offsetX: 0
            property real offsetY: 0
        }
    }

    FileView {
        id: luaFile
        path: root.open || root.hopping ? root.luaPath : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { root.luaMissing = false; root.luaText = text() }
        onLoadFailed: { root.luaMissing = root.open; root.luaText = "" }
    }
    FileView {
        id: mugFile
        path: root.dolphin + "/Data/Dynamic/sovakot.json"
        blockLoading: true
        watchChanges: true
        atomicWrites: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.stampLogo()
        JsonAdapter {
            id: mug
            property real zoom: 1
            property real offsetX: 0
            property real offsetY: 0
        }
    }

    Process {
        id: keep
        onExited: (exitCode, exitStatus) => {
            root.luaSaved = exitCode === 0
            if (exitCode === 0) root.pushLua()
            else root.keyNote = root.word("hyprland.lua could not be backed up, so nothing was changed.")
        }
    }
    Timer { id: luaPush; interval: 0; onTriggered: root.pushLua() }
    Timer { id: luaReload; interval: 200; onTriggered: Quickshell.execDetached(["hyprctl", "reload"]) }
    Process {
        id: logo
        stdout: StdioCollector { onStreamFinished: if (text.includes("made")) Emblem.stamp++ }
    }
    Process {
        id: launch
        onExited: (exitCode, exitStatus) => { if (exitCode !== 0) root.ask(root.pending) }
    }
    Process {
        id: probe
        command: ["sh", "-c", "for e in codium vscodium code code-oss zeditor zed kate kwrite gnome-text-editor gedit mousepad xed pluma geany subl lapce emacs; do command -v $e >/dev/null 2>&1 && echo $e; done; for t in kitty foot alacritty ghostty wezterm konsole; do command -v $t >/dev/null 2>&1 || continue; for e in nvim hx vim micro nano; do command -v $e >/dev/null 2>&1 && echo \"$t -e $e\"; done; break; done"]
        stdout: StdioCollector { onStreamFinished: root.editors = text.split("\n").filter(l => l !== "") }
    }
    Process {
        id: thumber
        stdout: SplitParser { onRead: line => root.gotThumb(line) }
        onExited: root.nextThumbs()
    }
    Process {
        id: avatarProc
        onExited: {
            crop.zoom = 1
            crop.offsetX = 0
            crop.offsetY = 0
            cropFile.writeAdapter()
            root.avatarBusy = false
        }
    }

    Timer { id: hop; interval: 80; onTriggered: { root.hopping = false; root.show(root.side) } }
    Timer {
        id: guideTimer
        interval: 90
        onTriggered: {
            if (root.want.indexOf("row:") === 0) root.revealRow(root.want.slice(4))
            else if (root.guideSpot && root.guideSpot.group !== "" && root.want.indexOf("tab:") !== 0) root.reveal(root.guideSpot.group)
        }
    }
    Timer {
        interval: root.rush > 0 ? 120 : 500
        repeat: true
        triggeredOnStart: true
        running: root.present && (root.haloItem !== null || root.haloEdge !== null) && Guide.key !== ""
        onTriggered: {
            if (root.rush > 0) root.rush--
            root.findWindow()
            root.locate()
        }
    }
    Binding { target: Guide; property: "steps"; value: root.guideSteps }
    Binding { target: Guide; property: "at"; value: root.guideAt }
    Connections {
        target: Guide
        function onSummon() { if (!root.present) root.toggle() }
        function onKeyChanged() { if (Guide.key !== "") root.syncRows() }
    }
    Process {
        id: whereProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector { onStreamFinished: root.placed(text) }
    }
    Timer { id: hitTimer; interval: Math.max(200, root.s("settings_HighlightTime")); onTriggered: root.hit = "" }
    Timer {
        id: goTimer
        interval: 40
        onTriggered: {
            const e = root.aim
            if (!e || !e.key) return
            if (e.tab === "config") root.revealRow(e.key)
            else root.reveal(e.key)
        }
    }

    GlobalShortcut { appid: "settings"; name: "toggle"; onPressed: root.toggle() }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggle() }
    }

    component Tx: Text {
        color: root.tx
        font.family: root.font
        font.pixelSize: root.px
    }

    component Gl: Text {
        id: gl
        property string code: ""
        readonly property bool drawn: Art.has(code)
        text: drawn ? "" : root.glyph(code)
        color: root.mark
        font.family: root.iconFont
        font.pixelSize: root.px + 2
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        leftPadding: drawn ? glArt.box : 0
        Icon { id: glArt; visible: gl.drawn; anchors.centerIn: parent; source: gl.drawn ? gl.code : ""; color: gl.color; size: gl.font.pixelSize }
    }

    component Push: Rectangle {
        id: pu
        property string text: ""
        property string code: ""
        property bool danger: false
        property bool lit: false
        property bool solo: false
        readonly property bool stop: solo
        readonly property bool marked: root.keys && root.sel === pu
        readonly property color ink: lit || (danger && puArea.containsMouse) ? root.bg : root.tx
        signal clicked()
        function key(k) {
            if (k !== "enter") return false
            clicked()
            return true
        }
        implicitWidth: Math.max(implicitHeight, puRow.width + Math.round(root.px * 2))
        implicitHeight: root.rowH
        radius: height / 2
        color: lit ? root.hi : puArea.containsMouse ? (danger ? root.bad : root.softer) : root.soft
        border.width: marked ? 2 : 0
        border.color: lit ? root.tx : root.hi
        scale: puArea.pressed ? 0.95 : 1
        Behavior on color { Tint {} }
        Behavior on scale { Glide {} }
        Row {
            id: puRow
            anchors.centerIn: parent
            spacing: 8
            Gl { visible: pu.code !== ""; code: pu.code; anchors.verticalCenter: parent.verticalCenter; color: pu.ink; font.pixelSize: root.px }
            Tx { visible: pu.text !== ""; text: pu.text; anchors.verticalCenter: parent.verticalCenter; color: pu.ink }
        }
        MouseArea { id: puArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: pu.clicked() }
    }

    component Knob: Item {
        id: kn
        property bool lit: false
        signal toggled()
        property bool usable: true
        function key(k) {
            if (k !== "enter" || !usable) return false
            toggled()
            return true
        }
        implicitWidth: Math.round(root.px * 3)
        implicitHeight: Math.round(root.px * 1.7)
        opacity: usable ? 1 : 0.35
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: kn.lit ? root.hi : root.softer
            Behavior on color { Tint {} }
        }
        Rectangle {
            width: parent.height - 8 + (knArea.pressed ? 6 : 0)
            height: parent.height - 8
            radius: height / 2
            y: 4
            x: kn.lit ? parent.width - width - 4 : 4
            color: kn.lit ? root.bg : root.tx
            opacity: kn.lit ? 1 : 0.7
            Behavior on x { NumberAnimation { duration: Motion.time; easing.type: Motion.ease } }
            Behavior on width { Glide {} }
        }
        MouseArea { id: knArea; anchors.fill: parent; enabled: kn.usable; onPressed: root.unfocus(); onClicked: kn.toggled() }
    }

    component Entry: Rectangle {
        id: en
        property string value: ""
        property string hint: ""
        property bool wrong: false
        property bool keep: false
        property string family: ""
        property alias typed: enIn.text
        signal commit(string text)
        signal cancel()
        function fail() { wrong = true; enBad.restart() }
        function clear() { enIn.text = "" }
        function grab() { enIn.forceActiveFocus(); enIn.selectAll() }
        function key(k) {
            if (k !== "enter") return false
            grab()
            return true
        }
        implicitWidth: Math.round(root.px * 12)
        implicitHeight: root.rowH
        radius: root.rad
        color: root.soft
        border.width: wrong || enIn.activeFocus ? 1 : 0
        border.color: wrong ? root.bad : root.hi
        onValueChanged: if (!enIn.activeFocus) enIn.text = value
        Component.onCompleted: enIn.text = value
        Timer { id: enBad; interval: 700; onTriggered: en.wrong = false }
        TextInput {
            id: enIn
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            selectByMouse: true
            font.family: en.family || root.font
            font.pixelSize: root.px
            color: root.tx
            selectionColor: root.hi
            selectedTextColor: root.bg
            onAccepted: {
                en.wrong = false
                en.commit(text)
                if (!en.wrong) root.unfocus()
            }
            onActiveFocusChanged: if (!activeFocus && !en.wrong && !en.keep) text = en.value
            Keys.onEscapePressed: { text = en.value; root.unfocus(); en.cancel() }
        }
        Tx { visible: enIn.text === "" && en.hint !== ""; x: 10; anchors.verticalCenter: parent.verticalCenter; text: en.hint; opacity: 0.4 }
    }

    component Pick: Rectangle {
        id: pk
        property string value: ""
        property var options: []
        property bool filter: false
        property string family: ""
        property string shown: ""
        readonly property bool odd: options.length > 0 && !options.some(o => (typeof o === "string" ? o : o.value) === value)
        signal chosen(var v)
        function key(k) {
            if (k !== "enter") return false
            root.openMenu(pk, pk.options, pk.value, pk.filter, v => pk.chosen(v))
            return true
        }
        implicitWidth: Math.round(root.px * 15)
        implicitHeight: root.rowH
        radius: root.rad
        color: pkArea.containsMouse ? root.softer : root.soft
        border.width: odd ? 1 : 0
        border.color: root.bad
        Tx { x: 10; width: parent.width - 34; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: pk.shown || pk.value; font.family: pk.family || root.font }
        Gl { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; code: "f078"; font.pixelSize: root.px - 3; opacity: 0.6 }
        MouseArea { id: pkArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: root.openMenu(pk, pk.options, pk.value, pk.filter, v => pk.chosen(v)) }
    }

    component Slide: Item {
        id: sl
        property real low: 0
        property real high: 1
        property real step: 0
        property real value: 0
        property bool held: false
        property real live: 0
        readonly property real seen: held ? live : value
        readonly property real part: high > low ? Math.max(0, Math.min(1, (seen - low) / (high - low))) : 0
        signal moved(real v)
        signal done(real v)
        function key(k) {
            if (k !== "left" && k !== "right") return false
            const d = (step > 0 ? step : (high - low) / 20) * (k === "left" ? -1 : 1)
            const v = Number(Math.max(low, Math.min(high, value + d)).toFixed(4))
            moved(v)
            done(v)
            return true
        }
        implicitWidth: Math.round(root.px * 14)
        implicitHeight: root.rowH
        function at(x) {
            let v = low + Math.max(0, Math.min(1, (x - 7) / Math.max(1, width - 14))) * (high - low)
            if (step > 0) v = Math.round(v / step) * step
            live = Number(Math.max(low, Math.min(high, v)).toFixed(4))
            moved(live)
        }
        Rectangle { x: 7; width: parent.width - 14; height: 4; radius: 2; anchors.verticalCenter: parent.verticalCenter; color: root.softer }
        Rectangle { x: 7; width: (parent.width - 14) * sl.part; height: 4; radius: 2; anchors.verticalCenter: parent.verticalCenter; color: root.hi }
        Rectangle {
            x: (parent.width - 14) * sl.part
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            color: root.hi
            scale: sl.held ? 1.25 : slArea.containsMouse ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: Motion.time; easing.type: Motion.ease } }
        }
        MouseArea {
            id: slArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onPressed: m => { root.unfocus(); sl.held = true; sl.at(m.x) }
            onPositionChanged: m => { if (pressed) sl.at(m.x) }
            onReleased: { sl.done(sl.live); sl.held = false }
            onCanceled: sl.held = false
        }
    }

    component Halo: Rectangle {
        id: ha
        property bool lit: false
        property bool wrap: true
        visible: lit
        anchors.fill: wrap ? parent : undefined
        anchors.margins: 2
        z: 50
        radius: root.rad
        color: "transparent"
        border.width: root.haloLine
        border.color: root.halo
        property var flick: null
        onLitChanged: {
            if (lit) { flick = root.flickOf(ha); root.haloItem = ha }
            else { flick = null; if (root.haloItem === ha) root.haloItem = null }
        }
        Component.onCompleted: if (lit) { flick = root.flickOf(ha); root.haloItem = ha }
        Component.onDestruction: if (root.haloItem === ha) root.haloItem = null
        Connections {
            target: ha.flick
            ignoreUnknownSignals: true
            function onContentYChanged() { root.locate() }
        }
        SequentialAnimation on opacity {
            running: ha.lit
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 620; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 620; easing.type: Easing.InOutSine }
        }
    }

    component Group: Column {
        id: gp
        property string key: ""
        property string icon: ""
        property var names: []
        readonly property bool changed: names.some(n => root.stock?.[n] !== undefined && JSON.stringify(root.cfg?.[n]) !== JSON.stringify(root.stock[n]))
        default property alias items: gpBody.data
        width: parent ? parent.width : 0
        spacing: Math.round(root.px * 0.7)
        Item {
            width: gp.width
            height: 0
            z: 5
            Halo { wrap: false; x: -8; y: -6; width: gp.width + 16; height: gp.height + 12; lit: gp.key !== "" && root.want === "group:" + gp.key }
        }
        Row {
            spacing: Math.round(root.px * 0.7)
            Gl { visible: gp.icon !== ""; anchors.verticalCenter: parent.verticalCenter; code: gp.icon; font.pixelSize: root.px + 4; color: root.hit === gp.key ? root.hi : root.mark }
            Tx {
                anchors.verticalCenter: parent.verticalCenter
                text: root.word(gp.key)
                font.pixelSize: root.px + 4
                font.weight: Font.DemiBold
                color: root.hit === gp.key ? root.hi : root.tx
            }
            Gl {
                id: gpBack
                visible: gp.names.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(root.px * 1.5)
                height: width
                code: "f0e2"
                font.pixelSize: root.px - 1
                opacity: gpBackArea.containsMouse ? 1 : gp.changed ? 0.55 : 0.18
                Behavior on opacity { Glide {} }
                MouseArea {
                    id: gpBackArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: containsMouse ? root.hint(gpBack, root.word("Reset to default")) : root.unhint(gpBack)
                    onClicked: { root.unhint(gpBack); root.setMany(gp.names.filter(n => root.stock?.[n] !== undefined).map(n => [[n], root.stock[n]])) }
                }
                Component.onDestruction: root.unhint(gpBack)
            }
        }
        Rectangle {
            width: parent.width
            height: gpBody.height + root.rowPad
            radius: root.round
            color: root.soft
            Column { id: gpBody; x: root.rowPad; y: Math.round(root.rowPad / 2); width: parent.width - root.rowPad * 2; spacing: Math.round(root.px * 0.2) }
        }
        Connections {
            target: root
            function onReveal(k) { if (k === gp.key) root.scrollTo(gp) }
        }
    }

    component RowLine: Item {
        id: rl
        property string name: ""
        property string label: ""
        property string note: ""
        property string sub: ""
        readonly property bool stop: true
        readonly property bool marked: root.keys && root.sel === rl
        readonly property bool changed: name !== "" && root.stock?.[name] !== undefined && JSON.stringify(root.cfg?.[name]) !== JSON.stringify(root.stock[name])
        default property alias items: rlSlot.data
        function key(k) { return root.keyInto(rlSlot, k) }
        width: parent ? parent.width : 0
        height: Math.max(root.rowH, rlSlot.height) + Math.round(root.px * 0.8)
        HoverHandler { id: rlOver }
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -root.rowPad
            anchors.rightMargin: -root.rowPad
            radius: root.rad
            color: root.soft
            opacity: rlOver.hovered || rl.marked ? 1 : 0
            border.width: rl.marked ? 2 : 0
            border.color: root.hi
            Behavior on opacity { NumberAnimation { duration: Motion.time; easing.type: Motion.ease } }
        }
        Row {
            id: rlText
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(root.px * 0.5)
            Tx { id: rlName; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, Math.max(0, rl.width - rlSlot.width - root.gap - rlMark.width - parent.spacing)); elide: Text.ElideRight; text: root.word(rl.label) }
            Info { id: rlMark; anchors.verticalCenter: parent.verticalCenter; text: root.word(rl.note) }
            Gl {
                id: rlBack
                visible: rl.name !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? Math.round(root.px * 1.5) : 0
                height: Math.round(root.px * 1.5)
                code: "f0e2"
                font.pixelSize: root.px - 1
                opacity: rlBackArea.containsMouse ? 1 : rl.changed ? 0.55 : rlOver.hovered || rl.marked ? 0.3 : 0
                Behavior on opacity { Glide {} }
                MouseArea {
                    id: rlBackArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: containsMouse ? root.hint(rlBack, root.word("Reset to default")) : root.unhint(rlBack)
                    onClicked: { root.unhint(rlBack); root.reset([rl.name]) }
                }
            }
            Tx { visible: rl.sub !== ""; anchors.verticalCenter: parent.verticalCenter; width: Math.max(0, Math.min(implicitWidth, rl.width - rlSlot.width - root.gap - rlName.width - rlMark.width - parent.spacing * 2)); elide: Text.ElideMiddle; text: rl.sub; opacity: 0.45 }
        }
        Row { id: rlSlot; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 10 }
        Halo { lit: rl.name !== "" && root.want === "ctl:" + rl.name; anchors.margins: -5 }
    }

    component Flip: RowLine {
        id: fl
        property bool first: false
        readonly property bool lit: (root.cfg?.[fl.name] ?? fl.first) === true
        Knob { anchors.verticalCenter: parent.verticalCenter; lit: fl.lit; onToggled: root.set([fl.name], !fl.lit) }
    }

    component Dial: RowLine {
        id: dl
        property real low: 0
        property real high: 1
        property real step: 0
        property real times: 1
        property int digits: 0
        property string unit: ""
        property real first: 0
        property bool flipped: false
        function turn(v) { return flipped ? Number((low + high - v).toFixed(4)) : v }
        Tx { anchors.verticalCenter: parent.verticalCenter; text: (dlSlide.seen * dl.times).toFixed(dl.digits) + dl.unit; opacity: 0.6 }
        Slide {
            id: dlSlide
            low: dl.low
            high: dl.high
            step: dl.step
            value: dl.turn(Number(root.cfg?.[dl.name] ?? dl.first) || 0)
            onDone: v => root.set([dl.name], dl.step >= 1 ? Math.round(dl.turn(v)) : dl.turn(v))
        }
    }

    component Face: Item {
        id: fc
        property real size: 40
        property string source: root.avatarSrc
        property var trim: crop
        readonly property real iw: Math.max(1, fcImg.implicitWidth)
        readonly property real ih: Math.max(1, fcImg.implicitHeight)
        readonly property real rw: iw / Math.min(iw, ih)
        readonly property real rh: ih / Math.min(iw, ih)
        width: size
        height: size
        ClippingRectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.pane
            Image {
                id: fcImg
                source: fc.source
                sourceSize.width: 512
                cache: false
                mipmap: true
                width: fc.rw * parent.width
                height: fc.rh * parent.height
                x: (parent.width - width) / 2 + fc.trim.offsetX * parent.width
                y: (parent.height - height) / 2 + fc.trim.offsetY * parent.height
                scale: fc.trim.zoom
            }
        }
        Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 1; border.color: root.bd }
    }

    component Shot: Column {
        id: sh
        property string label: ""
        property string setting: ""
        property bool demo: false
        property string mode: ""
        property real t: 0
        property point centre: Qt.point(0.5, 0.5)
        readonly property string value: String(root.cfg?.[setting] ?? "")
        readonly property string file: root.abs(value)
        readonly property string media: root.kind(value)
        readonly property bool fading: mode === "simple" || mode === "fade"
        readonly property string shot: root.thumb(file) || (media === "image" ? root.url(file) : "")
        width: parent ? Math.max(Math.round(root.px * 12), Math.min(Math.round(root.px * 24), Math.floor((parent.width - root.gap) / 2))) : Math.round(root.px * 24)
        spacing: Math.round(root.px * 0.7)
        onFileChanged: root.wantThumbs([file])
        Component.onCompleted: root.wantThumbs([file])

        function play() {
            if (shot === "") return
            let m = String(root.cfg?.dolphin_BackgroundTransition ?? "wave")
            if (m === "random") {
                const l = root.transitions.filter(x => x !== "none" && x !== "random")
                m = l[Math.floor(Math.random() * l.length)]
            }
            shAnim.stop()
            centre = m === "any" ? Qt.point(Math.random(), Math.random()) : Qt.point(0.5, 0.5)
            t = 0
            mode = m
            shMove.duration = m === "none" ? 0 : Math.max(0, Number(root.cfg?.dolphin_BackgroundDuration ?? 1) || 0) * 1000
            shAnim.start()
        }
        function poly(w, h) {
            const m = mode, p = t, out = []
            if (m === "left") return [Qt.point(0, 0), Qt.point(w * p, 0), Qt.point(w * p, h), Qt.point(0, h), Qt.point(0, 0)]
            if (m === "right") return [Qt.point(w, 0), Qt.point(w - w * p, 0), Qt.point(w - w * p, h), Qt.point(w, h), Qt.point(w, 0)]
            if (m === "top") return [Qt.point(0, 0), Qt.point(w, 0), Qt.point(w, h * p), Qt.point(0, h * p), Qt.point(0, 0)]
            if (m === "bottom") return [Qt.point(0, h), Qt.point(w, h), Qt.point(w, h - h * p), Qt.point(0, h - h * p), Qt.point(0, h)]
            if (m === "wipe" || m === "wave") {
                const amp = m === "wave" ? h * 0.04 : 0, d = p * (w + h + amp * 4), n = m === "wave" ? 48 : 1
                out.push(Qt.point(w, 0))
                for (let i = 0; i <= n; i++) {
                    const u = i / n, o = amp * Math.sin(u * d / (h * 0.25) * 2 * Math.PI) * 0.7071
                    out.push(Qt.point(w - d + u * d - o, u * d + o))
                }
                out.push(Qt.point(w, 0))
                return out
            }
            if (m === "grow" || m === "center" || m === "any" || m === "outer") {
                const cx = centre.x * w, cy = centre.y * h
                const far = Math.sqrt(Math.pow(Math.max(cx, w - cx), 2) + Math.pow(Math.max(cy, h - cy), 2))
                const r = far * (m === "outer" ? 1 - p : p)
                for (let i = 0; i <= 48; i++) out.push(Qt.point(cx + r * Math.cos(i / 48 * 2 * Math.PI), cy + r * Math.sin(i / 48 * 2 * Math.PI)))
                return out
            }
            return [Qt.point(0, 0), Qt.point(w, 0), Qt.point(w, h), Qt.point(0, h), Qt.point(0, 0)]
        }

        SequentialAnimation {
            id: shAnim
            NumberAnimation { id: shMove; target: sh; property: "t"; from: 0; to: 1; easing.type: Easing.InOutCubic }
            PauseAnimation { duration: Motion.span(400) }
            ScriptAction { script: sh.mode = "" }
        }
        Connections {
            target: root
            function onPlayDemo() { if (sh.demo) sh.play() }
        }

        ClippingRectangle {
            width: sh.width
            height: Math.round(width * 0.625)
            radius: root.round
            color: root.soft
            Image {
                anchors.fill: parent
                visible: sh.shot !== ""
                source: sh.shot
                sourceSize.width: Math.max(64, Math.round(root.s("settings_ThumbSize")))
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
            Gl { anchors.centerIn: parent; visible: sh.shot === ""; code: sh.media === "video" ? "f03d" : sh.media === "image" ? "f03e" : "f05e"; font.pixelSize: root.px * 2.4; opacity: 0.4 }
            Loader {
                anchors.fill: parent
                active: sh.mode !== ""
                sourceComponent: Item {
                    Rectangle { anchors.fill: parent; color: root.pane }
                    Item {
                        id: shMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "white"
                                strokeColor: "transparent"
                                PathPolyline { path: sh.poly(shMask.width, shMask.height) }
                            }
                        }
                    }
                    Item {
                        anchors.fill: parent
                        opacity: sh.fading ? sh.t : 1
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: shMask
                            maskInverted: sh.mode === "outer"
                        }
                        Image {
                            anchors.fill: parent
                            source: sh.shot
                            sourceSize.width: Math.max(64, Math.round(root.s("settings_ThumbSize")))
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                        }
                    }
                }
            }
        }
        Row {
            spacing: Math.round(root.px * 0.5)
            Tx { anchors.verticalCenter: parent.verticalCenter; text: root.word(sh.label); font.weight: Font.DemiBold }
            Info { anchors.verticalCenter: parent.verticalCenter; text: sh.value || root.word("None (black)") }
        }
        Row {
            spacing: 8
            Push {
                text: root.word("Change")
                code: "f07c"
                solo: true
                onClicked: root.browseFor(root.word("Choose") + " " + root.word(sh.label).toLowerCase(), root.folderOf(sh.file), root.images.concat(root.videos), p => root.set([sh.setting], root.rel(p)))
            }
            Push { visible: sh.demo && sh.shot !== ""; text: root.word("Preview"); code: "f04b"; onClicked: sh.play() }
            Push { visible: sh.value !== ""; danger: true; code: "f00d"; onClicked: root.set([sh.setting], "") }
        }
    }

    component Choice: Row {
        id: ch
        property var options: []
        property var value
        signal chosen(var v)
        function key(k) {
            if (k !== "left" && k !== "right") return false
            const n = options.length, i = options.findIndex(o => o[1] === value)
            if (!n) return false
            chosen(options[(Math.max(0, i) + (k === "right" ? 1 : n - 1)) % n][1])
            return true
        }
        spacing: 6
        Repeater {
            model: ch.options
            delegate: Push {
                required property var modelData
                text: root.word(String(modelData[0]))
                lit: ch.value === modelData[1]
                onClicked: ch.chosen(modelData[1])
            }
        }
    }

    component Info: Item {
        id: nf
        property string text: ""
        visible: text !== ""
        width: visible ? Math.round(root.px * 1.5) : 0
        height: Math.round(root.px * 1.5)
        Gl { anchors.centerIn: parent; code: "f05a"; font.pixelSize: root.px; opacity: nfArea.containsMouse ? 1 : 0.35; Behavior on opacity { Glide {} } }
        MouseArea { id: nfArea; anchors.fill: parent; hoverEnabled: true; onContainsMouseChanged: containsMouse ? root.hint(nf, nf.text) : root.unhint(nf) }
        Component.onDestruction: root.unhint(nf)
    }

    component Pane: Item {
        id: pn
        default property alias items: pnStack.data
        function stops() {
            const out = []
            const walk = it => {
                const list = it.children
                for (let i = 0; i < list.length; i++) {
                    const c = list[i]
                    if (!c.visible) continue
                    if (c.stop === true) out.push(c)
                    else walk(c)
                }
            }
            walk(pnStack)
            return out
        }
        function nav(k) {
            const list = stops(), n = list.length
            if (!n) return false
            let i = list.indexOf(root.sel)
            if (k === "first" || i < 0) {
                if (k === "left") return false
                root.sel = list[0]
                root.reach(list[0])
                return true
            }
            const walks = k === "up" || k === "down"
            if (!walks && typeof list[i].key === "function" && list[i].key(k)) return true
            if (!walks && !(list[i].solo === true && k !== "enter")) return false
            i = (i + (k === "down" || k === "right" ? 1 : n - 1)) % n
            root.sel = list[i]
            root.reach(list[i])
            return true
        }
        Flickable {
            id: pnView
            anchors.fill: parent
            clip: true
            interactive: false
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: pnStack.height + root.gap * 3
            Column {
                id: pnStack
                x: Math.round((pnView.width - width) / 2)
                y: Math.round(root.gap * 1.2)
                width: Math.min(pnView.width - root.gap * 2, root.colW)
                spacing: Math.round(root.gap * 1.5)
            }
        }
        Scroller { view: pnView }
        Rectangle {
            visible: pnView.contentHeight > pnView.height
            anchors.right: parent.right
            anchors.rightMargin: 4
            width: 3
            radius: 1.5
            y: 6 + pnView.visibleArea.yPosition * (pn.height - 12)
            height: pnView.visibleArea.heightRatio * (pn.height - 12)
            color: root.tx
            opacity: 0.25
        }
    }

    Component {
        id: aiPage

        Pane {
            FolderListModel {
                id: ggufs
                folder: root.url(root.modelsDir)
                showDirs: false
                caseSensitive: false
                nameFilters: ["*.gguf"]
            }

            Group {
                key: "Panda Hypr AI"
                icon: "f1b0"
                Flip { label: "Enabled"; note: "Shows the panda in the bottom left corner. Click it to ask how to change any setting."; name: "hyprai_Show" }
                Flip { label: "Visualization"; note: "Cards for each setting it names, the walking guide, and the panda's speech bubble"; name: "hyprai_Visualization" }
                Flip { label: "Talks by itself"; note: "Now and then the panda says something when nothing is happening"; name: "hyprai_Chatter" }
                Flip { label: "Read Dolphin's files"; note: "Lets it look in Dolphin's scripts for things that are not settings. It can only read, never change."; name: "hyprai_Files" }
                RowLine {
                    label: "Model"
                    name: "hyprai_Model"
                    note: "A vision file with the same name ending in .mmproj next to the model turns the snipping tool on"
                    Pick {
                        value: String(root.cfg?.hyprai_Model ?? "")
                        filter: true
                        options: Array.from({ length: ggufs.count }, (v, i) => String(ggufs.get(i, "fileName")).replace(/\.gguf$/, ""))
                        onChosen: v => root.set(["hyprai_Model"], v)
                    }
                    Push { text: root.word("Browse"); code: "f07c"; onClicked: root.browseFor(root.word("Choose a model"), root.modelsDir, ["gguf"], p => root.set(["hyprai_Model"], root.rel(p))) }
                }
            }

            Group {
                key: "Answers"
                icon: "f086"
                Dial { label: "Answer length"; note: "The most words the panda may use in one answer"; name: "hyprai_MaxTokens"; low: 100; high: 2000; step: 50 }
                Dial { label: "Creativity"; note: "Low keeps answers exact, high makes them more varied"; name: "hyprai_Temperature"; low: 0; high: 1.5; step: 0.05; digits: 2 }
                Flip { label: "Short answers"; note: "Writes in ASD-STE100 Simplified Technical English: short steps, no filler"; name: "hyprai_SimpleEnglish" }
                Flip { label: "Think before answering"; note: "Slower, sometimes more careful"; name: "hyprai_Thinking" }
            }

            Group {
                key: "Memory"
                icon: "f2db"
                Dial { label: "Memory limit"; note: "The most memory the model may use"; name: "hyprai_MemoryLimit"; low: 0; high: 12; step: 0.5; digits: 1; unit: " GB" }
                Dial { label: "Keep loaded after closing"; note: "How long the model stays in memory after the chat closes"; name: "hyprai_Unload"; low: 0; high: 30; step: 1; unit: " min" }
                RowLine {
                    label: "Use the graphics card"
                    note: "Much faster when the graphics card has enough memory"
                    name: "hyprai_GpuLayers"
                    Knob { anchors.verticalCenter: parent.verticalCenter; lit: Number(root.cfg?.hyprai_GpuLayers ?? 0) > 0; onToggled: root.set(["hyprai_GpuLayers"], lit ? 0 : 99) }
                }
            }
        }
    }

    Component {
        id: editorPage

        Pane {
            Group {
                key: "Editor"
                icon: "f044"
                RowLine {
                    label: "Open editor"
                    note: "Shows every hidden part of Dolphin so you can drag things into place and click anything to change its settings"
                    Push { text: root.word(Reveal.editor ? "Close" : "Open"); code: "f044"; lit: Reveal.editor; onClicked: Reveal.editor = !Reveal.editor }
                }
                Flip { label: "Enabled"; note: "Lets the editor open"; name: "editor_Show" }
                Dial { label: "Snap"; note: "Widgets move in steps of this many bar heights"; name: "editor_Snap"; low: 0.01; high: 1; step: 0.01; digits: 2 }
            }
        }
    }

    Component {
        id: stylePage

        Pane {
            Group {
                key: "Profile"
                icon: "f007"
                Row {
                    spacing: root.gap
                    Face { size: Math.round(root.px * 7) }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(root.px * 0.6)
                        Row {
                            spacing: Math.round(root.px * 0.5)
                            Tx { anchors.verticalCenter: parent.verticalCenter; text: root.user; font.pixelSize: root.px + 6; font.weight: Font.DemiBold }
                            Info { anchors.verticalCenter: parent.verticalCenter; text: root.rel(root.avatarFile) }
                        }
                        Row {
                            spacing: 8
                            Push { text: root.word("Change picture"); code: "f03e"; solo: true; onClicked: root.browseFor(root.word("Choose a picture"), root.folderOf(root.avatarFile), root.images, p => root.setAvatar(p)) }
                            Push { text: root.word("Adjust"); code: "f125"; solo: true; onClicked: root.cropping = "avatar" }
                        }
                    }
                }
                RowLine {
                    label: "Setting presets"
                    note: "A preset is a full copy of your settings. Pick one to switch to it, or copy the current settings into a new one. Default never changes."
                    Push { anchors.verticalCenter: parent.verticalCenter; text: Presets.current; code: "f0c7"; onClicked: root.presets = true }
                }
            }

            Group {
                key: "Wallpaper"
                icon: "f03e"
                Flow {
                    width: parent.width
                    spacing: root.gap
                    Shot { label: "Wallpaper"; setting: "dolphin_Background"; demo: true }
                    Shot { label: "Lock screen"; setting: "dolphin_Lockscreen" }
                }
                Dial { label: "Wallpaper saturation"; note: "How strong the wallpaper colours are. 0 leaves the picture as it is, below 0 fades towards grey, above 0 is more vivid."; name: "dolphin_BackgroundSaturation"; low: -1; high: 1; step: 0.05; digits: 2 }
                Dial { label: "Lock screen saturation"; note: "The same for the lock screen picture"; name: "lockscreen_Saturation"; low: -1; high: 1; step: 0.05; digits: 2 }
            }

            Group {
                key: "Transition"
                icon: "f0ec"
                names: ["dolphin_BackgroundTransition"]
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: root.transitions
                        delegate: Push {
                            required property string modelData
                            text: modelData
                            solo: true
                            lit: String(root.cfg?.dolphin_BackgroundTransition ?? "wave") === modelData
                            onClicked: { root.set(["dolphin_BackgroundTransition"], modelData); root.playDemo() }
                        }
                    }
                }
                RowLine {
                    label: "Duration"
                    note: "How long the wallpaper change takes"
                    name: "dolphin_BackgroundDuration"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: durSlide.seen.toFixed(1) + " s"; opacity: 0.6 }
                    Slide {
                        id: durSlide
                        low: 0
                        high: 5
                        step: 0.1
                        value: Number(root.cfg?.dolphin_BackgroundDuration ?? 1) || 0
                        onDone: v => { root.set(["dolphin_BackgroundDuration"], v); root.playDemo() }
                    }
                }
                Flip { label: "Ripples"; note: "The next wallpaper key spreads each new picture as a ring from the pointer, and pressing again starts another ring before the last one finishes"; name: "dolphin_BackgroundRipple" }
                Dial { visible: root.cfg?.dolphin_BackgroundRipple !== false; label: "Ripple time"; note: "How long one ring takes to cover the screen"; name: "dolphin_BackgroundNextTime"; low: 0.2; high: 3; step: 0.1; digits: 1; unit: " s" }
            }

            Group {
                key: "Catbar"
                icon: "f0c9"
                RowLine {
                    label: "Position"
                    name: "catbar_Position"
                    note: "The screen edge the catbar sits on"
                    Choice { options: [["Top", 0], ["Bottom", 1], ["Left", 3], ["Right", 2]]; value: Number(root.cfg?.catbar_Position ?? 0); onChosen: v => root.set(["catbar_Position"], v) }
                }
                RowLine {
                    label: "Shape"
                    name: "catbar_Type"
                    note: "Attached to the screen edge, or a floating bar"
                    Choice { options: [["Attached", 0], ["Floating", 1]]; value: Number(root.cfg?.catbar_Type ?? 0); onChosen: v => root.set(["catbar_Type"], v) }
                }
                Dial { label: "Height"; note: "How thick the catbar is"; name: "catbar_Height"; low: 0.02; high: 0.07; step: 0.001; times: 100; digits: 1; unit: "%" }
            }

            Group {
                key: "Desktop widgets"
                icon: "f017"
                Flip { label: "Enabled"; note: "Shows widgets on the wallpaper, behind the windows"; name: "desktop_Show" }
                Flip { label: "Inverted"; note: "Flips the colours of the widgets so they stand out when they blend into the wallpaper"; name: "desktop_Inverted" }
                Flip { label: "Contrast"; note: "Draws a solid border of the opposite shade around the widgets, so they stay readable on any wallpaper"; name: "desktop_Contrast" }
                Dial { visible: root.cfg?.desktop_Contrast === true; label: "Contrast strength"; note: "How solid the border is"; name: "desktop_ContrastStrength"; low: 0.1; high: 1; step: 0.05; times: 100; unit: "%" }
                Flip { label: "Clock"; note: "The time on the wallpaper"; name: "desktop_Clock" }
                RowLine {
                    visible: root.cfg?.desktop_Clock === true
                    label: "Clock type"
                    name: "desktop_ClockType"
                    note: "Numbers, or a clock face with moving hands"
                    Choice { options: [["Digital", "digital"], ["Stacked", "stacked"], ["Hands", "analog"]]; value: String(root.cfg?.desktop_ClockType ?? "digital"); onChosen: v => root.set(["desktop_ClockType"], v) }
                }
                RowLine {
                    visible: root.cfg?.desktop_Clock === true && root.cfg?.desktop_ClockType !== "analog"
                    label: "Time format"
                    name: "desktop_ClockStyle"
                    note: "12 or 24 hours"
                    Choice { options: [["12 hour", "12hr"], ["24 hour", "24hr"]]; value: String(root.cfg?.desktop_ClockStyle ?? "12hr"); onChosen: v => root.set(["desktop_ClockStyle"], v) }
                }
                Flip { visible: root.cfg?.desktop_Clock === true; label: "Seconds"; note: "Shows the seconds"; name: "desktop_ClockSeconds" }
                Flip { label: "Date"; note: "The date under the clock"; name: "desktop_Date" }
                RowLine {
                    id: dateRow
                    readonly property var list: root.choices.desktop_DateStyle ?? []
                    visible: root.cfg?.desktop_Date === true
                    label: "Date format"
                    name: "desktop_DateStyle"
                    note: "How the date is written"
                    Pick {
                        value: String(root.cfg?.desktop_DateStyle ?? "D")
                        shown: (dateRow.list.find(o => o.value === value) ?? ({ text: value })).text
                        options: dateRow.list
                        onChosen: v => root.set(["desktop_DateStyle"], v)
                    }
                }
                Flip { label: "Greeting"; note: "A greeting for the time of day"; name: "desktop_Greeting" }
                Flip { label: "Weather"; note: "Temperature and sky, from the weather widget"; name: "desktop_Weather" }
                Flip { label: "Battery"; note: "The battery level as a bar"; name: "desktop_Battery" }
                Flip { label: "Now playing"; note: "The title that is playing"; name: "desktop_Media" }
                Dial { label: "Size"; note: "How big the widgets are"; name: "desktop_Scale"; low: 0.4; high: 2.5; step: 0.05; digits: 2; unit: "x" }
                Dial { label: "Across"; note: "Left to right position on the screen"; name: "desktop_X"; low: 0; high: 1; step: 0.01; times: 100; unit: "%" }
                Dial { label: "Down"; note: "Top to bottom position on the screen"; name: "desktop_Y"; low: 0; high: 1; step: 0.01; times: 100; unit: "%" }
            }

            Group {
                key: "Fonts"
                icon: "f031"
                RowLine {
                    label: "Text font"
                    note: "Used for all text in Dolphin"
                    name: "dolphin_TextFont"
                    Pick { value: root.font; family: root.font; filter: true; options: root.fonts(false); onChosen: v => root.set(["dolphin_TextFont"], v) }
                }
                Tx { width: parent.width; elide: Text.ElideRight; text: "Snoopy Hyperland  0123456789  Aa Bb Cc  Привет"; font.pixelSize: root.px + 6; opacity: 0.8 }
                RowLine {
                    label: "Icon font"
                    note: "A Nerd Font that draws the icons"
                    name: "dolphin_IconFont"
                    Pick { value: root.iconFont; filter: true; options: root.fonts(true); onChosen: v => root.set(["dolphin_IconFont"], v) }
                }
                Row {
                    spacing: Math.round(root.px * 1.2)
                    Repeater {
                        model: ["f18b4", "f03da", "f1fc", "f2d2", "f013", "f064e", "f002", "f03e", "f186", "f1ab"]
                        delegate: Gl { required property string modelData; code: modelData; font.pixelSize: root.px + 8; opacity: 0.8 }
                    }
                }
            }

            Group {
                key: "Password mask"
                icon: "f023"
                RowLine {
                    label: "Mask characters"
                    name: "dolphin_Cypher"
                    note: "Shown instead of the letters you type on the lock screen and greeter"
                    Entry {
                        id: maskEntry
                        value: String(root.cfg?.dolphin_Cypher ?? "\u2022")
                        onCommit: t => { if (t) root.set(["dolphin_Cypher"], t); else maskEntry.fail() }
                    }
                }
                Item {
                    width: parent.width
                    height: root.rowH
                    Rectangle {
                        width: Math.round(root.px * 16)
                        height: parent.height
                        radius: root.rad
                        color: root.soft
                        Typer {
                            id: maskDemo
                            readonly property var marks: Array.from(String(root.cfg?.dolphin_Cypher ?? "") || "\u2022")
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            want: Array.from({ length: 10 }, (v, i) => marks[i % marks.length]).join("")
                            color: root.tx
                            font.family: root.font
                            font.pixelSize: root.px
                        }
                        MouseArea { anchors.fill: parent; onClicked: maskDemo.typed = "" }
                    }
                }
            }
        }
    }

    Component {
        id: interfacePage

        Pane {
            Group {
                key: "Theme"
                icon: "f1fc"
                Flow {
                    width: parent.width
                    spacing: root.px
                    Repeater {
                        model: root.themeNames
                        delegate: Item {
                            id: card
                            required property string modelData
                            readonly property var tones: root.themes[modelData] ?? ({})
                            readonly property bool lit: root.themeName === modelData
                            readonly property bool fixed: modelData === "Wallpaper" || root.stock?.Theme?.[modelData] !== undefined
                            readonly property bool stop: true
                            readonly property bool solo: true
                            readonly property bool marked: root.keys && root.sel === card
                            function key(k) {
                                if (k !== "enter") return false
                                root.useTheme(card.modelData)
                                return true
                            }
                            width: Math.round(root.px * 11)
                            height: mock.height + Math.round(root.px * 2.2)
                            Rectangle {
                                id: mock
                                width: parent.width
                                height: Math.round(root.px * 6.6)
                                radius: root.round
                                color: card.tones.Background ?? "#000000"
                                border.width: card.lit || card.marked ? 2 : 1
                                border.color: card.marked ? root.tx : card.lit ? root.hi : root.softer
                                Rectangle { x: 8; y: 8; width: parent.width - 16; height: 9; radius: 4.5; color: card.tones.Accent ?? "#000000" }
                                Rectangle { x: 12; y: 10.5; width: 16; height: 4; radius: 2; color: card.tones.Active ?? "#000000" }
                                Rectangle { x: 8; y: 26; width: (parent.width - 16) * 0.62; height: 5; radius: 2.5; color: card.tones.Text ?? "#000000" }
                                Rectangle { x: 8; y: 36; width: (parent.width - 16) * 0.4; height: 5; radius: 2.5; color: card.tones.Accent2 ?? "#000000" }
                                Row {
                                    x: 8
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 8
                                    spacing: 4
                                    Repeater {
                                        model: root.colorKeys
                                        delegate: Rectangle {
                                            required property string modelData
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: card.tones[modelData] ?? "#000000"
                                            border.width: 1
                                            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
                                        }
                                    }
                                }
                            }
                            MouseArea { id: cardArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: root.useTheme(card.modelData) }
                            Tx {
                                y: mock.height + 6
                                width: parent.width - (tools.visible ? tools.width + 4 : 0)
                                elide: Text.ElideRight
                                text: card.modelData === "Wallpaper" ? root.word("Wallpaper") : card.modelData
                                color: card.lit ? root.hi : root.tx
                            }
                            Row {
                                id: tools
                                visible: !card.fixed && (cardArea.containsMouse || penArea.containsMouse || binArea.containsMouse)
                                anchors.right: parent.right
                                y: mock.height + 6
                                Gl {
                                    width: Math.round(root.px * 1.6)
                                    code: "f040"
                                    font.pixelSize: root.px
                                    opacity: penArea.containsMouse ? 1 : 0.6
                                    MouseArea { id: penArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: root.sure = { kind: "rename", name: card.modelData } }
                                }
                                Gl {
                                    width: Math.round(root.px * 1.6)
                                    code: "f1f8"
                                    color: root.bad
                                    font.pixelSize: root.px
                                    opacity: binArea.containsMouse ? 1 : 0.6
                                    MouseArea { id: binArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: root.sure = { kind: "delete", name: card.modelData } }
                                }
                            }
                        }
                    }
                }
                RowLine {
                    label: "New theme"
                    note: "Starts as a copy of the colours in use"
                    Entry {
                        id: fresh
                        keep: true
                        hint: root.freeName()
                        onCommit: t => { if (root.addTheme(t || root.freeName())) fresh.clear(); else fresh.fail() }
                    }
                    Push { code: "f067"; onClicked: { if (root.addTheme(fresh.typed || root.freeName())) fresh.clear() } }
                }
            }

            Group {
                key: "Colours"
                icon: "f043"
                Tx {
                    visible: root.wallTheme
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.word("These colours follow the wallpaper. Make a new theme above to edit them.")
                    opacity: 0.6
                }
                Flow {
                    width: parent.width
                    spacing: root.px
                    Repeater {
                        model: root.colorKeys
                        delegate: Row {
                            id: tile
                            required property string modelData
                            readonly property string value: String(root.theme[modelData] ?? "#000000")
                            width: Math.round(root.px * 13)
                            spacing: 10
                            Rectangle {
                                id: dab
                                width: Math.round(root.px * 3.2)
                                height: width
                                radius: width / 2
                                color: tile.value
                                border.width: 1
                                border.color: root.softer
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.wallTheme
                                    onPressed: root.unfocus()
                                    onClicked: root.openPicker(dab, tile.value, false, h => root.set(["Theme", root.themeName, tile.modelData], h))
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Tx { text: root.word(tile.modelData); font.pixelSize: root.px - 1; opacity: 0.6 }
                                Tx { visible: root.wallTheme; text: tile.value }
                                Entry {
                                    id: hexEntry
                                    visible: !root.wallTheme
                                    implicitWidth: Math.round(root.px * 7.5)
                                    implicitHeight: Math.round(root.px * 2)
                                    value: tile.value
                                    onCommit: t => {
                                        const m = t.trim().match(/^#?([0-9a-fA-F]{6})$/)
                                        if (m) root.set(["Theme", root.themeName, tile.modelData], "#" + m[1].toLowerCase())
                                        else hexEntry.fail()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Group {
                key: "Wallpaper colours"
                icon: "f0d0"
                RowLine {
                    label: "Follow the wallpaper"
                    name: "dolphin_ThemeBackground"
                    note: "Theme colours are picked from the wallpaper each time it changes"
                    Knob { anchors.verticalCenter: parent.verticalCenter; lit: root.wallTheme; onToggled: root.set(["dolphin_ThemeBackground"], !root.wallTheme) }
                }
                RowLine {
                    label: "Colour strength"
                    note: "How strongly the wallpaper colours the theme"
                    name: "dolphin_ThemeMatch"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(matchSlide.seen * 100) + "%"; opacity: 0.6 }
                    Slide { id: matchSlide; low: 0; high: 1; step: 0.05; value: Number(root.cfg?.dolphin_ThemeMatch ?? 0.7) || 0; onDone: v => root.set(["dolphin_ThemeMatch"], v) }
                }
            }

            Group {
                key: "Language"
                icon: "f1ab"
                names: ["dolphin_Language"]
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: root.tongues
                        delegate: Push {
                            required property string modelData
                            text: root.tongueNames[modelData] ?? modelData.toUpperCase()
                            solo: true
                            lit: root.lang === modelData
                            onClicked: root.set(["dolphin_Language"], modelData)
                        }
                    }
                }
                RowLine {
                    label: "Keyboard layout"
                    note: "A layout name such as us, ru or jp(kana)"
                    name: "dolphin_KeyboardLayout"
                    Entry {
                        id: layoutEntry
                        value: String(root.cfg?.dolphin_KeyboardLayout ?? "us")
                        onCommit: t => { if (t.trim()) root.set(["dolphin_KeyboardLayout"], t.trim()); else layoutEntry.fail() }
                    }
                }
            }

            Group {
                key: "Motion"
                icon: "f0e4"
                Dial { label: "Theme fade"; note: "How long the colours of everything take to blend when the theme or the wallpaper changes. 0 switches at once."; name: "dolphin_ThemeFade"; low: 0; high: 1500; step: 50; unit: " ms" }
                Flip { label: "Wait for the wallpaper"; note: "After unlocking, the bars, the AI and the widgets stay hidden until the wallpaper has finished appearing"; name: "dolphin_WaitUnlock" }
                Dial { visible: root.cfg?.dolphin_WaitUnlock !== false; label: "Unlock fade"; note: "How long they take to fade in once the wallpaper is there"; name: "dolphin_UnlockFade"; low: 0; high: 2000; step: 50; unit: " ms" }
                RowLine {
                    label: "Change time"
                    note: "How long things take to move when a setting changes"
                    name: "dolphin_SettingsChangeTime"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(timeSlide.seen) + " ms"; opacity: 0.6 }
                    Slide { id: timeSlide; low: 0; high: 800; step: 10; value: Number(root.cfg?.dolphin_SettingsChangeTime ?? 100) || 0; onDone: v => root.set(["dolphin_SettingsChangeTime"], Math.round(v)) }
                }
                RowLine {
                    label: "Easing"
                    note: "The curve of that movement"
                    name: "dolphin_SettingsEasingStyle"
                    Pick { value: String(root.cfg?.dolphin_SettingsEasingStyle ?? "OutExpo"); options: root.easings; filter: true; onChosen: v => root.set(["dolphin_SettingsEasingStyle"], v) }
                }
                Item {
                    id: glide
                    property bool flip: false
                    width: parent.width
                    height: Math.round(root.px * 1.4)
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: root.softer }
                    Rectangle {
                        width: parent.height
                        height: width
                        radius: width / 2
                        color: root.hi
                        x: glide.flip ? parent.width - width : 0
                        Behavior on x { NumberAnimation { duration: Motion.time; easing.type: Motion.ease } }
                    }
                    Connections {
                        target: Motion
                        function onTimeChanged() { glide.flip = !glide.flip }
                        function onEaseChanged() { glide.flip = !glide.flip }
                    }
                    MouseArea { anchors.fill: parent; onClicked: glide.flip = !glide.flip }
                }
                RowLine {
                    label: "Typing speed"
                    note: "Time between two letters of typed text"
                    name: "dolphin_TypeAnimationTime"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(typeSlide.seen) + " ms"; opacity: 0.6 }
                    Slide { id: typeSlide; low: 5; high: 120; step: 1; value: Number(root.cfg?.dolphin_TypeAnimationTime ?? 15) || 15; onDone: v => root.set(["dolphin_TypeAnimationTime"], Math.round(v)) }
                }
                Item {
                    width: parent.width
                    height: root.rowH
                    Typer {
                        id: typeDemo
                        anchors.verticalCenter: parent.verticalCenter
                        want: root.word("Snoopy Hyperland types like this")
                        color: root.tx
                        opacity: 0.8
                        font.family: root.font
                        font.pixelSize: root.px
                    }
                    Connections {
                        target: Motion
                        function onTypeChanged() { typeDemo.typed = "" }
                    }
                    MouseArea { anchors.fill: parent; onClicked: typeDemo.typed = "" }
                }
                RowLine {
                    label: "Scroll speed"
                    note: "How far one scroll step moves lists in Dolphin"
                    name: "dolphin_ScrollSpeed"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: scrollSlide.seen.toFixed(1) + "x"; opacity: 0.6 }
                    Slide { id: scrollSlide; low: 0.2; high: 5; step: 0.1; value: Number(root.cfg?.dolphin_ScrollSpeed ?? 1) || 1; onDone: v => root.set(["dolphin_ScrollSpeed"], v) }
                }
            }

            Group {
                key: "Night light"
                icon: "f186"
                RowLine {
                    label: "Warm screen colours"
                    note: "Removes blue light from the screen"
                    name: "dolphin_Night"
                    Knob { anchors.verticalCenter: parent.verticalCenter; lit: root.cfg?.dolphin_Night === true; onToggled: root.set(["dolphin_Night"], root.cfg?.dolphin_Night !== true) }
                }
                RowLine {
                    label: "Strength"
                    note: "How warm the screen gets"
                    name: "dolphin_NightStrength"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(nightSlide.seen * 100) + "%"; opacity: 0.6 }
                    Slide { id: nightSlide; low: 0; high: 1; step: 0.05; value: Number(root.cfg?.dolphin_NightStrength ?? 0.5) || 0; onDone: v => root.set(["dolphin_NightStrength"], v) }
                }
            }

            Group {
                key: "Bars"
                icon: "f0c9"
                Flip { label: "Catbar stays open"; note: "Otherwise it shows while Super is held or the mouse is on it"; name: "catbar_Pinned" }
                Flip { label: "Sidebar stays open"; note: "Keeps the sidebar on screen"; name: "sidebar_Pinned" }
                Flip { label: "Taskbar stays open"; note: "Keeps the taskbar on screen"; name: "poodlebar_Pinned" }
            }

            Group {
                key: "Media Player"
                icon: "f001"
                Dial { label: "Violence"; note: "How hard the window reacts to beats and drops. It scales every beat effect at once."; name: "media_Violence"; low: 0; high: 4; step: 0.1; digits: 1; unit: "x" }
                Dial { label: "Drop sensitivity"; note: "How easily a jump in the bass counts as a beat or a drop. Higher reacts more often."; name: "media_Sensitivity"; first: 0.7; low: 0; high: 1; step: 0.01; times: 100; unit: "%" }
                Dial { label: "Beat timing"; note: "How early beat effects fire once the tempo is found. Raise it if effects feel late, lower it if they feel early."; name: "media_Sync"; low: 0; high: 200; step: 5; unit: " ms" }
                Dial { label: "Bar height"; note: "Scales the height of every sound bar"; name: "media_Gain"; low: 0.2; high: 3; step: 0.05; digits: 2; unit: "x" }
                RowLine {
                    label: "Bar style"
                    name: "media_FloorStyle"
                    note: "How the row of bars under the title is drawn"
                    Choice { options: [["Bottom", "bars"], ["Middle", "middle"], ["Blocks", "blocks"]]; value: String(root.cfg?.media_FloorStyle ?? "bars"); onChosen: v => root.set(["media_FloorStyle"], v) }
                }
                Dial { label: "Tint strength"; note: "How strongly the cover colour is laid over the Media Player background. The Theme tint effect switches it on or off."; name: "media_ThemeStrength"; low: 0; high: 0.8; step: 0.02; times: 100; unit: "%" }
                Dial { label: "Background clarity"; note: "How sharp the cover picture behind the Media Player is. 0% is fully blurred, 100% is the plain picture. The Cover background effect switches it on or off."; name: "media_BackdropBlur"; first: 1; flipped: true; low: 0; high: 1; step: 0.05; times: 100; unit: "%" }
                Dial { label: "Background strength"; note: "How strongly the cover picture shows through behind the Media Player"; name: "media_BackdropOpacity"; first: 0.28; low: 0; high: 1; step: 0.02; times: 100; unit: "%" }
                Flip { label: "Cover in the catbar panel"; note: "Fills the catbar media panel with the same cover background as the Media Player"; name: "widget_MediaBackdrop"; first: true }
                Dial { label: "Tempo spin"; note: "How much faster the disc turns in fast songs and busy parts, and slower in slow ones. 0 keeps one speed. The Tempo spin effect switches it on or off."; name: "media_Tempo"; first: 1; low: 0; high: 2; step: 0.1; digits: 1; unit: "x" }
                Flip { label: "Mini player"; note: "Shrinks the Media Player into a small bar in a screen corner. The arrows icon next to the gear does the same."; name: "media_Mini" }
                RowLine {
                    label: "Mini player corner"
                    name: "media_MiniCorner"
                    note: "The screen corner the mini player sits in"
                    Choice { options: [["Top left", "top-left"], ["Top right", "top-right"], ["Bottom left", "bottom-left"], ["Bottom right", "bottom-right"]]; value: String(root.cfg?.media_MiniCorner ?? "bottom-right"); onChosen: v => root.set(["media_MiniCorner"], v) }
                }
                Dial { label: "Mini player width"; note: "How wide the mini player is, in text sizes"; name: "media_MiniWidth"; low: 14; high: 50; step: 1 }
                Dial { label: "Mini player height"; note: "How tall the mini player is, in text sizes"; name: "media_MiniHeight"; low: 3.5; high: 10; step: 0.1; digits: 1 }
                Dial { label: "Title scroll speed"; note: "How fast a long song name slides in the mini player"; name: "media_MiniScroll"; low: 5; high: 120; step: 1 }
                RowLine {
                    label: "Effects"
                    note: "Each effect is switched on or off with the gear at the top right of the Media Player window"
                    Push { anchors.verticalCenter: parent.verticalCenter; text: root.word("Open"); code: "f001"; onClicked: Reveal.player() }
                }
            }

            Group {
                key: "Screenshot"
                icon: "f0c4"
                Flip { label: "Smart selection"; note: "The window, picture or box under the scissors lights up, and one click captures just that. Dragging still selects any area, and Enter captures the whole screen."; name: "snip_Smart" }
                Flip { visible: root.cfg?.snip_Smart !== false; label: "Find pictures and boxes"; note: "Also looks inside windows for pictures, cards and panels. Off finds whole windows only."; name: "snip_Content" }
                Flip { label: "Guide lines"; note: "Thin lines through the pointer that help line up a selection"; name: "snip_Guides" }
                Flip { label: "Name and size"; note: "Shows what is selected and its size in pixels next to the selection"; name: "snip_Labels" }
            }

            Group {
                key: "Modules"
                icon: "f1b3"
                names: root.showKeys
                Flow {
                    width: parent.width
                    spacing: root.px
                    Repeater {
                        model: root.showKeys
                        delegate: Rectangle {
                            id: mod
                            required property string modelData
                            readonly property bool lit: root.cfg?.[modelData] === true
                            readonly property bool stop: true
                            readonly property bool solo: true
                            readonly property bool marked: root.keys && root.sel === mod
                            function key(k) {
                                if (k === "right") { root.look(mod.modelData.split("_")[0] + "_"); return true }
                                if (k !== "enter") return false
                                root.set([mod.modelData], !mod.lit)
                                return true
                            }
                            width: Math.round(root.px * 15)
                            height: Math.round(root.px * 3.2)
                            radius: root.rad
                            color: lit ? root.glow : root.soft
                            border.width: marked ? 2 : 0
                            border.color: root.hi
                            Behavior on color { Tint {} }
                            Tx { x: 12; width: parent.width - modKnob.width - modGear.width - 36; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: root.word(root.moduleNames[mod.modelData.split("_")[0]] ?? root.title(mod.modelData.split("_")[0])) }
                            Gl {
                                id: modGear
                                anchors.right: modKnob.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(root.px * 1.9)
                                height: width
                                code: "f013"
                                font.pixelSize: root.px
                                opacity: modGearArea.containsMouse ? 1 : 0.4
                                Behavior on opacity { Glide {} }
                                MouseArea {
                                    id: modGearArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onContainsMouseChanged: containsMouse ? root.hint(modGear, root.word("Open its settings")) : root.unhint(modGear)
                                    onClicked: { root.unhint(modGear); root.look(mod.modelData.split("_")[0] + "_") }
                                }
                                Component.onDestruction: root.unhint(modGear)
                            }
                            Halo { lit: root.want === "ctl:" + mod.modelData; anchors.margins: -4 }
                            Knob { id: modKnob; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; lit: mod.lit; onToggled: root.set([mod.modelData], !mod.lit) }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: systemPage

        Pane {
            Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true; onTriggered: Hardware.refresh() }

            Group {
                key: "Display"
                icon: "f108"
                RowLine {
                    visible: Hardware.hasBacklight
                    label: "Screen brightness"
                    note: "The brightness of this screen"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(lightSlide.seen * 100) + "%"; opacity: 0.6 }
                    Slide { id: lightSlide; low: 0.02; high: 1; step: 0.01; value: Hardware.brightness; onMoved: v => Hardware.preview(v); onDone: v => Hardware.setBrightness(v) }
                }
                RowLine {
                    label: "Automatic brightness"
                    name: "system_AutoBrightness"
                    note: !Hardware.hasLightSensor ? "This computer has no light sensor" : "Follows the light in the room. Change the brightness yourself and it keeps that difference."
                    Tx { visible: Hardware.autoOn && Hardware.lux >= 0; anchors.verticalCenter: parent.verticalCenter; text: Math.round(Hardware.lux) + " lx"; opacity: 0.6 }
                    Knob {
                        anchors.verticalCenter: parent.verticalCenter
                        usable: Hardware.hasLightSensor && Hardware.hasBacklight
                        lit: usable && root.cfg?.system_AutoBrightness === true
                        onToggled: root.set(["system_AutoBrightness"], root.cfg?.system_AutoBrightness !== true)
                    }
                }
                Dial { visible: Hardware.autoOn; label: "Darkest"; note: "The lowest brightness in a dark room"; name: "system_AutoBrightnessMin"; low: 0.02; high: 1; step: 0.01; times: 100; unit: "%" }
                Dial { visible: Hardware.autoOn; label: "Brightest"; note: "The highest brightness in a bright room"; name: "system_AutoBrightnessMax"; low: 0.02; high: 1; step: 0.01; times: 100; unit: "%" }
                Tx { visible: Hardware.ready && !Hardware.hasBacklight; width: parent.width; wrapMode: Text.WordWrap; text: root.word("No screen backlight was found, or brightnessctl is not installed."); opacity: 0.55 }
            }

            Group {
                key: "Screen care"
                icon: "f132"
                Flip { label: "Pixel shift"; note: "Moves the whole picture a few pixels now and then, so an OLED screen wears evenly"; name: "system_PixelShift" }
                Dial { visible: Hardware.shift; label: "Shift distance"; note: "The furthest the picture moves from its place"; name: "system_PixelShiftRadius"; low: 1; high: 8; step: 1; unit: " px" }
                Dial { visible: Hardware.shift; label: "Shift every"; note: "Time between two moves"; name: "system_PixelShiftInterval"; low: 0.5; high: 30; step: 0.5; digits: 1; unit: " min" }
            }

            Group {
                key: "Animations"
                icon: "f0d0"
                Flip { label: "Animations"; note: "Off removes every slide and fade in Dolphin, and the window animations with them"; name: "system_Animations" }
            }

            Group {
                key: "Keyboard"
                icon: "f11c"
                RowLine {
                    visible: Hardware.hasKeyboardLight
                    label: "Keyboard backlight"
                    name: "system_KeyboardLight"
                    note: "Kept after a restart"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(keySlide.seen) === 0 ? root.word("Off") : Math.round(keySlide.seen) + " / " + Hardware.keyMax; opacity: 0.6 }
                    Slide {
                        id: keySlide
                        low: 0
                        high: Math.max(1, Hardware.keyMax)
                        step: 1
                        value: Hardware.keyNow
                        onMoved: v => Hardware.setKeyboardLight(v)
                        onDone: v => root.set(["system_KeyboardLight"], Math.round(v))
                    }
                }
                Tx { visible: Hardware.ready && !Hardware.hasKeyboardLight; width: parent.width; wrapMode: Text.WordWrap; text: root.word("This keyboard has no backlight that can be changed from here."); opacity: 0.55 }
            }

            Group {
                key: "Battery care"
                icon: "f240"
                Flip { label: "Low battery warning"; note: "Sends a notification when the battery gets this low while it is not charging"; name: "system_BatteryWarn" }
                RowLine {
                    visible: root.cfg?.system_BatteryWarn !== false
                    label: "Warn at"
                    name: "system_BatteryWarnAt"
                    note: "The battery level that sends the warning"
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(warnSlide.seen) + "%"; opacity: 0.6 }
                    Slide { id: warnSlide; low: 2; high: 30; step: 1; value: Number(root.cfg?.system_BatteryWarnAt ?? 5) || 5; onDone: v => root.set(["system_BatteryWarnAt"], Math.round(v)) }
                }
                RowLine {
                    visible: Hardware.hasChargeLimit && Hardware.limitOpen
                    label: "Charge limit"
                    name: "system_ChargeLimit"
                    note: "Stops charging at this level so the battery ages slower. 100% turns the limit off."
                    Tx { anchors.verticalCenter: parent.verticalCenter; text: Math.round(limitSlide.seen) + "%"; opacity: 0.6 }
                    Slide { id: limitSlide; low: 50; high: 100; step: 5; value: Number(root.cfg?.system_ChargeLimit ?? 100) || 100; onDone: v => root.set(["system_ChargeLimit"], Math.round(v)) }
                }
                RowLine {
                    visible: Hardware.hasChargeLimit && !Hardware.limitOpen
                    label: "Charge limit is locked"
                    note: "Only the administrator may change it. Unlocking asks for your password once and adds one udev rule."
                    Push { text: root.word("Unlock"); code: "f09c"; onClicked: Hardware.allowChargeLimit() }
                }
                Tx { visible: Hardware.note !== ""; width: parent.width; wrapMode: Text.WordWrap; text: root.word(Hardware.note); color: root.bad }
                Tx { visible: Hardware.ready && !Hardware.hasChargeLimit; width: parent.width; wrapMode: Text.WordWrap; text: root.word("This battery does not offer a charge limit."); opacity: 0.55 }
            }

            Group {
                key: "Power"
                icon: "f0e7"
                RowLine {
                    visible: Hardware.hasProfiles
                    label: "Power mode"
                    note: "Trades speed for battery life"
                    Push { text: root.word("Power saver"); lit: PowerProfiles.profile === PowerProfile.PowerSaver; onClicked: PowerProfiles.profile = PowerProfile.PowerSaver }
                    Push { text: root.word("Balanced"); lit: PowerProfiles.profile === PowerProfile.Balanced; onClicked: PowerProfiles.profile = PowerProfile.Balanced }
                    Push { visible: PowerProfiles.hasPerformanceProfile; text: root.word("Performance"); lit: PowerProfiles.profile === PowerProfile.Performance; onClicked: PowerProfiles.profile = PowerProfile.Performance }
                }
                RowLine {
                    visible: Hardware.ready && !Hardware.hasProfiles
                    label: "Power modes are not installed"
                    note: "Installs the power-profiles-daemon package. It asks for your password."
                    Push { visible: Hardware.canInstall; text: root.word(Hardware.installing ? "Installing" : "Install"); code: "f019"; onClicked: Hardware.installProfiles() }
                }
            }
        }
    }

    Component {
        id: keysPage

        Pane {
            RowLine {
                label: "Keys are saved in hyprland.lua"
                sub: root.rel(root.luaPath)
                Push { text: root.word("Open"); code: "f08e"; onClicked: root.openFile(root.luaPath) }
            }
            RowLine {
                visible: root.keymap.modVar !== ""
                label: "Super key"
                note: "The main key most shortcuts start with. SUPER is the Windows key."
                Pick {
                    implicitWidth: Math.round(root.px * 10)
                    value: String(root.keymap.vars[root.keymap.modVar] ?? "")
                    options: ["SUPER", "ALT", "CTRL", "SHIFT"]
                    onChosen: v => root.setMod(v)
                }
            }
            Tx { visible: root.keyNote !== ""; width: parent.width; wrapMode: Text.WordWrap; text: root.keyNote; color: root.bad }
            Tx { visible: root.luaMissing; text: root.word("hyprland.lua could not be read."); opacity: 0.6 }
            Repeater {
                model: root.keyGroups
                delegate: Group {
                    id: grp
                    required property var modelData
                    key: modelData.name
                    Repeater {
                        model: grp.modelData.binds
                        delegate: Item {
                            id: kb
                            required property var modelData
                            readonly property bool rec: root.recording === modelData.id
                            readonly property bool typed: root.typing === modelData.id
                            readonly property bool stop: true
                            readonly property bool marked: root.keys && root.sel === kb
                            function key(k) {
                                if (k !== "enter" || !modelData.editable) return false
                                root.typing = ""
                                root.keyNote = ""
                                root.recording = modelData.id
                                return true
                            }
                            width: parent ? parent.width : 0
                            height: root.rowH + 8

                            HoverHandler { id: kbOver }
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: -root.rowPad
                                anchors.rightMargin: -root.rowPad
                                radius: root.rad
                                color: root.soft
                                opacity: kbOver.hovered || kb.marked ? 1 : 0
                                border.width: kb.marked ? 2 : 0
                                border.color: root.hi
                                Behavior on opacity { Glide {} }
                            }
                            Row {
                                id: kbText
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Math.round(root.px * 0.5)
                                Tx { anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, Math.max(0, kb.width - kbSide.width - root.gap - root.px * 2)); elide: Text.ElideRight; text: root.word(kb.modelData.name) + (kb.modelData.tail ? " " + kb.modelData.tail : ""); color: root.hit === kb.modelData.id ? root.hi : root.tx }
                                Info { anchors.verticalCenter: parent.verticalCenter; text: kb.modelData.detail }
                            }
                            Row {
                                id: kbSide
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Tx { visible: kb.rec; anchors.verticalCenter: parent.verticalCenter; text: root.word("Press the new keys") + "\u2026  Esc"; color: root.hi }
                                Entry {
                                    id: kbEntry
                                    visible: kb.typed
                                    implicitWidth: Math.round(root.px * 16)
                                    implicitHeight: Math.round(root.px * 2)
                                    value: kb.modelData.tokens.join(" + ")
                                    hint: "SUPER + SHIFT + T"
                                    onCommit: t => { if (root.typeKeys(kb.modelData, t)) root.typing = ""; else kbEntry.fail() }
                                    onCancel: root.typing = ""
                                    onVisibleChanged: if (visible) grab()
                                }
                                Repeater {
                                    model: kb.rec || kb.typed ? [] : kb.modelData.tokens
                                    delegate: Rectangle {
                                        id: cap
                                        required property string modelData
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: capText.implicitWidth + Math.round(root.px * 1.2)
                                        height: Math.round(root.px * 2)
                                        radius: root.rad
                                        color: root.softer
                                        border.width: kb.modelData.clash === true ? 1 : 0
                                        border.color: root.bad
                                        Tx { id: capText; anchors.centerIn: parent; text: cap.modelData; font.pixelSize: root.px - 1 }
                                    }
                                }
                                Tx { visible: !kb.rec && !kb.typed && kb.modelData.tokens.length === 0; anchors.verticalCenter: parent.verticalCenter; text: root.word("Not set"); opacity: 0.4 }
                                Tx { visible: kb.modelData.clash === true && !kb.rec && !kb.typed; anchors.verticalCenter: parent.verticalCenter; text: root.word("used twice"); font.pixelSize: root.px - 3; color: root.bad }
                                Tx { visible: !kb.modelData.editable; anchors.verticalCenter: parent.verticalCenter; text: root.word("made by a loop"); font.pixelSize: root.px - 3; opacity: 0.4 }
                                Push {
                                    visible: kb.modelData.editable
                                    implicitHeight: Math.round(root.px * 2)
                                    code: "f11c"
                                    lit: kb.rec
                                    onClicked: { root.typing = ""; root.keyNote = ""; root.recording = kb.rec ? "" : kb.modelData.id }
                                }
                                Push {
                                    visible: kb.modelData.editable
                                    implicitHeight: Math.round(root.px * 2)
                                    code: "f040"
                                    lit: kb.typed
                                    onClicked: { root.recording = ""; root.keyNote = ""; root.typing = kb.typed ? "" : kb.modelData.id }
                                }
                            }
                            Connections {
                                target: root
                                function onReveal(k) { if (k === kb.modelData.id) root.scrollTo(kb) }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: configPage

        Item {
            id: cp
            readonly property var shown: root.module === "" ? root.rows : root.rows.filter(r => r.group === root.module && (root.only === "" || !!r.head || r.id === root.only || r.id.startsWith(root.only)))
            readonly property int wantRow: root.want.indexOf("row:") === 0 ? shown.findIndex(r => r.id === root.want.slice(4)) : -1
            readonly property real colWide: Math.min(width, root.colW + root.gap * 2)
            readonly property bool held: cur >= 0 && cur < shown.length
            property int cur: -1
            onShownChanged: cur = -1
            function nav(k) {
                const n = shown.length
                if (!n) return false
                if (k === "first" || k === "up" || k === "down" || !held) {
                    if (k === "left") return false
                    const d = k === "up" ? -1 : 1
                    let i = k === "first" && held ? cur - 1 : held ? cur : -1
                    for (let t = 0; t < n; t++) {
                        i = (i + d + n) % n
                        if (!shown[i].head) break
                    }
                    cur = i
                    lv.positionViewAtIndex(i, ListView.Contain)
                    return true
                }
                const it = lv.itemAtIndex(cur)
                return it ? it.key(k) : false
            }
            readonly property real colAt: Math.round((width - colWide) / 2)

            Item {
                id: cpTop
                x: cp.colAt + root.gap
                y: Math.round(root.gap * 1.2)
                width: cp.colWide - root.gap * 2
                height: Math.max(chips.height, opener.height)
                Flow {
                    id: chips
                    width: parent.width - opener.width - root.gap
                    spacing: 6
                    Push { text: root.word("All"); lit: root.module === ""; implicitHeight: Math.round(root.px * 2); onClicked: { root.only = ""; root.module = "" } }
                    Repeater {
                        model: root.modules
                        delegate: Push {
                            id: chipBtn
                            required property string modelData
                            text: root.human(root.title(modelData))
                            lit: root.module === modelData
                            implicitHeight: Math.round(root.px * 2)
                            onClicked: { root.only = ""; root.module = modelData }
                            Halo { lit: root.want === "chip:" + chipBtn.modelData; anchors.margins: -3 }
                        }
                    }
                }
                Push { id: opener; anchors.right: parent.right; text: root.word("Open config.json"); code: "f08e"; onClicked: root.edited() }
            }

            ListView {
                id: lv
                x: cp.colAt
                y: cpTop.y + cpTop.height + Math.round(root.px * 0.8)
                width: cp.colWide
                height: parent.height - y
                clip: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                model: cp.shown

                delegate: Item {
                    id: rw
                    required property var modelData
                    required property int index
                    readonly property bool head: !!modelData.head
                    readonly property var path: modelData.path ?? []
                    readonly property string leaf: path.length ? String(path[path.length - 1]) : ""
                    readonly property var value: head ? undefined : root.dig(root.cfg, path)
                    readonly property var first: head ? undefined : root.dig(root.stock, path)
                    readonly property bool changed: !head && first !== undefined && JSON.stringify(value) !== JSON.stringify(first)
                    readonly property bool marked: !head && root.keys && root.zone === "page" && cp.cur === index
                    function key(k) { return root.keyInto(rwCtl.item, k) }
                    width: lv.width
                    height: head ? Math.round(root.px * 4.2) : root.rowH + 8

                    Tx {
                        visible: rw.head
                        x: root.gap
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        text: String(rw.modelData.head ?? "")
                        font.pixelSize: root.px + 4
                        font.weight: Font.DemiBold
                    }

                    HoverHandler { id: rwArea }
                    Halo { lit: !rw.head && root.want === "row:" + rw.modelData.id }
                    Rectangle { visible: !rw.head && (rwArea.hovered || rw.marked); anchors.fill: parent; anchors.leftMargin: root.gap - root.rowPad; anchors.rightMargin: root.gap - root.rowPad; radius: root.rad; color: root.soft; border.width: rw.marked ? 2 : 0; border.color: root.hi }
                    Row {
                        visible: !rw.head
                        x: root.gap
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Tx { text: String(rw.modelData.label ?? ""); color: root.hit === rw.modelData.id ? root.hi : root.tx; anchors.verticalCenter: parent.verticalCenter }
                        Info { anchors.verticalCenter: parent.verticalCenter; text: rw.head ? "" : (root.info(String(rw.modelData.id)) !== "" ? root.info(String(rw.modelData.id)) + "\n" : "") + rw.path.join(" \u203a ") }
                    }
                    Row {
                        visible: !rw.head
                        anchors.right: parent.right
                        anchors.rightMargin: root.gap
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Gl {
                            id: rwBack
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(root.px * 1.8)
                            height: root.rowH
                            code: "f0e2"
                            font.pixelSize: root.px
                            opacity: rwBackArea.containsMouse ? 1 : rw.changed ? 0.6 : rwArea.hovered || rw.marked ? 0.3 : 0
                            Behavior on opacity { Glide {} }
                            MouseArea {
                                id: rwBackArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onContainsMouseChanged: containsMouse ? root.hint(rwBack, root.word("Reset to default")) : root.unhint(rwBack)
                                onClicked: { root.unhint(rwBack); root.reset(rw.path) }
                            }
                            Component.onDestruction: root.unhint(rwBack)
                        }
                        Loader {
                            id: rwCtl
                            anchors.verticalCenter: parent.verticalCenter
                            active: !rw.head
                            sourceComponent: {
                                const k = rw.modelData.kind
                                if (root.choices[rw.modelData.id]) return enumC
                                return k === "bool" ? boolC : k === "num" ? numC : k === "color" ? colorC : k === "icon" ? iconC : k === "ease" ? easeC : k === "font" ? fontC : k === "text" ? textC : rawC
                            }
                        }
                    }

                    Component {
                        id: enumC
                        Pick {
                            readonly property var list: root.choices[rw.modelData.id] ?? []
                            implicitWidth: Math.round(root.px * 19)
                            value: String(rw.value)
                            shown: (list.find(o => o.value === String(rw.value)) ?? ({ text: String(rw.value) })).text
                            options: list
                            onChosen: v => root.set(rw.path, typeof rw.value === "number" ? Number(v) : v)
                        }
                    }
                    Component {
                        id: boolC
                        Knob { lit: rw.value === true; onToggled: root.set(rw.path, rw.value !== true) }
                    }
                    Component {
                        id: numC
                        Entry {
                            id: numEntry
                            implicitWidth: Math.round(root.px * 7)
                            value: String(rw.value)
                            onCommit: t => {
                                const n = Number(t)
                                if (t.trim() === "" || isNaN(n)) numEntry.fail()
                                else root.set(rw.path, n)
                            }
                        }
                    }
                    Component {
                        id: colorC
                        Row {
                            spacing: 10
                            Rectangle {
                                id: tint
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(root.px * 2)
                                height: width
                                radius: width / 2
                                color: root.shade(rw.value)
                                border.width: 1
                                border.color: root.softer
                                MouseArea { anchors.fill: parent; onPressed: root.unfocus(); onClicked: root.paint(tint, rw.path, rw.value, true) }
                            }
                            Entry {
                                id: colorEntry
                                implicitWidth: Math.round(root.px * 9)
                                value: String(rw.value)
                                onCommit: t => { if (t.trim()) root.set(rw.path, t.trim()); else colorEntry.fail() }
                            }
                        }
                    }
                    Component {
                        id: iconC
                        Row {
                            spacing: 10
                            Gl { anchors.verticalCenter: parent.verticalCenter; width: Math.round(root.px * 2); code: String(rw.value); font.pixelSize: root.px + 5 }
                            Entry {
                                id: iconEntry
                                implicitWidth: Math.round(root.px * 7)
                                value: String(rw.value)
                                onCommit: t => { if (t.trim()) root.set(rw.path, t.trim()); else iconEntry.fail() }
                            }
                        }
                    }
                    Component {
                        id: easeC
                        Pick { value: String(rw.value); options: root.easings; filter: true; onChosen: v => root.set(rw.path, v) }
                    }
                    Component {
                        id: fontC
                        Pick { value: String(rw.value); family: String(rw.value); filter: true; options: root.fonts(/Icon/.test(rw.leaf)); onChosen: v => root.set(rw.path, v) }
                    }
                    Component {
                        id: textC
                        Entry { implicitWidth: Math.round(root.px * 18); value: String(rw.value ?? ""); onCommit: t => root.set(rw.path, t) }
                    }
                    Component {
                        id: rawC
                        Row {
                            spacing: 10
                            Tx { anchors.verticalCenter: parent.verticalCenter; text: Array.isArray(rw.value) ? rw.value.length + " " + root.word("items") : root.word("list"); opacity: 0.5 }
                            Push { text: root.word("Edit in file"); implicitHeight: Math.round(root.px * 2); onClicked: root.edited() }
                        }
                    }
                }
            }
            Scroller { view: lv }
            Rectangle {
                visible: lv.contentHeight > lv.height
                anchors.right: parent.right
                anchors.rightMargin: 4
                width: 3
                radius: 1.5
                y: lv.y + lv.visibleArea.yPosition * (lv.height - 6)
                height: lv.visibleArea.heightRatio * (lv.height - 6)
                color: root.tx
                opacity: 0.25
            }
            Connections {
                target: root
                function onRevealRow(k) {
                    const i = cp.shown.findIndex(r => r.id === k)
                    if (i >= 0) lv.positionViewAtIndex(i, ListView.Center)
                }
            }
            Item {
                id: edge
                readonly property bool above: cp.wantRow >= 0 && cp.wantRow < lv.indexAt(lv.width / 2, lv.contentY + 4)
                x: lv.x + root.gap
                y: above ? lv.y : lv.y + lv.height - height
                width: lv.width - root.gap * 2
                height: root.rowH
                onYChanged: if (root.haloEdge === edge) root.locate()
                Component.onDestruction: if (root.haloEdge === edge) root.haloEdge = null
            }
            Binding { target: root; property: "haloEdge"; value: cp.wantRow >= 0 ? edge : null }
            Connections {
                target: lv
                function onContentYChanged() { if (root.haloEdge === edge) root.locate() }
            }
        }
    }

    Component {
        id: infoPage

        Pane {
            Row {
                width: parent.width
                spacing: root.gap
                Face {
                    id: portrait
                    size: Math.round(root.px * 9)
                    source: root.infoImage
                    trim: mug
                }
                Column {
                    width: parent.width - portrait.width - root.gap
                    spacing: Math.round(root.px * 0.8)
                    Tx { text: root.infoName; font.pixelSize: root.px + 10; font.bold: true }
                    Tx { width: parent.width; wrapMode: Text.WordWrap; lineHeight: 1.35; text: root.infoText; opacity: 0.8 }
                }
            }
            Group {
                key: "Files"
                icon: "f07b"
                RowLine {
                    label: "Dolphin folder"
                    sub: root.rel(root.dolphin)
                    Push { text: root.word("Open"); code: "f07c"; onClicked: root.openFolder(root.dolphin) }
                }
                RowLine {
                    label: "Settings file"
                    sub: root.rel(root.configFile)
                    Push { text: root.word("Open"); code: "f08e"; onClicked: root.edited() }
                }
                RowLine {
                    label: "Editor"
                    note: "Opens scripts and config files"
                    Entry {
                        id: editorEntry
                        value: root.editor
                        onCommit: t => { if (t.trim()) root.set(["dolphin_EditorDefault"], t.trim()); else editorEntry.fail() }
                    }
                    Push { text: root.word("Pick"); onClicked: root.ask("") }
                }
            }
        }
    }

    LazyLoader {
        active: root.open && root.s("settings_Show")

        FloatingWindow {
            id: win
            property int mine: -1
            title: root.side === "left" ? "dolphin-settings-left" : "dolphin-settings"
            implicitWidth: Math.max(760, root.keepW > 0 ? root.keepW : Math.round((win.screen?.width ?? 1440) * root.s("settings_Width")))
            implicitHeight: Math.max(480, root.keepH > 0 ? root.keepH : Math.round((win.screen?.height ?? 900) * root.s("settings_Height")))
            color: root.bg
            Component.onCompleted: mine = root.epoch
            onVisibleChanged: if (!visible && mine === root.epoch && !root.hopping) root.open = false
            onWidthChanged: if (visible && width >= 760) root.nowW = Math.round(width)
            onHeightChanged: if (visible && height >= 480) root.nowH = Math.round(height)

            Item {
                id: desk
                property int at: 0
                readonly property var found: root.search(root.query)
                anchors.fill: parent
                focus: true

                function choose(e) {
                    if (!e) return
                    seek.text = ""
                    root.unfocus()
                    root.go(e)
                }

                Keys.onPressed: e => {
                    if (root.recording !== "") root.capture(e)
                    else if (e.key === Qt.Key_Escape) root.back()
                    else if (e.key === Qt.Key_F && (e.modifiers & Qt.ControlModifier)) { seek.forceActiveFocus(); seek.selectAll() }
                    else if (root.presets && desk.activeFocus && root.presetKey(e.key)) {}
                    else if (root.busy) return
                    else if (e.key === Qt.Key_Tab && (e.modifiers & Qt.ControlModifier)) root.step(1)
                    else if (e.key === Qt.Key_Backtab && (e.modifiers & Qt.ControlModifier)) root.step(-1)
                    else if (root.arrows[e.key] && desk.activeFocus && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) root.arrow(root.arrows[e.key])
                    else if (e.text.length === 1 && e.text >= " " && e.text !== "\x7f" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) { seek.text += e.text; seek.forceActiveFocus() }
                    else return
                    e.accepted = true
                }

                Connections {
                    target: root
                    function onUnfocus() { desk.forceActiveFocus(); root.keys = false }
                    function onMenuChanged() { if (!root.menu) desk.forceActiveFocus() }
                    function onPickChanged() { if (!root.pick) desk.forceActiveFocus() }
                    function onBrowseChanged() { if (!root.browse) desk.forceActiveFocus() }
                    function onPresetsChanged() {
                        desk.forceActiveFocus()
                        if (root.presets) root.presetAt = Math.max(0, [Presets.stockName].concat(Presets.names).indexOf(Presets.current))
                    }
                    function onCroppingChanged() { if (root.cropping === "") desk.forceActiveFocus() }
                    function onAskingChanged() { if (!root.asking) desk.forceActiveFocus() }
                    function onSureChanged() { if (!root.sure) desk.forceActiveFocus() }
                }
                Connections {
                    target: Config
                    function onValuesChanged() { root.syncRows() }
                }

                MouseArea { anchors.fill: parent; onPressed: root.unfocus() }

                Item {
                    id: crown
                    width: parent.width
                    height: Math.round(root.px * 4.4)

                    Row {
                        x: root.gap + root.s("settings_IconShift")
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12 - root.s("settings_IconShift")
                        Gl { code: root.s("settings_Icon"); font.pixelSize: root.px + 11; anchors.verticalCenter: parent.verticalCenter }
                        Tx { text: root.word(root.s("settings_Title")); font.pixelSize: root.px + 2; font.weight: Font.DemiBold; font.letterSpacing: 1; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Rectangle {
                        id: seekBox
                        anchors.centerIn: parent
                        width: Math.min(Math.round(root.px * 32), Math.round(desk.width * 0.38))
                        height: Math.round(root.px * 2.7)
                        radius: height / 2
                        color: root.pane
                        border.width: 1
                        border.color: seek.activeFocus ? root.hi : "transparent"
                        Gl { x: 14; anchors.verticalCenter: parent.verticalCenter; code: "f002"; font.pixelSize: root.px - 1; opacity: 0.6 }
                        TextInput {
                            id: seek
                            anchors.fill: parent
                            anchors.leftMargin: 38
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            selectByMouse: true
                            font.family: root.font
                            font.pixelSize: root.px
                            color: root.tx
                            selectionColor: root.hi
                            selectedTextColor: root.bg
                            onTextChanged: { root.query = text; desk.at = 0 }
                            Keys.onPressed: e => {
                                if (e.key === Qt.Key_Escape) { if (text !== "") text = ""; else root.unfocus() }
                                else if (e.key === Qt.Key_Down) desk.at = Math.min(desk.found.length - 1, desk.at + 1)
                                else if (e.key === Qt.Key_Up) desk.at = Math.max(0, desk.at - 1)
                                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) desk.choose(desk.found[desk.at])
                                else return
                                e.accepted = true
                            }
                        }
                        Tx { visible: seek.text === ""; x: 38; anchors.verticalCenter: parent.verticalCenter; text: root.word("Search settings"); opacity: 0.45 }
                        Tx { visible: seek.text === ""; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "Ctrl F"; font.pixelSize: root.px - 3; opacity: 0.35 }
                    }

                    Item {
                        anchors.right: parent.right
                        anchors.rightMargin: root.gap - 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(root.px * 2.4)
                        height: width
                        Rectangle { anchors.fill: parent; radius: width / 2; color: shut.containsMouse ? root.bad : "transparent" }
                        Gl { anchors.centerIn: parent; code: "f00d"; font.pixelSize: root.px + 1; color: shut.containsMouse ? root.bg : root.tx }
                        MouseArea { id: shut; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = false }
                    }
                }

                Item {
                    id: side
                    y: crown.height
                    width: Math.round(root.px * 15)
                    height: parent.height - y

                    Column {
                        id: who
                        y: Math.round(root.px * 0.6)
                        width: parent.width
                        spacing: Math.round(root.px * 0.6)
                        Face { size: Math.round(root.px * 4.6); anchors.horizontalCenter: parent.horizontalCenter }
                        Tx { anchors.horizontalCenter: parent.horizontalCenter; text: root.user; font.weight: Font.DemiBold }
                    }

                    Rectangle {
                        visible: root.tabAt >= 0
                        x: tabList.x
                        width: tabList.width
                        height: tabList.cell - 4
                        radius: height / 2
                        y: tabList.y + Math.max(0, root.tabAt) * tabList.cell + 2
                        color: root.glow
                        border.width: root.keys && root.zone === "rail" ? 2 : 0
                        border.color: root.hi
                        Behavior on y { NumberAnimation { duration: Motion.time; easing.type: Motion.ease } }
                    }
                    Column {
                        id: tabList
                        readonly property real cell: Math.round(root.px * 3.2)
                        x: Math.round(root.px * 0.9)
                        y: who.y + who.height + root.gap
                        width: parent.width - x * 2
                        Repeater {
                            model: root.tabs
                            delegate: Item {
                                id: tabRow
                                required property var modelData
                                readonly property bool lit: root.tab === modelData.Key
                                width: tabList.width
                                height: tabList.cell
                                Rectangle { anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: 2; radius: height / 2; visible: tabArea.containsMouse && !tabRow.lit; color: root.soft }
                                Gl { x: Math.round(root.px * 1.1); width: Math.round(root.px * 1.6); anchors.verticalCenter: parent.verticalCenter; code: String(tabRow.modelData.Icon ?? ""); color: tabRow.lit ? root.hi : root.mark; opacity: tabRow.lit ? 1 : 0.75 }
                                Tx { x: Math.round(root.px * 3.5); width: parent.width - x - 8; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: root.word(String(tabRow.modelData.Label ?? "")); font.weight: tabRow.lit ? Font.DemiBold : Font.Normal; opacity: tabRow.lit ? 1 : 0.75 }
                                MouseArea { id: tabArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: root.tab = tabRow.modelData.Key }
                                Halo { lit: root.want === "tab:" + tabRow.modelData.Key; anchors.margins: 2 }
                            }
                        }
                    }
                }

                Rectangle {
                    x: stage.x
                    y: stage.y
                    width: stage.width
                    height: stage.height
                    radius: root.round
                    color: root.pane
                }
                Item {
                    id: stage
                    readonly property real edge: Math.round(root.px * 0.7)
                    x: side.width
                    y: side.y
                    width: parent.width - x - edge
                    height: side.height - edge
                    clip: true

                    Loader {
                        id: page
                        anchors.fill: parent
                        sourceComponent: root.tab === "ai" ? aiPage : root.tab === "editor" ? editorPage : root.tab === "interface" ? interfacePage : root.tab === "system" ? systemPage : root.tab === "keys" ? keysPage : root.tab === "config" ? configPage : root.tab === "info" ? infoPage : stylePage
                        onLoaded: rise.restart()
                    }
                    Binding { target: root; property: "pageItem"; value: page.item }
                    ParallelAnimation {
                        id: rise
                        NumberAnimation { target: page; property: "opacity"; from: 0; to: 1; duration: Motion.time * 2; easing.type: Motion.ease }
                        NumberAnimation { target: page; property: "anchors.topMargin"; from: Math.round(root.px * 1.8); to: 0; duration: Motion.time * 2; easing.type: Motion.ease }
                    }

                    Loader {
                        anchors.fill: parent
                        active: !!root.browse
                        sourceComponent: Rectangle {
                            id: bl
                            property string dir: root.browse ? root.browse.dir : root.house
                            radius: root.round
                            color: root.pane
                            onDirChanged: scan.look()
                            Component.onCompleted: scan.look()

                            function choose(p) {
                                const f = root.browse.done
                                f(p)
                                root.browse = null
                            }

                            Process {
                                id: scan
                                property string want: ""
                                function look() {
                                    if (want === bl.dir && running) return
                                    want = bl.dir
                                    if (running) running = false
                                    else { command = root.thumbCmd([want]); running = true }
                                }
                                stdout: SplitParser { onRead: line => root.gotThumb(line) }
                                onExited: (exitCode, exitStatus) => { if (want !== "" && command[command.length - 1] !== want) { command = root.thumbCmd([want]); running = true } }
                            }

                            MouseArea { anchors.fill: parent; onPressed: root.unfocus(); onWheel: w => {} }

                            FolderListModel {
                                id: files
                                folder: root.url(bl.dir)
                                showDirsFirst: true
                                caseSensitive: false
                                nameFilters: (root.browse ? root.browse.exts : []).map(e => "*." + e)
                            }

                            Row {
                                id: blTop
                                x: root.gap
                                y: root.gap
                                height: root.rowH
                                spacing: 8
                                Push { code: "f060"; onClicked: root.browse = null }
                                Push { code: "f062"; visible: bl.dir.lastIndexOf("/") > 0; onClicked: bl.dir = bl.dir.replace(/\/[^\/]+$/, "") }
                                Tx { anchors.verticalCenter: parent.verticalCenter; text: root.browse ? root.browse.title : ""; font.pixelSize: root.px + 2; font.bold: true }
                                Tx { anchors.verticalCenter: parent.verticalCenter; text: root.rel(bl.dir); opacity: 0.5 }
                            }

                            GridView {
                                id: grid
                                x: root.gap
                                y: blTop.y + blTop.height + root.px
                                width: parent.width - root.gap * 2
                                height: parent.height - y - root.gap
                                clip: true
                                interactive: false
                                boundsBehavior: Flickable.StopAtBounds
                                cellWidth: Math.floor(width / Math.max(1, Math.floor(width / (root.px * 13))))
                                cellHeight: Math.round(root.px * 10.5)
                                model: files

                                delegate: Item {
                                    id: cell
                                    required property string fileName
                                    required property string filePath
                                    required property bool fileIsDir
                                    readonly property string shot: fileIsDir ? "" : root.thumb(filePath)
                                    width: grid.cellWidth
                                    height: grid.cellHeight

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        radius: root.round
                                        color: cellArea.containsMouse ? root.softer : root.soft

                                        ClippingRectangle {
                                            x: 6
                                            y: 6
                                            width: parent.width - 12
                                            height: parent.height - Math.round(root.px * 2.4) - 6
                                            radius: root.rad
                                            color: root.soft
                                            Image {
                                                anchors.fill: parent
                                                visible: cell.shot !== ""
                                                source: cell.shot
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                cache: false
                                            }
                                            Gl { anchors.centerIn: parent; visible: cell.shot === ""; code: cell.fileIsDir ? "f07b" : root.kind(cell.fileName) === "video" ? "f03d" : "f03e"; font.pixelSize: root.px * 2.4; color: root.hi }
                                        }
                                        Tx {
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: Math.round(root.px * 0.6)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: parent.width - 16
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideMiddle
                                            text: cell.fileName
                                            font.pixelSize: root.px - 2
                                        }
                                        MouseArea {
                                            id: cellArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (cell.fileIsDir) bl.dir = cell.filePath
                                                else bl.choose(cell.filePath)
                                            }
                                        }
                                    }
                                }
                            }
                            Scroller { view: grid }
                            Tx { anchors.centerIn: grid; visible: grid.count === 0; text: root.word("Nothing to pick in this folder"); opacity: 0.5 }
                        }
                    }
                }

                Rectangle {
                    id: bubble
                    property var last: null
                    readonly property var now: root.tip
                    readonly property real most: Math.round(root.px * Math.max(10, root.s("settings_TipWidth")))
                    onNowChanged: if (now) last = now
                    z: 80
                    visible: opacity > 0
                    opacity: now ? 1 : 0
                    scale: now ? 1 : 0.96
                    width: Math.min(most, bubbleProbe.implicitWidth) + Math.round(root.px * 1.6)
                    height: bubbleText.height + Math.round(root.px * 1.2)
                    x: last ? Math.max(8, Math.min(desk.width - width - 8, last.x - width / 2)) : 0
                    y: !last ? 0 : last.y + last.h + 6 + height > desk.height - 8 ? last.y - height - 6 : last.y + last.h + 6
                    radius: root.rad
                    color: root.bg
                    border.width: 1
                    border.color: root.softer
                    Behavior on opacity { Glide {} }
                    Behavior on scale { Glide {} }
                    Tx { id: bubbleProbe; visible: false; text: bubble.last ? bubble.last.text : "" }
                    Tx {
                        id: bubbleText
                        x: Math.round(root.px * 0.8)
                        y: Math.round(root.px * 0.6)
                        width: bubble.width - x * 2
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                        text: bubbleProbe.text
                    }
                }

                Rectangle {
                    id: hits
                    visible: seek.activeFocus && root.query.trim() !== "" && !root.busy
                    z: 40
                    x: seekBox.x
                    y: seekBox.y + seekBox.height + 4
                    width: seekBox.width
                    height: (desk.found.length ? desk.found.length : 1) * root.rowH + 12
                    radius: root.round
                    color: root.bg
                    border.width: 1
                    border.color: root.softer
                    MouseArea { anchors.fill: parent; onWheel: w => {} }
                    Tx { visible: desk.found.length === 0; anchors.centerIn: parent; text: root.word("Nothing found"); opacity: 0.5 }
                    Column {
                        x: 6
                        y: 6
                        width: parent.width - 12
                        Repeater {
                            model: desk.found
                            delegate: Rectangle {
                                id: hitRow
                                required property var modelData
                                required property int index
                                readonly property var tabOf: root.tabs.find(t => t.Key === modelData.tab) ?? ({})
                                width: parent.width
                                height: root.rowH
                                radius: root.rad
                                color: desk.at === index ? root.softer : "transparent"
                                Gl { x: 8; width: Math.round(root.px * 1.6); anchors.verticalCenter: parent.verticalCenter; code: String(hitRow.tabOf.Icon ?? ""); font.pixelSize: root.px; opacity: 0.7 }
                                Tx { x: 8 + Math.round(root.px * 2.2); width: parent.width - x - hitSub.width - 16; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: root.word(hitRow.modelData.label) }
                                Tx { id: hitSub; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: hitRow.modelData.sub || root.word(String(hitRow.tabOf.Label ?? "")); font.pixelSize: root.px - 2; opacity: 0.45 }
                                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: desk.at = hitRow.index; onClicked: desk.choose(hitRow.modelData) }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    z: 50
                    active: !!root.menu
                    sourceComponent: Item {
                        id: ml
                        readonly property var m: root.menu ?? ({ x: 0, y: 0, w: 0, h: 0, options: [], current: "", filter: false })
                        readonly property var shown: {
                            const q = mlIn.text.toLowerCase()
                            return q ? m.options.filter(o => String(o.text).toLowerCase().includes(q)) : m.options
                        }
                        property int at: -1
                        Component.onCompleted: {
                            if (m.filter) { mlIn.forceActiveFocus(); return }
                            at = Math.max(0, m.options.findIndex(o => o.value === m.current))
                            forceActiveFocus()
                            mlList.positionViewAtIndex(at, ListView.Contain)
                        }
                        Keys.onPressed: e => {
                            const n = shown.length
                            if (e.key === Qt.Key_Down) at = (at + 1) % Math.max(1, n)
                            else if (e.key === Qt.Key_Up) at = (at + Math.max(1, n) - 1) % Math.max(1, n)
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { choose(shown[Math.max(0, at)]); e.accepted = true; return }
                            else return
                            mlList.positionViewAtIndex(at, ListView.Contain)
                            e.accepted = true
                        }

                        function choose(o) {
                            if (!o) return
                            const f = root.menu.done
                            f(o.value)
                            root.menu = null
                        }

                        MouseArea { anchors.fill: parent; onClicked: root.menu = null; onWheel: w => {} }

                        Rectangle {
                            id: mlBox
                            readonly property real off: ml.m.filter ? root.rowH + 6 : 0
                            width: Math.max(ml.m.w, Math.round(root.px * 15))
                            height: off + mlList.height + 12
                            x: Math.max(4, Math.min(ml.m.x + ml.m.w - width, ml.width - width - 4))
                            y: ml.m.y + ml.m.h + 4 + height > ml.height ? Math.max(4, ml.m.y - height - 4) : ml.m.y + ml.m.h + 4
                            radius: root.round
                            color: root.bg
                            border.width: 1
                            border.color: root.softer
                            transformOrigin: Item.Top
                            NumberAnimation on opacity { from: 0; to: 1; duration: Motion.time }
                            NumberAnimation on scale { from: 0.94; to: 1; duration: Motion.time; easing.type: Motion.ease }

                            MouseArea { anchors.fill: parent }

                            Rectangle {
                                visible: ml.m.filter
                                x: 6
                                y: 6
                                width: parent.width - 12
                                height: root.rowH
                                radius: root.rad
                                color: root.pane
                                Gl { x: 10; anchors.verticalCenter: parent.verticalCenter; code: "f002"; font.pixelSize: root.px - 1; opacity: 0.5 }
                                TextInput {
                                    id: mlIn
                                    anchors.fill: parent
                                    anchors.leftMargin: 32
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    font.family: root.font
                                    font.pixelSize: root.px
                                    color: root.tx
                                    selectionColor: root.hi
                                    selectedTextColor: root.bg
                                    onTextChanged: ml.at = -1
                                    onAccepted: ml.choose(ml.shown[Math.max(0, ml.at)])
                                    Keys.onPressed: e => {
                                        if (e.key === Qt.Key_Escape) root.menu = null
                                        else if (e.key === Qt.Key_Down) { ml.at = Math.min(ml.shown.length - 1, ml.at + 1); mlList.positionViewAtIndex(ml.at, ListView.Contain) }
                                        else if (e.key === Qt.Key_Up) { ml.at = Math.max(0, ml.at - 1); mlList.positionViewAtIndex(ml.at, ListView.Contain) }
                                        else return
                                        e.accepted = true
                                    }
                                }
                            }

                            ListView {
                                id: mlList
                                x: 6
                                y: 6 + mlBox.off
                                width: parent.width - 12
                                height: Math.min(count, 8) * root.rowH
                                clip: true
                                interactive: false
                                boundsBehavior: Flickable.StopAtBounds
                                model: ml.shown
                                delegate: Rectangle {
                                    id: mi
                                    required property var modelData
                                    required property int index
                                    width: mlList.width
                                    height: root.rowH
                                    radius: Math.max(0, root.rad - 2)
                                    color: miArea.containsMouse || ml.at === index ? root.softer : "transparent"
                                    Rectangle { visible: !!mi.modelData.tint; x: 8; anchors.verticalCenter: parent.verticalCenter; width: Math.round(root.px * 1.2); height: width; radius: 3; color: mi.modelData.tint ?? "transparent"; border.width: 1; border.color: root.bd }
                                    Tx {
                                        x: mi.modelData.tint ? 16 + Math.round(root.px * 1.2) : 10
                                        width: parent.width - x - 34
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: String(mi.modelData.text)
                                        font.family: mi.modelData.family || root.font
                                    }
                                    Gl { visible: mi.modelData.value === ml.m.current; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; code: "f00c"; font.pixelSize: root.px - 1; color: root.hi }
                                    MouseArea { id: miArea; anchors.fill: parent; hoverEnabled: true; onClicked: ml.choose(mi.modelData) }
                                }
                            }
                            Scroller { view: mlList }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    z: 60
                    active: !!root.pick
                    sourceComponent: Item {
                        id: pl
                        readonly property var p: root.pick ?? ({ x: 0, y: 0, h: 0, value: "#ffffff", alpha: false })
                        readonly property int d: Math.round(root.px * 14)
                        property color seed: "#ffffff"
                        property real hh: 0
                        property real ss: 0
                        property real vv: 1
                        property real aa: 1
                        readonly property color cur: Qt.hsva(hh, ss, vv, p.alpha ? aa : 1)
                        Component.onCompleted: read(p.value)

                        function read(v) {
                            try { seed = v } catch (e) { return false }
                            hh = Math.max(0, seed.hsvHue)
                            ss = seed.hsvSaturation
                            vv = seed.hsvValue
                            aa = seed.a
                            return true
                        }
                        function save() { if (root.pick) root.pick.done(root.hex(cur, p.alpha)) }

                        MouseArea { anchors.fill: parent; onClicked: root.pick = null; onWheel: w => {} }

                        Rectangle {
                            width: pl.d + 28
                            height: plCol.height + 28
                            x: Math.max(4, Math.min(pl.p.x, pl.width - width - 4))
                            y: pl.p.y + pl.p.h + 4 + height > pl.height ? Math.max(4, pl.p.y - height - 4) : pl.p.y + pl.p.h + 4
                            radius: root.round
                            color: root.bg
                            border.width: 1
                            border.color: root.softer

                            MouseArea { anchors.fill: parent; onPressed: root.unfocus() }

                            Column {
                                id: plCol
                                x: 14
                                y: 14
                                width: pl.d
                                spacing: 12

                                Item {
                                    width: pl.d
                                    height: pl.d

                                    ClippingRectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "transparent"
                                        Shape {
                                            anchors.fill: parent
                                            ShapePath {
                                                strokeWidth: -1
                                                fillGradient: ConicalGradient {
                                                    centerX: pl.d / 2
                                                    centerY: pl.d / 2
                                                    angle: 0
                                                    GradientStop { position: 0; color: "#ff0000" }
                                                    GradientStop { position: 0.1667; color: "#ff00ff" }
                                                    GradientStop { position: 0.3333; color: "#0000ff" }
                                                    GradientStop { position: 0.5; color: "#00ffff" }
                                                    GradientStop { position: 0.6667; color: "#00ff00" }
                                                    GradientStop { position: 0.8333; color: "#ffff00" }
                                                    GradientStop { position: 1; color: "#ff0000" }
                                                }
                                                startX: 0
                                                startY: 0
                                                PathLine { x: pl.d; y: 0 }
                                                PathLine { x: pl.d; y: pl.d }
                                                PathLine { x: 0; y: pl.d }
                                                PathLine { x: 0; y: 0 }
                                            }
                                            ShapePath {
                                                strokeWidth: -1
                                                fillGradient: RadialGradient {
                                                    centerX: pl.d / 2
                                                    centerY: pl.d / 2
                                                    centerRadius: pl.d / 2
                                                    focalX: pl.d / 2
                                                    focalY: pl.d / 2
                                                    GradientStop { position: 0; color: "#ffffffff" }
                                                    GradientStop { position: 1; color: "#00ffffff" }
                                                }
                                                startX: 0
                                                startY: 0
                                                PathLine { x: pl.d; y: 0 }
                                                PathLine { x: pl.d; y: pl.d }
                                                PathLine { x: 0; y: pl.d }
                                                PathLine { x: 0; y: 0 }
                                            }
                                        }
                                    }
                                    Rectangle { anchors.fill: parent; radius: width / 2; color: "black"; opacity: 1 - pl.vv }
                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7
                                        x: pl.d / 2 + Math.cos(pl.hh * 2 * Math.PI) * pl.ss * pl.d / 2 - 7
                                        y: pl.d / 2 + Math.sin(pl.hh * 2 * Math.PI) * pl.ss * pl.d / 2 - 7
                                        color: Qt.hsva(pl.hh, pl.ss, pl.vv, 1)
                                        border.width: 2
                                        border.color: pl.vv > 0.6 && pl.ss < 0.5 ? "black" : "white"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        function at(m) {
                                            const r = pl.d / 2, dx = m.x - r, dy = m.y - r
                                            pl.hh = (Math.atan2(dy, dx) / (2 * Math.PI) + 1) % 1
                                            pl.ss = Math.min(1, Math.sqrt(dx * dx + dy * dy) / r)
                                        }
                                        onPressed: m => { root.unfocus(); at(m) }
                                        onPositionChanged: m => at(m)
                                        onReleased: pl.save()
                                    }
                                }

                                Row {
                                    spacing: 8
                                    Gl { width: 18; height: 20; code: "f185"; font.pixelSize: root.px }
                                    Slide { implicitWidth: pl.d - 26; implicitHeight: 20; value: pl.vv; onMoved: v => pl.vv = v; onDone: v => pl.save() }
                                }
                                Row {
                                    visible: pl.p.alpha === true
                                    spacing: 8
                                    Gl { width: 18; height: 20; code: "f043"; font.pixelSize: root.px }
                                    Slide { implicitWidth: pl.d - 26; implicitHeight: 20; value: pl.aa; onMoved: v => pl.aa = v; onDone: v => pl.save() }
                                }
                                Row {
                                    spacing: 8
                                    Rectangle { width: root.rowH; height: width; radius: root.rad; color: pl.cur; border.width: 1; border.color: root.bd }
                                    Entry {
                                        id: plHex
                                        implicitWidth: pl.d - root.rowH - 8
                                        value: root.hex(pl.cur, pl.p.alpha)
                                        onCommit: t => {
                                            const m = t.trim().match(pl.p.alpha ? /^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/ : /^#?([0-9a-fA-F]{6})$/)
                                            if (m && pl.read("#" + m[1])) pl.save()
                                            else plHex.fail()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    z: 65
                    active: !!root.asking
                    sourceComponent: Item {
                        id: al

                        Rectangle { anchors.fill: parent; color: root.bg; opacity: 0.8 }
                        MouseArea { anchors.fill: parent; onClicked: root.asking = null; onWheel: w => {} }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(Math.round(root.px * 34), parent.width - root.gap * 2)
                            height: alCol.height + root.gap * 2
                            radius: root.round
                            color: root.bg
                            border.width: 1
                            border.color: root.softer

                            MouseArea { anchors.fill: parent; onPressed: root.unfocus() }

                            Column {
                                id: alCol
                                x: root.gap
                                y: root.gap
                                width: parent.width - root.gap * 2
                                spacing: Math.round(root.px * 0.9)

                                Tx { text: root.word("Pick an editor"); font.pixelSize: root.px + 4; font.bold: true }
                                Tx {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    opacity: 0.6
                                    text: (root.asking && root.asking.path !== "" ? root.editor + " " + root.word("is not installed.") + " " : "") + root.word("Choose the app that opens scripts and config files.")
                                }
                                Flow {
                                    width: parent.width
                                    spacing: 8
                                    Repeater {
                                        model: root.editors
                                        delegate: Push {
                                            required property string modelData
                                            text: modelData
                                            lit: root.editor === modelData
                                            onClicked: root.useEditor(modelData)
                                        }
                                    }
                                }
                                Tx { visible: root.editors.length === 0 && !probe.running; width: parent.width; wrapMode: Text.WordWrap; opacity: 0.6; text: root.word("No editor was found on this computer. Install one, or type its command below.") }
                                Row {
                                    spacing: 8
                                    Entry {
                                        id: alEntry
                                        keep: true
                                        implicitWidth: alCol.width - alOk.width - alNo.width - 16
                                        hint: root.word("Command, for example kate")
                                        onCommit: t => { if (!root.useEditor(t)) alEntry.fail() }
                                    }
                                    Push { id: alOk; text: root.word("Use"); onClicked: { if (!root.useEditor(alEntry.typed)) alEntry.fail() } }
                                    Push { id: alNo; text: root.word("Cancel"); onClicked: root.asking = null }
                                }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    z: 64
                    active: root.presets
                    sourceComponent: Item {
                        id: pb
                        property string renaming: ""
                        property string dropping: ""
                        readonly property var all: [Presets.stockName].concat(Presets.names)
                        Component.onCompleted: Presets.refresh()

                        function make() {
                            if (Presets.add(pbNew.typed.trim() !== "" ? pbNew.typed : Presets.free(root.word("Preset")))) { pbNew.clear(); root.unfocus() }
                            else pbNew.fail()
                        }

                        Rectangle { anchors.fill: parent; color: root.bg; opacity: 0.8 }
                        MouseArea { anchors.fill: parent; onClicked: root.presets = false; onWheel: w => {} }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(Math.round(root.px * 38), parent.width - root.gap * 2)
                            height: pbCol.height + root.gap * 2
                            radius: root.round
                            color: root.bg
                            border.width: 1
                            border.color: root.softer

                            MouseArea { anchors.fill: parent; onPressed: root.unfocus() }

                            Column {
                                id: pbCol
                                x: root.gap
                                y: root.gap
                                width: parent.width - root.gap * 2
                                spacing: Math.round(root.px * 0.9)

                                Item {
                                    width: parent.width
                                    height: root.rowH
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10
                                        Gl { anchors.verticalCenter: parent.verticalCenter; code: "f0c7"; font.pixelSize: root.px + 3 }
                                        Tx { anchors.verticalCenter: parent.verticalCenter; text: root.word("Setting presets"); font.pixelSize: root.px + 4; font.bold: true }
                                    }
                                    Push { anchors.right: parent.right; code: "f00d"; onClicked: root.presets = false }
                                }
                                Row {
                                    spacing: 8
                                    Tx { text: root.word("Selected") + ":"; opacity: 0.6 }
                                    Tx { text: Presets.current; color: root.hi; font.weight: Font.DemiBold }
                                }

                                Flickable {
                                    id: pbFlick
                                    width: parent.width
                                    height: Math.min(pbList.height, Math.round(root.px * 22))
                                    contentHeight: pbList.height
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    Column {
                                        id: pbList
                                        width: parent.width
                                        spacing: 4
                                        Repeater {
                                            model: pb.all
                                            delegate: Rectangle {
                                                id: pr
                                                required property string modelData
                                                required property int index
                                                readonly property bool fixed: modelData === Presets.stockName
                                                readonly property bool live: modelData === Presets.current
                                                readonly property bool editing: pb.renaming === modelData
                                                readonly property bool asking: pb.dropping === modelData
                                                width: pbList.width
                                                height: root.rowH + 10
                                                radius: root.rad
                                                color: live ? root.glow : prArea.containsMouse ? root.soft : "transparent"
                                                border.width: root.keys && root.presetAt === index ? 2 : 0
                                                border.color: root.hi
                                                Behavior on color { Tint {} }

                                                MouseArea { id: prArea; anchors.fill: parent; hoverEnabled: true; onPressed: root.unfocus(); onClicked: { root.presetAt = pr.index; Presets.use(pr.modelData) } }
                                                Gl { id: prMark; x: 8; width: Math.round(root.px * 1.8); anchors.verticalCenter: parent.verticalCenter; code: pr.fixed ? "f023" : "f00c"; font.pixelSize: root.px; color: pr.live ? root.hi : root.mark; opacity: pr.live ? 1 : pr.fixed ? 0.45 : 0 }
                                                Tx {
                                                    visible: !pr.editing
                                                    x: prMark.x + prMark.width + 6
                                                    width: Math.max(0, prTools.x - x - 8)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    elide: Text.ElideRight
                                                    text: pr.modelData + (pr.fixed ? "  \u00b7  " + root.word("never changes") : "")
                                                }
                                                Entry {
                                                    id: prName
                                                    visible: pr.editing
                                                    x: prMark.x + prMark.width + 6
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    implicitWidth: Math.max(60, prTools.x - x - 8)
                                                    keep: true
                                                    value: pr.modelData
                                                    hint: root.word("New name")
                                                    onVisibleChanged: if (visible) grab()
                                                    onCommit: t => { if (Presets.rename(pr.modelData, t)) pb.renaming = ""; else fail() }
                                                    onCancel: pb.renaming = ""
                                                }
                                                Row {
                                                    id: prTools
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 6
                                                    Push { visible: pr.asking; text: root.word("Delete"); danger: true; onClicked: { pb.dropping = ""; Presets.remove(pr.modelData) } }
                                                    Push { visible: pr.asking; text: root.word("Cancel"); onClicked: pb.dropping = "" }
                                                    Gl {
                                                        visible: !pr.fixed && !pr.asking
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: Math.round(root.px * 2)
                                                        height: root.rowH
                                                        code: "f040"
                                                        font.pixelSize: root.px
                                                        opacity: prPen.containsMouse ? 1 : 0.5
                                                        MouseArea { id: prPen; anchors.fill: parent; hoverEnabled: true; onClicked: { pb.dropping = ""; pb.renaming = pr.editing ? "" : pr.modelData } }
                                                    }
                                                    Gl {
                                                        visible: !pr.fixed && !pr.asking
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: Math.round(root.px * 2)
                                                        height: root.rowH
                                                        code: "f1f8"
                                                        color: root.bad
                                                        font.pixelSize: root.px
                                                        opacity: prBin.containsMouse ? 1 : 0.5
                                                        MouseArea { id: prBin; anchors.fill: parent; hoverEnabled: true; onClicked: { pb.renaming = ""; pb.dropping = pr.modelData } }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: root.softer }
                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Entry { id: pbNew; keep: true; implicitWidth: parent.width - pbMake.width - 8; hint: root.word("Name of the new preset"); onCommit: t => pb.make() }
                                    Push { id: pbMake; text: root.word("Copy current to a new preset"); code: "f0c5"; lit: true; onClicked: pb.make() }
                                }
                                Tx { visible: Presets.note !== ""; width: parent.width; wrapMode: Text.WordWrap; text: root.word(Presets.note); color: root.bad }
                                Tx { width: parent.width; wrapMode: Text.WordWrap; opacity: 0.5; text: root.word("Your changes stay with the selected preset. Switching away from Default with changes keeps them as a preset called Custom.") }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    z: 66
                    active: !!root.sure
                    sourceComponent: Item {
                        id: box
                        readonly property string name: root.sure ? root.sure.name : ""
                        readonly property bool rename: !!root.sure && root.sure.kind === "rename"
                        Component.onCompleted: if (rename) slEntry.grab()

                        function done() {
                            if (!rename) {
                                const n = name
                                root.sure = null
                                root.dropTheme(n)
                            } else if (root.renameTheme(name, slEntry.typed)) root.sure = null
                            else slEntry.fail()
                        }

                        Rectangle { anchors.fill: parent; color: root.bg; opacity: 0.8 }
                        MouseArea { anchors.fill: parent; onClicked: root.sure = null; onWheel: w => {} }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(Math.round(root.px * 30), parent.width - root.gap * 2)
                            height: slCol.height + root.gap * 2
                            radius: root.round
                            color: root.bg
                            border.width: 1
                            border.color: root.softer

                            MouseArea { anchors.fill: parent }

                            Column {
                                id: slCol
                                x: root.gap
                                y: root.gap
                                width: parent.width - root.gap * 2
                                spacing: Math.round(root.px * 0.9)

                                Tx { width: parent.width; elide: Text.ElideRight; text: root.word(box.rename ? "Rename theme" : "Delete this theme?"); font.pixelSize: root.px + 4; font.bold: true }
                                Tx { width: parent.width; elide: Text.ElideRight; text: box.name; color: root.hi }
                                Tx { visible: !box.rename; width: parent.width; wrapMode: Text.WordWrap; opacity: 0.6; text: root.word("Its colours are removed from config.json. This cannot be undone.") }
                                Entry {
                                    id: slEntry
                                    visible: box.rename
                                    keep: true
                                    implicitWidth: slCol.width
                                    value: box.name
                                    hint: root.word("New name")
                                    onCommit: t => box.done()
                                    onCancel: root.sure = null
                                }
                                Row {
                                    anchors.right: parent.right
                                    spacing: 8
                                    Push { text: root.word(box.rename ? "Rename" : "Delete"); danger: !box.rename; onClicked: box.done() }
                                    Push { text: root.word("Cancel"); onClicked: root.sure = null }
                                }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    z: 70
                    active: root.cropping !== ""
                    sourceComponent: Rectangle {
                        id: viewer
                        readonly property real frame: height * Number(root.cfg?.greeter_CropSize ?? 0.6)
                        readonly property real zoomStep: Number(root.cfg?.greeter_ZoomStep ?? 1.15)
                        readonly property real zoomMax: Number(root.cfg?.greeter_ZoomMax ?? 8)
                        readonly property real padSpeed: Number(root.cfg?.greeter_TouchpadSpeed ?? 1)
                        readonly property real moveStep: Number(root.cfg?.greeter_MoveStep ?? 0.05)
                        readonly property int moveTime: Number(root.cfg?.greeter_MoveTime ?? 250)
                        readonly property int moveEase: Easing[root.cfg?.greeter_MoveEasing] ?? Easing.OutExpo
                        readonly property real iw: Math.max(1, vImg.implicitWidth)
                        readonly property real ih: Math.max(1, vImg.implicitHeight)
                        readonly property real rw: iw / Math.min(iw, ih)
                        readonly property real rh: ih / Math.min(iw, ih)
                        property bool animate: false
                        property real zoom: 1
                        property real fx: 0
                        property real fy: 0
                        property real vz: zoom
                        property real vx: fx
                        property real vy: fy
                        color: "black"
                        focus: true
                        Behavior on vz { enabled: viewer.animate; NumberAnimation { duration: Motion.span(viewer.moveTime); easing.type: viewer.moveEase } }
                        Behavior on vx { enabled: viewer.animate; NumberAnimation { duration: Motion.span(viewer.moveTime); easing.type: viewer.moveEase } }
                        Behavior on vy { enabled: viewer.animate; NumberAnimation { duration: Motion.span(viewer.moveTime); easing.type: viewer.moveEase } }
                        Component.onCompleted: {
                            place(crop.offsetX, crop.offsetY, Math.max(1, crop.zoom), false)
                            forceActiveFocus()
                        }

                        function place(x, y, z, anim) {
                            animate = anim
                            const mx = Math.max(0, (rw * z - 1) / 2)
                            const my = Math.max(0, (rh * z - 1) / 2)
                            zoom = z
                            fx = Math.max(-mx, Math.min(mx, x))
                            fy = Math.max(-my, Math.min(my, y))
                        }
                        function move(dx, dy, anim) { place(fx + dx, fy + dy, zoom, anim) }
                        function zoomAt(z, cx, cy, anim) {
                            z = Math.max(1, Math.min(zoomMax, z))
                            const r = z / zoom
                            place(cx - (cx - fx) * r, cy - (cy - fy) * r, z, anim)
                        }
                        function finish(keep) {
                            if (keep) {
                                crop.zoom = zoom
                                crop.offsetX = fx
                                crop.offsetY = fy
                                cropFile.writeAdapter()
                            }
                            root.cropping = ""
                        }

                        Image {
                            id: vImg
                            source: root.avatarSrc
                            cache: false
                            mipmap: true
                            width: viewer.rw * viewer.frame
                            height: viewer.rh * viewer.frame
                            x: (parent.width - width) / 2 + viewer.vx * viewer.frame
                            y: (parent.height - height) / 2 + viewer.vy * viewer.frame
                            scale: viewer.vz
                        }
                        Rectangle { anchors.centerIn: parent; width: viewer.frame; height: width; radius: width / 2; color: "transparent"; border.width: 2; border.color: "white" }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 16
                            text: root.word("Drag to move  ·  Scroll to zoom  ·  Enter or click to save  ·  Esc to cancel")
                            color: "white"
                            opacity: 0.6
                            font.family: root.font
                            font.pixelSize: root.px
                        }

                        MouseArea {
                            anchors.fill: parent
                            property point last
                            property bool dragged: false
                            onPressed: m => { last = Qt.point(m.x, m.y); dragged = false }
                            onPositionChanged: m => {
                                const dx = m.x - last.x, dy = m.y - last.y
                                if (!dragged && Math.abs(dx) + Math.abs(dy) < 4) return
                                dragged = true
                                last = Qt.point(m.x, m.y)
                                viewer.move(dx / viewer.frame, dy / viewer.frame, false)
                            }
                            onClicked: if (!dragged) viewer.finish(true)
                            onWheel: w => {
                                const pad = w.pixelDelta.y !== 0
                                const dir = w.inverted ? -1 : 1
                                const d = dir * (pad ? w.pixelDelta.y * viewer.padSpeed / 25 : w.angleDelta.y / 120)
                                viewer.zoomAt(viewer.zoom * Math.pow(viewer.zoomStep, d), (w.x - width / 2) / viewer.frame, (w.y - height / 2) / viewer.frame, !pad)
                            }
                        }

                        PinchHandler {
                            target: null
                            onScaleChanged: delta => {
                                if (delta > 0) viewer.zoomAt(viewer.zoom * delta, (centroid.position.x - viewer.width / 2) / viewer.frame, (centroid.position.y - viewer.height / 2) / viewer.frame, false)
                            }
                        }

                        Keys.onPressed: e => {
                            const n = viewer.moveStep
                            if (e.key === Qt.Key_Left) viewer.move(-n, 0, true)
                            else if (e.key === Qt.Key_Right) viewer.move(n, 0, true)
                            else if (e.key === Qt.Key_Up) viewer.move(0, -n, true)
                            else if (e.key === Qt.Key_Down) viewer.move(0, n, true)
                            else if (e.key === Qt.Key_I || e.key === Qt.Key_Plus || e.key === Qt.Key_Equal) viewer.zoomAt(viewer.zoom * viewer.zoomStep, 0, 0, true)
                            else if (e.key === Qt.Key_O || e.key === Qt.Key_Minus) viewer.zoomAt(viewer.zoom / viewer.zoomStep, 0, 0, true)
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) viewer.finish(true)
                            else if (e.key === Qt.Key_Escape) viewer.finish(false)
                            else return
                            e.accepted = true
                        }
                    }
                }
            }
        }
    }
}
