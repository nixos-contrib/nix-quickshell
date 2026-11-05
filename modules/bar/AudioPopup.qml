import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.modules.common

// The volume and the outputs: a slider with the mute button, and the list of the outputs to choose from
Popover {
    id: win
    heading: "Sound"
    headerValue: sink && sink.audio ? Math.round(sink.audio.volume * 100) + "%" : ""

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream) }
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd
            // mute, as the speaker of the bar
            Rectangle {
                Layout.preferredWidth: Theme.slot
                Layout.preferredHeight: Theme.slot
                radius: Theme.tileRadius
                color: muteArea.pressed ? Theme.barFocus : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: win.sink && win.sink.audio && win.sink.audio.muted ? "\udb81\udd81" : "\udb81\udd7e"
                    color: win.sink && win.sink.audio && win.sink.audio.muted ? Theme.muted : Theme.text
                    font { family: Theme.iconFont; pixelSize: Theme.statusIcon }
                }
                MouseArea {
                    id: muteArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (win.sink && win.sink.audio) win.sink.audio.muted = !win.sink.audio.muted
                }
            }
            Slider {
                Layout.fillWidth: true
                enabled: !(win.sink && win.sink.audio && win.sink.audio.muted)
                value: win.sink && win.sink.audio ? win.sink.audio.volume : 0
                onMoved: v => { if (win.sink && win.sink.audio) win.sink.audio.volume = v; }
            }
        }

        // the section: its label is the break, and no line
        Label {
            role: "label"
            text: "Output"
            Layout.topMargin: Theme.spaceXs
        }
        Repeater {
            model: win.outputs
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool current: win.sink !== null && modelData.id === win.sink.id
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: Theme.tileRadius + 1
                color: rowArea.containsMouse && !current ? Theme.surfaceHigh : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                    spacing: Theme.spaceSm
                    Label {
                        text: row.current ? "✓" : ""
                        color: Theme.primary
                        Layout.preferredWidth: 14
                    }
                    Label {
                        text: row.modelData.description !== "" ? row.modelData.description : row.modelData.name
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Pipewire.preferredDefaultAudioSink = row.modelData;
                        win.visible = false;
                    }
                }
            }
        }
    }
}
