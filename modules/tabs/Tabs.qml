import QtQuick
import QtQml
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs
import qs.modules.common

// The windows of every workspace, for the bar (modules/bar/Workspaces): the groups of each one, as they are on the screen, a group for a
// tabbed container of i3 and one for the windows that are side by side. i3 reserves almost nothing for its tabs and draws nothing in it,
// see the colors that nix-quickshell writes for it: the shell knows the windows from the tree of i3, and does what a click says with the
// commands of i3. There is no stacked layout in the design, but one that is there is a group of tabs too. The list of the tabs of a
// group, for when there are many, is a popup under the chevron of the group
Scope {
    id: root

    // The bar is not a dock of i3: the output has none at the top while the shell runs, as after a change of the screen. The shell shows
    // its bar again
    signal remapBar
    // the key of the list: the group that has the focus, for the bar to open its list under its chevron
    signal listKeyRequested(var group)

    // The windows of every workspace, by its name, for the group of the bar: a list of groups in the order they have on the screen, each
    // { id, stack (a tabbed container: it has a list), active (the focus is in it), tabs }, and a tab { id, name, cls, current (the one in
    // front, or with the focus, and only in the workspace in view), count (windows in it, more than one for a split), urgent }. The
    // windows that are not tabs, side by side, are one group without a list
    property var workspaceGroups: ({})
    // the group of tabs that has the focus, or a group of tabs of the workspace in view: the list of the key is for it
    property var focusedContainer: null
    readonly property bool listOpen: list.visible || menu.visible
    // the list that is open is the one of this group: its chevron closes it, as the item of a popup of the bar does
    function listShows(group) { return list.visible && list.container !== null && group !== null && list.container.id === group.id; }
    function closeList() { list.visible = false; menu.visible = false; }

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
    function docked(tree) {
        for (const output of tree.nodes ?? [])
            if (output.name !== "__i3" && (output.nodes ?? []).some(c => c.type === "dockarea" && c.name === "topdock" && (c.nodes ?? []).length === 0))
                return false;
        return true;
    }
    property int dockStrikes: 0
    property double lastRemap: 0
    function apply(tree) {
        // two reads in a row without a dock, and not more often than every ten seconds
        root.dockStrikes = root.docked(tree) ? 0 : root.dockStrikes + 1;
        if (root.dockStrikes >= 2 && Date.now() - root.lastRemap > 10000) {
            root.lastRemap = Date.now();
            root.dockStrikes = 0;
            root.remapBar();
        }
        const grouped = root.groups(tree);
        // the same value does not rebuild the bar
        if (JSON.stringify(grouped) !== JSON.stringify(root.workspaceGroups))
            root.workspaceGroups = grouped;
        let found = null;
        for (const output of tree.nodes ?? [])
            for (const content of output.nodes ?? [])
                for (const ws of content.nodes ?? [])
                    if (ws.type === "workspace" && content.focus && content.focus[0] === ws.id) {
                        const stacks = (grouped[ws.name] ?? []).filter(g => g.stack);
                        found = stacks.find(g => g.active) ?? stacks[0] ?? null;
                    }
        root.focusedContainer = found;
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
    // a window that is taken to the front is the answer to the list, or to a click on an icon: the list and the menu are done
    function focusTab(id) { root.closeList(); I3.dispatch(`[con_id=${id}] focus`); }
    function closeTab(id) { I3.dispatch(`[con_id=${id}] kill`); }
    // the wheel on a group: the window after the one that is in front, or before it, round. Not when none is in front: the workspace is
    // not the one in view
    function cycle(group, step) {
        const n = group.tabs.length;
        const at = group.tabs.findIndex(t => t.current);
        if (n < 2 || at < 0)
            return;
        root.focusTab(group.tabs[(at + step + n) % n].id);
    }
    // a tab that is dragged: as many places as it was let go away, to the left when it is less than 0. The caller keeps it in its group
    function moveTab(tab, places) {
        const way = places < 0 ? "left" : "right";
        const moves = [];
        for (let i = 0; i < Math.abs(places); i++)
            moves.push("move " + way);
        I3.dispatch(`[con_id=${tab.id}] ${moves.join(", ")}`);
    }

    // from the chevron of a group: where the list hangs from is given, in points
    function openListAt(container, x, y) {
        if (!container)
            return;
        list.container = container;
        list.openAt(x - list.panelWidth / 2, y + 4);
    }
    IpcHandler {
        target: "tabs"
        function list(): void { if (root.focusedContainer) root.listKeyRequested(root.focusedContainer); }
    }

    // from the right button of an icon of the bar
    function openMenuAt(group, tab, x, y) {
        root.closeList();
        menu.group = group;
        menu.tab = tab;
        menu.openAt(x - menu.panelWidth / 2, y + 4);
    }
    TabMenu {
        id: menu
        onCloseRequested: id => root.closeTab(id)
        onMoveRequested: (tab, places) => root.moveTab(tab, places)
    }

    TabList {
        id: list
        onPicked: id => { root.focusTab(id); list.visible = false; }
        onTabClosed: id => root.closeTab(id)
    }
}
