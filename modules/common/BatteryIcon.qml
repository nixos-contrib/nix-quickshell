import QtQuick
import qs

// The battery drawn to its charge: an outline with a nub, filled to level (0 to 100). Red when it is low, green while it charges
Item {
    id: icon
    property real level: 0
    property bool charging: false
    property bool low: false

    implicitWidth: 24
    implicitHeight: 12

    Rectangle {
        width: 21
        height: parent.height
        radius: 3
        color: "transparent"
        border { width: 1.5; color: icon.low ? Theme.critical : Theme.barText }
        opacity: 0.85
        Rectangle {
            x: 2.5
            y: 2.5
            height: parent.height - 5
            width: Math.max(2, (parent.width - 5) * icon.level / 100)
            radius: 1.5
            color: icon.low ? Theme.critical : (icon.charging ? Theme.success : Theme.barText)
        }
    }
    Rectangle {
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 5
        radius: 1
        color: icon.low ? Theme.critical : Theme.barText
        opacity: 0.85
    }
}
