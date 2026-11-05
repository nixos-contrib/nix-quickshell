import QtQuick
import qs

// The menu of an icon of the tray: its entries in the popup under the icon
Popover {
    id: win
    property var item: null
    padding: Theme.spaceSm

    function openFor(trayItem, x) {
        win.item = trayItem;
        win.openAt(x);
    }

    MenuList {
        width: parent.width
        menu: win.item ? win.item.menu : null
        onActivated: win.visible = false
    }
}
