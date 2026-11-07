import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.modules.common

// What is playing, in the bar: the button of the active player, a pause while it plays and a play while it is paused, as the popup has it, and its
// title and artist when the pointer stays on it. A click opens the player, the right button or the middle one plays and pauses, and the wheel is the volume of the player when it has one. It is not there when
// nothing plays, and when the player is stopped
Rectangle {
    id: item
    property Popover popover
    signal toggled(real x)

    readonly property var player: Media.active
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing

    visible: Media.present
    Layout.preferredWidth: Theme.statusIcon + Theme.tilePad * 2
    Layout.preferredHeight: Theme.slot
    radius: Theme.radiusSm
    color: area.pressed || (popover && popover.visible) ? Theme.barFocus : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    // what a right click does, as the main button of the popup: a pause while it plays, a play while it is paused
    MediaIcon {
        anchors.centerIn: parent
        kind: item.playing ? "pause" : "play"
        color: Theme.barText
    }
    Tip { id: tip }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onEntered: tip.show(item, Media.summary)
        onExited: tip.hide()
        onClicked: mouse => {
            tip.hide();
            if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
                if (item.player && item.player.canTogglePlaying)
                    item.player.togglePlaying();
            } else {
                item.toggled(item.mapToItem(null, 0, 0).x);
            }
        }
        onWheel: wheel => {
            if (item.player && item.player.volumeSupported)
                item.player.volume = Math.max(0, Math.min(1, item.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }
}
