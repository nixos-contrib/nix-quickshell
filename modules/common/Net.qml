pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs

// The network of the machine, for the item of the bar and its popup. NetworkManager is the one that knows Wi-Fi, and it is not on every machine. When it is
// there its devices are the network: a cable, or a Wi-Fi with its networks. When it is not, the connection is the wired interface, read from the system, so
// that a machine with plain networking has an icon too
Singleton {
    id: net

    // ---- NetworkManager
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool nm: devices.length > 0
    // the radio: off by the software, or blocked by a switch of the hardware, which is what the key of the airplane mode is
    readonly property bool wifiRadio: Networking.wifiEnabled
    readonly property bool airplane: wifiDevice !== null && !Networking.wifiHardwareEnabled
    // what the Wi-Fi sees: the one that is connected first, then the ones that the machine knows, then by strength
    readonly property var networks: wifiDevice ? wifiDevice.networks.values.slice().sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)) : []
    readonly property var connectedNetwork: networks.find(n => n.connected) ?? null

    // ---- the wired interface, when NetworkManager is not there
    // the interface that the user chose in the `network` of the theme file, or none, which is the one of the default route
    readonly property string chosen: Theme.user.network?.interface ?? ""
    // what is read of an interface: { iface, state, carrier, speed, mac, address, gateway }
    property var info: ({})
    readonly property bool hasWired: info.iface !== undefined && info.iface !== ""
    readonly property bool wiredUp: hasWired && info.carrier === "1" && info.state !== "down"

    // ---- what the item says
    // there is a network to show
    readonly property bool present: nm || hasWired
    readonly property bool connected: nm ? ((wiredDevice !== null && wiredDevice.connected) || connectedNetwork !== null) : wiredUp
    // wired, wifi or airplane: a cable that is connected is the connection before anything else, as NetworkManager prefers it, and the airplane mode
    // is only what the machine is in when it has no cable to say otherwise
    readonly property string kind: {
        if (!nm)
            return "wired";
        if (wiredDevice !== null && wiredDevice.connected)
            return "wired";
        if (airplane)
            return "airplane";
        if (wifiDevice !== null)
            return "wifi";
        return "wired";
    }
    // the waves of a Wi-Fi: the ones of the strength of the network that is connected, and all of them, crossed, when it is not connected
    readonly property int level: kind === "wifi" ? (connectedNetwork !== null ? levelOf(connectedNetwork.signalStrength) : 3) : 0
    // the Wi-Fi is on and not connected, or it is off: the icon is crossed
    readonly property bool crossed: kind === "airplane" ? false : (kind === "wifi" ? (connectedNetwork === null || !wifiRadio) : !connected)
    // the way it is said
    readonly property string status: {
        if (airplane)
            return "Airplane mode";
        if (kind === "wifi" && !wifiRadio)
            return "Wi-Fi is off";
        if (connected)
            return kind === "wifi" && connectedNetwork ? connectedNetwork.name : "Connected";
        return "Not connected";
    }
    // the interface that the details are of
    readonly property string watch: nm ? (kind === "wifi" ? (wifiDevice?.name ?? "") : (wiredDevice?.name ?? "")) : chosen

    function levelOf(strength: real): int {
        return strength >= 0.66 ? 3 : (strength >= 0.33 ? 2 : (strength >= 0.1 ? 1 : 0));
    }
    // a network that asks for a key and is not known yet: it needs the password, and an open one does not
    function needsKey(network: var): bool {
        return !network.known && network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }
    // a network that asks for a login of an organization: the shell has no field for it
    function enterprise(network: var): bool {
        return network.security === WifiSecurityType.WpaEap || network.security === WifiSecurityType.Wpa2Eap || network.security === WifiSecurityType.Wpa3SuiteB192 || network.security === WifiSecurityType.Leap;
    }
    // "1 Gb/s", "100 Mb/s", or nothing when the interface does not say: a virtual one reports -1
    function speedText(): string {
        const mbit = parseInt(info.speed ?? "");
        if (!isFinite(mbit) || mbit <= 0)
            return "";
        return mbit >= 1000 ? (mbit / 1000) + " Gb/s" : mbit + " Mb/s";
    }
    function failureText(reason: var): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Wrong password";
        case ConnectionFailReason.WifiAuthTimeout:
            return "No answer from the network";
        case ConnectionFailReason.WifiNetworkLost:
            return "The network is gone";
        default:
            return "Could not connect";
        }
    }
    function toggleWifi(): void {
        if (wifiDevice !== null && !airplane)
            Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: net.refresh()
    }
    onWatchChanged: refresh()

    Process {
        id: reader
        command: ["sh", Quickshell.shellPath("modules/common/net-wired.sh"), net.watch]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        out[line.substring(0, i)] = line.substring(i + 1);
                }
                net.info = out;
            }
        }
    }
}
