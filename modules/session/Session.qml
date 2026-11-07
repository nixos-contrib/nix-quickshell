import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs
import qs.modules.common

// The menu of the session: lock, log out, suspend, reboot and power off, a card in the middle of the screen as the launcher is, from a key
// (`nshell session`) or from a right click on the logo. Each has a key, the letter that is underlined, and the arrows and Enter do the
// same. Reboot and power off ask once more in the same card, and nothing else does. The commands are the `session` of the theme file:
// lock has none by default, and then it is not there, as X11 has no lock screen for a shell to draw: it only runs the one of the user
Scope {
    id: root

    readonly property bool open: win.visible
    property string asking: ""
    property int current: 0

    readonly property var config: Theme.user.session ?? ({})
    // the five, with the letter of each (mark is its place in the label), and the command that it runs
    readonly property var all: [
        { id: "lock", label: "Lock", mark: 0, key: Qt.Key_L, glyph: "\uf023", ask: false, command: config.lock ?? "" },
        { id: "logout", label: "Log out", mark: 1, key: Qt.Key_O, glyph: "\uf08b", ask: false, command: config.logout ?? "i3-msg exit" },
        { id: "suspend", label: "Suspend", mark: 0, key: Qt.Key_S, glyph: "\uf186", ask: false, command: config.suspend ?? "systemctl suspend" },
        { id: "reboot", label: "Reboot", mark: 0, key: Qt.Key_R, glyph: "\uf021", ask: true, command: config.reboot ?? "systemctl reboot" },
        { id: "poweroff", label: "Power off", mark: 0, key: Qt.Key_P, glyph: "\uf011", ask: true, command: config.poweroff ?? "systemctl poweroff" }
    ]
    // an action with no command is not there
    readonly property var actions: all.filter(a => a.command !== "")
    readonly property var pending: actions.find(a => a.id === asking) ?? null

    // a burst of the same key is one press, see Launcher
    property double lastIpc: 0
    function fresh(): bool {
        const now = Date.now();
        const first = now - root.lastIpc > 400;
        root.lastIpc = now;
        return first;
    }
    function toggle(): void {
        if (win.visible) {
            win.visible = false;
            return;
        }
        root.asking = "";
        root.current = 0;
        // the card has the height of its lines as they are when it opens: i3 does not follow a floating window that grows
        win.implicitHeight = 124 + root.actions.length * 44 + Theme.marginHigh * 2;
        win.visible = true;
    }
    function hide(): void { win.visible = false; }

    function marked(a: var): string {
        return a.label.substring(0, a.mark) + "<u>" + a.label.substring(a.mark, a.mark + 1) + "</u>" + a.label.substring(a.mark + 1);
    }
    function run(a: var): void {
        if (a.ask && root.asking !== a.id) {
            root.asking = a.id;
            return;
        }
        win.visible = false;
        Quickshell.execDetached(["sh", "-c", a.command]);
    }

    IpcHandler {
        target: "session"
        function toggle(): void { if (root.fresh()) root.toggle(); }
    }

    FloatingWindow {
        id: win
        title: "nshell-session"
        visible: false
        color: "transparent"
        // the room around the card is for its shadow
        implicitWidth: 340 + Theme.marginHigh * 2
        implicitHeight: 400

        property double openedAt: 0
        FocusGuard {
            id: focusGuard
            windowName: "nshell-session"
            onLost: win.visible = false
        }
        onVisibleChanged: {
            if (visible) {
                openedAt = Date.now();
                focusTimer.restart();
            }
        }
        Timer {
            id: focusTimer
            interval: 80
            onTriggered: {
                I3.dispatch('[title="^nshell-session$"] focus');
                card.forceActiveFocus();
            }
        }

        Panel {
            id: card
            anchors { fill: parent; margins: Theme.marginHigh }
            elevation: 2
            fillBody: true
            focus: true
            title: root.pending ? root.pending.label : "Session"
            footer: root.pending ? "↵ " + root.pending.label.toLowerCase() + "     esc back" : "↵ choose     esc close"
            onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) focusGuard.check()

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (root.asking !== "")
                        root.asking = "";
                    else
                        win.visible = false;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.pending)
                        root.run(root.pending);
                    else if (root.actions.length > 0)
                        root.run(root.actions[root.current]);
                    event.accepted = true;
                } else if (root.asking === "") {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        root.current = (root.current + 1) % root.actions.length;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                        root.current = (root.current + root.actions.length - 1) % root.actions.length;
                        event.accepted = true;
                    } else {
                        const a = root.actions.find(x => x.key === event.key);
                        if (a) {
                            root.current = root.actions.indexOf(a);
                            root.run(a);
                            event.accepted = true;
                        }
                    }
                }
            }

            // the lines
            ColumnLayout {
                anchors.fill: parent
                visible: root.asking === ""
                spacing: 4
                Repeater {
                    model: root.actions
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Theme.radiusMd
                        color: root.current === index ? Theme.surfaceHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
                            spacing: Theme.spaceMd
                            Text {
                                Layout.preferredWidth: 20
                                horizontalAlignment: Text.AlignHCenter
                                text: row.modelData.glyph
                                color: row.modelData.ask ? Theme.critical : Theme.text
                                font { family: Theme.iconFont; pixelSize: Theme.iconBar }
                            }
                            Label {
                                Layout.fillWidth: true
                                textFormat: Text.StyledText
                                text: root.marked(row.modelData)
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = row.index
                            onClicked: root.run(row.modelData)
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            // the question: the same card, with the two answers
            ColumnLayout {
                anchors.fill: parent
                visible: root.asking !== ""
                spacing: Theme.spaceLg
                Item { Layout.fillHeight: true }
                Label {
                    Layout.fillWidth: true
                    role: "heading"
                    horizontalAlignment: Text.AlignHCenter
                    text: root.pending ? root.pending.label + " now?" : ""
                }
                Label {
                    Layout.fillWidth: true
                    role: "caption"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "Everything that is open is closed."
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spaceMd
                    PillButton { text: "Cancel"; onClicked: root.asking = "" }
                    PillButton { text: root.pending ? root.pending.label : ""; active: true; onClicked: root.run(root.pending) }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
