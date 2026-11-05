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
                // The logo is an item like the others, as the Apple of the menu bar: the same size, and it fills while it is pressed.
                // It opens the launcher, until the shell has its own
                Rectangle {
                    Layout.preferredWidth: Theme.slot
                    Layout.preferredHeight: Theme.slot
                    radius: Theme.tileRadius
                    color: logoArea.pressed ? Theme.barFocus : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Image {
                        anchors.centerIn: parent
                        source: Qt.resolvedUrl("../../assets/nix-snowflake.svg")
                        sourceSize: Qt.size(Theme.statusIcon * 2, Theme.statusIcon * 2)
                        width: Theme.statusIcon
                        height: Theme.statusIcon
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        id: logoArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
                    }
                }
                Workspaces {}
            }

            Item { Layout.fillWidth: true }

            // The status area: the icons of the tray, the bell and the clock, every one in a slot and the same space between
            // them, as the menu bar of macOS has its items. The bell has the count of the history, a slash when do not
            // disturb is on, a click opens the history and the right button toggles do not disturb
            RowLayout {
                spacing: Theme.spaceSm

                Tray {
                    openItem: trayMenu.visible ? trayMenu.item : null
                    onMenuRequested: (item, x) => trayMenu.openFor(item, x)
                }

                Rectangle {
                    Layout.preferredHeight: Theme.slot
                    Layout.preferredWidth: Math.max(Theme.slot, bell.implicitWidth + Theme.spaceSm)
                    radius: Theme.tileRadius
                    color: bellArea.pressed || root.notifications.centerOpen ? Theme.barFocus : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: bell
                        anchors.centerIn: parent
                        spacing: Theme.spaceXs + 2
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.notifications.dnd ? "\uf1f6" : "\uf0f3"
                            color: root.notifications.dnd ? Theme.barMuted : Theme.barText
                            font { family: Theme.iconFont; pixelSize: Theme.statusIcon }
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
                        id: bellArea
                        anchors.fill: parent
                        hoverEnabled: true
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
