pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// The Bluetooth of the machine, for the item of the bar and its popup: the adapter, its power, and the devices that BlueZ knows, the ones that are paired
// and the ones in range. Quickshell has no agent for the pairing, so a device that asks for a code, or for a confirmation, cannot be paired from here
Singleton {
    id: bt

    readonly property var adapter: Bluetooth.defaultAdapter
    // there is a controller: without one there is nothing to show
    readonly property bool present: adapter !== null
    readonly property bool on: present && adapter.enabled
    // switched off by something outside of the shell, a key or the rfkill of the airplane mode
    readonly property bool blocked: present && adapter.state === BluetoothAdapterState.Blocked
    readonly property var devices: adapter ? adapter.devices.values : []
        // the devices of the user: the one that is connected first, then the others by name
    readonly property var mine: devices.filter(d => d.paired || d.bonded).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var connectedDevices: on ? mine.filter(d => d.connected) : []
    readonly property bool connected: connectedDevices.length > 0
    // the ones in range that are not paired yet. A device that has only its address for a name is noise, and is left out
    readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && named(d)).sort((a, b) => a.name.localeCompare(b.name))
    // the way it is said
    readonly property string status: {
        if (blocked)
            return "Blocked";
        if (!on)
            return "Off";
        if (connected)
            return connectedDevices[0].name + (connectedDevices.length > 1 ? " +" + (connectedDevices.length - 1) : "");
        return "On";
    }

    // what went wrong with a device, by its address, to say it under its line
    property var failed: ({})
    // the devices that the user asked to pair: when one is paired, it is connected too, as the user means by a click
    property var asked: ({})

    function named(device: var): bool {
        return device.name !== "" && device.name.replace(/-/g, ":") !== device.address;
    }
    // "80%" for a device that says its battery, and nothing for the others
    function batteryText(device: var): string {
        return device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "";
    }
    function toggle(): void {
        if (present && !blocked)
            adapter.enabled = !adapter.enabled;
    }
    function fail(device: var, text: string): void {
        const f = Object.assign({}, bt.failed);
        f[device.address] = text;
        bt.failed = f;
    }
    function clear(device: var): void {
        const f = Object.assign({}, bt.failed);
        delete f[device.address];
        bt.failed = f;
    }
    // a click on a line: a device that is paired is connected, and one that is not is paired and then connected
    function activate(device: var): void {
        clear(device);
        if (device.paired || device.bonded) {
            device.connect();
        } else {
            const a = Object.assign({}, bt.asked);
            a[device.address] = true;
            bt.asked = a;
            device.pair();
        }
    }

    // the watch of each device: the end of a pairing or of a connection that did not happen
    Instantiator {
        model: bt.devices
        delegate: QtObject {
            id: watch
            required property var modelData
            readonly property bool paired: modelData.paired
            readonly property bool pairing: modelData.pairing
            readonly property int state: modelData.state
            property int last: modelData.state
            onPairedChanged: {
                if (paired && bt.asked[modelData.address]) {
                    const a = Object.assign({}, bt.asked);
                    delete a[modelData.address];
                    bt.asked = a;
                    modelData.connect();
                }
            }
            onPairingChanged: {
                if (!pairing && !paired && bt.asked[modelData.address]) {
                    const a = Object.assign({}, bt.asked);
                    delete a[modelData.address];
                    bt.asked = a;
                    bt.fail(modelData, "Could not pair. It may ask for a code that the shell cannot take.");
                }
            }
            onStateChanged: {
                if (last === BluetoothDeviceState.Connecting && state === BluetoothDeviceState.Disconnected && !modelData.connected)
                    bt.fail(modelData, "Could not connect");
                last = state;
            }
        }
    }
}
