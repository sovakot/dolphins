import QtQuick
import "../../../../Backend"

Widget {
    id: loc
    key: "location"
    hot: true
    icon: Sky.online ? sign(s("Art")) || "pin" : sign(s("OfflineArt")) || "pinOff"
    tip: !Sky.online ? t("No internet") : Sky.place + (Sky.region ? ", " + Sky.region : "")
    len: along(mark)

    Icon {
        id: mark
        anchors.centerIn: parent
        source: loc.icon
        family: loc.iconFont
        size: loc.unit * 0.5
        color: loc.ink
    }
}
