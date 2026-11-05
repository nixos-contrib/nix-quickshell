import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The workspaces of i3 as squares: the one in use is a lighter block, the others only their number, and an urgent one is red. A workspace
// that has a tabbed container shows its windows as the tabs of a group, as in a browser: an icon for each (the front one lit) and a
// chevron that opens the list, see modules/tabs. Only in the group look of the tabs
RowLayout {
    id: row
    spacing: Theme.spaceXs
    // the tabs of the shell, which has the containers; null when there are none
    property var tabs: null
    // a click on the chevron: the container, and where its list hangs from, in points of the screen
    signal listRequested(var container, real x, real y)

    readonly property bool grouped: tabs !== null && tabs.look === "group"
    function iconFor(cls) {
        const entry = DesktopEntries.heuristicLookup(cls) ?? DesktopEntries.byId(cls.toLowerCase());
        return Quickshell.iconPath(entry ? entry.icon : cls.toLowerCase(), "application-x-executable");
    }

    Repeater {
        model: I3.workspaces
        delegate: RowLayout {
            id: item
            required property I3Workspace modelData
            // the tabbed container of the workspace, if it has one
            // a container with one window has nothing to group
            readonly property var container: row.grouped ? (row.tabs.containers.find(c => c.ws === modelData.name && c.tabs.length > 1) ?? null) : null
            spacing: 2

            Rectangle {
                id: tile
                Layout.preferredWidth: Theme.tile
                Layout.preferredHeight: Theme.tile
                radius: Theme.radiusSm
                color: item.modelData.urgent ? Theme.critical : (item.modelData.focused ? Theme.barFocus : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: item.modelData.name
                    color: item.modelData.urgent ? Theme.textOnPrimary : (item.modelData.focused || item.modelData.active ? Theme.barText : Theme.barMuted)
                    font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Medium }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.modelData.activate()
                }
            }

            // the group: up to three windows, the front one lit, and how many more there are
            Row {
                id: group
                visible: item.container !== null
                spacing: 2
                Layout.leftMargin: 2
                Repeater {
                    model: item.container ? item.container.tabs.slice(0, 3) : []
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        width: Theme.tile
                        height: Theme.tile
                        radius: Theme.radiusSm
                        color: modelData.current ? Theme.barFocus : (chipArea.containsMouse ? Qt.alpha(Theme.barFocus, 0.5) : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Image {
                            anchors.centerIn: parent
                            source: row.iconFor(chip.modelData.cls)
                            sourceSize: Qt.size(48, 48)
                            width: 16
                            height: 16
                            fillMode: Image.PreserveAspectFit
                            opacity: chip.modelData.current ? 1 : 0.75
                        }
                        // an urgent window of the group
                        Rectangle { visible: chip.modelData.urgent; anchors { right: parent.right; top: parent.top; margins: 3 } width: 6; height: 6; radius: 3; color: Theme.critical }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: row.tabs.focusTab(chip.modelData.id)
                        }
                    }
                }
                // more than three: the count, and the list with them all
                Label {
                    visible: item.container !== null && item.container.tabs.length > 3
                    anchors.verticalCenter: parent.verticalCenter
                    role: "caption"
                    text: "+" + (item.container ? item.container.tabs.length - 3 : 0)
                    color: Theme.barMuted
                }
                // the chevron of the list
                Rectangle {
                    id: chevron
                    width: Theme.tile
                    height: Theme.tile
                    radius: Theme.radiusSm
                    color: chevronArea.containsMouse ? Theme.barFocus : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    ChevronIcon { anchors.centerIn: parent; size: 14; color: chevronArea.containsMouse ? Theme.barText : Theme.barMuted }
                    MouseArea {
                        id: chevronArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = chevron.mapToItem(null, 0, 0);
                            row.listRequested(item.container, p.x, p.y + chevron.height);
                        }
                    }
                }
            }
        }
    }
}
