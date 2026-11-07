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
    // the room around the cards is for their shadows, and the window starts under the bar, see Popover
    readonly property int room: Theme.marginLow
    implicitWidth: 348 + room * 2
    // As tall as it can be, like the toasts: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    // the cards and their shadows, see the toasts
    mask: Region { x: stack.x - win.room; y: 0; width: stack.width + win.room * 2; height: stack.y + stack.height + win.room }

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
            stack.forceActiveFocus();
            revealTimer.restart();
        }
    }
    Timer {
        id: revealTimer
        interval: 60
        onTriggered: win.placed = true
    }

    // There is no panel around the cards: they are the cards of the toasts, in the same corner and of the same width, and the history is more of them
    // where they stood. The header is a card of its own: there is no blur, and its text would be on whatever is behind
    Column {
        id: stack
        x: win.room
        y: Theme.gap
        width: 348
        spacing: Theme.spacing
        opacity: win.placed ? 1 : 0
        focus: true
        Keys.onEscapePressed: win.visible = false
        // a click anywhere else closes it, as the popups of the bar
        onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) focusGuard.check()

        // The bell of the bar, which is also what opens this: it is the switch of do not disturb, a bell that is crossed while it is on, in the
        // color of the accent, and the line under the title says so. There is no count of all of them: the header of a group has its own
        Rectangle {
            id: header
            width: parent.width
            implicitHeight: headerRow.implicitHeight + Theme.spacing * 2
            height: implicitHeight
            radius: Theme.radiusLg
            color: Theme.surface
            border { width: 1; color: Theme.border }
            Shadow {}

            RowLayout {
                id: headerRow
                anchors { fill: parent; margins: Theme.spacing; leftMargin: Theme.spacing + 4 }
                spacing: Theme.spaceMd

                Rectangle {
                    id: bellButton
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Theme.radiusMd
                    color: bellArea.pressed ? Theme.surfaceHigh : (bellArea.containsMouse ? Theme.bg : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    Text {
                        anchors.centerIn: parent
                        text: win.dnd ? "\udb80\udc9b" : "\udb80\udc9a"
                        color: win.dnd ? Theme.primary : Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.iconBar + 2 }
                    }
                    MouseArea {
                        id: bellArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: bellTip.show(bellButton, win.dnd ? "Turn do not disturb off" : "Turn do not disturb on")
                        onExited: bellTip.hide()
                        onClicked: {
                            bellTip.hide();
                            win.toggleDnd();
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        Layout.fillWidth: true
                        role: "title"
                        text: "Notifications"
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: win.dnd
                        role: "caption"
                        color: Theme.primary
                        text: "Do not disturb is on"
                    }
                }
                PillButton {
                    visible: list.count > 0
                    text: "Clear all"
                    onClicked: win.clearAll()
                }
            }
        }
        Tip { id: bellTip }

        // The list takes the place of the cards, and the view around it is a room bigger on every side: it clips what scrolls, and it would cut the
        // shadows at the edge of the cards, as the stack of the toasts has it
        Item {
            id: viewport
            width: parent.width
            visible: list.count > 0
            height: list.count > 0 ? Math.min(list.contentHeight, Math.max(120, win.height - Theme.gap - win.room - header.height - stack.spacing)) : 0
            ListView {
                id: list
                x: -win.room
                y: -win.room
                width: viewport.width + win.room * 2
                height: viewport.height + win.room * 2
                topMargin: win.room
                bottomMargin: win.room
                model: win.history
                spacing: Theme.spacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                delegate: HistoryCard {
                    id: entry
                    readonly property var info: win.layout[index] ?? { count: 1, head: true, open: false, shown: true }
                    inset: win.room
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
        }

        // the empty state: a card, as the rest is
        Rectangle {
            width: parent.width
            visible: list.count === 0
            implicitHeight: empty.implicitHeight + Theme.spaceXl * 2
            height: implicitHeight
            radius: Theme.radiusLg
            color: Theme.surface
            border { width: 1; color: Theme.border }
            Shadow {}
            Label {
                id: empty
                anchors.centerIn: parent
                role: "caption"
                text: "No notifications"
            }
        }
    }
}
