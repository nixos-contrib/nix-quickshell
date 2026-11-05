import QtQuick
import QtQuick.Layouts
import qs

// The container of every window of the shell, with the same parts in the same order:
//   the header   a title at the left, then a value (muted) or buttons at the right. Or a header of its own, the search field
//   a divider    one line under the header, and none other
//   the body     what the window is about. An empty state is centered in it
//   the footer   a hint, at the bottom left, small and muted
// The color, the radius, the border and the room around are the same for all of them
Rectangle {
    id: panel
    property string title
    property string value
    property string footer
    // the room around, the same for all but a menu, which is a list of lines with room of their own, and a dialog
    property int padding: Theme.panelPadding
    // the body takes what is left when the panel has a size of its own, and is as tall as its content when it has not
    property bool fillBody: false
    // a header of its own, instead of the title
    property alias header: custom.data
    // buttons at the right of the title
    property alias actions: actionRow.data
    default property alias content: body.data

    readonly property bool hasHeader: title !== "" || custom.children.length > 0
    // what the panel takes besides the body, so that a body can be as tall as what is left
    readonly property real chromeHeight: padding * 2 + (hasHeader ? headerBox.implicitHeight + 1 + Theme.spaceMd * 2 : 0) + (footer !== "" ? footerLabel.implicitHeight + Theme.spaceMd : 0)

    implicitHeight: col.implicitHeight + padding * 2
    radius: Theme.radiusLg
    color: Theme.bg
    border { width: 1; color: Theme.border }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: panel.padding }
        spacing: Theme.spaceMd

        Item {
            id: headerBox
            visible: panel.hasHeader
            Layout.fillWidth: true
            implicitHeight: Math.max(titleRow.implicitHeight, custom.childrenRect.height)

            RowLayout {
                id: titleRow
                visible: panel.title !== ""
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Theme.spaceSm
                Label {
                    role: "title"
                    text: panel.title
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    visible: panel.value !== ""
                    role: "caption"
                    text: panel.value
                }
                Row {
                    id: actionRow
                    spacing: Theme.spaceSm
                }
            }
            Item {
                id: custom
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: childrenRect.height
            }
        }

        Rectangle {
            visible: panel.hasHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: panel.fillBody
            implicitHeight: panel.fillBody ? 0 : childrenRect.height
        }

        Label {
            id: footerLabel
            visible: panel.footer !== ""
            role: "caption"
            text: panel.footer
        }
    }
}
