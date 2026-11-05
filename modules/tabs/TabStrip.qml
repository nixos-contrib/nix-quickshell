import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs
import qs.modules.common

// The strip of one tabbed container: a window of the shell over the strip that i3 reserves, as wide and as high as it, drawn with the
// tabs of the container. i3 floats it, see the rule in docs/i3.md, and it is moved to its place from the rectangles of i3
FloatingWindow {
    id: win
    // { id, x, y, w, h, active, tabs }, see Tabs
    required property var spec
    signal tabClicked(real id)
    signal tabClosed(real id)
    signal listRequested
    signal blankClicked

    readonly property real scale: win.devicePixelRatio
    readonly property string name: "nshell-tabs-" + spec.id
    title: name
    color: "transparent"
    visible: true
    implicitWidth: Math.max(1, spec.w / scale)
    implicitHeight: Math.max(1, spec.h / scale)
    // the window does not draw before i3 has put it in its place, or it showed in the middle of the screen
    property bool placed: false

    function place() {
        const w = Math.round(spec.w), h = Math.round(spec.h), x = Math.round(spec.x), y = Math.round(spec.y);
        I3.dispatch(`[title="^${win.name}$"] resize set ${w}px ${h}px, move absolute position ${x}px ${y}px`);
    }
    // i3 shows a floating window in the middle first, and does what it is told a moment later
    Timer { id: placeTimer; interval: 50; running: true; onTriggered: { win.place(); revealTimer.restart(); } }
    Timer { id: revealTimer; interval: 50; onTriggered: win.placed = true }
    onSpecChanged: placeTimer.restart()

    readonly property real pad: spec.attached ? 4 : 6
    // the strip that is a row of the bar is as wide as the output, and the tabs start where the container does
    readonly property real inset: spec.inset / scale
    readonly property int count: spec.tabs.length
    readonly property real button: 30
    readonly property real avail: width - inset * 2 - pad * 2 - button - Theme.spaceXs
    readonly property real tabWidth: Math.max(44, Math.min(260, avail / Math.max(1, count)))
    readonly property bool compact: tabWidth < 104

    function iconFor(cls) {
        const entry = DesktopEntries.heuristicLookup(cls) ?? DesktopEntries.byId(cls.toLowerCase());
        return Quickshell.iconPath(entry ? entry.icon : cls.toLowerCase(), "application-x-executable");
    }

    // the track: the color of the bar, so that the strip is part of it, and the tabs are in it
    Rectangle {
        anchors.fill: parent
        radius: spec.attached ? 0 : (spec.full ? 0 : Theme.radiusMd)
        topLeftRadius: spec.attached ? Theme.radiusMd : (spec.full ? 0 : Theme.radiusMd)
        topRightRadius: spec.attached ? Theme.radiusMd : (spec.full ? 0 : Theme.radiusMd)
        bottomLeftRadius: spec.attached ? 0 : (spec.full ? 0 : Theme.radiusMd)
        bottomRightRadius: spec.attached ? 0 : (spec.full ? 0 : Theme.radiusMd)
        color: Theme.base
        opacity: win.placed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        // the hairline between the bar and a strip that is a row of it
        Rectangle { visible: win.spec.full || win.spec.attached; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.border }

        // a click where there is no tab
        MouseArea { anchors.fill: parent; onPressed: win.blankClicked() }

        Flickable {
            id: scroller
            anchors { left: parent.left; right: listButton.left; top: parent.top; bottom: parent.bottom; leftMargin: win.inset + win.pad; rightMargin: Theme.spaceXs }
            contentWidth: row.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: false
            // the wheel moves the tabs sideways when they do not fit
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => scroller.contentX = Math.max(0, Math.min(scroller.contentWidth - scroller.width, scroller.contentX - (wheel.angleDelta.y + wheel.angleDelta.x)))
            }
            Row {
                id: row
                height: parent.height
                spacing: 2
                Repeater {
                    model: ScriptModel { values: win.spec.tabs; objectProp: "id" }
                    delegate: Rectangle {
                        id: tab
                        required property var modelData
                        required property int index
                        readonly property bool front: modelData.current
                        width: win.tabWidth
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height - win.pad * 2
                        radius: Theme.radiusSm + 2
                        // the tab in front is a raised tile, and lighter when the focus is in this container
                        color: front ? (win.spec.active ? Theme.surfaceHigh : Theme.surface) : (area.containsMouse ? Qt.alpha(Theme.surface, 0.7) : "transparent")
                        Behavior on color { ColorAnimation { duration: 110 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: win.compact ? 0 : Theme.spaceSm + 2; rightMargin: win.compact ? 0 : 6 }
                            spacing: Theme.spaceSm
                            Item { visible: win.compact; Layout.fillWidth: true }
                            Image {
                                source: win.iconFor(tab.modelData.cls)
                                sourceSize: Qt.size(48, 48)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                fillMode: Image.PreserveAspectFit
                            }
                            Label {
                                visible: !win.compact
                                text: tab.modelData.name
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                color: tab.front ? Theme.text : Theme.muted
                            }
                            Rectangle {
                                visible: tab.modelData.urgent
                                Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4
                                color: Theme.critical
                            }
                            // close, on the pointer, and on the tab in front
                            Item {
                                visible: !win.compact
                                Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                opacity: area.containsMouse || tab.front ? 1 : 0
                                Rectangle { anchors.fill: parent; radius: 9; color: closeArea.containsMouse ? Qt.alpha(Theme.text, 0.14) : "transparent" }
                                Text { anchors.centerIn: parent; text: "✕"; color: closeArea.containsMouse ? Theme.text : Theme.muted; font { pixelSize: 9; weight: Font.Medium } }
                                MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.tabClosed(tab.modelData.id) }
                            }
                            Item { visible: win.compact; Layout.fillWidth: true }
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton)
                                    win.tabClosed(tab.modelData.id);
                                else
                                    win.tabClicked(tab.modelData.id);
                            }
                        }
                    }
                }
            }
        }

        // the button of the list: the windows of the container, to choose from when there are many
        Rectangle {
            id: listButton
            anchors { right: parent.right; rightMargin: win.inset + win.pad; verticalCenter: parent.verticalCenter }
            width: win.button; height: parent.height - win.pad * 2
            radius: Theme.radiusSm + 2
            color: listArea.containsMouse ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: 110 } }
            Text { anchors.centerIn: parent; text: "▾"; color: Theme.muted; font.pixelSize: 13 }
            MouseArea { id: listArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.listRequested() }
        }
    }
}
