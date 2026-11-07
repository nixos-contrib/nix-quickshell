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
    // The group of its app: how many notifications it has. A card that is `collapsed` stands for all of them, and what is done to it is done to
    // all: it opens the list, it is closed with them, and it runs out of time with them. Its count is a badge in its header, and the header of
    // the group above its cards says it when the list is open
    property int groupCount: 1
    property bool collapsed: false
    signal toggleGroup
    signal groupDismissed
    signal groupExpired
    // The close button has a hover area of its own, which takes the pointer from the one of the card: the card counts
    // as hovered over either, or it would hide the button the pointer is on, and blink
    readonly property bool hovered: hover.containsMouse || closeArea.containsMouse || groupBadge.over
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    // The progress that an app sends in the `value` hint, 0 to 100, as a downloads, a copy or a build does: a thin bar in the card. The app sends the
    // same notification again as it goes, and the card is the same one, updated in place
    readonly property var rawValue: notification.hints ? notification.hints["value"] : undefined
    readonly property bool hasProgress: rawValue !== undefined && rawValue !== null && isFinite(Number(rawValue))
    readonly property real progress: hasProgress ? Math.max(0, Math.min(100, Number(rawValue))) / 100 : 0
    // the time that the app asks for, in milliseconds as the protocol has it (Quickshell 0.3.2 gives it as it came, and not in seconds as its docs say), or the
    // one of the shell: a short one for a low urgency
    readonly property int timeout: notification.expireTimeout > 0 ? notification.expireTimeout : (notification.urgency === NotificationUrgency.Low ? 4000 : 7000)

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
    Behavior on opacity { NumberAnimation { duration: Theme.motionBase } }
    Behavior on x { NumberAnimation { duration: Theme.motionSlow; easing.type: Theme.motionEasing } }
    Behavior on border.color { ColorAnimation { duration: Theme.motionFast } }
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
        id: expiry
        interval: root.timeout
        running: root.visible && !root.paused && !root.critical && !root.hovered
        onTriggered: root.collapsed ? root.groupExpired() : root.notification.expire()
    }
    // an app that sends it again as it goes keeps the card: the time starts again with each update
    Connections {
        target: root.notification
        function onHintsChanged() { expiry.restart(); }
        function onSummaryChanged() { expiry.restart(); }
        function onBodyChanged() { expiry.restart(); }
    }

    // A click does what the app asks for by default, such as focusing the chat, and the card goes with it: invoking an
    // action closes a notification, unless the app marks it as resident. Without a default action it only closes. The
    // middle button only closes
    function activate() {
        // the card of a folded group opens the list: the default action is that of this one notification
        if (root.collapsed) {
            root.toggleGroup();
            return;
        }
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
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: root.collapsed ? root.groupDismissed() : root.notification.dismiss() }

    // The close button shows while the pointer is over the card, as in macOS. A critical card does not run out, so it
    // always has it
    Rectangle {
        id: close
        readonly property bool shown: !root.collapsed && (root.hovered || root.critical)
        width: 22
        height: 22
        radius: 11
        anchors { top: parent.top; right: parent.right; margins: Theme.spacing - 2 }
        color: closeArea.containsMouse ? Theme.surfaceHigh : Theme.bg
        border { width: 1; color: Theme.border }
        opacity: shown ? 1 : 0
        visible: opacity > 0
        z: 2
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
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
            onClicked: root.collapsed ? root.groupDismissed() : root.notification.dismiss()
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

            // The app, and for a card that stands for a group its count, which says Clear and the number while the pointer is over the card
            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: root.collapsed ? 0 : 24
                spacing: 6
                Text {
                    text: root.notification.appName
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontSmall; weight: Font.Normal; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                GroupBadge {
                    id: groupBadge
                    visible: root.collapsed
                    count: root.groupCount
                    active: root.hovered
                    onClear: root.groupDismissed()
                }
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
            Meter {
                visible: root.hasProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                value: root.progress
                color: root.critical ? Theme.critical : Theme.primary
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
