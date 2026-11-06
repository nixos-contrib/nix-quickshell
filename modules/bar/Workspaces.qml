import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The workspaces of i3 as squares: the one in use is a lighter block, the others only their number, and an urgent one is red. After the
// number, the windows of the workspace, the same for every one: an icon for each (the one in front, or the one with the focus, lit), and
// a title when the pointer stays on it. The windows that are side by side are one group. A tabbed container is a group of its own, with a
// chevron that opens the list of its tabs, see modules/tabs, and a line is between the groups
RowLayout {
    id: row
    spacing: Theme.spaceXs
    // the tabs of the shell, which has the windows; null when there are none
    property var tabs: null
    // a click on the chevron: the group, and where its list hangs from, in points of the screen
    signal listRequested(var container, real x, real y)

    // the chevrons that are in the bar, by the id of their group, for the list of a key to hang from one
    property var chevrons: ({})
    function openListFor(group) {
        const c = row.chevrons[group.id];
        if (!c)
            return;
        const p = c.mapToItem(null, 0, 0);
        row.listRequested(group, p.x, p.y + c.height);
    }
    // the icons of a group: more than this are a count
    readonly property int shown: 3
    function iconFor(cls) {
        const entry = DesktopEntries.heuristicLookup(cls) ?? DesktopEntries.byId(cls.toLowerCase());
        return Quickshell.iconPath(entry ? entry.icon : cls.toLowerCase(), "application-x-executable");
    }

    Tip { id: tip }

    Repeater {
        model: I3.workspaces
        delegate: RowLayout {
            id: item
            required property I3Workspace modelData
            // its groups, in the order of the screen
            readonly property var groups: row.tabs ? (row.tabs.workspaceGroups[modelData.name] ?? []) : []
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

            Repeater {
                model: item.groups
                delegate: Row {
                    id: group
                    required property var modelData
                    required property int index
                    spacing: 2
                    Layout.leftMargin: 2

                    // the line between two groups
                    Rectangle {
                        visible: group.index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: Theme.tile - 12
                        color: Theme.barMuted
                        opacity: 0.4
                    }
                    Repeater {
                        model: group.modelData.tabs.slice(0, row.shown)
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
                            // a tab that is a split of several windows: how many
                            Rectangle {
                                visible: chip.modelData.count > 1
                                anchors { right: parent.right; bottom: parent.bottom; margins: 1 }
                                width: 13
                                height: 13
                                radius: 7
                                color: Theme.barMuted
                                Text {
                                    anchors.centerIn: parent
                                    text: chip.modelData.count
                                    color: Theme.barBg
                                    font { family: Theme.font; pixelSize: 9; weight: Font.Bold }
                                }
                            }
                            // an urgent window
                            Rectangle { visible: chip.modelData.urgent; anchors { right: parent.right; top: parent.top; margins: 3 } width: 6; height: 6; radius: 3; color: Theme.critical }
                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { tip.hide(); row.tabs.focusTab(chip.modelData.id); }
                                onContainsMouseChanged: containsMouse ? tip.show(chip, chip.modelData.count > 1 ? chip.modelData.name + " and " + (chip.modelData.count - 1) + " more" : chip.modelData.name) : tip.hide()
                            }
                        }
                    }
                    // more than the icons: the count
                    Label {
                        visible: group.modelData.tabs.length > row.shown
                        anchors.verticalCenter: parent.verticalCenter
                        role: "caption"
                        text: "+" + (group.modelData.tabs.length - row.shown)
                        color: Theme.barMuted
                    }
                    // the chevron of the list, only for tabs
                    Rectangle {
                        id: chevron
                        visible: group.modelData.stack
                        Component.onCompleted: row.chevrons[group.modelData.id] = chevron
                        Component.onDestruction: if (row.chevrons[group.modelData.id] === chevron) delete row.chevrons[group.modelData.id]
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
                                tip.hide();
                                const p = chevron.mapToItem(null, 0, 0);
                                row.listRequested(group.modelData, p.x, p.y + chevron.height);
                            }
                        }
                    }
                }
            }
        }
    }
}
