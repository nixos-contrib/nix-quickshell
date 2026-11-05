import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.notifications

// The bar of the screen, as the menu bar of macOS has it: the logo and the workspaces at the left, the tray, the bell and the
// clock at the right. It is a dock, so i3 gives the windows the room under it. Two groups at each side, close inside and far
// from each other
Scope {
    id: root
    required property Notifications notifications
    property bool shown: true

    IpcHandler {
        target: "bar"
        function toggle(): void { root.shown = !root.shown; }
    }

    TrayMenu { id: trayMenu }

    PanelWindow {
        id: bar
        visible: root.shown
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        color: Theme.barBg

        RowLayout {
            anchors { fill: parent; leftMargin: Theme.edge; rightMargin: Theme.edge }
            spacing: 0

            // The logo of NixOS in its two blues, as the one of Apple in the menu bar, and the workspaces
            RowLayout {
                spacing: Theme.spaceLg
                Image {
                    source: Qt.resolvedUrl("../../assets/nix-snowflake.svg")
                    sourceSize: Qt.size(Theme.logo * 2, Theme.logo * 2)
                    Layout.preferredWidth: Theme.logo
                    Layout.preferredHeight: Theme.logo
                    fillMode: Image.PreserveAspectFit
                }
                Workspaces {}
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: Theme.spaceXl

                Tray { onMenuRequested: (item, x) => trayMenu.openFor(item, x) }

                // The status: the bell and the clock. The bell has the count of the history, a slash when do not disturb is on, a click
                // opens the history and the right button toggles do not disturb
                RowLayout {
                    spacing: Theme.spaceMd

                    Item {
                        Layout.preferredHeight: Theme.slot
                        Layout.preferredWidth: bell.implicitWidth
                        Row {
                            id: bell
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spaceXs + 2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.notifications.dnd ? "" : ""
                                color: root.notifications.dnd ? Theme.barMuted : Theme.barText
                                font { family: Theme.iconFont; pixelSize: Theme.iconStatus }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.notifications.unread > 0
                                text: root.notifications.unread
                                color: Theme.barText
                                font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Medium }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => mouse.button === Qt.RightButton ? root.notifications.toggleDnd() : root.notifications.toggleCenter()
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(Clock.date, "ddd d MMM HH:mm")
                        color: Theme.barText
                        font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Medium }
                    }
                }
            }
        }
    }
}
