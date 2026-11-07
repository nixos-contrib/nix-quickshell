import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.modules.common

// The Bluetooth: its power as a switch, the devices of the user and the ones in range. A click on a device that is paired connects it, and on one that is not
// pairs it and then connects it. The device that is connected opens its two things, Disconnect and Forget, and so does the right button on any of them
Popover {
    id: win
    heading: "Bluetooth"
    // the name of what is connected: that it is on is said by the switch
    headerValue: Bt.connected ? Bt.status : ""
    // the power is in the header: the switch of the adapter
    actions: PillButton {
        text: Bt.on ? "On" : "Off"
        active: Bt.on
        enabled: !Bt.blocked
        onClicked: Bt.toggle()
    }

    // the device that is open under its line: its address
    property string selected: ""

    onVisibleChanged: if (!visible) selected = ""
    // the adapter looks for devices for as long as the popup is open
    Binding {
        target: Bt.adapter
        property: "discovering"
        value: win.visible
        when: Bt.on && win.visible
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        Label {
            visible: Bt.blocked
            Layout.fillWidth: true
            role: "caption"
            wrapMode: Text.Wrap
            text: "The adapter is switched off by the hardware."
        }

        Label { visible: Bt.on && Bt.mine.length > 0; role: "caption"; text: "My devices" }
        Repeater {
            model: Bt.on ? Bt.mine.slice(0, 8) : []
            delegate: DeviceRow {}
        }

        Label { visible: Bt.on; role: "caption"; text: "Nearby"; Layout.topMargin: Theme.spaceXs }
        Label {
            visible: Bt.on && Bt.nearby.length === 0
            Layout.fillWidth: true
            role: "caption"
            text: "Looking for devices…"
        }
        Repeater {
            model: Bt.on ? Bt.nearby.slice(0, 8) : []
            delegate: DeviceRow {}
        }
    }

    // a line of a device, and under it what can be done with it when it is open
    component DeviceRow: ColumnLayout {
        id: row
        required property var modelData
        readonly property bool open: win.selected === modelData.address
        readonly property bool mineNow: modelData.paired || modelData.bonded
        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.pairing
        // a battery is said while the device is connected: BlueZ keeps the last one for a while after
        readonly property string battery: modelData.connected ? Bt.batteryText(modelData) : ""
        Layout.fillWidth: true
        spacing: 2

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Theme.radiusMd
            color: lineArea.containsMouse || row.open ? Theme.surfaceHigh : "transparent"
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                spacing: Theme.spaceSm
                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: row.modelData.name
                }
                Label {
                    visible: row.battery !== ""
                    role: "caption"
                    text: row.battery
                }
                Label {
                    role: "caption"
                    text: row.busy ? (row.modelData.pairing ? "Pairing…" : "Connecting…") : (row.modelData.connected ? "Connected" : "")
                    color: row.modelData.connected ? Theme.primary : Theme.muted
                }
            }
            MouseArea {
                id: lineArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (row.busy)
                        return;
                    if (mouse.button === Qt.RightButton || row.modelData.connected) {
                        if (row.mineNow)
                            win.selected = row.open ? "" : row.modelData.address;
                    } else {
                        Bt.activate(row.modelData);
                    }
                }
            }
        }

        Label {
            visible: Bt.failed[row.modelData.address] !== undefined
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spaceSm
            Layout.rightMargin: Theme.spaceSm
            role: "caption"
            wrapMode: Text.Wrap
            color: Theme.critical
            text: Bt.failed[row.modelData.address] ?? ""
        }
        RowLayout {
            visible: row.open
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spaceSm
            Layout.rightMargin: Theme.spaceSm
            spacing: Theme.spaceSm
            Item { Layout.fillWidth: true }
            PillButton {
                visible: row.modelData.connected
                text: "Disconnect"
                onClicked: {
                    row.modelData.disconnect();
                    win.selected = "";
                }
            }
            PillButton {
                visible: !row.modelData.connected
                text: "Connect"
                active: true
                onClicked: {
                    Bt.activate(row.modelData);
                    win.selected = "";
                }
            }
            PillButton {
                text: "Forget"
                onClicked: {
                    row.modelData.forget();
                    win.selected = "";
                }
            }
        }
    }
}
