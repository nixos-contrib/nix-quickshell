import QtQuick
import Quickshell
import qs

// The title that hangs under an item of the bar after the pointer has stayed on it for a moment: show(item, text) and hide(). One for
// the bar, moved from item to item. A window of the popup kind, which i3 does not manage and does not give the focus
PopupWindow {
    id: tip
    property string text: ""
    property Item target: null

    function show(item, label) {
        tip.target = item;
        tip.text = label;
        delay.restart();
    }
    function hide() {
        delay.stop();
        tip.visible = false;
    }

    visible: false
    color: "transparent"
    anchor.item: tip.target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    implicitWidth: Math.min(360, caption.implicitWidth + 24) + Theme.marginLow * 2
    implicitHeight: caption.implicitHeight + 12 + Theme.marginLow * 2

    Timer {
        id: delay
        interval: 450
        onTriggered: tip.visible = tip.target !== null && tip.text !== ""
    }

    Rectangle {
        anchors { fill: parent; margins: Theme.marginLow }
        radius: Theme.radiusMd
        color: Theme.bg
        border { width: 1; color: Theme.border }
        Shadow { elevation: 1 }
        Label {
            id: caption
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 336)
            elide: Text.ElideRight
            role: "caption"
            color: Theme.text
            text: tip.text
        }
    }
}
