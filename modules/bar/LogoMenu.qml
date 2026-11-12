import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

// The menu of the logo, as the Apple menu of macOS: About This Computer, what the logo opened before (the apps), the mode, Force Quit for
// the app that has the focus, and the session. The lines that end in dots ask before they do it, in the card of the session, and Sleep and Lock
// do not. There is no System Settings, as there is no settings app: the mode of the theme is the one setting that a click can change
Popover {
    id: win
    property var session
    property var launcher
    // the window that has the focus, { name, pid }: the bar asks for it when the logo is pressed, and the menu opens when it is let go
    property var target: null
    property string targetName: ""
    property string targetId: ""

    panelWidth: 260
    padding: Theme.spaceSm

    // what a line does runs a moment after the menu has closed: the window that opens takes the focus, and i3 gives it back to the window
    // before it when the menu goes, so the launcher opened with the menu still closing lost it at once and closed
    property var queued: null
    Timer {
        id: later
        interval: 200
        onTriggered: if (win.queued) win.queued()
    }

    // the focused window of i3, which is a window of an app and not of the shell
    function probe(): void {
        win.target = null;
        tree.running = true;
    }
    function find(node: var): var {
        if (node.focused && node.window)
            return node;
        for (const child of (node.nodes ?? []).concat(node.floating_nodes ?? [])) {
            const found = find(child);
            if (found)
                return found;
        }
        return null;
    }
    Process {
        id: tree
        command: ["i3-msg", "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const node = win.find(JSON.parse(text));
                    const cls = node && node.window_properties ? (node.window_properties.class ?? "") : "";
                    // the windows of the shell are not an app to quit
                    if (!node || cls === "" || cls.toLowerCase() === "quickshell" || (node.name ?? "").startsWith("nshell-") || node.name === "polkit")
                        return;
                    win.targetName = Apps.nameOfClass(cls);
                    pid.command = ["xprop", "-id", String(node.window), "_NET_WM_PID"];
                    pid.running = true;
                } catch (err) {
                    console.log("logo menu: no focused window", err);
                }
            }
        }
    }
    Process {
        id: pid
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/=\s*(\d+)/);
                if (m)
                    win.target = { name: win.targetName, pid: parseInt(m[1]) };
            }
        }
    }

    // the half-circle for the mode, light against dark: the sun of the icon font draws as a gear at this size
    // the lines: a separator is { sep: true }. Each runs, and the menu closes
    readonly property var entries: [
        { text: "About This Computer", glyph: "\uf108", action: () => win.session.showAbout() },
        { sep: true },
        { text: "Applications…", glyph: "\uf009", action: () => win.launcher.show("apps") },
        { text: Theme.dark ? "Switch to Light Mode" : "Switch to Dark Mode", glyph: "\uf042", action: () => Quickshell.execDetached(["nix-quickshell", "theme", "toggle"]) },
        { sep: true },
        { text: "Force Quit " + (target ? target.name : ""), show: target !== null, action: () => win.session.askForceQuit(win.target) },
        { sep: true, show: target !== null },
        { text: "Sleep", action: () => win.session.runNow("suspend") },
        { text: "Restart…", action: () => win.session.ask("reboot") },
        { text: "Shut Down…", action: () => win.session.ask("poweroff") },
        { sep: true },
        { text: "Lock Screen", show: (Theme.user.session?.lock ?? "") !== "", action: () => win.session.runNow("lock") },
        { text: "Log Out…", action: () => win.session.ask("logout") }
    ].filter(e => e.show !== false)

    ColumnLayout {
        width: parent.width
        spacing: 2
        Repeater {
            model: win.entries
            delegate: Item {
                id: line
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: modelData.sep ? 9 : 30

                Rectangle {
                    visible: line.modelData.sep === true
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 1
                    color: Theme.border
                }
                Rectangle {
                    visible: line.modelData.sep !== true
                    anchors.fill: parent
                    radius: Theme.radiusMd
                    color: area.containsMouse ? Theme.surfaceHigh : "transparent"
                    // an icon for the places, About and the apps, and none for what is done, as the Apple menu has it: a line without one starts at
                    // the edge, and does not line up with the ones that have it, as there
                    Text {
                        visible: line.modelData.glyph !== undefined
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                        width: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: line.modelData.glyph ?? ""
                        color: Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.iconBar - 2 }
                    }
                    Label {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: line.modelData.glyph !== undefined ? 10 + 20 + 8 : 10 }
                        text: line.modelData.text ?? ""
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        enabled: line.modelData.sep !== true
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.visible = false;
                            win.queued = line.modelData.action;
                            later.restart();
                        }
                    }
                }
            }
        }
    }
}
