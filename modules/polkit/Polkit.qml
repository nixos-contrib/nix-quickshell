import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import qs
import qs.modules.common

// The agent of polkit of the session: the card that asks for the touch of the key, or for the password, when something needs to
// be authorized. 1Password unlocking with the system is the case it is made for: a key, a line, the app, and the status of the
// touch. Any other action gets its icon and its sentence. It is a window of its own, in the middle of the screen, and i3
// floats it by its title, see docs/i3.md
Scope {
    id: root
    readonly property var flow: agent.flow
    readonly property bool onePassword: flow !== null && flow.actionId.startsWith("com.1password.")

    PolkitAgent {
        id: agent
        onIsRegisteredChanged: console.log("polkit agent registered:", isRegistered)
    }

    FloatingWindow {
        id: win
        title: "polkit"
        visible: agent.isActive
        color: "transparent"
        implicitWidth: 440
        implicitHeight: 290

        Panel {
            id: card
            anchors.fill: parent
            padding: Theme.spaceXl
            fillBody: true
            focus: true
            Keys.onEscapePressed: if (root.flow) root.flow.cancelAuthenticationRequest()

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spaceLg

                Label {
                    Layout.fillWidth: true
                    role: "heading"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    text: root.flow ? root.flow.message : ""
                }

                // The key and the app with a line between them; any other action has only its icon
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spaceMd

                    Rectangle {
                        visible: root.onePassword
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: Theme.radiusMd
                        color: Theme.surface
                        border { width: 1; color: Theme.border }
                        Image {
                            anchors.centerIn: parent
                            source: Quickshell.iconPath("yubioath", "dialog-password")
                            sourceSize: Qt.size(72, 72)
                            width: 36
                            height: 36
                        }
                    }
                    Rectangle {
                        visible: root.onePassword
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 2
                        radius: 1
                        color: Theme.border
                    }
                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: Theme.radiusMd
                        color: Theme.surface
                        border { width: 1; color: Theme.border }
                        Image {
                            anchors.centerIn: parent
                            source: Quickshell.iconPath(root.onePassword ? "1password" : (root.flow ? root.flow.iconName : ""), "dialog-password")
                            sourceSize: Qt.size(72, 72)
                            width: 36
                            height: 36
                        }
                    }
                }

                // The status of the touch, as PAM says it, or the field for the password when PAM asks for one
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Theme.radiusMd
                    color: Theme.surface
                    border { width: 1; color: root.flow && root.flow.supplementaryIsError ? Theme.critical : Theme.border }

                    Text {
                        anchors { fill: parent; margins: Theme.spaceMd }
                        visible: !(root.flow && root.flow.isResponseRequired)
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: root.flow && root.flow.supplementaryMessage !== "" ? root.flow.supplementaryMessage : (root.onePassword ? "Touch your YubiKey" : "Waiting for authentication")
                        color: root.flow && root.flow.supplementaryIsError ? Theme.critical : Theme.muted
                        font { family: Theme.font; pixelSize: Theme.textBody }
                    }

                    TextInput {
                        id: password
                        anchors { fill: parent; margins: Theme.spaceMd }
                        visible: root.flow ? root.flow.isResponseRequired : false
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.textBody }
                        onVisibleChanged: if (visible) forceActiveFocus()
                        onAccepted: {
                            root.flow.submit(text);
                            text = "";
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: password.text === ""
                            text: root.flow ? root.flow.inputPrompt : ""
                            color: Theme.muted
                            font: password.font
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Theme.spaceSm
                    PillButton {
                        text: "Cancel"
                        onClicked: if (root.flow) root.flow.cancelAuthenticationRequest()
                    }
                    PillButton {
                        visible: root.flow ? root.flow.isResponseRequired : false
                        active: true
                        text: "Authorize"
                        onClicked: password.accepted()
                    }
                }
            }
        }
    }
}
