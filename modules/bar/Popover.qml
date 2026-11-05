import QtQuick
import Quickshell
import Quickshell.I3
import qs

// The popup under an item of the bar: the menu of an icon of the tray, the volume, the battery. A window of its own, hung from the
// item, in the style of the shell. It closes with Escape and when it loses the focus (a click anywhere else). What goes inside
// it is the content, in a panel that is as tall as it needs
FloatingWindow {
    id: win
    property real anchorX: 0
    property int panelWidth: 276
    default property alias content: body.data

    // the item that opened it, in the bar: its place in the window of the bar
    function openAt(x) {
        win.anchorX = x;
        win.visible = true;
    }

    title: "nshell-menu"
    visible: false
    color: "transparent"
    implicitWidth: panelWidth + 24
    // As tall as it can be, like the toasts and the center: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    mask: Region { item: panel }

    function place() {
        const scale = win.devicePixelRatio;
        // the panel is 12 in from the window, and it hangs from the item, kept inside the screen
        const x = Math.round((Math.min(win.anchorX, win.screen.width - Theme.edge - panel.width) - 12) * scale);
        const y = Math.round((Theme.barHeight - 8) * scale);
        // and takes the focus, which i3 may have given to the window of the popup that was closing
        I3.dispatch(`[title="^nshell-menu$"] move absolute position ${x}px ${y}px, focus`);
    }
    property double openedAt: 0
    onVisibleChanged: if (visible) {
        openedAt = Date.now();
        placeTimer.restart();
    }
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
        width: win.panelWidth
        height: Math.min(win.height - 24, body.implicitHeight + 16)
        radius: Theme.radius
        color: Theme.surface
        border { width: 1; color: Theme.border }
        focus: true
        Keys.onEscapePressed: win.visible = false
        onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) win.visible = false

        Item {
            id: body
            x: 8
            y: 8
            width: parent.width - 16
            implicitHeight: childrenRect.height
        }
    }
}
