import QtQuick
import qs

// The small round button of the shell: Clear all, Show more, Do not disturb
Rectangle {
    id: button
    property string text
    property bool active: false
    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: height / 2
    color: area.pressed ? Theme.accent : (active ? Theme.primary : (area.containsMouse ? Theme.surfaceHigh : Theme.surface))
    border { width: 1; color: active ? Theme.primary : Theme.border }

    Text {
        id: label
        anchors.centerIn: parent
        text: button.text
        color: area.pressed ? Theme.onFill : (button.active ? Theme.onPrimary : Theme.primary)
        font { family: Theme.font; pixelSize: Theme.textCaption; weight: Font.Medium }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
