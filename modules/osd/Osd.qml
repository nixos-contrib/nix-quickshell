import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Services.Pipewire
import qs
import qs.modules.common

// The volume on the screen, for a moment, when it changes: from a key, the wheel on the bar, the slider or another app. It watches
// the sound and does not ask to be called, so every way to change it shows the same thing. It never takes the focus, and it is gone
// before a click could need what is under its shadow
Scope {
    id: root
    // the popups of the bar show the volume themselves
    property bool suppressed: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    // The values arrive while the shell starts, and when the output changes: that is not a change of the user
    onSinkChanged: settle.restart()
    Timer {
        id: settle
        interval: 800
        running: true
    }
    function bump() {
        if (settle.running || root.suppressed)
            return;
        root.active = true;
        hide.restart();
    }
    onVolumeChanged: bump()
    onMutedChanged: bump()

    property bool active: false
    Timer {
        id: hide
        interval: 1400
        onTriggered: root.active = false
    }

    FloatingWindow {
        id: win
        title: "nshell-osd"
        visible: root.active || card.opacity > 0
        color: "transparent"
        // the room around the pill is for its shadow
        implicitWidth: 260 + Theme.marginHigh * 2
        implicitHeight: 64 + Theme.marginHigh * 2

        // i3 floats the window, at the bottom in the middle, in pixels of the screen, which the scale of Qt multiplies
        function place() {
            const scale = win.devicePixelRatio;
            const x = Math.round((win.screen.width - win.width) / 2 * scale);
            const y = Math.round((win.screen.height - win.height + Theme.marginHigh - 96) * scale);
            I3.dispatch(`[title="^nshell-osd$"] move absolute position ${x}px ${y}px`);
        }
        // drawn when it is in its place, see Popover
        property bool placed: false
        onVisibleChanged: {
            placed = false;
            if (visible)
                placeTimer.restart();
        }
        Timer {
            id: placeTimer
            interval: 60
            onTriggered: {
                win.place();
                revealTimer.restart();
            }
        }
        Timer {
            id: revealTimer
            interval: 60
            onTriggered: win.placed = true
        }

        Rectangle {
            id: card
            anchors { fill: parent; margins: Theme.marginHigh }
            radius: Theme.radiusLg
            color: Theme.bg
            border { width: 1; color: Theme.border }
            opacity: root.active && win.placed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Shadow { elevation: 2 }

            RowLayout {
                anchors { fill: parent; leftMargin: Theme.panelPadding; rightMargin: Theme.panelPadding }
                spacing: Theme.spaceMd
                SpeakerIcon {
                    size: Theme.slot
                    level: root.volume
                    muted: root.muted
                    color: root.muted ? Theme.muted : Theme.text
                }
                Meter {
                    Layout.fillWidth: true
                    value: root.volume
                    color: root.muted ? Theme.muted : Theme.primary
                }
                Label {
                    role: "caption"
                    text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 40
                }
            }
        }
    }
}
