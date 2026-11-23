import "../../../Backend"
import "../../../Data/Dynamic"

Twine {
    cfg: Config.values
    words: Config.words
    store: Config
    name: "catbar"
    onGroupsChanged: Config.claim(name, groups.filter(g => g.paged).map(g => g.id), panelBase)
}
