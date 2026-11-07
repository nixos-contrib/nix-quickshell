import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs
import qs.modules.common

// The card in the middle of the screen for the session, as the launcher is. It has three views in the same window: the menu of the session,
// with Lock, Log out, Suspend, Reboot and Power off, from `nshell session`; the question that Reboot, Power off, Log out and Force Quit ask
// before they do it; and About This Computer. The menu of the logo opens it on the question or on the about. Each line has a key, the letter that
// is underlined, and the arrows and Enter do the same. The commands are the `session` of the theme file: lock has none by default, and then it
// is not there, as X11 has no lock screen for a shell to draw: it only runs the one of the user
Scope {
    id: root

    readonly property bool open: win.visible
    // menu, ask or about
    property string view: "menu"
    property string asking: ""
    property int current: 0
    // the question came from the menu of the session, and goes back to it: when it came from the menu of the logo, it closes
    property bool cameFromMenu: false
    // the window that Force Quit would end: { name, pid }, which the menu of the logo finds
    property var forceTarget: null

    readonly property var config: Theme.user.session ?? ({})
    // the five, with the letter of each (mark is its place in the label), and the command that it runs. Those that lose what is not saved ask
    readonly property var all: [
        { id: "lock", label: "Lock", mark: 0, key: Qt.Key_L, glyph: "\uf023", ask: false, command: config.lock ?? "" },
        { id: "logout", label: "Log out", mark: 1, key: Qt.Key_O, glyph: "\uf08b", ask: true, command: config.logout ?? "i3-msg exit" },
        { id: "suspend", label: "Suspend", mark: 0, key: Qt.Key_S, glyph: "\uf186", ask: false, command: config.suspend ?? "systemctl suspend" },
        { id: "reboot", label: "Reboot", mark: 0, key: Qt.Key_R, glyph: "\uf021", ask: true, command: config.reboot ?? "systemctl reboot" },
        { id: "poweroff", label: "Power off", mark: 0, key: Qt.Key_P, glyph: "\uf011", ask: true, command: config.poweroff ?? "systemctl poweroff" }
    ]
    // an action with no command is not there
    readonly property var actions: all.filter(a => a.command !== "")
    // what the question is about: an action, or the window to end
    readonly property var pending: {
        if (asking === "forcequit" && forceTarget)
            return { id: "forcequit", label: "Force Quit", question: "Force quit " + forceTarget.name + "?", caption: "What is not saved in it is lost.", command: "kill -9 " + forceTarget.pid };
        const a = actions.find(x => x.id === asking);
        return a ? Object.assign({ question: a.label + " now?", caption: "Everything that is open is closed." }, a) : null;
    }

    // a burst of the same key is one press, see Launcher
    property double lastIpc: 0
    function fresh(): bool {
        const now = Date.now();
        const first = now - root.lastIpc > 400;
        root.lastIpc = now;
        return first;
    }
    // the card has the height of what it shows as it opens: i3 does not follow a floating window that grows
    function show(view: string, height: int): void {
        root.view = view;
        root.asking = view === "ask" ? root.asking : "";
        if (view !== "ask")
            root.cameFromMenu = false;
        win.implicitHeight = height + Theme.marginHigh * 2;
        win.visible = true;
    }
    function toggle(): void {
        if (win.visible) {
            win.visible = false;
            return;
        }
        root.current = 0;
        root.show("menu", 124 + root.actions.length * 44);
    }
    function hide(): void { win.visible = false; }
    // the question for an action, from the menu of the logo. Force Quit has its window in forceTarget
    function ask(id: string): void {
        root.asking = id;
        root.cameFromMenu = false;
        root.show("ask", 300);
    }
    function askForceQuit(target: var): void {
        root.forceTarget = target;
        root.ask("forcequit");
    }
    // an action with no question, from the menu of the logo
    function runNow(id: string): void {
        const a = root.actions.find(x => x.id === id);
        if (a)
            Quickshell.execDetached(["sh", "-c", a.command]);
    }
    function showAbout(): void {
        about.running = true;
        root.show("about", 470);
    }

    // out of the question: back to the menu when it came from there, closed when it came from the logo
    function back(): void {
        if (root.view === "ask" && root.cameFromMenu) {
            root.view = "menu";
            root.asking = "";
        } else {
            win.visible = false;
        }
    }

    function marked(a: var): string {
        return a.label.substring(0, a.mark) + "<u>" + a.label.substring(a.mark, a.mark + 1) + "</u>" + a.label.substring(a.mark + 1);
    }
    function run(a: var): void {
        if (a.ask && root.asking !== a.id) {
            root.asking = a.id;
            root.view = "ask";
            root.cameFromMenu = true;
            return;
        }
        win.visible = false;
        Quickshell.execDetached(["sh", "-c", a.command]);
    }

    // "3 days, 4 hours", "2 hours, 5 minutes", "7 minutes"
    function span(seconds: int): string {
        const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60);
        const part = (n, unit) => n + " " + unit + (n === 1 ? "" : "s");
        if (d > 0)
            return part(d, "day") + ", " + part(h, "hour");
        return h > 0 ? part(h, "hour") + ", " + part(m, "minute") : part(m, "minute");
    }

    // what About This Computer says: the system, and what it runs on
    property var info: ({})
    Process {
        id: about
        command: ["sh", "-c", `
            printf 'host=%s\\n' "$(cat /proc/sys/kernel/hostname)"
            printf 'kernel=%s\\n' "$(uname -sr)"
            printf 'arch=%s\\n' "$(uname -m)"
            printf 'cores=%s\\n' "$(nproc)"
            . /etc/os-release; printf 'name=%s\\nversion=%s\\n' "$NAME" "$VERSION"
            awk '/MemTotal/ { printf "mem=%d\\n", $2 / 1048576 + 0.5 }' /proc/meminfo
            awk '{ printf "up=%d\\n", $1 }' /proc/uptime
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        out[line.substring(0, i)] = line.substring(i + 1);
                }
                root.info = out;
            }
        }
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
            title: root.view === "about" ? "About This Computer" : (root.view === "ask" && root.pending ? root.pending.label : "Session")
            footer: root.view === "ask" ? "↵ " + (root.pending ? root.pending.label.toLowerCase() : "") + "     esc " + (root.cameFromMenu ? "back" : "close") : (root.view === "about" ? "esc close" : "↵ choose     esc close")
            onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) focusGuard.check()

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.back();
                    event.accepted = true;
                } else if (root.view === "about") {
                    // nothing else to do in the about
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.view === "ask" && root.pending)
                        root.run(root.pending);
                    else if (root.view === "menu" && root.actions.length > 0)
                        root.run(root.actions[root.current]);
                    event.accepted = true;
                } else if (root.view === "menu") {
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
                visible: root.view === "menu"
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
                                color: row.modelData.id === "reboot" || row.modelData.id === "poweroff" ? Theme.critical : Theme.text
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
                visible: root.view === "ask"
                spacing: Theme.spaceLg
                Item { Layout.fillHeight: true }
                Label {
                    Layout.fillWidth: true
                    role: "heading"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.pending ? root.pending.question : ""
                }
                Label {
                    Layout.fillWidth: true
                    role: "caption"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.pending ? root.pending.caption : ""
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spaceMd
                    PillButton { text: "Cancel"; onClicked: root.back() }
                    PillButton { text: root.pending ? root.pending.label : ""; active: true; onClicked: root.run(root.pending) }
                }
                Item { Layout.fillHeight: true }
            }

            // About This Computer
            ColumnLayout {
                anchors.fill: parent
                visible: root.view === "about"
                spacing: Theme.spaceMd
                Item { Layout.preferredHeight: Theme.spaceSm }
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: Qt.resolvedUrl(Theme.dark ? "../../assets/nixos-logomark-white-flat.svg" : "../../assets/nixos-logomark-black-flat.svg")
                    sourceSize: Qt.size(160, 140)
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 70
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    Layout.fillWidth: true
                    role: "heading"
                    horizontalAlignment: Text.AlignHCenter
                    text: root.info.name ?? "NixOS"
                }
                Label {
                    Layout.fillWidth: true
                    role: "caption"
                    horizontalAlignment: Text.AlignHCenter
                    text: root.info.version ?? ""
                }
                Item { Layout.preferredHeight: Theme.spaceSm }
                Repeater {
                    model: [
                        { k: "Host", v: root.info.host ?? "" },
                        { k: "Kernel", v: root.info.kernel ?? "" },
                        { k: "Architecture", v: root.info.arch ?? "" },
                        { k: "Processor", v: root.info.cores ? root.info.cores + (root.info.cores === "1" ? " core" : " cores") : "" },
                        { k: "Memory", v: root.info.mem ? root.info.mem + " GB" : "" },
                        { k: "Uptime", v: root.info.up ? root.span(parseInt(root.info.up)) : "" }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Theme.spaceMd
                        Label { role: "caption"; text: modelData.k; Layout.preferredWidth: 110 }
                        Label { text: modelData.v; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
