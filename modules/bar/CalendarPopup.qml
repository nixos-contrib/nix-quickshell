import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

// The calendar under the clock: one month as a grid, today lit, the days of the months around it muted. Left and Right, the wheel and the
// two arrows go from month to month, and Today is the way back. It has no events: the shell has no accounts, and a calendar of the
// month is the whole of it. The week starts on Monday, or on Sunday, and may have its numbers: `calendar` in the theme file
Popover {
    id: win

    // the month in view, as the date of its first day is built: the month is 0 to 11
    property int year: Clock.date.getFullYear()
    property int month: Clock.date.getMonth()

    readonly property var options: Theme.user.calendar ?? ({})
    // as the day of the week of a Date: 0 is Sunday, 1 is Monday
    readonly property int weekStart: options.weekStart === "sunday" ? 0 : 1
    readonly property bool weekNumbers: options.weekNumbers === true
    readonly property bool away: year !== Clock.date.getFullYear() || month !== Clock.date.getMonth()

    // a month has at most six weeks: the grid always has six rows, so that the popup does not change its height from month to month
    readonly property int columns: weekNumbers ? 8 : 7
    readonly property real cellWidth: Math.floor((panelWidth - padding * 2) / columns)
    readonly property real cellHeight: 32
    // the days before the first of the month that fill the first row
    readonly property int offset: (new Date(year, month, 1).getDay() - weekStart + 7) % 7

    heading: Qt.locale().monthName(month, Locale.LongFormat) + " " + year

    function shift(months: int): void {
        const d = new Date(year, month + months, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }
    function today(): void {
        year = Clock.date.getFullYear();
        month = Clock.date.getMonth();
    }
    // the date of a cell, 0 to 41: the cells before the first of the month are the ones of the month before, and the ones after the
    // last are the ones of the month after
    function dateOf(cell: int): date {
        return new Date(year, month, 1 - offset + cell);
    }
    function isToday(d: date): bool {
        const now = Clock.date;
        return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate();
    }
    // the week of the year of ISO 8601: the one that has the Thursday of the row, whichever day the row starts on
    function weekOf(row: int): int {
        const first = dateOf(row * 7);
        const thursday = new Date(first.getFullYear(), first.getMonth(), first.getDate() + ((4 - first.getDay() + 7) % 7));
        const start = new Date(thursday.getFullYear(), 0, 1);
        return Math.floor((thursday - start) / 86400000 / 7) + 1;
    }

    // a calendar opens on this month, not on the one that was in view when it was closed
    onVisibleChanged: if (visible) today()

    ColumnLayout {
        id: content
        width: parent.width
        spacing: Theme.spaceMd

        // the keys: this item has the focus when the popup is in its place, and Escape is the panel's
        Item {
            id: keys
            focus: true
            implicitWidth: 0
            implicitHeight: 0
            Keys.onLeftPressed: win.shift(-1)
            Keys.onRightPressed: win.shift(1)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Up) {
                    win.shift(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Down) {
                    win.shift(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Home || event.key === Qt.Key_T) {
                    win.today();
                    event.accepted = true;
                }
            }
        }
        Connections {
            target: win
            // the popover gives the focus to its panel when it is in its place, and the keys have it after
            function onPlacedChanged() { if (win.placed) keys.forceActiveFocus(); }
        }

        // the arrows at the sides, and the way back to today between them when another month is in view
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd
            Rectangle {
                Layout.preferredWidth: Theme.slot
                Layout.preferredHeight: Theme.slot
                radius: Theme.radiusSm
                color: previous.pressed ? Theme.surfaceHigh : (previous.containsMouse ? Theme.surface : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                // the chevron of the shell is drawn pointing down: a quarter turn each way
                ChevronIcon {
                    anchors.centerIn: parent
                    size: 18
                    rotation: 90
                    color: Theme.text
                }
                MouseArea {
                    id: previous
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.shift(-1)
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.slot
                PillButton {
                    anchors.centerIn: parent
                    visible: win.away
                    text: "Today"
                    onClicked: win.today()
                }
            }
            Rectangle {
                Layout.preferredWidth: Theme.slot
                Layout.preferredHeight: Theme.slot
                radius: Theme.radiusSm
                color: next.pressed ? Theme.surfaceHigh : (next.containsMouse ? Theme.surface : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                ChevronIcon {
                    anchors.centerIn: parent
                    size: 18
                    rotation: -90
                    color: Theme.text
                }
                MouseArea {
                    id: next
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.shift(1)
                }
            }
        }

        // the days of the week, then the six weeks
        GridLayout {
            Layout.fillWidth: true
            columns: win.columns
            columnSpacing: 0
            rowSpacing: 2

            Repeater {
                model: win.columns
                Item {
                    required property int index
                    // the first column of the numbers has no name
                    readonly property int day: win.weekNumbers ? index - 1 : index
                    Layout.preferredWidth: win.cellWidth
                    Layout.preferredHeight: win.cellHeight - 8
                    Label {
                        anchors.centerIn: parent
                        visible: parent.day >= 0
                        role: "label"
                        text: parent.day >= 0 ? Qt.locale().dayName((win.weekStart + parent.day) % 7, Locale.ShortFormat).substring(0, 2) : ""
                    }
                }
            }
            Repeater {
                model: 6 * win.columns
                Item {
                    id: cell
                    required property int index
                    readonly property int row: Math.floor(index / win.columns)
                    // -1 is the number of the week
                    readonly property int column: index % win.columns - (win.weekNumbers ? 1 : 0)
                    readonly property date day: column >= 0 ? win.dateOf(row * 7 + column) : new Date(0)
                    readonly property bool inMonth: column >= 0 && day.getMonth() === win.month
                    readonly property bool isToday: column >= 0 && win.isToday(day)
                    Layout.preferredWidth: win.cellWidth
                    Layout.preferredHeight: win.cellHeight

                    // today is the filled tile, as the focused workspace is in the bar
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) + 2
                        height: width
                        radius: Theme.radiusSm
                        visible: cell.isToday
                        color: Theme.primary
                    }
                    Label {
                        anchors.centerIn: parent
                        role: cell.column < 0 ? "caption" : "body"
                        text: cell.column < 0 ? win.weekOf(cell.row) : cell.day.getDate()
                        color: cell.isToday ? Theme.textOnPrimary : (cell.column < 0 || !cell.inMonth ? Theme.muted : Theme.text)
                        strong: cell.isToday
                    }
                }
            }
        }

        // the wheel changes the month, a notch at a time
        WheelHandler {
            property real travelled: 0
            onWheel: event => {
                travelled += event.angleDelta.y;
                while (Math.abs(travelled) >= 120) {
                    win.shift(travelled > 0 ? -1 : 1);
                    travelled -= travelled > 0 ? 120 : -120;
                }
            }
        }
    }
}
