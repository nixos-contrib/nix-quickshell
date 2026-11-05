import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Services.Notifications
import qs

// The notification server of the session, and the toasts it shows in the corner
Scope {
    id: root
    readonly property int count: server.trackedNotifications.values.length
    // Shows the cards that wait behind the newest ones, and goes back when there is nothing left behind
    property bool expanded: false
    onCountChanged: if (count <= Theme.toastLimit) expanded = false

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => n.tracked = true
    }

    // A window that i3 floats in the corner without the focus, see the rule in its config
    FloatingWindow {
        id: win
        title: "nshell-toast"
        visible: server.trackedNotifications.values.length > 0
        color: "transparent"
        implicitWidth: 372
        // i3 does not follow a floating window that grows, so it is as tall as it will need and only the cards take
        // the pointer: the rest of it is transparent and lets the clicks through
        implicitHeight: Math.max(400, win.screen.height - 72)
        mask: Region { item: panel }

        // i3 floats the window, and the corner is set in pixels of the screen, which the scale of Qt multiplies
        function place() {
            const scale = win.devicePixelRatio;
            const x = Math.round(win.screen.width * scale - win.width * scale - 24 * scale);
            const y = Math.round(56 * scale);
            I3.dispatch(`[title="^nshell-toast$"] move absolute position ${x}px ${y}px`);
        }
        onVisibleChanged: if (visible) placeTimer.restart()
        onWidthChanged: placeTimer.restart()
        Timer {
            id: placeTimer
            interval: 80
            onTriggered: win.place()
        }

        // The cards scroll when they do not fit the height of the screen, and the buttons under them stay in place
        Column {
            id: panel
            width: 372 - 24
            x: 12
            y: 12
            spacing: Theme.spacing

            Flickable {
                id: scroller
                width: parent.width
                height: Math.min(stack.implicitHeight, win.height - 24 - (footer.visible ? footer.height + panel.spacing : 0))
                contentWidth: width
                contentHeight: stack.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                // The newest is on top and the older ones wait below, so that showing them does not move the cards
                // that are being read. The model keeps a card for the same notification when the list changes: it does
                // not start its time again
                Column {
                    id: stack
                    width: scroller.width
                    spacing: Theme.spacing
                    move: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }
                    Repeater {
                        model: ScriptModel { values: server.trackedNotifications.values.slice().reverse() }
                        delegate: Toast {
                            required property Notification modelData
                            required property int index
                            notification: modelData
                            visible: root.expanded || index < Theme.toastLimit
                        }
                    }
                }
            }
            StackFooter {
                id: footer
                width: parent.width
                visible: root.count >= 3
                hidden: Math.max(0, root.count - Theme.toastLimit)
                expanded: root.expanded
                onToggle: root.expanded = !root.expanded
                onClearAll: server.trackedNotifications.values.slice().forEach(n => n.dismiss())
            }
        }
    }
}
