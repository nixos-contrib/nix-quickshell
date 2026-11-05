import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs

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
    Layout.preferredWidth: Math.max(Theme.slot, row.implicitWidth + Theme.spaceSm)
    Layout.preferredHeight: Theme.slot
    radius: Theme.tileRadius
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spaceXs + 2

        // the battery: an outline with a nub, filled to the charge
        Item {
            width: 24
            height: 12
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 21
                height: parent.height
                radius: 3
                color: "transparent"
                border { width: 1.5; color: item.low ? Theme.critical : Theme.barText }
                opacity: 0.85
                Rectangle {
                    x: 2.5
                    y: 2.5
                    height: parent.height - 5
                    width: Math.max(2, (parent.width - 5) * item.level / 100)
                    radius: 1.5
                    color: item.low ? Theme.critical : (item.charging ? Theme.success : Theme.barText)
                }
            }
            Rectangle {
                x: 22
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 5
                radius: 1
                color: item.low ? Theme.critical : Theme.barText
                opacity: 0.85
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(item.level) + "%"
            color: item.low ? Theme.critical : Theme.barText
            font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Medium }
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
