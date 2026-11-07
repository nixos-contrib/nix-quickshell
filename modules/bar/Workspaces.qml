import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The workspaces of i3 as squares: the one in use is a lighter block, the others only their number, and an urgent one is red. After the
// number, the windows of the workspace, the same for every one: an icon for each (the one in front, or the one with the focus, lit), and
// a title when the pointer stays on it. The windows that are side by side are one group. A tabbed container is a group of its own, with a
// chevron that opens the list of its tabs, see modules/tabs, and a line is between the groups. A group of more than five windows is one icon,
// the one in front, with the same chevron.
// On an icon: a click takes its window to the front, the right button opens a menu (close, move), and a drag along a group of tabs
// moves the tab to where it is let go. The wheel on a group goes from one window to the next
RowLayout {
    id: row
    spacing: Theme.spaceXs
    // the tabs of the shell, which has the windows; null when there are none
    property var tabs: null
    // a click on the chevron: the group, and where its list hangs from, in points of the screen: the left edge of the number of its workspace, and
    // the bottom of the bar
    signal listRequested(var container, real x, real y)
    // the right button on an icon: the group, the tab, and where its menu hangs from
    signal menuRequested(var group, var tab, real x, real y)

    // the chevrons that are in the bar, by the id of their group, for the list of a key to hang from one
    property var chevrons: ({})
    function openListFor(group) {
        const c = row.chevrons[group.id];
        if (!c)
            return;
        const p = c.owner.mapToItem(null, 0, 0);
        row.listRequested(group, p.x, p.y + c.owner.height);
    }
    // a group of more windows than this is collapsed: the icon of the one in front, and the chevron of the list, which has them all. There
    // is no count: the list and the tip say how many
    readonly property int shown: 5
    function collapsed(group) { return group.tabs.length > row.shown; }
    // the icons of a group: all of them, or the one in front (the first, when none is) of a collapsed one
    function visibleTabs(group) {
        if (!row.collapsed(group))
            return group.tabs;
        return [group.tabs.find(t => t.current) ?? group.tabs[0]];
    }
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
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }

                Text {
                    anchors.centerIn: parent
                    text: item.modelData.name
                    color: item.modelData.urgent ? Theme.textOnPrimary : (item.modelData.focused || item.modelData.active ? Theme.barText : Theme.barMuted)
                    font { family: Theme.font; pixelSize: Theme.fontBar; weight: Font.Normal }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.modelData.activate()
                }
            }

            // keyed by the id of the group: a change of a title or of the tab in front updates the icons and does not make them again,
            // which a drag in the middle of it would not survive
            Repeater {
                model: ScriptModel { values: item.groups; objectProp: "id" }
                delegate: Row {
                    id: group
                    required property var modelData
                    required property int index
                    spacing: 2
                    Layout.leftMargin: 2

                    // the wheel on the group: the next window, or the one before it. A turn of a notch is a step, and a touchpad that
                    // sends many small ones adds them up
                    WheelHandler {
                        id: wheel
                        property real sum: 0
                        enabled: group.modelData.tabs.length > 1
                        onWheel: event => {
                            sum += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                            if (Math.abs(sum) >= 120) {
                                if (!pause.running) {
                                    row.tabs.cycle(group.modelData, sum < 0 ? 1 : -1);
                                    pause.restart();
                                }
                                sum = 0;
                            }
                        }
                    }
                    Timer { id: pause; interval: 150 }

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
                        model: ScriptModel { values: row.visibleTabs(group.modelData); objectProp: "id" }
                        delegate: Rectangle {
                            id: chip
                            required property var modelData
                            // where it is in the group, for the drag
                            readonly property int place: group.modelData.tabs.findIndex(t => t.id === modelData.id)
                            width: Theme.tile
                            height: Theme.tile
                            radius: Theme.radiusSm
                            color: modelData.current ? Theme.barFocus : (chipArea.containsMouse ? Qt.alpha(Theme.barFocus, 0.5) : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                            // a drag takes the icon with the pointer
                            z: drag.active ? 2 : 0
                            // how far it was dragged, kept: the handler says 0 again when the drag ends
                            property real dragged: 0
                            transform: Translate { x: drag.active ? chip.dragged : 0 }
                            opacity: drag.active ? 0.85 : 1

                            Image {
                                anchors.centerIn: parent
                                source: row.iconFor(chip.modelData.cls)
                                sourceSize: Qt.size(48, 48)
                                width: Theme.statusIcon
                                height: Theme.statusIcon
                                fillMode: Image.PreserveAspectFit
                                opacity: chip.modelData.current ? 1 : 0.75
                            }
                            // an urgent window
                            Rectangle { visible: chip.modelData.urgent; anchors { right: parent.right; top: parent.top; margins: 3 } width: 6; height: 6; radius: 3; color: Theme.critical }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    tip.hide();
                                    if (mouse.button === Qt.RightButton) {
                                        const p = chip.mapToItem(null, 0, 0);
                                        row.menuRequested(group.modelData, chip.modelData, p.x + chip.width / 2, p.y + chip.height);
                                    } else {
                                        row.tabs.focusTab(chip.modelData.id);
                                    }
                                }
                                onContainsMouseChanged: {
                                    if (!containsMouse || drag.active)
                                        tip.hide();
                                    else
                                        tip.show(chip, row.collapsed(group.modelData) ? chip.modelData.name + " and " + (group.modelData.tabs.length - 1) + " more" : (chip.modelData.count > 1 ? chip.modelData.name + " and " + (chip.modelData.count - 1) + " more" : chip.modelData.name));
                                }
                            }
                            // along a group of tabs: the tab goes as many places as it was dragged, one for the width of an icon, and
                            // never out of the group
                            DragHandler {
                                id: drag
                                enabled: group.modelData.stack && group.modelData.tabs.length > 1 && !row.collapsed(group.modelData)
                                target: null
                                yAxis.enabled: false
                                onTranslationChanged: if (active) chip.dragged = translation.x
                                onActiveChanged: {
                                    tip.hide();
                                    if (active) {
                                        chip.dragged = 0;
                                        return;
                                    }
                                    const step = Theme.tile + 2;
                                    let places = Math.round(chip.dragged / step);
                                    places = Math.max(-chip.place, Math.min(group.modelData.tabs.length - 1 - chip.place, places));
                                    if (places !== 0)
                                        row.tabs.moveTab(chip.modelData, places);
                                }
                            }
                        }
                    }
                    // the chevron of the list, for tabs and for a collapsed group
                    Rectangle {
                        id: chevron
                        // the number of the workspace, which the list lines up with
                        property Item owner: tile
                        visible: group.modelData.stack || row.collapsed(group.modelData)
                        Component.onCompleted: row.chevrons[group.modelData.id] = chevron
                        Component.onDestruction: if (row.chevrons[group.modelData.id] === chevron) delete row.chevrons[group.modelData.id]
                        width: Theme.tile
                        height: Theme.tile
                        radius: Theme.radiusSm
                        color: chevronArea.containsMouse ? Theme.barFocus : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        ChevronIcon { anchors.centerIn: parent; size: 14; color: chevronArea.containsMouse ? Theme.barText : Theme.barMuted }
                        MouseArea {
                            id: chevronArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tip.hide();
                                const p = chevron.owner.mapToItem(null, 0, 0);
                                row.listRequested(group.modelData, p.x, p.y + chevron.owner.height);
                            }
                        }
                    }
                }
            }
        }
    }
}
