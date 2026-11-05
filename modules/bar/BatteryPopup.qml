import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.modules.common

// The details of the battery: the charge, what it is doing and how long it takes, and its health
Popover {
    id: win
    heading: "Battery"
    headerValue: device ? Math.round(level) + "%" : ""

    readonly property var device: UPower.displayDevice
    // the charge, 0 to 100: Quickshell gives a fraction
    readonly property real level: device ? Math.max(0, Math.min(100, device.percentage * 100)) : 0

    // "1 h 20 min", "45 min"
    function span(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        if (minutes < 1)
            return "less than a minute";
        const h = Math.floor(minutes / 60);
        const m = minutes % 60;
        return h > 0 ? h + " h " + (m > 0 ? m + " min" : "").trim() : m + " min";
    }

    function status(): string {
        if (!device)
            return "";
        switch (device.state) {
        case UPowerDeviceState.Charging:
            return device.timeToFull > 0 ? "Charging, " + span(device.timeToFull) + " until full" : "Charging";
        case UPowerDeviceState.Discharging:
            return device.timeToEmpty > 0 ? "On battery, " + span(device.timeToEmpty) + " left" : "On battery";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.Empty:
            return "Empty";
        case UPowerDeviceState.PendingCharge:
        case UPowerDeviceState.PendingDischarge:
            return "Not charging";
        default:
            return UPowerDeviceState.toString(device.state);
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        // the same row as the sound: the icon at the left, in a slot, and a track
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd
            Item {
                Layout.preferredWidth: Theme.slot
                Layout.preferredHeight: Theme.slot
                BatteryIcon {
                    anchors.centerIn: parent
                    level: win.level
                    charging: win.device !== null && win.device.state === UPowerDeviceState.Charging
                    low: win.level <= 15 && !(win.device !== null && win.device.state === UPowerDeviceState.Charging)
                }
            }
            Meter {
                Layout.fillWidth: true
                value: win.level / 100
                color: win.device && win.device.state === UPowerDeviceState.Charging ? Theme.success : (win.level <= 15 ? Theme.critical : Theme.primary)
            }
        }

        Label {
            Layout.fillWidth: true
            text: win.status()
            wrapMode: Text.Wrap
        }
        Label {
            visible: win.device && win.device.healthSupported
            Layout.fillWidth: true
            role: "caption"
            text: win.device ? "Health " + Math.round(win.device.healthPercentage * 100) + "%" : ""
        }
    }
}
