import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// The icons of the apps that live in the tray, the ones that talk StatusNotifierItem: Discord and 1Password, among them.
// A click does what the app does, the right button shows its menu
RowLayout {
    id: tray
    spacing: Theme.spaceSm
    // the item whose menu is open: its tile is filled, as long as the menu is
    property var openItem: null
    // the right button, or the left one for the apps that only have a menu: the item and where its icon is in the bar
    signal menuRequested(var item, real x)

    Repeater {
        model: SystemTray.items
        delegate: Rectangle {
            id: slot
            required property SystemTrayItem modelData

            Layout.preferredWidth: Theme.slot
            Layout.preferredHeight: Theme.slot
            visible: modelData.status !== Status.Passive
            radius: Theme.tileRadius
            color: area.pressed || tray.openItem === slot.modelData ? Theme.barFocus : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.statusIcon
                source: slot.modelData.icon
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton)
                        slot.modelData.secondaryActivate();
                    else if (mouse.button === Qt.RightButton || slot.modelData.onlyMenu)
                        tray.menuRequested(slot.modelData, slot.mapToItem(null, 0, 0).x);
                    else
                        slot.modelData.activate();
                }
            }
        }
    }
}
