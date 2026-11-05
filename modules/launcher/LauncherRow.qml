import QtQuick
import QtQuick.Layouts
import qs

// A line of the launcher: the icon, the name and what it is. The current one is filled, as the selected tile of the bar
Rectangle {
    id: row
    required property var modelData
    required property int index
    readonly property bool current: ListView.isCurrentItem
    signal chosen

    width: ListView.view ? ListView.view.width : 600
    height: 52
    radius: Theme.tileRadius + 3
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
            Text {
                text: row.modelData.title
                color: Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
                font { family: Theme.font; pixelSize: Theme.fontTitle + 1; weight: Font.Medium }
            }
            Text {
                visible: text !== ""
                text: row.modelData.subtitle
                color: Theme.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
                font { family: Theme.font; pixelSize: Theme.fontSmall + 1 }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: row.chosen()
    }
}
