import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs

// The details of the battery: the charge, what it is doing and how long it takes, and its health
Popover {
    id: win
    panelWidth: 300

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

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceXs
            Text {
                text: "Battery"
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontTitle + 1; weight: Font.DemiBold }
                Layout.fillWidth: true
            }
            Text {
                text: win.device ? Math.round(win.level) + "%" : ""
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontTitle + 1; weight: Font.DemiBold }
            }
        }

        // the charge, as a bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: 4
            color: Theme.surfaceHigh
            Rectangle {
                height: parent.height
                radius: 4
                width: parent.width * win.level / 100
                color: win.device && win.device.state === UPowerDeviceState.Charging ? Theme.success : (win.level <= 15 ? Theme.critical : Theme.primary)
            }
        }

        Text {
            Layout.fillWidth: true
            text: win.status()
            color: Theme.muted
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontBody + 1 }
        }
        Text {
            visible: win.device && win.device.healthSupported
            Layout.fillWidth: true
            text: win.device ? "Health " + Math.round(win.device.healthPercentage * 100) + "%" : ""
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontBody }
        }
        Item { Layout.preferredHeight: Theme.spaceXs }
    }
}
