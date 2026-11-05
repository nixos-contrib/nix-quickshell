import QtQuick
import QtQuick.Layouts
import qs

// Under a stack of three cards or more: the button that shows the ones that wait behind, and the one that clears them all
Item {
    id: root
    property int hidden: 0
    property bool expanded: false
    signal toggle
    signal clearAll

    implicitHeight: 30

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        Rectangle {
            visible: root.hidden > 0
            implicitWidth: more.implicitWidth + 24
            implicitHeight: 26
            radius: 13
            color: moreArea.pressed ? Theme.accent : (moreArea.containsMouse ? Theme.surfaceHigh : Theme.surface)
            border { width: 1; color: Theme.border }
            Text {
                id: more
                anchors.centerIn: parent
                text: root.expanded ? "Show less" : "Show " + root.hidden + " more"
                color: moreArea.pressed ? Theme.textOnAccent : Theme.primary
                font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Medium }
            }
            MouseArea {
                id: moreArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggle()
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: clear.implicitWidth + 24
            implicitHeight: 26
            radius: 13
            color: clearArea.pressed ? Theme.accent : (clearArea.containsMouse ? Theme.surfaceHigh : Theme.surface)
            border { width: 1; color: Theme.border }
            Text {
                id: clear
                anchors.centerIn: parent
                text: "Clear all"
                color: clearArea.pressed ? Theme.textOnAccent : Theme.primary
                font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Medium }
            }
            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAll()
            }
        }
    }
}
