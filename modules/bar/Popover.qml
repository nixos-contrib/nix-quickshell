import QtQuick
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The popup under an item of the bar: the menu of an icon of the tray, the volume, the battery. A window of its own, hung from the
// item, with a panel in it. It closes with Escape and when it loses the focus (a click anywhere else). The header is the heading and
// its value, none for a menu, and the content goes in the body of the panel
FloatingWindow {
    id: win
    property real anchorX: 0
    property int panelWidth: Theme.popupWidth
    property string heading: ""
    property string headerValue: ""
    // the room around the content: less for a menu, whose lines have room of their own
    property int padding: Theme.panelPadding
    default property alias content: panel.content

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
    FocusGuard {
        id: focusGuard
        windowName: "nshell-menu"
        onLost: win.visible = false
    }
    // i3 shows a floating window in the middle of the screen, and it is moved to its place a moment later: the panel is not drawn
    // until it is there, or it showed for a moment where it does not belong
    property bool placed: false
    onVisibleChanged: {
        placed = false;
        if (visible) {
            openedAt = Date.now();
            placeTimer.restart();
        }
    }
    Timer {
        id: placeTimer
        interval: 60
        onTriggered: {
            win.place();
            panel.forceActiveFocus();
            revealTimer.restart();
        }
    }
    Timer {
        id: revealTimer
        interval: 60
        onTriggered: win.placed = true
    }

    Panel {
        id: panel
        x: 12
        y: 12
        width: win.panelWidth
        height: Math.min(win.height - 24, implicitHeight)
        title: win.heading
        value: win.headerValue
        padding: win.padding
        opacity: win.placed ? 1 : 0
        focus: true
        Keys.onEscapePressed: win.visible = false
        onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) focusGuard.check()
    }
}
