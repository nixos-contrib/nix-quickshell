import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Do not disturb for the sounds that apps play themselves. A chat app plays its ping on its own, the notification server has
// nothing to do with it. So the sound effects of the apps that are listed, their "Playback" streams, are muted while do not
// disturb is on and have their sound while it is off. The audio of a call is another stream and is not touched.
//
// Two things make it a loop and not one write. A stream accepts the mute a moment after it appears, when its parameters are there.
// And the session manager remembers the mute of an app and restores it on its next stream, so while do not disturb is off the
// effects are unmuted too, and not only the ones that were muted here
Scope {
    id: root
    // do not disturb is on
    property bool active: false
    // the names of the apps, in lower case, as their streams call them
    property var apps: ["vesktop", "discord"]

    // every stream: its audio and its properties arrive a moment after the stream itself
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream)
    // the properties of a node are there when the node is bound
    PwObjectTracker { objects: root.streams }

    function quiet(node: var): bool {
        const p = node.properties;
        const app = String(p["application.name"] ?? p["application.process.binary"] ?? "").toLowerCase();
        return root.apps.some(a => app.includes(a)) && p["media.name"] === "Playback";
    }

    function enforce() {
        for (const node of root.streams) {
            if (!node.ready || node.audio === null || !root.quiet(node))
                continue;
            if (root.active && !node.audio.muted)
                node.audio.muted = true;
            else if (!root.active && node.audio.muted)
                node.audio.muted = false;
        }
    }

    // a change, of do not disturb or of the streams, is followed by a couple of seconds of looking
    function settle() {
        enforce();
        burst.left = 20;
        burst.restart();
    }
    onActiveChanged: settle()
    onStreamsChanged: settle()

    Timer {
        id: burst
        property int left: 0
        interval: 100
        repeat: true
        onTriggered: {
            root.enforce();
            if (--left <= 0 && !root.active)
                stop();
        }
    }
    // and without a pause while it is on: a ping can come at any time
    Timer {
        interval: 100
        repeat: true
        running: root.active
        onTriggered: root.enforce()
    }
}
