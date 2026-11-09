import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import qs
import qs.modules.common

// The agent of polkit of the session: the card that asks for the touch of the key, or for the password, when something needs to
// be authorized. 1Password unlocking with the system is the case it is made for: a key, a line, the app, and the status of the
// touch. Any other action gets its icon and its sentence. It is a window of its own, in the middle of the screen, and i3
// floats it by its title, see docs/i3.md
Scope {
    id: root
    readonly property var flow: agent.flow

    PolkitAgent {
        id: agent
        onIsRegisteredChanged: console.log("polkit agent registered:", isRegistered)
    }

    FloatingWindow {
        id: win
        title: "polkit"
        visible: agent.isActive
        color: "transparent"
        // the room around the card is for its shadow, and the card is as tall as its content
        implicitWidth: 440 + Theme.marginHigh * 2
        implicitHeight: card.implicitHeight + Theme.marginHigh * 2

        PolkitCard {
            id: card
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.marginHigh }
            flow: root.flow
        }
    }
}
