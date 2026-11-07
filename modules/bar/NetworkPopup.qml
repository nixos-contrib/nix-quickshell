import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

// The network: what it is connected by. For the wired interface, its state, its address, the gateway and the speed of the cable
Popover {
    id: win
    heading: "Network"
    headerValue: Net.status

    // read again when it opens: the item is read every few seconds, and the details are looked at once
    onVisibleChanged: if (visible) Net.refresh()

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd
            Item {
                Layout.preferredWidth: Theme.slot
                Layout.preferredHeight: Theme.slot
                NetworkIcon {
                    anchors.centerIn: parent
                    kind: Net.kind
                    crossed: !Net.connected
                    color: Net.connected ? Theme.text : Theme.muted
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    strong: true
                    text: "Wired"
                }
                Label {
                    Layout.fillWidth: true
                    role: "caption"
                    text: Net.wired.iface ?? ""
                }
            }
        }

        Repeater {
            model: [
                { k: "Address", v: Net.wired.address ?? "" },
                { k: "Gateway", v: Net.wired.gateway ?? "" },
                { k: "Speed", v: Net.speedText() },
                { k: "Hardware address", v: Net.wired.mac ?? "" }
            ].filter(r => r.v !== "")
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.spaceMd
                Label { role: "caption"; text: modelData.k; Layout.preferredWidth: 110 }
                Label { text: modelData.v; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
        // a cable that is not connected says so, as there is nothing else to say
        Label {
            visible: !Net.connected
            Layout.fillWidth: true
            role: "caption"
            wrapMode: Text.Wrap
            text: "The cable is not connected, or the other end does not answer."
        }
    }
}
