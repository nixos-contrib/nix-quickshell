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

    // The look of a strip that has the width of the workspace and is under the bar: flush, square, as a second row of the bar, or card,
    // the width of its container, rounded. Any other strip is a card. `nshell tabs style` changes it
    property string look: "attached"
    property var lastTree: null

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
    function tabOf(child, front) {
        const leaf = root.leafOf(child);
        return {
            id: child.id,
            name: leaf.name ?? "",
            cls: leaf.window_properties ? (leaf.window_properties.class ?? "") : "",
            current: front,
            urgent: root.anyUrgent(child)
        };
    }
    function collect(node, out, output) {
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
                // attached: lower, against the window, and lower than the reserved strip: a row of 32 points on top of the window
                const attached = root.look === "attached";
                const frontKid = kids.find(k => k.id === front) ?? kids[0];
                const ear = attached ? Math.round(Theme.windowRadius * scale) : 0;
                out.push({
                    id: node.id,
                    attached: attached,
                    full: flush,
                    // the window of the strip, and how far in from its left edge the tabs start
                    x: flush ? output.rect.x : node.rect.x,
                    // the strip is the height of the strip that i3 keeps, and the window is under it with the gap between them: the
                    // attached row is moved down to the window, which leaves the gap above it, the same as the one under the window
                    y: attached ? frontKid.rect.y - strips[0].height : node.rect.y,
                    ear: ear,
                    w: flush ? output.rect.width : node.rect.width,
                    h: strips[0].height,
                    inset: flush ? left : 0,
                    active: root.holdsFocus(node),
                    tabs: kids.map(k => root.tabOf(k, k.id === front))
                });
            }
        }
        for (const c of (node.nodes ?? []).concat(node.floating_nodes ?? []))
            root.collect(c, out, output);
    }
    // only the workspace that each output shows has strips: the tree has the others too
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
                    if (ws.id === shown)
                        root.collect(ws, out, output);
            }
        }
        return out;
    }
    function apply(tree) {
        root.lastTree = tree;
        const built = root.build(tree);
        // the same value does not rebuild the windows
        if (JSON.stringify(built) !== JSON.stringify(root.containers))
            root.containers = built;
        root.focusedContainer = built.find(c => c.active) ?? null;
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
            if (look === "flush" || look === "card" || look === "attached")
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
        model: ScriptModel { values: root.containers; objectProp: "id" }
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
