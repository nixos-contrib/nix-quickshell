import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications
import qs

// The notification server of the session, and the toasts it shows in the corner
Scope {
    id: root
    readonly property int count: server.trackedNotifications.values.length
    // Shows the cards that wait behind the newest ones, and goes back when there is nothing left behind
    property bool expanded: false
    onCountChanged: if (count <= Theme.toastLimit) expanded = false

    // A key that is held a moment repeats, and the command it runs comes again and again, 25 ms apart: these commands toggle, so
    // the repeat would close what the first opened. Only the first of a burst counts, the ones that follow it within 400 ms are
    // the same press
    property double lastIpc: 0
    function fresh(): bool {
        const now = Date.now();
        const first = now - root.lastIpc > 400;
        root.lastIpc = now;
        return first;
    }

    // For the bar: something came since the history was last opened, which the bell says with a dot, and the two things its bell does.
    // How many are in the history is in the panel
    property bool hasNew: false
    readonly property int stored: history.count
    readonly property bool centerOpen: center.visible
    function toggleCenter() { center.visible = !center.visible; }
    function closeCenter() { center.visible = false; }
    function toggleDnd() { root.dnd = !root.dnd; }

    // Do not disturb: the toasts stay away, critical ones excepted, and the history still has them
    property bool dnd: false
    onDndChanged: save()

    // A popup of the bar is open: the toasts wait, and come when it closes, so that they do not cover what is being used
    property bool popupOpen: false

    // What came: the newest first, the last hundred. It follows the notification while the app has it: when the app updates it
    // the entry says the new text, and when the app takes it back the entry goes. What is dismissed or expires stays. And it is
    // kept in a file, so that the history is the same after the shell starts again
    ListModel {
        id: history
        onCountChanged: root.save()
    }

    function fields(n) {
        return {
            appName: n.appName,
            summary: n.summary,
            body: n.body,
            picture: Pictures.of(n.image, n.appIcon, n.appName, n.desktopEntry),
            iconName: Pictures.iconName(n.image, n.appIcon, n.appName, n.desktopEntry),
            critical: n.urgency === NotificationUrgency.Critical
        };
    }
    function indexOfId(nid) {
        for (let i = 0; i < history.count; i++)
            if (history.get(i).nid === nid)
                return i;
        return -1;
    }
    function record(n) {
        const entry = root.fields(n);
        entry.nid = n.id;
        entry.time = Math.floor(Date.now() / 1000);
        history.insert(0, entry);
        // the panel that is open shows it already
        root.hasNew = !center.visible;
        while (history.count > 100)
            history.remove(history.count - 1);
        // the app may update it, and may take it back
        const refresh = () => root.refresh(n);
        n.summaryChanged.connect(refresh);
        n.bodyChanged.connect(refresh);
        n.imageChanged.connect(refresh);
        n.appIconChanged.connect(refresh);
        n.urgencyChanged.connect(refresh);
        n.closed.connect(reason => {
            if (reason === NotificationCloseReason.CloseRequested)
                root.withdraw(n.id);
        });
    }
    function refresh(n) {
        const i = root.indexOfId(n.id);
        if (i < 0)
            return;
        const f = root.fields(n);
        for (const key in f)
            history.setProperty(i, key, f[key]);
        root.save();
    }
    function withdraw(nid) {
        const i = root.indexOfId(nid);
        if (i >= 0)
            history.remove(i);
    }

    // the file, in the state folder of the user: the entries without their raw pictures, which do not last, and do not disturb
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nix-shell/history.json"
    function save() {
        saver.restart();
    }
    Timer {
        id: saver
        interval: 400
        onTriggered: {
            const entries = [];
            for (let i = 0; i < history.count; i++) {
                const e = history.get(i);
                entries.push({ appName: e.appName, summary: e.summary, body: e.body, iconName: e.iconName, critical: e.critical, time: e.time });
            }
            store.setText(JSON.stringify({ dnd: root.dnd, entries: entries }));
        }
    }
    FileView {
        id: store
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text());
                root.dnd = saved.dnd === true;
                // older than anything that came since the shell started
                for (const e of saved.entries ?? [])
                    history.append({
                        nid: -1,
                        appName: e.appName,
                        summary: e.summary,
                        body: e.body,
                        iconName: e.iconName ?? "",
                        picture: Pictures.of("", e.iconName ?? "", e.appName, ""),
                        critical: e.critical === true,
                        time: e.time
                    });
            } catch (err) {
                console.log("notifications: the saved history could not be read:", err);
            }
        }
    }
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.statePath.substring(0, root.statePath.lastIndexOf("/"))])

    // The image that came with a notification is served under a URL that is gone when it closes. Each entry of the history
    // keeps its picture loaded here, at the size the cards ask for, and the cards find it in the cache of Qt
    Item {
        visible: false
        Repeater {
            model: history
            delegate: Image {
                required property string picture
                source: picture
                sourceSize: Qt.size(96, 96)
                asynchronous: false
                cache: true
            }
        }
    }

    // The chat apps play their pings themselves: they are muted while do not disturb is on
    QuietSound { active: root.dnd }

    IpcHandler {
        target: "center"
        function toggle(): void { if (root.fresh()) root.toggleCenter(); }
        function dnd(): void { if (root.fresh()) root.toggleDnd(); }
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => {
            root.record(n);
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                n.tracked = true;
        }
    }

    // A window that i3 floats in the corner without the focus, see the rule in its config
    FloatingWindow {
        id: win
        title: "nshell-toast"
        visible: server.trackedNotifications.values.length > 0 && !center.visible && !root.popupOpen
        color: "transparent"
        // the room around the cards is for their shadows
        readonly property int room: Theme.marginLow
        implicitWidth: 348 + room * 2
        // i3 does not follow a floating window that grows, so it is as tall as it will need and only the cards take
        // the pointer: the rest of it is transparent and lets the clicks through
        implicitHeight: Math.max(400, win.screen.height - 72)
        // the window takes the clicks on the cards and on their shadows, and the shape of the window is the one of the mask: a shadow
        // outside of it is cut. The rest of the tall window lets them through
        mask: Region { x: panel.x - win.room; y: 0; width: panel.width + win.room * 2; height: panel.y + panel.height + win.room }

        // i3 floats the window, and the corner is set in pixels of the screen, which the scale of Qt multiplies
        function place() {
            const scale = win.devicePixelRatio;
            // the cards are a room in from the window: their edge is the one of the bar, and they start the gap under it
            const x = Math.round((win.screen.width - win.width + room - Theme.edge) * scale);
            const y = Math.round(Theme.barHeight * scale);
            I3.dispatch(`[title="^nshell-toast$"] move absolute position ${x}px ${y}px`);
        }
        // drawn when it is in its place, see Popover
        property bool placed: false
        onVisibleChanged: {
            placed = false;
            if (visible)
                placeTimer.restart();
        }
        onWidthChanged: placeTimer.restart()
        Timer {
            id: placeTimer
            interval: 60
            onTriggered: {
                win.place();
                revealTimer.restart();
            }
        }
        Timer {
            id: revealTimer
            interval: 60
            onTriggered: win.placed = true
        }

        // The cards scroll when they do not fit the height of the screen, and the buttons under them stay in place
        Column {
            id: panel
            opacity: win.placed ? 1 : 0
            width: 348
            x: win.room
            y: Theme.gap
            spacing: Theme.spacing

            // The list takes the place of the cards, and the Flickable around it is a room bigger on every side: it clips what scrolls,
            // and it would cut the shadows at the edge of the cards
            Item {
                id: viewport
                width: parent.width
                height: Math.min(stack.implicitHeight, win.height - Theme.gap - win.room - (footer.visible ? footer.height + panel.spacing : 0))
                Flickable {
                    id: scroller
                    x: -win.room
                    y: -win.room
                    width: viewport.width + win.room * 2
                    height: viewport.height + win.room * 2
                    contentWidth: width
                    contentHeight: stack.implicitHeight + win.room * 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    // The newest is on top and the older ones wait below, so that showing them does not move the cards
                    // that are being read. The model keeps a card for the same notification when the list changes: it does
                    // not start its time again
                    Column {
                        id: stack
                        x: win.room
                        y: win.room
                        width: viewport.width
                        spacing: Theme.spacing
                        move: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }
                        Repeater {
                            model: ScriptModel { values: server.trackedNotifications.values.slice().reverse() }
                            delegate: Toast {
                                required property Notification modelData
                                required property int index
                                notification: modelData
                                paused: root.popupOpen
                                visible: root.expanded || index < Theme.toastLimit
                            }
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

    // opening the history is seeing what came
    Connections {
        target: center
        function onVisibleChanged() { if (center.visible) root.hasNew = false; }
    }
    Center {
        id: center
        history: history
        dnd: root.dnd
        onToggleDnd: root.dnd = !root.dnd
        onClearAll: { history.clear(); root.hasNew = false; }
    }
}
