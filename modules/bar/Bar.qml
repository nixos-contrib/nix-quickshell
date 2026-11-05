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
    // the launcher, which the logo opens
    required property var launcher
    property bool shown: true

    IpcHandler {
        target: "bar"
        function toggle(): void { root.shown = !root.shown; }
    }

    TrayMenu { id: trayMenu }
    AudioPopup { id: audioPopup }
    BatteryPopup { id: batteryPopup }

    // One popup at a time, the history of the notifications among them: the others close when one opens, and a click on the item
    // of the one that is open closes it
    function closePopups() {
        trayMenu.visible = false;
        audioPopup.visible = false;
        batteryPopup.visible = false;
        notifications.closeCenter();
    }
    function toggle(popup, x) {
        const wasOpen = popup.visible;
        closePopups();
        if (!wasOpen)
            popup.openAt(x);
    }

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
                // It opens the launcher
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
                        onClicked: root.launcher.show("apps")
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
                    onMenuRequested: (item, x) => {
                        root.closePopups();
                        trayMenu.openFor(item, x);
                    }
                }

                AudioItem {
                    popover: audioPopup
                    onToggled: x => root.toggle(audioPopup, x)
                }

                BatteryItem {
                    popover: batteryPopup
                    onToggled: x => root.toggle(batteryPopup, x)
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
                            text: root.notifications.dnd ? "\udb80\udc9b" : "\udb80\udc9a"
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
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                root.notifications.toggleDnd();
                            } else {
                                // the center is one of the popups: the others close, and a click on the bell closes it when it is open
                                const wasOpen = root.notifications.centerOpen;
                                root.closePopups();
                                if (!wasOpen)
                                    root.notifications.toggleCenter();
                            }
                        }
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
