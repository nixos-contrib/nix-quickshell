import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.modules.common

// One notification as a card: the app, the summary, the body and its actions. Critical ones stay until dismissed
Rectangle {
    id: root
    required property Notification notification
    // a popup of the bar is open and the toast waits: its time starts when it is shown
    property bool paused: false
    // The close button has a hover area of its own, which takes the pointer from the one of the card: the card counts
    // as hovered over either, or it would hide the button the pointer is on, and blink
    readonly property bool hovered: hover.containsMouse || closeArea.containsMouse
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property int timeout: notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : (notification.urgency === NotificationUrgency.Low ? 4000 : 7000)

    width: parent ? parent.width : 400
    implicitHeight: content.implicitHeight + Theme.spacing * 2
    height: implicitHeight
    radius: Theme.radiusLg
    color: Theme.surface
    border.width: 1
    border.color: root.hovered ? Theme.primary : Theme.border
    opacity: 0
    x: 24

    Component.onCompleted: {
        opacity = 1;
        x = 0;
    }
    Behavior on opacity { NumberAnimation { duration: 180 } }
    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Shadow {}

    // The strip at the left says how urgent it is
    Rectangle {
        width: 3
        radius: 2
        color: root.critical ? Theme.critical : Theme.primary
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: Theme.spacing }
    }

    // Time to live: stops while the pointer is over the card, and critical ones do not run out
    Timer {
        interval: root.timeout
        running: root.visible && !root.paused && !root.critical && !root.hovered
        onTriggered: root.notification.expire()
    }

    // A click does what the app asks for by default, such as focusing the chat, and the card goes with it: invoking an
    // action closes a notification, unless the app marks it as resident. Without a default action it only closes. The
    // middle button only closes
    function activate() {
        const action = root.notification.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        else
            root.notification.dismiss();
    }

    // The hover is a MouseArea: the HoverHandler kept its state when the pointer left the window
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.activate() }
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: root.notification.dismiss() }

    // The close button shows while the pointer is over the card, as in macOS. A critical card does not run out, so it
    // always has it
    Rectangle {
        id: close
        readonly property bool shown: root.hovered || root.critical
        width: 22
        height: 22
        radius: 11
        anchors { top: parent.top; right: parent.right; margins: Theme.spacing - 2 }
        color: closeArea.containsMouse ? Theme.surfaceHigh : Theme.bg
        border { width: 1; color: Theme.border }
        opacity: shown ? 1 : 0
        visible: opacity > 0
        z: 2
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "\u2715"
            color: closeArea.containsMouse ? Theme.text : Theme.muted
            font { pixelSize: 10; weight: Font.Normal }
        }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.notification.dismiss()
        }
    }

    RowLayout {
        id: content
        anchors { fill: parent; margins: Theme.spacing; leftMargin: Theme.spacing + 12 }
        spacing: Theme.spacing + 2

        Image {
            readonly property string picture: Pictures.of(root.notification.image, root.notification.appIcon, root.notification.appName, root.notification.desktopEntry)
            visible: picture !== ""
            source: picture
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

            Text {
                text: root.notification.appName
                color: Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Normal; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.rightMargin: 24
            }
            Text {
                text: root.notification.summary
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: text !== ""
                text: root.notification.body
                color: Theme.text
                opacity: 0.8
                textFormat: Text.StyledText
                font { family: Theme.font; pixelSize: Theme.fontBody }
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Flow {
                visible: root.notification.actions.some(a => a.identifier !== "default")
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 4
                Repeater {
                    model: root.notification.actions
                    delegate: Rectangle {
                        required property NotificationAction modelData
                        visible: modelData.identifier !== "default"
                        implicitWidth: label.implicitWidth + 24
                        implicitHeight: 30
                        radius: Theme.radiusMd
                        color: press.pressed ? Theme.accent : (btn.hovered ? Theme.surfaceHigh : Theme.bg)
                        border { width: 1; color: Theme.border }
                        HoverHandler { id: btn }
                        TapHandler { id: press; onTapped: modelData.invoke() }
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.text
                            color: press.pressed ? Theme.textOnAccent : Theme.primary
                            font { family: Theme.font; pixelSize: Theme.fontSmall + 1; weight: Font.Normal }
                        }
                    }
                }
            }
        }
    }
}
