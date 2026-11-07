import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.modules.common

// The battery in the bar: a battery drawn to its charge, with the percentage, and a bolt when it charges. It is only there when there
// is a battery. A click opens the details
Rectangle {
    id: item
    property Popover popover
    signal toggled(real x)

    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isPresent
    // Quickshell gives the charge as a fraction, 0 to 1
    readonly property real level: present ? Math.max(0, Math.min(100, device.percentage * 100)) : 0
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    readonly property bool low: present && !charging && level <= 15

    visible: present
    Layout.preferredWidth: row.implicitWidth + Theme.tilePad * 2 - Theme.textBearing
    Layout.preferredHeight: Theme.slot
    radius: Theme.radiusSm
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    Row {
        id: row
        x: Theme.tilePad
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceXs + 2

        BatteryIcon {
            anchors.verticalCenter: parent.verticalCenter
            level: item.level
            charging: item.charging
            low: item.low
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(item.level) + "%"
            color: item.low ? Theme.critical : Theme.barText
            font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Normal }
        }
        Text {
            visible: item.charging
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf0e7"
            color: Theme.success
            font { family: Theme.iconFont; pixelSize: Theme.fontBar }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: item.toggled(item.mapToItem(null, 0, 0).x)
    }
}
