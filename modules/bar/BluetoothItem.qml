import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

// The Bluetooth in the bar: the sign of the Bluetooth, with the bars at its sides when a device is connected and crossed when it is off, in a slot like the
// sound and the network. A click opens it, and the right button turns it off and on. It is not there when the machine has no adapter
Rectangle {
    id: item
    property Popover popover
    signal toggled(real x)

    visible: Bt.present
    Layout.preferredWidth: Theme.statusIcon + Theme.tilePad * 2
    Layout.preferredHeight: Theme.slot
    radius: Theme.radiusSm
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    BluetoothIcon {
        anchors.centerIn: parent
        connected: Bt.connected
        crossed: !Bt.on
        color: Bt.on ? Theme.barText : Theme.barMuted
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                item.toggled(item.mapToItem(null, 0, 0).x);
            else
                Bt.toggle();
        }
    }
}
