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
    spacing: Theme.spaceMd
    // the right button, or the left one for the apps that only have a menu: the item and where its icon is in the bar
    signal menuRequested(var item, real x)

    Repeater {
        model: SystemTray.items
        delegate: Item {
            id: slot
            required property SystemTrayItem modelData

            Layout.preferredWidth: Theme.trayIcon
            Layout.preferredHeight: Theme.trayIcon
            visible: modelData.status !== Status.Passive

            IconImage {
                anchors.fill: parent
                source: slot.modelData.icon
                opacity: area.containsMouse ? 1 : 0.9
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
