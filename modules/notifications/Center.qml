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

    // The groups of the history, as the toasts have them: more than two of one app are one card, the newest, and a click opens the list. By the
    // place in the history, which the count of the model says when it changes
    property var openApps: ({})
    function openApp(app: string, open: bool): void {
        const next = Object.assign({}, win.openApps);
        if (open)
            next[app] = true;
        else
            delete next[app];
        win.openApps = next;
    }
    function removeApp(app: string): void {
        for (let i = win.history.count - 1; i >= 0; i--)
            if (win.history.get(i).appName === app)
                win.history.remove(i);
    }
    readonly property var layout: {
        const n = win.history.count;
        const apps = [];
        const counts = {};
        for (let i = 0; i < n; i++) {
            const app = win.history.get(i).appName;
            apps.push(app);
            counts[app] = (counts[app] ?? 0) + 1;
        }
        const seen = {};
        const out = [];
        for (const app of apps) {
            const grouped = counts[app] > 2;
            const open = grouped && win.openApps[app] === true;
            const head = seen[app] !== true;
            seen[app] = true;
            out.push({ count: counts[app], head: head, open: open, shown: !grouped || open || head });
        }
        return out;
    }

    title: "nshell-center"
    visible: false
    color: "transparent"
    // the room around the panel is for its shadow, and the window starts under the bar, see Popover
    readonly property int room: Theme.marginLow
    implicitWidth: 376 + room * 2
    // As tall as it can be, like the toasts: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    // the cards and their shadows, see the toasts
    mask: Region { x: panel.x - win.room; y: 0; width: panel.width + win.room * 2; height: panel.y + panel.height + win.room }

    function place() {
        const scale = win.devicePixelRatio;
        const x = Math.round((win.screen.width - win.width + room - Theme.edge) * scale);
        const y = Math.round(Theme.barHeight * scale);
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
        y: Theme.gap
        width: 376
        height: Math.min(win.height - Theme.gap - win.room, implicitHeight)
        title: "Notifications"
        // how many are in the history, which the bar no longer says
        value: win.history.count > 0 ? String(win.history.count) : ""
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
            // what is left in the panel under its header: the panel has the gap above it and the room of its shadow under it
            height: count > 0 ? Math.min(contentHeight, Math.max(120, win.height - Theme.gap - win.room - panel.chromeHeight)) : 0
            visible: count > 0
            model: win.history
            spacing: Theme.spaceSm + 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: HistoryCard {
                id: entry
                readonly property var info: win.layout[index] ?? { count: 1, head: true, open: false, shown: true }
                groupCount: info.count
                groupHead: info.head
                groupOpen: info.open
                shown: info.shown
                onToggleGroup: win.openApp(appName, !info.open)
                onGroupRemoved: win.removeApp(appName)
            }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.motionBase } }
            displaced: Transition { NumberAnimation { properties: "y"; duration: Theme.motionBase; easing.type: Theme.motionEasing } }
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
