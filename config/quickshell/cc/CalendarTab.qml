// Month view. Arrows change month; the title jumps back to today.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.ui

ColumnLayout {
    id: root
    spacing: 14

    SystemClock { id: clock; precision: SystemClock.Minutes }

    property int year: clock.date.getFullYear()
    property int month: clock.date.getMonth()
    readonly property int firstDay: Qt.locale().firstDayOfWeek   // 0 = Sunday

    function shift(delta) {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }
    // ISO 8601 week number
    function weekNumber(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    // 6 weeks starting on the locale's first weekday
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - firstDay + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) out.push(new Date(year, month, 1 - offset + i));
        return out;
    }

    // Today
    Card {
        Layout.fillWidth: true
        padding: 18
        RowLayout {
            spacing: 16
            Text {
                text: clock.date.getDate()
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 44
                font.weight: Font.Light
            }
            ColumnLayout {
                spacing: 2
                Text {
                    text: Qt.formatDate(clock.date, "dddd")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Text {
                    text: Qt.formatDate(clock.date, "MMMM yyyy") + "  ·  Week " + root.weekNumber(clock.date)
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }

    Card {
        Layout.fillWidth: true
        padding: 16

        RowLayout {
            Layout.fillWidth: true
            IconButton { size: 30; icon: "go-previous-symbolic"; onClicked: root.shift(-1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                font.weight: Font.DemiBold
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.year = clock.date.getFullYear(); root.month = clock.date.getMonth(); }
                }
            }
            IconButton { size: 30; icon: "go-next-symbolic"; onClicked: root.shift(1) }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: 7
                delegate: Text {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: root.cells
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool today: root.sameDay(modelData, clock.date)
                    readonly property bool inMonth: modelData.getMonth() === root.month
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 18
                    color: today ? Theme.accent : cellMouse.containsMouse ? Theme.cardHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.anim } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.getDate()
                        color: today ? Theme.accentInk : inMonth ? Theme.fg : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: today ? Font.Bold : Font.Normal
                    }
                    MouseArea { id: cellMouse; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
