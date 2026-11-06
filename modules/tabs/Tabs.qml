import QtQuick
import QtQml
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs
import qs.modules.common

// The tabs of the tabbed containers of i3. i3 reserves the strip of a tabbed container and draws nothing in it, see
// the colors that nix-shell writes for it, and a window of the shell is put over each strip: the shell knows where from the tree of i3
// (the rectangles of the tabs), and does what a click says with the commands of i3. There is no stacked layout: a container is tabbed,
// and the button at the end of its strip opens the list of its windows, for when there are many
Scope {
    id: root

    // group: no strip, the windows of a workspace are in the bar, at its number. The others are strips over the room that i3 reserves, which
    // has to be as high as a strip (the patch of i3), and are not used with the group.
    // The look of a strip that has the width of the workspace and is under the bar: flush, square, as a second row of the bar, or card,
    // the width of its container, rounded. Any other strip is a card. `nshell tabs style` changes it
    property string look: "group"
    property var lastTree: null
    // Windows that i3 moved when the screen changed, which is what leaving full screen in the window of the VM does: the strip is put in
    // its place again. The number of times it was, by container
    property var nonces: ({})
    // The bar is not a dock of i3: the output has none at the top while the shell runs. The shell shows its bar again
    property bool dockMissing: false
    signal remapBar

    // The windows of every workspace, by its name, for the group of the bar: a list of groups in the order they have on the screen, each
    // { id, stack (a tabbed container: it has a list), active (the focus is in it), tabs }, and a tab as in the containers. The windows
    // that are not tabs, side by side, are one group without a list. A tab is lit (current) only in the workspace in view
    property var workspaceGroups: ({})
    // The tabbed containers in view, each { id, x, y, w, h (the strip, in pixels of the screen), active (the focus is in it), tabs }, and
    // a tab { id, name, cls, current (the tab in front), urgent }
    property var containers: []
    // the container that holds the focus: the list of a key opens for it
    property var focusedContainer: null

    readonly property bool listOpen: list.visible
    function closeList() { list.visible = false; }

    // --------------------------------------------------------------------------------------------------------- the tree of i3
    function leafOf(node) {
        if (node.window)
            return node;
        const kids = (node.nodes ?? []).concat(node.floating_nodes ?? []);
        if (kids.length === 0)
            return node;
        const first = node.focus && node.focus.length > 0 ? kids.find(k => k.id === node.focus[0]) : null;
        return root.leafOf(first ?? kids[0]);
    }
    function holdsFocus(node) {
        if (node.focused)
            return true;
        return (node.nodes ?? []).concat(node.floating_nodes ?? []).some(k => root.holdsFocus(k));
    }
    function anyUrgent(node) {
        if (node.urgent)
            return true;
        return (node.nodes ?? []).concat(node.floating_nodes ?? []).some(k => root.anyUrgent(k));
    }
    // the windows in a node: a tab can be a split of several
    function windowsIn(node) {
        if (node.window)
            return 1;
        return (node.nodes ?? []).concat(node.floating_nodes ?? []).reduce((n, k) => n + root.windowsIn(k), 0);
    }
    function tabOf(child, front) {
        const leaf = root.leafOf(child);
        return {
            id: child.id,
            name: leaf.name ?? "",
            cls: leaf.window_properties ? (leaf.window_properties.class ?? "") : "",
            current: front,
            // more than one when the tab is a split: the icon and the title are the ones of its first window
            count: Math.max(1, root.windowsIn(child)),
            urgent: root.anyUrgent(child)
        };
    }
    function collect(node, out, output, ws, inView) {
        if (node.type === "con" && node.layout === "tabbed" && (node.nodes ?? []).length > 0) {
            const kids = node.nodes;
            const strips = kids.map(k => k.deco_rect).filter(d => d && d.height > 0);
            const hidden = kids.some(k => (k.fullscreen_mode ?? 0) !== 0 || (node.fullscreen_mode ?? 0) !== 0);
            if (strips.length > 0 && !hidden) {
                const front = node.focus && node.focus.length > 0 ? node.focus[0] : kids[0].id;
                // the strip is at the top of the container, as wide as it: the rectangle of the container, with the height of the tabs.
                // The deco_rect of i3 is not in the same coordinates in x and in y
                // the container fills the width of the output and is just under the bar: the strip can be a row of the bar
                const scale = Quickshell.screens.length > 0 ? Quickshell.screens[0].devicePixelRatio : 1;
                const left = node.rect.x - output.rect.x;
                const right = output.rect.x + output.rect.width - node.rect.x - node.rect.width;
                const flush = root.look === "flush" && Math.abs(node.rect.y - (output.rect.y + Theme.barHeight * scale)) <= 2 && Math.abs(left - right) <= 2 && left < output.rect.width / 8;
                // attached (experimental): moved down against the window, which leaves the corners of the window round under its corners
                const attached = root.look === "attached";
                const frontKid = kids.find(k => k.id === front) ?? kids[0];
                out.push({
                    id: node.id,
                    ws: ws,
                    inView: inView,
                    attached: attached,
                    full: flush,
                    // the window of the strip, and how far in from its left edge the tabs start
                    x: flush ? output.rect.x : node.rect.x,
                    // the strip is the height of the strip that i3 keeps, and the window is under it with the gap between them: the
                    // attached row is moved down to the window, which leaves the gap above it, the same as the one under the window
                    y: attached ? frontKid.rect.y - strips[0].height : node.rect.y,
                    ear: 0,
                    nonce: root.nonces[node.id] ?? 0,
                    w: flush ? output.rect.width : node.rect.width,
                    h: strips[0].height,
                    inset: flush ? left : 0,
                    active: root.holdsFocus(node),
                    tabs: kids.map(k => root.tabOf(k, k.id === front))
                });
            }
        }
        for (const c of (node.nodes ?? []).concat(node.floating_nodes ?? []))
            root.collect(c, out, output, ws, inView);
    }
    // every workspace has the strips of its containers, in windows that i3 hides with the workspace, so that they are not seen for a
    // moment on the next one when it changes. The ones of the workspace in view are the ones that count for the focus
    function build(tree) {
        const out = [];
        for (const output of tree.nodes ?? []) {
            if (output.name === "__i3")
                continue;
            for (const content of output.nodes ?? []) {
                if (content.type !== "con")
                    continue;
                // the workspace in view is the first of the focus of the content of the output
                const shown = content.focus && content.focus.length > 0 ? content.focus[0] : -1;
                for (const ws of content.nodes ?? [])
                    if (ws.type === "workspace" && !ws.name.startsWith("__i3"))
                        root.collect(ws, out, output, ws.name, ws.id === shown);
            }
        }
        return out;
    }
    function groupsOf(ws, inView) {
        const out = [];
        let loose = null;
        const walk = node => {
            const kids = node.nodes ?? [];
            if ((node.layout === "tabbed" || node.layout === "stacked") && kids.length > 1) {
                loose = null;
                const front = node.focus && node.focus.length > 0 ? node.focus[0] : kids[0].id;
                out.push({ id: node.id, stack: true, active: root.holdsFocus(node), tabs: kids.map(k => root.tabOf(k, inView && k.id === front)) });
                return;
            }
            if (node.window) {
                // the windows of the shell itself (a popup, a toast) are not windows of the workspace
                const cls = node.window_properties ? (node.window_properties.class ?? "") : "";
                if (cls === "quickshell" || (node.name ?? "").startsWith("nshell-") || node.name === "polkit")
                    return;
                if (!loose) {
                    loose = { id: node.id, stack: false, active: false, tabs: [] };
                    out.push(loose);
                }
                loose.tabs.push(root.tabOf(node, inView && !!node.focused));
                loose.active = loose.active || !!node.focused;
                return;
            }
            for (const c of kids.concat(node.floating_nodes ?? []))
                walk(c);
        };
        walk(ws);
        return out;
    }
    function groups(tree) {
        const out = {};
        for (const output of tree.nodes ?? []) {
            if (output.name === "__i3")
                continue;
            for (const content of output.nodes ?? []) {
                if (content.type !== "con")
                    continue;
                const shown = content.focus && content.focus.length > 0 ? content.focus[0] : -1;
                for (const ws of content.nodes ?? [])
                    if (ws.type === "workspace" && !ws.name.startsWith("__i3"))
                        out[ws.name] = root.groupsOf(ws, ws.id === shown);
            }
        }
        return out;
    }
    // where the windows of the strips are, by the id of their container: x, y, w, h in pixels of the screen
    function actualStrips(tree) {
        const found = {};
        const walk = n => {
            const m = /^nshell-tabs-(\d+)$/.exec(n.name ?? "");
            if (m && n.window)
                found[m[1]] = n.rect;
            for (const c of (n.nodes ?? []).concat(n.floating_nodes ?? []))
                walk(c);
        };
        walk(tree);
        return found;
    }
    function docked(tree) {
        for (const output of tree.nodes ?? [])
            if (output.name !== "__i3" && (output.nodes ?? []).some(c => c.type === "dockarea" && c.name === "topdock" && (c.nodes ?? []).length === 0))
                return false;
        return true;
    }
    property int dockStrikes: 0
    property double lastRemap: 0
    function apply(tree) {
        root.lastTree = tree;
        // two reads in a row without a dock, and not more often than every ten seconds
        root.dockStrikes = root.docked(tree) ? 0 : root.dockStrikes + 1;
        if (root.dockStrikes >= 2 && Date.now() - root.lastRemap > 10000) {
            root.lastRemap = Date.now();
            root.dockStrikes = 0;
            root.remapBar();
        }
        const actual = root.actualStrips(tree);
        const built = root.build(tree);
        for (const c of built) {
            const a = actual[String(c.id)];
            if (c.inView && a && (Math.abs(a.x - c.x) > 2 || Math.abs(a.y - c.y) > 2 || Math.abs(a.width - c.w) > 2 || Math.abs(a.height - (c.h + c.ear)) > 2)) {
                root.nonces[c.id] = (root.nonces[c.id] ?? 0) + 1;
                c.nonce = root.nonces[c.id];
            }
        }
        // the same value does not rebuild the windows
        if (JSON.stringify(built) !== JSON.stringify(root.containers))
            root.containers = built;
        const grouped = root.groups(tree);
        if (JSON.stringify(grouped) !== JSON.stringify(root.workspaceGroups))
            root.workspaceGroups = grouped;
        if (root.look === "group") {
            // the stack that holds the focus, or else a stack of the workspace in view
            let found = null;
            for (const output of tree.nodes ?? [])
                for (const content of output.nodes ?? [])
                    for (const ws of content.nodes ?? [])
                        if (ws.type === "workspace" && content.focus && content.focus[0] === ws.id) {
                            const stacks = (grouped[ws.name] ?? []).filter(g => g.stack);
                            found = stacks.find(g => g.active) ?? stacks[0] ?? null;
                        }
            root.focusedContainer = found;
        } else
            root.focusedContainer = built.find(c => c.active && c.inView) ?? null;
    }

    Process {
        id: tree
        command: ["i3-msg", "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.apply(JSON.parse(text)); } catch (e) { console.log("tabs: the tree could not be read:", e); }
            }
        }
    }
    // a burst of events, as the ones of a layout change, is one read of the tree
    Timer {
        id: refresh
        interval: 30
        onTriggered: if (!tree.running) tree.running = true
    }
    Process {
        running: true
        command: ["i3-msg", "-t", "subscribe", "-m", "[\"window\",\"workspace\"]"]
        stdout: SplitParser { onRead: refresh.restart() }
    }
    // i3 sends no event when the layout of a container changes, tabbed or split: the tree is read again from time to time, which a
    // key that changes the layout also waits for, as the binding comes before its command is done
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: if (!tree.running) tree.running = true
    }
    Process {
        running: true
        command: ["i3-msg", "-t", "subscribe", "-m", "[\"binding\"]"]
        stdout: SplitParser { onRead: later.restart() }
    }
    Timer {
        id: later
        interval: 120
        onTriggered: if (!tree.running) tree.running = true
    }
    Component.onCompleted: refresh.restart()

    // ------------------------------------------------------------------------------------------------------------ the actions
    function focusTab(id) { I3.dispatch(`[con_id=${id}] focus`); }
    function closeTab(id) { I3.dispatch(`[con_id=${id}] kill`); }
    // the click on a strip took the focus from the window that had it: it goes back
    function refocus() {
        const c = root.focusedContainer;
        if (c) {
            const front = c.tabs.find(t => t.current);
            if (front)
                root.focusTab(front.id);
        }
    }

    // from a button of the bar: where the list hangs from is given, in points
    function openListAt(container, x, y) {
        if (!container)
            return;
        list.container = container;
        list.openAt(x - list.panelWidth / 2, y + 4);
    }
    function openList(container) {
        if (!container)
            return;
        list.container = container;
        const scale = Quickshell.screens.length > 0 ? Quickshell.screens[0].devicePixelRatio : 1;
        // at the end of the strip, under its button
        list.openAt((container.x + container.w - container.inset) / scale - list.panelWidth - 6, (container.y + container.h) / scale);
    }

    onLookChanged: if (root.lastTree) root.apply(root.lastTree)

    IpcHandler {
        target: "tabs"
        function list(): void { root.openList(root.focusedContainer); }
        function style(look: string): string {
            if (look === "flush" || look === "card" || look === "attached" || look === "group")
                root.look = look;
            return root.look;
        }
    }

    TabList {
        id: list
        onPicked: id => { root.focusTab(id); list.visible = false; }
        onTabClosed: id => root.closeTab(id)
    }

    // keyed by the id of the container: a change of a title or a tab updates the window and does not make it again
    Instantiator {
        // no strips in the group look: the tabs are in the bar
        model: ScriptModel { values: root.look === "group" ? [] : root.containers; objectProp: "id" }
        delegate: TabStrip {
            required property var modelData
            spec: modelData
            onTabClicked: id => root.focusTab(id)
            onTabClosed: id => root.closeTab(id)
            onListRequested: root.openList(modelData)
            onBlankClicked: root.refocus()
        }
    }
}
