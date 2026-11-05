import QtQuick
import Quickshell
import Quickshell.I3
import qs

// The menu of an icon of the tray, under the icon, in the style of the shell. It closes with Escape, when it loses the focus
// (a click anywhere else) and when an entry is chosen
FloatingWindow {
    id: win
    property var item: null
    property real anchorX: 0

    function openFor(trayItem, x) {
        win.item = trayItem;
        win.anchorX = x;
        win.visible = true;
    }

    title: "nshell-menu"
    visible: false
    color: "transparent"
    implicitWidth: 300
    // As tall as it can be, like the toasts and the center: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    mask: Region { item: panel }

    function place() {
        const scale = win.devicePixelRatio;
        // the panel is 12 in from the window, and it hangs from the icon, kept inside the screen
        const x = Math.round((Math.min(win.anchorX, win.screen.width - Theme.edge - panel.width) - 12) * scale);
        const y = Math.round((Theme.barHeight - 8) * scale);
        I3.dispatch(`[title="^nshell-menu$"] move absolute position ${x}px ${y}px`);
    }
    onVisibleChanged: if (visible) placeTimer.restart()
    Timer {
        id: placeTimer
        interval: 80
        onTriggered: {
            win.place();
            panel.forceActiveFocus();
        }
    }

    Rectangle {
        id: panel
        x: 12
        y: 12
        width: 300 - 24
        height: Math.min(win.height - 24, list.implicitHeight + 16)
        radius: Theme.radius
        color: Theme.surface
        border { width: 1; color: Theme.border }
        focus: true
        Keys.onEscapePressed: win.visible = false
        onActiveFocusChanged: if (!activeFocus && win.visible && placeTimer.running === false) win.visible = false

        MenuList {
            id: list
            x: 8
            y: 8
            width: parent.width - 16
            menu: win.item ? win.item.menu : null
            onActivated: win.visible = false
        }
    }
}
