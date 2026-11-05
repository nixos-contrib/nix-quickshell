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
    // the top of the window, in points of the screen: under the bar when it is not set, or where a container asks for it
    property real anchorY: -1
    property int panelWidth: Theme.popupWidth
    property string heading: ""
    property string headerValue: ""
    // the room around the content: less for a menu, whose lines have room of their own
    property int padding: Theme.panelPadding
    default property alias content: panel.content

    // the item that opened it, in the bar: its place in the window of the bar
    function openAt(x, y) {
        win.anchorX = x;
        win.anchorY = y === undefined ? -1 : y;
        win.visible = true;
    }

    title: "nshell-menu"
    visible: false
    color: "transparent"
    // the room around the panel is for its shadow, at the sides and under it. The window starts under the bar, so that it never covers
    // it: a click on an item of the bar is for the item, and the window is as high as the gap between the bar and the panel
    readonly property int room: Theme.marginLow
    readonly property int top: 4
    implicitWidth: panelWidth + room * 2
    // As tall as it can be, like the toasts and the center: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    // the panel and its shadow: the shape of the window is the one of the mask, and a shadow outside of it is cut
    mask: Region { x: panel.x - win.room; y: 0; width: panel.width + win.room * 2; height: panel.y + panel.height + win.room }

    function place() {
        const scale = win.devicePixelRatio;
        // the panel is a room in from the window, and it hangs from the item, kept inside the screen
        const x = Math.round((Math.min(win.anchorX, win.screen.width - Theme.edge - panel.width) - room) * scale);
        const y = Math.round((anchorY >= 0 ? anchorY : Theme.barHeight) * scale);
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
        x: win.room
        y: win.top
        width: win.panelWidth
        height: Math.min(win.height - win.top - win.room, implicitHeight)
        title: win.heading
        value: win.headerValue
        padding: win.padding
        opacity: win.placed ? 1 : 0
        focus: true
        Keys.onEscapePressed: win.visible = false
        onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) focusGuard.check()
    }
}
