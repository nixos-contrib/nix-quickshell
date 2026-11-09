import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

// The card of the polkit agent: the key and the app with a line between them, the status of the touch or the field for the password, and
// the buttons. It is as tall as its content. flow is the request that is asked, the one of the agent, or a stand in with the same properties
// in the preview of the card
Panel {
    id: card
    property var flow: null
    readonly property bool onePassword: flow !== null && flow.actionId.startsWith("com.1password.")

    elevation: 2
    padding: Theme.spaceXl
    focus: true
    Keys.onEscapePressed: if (card.flow) card.flow.cancelAuthenticationRequest()

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceLg

        Label {
            Layout.fillWidth: true
            role: "heading"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            text: card.flow ? card.flow.message : ""
        }

        // The key and the app with a line between them; any other action has only its icon
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceMd

            Rectangle {
                visible: card.onePassword
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
                visible: card.onePassword
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
                    source: Quickshell.iconPath(card.onePassword ? "1password" : (card.flow ? card.flow.iconName : ""), "dialog-password")
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
            border { width: 1; color: card.flow && card.flow.supplementaryIsError ? Theme.critical : Theme.border }

            Text {
                anchors { fill: parent; margins: Theme.spaceMd }
                visible: !(card.flow && card.flow.isResponseRequired)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: card.flow && card.flow.supplementaryMessage !== "" ? card.flow.supplementaryMessage : (card.onePassword ? "Touch your YubiKey" : "Waiting for authentication")
                color: card.flow && card.flow.supplementaryIsError ? Theme.critical : Theme.muted
                font { family: Theme.font; pixelSize: Theme.textBody }
            }

            TextInput {
                id: password
                anchors { fill: parent; margins: Theme.spaceMd }
                visible: card.flow ? card.flow.isResponseRequired : false
                verticalAlignment: TextInput.AlignVCenter
                echoMode: card.flow && card.flow.responseVisible ? TextInput.Normal : TextInput.Password
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.textBody }
                onVisibleChanged: if (visible) forceActiveFocus()
                onAccepted: {
                    card.flow.submit(text);
                    text = "";
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text === ""
                    text: card.flow ? card.flow.inputPrompt : ""
                    color: Theme.muted
                    font: password.font
                }
            }
        }

        // the room between the status and the buttons: the card is as tall as its content, so no band is left empty
    Item { Layout.preferredHeight: Theme.spaceSm }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.spaceSm
            PillButton {
                text: "Cancel"
                onClicked: if (card.flow) card.flow.cancelAuthenticationRequest()
            }
            PillButton {
                visible: card.flow ? card.flow.isResponseRequired : false
                active: true
                text: "Authorize"
                onClicked: password.accepted()
            }
        }
    }
}
