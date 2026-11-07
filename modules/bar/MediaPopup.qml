import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.modules.common

// The player: the cover, the title and the artist, previous, play or pause and next, and the position with a slider that seeks where the
// player lets it. The other players that are there are a short list under the controls, and a click makes one the active player for as long
// as the popup is open
Popover {
    id: win

    readonly property var player: Media.active
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property var others: Media.players.filter(p => p !== win.player && p.playbackState !== MprisPlaybackState.Stopped)
    // a stream or a player that does not say where it is has no position to show
    readonly property bool hasPosition: player !== null && player.positionSupported && player.lengthSupported && player.length > 0

    heading: player ? player.identity : "Media"

    // the choice of the popup is for as long as it is open, and the bar follows the one that plays again after it
    onVisibleChanged: if (!visible) Media.selected = null

    // a player does not tell its position as it moves: it is asked, a second at a time, while it plays and the popup is there
    Timer {
        interval: 1000
        repeat: true
        running: win.visible && win.playing
        triggeredOnStart: true
        onTriggered: if (win.player) win.player.positionChanged()
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            // the cover, only while the popup is open: it is an address, and a picture to load
            Item {
                id: cover
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                visible: art.status === Image.Ready
                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    radius: Theme.radiusMd
                    visible: false
                    layer.enabled: true
                }
                Image {
                    id: art
                    anchors.fill: parent
                    visible: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    source: win.visible && win.player ? win.player.trackArtUrl : ""
                }
                MultiEffect {
                    anchors.fill: parent
                    source: art
                    maskEnabled: true
                    maskSource: coverMask
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    strong: true
                    text: win.player ? (win.player.trackTitle !== "" ? win.player.trackTitle : win.player.identity) : ""
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    role: "caption"
                    text: win.player ? win.player.trackArtist : ""
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    role: "caption"
                    text: win.player ? win.player.trackAlbum : ""
                    elide: Text.ElideRight
                }
            }
        }

        // previous, play or pause, next: each is dimmed when the player cannot do it
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceMd

            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Theme.radiusMd
                opacity: win.player && win.player.canGoPrevious ? 1 : 0.4
                color: previousArea.pressed ? Theme.surfaceHigh : (previousArea.containsMouse && win.player && win.player.canGoPrevious ? Theme.surface : "transparent")
                MediaIcon {
                    anchors.centerIn: parent
                    kind: "previous"
                    size: 20
                    color: Theme.text
                }
                MouseArea {
                    id: previousArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: win.player !== null && win.player.canGoPrevious
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.player.previous()
                }
            }
            // the one that is the answer: filled, as a button that is on is
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: width / 2
                opacity: win.player && win.player.canTogglePlaying ? 1 : 0.4
                color: toggleArea.pressed ? Theme.accent : Theme.primary
                MediaIcon {
                    anchors.centerIn: parent
                    kind: win.playing ? "pause" : "play"
                    filled: true
                    size: 20
                    color: Theme.textOnPrimary
                }
                MouseArea {
                    id: toggleArea
                    anchors.fill: parent
                    enabled: win.player !== null && win.player.canTogglePlaying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.player.togglePlaying()
                }
            }
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Theme.radiusMd
                opacity: win.player && win.player.canGoNext ? 1 : 0.4
                color: nextArea.pressed ? Theme.surfaceHigh : (nextArea.containsMouse && win.player && win.player.canGoNext ? Theme.surface : "transparent")
                MediaIcon {
                    anchors.centerIn: parent
                    kind: "next"
                    size: 20
                    color: Theme.text
                }
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: win.player !== null && win.player.canGoNext
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.player.next()
                }
            }
            Item { Layout.fillWidth: true }
        }

        // where it is, and a slider that moves it when the player allows
        RowLayout {
            Layout.fillWidth: true
            visible: win.hasPosition
            spacing: Theme.spaceSm
            Label {
                role: "caption"
                text: win.player ? Media.clock(Math.min(win.player.position, win.player.length)) : ""
                Layout.preferredWidth: 40
            }
            Slider {
                Layout.fillWidth: true
                enabled: win.player !== null && win.player.canSeek
                value: win.hasPosition ? Math.max(0, Math.min(1, win.player.position / win.player.length)) : 0
                onMoved: v => { if (win.player && win.player.canSeek) win.player.position = v * win.player.length; }
            }
            Label {
                role: "caption"
                horizontalAlignment: Text.AlignRight
                text: win.player ? Media.clock(win.player.length) : ""
                Layout.preferredWidth: 40
            }
        }

        // the other players, each a line: a click makes it the one of the popup
        Label {
            visible: win.others.length > 0
            role: "label"
            text: "Players"
            Layout.topMargin: Theme.spaceXs
        }
        Repeater {
            model: win.others
            delegate: Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: Theme.radiusMd
                color: rowArea.containsMouse ? Theme.surfaceHigh : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceSm; rightMargin: Theme.spaceSm }
                    spacing: Theme.spaceSm
                    Label {
                        text: row.modelData.identity + (row.modelData.trackTitle !== "" ? " – " + row.modelData.trackTitle : "")
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Label {
                        role: "caption"
                        text: row.modelData.playbackState === MprisPlaybackState.Playing ? "Playing" : "Paused"
                    }
                }
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.selected = row.modelData
                }
            }
        }
    }
}
