pragma Singleton
import QtQuick
import Quickshell

// The palette of nixos.org: the two blues of the logo on a dark slate. Everything draws from here
Singleton {
    readonly property color bg: "#10151c"
    readonly property color surface: "#1a212b"
    readonly property color surfaceHigh: "#242d3a"
    readonly property color border: "#2c3745"
    readonly property color text: "#e8eef5"
    readonly property color muted: "#8b99ab"
    readonly property color primary: "#7ebae4"
    readonly property color accent: "#5277c3"
    readonly property color critical: "#e5616f"
    readonly property color warning: "#e9b45b"

    readonly property string font: "SF Pro Text"
    readonly property int radius: 14
    // the most toasts on the screen at once, the rest wait behind
    readonly property int toastLimit: 4
    readonly property int spacing: 10
    readonly property int fontSmall: 10
    readonly property int fontBody: 12
    readonly property int fontTitle: 13
}
