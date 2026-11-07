import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// The header of a group that is open, above its cards and outside of them: the app and how many, and the two things to do with all of them, as
// the footer of the stack has them: close the list, and clear it
Item {
    id: header
    property string app: ""
    property int count: 0
    signal showLess
    signal clearAll

    implicitHeight: 30

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        Text {
            text: header.app + " · " + header.count
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Normal; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
            elide: Text.ElideRight
            Layout.fillWidth: true
            leftPadding: 4
        }
        PillButton { text: "Show less"; implicitHeight: 26; onClicked: header.showLess() }
        PillButton { text: "Clear all"; implicitHeight: 26; onClicked: header.clearAll() }
    }
}
