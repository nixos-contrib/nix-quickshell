import QtQuick
import Quickshell
import Quickshell.Io

// Tells that the pointer was pressed outside of the shell while a popup is open, anywhere: on an app, on the wallpaper, where no window
// is. Focus is not enough for that: a click on the wallpaper takes the focus from no one. While active it listens to the raw presses of
// the buttons of X (xinput), and for each one asks what window is under the pointer (xdotool): a window of the shell (nshell-...,
// the bar, which is the strip at the top) is not outside, and anything else, the root window of the wallpaper included, is. The click itself goes on to what it was
// on, so that the first click on an app both closes the popup and is the click of the app
Scope {
    id: root
    property bool active: false
    // the strip at the top that is the bar, in pixels of the screen: a click there is for the items of the bar, which close and open
    // the popups themselves
    property real barHeight: 0
    signal outside

    function press() {
        if (!probe.running)
            probe.running = true;
    }

    // The raw press comes with its button in the line that follows it: the wheel (4 to 7) is not a click
    property bool pending: false
    Process {
        running: root.active
        command: ["xinput", "test-xi2", "--root"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("RawButtonPress") !== -1) {
                    root.pending = true;
                } else if (root.pending && line.indexOf("detail:") !== -1) {
                    root.pending = false;
                    const button = parseInt(line.split(":")[1]);
                    if (button >= 1 && button <= 3)
                        root.press();
                }
            }
        }
    }

    // Where the pointer is, and the name of the window under it. The root window has none
    Process {
        id: probe
        command: ["sh", "-c", "loc=$(xdotool getmouselocation --shell); echo \"$loc\"; xdotool getwindowname \"$(echo \"$loc\" | sed -n 's/^WINDOW=//p')\" 2>/dev/null | sed 's/^/NAME=/'; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let y = 0, name = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("Y="))
                        y = parseInt(line.substring(2));
                    else if (line.startsWith("NAME="))
                        name = line.substring(5).trim();
                }
                if (root.active && y >= root.barHeight && !name.startsWith("nshell") && name !== "polkit")
                    root.outside();
            }
        }
    }
}
