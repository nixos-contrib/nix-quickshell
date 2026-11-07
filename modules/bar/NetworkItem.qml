import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

// The network in the bar: a cable that is connected or crossed, in a slot like the sound and the battery. A click opens its details. It is not there when
// the machine has no network device at all
Rectangle {
    id: item
    property Popover popover
    signal toggled(real x)

    visible: Net.present
    Layout.preferredWidth: Theme.statusIcon + Theme.tilePad * 2
    Layout.preferredHeight: Theme.slot
    radius: Theme.radiusSm
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    NetworkIcon {
        anchors.centerIn: parent
        kind: Net.kind
        crossed: !Net.connected
        color: Net.connected ? Theme.barText : Theme.barMuted
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: item.toggled(item.mapToItem(null, 0, 0).x)
    }
}
