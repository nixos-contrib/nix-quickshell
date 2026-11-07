import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// A notification of the history: the same card as the toast, without its timer, and it says how long ago it came. It is the slot of the card in the list too: the
// room of the card, and of what goes with it, as the stack of the toasts has it. The group of its app is more than two: the newest card stands for
// them, with two edges under it and its count as a badge, and when the list is open its header is above the first card
Item {
    id: card
    required property int index
    required property string appName
    required property string summary
    required property string body
    required property string picture
    required property bool critical
    required property int time

    property int groupCount: 1
    // the newest of its app, which is the one that stands for the group
    property bool groupHead: true
    property bool groupOpen: false
    property bool shown: true
    // the room at each side that the list has for the shadows of the cards: the card is inside of it, and the list does not move its delegates
    property real inset: 0
    readonly property bool grouped: groupCount > 2 && groupHead
    // a card that stands for the others, and the first card of a group that is open, which has its header above it
    readonly property bool collapsed: grouped && !groupOpen
    readonly property bool headed: grouped && groupOpen
    readonly property real lead: headed ? groupHeader.height + Theme.spacing : 0
    readonly property real peek: collapsed ? 12 : 0
    signal toggleGroup
    signal groupRemoved

    readonly property bool hovered: hover.containsMouse || closeArea.containsMouse || groupBadge.over

    width: ListView.view ? ListView.view.width : 340
    implicitHeight: lead + face.height + peek
    // the list puts its space between the cards, so a card that is not shown has the negative of it
    height: shown ? implicitHeight : -(ListView.view ? ListView.view.spacing : 0)
    visible: shown

    GroupHeader {
        id: groupHeader
        visible: card.headed
        x: card.inset
        width: card.width - card.inset * 2
        app: card.appName
        count: card.groupCount
        onShowLess: card.toggleGroup()
        onClearAll: card.groupRemoved()
    }
    // the edges of the cards that are folded under this one
    Rectangle {
        visible: card.collapsed
        z: -2
        x: card.inset + 20
        y: card.lead + 12
        width: card.width - card.inset * 2 - 40
        height: face.height
        radius: Theme.radiusLg
        color: Theme.surface
        border { width: 1; color: Theme.border }
    }
    Rectangle {
        visible: card.collapsed
        z: -1
        x: card.inset + 10
        y: card.lead + 6
        width: card.width - card.inset * 2 - 20
        height: face.height
        radius: Theme.radiusLg
        color: Theme.surface
        border { width: 1; color: Theme.border }
    }

    Rectangle {
        id: face
        x: card.inset
        y: card.lead
        width: card.width - card.inset * 2
        implicitHeight: content.implicitHeight + Theme.spacing * 2
        height: implicitHeight
        radius: Theme.radiusLg
        color: Theme.surface
        border { width: 1; color: card.hovered ? Theme.primary : Theme.border }
        Behavior on border.color { ColorAnimation { duration: Theme.motionFast } }
        Shadow {}

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
        // the card that stands for a group opens its list
        TapHandler { enabled: card.collapsed; acceptedButtons: Qt.LeftButton; onTapped: card.toggleGroup() }

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
                    Layout.rightMargin: card.hovered && !card.collapsed ? 26 : 0
                    spacing: 6
                    Text {
                        text: card.appName
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Normal; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: Clock.ago(card.time)
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: Theme.fontSmall }
                    }
                    GroupBadge {
                        id: groupBadge
                        visible: card.collapsed
                        count: card.groupCount
                        active: card.hovered
                        onClear: card.groupRemoved()
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

        // Takes the card out of the history, shown while the pointer is over it. The card that stands for a group has the badge instead
        Rectangle {
            width: 22
            height: 22
            radius: 11
            anchors { top: parent.top; right: parent.right; margins: Theme.spacing - 2 }
            color: closeArea.containsMouse ? Theme.surfaceHigh : Theme.bg
            border { width: 1; color: Theme.border }
            opacity: card.hovered && !card.collapsed ? 1 : 0
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
                enabled: !card.collapsed
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.ListView.view.model.remove(card.index)
            }
        }
    }
}
