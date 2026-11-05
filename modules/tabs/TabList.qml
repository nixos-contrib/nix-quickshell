import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.bar
import qs.modules.common

// The list of the windows of a tabbed container, from the button at the end of its strip or from a key: an icon and the title of each,
// and a field that filters them. Up and down choose, Enter takes the window to the front
Popover {
    id: win
    property var container: null
    signal picked(real id)
    signal tabClosed(real id)

    heading: "Tabs"
    headerValue: container ? container.tabs.length + " windows" : ""
    panelWidth: 380

    property int index: 0
    readonly property string query: filter.text.toLowerCase()
    readonly property var rows: (container ? container.tabs : []).filter(t => query === "" || t.name.toLowerCase().indexOf(query) !== -1 || t.cls.toLowerCase().indexOf(query) !== -1)
    onVisibleChanged: if (visible) {
        filter.text = "";
        const front = (container ? container.tabs : []).findIndex(t => t.current);
        index = Math.max(0, front);
        filter.forceActiveFocus();
    }
    function move(d) { if (rows.length > 0) index = (index + d + rows.length) % rows.length; }
    function iconFor(cls) {
        const entry = DesktopEntries.heuristicLookup(cls) ?? DesktopEntries.byId(cls.toLowerCase());
        return Quickshell.iconPath(entry ? entry.icon : cls.toLowerCase(), "application-x-executable");
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceSm

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Theme.radiusMd
            color: Theme.surface
            border { width: 1; color: Theme.border }
            TextInput {
                id: filter
                anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.accent
                font { family: Theme.font; pixelSize: Theme.textBody }
                onTextChanged: win.index = 0
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N)) { win.move(1); event.accepted = true; }
                    else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P)) { win.move(-1); event.accepted = true; }
                    else if (event.key === Qt.Key_Escape) { win.visible = false; event.accepted = true; }
                }
                onAccepted: if (win.rows.length > 0) win.picked(win.rows[win.index].id)
                Text { visible: filter.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Filter windows"; color: Theme.muted; font: filter.font }
            }
        }

        ListView {
            id: view
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 360)
            clip: true
            spacing: 2
            model: win.rows
            currentIndex: win.index
            interactive: contentHeight > height
            delegate: Rectangle {
                id: item
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 48
                radius: Theme.radiusMd
                color: index === win.index ? Theme.surfaceHigh : (area.containsMouse ? Theme.surface : "transparent")
                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceMd }
                    spacing: Theme.spaceMd
                    Image { source: win.iconFor(item.modelData.cls); sourceSize: Qt.size(96, 96); Layout.preferredWidth: 32; Layout.preferredHeight: 32; fillMode: Image.PreserveAspectFit }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { text: item.modelData.name; elide: Text.ElideRight; Layout.fillWidth: true; strong: true }
                        Label { role: "caption"; text: item.modelData.cls; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    Rectangle { visible: item.modelData.urgent; Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: Theme.critical }
                    // the window that is in front
                    Text { visible: item.modelData.current; text: "✓"; color: Theme.primary; font.pixelSize: 13 }
                    Item {
                        Layout.preferredWidth: 20; Layout.preferredHeight: 20
                        opacity: area.containsMouse ? 1 : 0
                        Rectangle { anchors.fill: parent; radius: 10; color: closeArea.containsMouse ? Qt.alpha(Theme.text, 0.14) : "transparent" }
                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.muted; font { pixelSize: 10; weight: Font.Medium } }
                        MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.tabClosed(item.modelData.id) }
                    }
                }
                MouseArea { id: area; anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.picked(item.modelData.id) }
            }
        }
    }
}
