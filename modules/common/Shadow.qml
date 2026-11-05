import QtQuick
import QtQuick.Effects
import qs

// The shadow of what floats, behind the card that it is a child of, in the same radius. elevation is 1 for what comes from the bar
// (popups, toasts) and 2 for what comes to the middle of the screen (launcher, polkit, OSD). The window of the card has to be
// bigger than the card by the margin of its elevation, or the shadow is cut at the edge of the window, see Theme.margin
RectangularShadow {
    property int elevation: 1

    z: -1
    anchors.fill: parent
    visible: elevation > 0
    radius: parent.radius
    blur: elevation > 1 ? Theme.blurHigh : Theme.blurLow
    offset.y: elevation > 1 ? Theme.offsetHigh : Theme.offsetLow
    color: Theme.shadow
}
