import QtQuick
import qs

// A value from 0 to 1 that is only shown: the track of the slider, in the same height and colors, without the handle, as
// there is nothing to move
Item {
    id: meter
    property real value: 0
    property color color: Theme.primary

    implicitHeight: 24
    implicitWidth: 200

    Rectangle {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: Theme.trackHeight
        radius: Theme.trackHeight / 2
        color: Theme.surfaceHigh

        Rectangle {
            width: Math.max(0, Math.min(1, meter.value)) * parent.width
            height: parent.height
            radius: Theme.trackHeight / 2
            color: meter.color
        }
    }
}
