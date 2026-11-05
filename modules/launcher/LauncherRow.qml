import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// A line of the launcher: the icon, the name and what it is. The current one is filled, as the selected tile of the bar
Rectangle {
    id: row
    required property var modelData
    required property int index
    readonly property bool current: ListView.isCurrentItem
    signal chosen

    width: ListView.view ? ListView.view.width : 600
    height: 52
    radius: Theme.radiusMd
    color: current ? Theme.surfaceHigh : "transparent"

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.spaceMd; rightMargin: Theme.spaceMd }
        spacing: Theme.spaceMd

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Image {
                anchors.fill: parent
                visible: row.modelData.icon !== ""
                source: row.modelData.icon
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                text: row.modelData.title
                strong: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                visible: text !== ""
                role: "caption"
                text: row.modelData.subtitle
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: row.chosen()
    }
}
