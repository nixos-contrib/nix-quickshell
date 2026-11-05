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
    readonly property color border: "#2a303a"
    readonly property color text: "#e8eef5"
    readonly property color muted: "#8b95a3"
    readonly property color primary: "#7ebae4"
    readonly property color accent: "#5277c3"
    readonly property color critical: "#e5616f"
    readonly property color warning: "#e9b45b"

    // Type: SF Pro Text, and the sizes of the roles. The bar and the cards have their own, the bar is read from further
    readonly property string font: "SF Pro Text"
    readonly property string iconFont: "JetBrainsMono Nerd Font Mono"
    readonly property int fontSmall: 10
    readonly property int fontBody: 12
    readonly property int fontTitle: 13
    readonly property int fontBar: 14
    readonly property int iconBar: 18

    // Space: a scale on a grid of 4. Items of a group are an xs to a md apart, and groups are lg to xl apart, so that the
    // eye reads the groups by their distance
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 24

    // Shape
    readonly property int spacing: 10
    readonly property int radius: 14
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
    // The corner of a tile of the bar, and of the filled tile of an item that is pressed or whose menu is open: the same for the
    // workspaces, the tray, the bell and the logo. The bar has no highlight for the pointer over an item, as the menu bar of macOS
    readonly property int tileRadius: 7
    // The icons of the status area, the tray and the bell alike, have one size in their slot, as in the menu bar of macOS: no
    // item is bigger or further from the next for what it is
    readonly property int statusIcon: 20

    // The most toasts on the screen at once, the rest wait behind
    readonly property int toastLimit: 4
}
