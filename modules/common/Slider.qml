import QtQuick
import qs

// A slider from 0 to 1: a track that fills with the blue, and a handle. It does not move the value itself, it says where the
// pointer is with moved(), and the one who owns the value sets it
Item {
    id: slider
    property real value: 0
    property bool enabled: true
    signal moved(real value)

    implicitHeight: 24
    implicitWidth: 200

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 6
        radius: 3
        color: Theme.surfaceHigh

        Rectangle {
            width: Math.max(0, Math.min(1, slider.value)) * parent.width
            height: parent.height
            radius: 3
            color: slider.enabled ? Theme.primary : Theme.muted
        }
    }
    Rectangle {
        width: 16
        height: 16
        radius: 8
        color: Theme.text
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(1, slider.value)) * (slider.width - width)
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(mouseX) { return Math.max(0, Math.min(1, (mouseX - 8) / (slider.width - 16))); }
        onPressed: mouse => slider.moved(at(mouse.x))
        onPositionChanged: mouse => { if (pressed) slider.moved(at(mouse.x)); }
    }
}
