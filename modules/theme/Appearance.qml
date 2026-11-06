import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The mode of the theme, dark or light: the choice is dark, light or auto, and auto follows the hours of the day. It is kept in a
// file of the state folder, so it is the same after the shell starts again, and it is changed from outside with `nshell theme`
Scope {
    id: root
    // dark, light or auto: what the file of the theme says, until a choice of `nshell theme` kept in the state folder replaces it. A
    // shell that was not told is dark
    property string choice: Theme.user.mode || "dark"
    // auto is light from this hour of the day until the other
    readonly property int lightFrom: Theme.user.hours ? Theme.user.hours.light ?? 7 : 7
    readonly property int darkFrom: Theme.user.hours ? Theme.user.hours.dark ?? 19 : 19

    property date now: new Date()
    Timer {
        interval: 60000
        repeat: true
        running: root.choice === "auto"
        onTriggered: root.now = new Date()
    }
    readonly property string resolved: choice === "auto" ? (now.getHours() >= lightFrom && now.getHours() < darkFrom ? "light" : "dark") : choice
    Binding {
        target: Theme
        property: "mode"
        value: root.resolved
    }

    function set(value: string): bool {
        if (value !== "dark" && value !== "light" && value !== "auto")
            return false;
        root.choice = value;
        // a choice of the hours is read now, and not a minute from now
        root.now = new Date();
        root.save();
        return true;
    }

    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nix-quickshell/theme.json"
    function save() {
        store.setText(JSON.stringify({ mode: root.choice }));
    }
    FileView {
        id: store
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const mode = JSON.parse(text()).mode;
                if (mode === "dark" || mode === "light" || mode === "auto")
                    root.choice = mode;
            } catch (err) {
                console.log("theme: the saved mode could not be read:", err);
            }
        }
    }
    // The apps follow the mode: `nshell apps` puts the colors of the mode where they read them, and tells them to read them again
    function apply() {
        Quickshell.execDetached([Quickshell.env("NSHELL_BIN") || "nshell", "apps", root.resolved]);
    }
    onResolvedChanged: apply()
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.statePath.substring(0, root.statePath.lastIndexOf("/"))]);
        apply();
    }

    // nshell theme [dark|light|auto|toggle]: toggle flips what is shown, and an auto becomes the choice it showed
    IpcHandler {
        target: "theme"
        function set(mode: string): string { return root.set(mode) ? root.choice : "usage: nshell theme [dark|light|auto|toggle]"; }
        function toggle(): string {
            root.set(Theme.mode === "dark" ? "light" : "dark");
            return root.choice;
        }
        function get(): string { return root.choice + (root.choice === "auto" ? " (" + root.resolved + ")" : ""); }
    }
}
