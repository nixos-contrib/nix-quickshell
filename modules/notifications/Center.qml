import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The history of the notifications, in the corner of the toasts: newest first, with Clear all and Do not disturb
FloatingWindow {
    id: win
    required property ListModel history
    property bool dnd: false
    signal toggleDnd
    signal clearAll

    title: "nshell-center"
    visible: false
    color: "transparent"
    // the room around the panel is for its shadow
    readonly property int room: Theme.marginLow
    implicitWidth: 376 + room * 2
    // As tall as it can be, like the toasts: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    // the cards and their shadows, see the toasts
    mask: Region { x: panel.x - win.room; y: panel.y - win.room; width: panel.width + win.room * 2; height: panel.height + win.room * 2 }

    function place() {
        const scale = win.devicePixelRatio;
        const x = Math.round((win.screen.width - win.width + room - Theme.edge) * scale);
        const y = Math.round((Theme.barHeight + Theme.gap - room) * scale);
        // and takes the focus, which i3 may have given to the window of the popup that was closing
        I3.dispatch(`[title="^nshell-center$"] move absolute position ${x}px ${y}px, focus`);
    }
    property double openedAt: 0
    FocusGuard {
        id: focusGuard
        windowName: "nshell-center"
        onLost: win.visible = false
    }
    // drawn when it is in its place, see Popover
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
        y: win.room
        width: 376
        height: Math.min(win.height - win.room * 2, implicitHeight)
        title: "Notifications"
        opacity: win.placed ? 1 : 0
        focus: true
        Keys.onEscapePressed: win.visible = false
        // a click anywhere else closes it, as the popups of the bar
        onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) focusGuard.check()

        actions: [
            PillButton {
                text: "Do not disturb"
                active: win.dnd
                onClicked: win.toggleDnd()
            },
            PillButton {
                visible: list.count > 0
                text: "Clear all"
                onClicked: win.clearAll()
            }
        ]

        ListView {
            id: list
            width: parent.width
            height: count > 0 ? Math.min(contentHeight, Math.max(120, win.height - 24 - panel.chromeHeight)) : 0
            visible: count > 0
            model: win.history
            spacing: Theme.spaceSm + 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: HistoryCard {}
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 140 } }
            displaced: Transition { NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic } }
        }

        // the empty state, centered in the body
        Label {
            width: parent.width
            height: list.count === 0 ? implicitHeight + Theme.spaceXl : 0
            visible: list.count === 0
            role: "caption"
            text: "No notifications"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
