import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

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

    // The group of its app, as the stack has it: more than two are one card, the newest, with the count in its header, and a click opens the
    // list. The others are not shown, and take no room: the list puts its space between the cards, so a card that is not shown has the
    // negative of it
    property int groupCount: 1
    property bool groupHead: true
    property bool groupOpen: false
    property bool shown: true
    readonly property bool isGroup: groupCount > 2 && groupHead
    readonly property bool collapsed: isGroup && !groupOpen
    signal toggleGroup
    signal groupRemoved

    readonly property bool hovered: hover.containsMouse || closeArea.containsMouse

    width: ListView.view ? ListView.view.width : 340
    implicitHeight: content.implicitHeight + Theme.spacing * 2
    height: shown ? implicitHeight : -(ListView.view ? ListView.view.spacing : 0)
    visible: shown
    radius: Theme.radiusMd
    color: Theme.surface
    border { width: 1; color: card.hovered ? Theme.primary : Theme.border }
    Behavior on border.color { ColorAnimation { duration: Theme.motionFast } }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
    // the card of a group opens and closes it
    TapHandler { enabled: card.isGroup; acceptedButtons: Qt.LeftButton; onTapped: card.toggleGroup() }

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
                    font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Normal; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: card.isGroup
                    text: card.groupCount
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontSmall }
                }
                ChevronIcon {
                    visible: card.isGroup
                    size: 12
                    rotation: card.groupOpen ? 180 : 0
                    color: Theme.muted
                    Behavior on rotation { NumberAnimation { duration: Theme.motionFast } }
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
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
        Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeArea.containsMouse ? Theme.text : Theme.muted
            font { pixelSize: 10; weight: Font.Normal }
        }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // the card of a folded group takes all of its app out, as it stands for them
            onClicked: card.collapsed ? card.groupRemoved() : card.ListView.view.model.remove(card.index)
        }
    }
}
