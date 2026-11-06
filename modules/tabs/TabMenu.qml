import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.bar
import qs.modules.common

// The menu of an icon of the bar, from its right button: close the window, and for a tab move it one place to the left or to the right.
// A tab that is a split of several windows has no close, which would close them all
Popover {
    id: win
    property var group: null
    property var tab: null
    signal closeRequested(real id)
    signal moveRequested(var tab, int places)

    padding: Theme.spaceSm
    panelWidth: 190

    // where the tab is in its group
    readonly property int slot: group && tab ? group.tabs.findIndex(t => t.id === tab.id) : -1
    readonly property var entries: {
        const out = [];
        if (!tab)
            return out;
        if (tab.count <= 1)
            out.push({ text: "Close", action: "close" });
        if (group && group.stack && slot > 0)
            out.push({ text: "Move left", action: "left" });
        if (group && group.stack && slot >= 0 && slot < group.tabs.length - 1)
            out.push({ text: "Move right", action: "right" });
        return out;
    }
    function run(action) {
        win.visible = false;
        if (action === "close")
            win.closeRequested(win.tab.id);
        else
            win.moveRequested(win.tab, action === "left" ? -1 : 1);
    }

    ColumnLayout {
        width: parent.width
        spacing: 2
        Repeater {
            model: win.entries
            delegate: Rectangle {
                id: entry
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: Theme.radiusMd
                color: area.containsMouse ? Theme.surfaceHigh : "transparent"
                Label {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                    text: entry.modelData.text
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.run(entry.modelData.action)
                }
            }
        }
    }
}
