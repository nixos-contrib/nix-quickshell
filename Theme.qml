pragma Singleton
import QtQuick
import Quickshell

// The design system of the shell: every color, size and space comes from here, and nothing else has a number of its own.
// The base is black, the black of the menu bar of macOS above the screen, so that the two read as one band. Every surface is
// a step up from it, and the blues of nixos.org are only for what is active or can be pressed
Singleton {
    // Color: the base, three steps of surface, the text, and the accents
    readonly property color base: "#000000"
    readonly property color bg: "#0b0d10"
    readonly property color surface: "#14171c"
    readonly property color surfaceHigh: "#222730"
    // the edge of a card: a hairline of white, so that it is the same on any surface and any wallpaper
    readonly property color border: Qt.rgba(1, 1, 1, 0.10)
    readonly property color text: "#e8eef5"
    readonly property color muted: "#8b95a3"
    readonly property color primary: "#7ebae4"
    readonly property color accent: "#5277c3"
    readonly property color success: "#6fc488"
    readonly property color critical: "#e5616f"
    readonly property color warning: "#e9b45b"

    // Type: SF Pro Text, and the sizes of the roles. The bar and the cards have their own, the bar is read from further
    readonly property string font: "SF Pro Text"
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
    readonly property int radiusLg: 16
    readonly property int radiusMd: Math.round(radiusLg * 0.625)
    readonly property int radiusSm: Math.round(radiusLg * 0.375)
    readonly property int panelPadding: 16
    readonly property int popupWidth: 320
    // the track of a slider and of a meter: the same height, and the same colors
    readonly property int trackHeight: 6
    // The room between the edge of the screen and the bar, the toasts, the history and the menus: what lines them up
    readonly property int edge: 20
    // The room under the bar before the first card
    readonly property int gap: 12

    // The bar
    readonly property color barBg: base
    readonly property color barText: text
    readonly property color barMuted: "#a8a8ac"
    readonly property color barFocus: surfaceHigh
    // the text on the filled tile of the focused workspace, and on the red of an urgent one
    readonly property color onFill: "#ffffff"
    // Every item of the bar sits in a slot of the same size, centered: the workspaces, the icons of the tray, the bell. The
    // bar has the same room above and below the slot
    readonly property int slot: 24
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
