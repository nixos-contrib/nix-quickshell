pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The design system of the shell: every color, size and space comes from here, and nothing else has a number of its own.
// The base is the color of the windows in both modes (white, and the navy that is nearly black). The bar is the base on dark, so that it is
// not an element of its own, and on light it is a blue, a header over the white windows. The cards are a step up from the windows, and the blues of nixos.org are only for what is active or can be
// pressed
Singleton {
    // The theme is data. A flavour of the package, flavours/<name>.json, has the roles of a dark and of a light palette: nixos-navy is the
    // default, the dark blues of nixos.org and its white, and nixos-graphite is the same with greys. The file of the user is over it,
    // ~/.config/nix-quickshell/theme.json or the one of NSHELL_THEME: the flavour, the font, the radius, the hours of auto, and the roles
    // of a palette to change. Both are read when the shell starts and again when they change
    readonly property string userPath: Quickshell.env("NSHELL_THEME") || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/nix-quickshell/theme.json"
    function readJson(view: var): var {
        try {
            const text = view.text();
            return text ? JSON.parse(text) : {};
        } catch (err) {
            console.log("theme: could not read", view.path, err);
            return {};
        }
    }
    property var user: readJson(userFile)
    property var flavour: readJson(flavourFile)
    FileView {
        id: userFile
        path: Theme.userPath
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Theme.user = Theme.readJson(userFile)
        onLoadFailed: Theme.user = {}
    }
    FileView {
        id: flavourFile
        path: Quickshell.shellPath("flavours/" + (Theme.user.flavour || "nixos-navy") + ".json")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Theme.flavour = Theme.readJson(flavourFile)
    }

    // The mode, dark or light, set by Appearance: the colors below follow it, live
    property string mode: "dark"
    readonly property bool dark: mode !== "light"

    // Color: the base (the bar, the color of the windows), three steps of surface, the edge, the text, and the accents. textOnPrimary is the text on a fill of
    // primary, and textOnAccent the text on a fill of accent, as a pressed button. Not named on...: QML reads that as a signal handler
    readonly property var palette: Object.assign({}, flavour[dark ? "dark" : "light"] || {}, user[dark ? "dark" : "light"] || {})

    readonly property color base: palette.base
    readonly property color bg: palette.bg
    readonly property color surface: palette.surface
    readonly property color surfaceHigh: palette.surfaceHigh
    // the edge of a card: a hairline of white on dark and of black on light, so that it is the same on any surface and any wallpaper
    readonly property color border: palette.border
    readonly property color text: palette.text
    readonly property color muted: palette.muted
    readonly property color primary: palette.primary
    readonly property color accent: palette.accent
    readonly property color textOnPrimary: palette.textOnPrimary
    readonly property color success: palette.success
    readonly property color critical: palette.critical
    readonly property color warning: palette.warning

    // Type: Route 159, the typeface of NixOS, unless the theme names another (Inter is the fallback for what it has not: fontconfig, see the module), and the sizes of the roles. The bar and the cards have their own, the bar is read from further
    readonly property string font: user.font || flavour.font || "Route 159"
    readonly property string iconFont: "JetBrainsMono Nerd Font Mono"
    readonly property int fontSmall: 10
    readonly property int fontBody: 12
    readonly property int fontTitle: 13
    readonly property int fontBar: 14
    // the title of a dialog, as the polkit card
    readonly property int fontHeading: 17
    readonly property int iconBar: 18

    // The five roles of text. Everything that is read in a window of the shell has one of them, through the Label component, and
    // nothing has a size of its own: a heading (the search field, the title of a dialog), a title (the header of a panel), the body
    // (rows, descriptions), a caption (a value, a subtitle, a hint) and a label (a section, the name of the app of a card)
    readonly property int textHeading: 17
    readonly property int textTitle: 14
    readonly property int textBody: 13
    readonly property int textCaption: 12
    readonly property int textLabel: 10

    // Space: a scale on a grid of 4. Items of a group are an xs to a md apart, and groups are lg to xl apart, so that the
    // eye reads the groups by their distance
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 24

    // Shape. Three radii from one, the inside smaller than the outside so that the corners nest: sm for the tiles of the bar, the
    // chips and the tracks, md for the rows, the buttons and the cards inside a panel, lg for what floats: the panels, the
    // popups, the toasts, the launcher, the polkit card and the OSD. A theme changes the one, and the others follow
    readonly property int spacing: 10
    readonly property int radiusLg: user.radius ?? flavour.radius ?? 16
    readonly property int radiusMd: Math.round(radiusLg * 0.625)
    readonly property int radiusSm: Math.round(radiusLg * 0.375)
    readonly property int panelPadding: 16
    readonly property int popupWidth: 320
    // the track of a slider and of a meter: the same height, and the same colors
    readonly property int trackHeight: 6
    // Elevation: the shadow of what floats, soft and a little below its card. A window of the shell is a transparent window with the
    // card in it, so the shadow is drawn in the window, and the window is bigger than the card by the margin of the elevation: the
    // blur and the offset, and a little more. Level 1 is for what hangs from the bar, 2 for what comes to the middle
    readonly property color shadow: palette.shadow
    readonly property int blurLow: 24
    readonly property int offsetLow: 6
    readonly property int blurHigh: 48
    readonly property int offsetHigh: 14
    readonly property int marginLow: 32
    readonly property int marginHigh: 64
    // The room between the edge of the screen and the bar, the toasts, the history and the menus: what lines them up
    readonly property int edge: 20
    // The room under the bar before the first card
    readonly property int gap: 12

    // The bar has roles of its own: on dark it is the base, as the windows, and on light it is a blue (a grey in graphite) with white text, a
    // header over the white windows. The focus is the tile of the focused workspace and of an open menu, and the logomark is white on a dark bar
    readonly property color barBg: palette.barBg
    readonly property color barText: palette.barText
    readonly property color barMuted: palette.barMuted
    readonly property color barFocus: palette.barFocus
    readonly property bool barDark: barBg.hslLightness < 0.5
    // the text on the filled tile of the focused workspace, and on the red of an urgent one
    readonly property color textOnAccent: palette.textOnAccent
    // Every item of the bar sits in a slot of the same size, centered: the workspaces, the icons of the tray, the bell. The
    // bar has the same room above and below the slot
    readonly property int slot: 24
    // The logomark of NixOS in the bar: 18 points high, which is 36 pixels on a screen of twice the pixels, over the 24 that the branding guide
    // has as the least for a screen. It is a solid, wide shape, which reads larger than the thin icons of the bar at the same height. A quarter of its height is free around it, the least
    // that the guide asks for, see assets/
    readonly property int logoHeight: 18
    readonly property int logoClear: 5
    readonly property int barHeight: 40
    readonly property int tile: slot
    // The tiles of the status area, the tray, the sound, the battery, the bell and the clock, have the same room inside, on each
    // side of what they hold, and the same gap between them: so the space between what is shown is the same all along. With a room
    // of its own for each the gaps grew from one item to the next
    readonly property int tilePad: 4
    readonly property int statusGap: 4
    // a piece of text has a little room of its own at its edges, so a tile of text is that much further from the next than a tile of
    // an icon: its padding is smaller on the side where the text ends or starts
    readonly property int textBearing: 1
    // The corner of a tile of the bar, radiusSm, is the same for the workspaces, the tray, the bell and the logo, and for the filled tile
    // of an item that is pressed or whose menu is open. The bar has no highlight for the pointer over an item, as the menu bar of macOS
    // The icons of the status area, the tray and the bell alike, have one size in their slot, as in the menu bar of macOS: no
    // item is bigger or further from the next for what it is
    readonly property int statusIcon: 20

    // The most toasts on the screen at once, the rest wait behind
    readonly property int toastLimit: 4
}
