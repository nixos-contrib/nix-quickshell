import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Services.Notifications
import qs

// The notification server of the session, and the toasts it shows in the corner
Scope {
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
        implicitHeight: 800
        mask: Region { item: stack }

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

        Column {
            id: stack
            width: 372 - 24
            x: 12
            y: 12
            spacing: Theme.spacing
            Repeater {
                model: server.trackedNotifications
                delegate: Toast {
                    required property Notification modelData
                    notification: modelData
                }
            }
        }
    }
}
