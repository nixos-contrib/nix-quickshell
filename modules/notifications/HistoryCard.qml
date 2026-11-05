import QtQuick
import QtQuick.Layouts
import qs

// A notification of the history: the same card as the toast, without its timer, and it says how long ago it came
Rectangle {
    id: card
    required property int index
    required property string appName
    required property string summary
    required property string body
    required property string picture
    required property bool critical
    required property int time

    readonly property bool hovered: hover.containsMouse || closeArea.containsMouse

    width: ListView.view ? ListView.view.width : 340
    implicitHeight: content.implicitHeight + Theme.spacing * 2
    height: implicitHeight
    radius: Theme.radius
    color: Theme.surface
    border { width: 1; color: card.hovered ? Theme.primary : Theme.border }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Rectangle {
        width: 3
        radius: 2
        color: card.critical ? Theme.critical : Theme.primary
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: Theme.spacing }
    }

    RowLayout {
        id: content
        anchors { fill: parent; margins: Theme.spacing; leftMargin: Theme.spacing + 12 }
        spacing: Theme.spacing + 2

        Image {
            visible: card.picture !== ""
            source: card.picture
            sourceSize: Qt.size(96, 96)
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignTop
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: card.hovered ? 26 : 0
                Text {
                    text: card.appName
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Medium; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: Clock.ago(card.time)
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontSmall }
                }
            }
            Text {
                text: card.summary
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: text !== ""
                text: card.body
                color: Theme.text
                opacity: 0.8
                textFormat: Text.StyledText
                font { family: Theme.font; pixelSize: Theme.fontBody }
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // Takes the card out of the history, shown while the pointer is over it
    Rectangle {
        width: 22
        height: 22
        radius: 11
        anchors { top: parent.top; right: parent.right; margins: Theme.spacing - 2 }
        color: closeArea.containsMouse ? Theme.surfaceHigh : Theme.bg
        border { width: 1; color: Theme.border }
        opacity: card.hovered ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeArea.containsMouse ? Theme.text : Theme.muted
            font { pixelSize: 10; weight: Font.Medium }
        }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.ListView.view.model.remove(card.index)
        }
    }
}
