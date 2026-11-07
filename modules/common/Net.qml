pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The network of the machine, for the item of the bar and its popup. NetworkManager is the one that knows Wi-Fi, and it is not on every machine: when it is not
// there, the connection is the wired interface, which is read from the system, so that a machine with plain networking has an icon too
Singleton {
    id: net

    // the interface that the user chose in the `network` of the theme file, or none, which is the one of the default route
    readonly property string chosen: Theme.user.network?.interface ?? ""

    // what is read of the wired interface: { iface, state, carrier, speed, mac, address, gateway }
    property var wired: ({})
    readonly property bool hasWired: wired.iface !== undefined && wired.iface !== ""
    readonly property bool wiredUp: hasWired && wired.carrier === "1" && wired.state !== "down"

    // there is a network to show
    readonly property bool present: hasWired
    // connected, and by what: wired for now
    readonly property bool connected: wiredUp
    readonly property string kind: "wired"
    // the way it is said: "Connected", "Not connected"
    readonly property string status: connected ? "Connected" : "Not connected"

    // "1 Gb/s", "100 Mb/s", or nothing when the interface does not say: a virtual one reports -1
    function speedText(): string {
        const mbit = parseInt(wired.speed ?? "");
        if (!isFinite(mbit) || mbit <= 0)
            return "";
        return mbit >= 1000 ? (mbit / 1000) + " Gb/s" : mbit + " Mb/s";
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
    onChosenChanged: refresh()

    Process {
        id: reader
        command: ["sh", Quickshell.shellPath("modules/common/net-wired.sh"), net.chosen]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        out[line.substring(0, i)] = line.substring(i + 1);
                }
                net.wired = out;
            }
        }
    }
}
