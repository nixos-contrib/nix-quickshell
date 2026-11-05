import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs

// The sound of the VM in the bar: a speaker that says the volume, a click opens the volume and the outputs, the wheel changes the
// volume and the middle button mutes
Rectangle {
    id: item
    property Popover popover
    signal toggled(real x)

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    PwObjectTracker { objects: item.sink ? [item.sink] : [] }

    function glyph() {
        if (muted)
            return "\udb81\udd81";
        if (volume <= 0)
            return "\udb81\udf5f";
        if (volume < 0.34)
            return "\udb81\udd7f";
        if (volume < 0.67)
            return "\udb81\udd80";
        return "\udb81\udd7e";
    }

    visible: sink !== null
    Layout.preferredWidth: Theme.slot
    Layout.preferredHeight: Theme.slot
    radius: Theme.tileRadius
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: item.glyph()
        color: item.muted ? Theme.barMuted : Theme.barText
        font { family: Theme.iconFont; pixelSize: Theme.statusIcon }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
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
