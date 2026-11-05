import QtQuick
import QtQuick.Layouts
import Quickshell.I3
import qs

// The workspaces of i3 as squares: the one in use is a lighter block, the others only their number, and an urgent one is red
RowLayout {
    spacing: Theme.spaceXs

    Repeater {
        model: I3.workspaces
        delegate: Rectangle {
            id: tile
            required property I3Workspace modelData

            Layout.preferredWidth: Theme.tile
            Layout.preferredHeight: Theme.tile
            radius: Theme.radiusSm
            color: modelData.urgent ? Theme.critical : (modelData.focused ? Theme.barFocus : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: tile.modelData.name
                color: tile.modelData.urgent ? Theme.textOnPrimary : (tile.modelData.focused || tile.modelData.active ? Theme.barText : Theme.barMuted)
                font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Medium }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.modelData.activate()
            }
        }
    }
}
