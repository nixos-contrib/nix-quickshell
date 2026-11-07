import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQml.Models
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// The icons of the apps that live in the tray, the ones that talk StatusNotifierItem: Discord and 1Password, among them.
// A click does what the app does, the right button shows its menu
RowLayout {
    id: tray
    spacing: Theme.statusGap
    // the item whose menu is open: its tile is filled, as long as the menu is
    property var openItem: null
    // the right button, or the left one for the apps that only have a menu: the item and where its icon is in the bar
    signal menuRequested(var item, real x)

    // The apps are in the order of their names and not of the order they started in, which changes from one login to the next. A
    // ScriptModel keeps the icon of an app when the list changes
    Repeater {
        model: ScriptModel {
            values: SystemTray.items.values.slice().sort((a, b) => (a.title || a.id).toLowerCase().localeCompare((b.title || b.id).toLowerCase()))
        }
        delegate: Rectangle {
            id: slot
            required property SystemTrayItem modelData

            Layout.preferredWidth: Theme.statusIcon + Theme.tilePad * 2
            Layout.preferredHeight: Theme.slot
            visible: modelData.status !== Status.Passive
            radius: Theme.radiusSm
            color: area.pressed || tray.openItem === slot.modelData ? Theme.barFocus : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.motionFast } }

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
