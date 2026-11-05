import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.common

// The entries of a menu of the tray: text, icon, check marks, separators. An entry with children has them listed under
// it, indented, as the menus of the apps are short
ColumnLayout {
    id: list
    property var menu
    property int depth: 0
    signal activated

    spacing: 2

    QsMenuOpener {
        id: opener
        menu: list.menu
    }

    Repeater {
        model: opener.children
        delegate: ColumnLayout {
            id: entry
            required property var modelData
            Layout.fillWidth: true
            spacing: 2

            Rectangle {
                visible: entry.modelData.isSeparator
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                color: Theme.border
            }

            Rectangle {
                visible: !entry.modelData.isSeparator
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: Theme.radiusMd
                color: area.containsMouse && entry.modelData.enabled && !entry.modelData.hasChildren ? Theme.surfaceHigh : "transparent"

                RowLayout {
                    anchors { fill: parent; leftMargin: 10 + list.depth * 14; rightMargin: 10 }
                    spacing: 8
                    Text {
                        // a mark for the entries that are checked, and room for it in the ones that can be
                        visible: entry.modelData.buttonType !== QsMenuButtonType.None
                        text: entry.modelData.checkState === Qt.Checked ? "✓" : ""
                        color: Theme.primary
                        Layout.preferredWidth: 12
                        font { family: Theme.font; pixelSize: Theme.textBody }
                    }
                    IconImage {
                        visible: entry.modelData.icon !== ""
                        source: entry.modelData.icon
                        implicitSize: 16
                    }
                    Label {
                        text: entry.modelData.text
                        color: entry.modelData.hasChildren || !entry.modelData.enabled ? Theme.muted : Theme.text
                        strong: entry.modelData.hasChildren
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: entry.modelData.enabled && !entry.modelData.hasChildren
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        entry.modelData.triggered();
                        list.activated();
                    }
                }
            }

            // by file name: a component cannot be instantiated inside itself, but it can be loaded
            Loader {
                active: entry.modelData.hasChildren
                visible: active
                Layout.fillWidth: true
                source: "MenuList.qml"
                onLoaded: {
                    item.menu = entry.modelData;
                    item.depth = list.depth + 1;
                    item.activated.connect(list.activated);
                }
            }
        }
    }
}
