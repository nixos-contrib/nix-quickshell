import QtQuick
import Quickshell.Io

// Tells if a window lost the focus for real. The window says that it did when a key grab starts, as i3 does while a key that it
// binds is held: X sends a FocusOut with the mode NotifyGrab, which Qt gives to QML as a loss of focus, and a window that closes
// on a loss of focus closed in the middle of a held Mod+Shift+d. So the loss is checked with i3, which knows who has the focus: if
// it is still this window the loss was the grab, and if it is another one it was a click, and lost() is sent.
QtObject {
    id: guard
    // the title of the window to look after
    property string windowName

    signal lost

    function check() {
        if (!probe.running)
            probe.running = true;
    }

    function holdsFocus(node) {
        if (node.focused && node.name === guard.windowName)
            return true;
        for (const child of (node.nodes ?? []).concat(node.floating_nodes ?? []))
            if (guard.holdsFocus(child))
                return true;
        return false;
    }

    property Process probe: Process {
        command: ["i3-msg", "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!guard.holdsFocus(JSON.parse(text)))
                        guard.lost();
                } catch (e) {
                    // i3 could not be asked: the loss is taken as it came
                    guard.lost();
                }
            }
        }
    }
}
