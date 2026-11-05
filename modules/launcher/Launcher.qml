import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs
import qs.modules.common
import "search.js" as Search

// The launcher: a card in the middle of the screen with a search field and a list. Two modes, the apps and the windows, and Tab
// goes from one to the other. The apps are ordered by how well they match and by how often they are run
Scope {
    id: root
    property string mode: "apps"
    property string query: ""
    readonly property var modes: ["apps", "windows"]
    // the windows of i3, read when the launcher opens in that mode
    property var windows: []
    // how many times each app was run, by the id of its desktop entry
    property var usage: ({})

    // A pick: a script asked for a choice among its lines, see `nshell pick`. The folder holds the lines and the pipe where the
    // answer goes, and the prompt takes the place of the modes
    property string pickDir: ""
    property string pickPrompt: ""
    property var pickLines: []

    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nix-shell/launcher.json"

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

    function openPick(dir: string, prompt: string) {
        // one at a time: a pick that is still open is cancelled
        if (root.pickDir !== "")
            root.answer("CANCEL", "");
        root.pickDir = dir;
        root.pickPrompt = prompt;
        pickFile.path = dir + "/items";
        pickFile.reload();
    }
    // the answer to the script, through the pipe that it waits on: OK and the line, or CANCEL
    function answer(status: string, line: string) {
        if (root.pickDir === "")
            return;
        const pipe = root.pickDir + "/result";
        root.pickDir = "";
        Quickshell.execDetached(["sh", "-c", 'printf "%s\n%s" "$1" "$2" > "$3"', "sh", status, line, pipe]);
    }

    function show(m) {
        // the launcher opened by hand takes the place of a pick that was waiting, which is cancelled
        const wasPick = root.pickDir !== "";
        if (wasPick)
            root.answer("CANCEL", "");
        if (win.visible && root.mode === m && !wasPick) {
            win.visible = false;
            return;
        }
        root.setMode(m);
        win.visible = true;
    }
    function setMode(m) {
        root.mode = m;
        root.query = "";
        if (m === "windows")
            tree.running = true;
    }
    function cycle() {
        root.setMode(root.modes[(root.modes.indexOf(root.mode) + 1) % root.modes.length]);
    }

    function iconUrl(name: string): string {
        if (!name)
            return "";
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true);
    }

    // what the list shows, best first
    readonly property var items: root.pickDir !== "" ? root.pickItems() : (root.mode === "apps" ? root.appItems() : root.windowItems())

    function appItems() {
        const q = root.query.trim().toLowerCase();
        const out = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay)
                continue;
            let s = 1;
            if (q !== "") {
                s = Math.max(Search.score(q, e.name, true), 0.6 * Search.score(q, e.genericName, false), 0.5 * Search.score(q, e.keywords.join(" "), false), 0.2 * Search.score(q, e.comment, false));
                if (s <= 0)
                    continue;
            }
            out.push({
                title: e.name,
                subtitle: e.genericName !== "" ? e.genericName : e.comment,
                icon: root.iconUrl(e.icon),
                score: s + Math.log(1 + (root.usage[e.id] ?? 0)) * 0.6,
                run: () => root.launch(e)
            });
        }
        out.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
        return out.slice(0, 60);
    }

    function pickItems() {
        const q = root.query.trim().toLowerCase();
        const out = [];
        for (const line of root.pickLines) {
            const f = line.split("\t");
            const s = q === "" ? 1 : Math.max(Search.score(q, f[0], true), 0.6 * Search.score(q, f[1] ?? "", false));
            if (s <= 0)
                continue;
            out.push({
                title: f[0],
                subtitle: f[1] ?? "",
                icon: root.iconUrl(f[2] ?? ""),
                score: s,
                run: () => {
                    root.answer("OK", line);
                    win.visible = false;
                }
            });
        }
        // the order of the script when nothing is typed, the best match first when it is
        if (q !== "")
            out.sort((a, b) => b.score - a.score);
        return out;
    }

    function windowItems() {
        const q = root.query.trim().toLowerCase();
        const out = [];
        for (const w of root.windows) {
            const s = q === "" ? 1 : Math.max(Search.score(q, w.title, true), 0.6 * Search.score(q, w.cls, true));
            if (s <= 0)
                continue;
            const entry = DesktopEntries.heuristicLookup(w.cls);
            out.push({
                title: w.title !== "" ? w.title : w.cls,
                subtitle: w.cls + (w.ws !== "" ? " · workspace " + w.ws : ""),
                icon: entry ? root.iconUrl(entry.icon) : "",
                score: s,
                run: () => {
                    win.visible = false;
                    I3.dispatch("[con_id=" + w.id + "] focus");
                }
            });
        }
        out.sort((a, b) => b.score - a.score);
        return out;
    }

    function launch(entry) {
        win.visible = false;
        entry.execute();
        const u = root.usage;
        u[entry.id] = (u[entry.id] ?? 0) + 1;
        root.usage = u;
        store.setText(JSON.stringify(u));
    }

    // the windows, from the tree of i3, without the ones of the shell itself
    function parseTree(text) {
        const out = [];
        const walk = (n, ws) => {
            if (n.type === "workspace")
                ws = n.name;
            const name = n.name ?? "";
            const cls = n.window_properties ? (n.window_properties.class ?? "") : "";
            // only the windows of a workspace: the bar of the shell is in the dock area, and the popups and cards of the shell are
            // known by their class or by their names
            if (n.window !== null && n.window !== undefined && ws !== "" && cls !== "quickshell" && !name.startsWith("nshell-") && name !== "polkit")
                out.push({ id: n.id, title: name, cls: cls, ws: ws.startsWith("__i3") ? "scratchpad" : ws });
            for (const c of (n.nodes ?? []).concat(n.floating_nodes ?? []))
                walk(c, ws);
        };
        try {
            walk(JSON.parse(text), "");
        } catch (e) {
            console.log("launcher: the tree of i3 could not be read:", e);
        }
        root.windows = out;
    }

    Process {
        id: tree
        command: ["i3-msg", "-t", "get_tree"]
        stdout: StdioCollector { onStreamFinished: root.parseTree(text) }
    }

    FileView {
        id: pickFile
        printErrors: false
        onLoaded: {
            root.pickLines = text().split("\n").filter(l => l !== "");
            root.query = "";
            win.visible = true;
        }
        onLoadFailed: root.answer("CANCEL", "")
    }

    FileView {
        id: store
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.statePath.substring(0, root.statePath.lastIndexOf("/"))])

    IpcHandler {
        target: "launcher"
        function apps(): void { if (root.fresh()) root.show("apps"); }
        function windows(): void { if (root.fresh()) root.show("windows"); }
        function pick(dir: string, prompt: string): void { root.openPick(dir, prompt); }
    }

    FloatingWindow {
        id: win
        title: "nshell-launcher"
        visible: false
        color: "transparent"
        implicitWidth: 680
        implicitHeight: 480

        property double openedAt: 0
        onVisibleChanged: {
            if (visible) {
                openedAt = Date.now();
                search.text = "";
                focusTimer.restart();
            } else if (root.pickDir !== "") {
                // closed without a choice: the script is waiting, and gets a cancel
                root.answer("CANCEL", "");
            }
        }
        Timer {
            id: focusTimer
            interval: 80
            onTriggered: {
                I3.dispatch('[title="^nshell-launcher$"] focus');
                search.forceActiveFocus();
            }
        }

        Panel {
            id: card
            anchors.fill: parent
            fillBody: true
            focus: true
            footer: root.pickDir !== "" ? "↵ choose     esc cancel" : "↵ open     ⇥ " + (root.mode === "apps" ? "windows" : "apps") + "     esc close"

            // the header is the search field, and the modes at its right. A pick has none
            header: RowLayout {
                width: parent.width
                spacing: Theme.spaceMd

                Text {
                    text: "\udb80\udf49"
                    color: Theme.muted
                    font { family: Theme.iconFont; pixelSize: Theme.iconBar }
                }
                TextInput {
                    id: search
                    Layout.fillWidth: true
                    color: Theme.text
                    selectionColor: Theme.accent
                    font { family: Theme.font; pixelSize: Theme.textHeading }
                    onTextChanged: root.query = text
                    // the keys are here, so this is what loses the focus when the window does: a click anywhere else closes the
                    // launcher, and a pick is cancelled
                    onActiveFocusChanged: if (!activeFocus && win.visible && Date.now() - win.openedAt > 600) win.visible = false
                    Text {
                        visible: search.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.pickDir !== "" ? root.pickPrompt : (root.mode === "apps" ? "Search apps" : "Search windows")
                        color: Theme.muted
                        font: search.font
                    }
                    Keys.onPressed: event => {
                        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
                        if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) {
                            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) {
                            list.currentIndex = Math.max(0, list.currentIndex - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            if (root.pickDir === "")
                                root.cycle();
                            search.text = "";
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            win.visible = false;
                            event.accepted = true;
                        }
                    }
                    onAccepted: if (list.currentItem) list.currentItem.modelData.run()
                }
                Repeater {
                    model: root.pickDir !== "" ? [] : root.modes
                    delegate: PillButton {
                        required property string modelData
                        text: modelData === "apps" ? "Apps" : "Windows"
                        active: root.mode === modelData
                        onClicked: {
                            root.setMode(modelData);
                            search.text = "";
                            search.forceActiveFocus();
                        }
                    }
                }
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 2
                model: root.items
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                onModelChanged: currentIndex = 0
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: LauncherRow {
                    onChosen: modelData.run()
                }

                // the empty state, centered in the body
                Label {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    role: "caption"
                    text: "No results"
                }
            }
        }
    }
}
