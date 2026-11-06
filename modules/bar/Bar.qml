import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs
import qs.modules.notifications

// The bar of the screen, as the menu bar of macOS has it: the logo and the workspaces at the left, the tray, the bell and the
// clock at the right. It is a dock, so i3 gives the windows the room under it. Two groups at each side, close inside and far
// from each other
Scope {
    id: root
    required property Notifications notifications
    // A key that is held a moment repeats, and the command it runs comes again and again, 25 ms apart: these commands toggle, so
    // the repeat would close what the first opened. Only the first of a burst counts, the ones that follow it within 400 ms are
    // the same press
    property double lastIpc: 0
    function fresh(): bool {
        const now = Date.now();
        const first = now - root.lastIpc > 400;
        root.lastIpc = now;
        return first;
    }

    // the launcher, which the logo opens
    required property var launcher
    // the tabs of the containers, for the group of a workspace, see Workspaces
    property var tabs: null
    property bool shown: true

    IpcHandler {
        target: "bar"
        function toggle(): void { if (root.fresh()) root.shown = !root.shown; }
        // the popups of the bar, from the outside: a key, or a test. They hang from the right end of the bar
        function audio(): void { if (root.fresh()) root.toggle(audioPopup, bar.width - 480); }
        function battery(): void { if (root.fresh()) root.toggle(batteryPopup, bar.width - 400); }
        function tray(): void {
            const items = SystemTray.items.values;
            if (items.length === 0 || !root.fresh())
                return;
            root.closePopups();
            trayMenu.openFor(items[0], bar.width - 520);
        }
    }

    TrayMenu { id: trayMenu }
    Binding {
        target: root.notifications
        property: "popupOpen"
        value: trayMenu.visible || audioPopup.visible || batteryPopup.visible
    }
    AudioPopup { id: audioPopup }
    BatteryPopup { id: batteryPopup }

    // One popup at a time, the history of the notifications among them: the others close when one opens, and a click on the item
    // of the one that is open closes it
    // the bar is shown again, for i3 to take it as a dock again
    function remap() {
        if (!root.shown)
            return;
        root.shown = false;
        remapTimer.restart();
    }
    Timer { id: remapTimer; interval: 300; onTriggered: root.shown = true }
    function closePopups() {
        if (root.tabs)
            root.tabs.closeList();
        trayMenu.visible = false;
        audioPopup.visible = false;
        batteryPopup.visible = false;
        notifications.closeCenter();
    }
    // the history of the notifications, from the bell and from the clock, as the clock opens it in macOS and in Windows 11
    // the key of the list of tabs: it hangs from the chevron of the group
    Connections {
        target: root.tabs
        function onListKeyRequested(group) {
            root.closePopups();
            workspaces.openListFor(group);
        }
    }
    // the workspace changes, from a click on its number or from a key: the popups are on every workspace, and have no business on the new one
    Connections {
        target: I3
        function onFocusedWorkspaceChanged() { root.closePopups(); }
    }
    function toggleHistory() {
        const wasOpen = notifications.centerOpen;
        closePopups();
        if (!wasOpen)
            notifications.toggleCenter();
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

        // a click on the bar where no item is closes the popups, as a click anywhere else
        MouseArea {
            anchors.fill: parent
            onPressed: root.closePopups()
        }

        RowLayout {
            anchors { fill: parent; leftMargin: Theme.edge; rightMargin: Theme.edge }
            spacing: 0

            // The logomark of NixOS, as the one of Apple in the menu bar, and the workspaces. It opens the launcher
            RowLayout {
                spacing: Theme.spaceSm
                // The official flat logomark, white on the dark bar and black on the light one, as the branding guide has them: not painted in
                // any other color. It has no fill behind it, which would cut its clear space, and it dims while it is pressed
                Item {
                    Layout.preferredWidth: logo.width + Theme.logoClear * 2
                    Layout.preferredHeight: Theme.slot
                    Image {
                        id: logo
                        anchors.centerIn: parent
                        source: Qt.resolvedUrl(Theme.dark ? "../../assets/nixos-logomark-white-flat.svg" : "../../assets/nixos-logomark-black-flat.svg")
                        // the drawing is 2304 x 1995 and is kept in that proportion
                        sourceSize: Qt.size(Theme.logoHeight * 2 * 2304 / 1995, Theme.logoHeight * 2)
                        width: Math.round(Theme.logoHeight * 2304 / 1995)
                        height: Theme.logoHeight
                        fillMode: Image.PreserveAspectFit
                        opacity: logoArea.pressed ? 0.6 : (logoArea.containsMouse ? 0.85 : 1)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: logoArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launcher.show("apps")
                    }
                }
                Workspaces {
                    id: workspaces
                    tabs: root.tabs
                    onMenuRequested: (group, tab, x, y) => {
                        root.closePopups();
                        root.tabs.openMenuAt(group, tab, x, y);
                    }
                    onListRequested: (container, x, y) => {
                        root.closePopups();
                        root.tabs.openListAt(container, x, y);
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // The status area: the icons of the tray, the bell and the clock, every one in a slot and the same space between
            // them, as the menu bar of macOS has its items. The bell has the count of the history, a slash when do not
            // disturb is on, a click opens the history and the right button toggles do not disturb
            RowLayout {
                spacing: Theme.statusGap

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
                    Layout.preferredWidth: bell.implicitWidth + Theme.tilePad * 2 - Theme.textBearing
                    radius: Theme.radiusSm
                    color: bellArea.pressed || root.notifications.centerOpen ? Theme.barFocus : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: bell
                        x: Theme.tilePad
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spaceXs + 2
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.notifications.dnd ? "\udb80\udc9b" : "\udb80\udc9a"
                            color: root.notifications.dnd ? Theme.barMuted : Theme.barText
                            font { family: Theme.iconFont; pixelSize: Theme.statusIcon }
                        }
                    }
                    // something came since the history was last opened: a dot at the corner of the bell, with a ring of the color of the bar
                    Rectangle {
                        visible: root.notifications.hasNew
                        x: bell.x + bell.width - width + 3
                        y: bell.y + 1
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.primary
                        border { width: 2; color: Theme.barBg }
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
                                root.toggleHistory();
                            }
                        }
                    }
                }

                // the clock: a tile like the others, which opens the history too
                Rectangle {
                    Layout.preferredHeight: Theme.slot
                    Layout.preferredWidth: clock.implicitWidth + Theme.tilePad * 2 - Theme.textBearing
                    radius: Theme.radiusSm
                    color: clockArea.pressed || root.notifications.centerOpen ? Theme.barFocus : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        id: clock
                        x: Theme.tilePad - Theme.textBearing
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(Clock.date, "ddd d MMM HH:mm")
                        color: Theme.barText
                        font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Medium }
                    }
                    MouseArea {
                        id: clockArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleHistory()
                    }
                }
            }
        }
    }
}
