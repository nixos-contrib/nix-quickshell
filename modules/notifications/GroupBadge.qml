import QtQuick
import qs

// The count of a group, in the header of the card that stands for it: a small pill with the number. While the pointer is over the card it says what
// a click on it does, Clear and the number, so that it is not taken for the close button of one notification
Rectangle {
    id: badge
    property int count: 0
    // the pointer is over the card, which says it
    property bool active: false
    // the pointer is over the badge, which has a hover area of its own: the card counts it as its own
    readonly property bool over: area.containsMouse
    signal clear

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 20
    radius: height / 2
    color: area.pressed ? Theme.accent : (badge.active ? Theme.bg : Theme.surfaceHigh)
    border { width: 1; color: badge.active ? Theme.border : "transparent" }
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: badge.active ? "Clear " + badge.count : badge.count
        color: area.pressed ? Theme.textOnAccent : (badge.active ? Theme.primary : Theme.muted)
        font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Normal }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: badge.active
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: badge.clear()
    }
}
