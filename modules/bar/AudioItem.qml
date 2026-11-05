import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.modules.common

// The sound of the VM in the bar: a speaker that says the volume, a click opens the volume and the outputs, the wheel changes the
// volume and the right button, or the middle one, mutes
Rectangle {
    id: item
    property Popover popover
    signal toggled(real x)

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    PwObjectTracker { objects: item.sink ? [item.sink] : [] }

    visible: sink !== null
    Layout.preferredWidth: Theme.statusIcon + Theme.tilePad * 2
    Layout.preferredHeight: Theme.slot
    radius: Theme.tileRadius
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    SpeakerIcon {
        anchors.centerIn: parent
        level: item.volume
        muted: item.muted
        color: item.muted ? Theme.barMuted : Theme.barText
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            // the right button mutes, as on the bell it silences the notifications, and the middle button does the same: a
            // trackpad has no middle button
            if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
                if (item.sink && item.sink.audio)
                    item.sink.audio.muted = !item.sink.audio.muted;
            } else {
                item.toggled(item.mapToItem(null, 0, 0).x);
            }
        }
        onWheel: wheel => {
            if (item.sink && item.sink.audio)
                item.sink.audio.volume = Math.max(0, Math.min(1, item.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }
}
