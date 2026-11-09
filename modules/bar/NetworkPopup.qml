import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.modules.common

// The network: what the machine is connected by, and for a Wi-Fi the networks that it sees, to join. A network that is known is joined with a click, an open
// one too, and one that asks for a password has a field for it under its line. The wired interface, or the one of a Wi-Fi, says its address, its gateway
// and, for a cable, its speed. A value that is pasted somewhere else is copied by a click on its line
Popover {
    id: win
    heading: "Network"
    headerValue: Net.status

    // the line that is open under: its name, and the failure that it had
    property string selected: ""
    property var failed: ({})
    // the line that was copied, which says so for a moment
    property string copied: ""
    Timer {
        id: copiedTimer
        interval: 1500
        onTriggered: win.copied = ""
    }
    // the text goes to the clipboard with xclip, as the launcher puts a copy back. The address is copied without its prefix length:
    // what is pasted is for a command, `ssh` or `curl`, and the line still shows the prefix
    function copy(key: string, value: string): void {
        const text = key === "Address" ? value.replace(/\/\d+$/, "") : value;
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | xclip -selection clipboard -i', "sh", text]);
        win.copied = key;
        copiedTimer.restart();
    }

    // read again when it opens, and the Wi-Fi scans for as long as it is: the item is read every few seconds
    onVisibleChanged: {
        if (visible)
            Net.refresh();
        else {
            selected = "";
            copied = "";
        }
    }
    Binding {
        target: Net.wifiDevice
        property: "scannerEnabled"
        value: win.visible
        when: Net.wifiDevice !== null
    }

    function join(network: var): void {
        // the line opens, and says why when the shell cannot join it
        win.selected = network.name;
        const f = Object.assign({}, win.failed);
        delete f[network.name];
        win.failed = f;
        if (Net.enterprise(network) || Net.needsKey(network))
            return;
        network.connect();
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        // what it is connected by
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd
            Item {
                Layout.preferredWidth: Theme.slot
                Layout.preferredHeight: Theme.slot
                NetworkIcon {
                    anchors.centerIn: parent
                    kind: Net.kind
                    level: Net.level
                    crossed: Net.crossed
                    color: Net.connected ? Theme.text : Theme.muted
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    strong: true
                    elide: Text.ElideRight
                    text: Net.kind === "wifi" && Net.connectedNetwork ? Net.connectedNetwork.name : (Net.kind === "airplane" ? "Airplane mode" : (Net.kind === "wifi" ? "Wi-Fi" : "Wired"))
                }
                Label {
                    Layout.fillWidth: true
                    role: "caption"
                    text: Net.watch !== "" ? Net.watch : (Net.info.iface ?? "")
                }
            }
        }

        // the details of the interface, the ones that it has
        Repeater {
            model: [
                { k: "Address", v: Net.info.address ?? "", copy: true },
                { k: "Gateway", v: Net.info.gateway ?? "", copy: true },
                { k: "Speed", v: Net.kind === "wired" ? Net.speedText() : "", copy: false },
                { k: "Hardware address", v: Net.info.mac ?? "", copy: true }
            ].filter(r => r.v !== "")
            delegate: Rectangle {
                id: detail
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.spaceXl + Theme.spaceXs
                radius: Theme.radiusMd
                color: detailArea.containsMouse ? Theme.surfaceHigh : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                    spacing: Theme.spaceMd
                    Label { role: "caption"; text: detail.modelData.k; Layout.preferredWidth: 110 }
                    Label { text: detail.modelData.v; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label {
                        visible: win.copied === detail.modelData.k
                        role: "caption"
                        text: "Copied"
                        color: Theme.primary
                    }
                }
                MouseArea {
                    id: detailArea
                    anchors.fill: parent
                    enabled: detail.modelData.copy
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.copy(detail.modelData.k, detail.modelData.v)
                }
            }
        }
        Label {
            visible: !Net.nm && !Net.connected
            Layout.fillWidth: true
            role: "caption"
            wrapMode: Text.Wrap
            text: "The cable is not connected, or the other end does not answer."
        }

        // ---- the Wi-Fi
        RowLayout {
            visible: Net.wifiDevice !== null
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceXs
            Label { role: "label"; text: "Wi-Fi"; Layout.fillWidth: true }
            PillButton {
                text: Net.wifiRadio && !Net.airplane ? "On" : "Off"
                active: Net.wifiRadio && !Net.airplane
                enabled: !Net.airplane
                onClicked: Net.toggleWifi()
            }
        }
        Label {
            visible: Net.airplane
            Layout.fillWidth: true
            role: "caption"
            wrapMode: Text.Wrap
            text: "The radio is switched off by the hardware."
        }
        Label {
            visible: Net.wifiDevice !== null && Net.wifiRadio && !Net.airplane && Net.networks.length === 0
            Layout.fillWidth: true
            role: "caption"
            text: "Looking for networks…"
        }

        Repeater {
            model: Net.wifiRadio && !Net.airplane ? Net.networks.slice(0, 8) : []
            delegate: ColumnLayout {
                id: row
                required property var modelData
                readonly property bool open: win.selected === modelData.name
                readonly property bool secured: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Owe
                Layout.fillWidth: true
                spacing: 2

                Connections {
                    target: row.modelData
                    function onConnectionFailed(reason) {
                        const f = Object.assign({}, win.failed);
                        f[row.modelData.name] = Net.failureText(reason);
                        win.failed = f;
                        win.selected = row.modelData.name;
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: Theme.radiusMd
                    color: lineArea.containsMouse || row.open ? Theme.surfaceHigh : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                        spacing: Theme.spaceSm
                        NetworkIcon {
                            kind: "wifi"
                            level: Net.levelOf(row.modelData.signalStrength)
                            size: 16
                            color: Theme.text
                        }
                        Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: row.modelData.name
                        }
                        // a lock for a network that asks for a password
                        Text {
                            visible: row.secured
                            text: "\uf023"
                            color: Theme.muted
                            font { family: Theme.iconFont; pixelSize: Theme.iconBar - 4 }
                        }
                        Label {
                            role: "caption"
                            text: row.modelData.stateChanging ? "Connecting…" : (row.modelData.connected ? "Connected" : (row.modelData.known ? "Known" : ""))
                            color: row.modelData.connected ? Theme.primary : Theme.muted
                        }
                    }
                    MouseArea {
                        id: lineArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // the one that is connected opens its two things, and the others are joined
                            if (row.modelData.connected)
                                win.selected = row.open ? "" : row.modelData.name;
                            else
                                win.join(row.modelData);
                        }
                    }
                }

                // under a line that is open: the password of a network that asks for it, or what can be done with the one that is known
                ColumnLayout {
                    visible: row.open
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spaceSm
                    Layout.rightMargin: Theme.spaceSm
                    spacing: Theme.spaceSm

                    Label {
                        visible: Net.enterprise(row.modelData)
                        Layout.fillWidth: true
                        role: "caption"
                        wrapMode: Text.Wrap
                        text: "This network asks for a login that the shell cannot take."
                    }
                    // the password
                    Rectangle {
                        visible: Net.needsKey(row.modelData) && !Net.enterprise(row.modelData)
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: Theme.radiusMd
                        color: Theme.surface
                        border { width: 1; color: win.failed[row.modelData.name] ? Theme.critical : Theme.border }
                        TextInput {
                            id: key
                            anchors { fill: parent; margins: Theme.spaceSm }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.textBody }
                            onVisibleChanged: if (visible) forceActiveFocus()
                            onAccepted: {
                                row.modelData.connectWithPsk(text);
                                text = "";
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: key.text === ""
                                text: "Password"
                                color: Theme.muted
                                font: key.font
                            }
                        }
                    }
                    Label {
                        visible: win.failed[row.modelData.name] !== undefined
                        Layout.fillWidth: true
                        role: "caption"
                        color: Theme.critical
                        text: win.failed[row.modelData.name] ?? ""
                    }
                    RowLayout {
                        Layout.fillWidth: true
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
                            visible: row.modelData.known
                            text: "Forget"
                            onClicked: {
                                row.modelData.forget();
                                win.selected = "";
                            }
                        }
                        PillButton {
                            visible: Net.needsKey(row.modelData) && !Net.enterprise(row.modelData)
                            text: "Join"
                            active: true
                            onClicked: {
                                row.modelData.connectWithPsk(key.text);
                                key.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
