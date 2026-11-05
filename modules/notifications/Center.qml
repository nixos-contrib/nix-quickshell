import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The history of the notifications, in the corner of the toasts: newest first, with Clear all and Do not disturb
FloatingWindow {
    id: win
    required property ListModel history
    property bool dnd: false
    signal toggleDnd
    signal clearAll

    title: "nshell-center"
    visible: false
    color: "transparent"
    implicitWidth: 400
    // As tall as it can be, like the toasts: i3 does not follow a floating window that grows
    implicitHeight: Math.max(400, win.screen.height - 72)
    mask: Region { item: panel }

    function place() {
        const scale = win.devicePixelRatio;
        const x = Math.round((win.screen.width - win.width + 12 - Theme.edge) * scale);
        const y = Math.round(Theme.barHeight * scale);
        I3.dispatch(`[title="^nshell-center$"] move absolute position ${x}px ${y}px`);
    }
    onVisibleChanged: if (visible) placeTimer.restart()
    Timer {
        id: placeTimer
        interval: 80
        onTriggered: win.place()
    }

    Rectangle {
        id: panel
        x: 12
        y: 12
        width: 400 - 24
        height: Math.min(win.height - 24, header.implicitHeight + (list.count > 0 ? list.contentHeight : empty.implicitHeight) + Theme.spacing * 4)
        radius: Theme.radius + 4
        color: Theme.bg
        border { width: 1; color: Theme.border }
        focus: true
        Keys.onEscapePressed: win.visible = false

        ColumnLayout {
            anchors { fill: parent; margins: Theme.spacing + 4 }
            spacing: Theme.spacing

            RowLayout {
                id: header
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "Notifications"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontTitle + 2; weight: Font.DemiBold }
                    Layout.fillWidth: true
                }
                PillButton {
                    text: "Do not disturb"
                    active: win.dnd
                    onClicked: win.toggleDnd()
                }
                PillButton {
                    visible: list.count > 0
                    text: "Clear all"
                    onClicked: win.clearAll()
                }
            }

            ListView {
                id: list
                visible: count > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: win.history
                spacing: Theme.spacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                delegate: HistoryCard {}
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 140 } }
                displaced: Transition { NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic } }
            }

            Text {
                id: empty
                visible: list.count === 0
                text: "No notifications"
                color: Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontBody }
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.spacing
                Layout.bottomMargin: Theme.spacing
            }
        }
    }
}
